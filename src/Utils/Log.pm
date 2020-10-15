package Utils::Log;
# this package is a very minimal logging package; it is simply a method to obtain a Mojo::Log instance;
# in a real production system we could use one of the modules that exists
# for this pourpose and let a fine-grained configuration by sys-guys/dev-ops;
# in this project I wrote this class only to avoid external dependencies

use strict;
use warnings;


use Mojo::Log;
use Utils::Config;
use Data::Dumper;


my $get_log_file_name_sub = sub
{   
    my $dir_name = Utils::Config::getLogDir();
    if (!(-d $dir_name))
    {   # TODO: too brutal! maybe it's better to create the subdir...
        die($dir_name, " directory doesn't exists!")
    }
    return $dir_name . '/application.log';
};


my $logger; # singleton instance
sub getLogger
{   
    if (!defined($logger))
    {   my $file_name = $get_log_file_name_sub->();
        unlink $file_name;
        my $log_level = Utils::Config::getLogLevel();
        # TODO: check if the supplied level is valid!
        $logger = Mojo::Log->new(path => $file_name, level => $log_level);
        $logger->debug('logger started!');
    }

    return $logger;
}


sub debugWithDump
{   my($msg, $obj) = @_;
    getLogger()->debug($msg, Dumper($obj));
}

1;