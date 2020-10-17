use strict;
use warnings;

use Test::More;
use Utils::Log;
use File::Basename qw( basename );
use Utils::Config;

Utils::Config::setDevelopMode();
Utils::Log::getLogger()->info('Executing tests: ' . basename($0));


require_ok( 'Mojolicious::Lite' );
require_ok( 'DBD::SQLite' );

done_testing();