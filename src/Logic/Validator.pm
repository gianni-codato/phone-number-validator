package Logic::Validator;

use Moose::Role;

# requires that the concrete class implements the validate method
requires 'validate';

# mostly for debugging purpouse
has 'name' => (isa => 'Str', is => 'ro', required => 1);


1;
