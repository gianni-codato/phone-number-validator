package Persistence::Repository::PhoneNumber;

use Moose;

use Utils::Log;

extends 'Persistence::GenericDataSource';

sub initDb
{   my $self = shift;

    my $init_db = '
        CREATE TABLE phone_number 
        (   id                      int         primary key
        ,   raw_number              varchar(80) not null
        ,   normalized_number       char(14)    null
        ,   validation_code         char(5)     not null
        ,   validation_description  varchar(80) not null
        );
    ';
    $self->executeQuery($init_db);
}
sub getMainTableName { return 'phone_number'; }



my $insert_validation = '
    INSERT INTO phone_number 
    (id , raw_number, normalized_number , validation_code , validation_description) 
    VALUES
    (?  , ?         , ?                 , ?               , ?                     );
';
sub insertValidation
{   my $self = shift; my($validationResult) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::PhoneNumber::insertValidation invoked");

    my $params = 
    [   $validationResult->phoneNumber->id,
        $validationResult->phoneNumber->rawNum,
        $validationResult->normalizedNumber,
        $validationResult->resultCode,
        $validationResult->resultDescription,
    ];
    $self->executeQuery($insert_validation, $params)
}



my $delete_validation = '
    DELETE FROM phone_number WHERE id = ?;
';
sub deleteValidation
{   my $self = shift; my($validationResult) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::PhoneNumber::deleteValidation invoked");

    my $old_value_result_set = $self->selectValidationById($validationResult);
    my $params = [ $validationResult->phoneNumber->id ];
    $self->executeQuery($delete_validation, $params);
    
    return $old_value_result_set;
}



my $select_validation_by_id = '
    SELECT * FROM phone_number WHERE id = ?;
';
sub selectValidationById
{   my $self = shift; my($validationResult) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::PhoneNumber::selectValidationById invoked");

    my $params = [ $validationResult->phoneNumber->id ];
    my $select_result_set = $self->executeQuery($select_validation_by_id, $params);
    
    if (scalar(@$select_result_set) > 0)
    {   return $select_result_set->[0];
    }
    return undef;
}



sub insertOrReplaceValidation
{   my $self = shift; my($validationResult) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::PhoneNumber::insertOrReplaceValidation invoked");

    $self->beginTran;
    my $old_value = $self->deleteValidation($validationResult);
    $self->insertValidation($validationResult);
    $self->commitTran;

    return $old_value;
}


1;