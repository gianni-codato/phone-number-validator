package Logic::Validator::Standard;

use Moose;
use Model::ValidatorResult;

with 'Logic::Validator';

sub validate
{   my $self = shift; my($phoneNumber) = @_;

    my $raw_num = $phoneNumber->rawNum;
    
    my @splitted_num = split('_DELETED_', $raw_num);
    my $num_elements = scalar(@splitted_num);
    if ($num_elements > 2)
    {   return $self->buildValidatorResult($phoneNumber, 'I1');
    }
    
    my($num, $time, $correction_code);

    $num = $splitted_num[0];
    if (!defined($num) || $num eq '')
    {   return $self->buildValidatorResult($phoneNumber, 'I3');
    }
    if ($num !~ m|^(27)?(\d{3})(\d{6})$|)
    {   return $self->buildValidatorResult($phoneNumber, 'I2');
    }
    my $normalized_number = "+(27) $2 $3"; 

    if ($num_elements == 2)
    {   $time = $splitted_num[1];
        if (!defined($time) or $time eq '') # i.e. '27123456789_DELETED_'
        {   $correction_code = 'C1';
        }
        else
        {   if ($time !~ m|^\d+$|)
            {   $correction_code = 'C3';
                $time = undef;
            }
            else 
            {   $correction_code = 'C2';
                $time = localtime($time);
            }
        }
    }
    $correction_code = 'A1' if (!defined($correction_code));

    return $self->buildValidatorResult($phoneNumber, $correction_code, $normalized_number, [$time]);
}



my $code_descriptions =
{   I1 => 'The phone number is incorrect because is neither a simple one nor a deleted one',
    I2 => 'The phone number has an incorrect format: it should be composed by 9 (without international prefix) or 11 (with international prefix) digits',
    I3 => 'The phone number is absent',
    C1 => 'The phone number is no longer active (deleted but without date/time specification): the information about that deactivation have being removed from the number',
    C2 => 'The phone number is no longer active (deletion date/time: %s): the information about that deactivation have being removed from the number',
    C3 => 'The phone number is no longer active (deleted): the information about that deactivation were corrupted and removed from the number',
    A1 => 'The number is correct',

};
my $type_mapping =
{   I => 'INCORRECT',
    C => 'CORRECTED',
    A => 'ACCEPTABLE',
};
sub buildValidatorResult
{   my $self = shift; my($phone_number, $result_code, $normalized_number, $params) = @_;

    my $result_type = $type_mapping->{substr($result_code, 0, 1)};
    my $result_description = $code_descriptions->{$result_code};
    if (defined($params))
    {   no warnings 'redundant'; # suppress "Redundant argument in sprintf at ...": known and unuseful
        $result_description = sprintf($result_description, @$params);        
    }

    my $constructor_params =
    {   phoneNumber => $phone_number,
        validator   => $self,
        resultType  => $result_type,
        resultCode  => $result_code,
        resultDescription => $result_description,
    };
    $constructor_params->{normalizedNumber} = $normalized_number if (defined($normalized_number));

    return Model::ValidatorResult->new($constructor_params);
}

1;