use strict;
use warnings;

use Test::More;

use Persistence::InMemoryDB;
use Persistence::Repository::PhoneNumber;

use Moose;


my $db = Persistence::InMemoryDB->new;
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


$db = Persistence::Repository::PhoneNumber->new;
ok(blessed($db) eq 'Persistence::Repository::PhoneNumber');


done_testing();