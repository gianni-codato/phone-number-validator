package Logic::ValidatorResult;

use Moose;

use Moose::Util::TypeConstraints;
enum 'ValidatorResultType', [qw(ACCEPTABLE CORRECTED INCORRECT)];
no Moose::Util::TypeConstraints;

has 'phoneNumber'   => (isa => 'Model::PhoneNumber' , is => 'ro', required => 1);
has 'validator'     => (does=> 'Logic::Validator'   , is => 'ro', required => 1);
has 'resultType'    => (isa => 'ValidatorResultType', is => 'ro', required => 1);
has 'resultCode'        => (isa => 'Str'            , is => 'ro', required => 1); # the meaning of the code is left to every validator implementation
has 'resultDescription' => (isa => 'Str'            , is => 'ro', required => 0); # human readable description of the resultCode
has 'normalizedNumber'  => (isa => 'Str'            , is => 'ro', required => 0); # format will be +(27) prefix number


1;