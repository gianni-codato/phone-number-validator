package Logic::Validator;
# interface for all validators


use Moose::Role;

# requires that the concrete class implements the validate method
requires 'validate';


has 'name' => (isa => 'Str', is => 'ro', required => 1);


1;
