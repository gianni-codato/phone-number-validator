package Persistence::DataSourceManager;
# this package provides db connection to every other module of the application

use Utils::Log;
use Persistence::Repository::I18n;
use Persistence::Repository::Users;
use Persistence::Repository::PhoneNumber;


my $data_sources =
{   i18n            => Persistence::Repository::I18n->new,
    users           => Persistence::Repository::Users->new,
    phoneNumbers    => Persistence::Repository::PhoneNumber->new,
};
# in a real application this sub should return a connection taken from a pool or
# create a new connection, using connection parameters (host, port, username, password, etc)
# from some secret manager or secure ad-hoc storage; but this is a "demo" app... so keep it simple!
sub getDataSource
{   my($dataSourceName) = @_;
    Utils::Log::getLogger()->debug("Persistence::DataSourceManager::getDataSource: dataSourceName=$dataSourceName");
    
    return $data_sources->{$dataSourceName};
};