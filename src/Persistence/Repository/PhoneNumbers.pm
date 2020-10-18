package Persistence::Repository::PhoneNumbers;

use Moose;

use Utils::Log;
use Model::ValidatorResult;
use Model::AuditValidatorResult;
use Model::PhoneNumber;


extends 'Persistence::GenericDataSource';

sub initDb
{   my $self = shift;

    my $init_db = '
        CREATE TABLE phone_number 
        (   id                      int         not null
        ,   raw_number              varchar(80) not null
        ,   validator_name          varchar(80) not null
        ,   result_type             varchar(80) not null
        ,   normalized_number       char(14)    null
        ,   validation_code         char(5)     not null
        ,   validation_description  varchar(80) not null

        ,   PRIMARY KEY (id)
        );

        CREATE TABLE audit_phone_number 
        (   id                      int         not null
        ,   raw_number              varchar(80) not null
        ,   validator_name          varchar(80) not null
        ,   result_type             varchar(80) not null
        ,   normalized_number       char(14)    null
        ,   validation_code         char(5)     not null
        ,   validation_description  varchar(80) not null
        ,   login_name              varchar(80) not null
        ,   timestamp               int         not null
        /*  
            NOTES: 
            no logic primary key: using the dafault provided by sqlite
            timestamp is not a strong guarantee on uniqueness!
            PRIMARY KEY (id, login_name, timestamp)
            
            conceptually correct, but in this design violate foreign key 
            constranit - can simply fixed using a insert-or-update pattern
        ,   FOREIGN KEY (id) REFERENCES phone_number(id)
        */
        );
    ';
    $self->multiStatementQuery($init_db);
}
sub getMainTableName { return 'phone_number'; }



my $insert_validation = '
    INSERT INTO phone_number 
    (id , raw_number, validator_name, result_type, normalized_number , validation_code , validation_description) 
    VALUES
    (?  , ?         , ?             , ?          , ?                 , ?               , ?                     );

    INSERT INTO audit_phone_number 
    (id , raw_number, validator_name, result_type, normalized_number , validation_code , validation_description, login_name, timestamp) 
    VALUES
    (?  , ?         , ?             , ?          , ?                 , ?               , ?                     , ?         , ?        );
';
sub insertValidation
{   my $self = shift; my($validationResult, $user) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::PhoneNumbers::insertValidation invoked");

    my $params = 
    [   $validationResult->phoneNumber->id,
        $validationResult->phoneNumber->rawNum,
        $validationResult->validator->name,
        $validationResult->resultType,
        $validationResult->normalizedNumber,
        $validationResult->resultCode,
        $validationResult->resultDescription,
        $user->loginName,
        time(),
    ];
    $self->multiStatementQuery($insert_validation, $params)
}



my $delete_validation_by_id = '
    DELETE FROM phone_number WHERE id = ?;
';
sub deleteValidationById
{   my $self = shift; my($id) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::PhoneNumbers::deleteValidationById invoked");

    my $old_value_result_set = $self->selectValidationById($id);
    $self->executeQuery($delete_validation_by_id, [ $id ]);
    
    return $old_value_result_set;
}



sub insertOrReplaceValidation
{   my $self = shift; my($validationResult, $user) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::PhoneNumbers::insertOrReplaceValidation invoked");

    # $self->beginTran;
    my $old_value = $self->deleteValidationById($validationResult->phoneNumber->id);
    $self->insertValidation($validationResult, $user);
    # $self->commitTran;

    return $old_value;
}



# helper function to translate a phone number hash-ref row to 
# an object suitable for building a ValidatorResult object
my $from_table_to_hash = sub
{   my($row) = @_;
    my $retVal = 
    {   phoneNumber         => Model::PhoneNumber->new(id => $row->{id}, rawNum => $row->{raw_number}),
        validator           => Logic::ValidatorManager->getInstance->getValidator($row->{validator_name}),
        resultType          => $row->{result_type},
        resultCode          => $row->{validation_code},
        resultDescription   => $row->{validation_description},
    };
    $retVal->{normalizedNumber} = $row->{normalized_number} if (defined($row->{normalized_number}));
    return $retVal;
};



my $select_validation_by_id = '
    SELECT * FROM phone_number WHERE id = ?;
';
sub selectValidationById
{   my $self = shift; my($id) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::PhoneNumbers::selectValidationById invoked");

    my $select_result_set = $self->executeQuery($select_validation_by_id, [ $id ]);
    
    if (scalar(@$select_result_set) > 0)
    {   my $row = $select_result_set->[0];
        # my simple ORM...
        return Model::ValidatorResult->new($from_table_to_hash->($row));
    }
    return undef;
}



my $select_validation_audit_by_id = '
    SELECT * FROM audit_phone_number WHERE id = ? ORDER BY timestamp;
';
sub selectValidationAuditById
{   my $self = shift; my($id) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::PhoneNumbers::selectValidationById invoked");

    my $select_result_set = $self->executeQuery($select_validation_audit_by_id, [ $id ]);
    
    return undef unless scalar(@$select_result_set) > 0;
    
    # my simple ORM...
    my @object_result_set = map {
        my $params = $from_table_to_hash->($_);
        $params->{loginName} = $_->{login_name};
        $params->{timestamp} = localtime($_->{timestamp});
        Model::AuditValidatorResult->new($params);
    } @$select_result_set;

    return \@object_result_set;
}


1;