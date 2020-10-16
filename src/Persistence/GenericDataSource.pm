package Persistence::GenericDataSource;

use Moose;

use DBD::SQLite;
use Utils::Log;


# database handle
has 'dbh'           => (isa => 'DBI::db', is => 'rw');
has 'name'          => (isa => 'Str'    , is => 'rw', required => 1);


my $isInitRequired; # private sub pre-declaration


sub BUILD
{   my $self = shift;
    Utils::Log::getLogger()->debug("Persistence::GenericDataSource: BUILD invoked");

    # options that should work fine, for a exercise like this one
    my $dbh = DBI->connect("dbi:SQLite:dbname=" . $self->name, undef, undef, 
    {   AutoCommit => 1,
        RaiseError => 1,
        sqlite_see_if_its_a_number => 1,
    });
    $dbh->do("PRAGMA cache_size = 80000");
    $dbh->do("PRAGMA synchronous = OFF");
    $dbh->do("PRAGMA journal_mode = MEMORY");

    $self->dbh($dbh);

    # check if the data source need initializazion
    # this is a form of self-made abstract method!
    if (ref($self) ne 'Persistence::GenericDataSource') 
    {   my $main_table_name = $self->getMainTableName() ; # astract method
        my $is_init_required = $isInitRequired->($self, $main_table_name);
        $self->initDb() if $is_init_required;
    }
}


my $search_table = "
    SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?;
";
$isInitRequired = sub
{   my($self, $main_table_name) = @_;
    
    my $rs = $self->executeQuery($search_table, [ $main_table_name ]);
    
    return (scalar(@$rs) == 0);
};


sub beginTran
{   my $self = shift;
    $self->executeQuery('BEGIN EXCLUSIVE TRANSACTION;');
}

sub commitTran
{   my $self = shift;
    Utils::Log::getLogger()->debug("Persistence::GenericDataSource: BUILD invoked");
    $self->executeQuery('COMMIT TRANSACTION;');
}


sub multiStatementQuery
{   my $self = shift; my($multiStatementQuery, $params, $flagArrayRow) = @_;
    Utils::Log::getLogger()->debug("Persistence::GenericDataSource: multiStatementQuery=$multiStatementQuery");

    my @full_result_set = ();

    my @statement_list = split(m|;|, $multiStatementQuery);
    foreach my $statement(@statement_list)
    {   my $result_set = $self->executeQuery($statement, $params, $flagArrayRow);
        push(@full_result_set, @$result_set) if (ref($result_set) eq 'ARRAY');
    }

    return \@full_result_set;
}


# return undef if the sql statement doesn't produce any result-set;
# return an array-ref with the result-set rows otherwise: every row
# will be an array-ref (for positional field access) or an hash-ref
# (default, for named field access), based on the $flagArrayRow 
# parameter value
sub executeQuery
{   my $self = shift; my($statement, $params, $flagArrayRow) = @_;
    Utils::Log::getLogger()->debug("Persistence::GenericDataSource: flagArrayRow=" 
            . (defined($flagArrayRow) ? $flagArrayRow : "undef") . "; executeQuery=$statement");

    my $dbh = $self->dbh;
    
    my $sth = $dbh->prepare($statement);

    if (defined($params))
    {   my $index = 0;
        map {   $sth->bind_param(++$index, $_);
                Utils::Log::getLogger()->debug(
                    "Persistence::GenericDataSource: executeQuery; param $index = ", (defined($_) ? $_ : ''));
        } @$params;
    }

    $sth->execute();
    
    my $array_or_hash = (defined($flagArrayRow) && $flagArrayRow == 1 ? [] : {});
    
    if ($sth->{NUM_OF_FIELDS})  # verifico se era una select
    {   my $ret_val =  $sth->fetchall_arrayref($array_or_hash);
        Utils::Log::debugWithDump(": executeQuery; result set=", $ret_val);
        return $ret_val;
    }
    return undef;
}


1;