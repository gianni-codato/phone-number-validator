package Logic::AppLogic;

use Moose;
use Model::PhoneNumber;

has 'db'        => (isa  => 'Persistence::Repository::PhoneNumber'  , is => 'ro', required => 1);
has 'validator' => (does => 'Logic::Validator'                      , is => 'rw', required => 1);


sub checkSingleNumber
{   my $self = shift; my($phoneNumber) = @_;

    my $validator_result = $self->validator->validate($phoneNumber);
    $self->db->insertOrReplaceValidation($validator_result);

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
{   my $self = shift; my($csvContent) = @_;

    my @validator_result_list = ();

    $process_csv_lines->($csvContent, sub
    {   my($id, $raw_number) = @_;
        my $phone_number = Model::PhoneNumber->new(id => $id, rawNum => $raw_number);
        my $line_validator_result = $self->checkSingleNumber($phone_number);
        push(@validator_result_list, $line_validator_result);
    });

    return \@validator_result_list;
}


1;
