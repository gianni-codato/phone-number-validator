package Persistence::Repository::I18n;

use Moose;

use Utils::Log;

extends 'Persistence::InMemoryDB';

my $init_db = "
    CREATE TABLE i18n_message
    (   message_key             varchar(80)     not null
    ,   language_code           varchar(5)      not null
    ,   message_value           varchar(255)    not null
        -- PRIMARY KEY (message_key, language_code)
    );

    INSERT INTO i18n_message VALUES
    ('Logic::Validator::Standard/I1', 'en-en', 'The phone number is incorrect because is neither a simple one nor a deleted one'),
    ('Logic::Validator::Standard/I2', 'en-en', 'The phone number has an incorrect format: it should be composed by 9 (without international prefix) or 11 (with international prefix) digits'),
    ('Logic::Validator::Standard/I3', 'en-en', 'The phone number is absent'),
    ('Logic::Validator::Standard/C1', 'en-en', 'The phone number is no longer active (deleted but without date/time specification): the information about that deactivation have being removed from the number'),
    ('Logic::Validator::Standard/C2', 'en-en', 'The phone number is no longer active (deletion date/time: \%s): the information about that deactivation have being removed from the number'),
    ('Logic::Validator::Standard/C3', 'en-en', 'The phone number is no longer active (deleted): the information about that deactivation were corrupted and removed from the number'),
    ('Logic::Validator::Standard/A1', 'en-en', 'The number is correct'),
    ('Logic::Validator::Standard/I1', 'it-it', 'Il numero di telefono non è corretto perché non risulta essere semplice nè cancellato'),
    ('Logic::Validator::Standard/I2', 'it-it', 'Il numero di telefono ha un formato non corretto: dovrebbe essere composto di 9 (senza prefisso internaionale) or 11 (con prefisso internazionale) cifre'),
    ('Logic::Validator::Standard/I3', 'it-it', 'Il numero di telefono è assente'),
    ('Logic::Validator::Standard/C1', 'it-it', 'Il numero di telefono non è più attivo (cancellato ma senza l''indicazione della data/ora): l''informazione circa la disattivazione è stata rimossa dal numero'),
    ('Logic::Validator::Standard/C2', 'it-it', 'Il numero di telefono non è più attivo (data/ora di cancellazione: \%s): l''informazione circa la disattivazione è stata rimossa dal numero'),
    ('Logic::Validator::Standard/C3', 'it-it', 'Il numero di telefono non è più attivo (cancellato): l''informazione circa la disattivazione era corrotta ed è stata rimossa dal numero'),
    ('Logic::Validator::Standard/A1', 'it-it', 'Il numero di telefono è corretto');
";
sub BUILD
{   my $self = shift;
    $self->multiStatementQuery($init_db);
}



my $select_message = '
    SELECT message_value FROM i18n_message WHERE message_key = ? and language_code = ?;
';
sub selectMessage
{   my $self = shift; my($context, $key, $languageCode) = @_;
    Utils::Log::getLogger()->debug("Persistence::Repository::I18n::selectMessage invoked");

    my $params = [ "$context/$key", $languageCode];
    my $select_result_set = $self->executeQuery($select_message, $params);
    
    if (scalar(@$select_result_set) > 0)
    {   return $select_result_set->[0]->{message_value};
    }
    return undef;
}



1;