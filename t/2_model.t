use strict;
use warnings;

use Test::More;

use Model::PhoneNumber;
use Moose;


my $pn = Model::PhoneNumber->new(id => 103343262, rawNum => '6478342944');
ok(blessed($pn) eq 'Model::PhoneNumber');


done_testing();