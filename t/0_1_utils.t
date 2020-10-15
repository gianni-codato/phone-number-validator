use strict;
use warnings;

use Test::More;

use Moose;
use Utils::Log;
use Utils::Config;


# test for config module
$ENV{PHONE_NUMBER_LOG_DIR} = 'prova_dir';
is(Utils::Config::getLogDir(), 'prova_dir', 'log dir - specified value');
delete($ENV{PHONE_NUMBER_LOG_DIR});
is(Utils::Config::getLogDir(), 'tmp/log', 'log dir - default value');

$ENV{PHONE_NUMBER_LOG_LEVEL} = 'debug';
is(Utils::Config::getLogLvel(), 'debug', 'log level - specified value');
delete($ENV{PHONE_NUMBER_LOG_LEVEL});
is(Utils::Config::getLogLvel(), 'info', 'log level - default value');

$ENV{PHONE_NUMBER_VALIDATOR} = 'prova_validator';
is(Utils::Config::getValidatorName(), 'prova_validator', 'validator name - specified value');
delete($ENV{PHONE_NUMBER_VALIDATOR});
is(Utils::Config::getValidatorName(), 'simple', 'validator name - default value');



# test for log module
my $logger = Utils::Log::getLogger();
$logger->debug('TEST');
# if we reach this point the logging system is working fine (otherwise an exeption is thrown by Mojo::Log... ok I could catch the exception but it's an exercise...)
is(blessed($logger), 'Mojo::Log', 'logging system');



done_testing();