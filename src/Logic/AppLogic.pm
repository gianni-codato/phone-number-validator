package Logic::AppLogic;
# this package is the core of the business logic of the application

use Moose;

use Model::PhoneNumber;
use Utils::Log;
use Utils::Config;
use Persistence::DataSourceManager;
use Digest::MD5 qw(md5_hex);
use Model::User;


# the validator instance that should be used for all validation operation
# it is injected upon object construction
has 'validator' => (does => 'Logic::Validator', is => 'rw', required => 1);


my $pn_data_source; # PhoneNumber data-source cache
# Main logic action
# receive a PhoneNumber instance to be validated; if the user passed in is valid, the 
# validation result is also stored in the proper data-source
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


# private utility sub that receive the csv content and process it line by line
# the $processorSub parameter is a sub that receive the list elements that are on a single line and process them
my $process_csv_lines = sub
{   my($csvContent, $processorSub) = @_;

    chomp($csvContent); # remove possible last empty line
    my @lines = split("\n", $csvContent);
    foreach my $line(@lines)
    {   chomp($line);
        next if ($line eq '' || $line =~ m|^\s+$| || $line =~ 'id,sms_phone'); # header line
        my($id, $raw_number) = split(',', $line);
        $processorSub->($id, $raw_number);
    }
};


# Main logic action
# receive a cvs file content and every line is processed through the checkSingleNumber sub
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



# Main logic action
# if the supplied user is valid, retrieve the current validation for the supplied id
sub getNumberById
{   my $self = shift; my($id, $user) = @_;

    return undef unless defined($user); # only authenticated users can access the database

    $pn_data_source = Persistence::DataSourceManager::getDataSource('phoneNumbers') if (!defined($pn_data_source));
    
    return $pn_data_source->selectValidationById($id);
}



# Main logic action
# if the supplied user is valid, retrieve the history of validations (audit) for the supplied id
sub getAuditNumberById
{   my $self = shift; my($id, $user) = @_;

    return undef unless defined($user); # only authenticated users can access into the database

    $pn_data_source = Persistence::DataSourceManager::getDataSource('phoneNumbers') if (!defined($pn_data_source));
    
    return $pn_data_source->selectValidationAuditById($id);
}



my $user_data_source; # Users data-source cache
# Main logic action
# TODO: the authentication logic should be put in a separate module, but for this simple excercise can stay here
# check the validity of the user and password provided as input
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
