package Persistence::InMemoryDB;

use Moose;

use DBD::SQLite;
use Utils::Log;


# database handle
has 'dbh' => (isa => 'DBI::db', is => 'rw');


sub BUILD
{   my $self = shift;
    Utils::Log::getLogger()->debug("Persistence::InMemoryDB: BUILD invoked");

    # options that should work fine, for a exercise like this one
    my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:", undef, undef, 
    {   AutoCommit => 1,
        RaiseError => 1,
        sqlite_see_if_its_a_number => 1,
    });
    $dbh->do("PRAGMA cache_size = 80000");
    $dbh->do("PRAGMA synchronous = OFF");
    $dbh->do("PRAGMA journal_mode = MEMORY");

    $self->dbh($dbh);
}


sub beginTran
{   my $self = shift;
    $self->executeQuery('BEGIN EXCLUSIVE TRANSACTION;');
}

sub commitTran
{   my $self = shift;
    Utils::Log::getLogger()->debug("Persistence::InMemoryDB: BUILD invoked");
    $self->executeQuery('COMMIT TRANSACTION;');
}


sub multiStatementQuery
{   my $self = shift; my($multiStatementQuery, $params, $flagArrayRow) = @_;
    Utils::Log::getLogger()->debug("Persistence::InMemoryDB: multiStatementQuery=$multiStatementQuery");

    my @full_result_set = ();

    my @statement_list = split(m|;|, $multiStatementQuery);
    foreach my $statement(@statement_list)
    {   my $result_set = $self->executeQuery($statement, $params, $flagArrayRow);
        push(@full_result_set, @$result_set) if (ref($result_set) eq 'ARRAY');
    }

    return \@full_result_set;
}


# TODO: check if the following sub is needed
# sub singleStatementQuery
# {   my $self = shift; my($singleStatementQuery, $resultType) = @_;
#     
#     # TODO: check connection
#     
#     my $result_set_found = 0;
#     my $want_result_set = defined(wantarray); # verifico se il chiamante vuole l'eventuale result-set o meno
#     
#     # print "\nEseguo query: ", $statement if $callback;
#     # my $start_time = time();
#     my $stm_result_set = $self->executeQuery($singleStatementQuery, $resultType);
#     # my $end_time = time();
#     # my $tempo_lettura = format_elapsed_time($end_time - $start_time);
#     # print "\n", 'Tempo singola query:', "\t", $tempo_lettura;
# 
#     if (defined($stm_result_set) && $want_result_set)
#     {   $result_set_found = 1;
#         push(@full_result_set, @$stm_result_set);
#     }
# 
#     return ($result_set_found ? $stm_result_set : undef);
# }


# return undef if the sql statement doesn't produce any result-set;
# return an array-ref with the result-set rows otherwise: every row
# will be an array-ref (for positional field access) or an hash-ref
# (default, for named field access), based on the $flagArrayRow 
# parameter value
sub executeQuery
{   my $self = shift; my($statement, $params, $flagArrayRow) = @_;
    Utils::Log::getLogger()->debug("Persistence::InMemoryDB: flagArrayRow=" 
            . (defined($flagArrayRow) ? $flagArrayRow : "undef") . "; executeQuery=$statement");

    my $dbh = $self->dbh;
    
    my $sth = $dbh->prepare($statement);

    if (defined($params))
    {   my $index = 0;
        map {   $sth->bind_param(++$index, $_);
                Utils::Log::getLogger()->debug("Persistence::InMemoryDB: executeQuery; param $index = ", $_);
        } @$params;
    }

    $sth->execute();
    
    my $array_or_hash = (defined($flagArrayRow) && $flagArrayRow == 1 ? [] : {});
    
    if ($sth->{NUM_OF_FIELDS})  # verifico se era una select
    {   my $ret_val =  $sth->fetchall_arrayref($array_or_hash);
        Utils::Log::debugWithDump("Persistence::InMemoryDB: executeQuery; result set=", $ret_val);
        return $ret_val;
    }
    return undef;
}


1;