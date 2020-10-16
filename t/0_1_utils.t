use strict;
use warnings;

use Test::More;

use Moose;
use Utils::Log;
use File::Basename qw( basename );
use Utils::Config;

Utils::Config::setDevelopMode();
Utils::Log::getLogger()->info('Executing tests: ', basename($0));


# test for config module
$ENV{PHONE_NUMBER_LOG_DIR} = 'prova_dir';
is(Utils::Config::getLogDir(), 'prova_dir', 'log dir - specified value');
delete($ENV{PHONE_NUMBER_LOG_DIR});
is(Utils::Config::getLogDir(), 'work/log', 'log dir - default value');

$ENV{PHONE_NUMBER_LOG_LEVEL} = 'debug';
is(Utils::Config::getLogLevel(), 'debug', 'log level - specified value');
delete($ENV{PHONE_NUMBER_LOG_LEVEL});
is(Utils::Config::getLogLevel(), 'info', 'log level - default value');

$ENV{PHONE_NUMBER_VALIDATOR} = 'prova_validator';
is(Utils::Config::getValidatorName(), 'prova_validator', 'validator name - specified value');
delete($ENV{PHONE_NUMBER_VALIDATOR});
is(Utils::Config::getValidatorName(), 'standard', 'validator name - default value');



# test for log module
my $logger = Utils::Log::getLogger();
$logger->debug('TEST');
# if we reach this point the logging system is working fine (otherwise an exeption is thrown by Mojo::Log... ok I could catch the exception but it's an exercise...)
is(blessed($logger), 'Mojo::Log', 'logging system');



done_testing();