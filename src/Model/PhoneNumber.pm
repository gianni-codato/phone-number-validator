package Model::PhoneNumber;

use Moose;

# immutable object (all fields are required upon contruction and are read only)
has 'id' => (isa => 'Int', is => 'ro', required => 1);
has 'rawNum' => (isa => 'Str', is => 'ro', required => 1);


1;
