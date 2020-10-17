package Logic::AppLogic;

use Moose;

use Model::PhoneNumber;
use Utils::Log;
use Utils::Config;
use Persistence::DataSourceManager;
use Digest::MD5 qw(md5_hex);
use Model::User;


has 'validator' => (does => 'Logic::Validator', is => 'rw', required => 1);


my $pn_data_source;
sub checkSingleNumber
{   my $self = shift; my($phoneNumber, $user) = @_;
    Utils::Log::getLogger()->debug("Logic::AppLogic: checkSingleNumber invoked");

    my $languageCode = (defined($user) ? $user->languageCode : Utils::Config::getDefaultLanguageCode());
    my $validator_result = $self->validator->validate($phoneNumber, $languageCode);

    if (defined($user)) # only authenticated users can persist data into the database
    {   $pn_data_source = Persistence::DataSourceManager::getDataSource('phoneNumbers') if (!defined($pn_data_source));
        $pn_data_source->insertOrReplaceValidation($validator_result, $user);
    }

    return $validator_result;
}


# private utility sub
# $processorSub is a sub that receive the list elements that are on a single line and process them
my $process_csv_lines = sub
{   my($csvContent, $processorSub) = @_;

    chomp($csvContent); # remove possible last empty line
    my @lines = split("\n", $csvContent);
    foreach my $line(@lines)
    {   next if ($line eq '' || $line =~ m|^\s+$| || $line =~ 'id,sms_phone'); # header line
        my($id, $raw_number) = split(',', $line);
        $processorSub->($id, $raw_number);
    }
};


sub checkNumbers
{   my $self = shift; my($csvContent, $user) = @_;
    Utils::Log::getLogger()->debug("Logic::AppLogic: checkNumbers invoked");

    my @validator_result_list = ();

    $process_csv_lines->($csvContent, sub
    {   my($id, $raw_number) = @_;
        my $phone_number = Model::PhoneNumber->new(id => $id, rawNum => $raw_number);
        my $line_validator_result = $self->checkSingleNumber($phone_number, $user);
        push(@validator_result_list, $line_validator_result);
    });

    return \@validator_result_list;
}



sub getNumberById
{   my $self = shift; my($id, $user) = @_;

    return undef unless defined($user); # only authenticated users can access the database

    $pn_data_source = Persistence::DataSourceManager::getDataSource('phoneNumbers') if (!defined($pn_data_source));
    
    return $pn_data_source->selectValidationById($id);
}



sub getAuditNumberById
{   my $self = shift; my($id, $user) = @_;

    return undef unless defined($user); # only authenticated users can access into the database

    $pn_data_source = Persistence::DataSourceManager::getDataSource('phoneNumbers') if (!defined($pn_data_source));
    
    return $pn_data_source->selectValidationAuditById($id);
}



# the authentication logic should be put in a separate module, but for this simple excercise can stay here
my $user_data_source;
sub authenticate
{   my $self = shift; my($loginName, $password) = @_;
    Utils::Log::getLogger()->debug("Logic::AppLogic: authenticate $loginName, $password");

    $user_data_source = Persistence::DataSourceManager::getDataSource('users') if (!defined($user_data_source));
    my $user = $user_data_source->selectUser($loginName);

    if (defined($user))
    {   my $md5_hex = md5_hex($password);
        return $user if ($user->hashedPassword eq $md5_hex); # authenticated
    }

    return undef; # not authenticated
}


1;
