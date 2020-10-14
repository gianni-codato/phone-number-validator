use strict;
use warnings;

use Test::More;

use Data::Dumper;
use Moose;

use Model::PhoneNumber;
use Logic::ValidatorManager;
use Logic::Validator::Simple;
use Logic::AppLogic;
use Persistence::Repository::PhoneNumber;


# testing a simple validator: 1a) manual instantiation
my $validator = Logic::Validator::Simple->new(name => 'MySimpleValidator');
is(blessed($validator), 'Logic::Validator::Simple', 'Simple validator creation');
is($validator->name, 'MySimpleValidator', 'testing simple validator name');

# testing a simple validator: 1b) manager instantiation
my $manager = Logic::ValidatorManager->getInstance();
is(blessed($manager), 'Logic::ValidatorManager');
$validator = $manager->getValidator('simple');
ok(defined($validator), 'simple validator creation from validators manager (defined)');
is(blessed($validator), 'Logic::Validator::Simple', 'simple validator creation from validators manager');
is($validator->name, 'simple', 'testing validator name from validators manager');


my $pn; # used for storing PhoneNumber instances
my $validatorResult; # used for storing validation results

# testing a simple validator: 2a) validate an incorrect PhoneNumber instance - wrong number of digits
$pn = Model::PhoneNumber->new(id => 103343262, rawNum => '6478342944');
$validatorResult = $validator->validate($pn);
is(blessed($validatorResult), 'Logic::ValidatorResult');
is($validatorResult->resultType, 'INCORRECT', 'Validating an incorrect number');

# testing a simple validator: 2b) validate an incorrect PhoneNumber instance - wrong prefix
$pn = Model::PhoneNumber->new(id => 103343262, rawNum => '46478342944');
$validatorResult = $validator->validate($pn);
is(blessed($validatorResult), 'Logic::ValidatorResult');
is($validatorResult->resultType, 'INCORRECT', 'Validating an incorrect number');

# testing a simple validator: 2c) validate an incorrect PhoneNumber instance - no tonly digits
$pn = Model::PhoneNumber->new(id => 103343262, rawNum => '46478a42944');
$validatorResult = $validator->validate($pn);
is(blessed($validatorResult), 'Logic::ValidatorResult');
is($validatorResult->resultType, 'INCORRECT', 'Validating an incorrect number');

# testing a simple validator: 3a) validate an acceptable PhoneNumber instance, with prefix
$pn = Model::PhoneNumber->new(id => 103343262, rawNum => '27478342944');
$validatorResult = $validator->validate($pn);
is(blessed($validatorResult), 'Logic::ValidatorResult');
is($validatorResult->resultType, 'ACCEPTABLE', 'Validating an incorrect number');

# testing a simple validator: 3b) validate an acceptable PhoneNumber instance, without prefix
$pn = Model::PhoneNumber->new(id => 103343262, rawNum => '478342944');
$validatorResult = $validator->validate($pn);
is(blessed($validatorResult), 'Logic::ValidatorResult');
is($validatorResult->resultType, 'ACCEPTABLE', 'Validating an incorrect number');


$validator = $manager->getValidator('standard');
ok(defined($validator), 'standard validator creation from validators manager (defined)');
is(blessed($validator), 'Logic::Validator::Standard', 'standard validator creation from validators manager');

$pn = Model::PhoneNumber->new(id => 103343262, rawNum => '478342944');
$validatorResult = $validator->validate($pn);
is(blessed($validatorResult), 'Logic::ValidatorResult');
is($validatorResult->resultType, 'ACCEPTABLE', 'Standard validator - acceptable number - type');
is($validatorResult->resultCode, 'A1', 'Standard validator - acceptable number - code');
# diag(Dumper($validatorResult));

$pn = Model::PhoneNumber->new(id => 103343262, rawNum => '000478342944');
$validatorResult = $validator->validate($pn);
is(blessed($validatorResult), 'Logic::ValidatorResult');
is($validatorResult->resultType, 'INCORRECT', 'Standard validator - incorrect number (1) - type');
is($validatorResult->resultCode, 'I2', 'Standard validator - incorrect number (1) - code');
# diag(Dumper($validatorResult));

$pn = Model::PhoneNumber->new(id => 103343262, rawNum => '_DELETED_');
$validatorResult = $validator->validate($pn);
is(blessed($validatorResult), 'Logic::ValidatorResult');
is($validatorResult->resultType, 'INCORRECT', 'Standard validator - incorrect number (2) - type');
is($validatorResult->resultCode, 'I3', 'Standard validator - incorrect number (2) - code');

$pn = Model::PhoneNumber->new(id => 103343262, rawNum => '27735405794_DELETED_1456789200');
$validatorResult = $validator->validate($pn);
is(blessed($validatorResult), 'Logic::ValidatorResult');
is($validatorResult->resultType, 'CORRECTED', 'Standard validator - corrected - type');
is($validatorResult->resultCode, 'C2', 'Standard validator - corrected - code');
# diag(Dumper($validatorResult));


done_testing();