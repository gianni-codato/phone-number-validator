use strict;
use warnings;

use Test::More;


use Digest::MD5 qw(md5_hex);
use Moose;
use Persistence::DataSourceManager;
use Persistence::InMemoryDB;
use Persistence::Repository::PhoneNumber;
use Persistence::Repository::I18n;
use Persistence::Repository::Users;



my $db;

# tests for data-source manager
$db = Persistence::DataSourceManager::getDataSource('i18n');
is(blessed($db), 'Persistence::Repository::I18n', 'datasource manager - i18n');
$db = Persistence::DataSourceManager::getDataSource('phoneNumbers');
is(blessed($db), 'Persistence::Repository::PhoneNumber', 'datasource manager - phoneNumbers');
$db = Persistence::DataSourceManager::getDataSource('users');
is(blessed($db), 'Persistence::Repository::Users', 'datasource manager - users');



# tests for the base super-class of all data-source
$db = Persistence::InMemoryDB->new;
ok(blessed($db) eq 'Persistence::InMemoryDB');


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



# tests for the PhoneNumber data-source
$db = Persistence::Repository::PhoneNumber->new;
is(blessed($db), 'Persistence::Repository::PhoneNumber', 'PhoneNumber db initialization');



# tests for the I18n data-source
$db = Persistence::Repository::I18n->new;
is(blessed($db), 'Persistence::Repository::I18n', 'I18n db initialization');

my $msg = $db->selectMessage('Logic::Validator::StandardI18n', 'A1', 'it-IT');
is($msg, 'Il numero di telefono è corretto', 'I18n massage select');



# tests for the I18n data-source
$db = Persistence::Repository::Users->new;
is(blessed($db), 'Persistence::Repository::Users', 'User db initialization');
my $user = $db->selectUser('codato');
is(blessed($user), 'Model::User', 'user select');
is($user->loginName, 'codato', 'user select - login');
is($user->hashedPassword, md5_hex('gianni'), 'user select - password');
is($user->languageCode, 'it-IT', 'user select - language');

ok(!defined($db->selectUser('user inesistente!')));


done_testing();