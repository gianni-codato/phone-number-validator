package Model::AuditValidatorResult;

use Moose;

extends 'Model::ValidatorResult';

# immutable object (all fields are required upon contruction and are read only)
has 'loginName'             => (isa => 'Str', is => 'ro', required => 1);
has 'timestamp'             => (isa => 'Str', is => 'ro', required => 1); # human readable timestamp (not a good choice in general, here only for the sake of semplicity...)


1;
