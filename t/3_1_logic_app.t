use strict;
use warnings;

use Test::More;

use Data::Dumper;
use Moose;

use Logic::ValidatorManager;
use Logic::AppLogic;
use Persistence::DataSourceManager;


my $validator   = Logic::ValidatorManager->getInstance->getValidator('simple');
my $database    = Persistence::DataSourceManager::getDataSource('phoneNumbers');
my $appLogic    = Logic::AppLogic->new(db => $database, validator => $validator);
my $user        = Persistence::DataSourceManager::getDataSource('users')->selectUser('codato');


my $phoneNum = Model::PhoneNumber->new(id => 103343262, rawNum => '27478342944');
my $validatorResult = $appLogic->checkSingleNumber($phoneNum, $user);
# diag(Dumper($validatorResult));
is($validatorResult->resultType, 'ACCEPTABLE', 'Validation using AppLogic - result type');
is($validatorResult->normalizedNumber, '+(27) 478 342944', 'Validation using AppLogic - normalized number');


my $csvContent = <<'EOF';
id,sms_phone
103426540,84528784843
103290182,_DELETED_1487769666
103278808,263716791426
EOF
$validatorResult = $appLogic->checkNumbers($csvContent, $user);
# diag(Dumper($validatorResult));

$csvContent = <<'EOF';
10,84528784843
EOF
$validatorResult = $appLogic->checkNumbers($csvContent, $user);
# diag(Dumper($validatorResult));



done_testing();