package Model::User;

use Moose;

# immutable object (all fields are required upon contruction and are read only)
has 'loginName'         => (isa => 'Str', is => 'ro', required => 1);
has 'hashedPassword'    => (isa => 'Str', is => 'ro', required => 1);
has 'languageCode'      => (isa => 'Str', is => 'ro', required => 1);


1;
