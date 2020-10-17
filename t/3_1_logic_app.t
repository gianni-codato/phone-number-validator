use strict;
use warnings;

use Test::More;

use Data::Dumper;
use Moose;

use Logic::ValidatorManager;
use Logic::AppLogic;
use Persistence::DataSourceManager;
use File::Basename qw( basename );
use Utils::Config;

Utils::Config::setDevelopMode();
my $log = Utils::Log::getLogger();
$log->info('Executing tests: ' . basename($0));


my $validator   = Logic::ValidatorManager->getInstance->getValidator('simple');
my $database    = Persistence::DataSourceManager::getDataSource('phoneNumbers');
my $appLogic    = Logic::AppLogic->new(db => $database, validator => $validator);
my $user        = Persistence::DataSourceManager::getDataSource('users')->selectUser('codato');
my $id          = 103343262;


my $phoneNum = Model::PhoneNumber->new(id => $id, rawNum => '27478342944');
my $validatorResult = $appLogic->checkSingleNumber($phoneNum, $user);
$log->debug('Validation using AppLogic ' . Dumper($validatorResult));
is($validatorResult->resultType, 'ACCEPTABLE', 'Validation using AppLogic - result type');
is($validatorResult->normalizedNumber, '+(27) 478 342944', 'Validation using AppLogic - normalized number');


my $csvContent = <<'EOF';
id,sms_phone
103426540,84528784843
103290182,_DELETED_1487769666
103278808,263716791426
EOF
$validatorResult = $appLogic->checkNumbers($csvContent, $user);
$log->debug('multi number validation ' . Dumper($validatorResult));
is(scalar(@$validatorResult), 3, 'multi number validation');

$csvContent = <<'EOF';
10,84528784843
EOF
$validatorResult = $appLogic->checkNumbers($csvContent, $user);
$log->debug('multi number validation - without header line' . Dumper($validatorResult));
is(scalar(@$validatorResult), 1, 'multi number validation - without header line');



# user authentication
$user = $appLogic->authenticate('codato', '123');
ok(!defined($user), 'authentication - wrong password');

$user = $appLogic->authenticate('123', 'gianni');
ok(!defined($user), 'authentication - wrong user');

$user = $appLogic->authenticate('codato', 'gianni');
is(blessed($user), 'Model::User', 'authentication - ok');



# data retrivial: simply check the type; the content is checked by persistence layer
my $number = $appLogic->getNumberById($id, $user);
is(blessed($number), 'Model::ValidatorResult', 'select validation result - type');
ok(!defined($appLogic->getNumberById($id, undef)), 'select validation result - unauthenticated access');

my $auditNumber = $appLogic->getAuditNumberById($id, $user);
is(scalar(@$auditNumber), 1, 'select validation audit result - cardinality');
is(blessed($auditNumber->[0]), 'Model::AuditValidatorResult', 'select validation audit result - type');
ok(!defined($appLogic->getAuditNumberById($id, undef)), 'select validation audit result - unauthenticated access');



done_testing();