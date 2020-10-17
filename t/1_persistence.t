use strict;
use warnings;

use Test::More;


use Digest::MD5 qw(md5_hex);
use Moose;
use Model::ValidatorResult;
use Model::PhoneNumber;
use Logic::ValidatorManager;
use Persistence::DataSourceManager;
use Persistence::GenericDataSource;
use Persistence::Repository::PhoneNumbers;
use Persistence::Repository::I18n;
use Persistence::Repository::Users;
use File::Basename qw( basename );
use Utils::Config;

Utils::Config::setDevelopMode();
Utils::Log::getLogger()->info('Executing tests: ' . basename($0));



my $db;

# tests for data-source manager
$db = Persistence::DataSourceManager::getDataSource('i18n');
is(blessed($db), 'Persistence::Repository::I18n', 'datasource manager - i18n');
$db = Persistence::DataSourceManager::getDataSource('phoneNumbers');
is(blessed($db), 'Persistence::Repository::PhoneNumbers', 'datasource manager - phoneNumbers');
$db = Persistence::DataSourceManager::getDataSource('users');
is(blessed($db), 'Persistence::Repository::Users', 'datasource manager - users');



# tests for the base super-class of all data-source
$db = Persistence::GenericDataSource->new(name => ':memory:');
ok(blessed($db) eq 'Persistence::GenericDataSource');


my $resultSet = $db->executeQuery("CREATE TABLE test (test int)");
is($resultSet, undef, 'undefined result-set');

$resultSet = $db->executeQuery("SELECT * FROM test WHERE test = ?", [1]);
ok(defined($resultSet), 'empty result-set is defined');
is(ref($resultSet), 'ARRAY', 'empty result-set type');
is(scalar(@$resultSet), 0, 'result-set cardinality');

$db->executeQuery("INSERT INTO test VALUES (?), (?), (?)", [-1, 2, 100]);
$resultSet = $db->executeQuery("SELECT test FROM test ORDER BY test");
is(ref($resultSet), 'ARRAY', 'result-set type');
is(scalar(@$resultSet), 3, 'result-set cardinality - hash');
my $secondRow = $resultSet->[1];
is(ref($secondRow) , 'HASH', 'result-set row type - hash');
is(scalar(keys(%$secondRow)), 1, 'result-set field number - hash');
ok(exists($secondRow->{test}), 'result-set row field - hash');
is($secondRow->{test}, 2, 'result-set row field value - hash');

$resultSet = $db->executeQuery("SELECT test FROM test ORDER BY test LIMIT 1", undef, 1);
is(scalar(@$resultSet), 1, 'result-set cardinality - array');
my $firstRow = $resultSet->[0];
is(ref($firstRow) , 'ARRAY', 'result-set row type - array');
is(scalar(@$firstRow) , 1, 'result-set field number - array');
is($firstRow->[0] , -1, 'result-set row field value - array');



# tests for the I18n data-source
$db = Persistence::Repository::I18n->new(name => ':memory:');
is(blessed($db), 'Persistence::Repository::I18n', 'I18n db initialization');

my $msg = $db->selectMessage('Logic::Validator::StandardI18n', 'A1', 'it-IT');
is($msg, 'Il numero di telefono è corretto', 'I18n massage select');



# tests for the I18n data-source
$db = Persistence::Repository::Users->new(name => ':memory:');
is(blessed($db), 'Persistence::Repository::Users', 'User db initialization');
my $user = $db->selectUser('codato');
is(blessed($user), 'Model::User', 'user select');
is($user->loginName, 'codato', 'user select - login');
is($user->hashedPassword, md5_hex('gianni'), 'user select - password');
is($user->languageCode, 'it-IT', 'user select - language');
ok(!defined($db->selectUser('user inesistente!')));



# tests for the PhoneNumber data-source
$db = Persistence::Repository::PhoneNumbers->new(name => ':memory:');
is(blessed($db), 'Persistence::Repository::PhoneNumbers', 'PhoneNumber db initialization');
my $validationResult = Model::ValidatorResult->new(
    phoneNumber         => Model::PhoneNumber->new(id => 1, rawNum => '27123456789'),
    validator           => Logic::ValidatorManager->getInstance->getValidator('simple'),
    resultType          => 'ACCEPTABLE',
    resultCode          => 'A1',
    resultDescription   => 'not so important...',
    normalizedNumber    => '+27 (123) 456789',
);
$db->insertOrReplaceValidation($validationResult, $user);
my $vr_result = $db->selectValidationById(1);
is(blessed($vr_result), 'Model::ValidatorResult', 'select validation result - type');
is($vr_result->phoneNumber->id, 1, 'select validation result - primary key');
is($vr_result->normalizedNumber, '+27 (123) 456789', 'select validation result - field');
is($vr_result->resultType, 'ACCEPTABLE', 'updated row - another field');


# insert another validation for the same PhoneNumber and then check the update and the audit data
$validationResult->phoneNumber->{rawNum} = '27123456789_????';
$validationResult->{resultType} = 'CORRECTED';
sleep(2); # to be sure to have different timestamps
$db->insertOrReplaceValidation($validationResult, $user);
$vr_result = $db->selectValidationById(1);
is($vr_result->phoneNumber->id, 1, 'updated row - primary key');
is($vr_result->normalizedNumber, '+27 (123) 456789', 'updated row - unchanged field');
is($vr_result->resultType, 'CORRECTED', 'updated row - changed field');

my $vr_audit_result = $db->selectValidationAuditById(1);
is(scalar(@$vr_audit_result), 2, 'audit result - cardinality');
is(blessed($vr_audit_result->[0]), 'Model::AuditValidatorResult', 'audit result - type');
is($vr_audit_result->[0]->phoneNumber->id, 1, 'audit result - primary key 1');
is($vr_audit_result->[1]->phoneNumber->id, 1, 'audit result - primary key 2');
is($vr_audit_result->[0]->resultType, 'ACCEPTABLE', 'audit result - original value');
is($vr_audit_result->[1]->resultType, 'CORRECTED', 'audit result - changed value');



done_testing();