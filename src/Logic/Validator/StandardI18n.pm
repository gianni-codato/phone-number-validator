package Logic::Validator::StandardI18n;

use Moose;

use Model::ValidatorResult;
use Utils::Log;
use Persistence::DataSourceManager;

extends 'Logic::Validator::Standard';

sub validate
{   my $self = shift; my($phoneNumber, $languageCode) = @_;
    Utils::Log::getLogger()->debug("Logic::Validator::StandardI18n: languageCode=$languageCode");

    my $validatorResult = $self->Logic::Validator::Standard::validate($phoneNumber);

    my $ds = Persistence::DataSourceManager::getDataSource('i18n');
    my $msg = $ds->selectMessage(__PACKAGE__, $validatorResult->resultCode, $languageCode);
    # hack: using introspection to modify content (acceptable because the validate method
    # has the responsability to build the validator result)
    $validatorResult->{resultDescription} = $msg;
    Utils::Log::getLogger()->debug("Logic::Validator::StandardI18n: i18n msg=$msg");

    return $validatorResult;
}


1;