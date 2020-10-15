package Logic::Validator::Simple;

use Moose;
use Model::ValidatorResult;

with 'Logic::Validator';

sub validate
{   my $self = shift; my($phoneNumber) = @_;

    my $rawNum = $phoneNumber->rawNum;
    
    my $isValid = $rawNum =~ m|^(27)?(\d{3})(\d{6})$|;
    my $normalizedNumber = '';
    if ($isValid) 
    {   $normalizedNumber = "+(27) $2 $3"; 
    }

    return Model::ValidatorResult->new
    (   phoneNumber => $phoneNumber,
        validator   => $self,
        resultType  => ($isValid ? 'ACCEPTABLE' : 'INCORRECT'),
        resultCode  => ($isValid ? 'OK' : 'KO'),
        resultDescription => 'N/A',
        normalizedNumber  => $normalizedNumber,
    )
}

1;