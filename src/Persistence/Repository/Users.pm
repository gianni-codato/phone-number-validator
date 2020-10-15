package Persistence::Repository::Users;

use Moose;

use Model::User;
use Utils::Log;

extends 'Persistence::InMemoryDB';

my $init_db = "
    CREATE TABLE user
    (   login_name              varchar(80) primary key
    ,   hashed_password         varchar(80) not null
    ,   language_code           char(5)     not null
    );

    INSERT INTO user VALUES
    ('codato'   , '1bc42179cc24bcc5eeff1b1b2d03657c' , 'it-IT'), -- md5_hex('gianni')
    ('trump'    , '0d343c0f0ca763f983c8042350059f56' , 'en-US'), -- md5_hex('donald')
    ('biden'    , '8ff32489f92f33416694be8fdc2d4c22' , 'en-US'); -- md5_hex('joe')
";
sub BUILD
{   my $self = shift;
    $self->multiStatementQuery($init_db);
}



my $select_user = '
    SELECT * FROM user WHERE login_name = ?
';
# return the object rappresenting the selected user
sub selectUser
{   my $self = shift; my($loginName) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::Users::selectUser invoked");

    my $params = [ $loginName ];
    my $select_result_set = $self->executeQuery($select_user, $params);
    
    if (scalar(@$select_result_set) > 0)
    {   my $db_row = $select_result_set->[0];
        return Model::User->new(
            loginName       => $db_row->{login_name},
            hashedPassword  => $db_row->{hashed_password},
            languageCode    => $db_row->{language_code}
        );
    }
    return undef;
}



1;