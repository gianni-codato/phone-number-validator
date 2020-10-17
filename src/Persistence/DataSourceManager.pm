package Persistence::DataSourceManager;
# this package provides db connection to every other module of the application

# in a real application this sub should return a connection taken from a pool or
# create a new connection, using connection parameters (host, port, username, password, etc)
# from some secret manager or secure ad-hoc storage; but this is a "demo" app... 
# so keep it simple! yet not so nice!

use Utils::Log;
use Persistence::Repository::I18n;
use Persistence::Repository::Users;
use Persistence::Repository::PhoneNumbers;
use Utils::Config;
use File::Path qw(make_path);


my $data_sources; # cache
sub getDataSource
{   my($dataSourceName) = @_;
    Utils::Log::getLogger()->debug("Persistence::DataSourceManager::getDataSource: dataSourceName=$dataSourceName");
    
    
    if (!defined($data_sources))
    {   
        my $path = Utils::Config::getDataSourceDir();
        if (! -d $path)
        {   make_path($path);
        }
        
        my $mode = Utils::Config::getMode();
        $data_sources = ($mode eq 'develop' 
        ?   {   i18n            => Persistence::Repository::I18n->          new(name => ':memory:'),
                users           => Persistence::Repository::Users->         new(name => ':memory:'),
                phoneNumbers    => Persistence::Repository::PhoneNumbers->  new(name => ':memory:'),
            }
        :   {   i18n            => Persistence::Repository::I18n->          new(name => $path . '/I18n.db'),
                users           => Persistence::Repository::Users->         new(name => $path . '/Users.db'),
                phoneNumbers    => Persistence::Repository::PhoneNumbers->  new(name => $path . '/PhoneNumbers.db'),
            }
        );
    }
    return $data_sources->{$dataSourceName};
};



1;