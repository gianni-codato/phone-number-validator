use strict;
use warnings;

use Test::More;

use Model::PhoneNumber;
use Moose;
use Utils::Log;
use File::Basename qw( basename );
use Utils::Config;

Utils::Config::setDevelopMode();
Utils::Log::getLogger()->info('Executing tests: ' . basename($0));


my $pn = Model::PhoneNumber->new(id => 103343262, rawNum => '6478342944');
ok(blessed($pn) eq 'Model::PhoneNumber');
is($pn->id, 103343262, 'Model::PhoneNumber - id field');
is($pn->rawNum, '6478342944', 'Model::PhoneNumber - id field');
Utils::Log::getLogger()->debug('Model::PhoneNumber is ok');


done_testing();