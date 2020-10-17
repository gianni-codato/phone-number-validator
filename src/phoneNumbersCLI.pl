use strict;
use warnings;

use Mojo::Server::Morbo;
use App::Prove;
use File::Basename qw( fileparse );
use File::Spec;
use File::Path qw( remove_tree );


welcome();
setupPath();
getCommand();



sub setupPath
{   # to avoid problems with directories handling with prove (App::Prove)
    # all the operations made by this CLI are done from the 'src/'' directory
    # of the project: so we get the absolute path of the 'src/' and move there
    my($basename, $path) = fileparse($0);
    my $abs_pth = File::Spec->rel2abs($path);
    chdir($abs_pth);
    push(@INC, '.');

    $ENV{PHONE_NUMBER_DATASOURCE_DIR} = '../work/data';
    $ENV{PHONE_NUMBER_LOG_DIR} = '../work/log';
    $ENV{PHONE_NUMBER_SRC_DIR} = '.';
    $ENV{PHONE_NUMBER_LOG_LEVEL} = 'debug';
}



sub getCommand
{   my $printPrompt = sub { print "\n> " }; 
    
    $printPrompt->();
    while (my $input = <STDIN>)
    {   chomp($input);
        my($command, @params) = split(' ', $input);

        if ($command eq 'help')
        {   help(@params);
        }
        elsif ($command eq 'exit' || $command eq 'quit')
        {   print "See you soon!";
            exit(0);
        }
        elsif ($command eq 'description')
        {   description();
        }
        elsif ($command eq 'setup')
        {   setup();
        }
        elsif ($command eq 'run-tests')
        {   (my $prove = App::Prove->new)->process_args('-I.', '../t');
            $prove->run;
        }
        elsif ($command eq 'start-server')
        {   Mojo::Server::Morbo->new->run('Rest/App.pl');
        }
        else
        {   print "unrecognized command '$command'";
        }

        $printPrompt->();
    }
}



sub setup
{   my($userName, $userPassword, $language) = @_;

    remove_tree('../work');
    eval " # forzo la creazione dei database
        use Persistence::DataSourceManager;
        Persistence::DataSourceManager->getDataSource('users');
    ";
    die($@) if $@;
}



sub help 
{   my($command) = @_;

    print <<EOM if (!defined($command) || $command =~ m|\s*|);
Here are the available commands (other then help/quit/exit):

    description
        print a generl description of this project
    
    setup
        prepares the enviroment for running the server;
        every time you run the setup command the project is re-configured again to its initial state and you
        will lose the previous configuration and data; type 'help setup' for more information about parameters
    
    run-tests 
        runs the unit tests and display the results; type 'help run-tests' for more informations about tests 
        and how to run them from the command line

    start-server
        runs one instance of the server (against which you can send requests with your favourite client --e.g. 
        curl-- or you can validate phone numbers using a browser); type CTRL+Inter to stop the server; type 
        'help start-server' for more informations about how to start the server from the command line (this 
        way you have more control over the server configuration)
EOM

    print <<EOM if ($command eq 'setup')
        
    The setup command prepares the enviroment for running the server: it create the databases in the work/data
    directory and prepare the log file (in work/log). If you run setup after you have used the server, the 
    project is re-configured again to its initial state and you will lose the previous configuration and data.
    If you forgot to run setup before 'start-server', don't worry, the application will do it for you (so setup
    is really useful only to clean-up the state of the project and restart after you played with the server).
EOM

    print <<EOM if ($command eq 'run-tests')
        
    The run-tests command runs all the unit test shipped with the project (in the t folder).
    Every file in the t folder is a suit of related tests concerning the same piece of the application.

    The tests don't corrupt the data that are in the permanent storage because they use 'mocked data'
    database (this is achieved through in-memory db that are created on-the-fly when necessary).

    Tests can also be run directly from the command line (without this CLI), using the standard 'prove' utility;
    you can see the file bat\run-tests.bat to get an idea about that
EOM

    print <<EOM if ($command eq 'start-server')
        
    The start-server command start the application using the 'morbo' server: the server print the address
    on which is listening (usually http://localhost:3000); after the server is up and running you can start
    doing request to it through an http client.
    
    The http://localhost:3000/v1/testSingleNumber endpoint is meant for browser interaction while the other
    endpoints constituite an API and maybe are best queryed with somenthing like curl: you can find some
    examples on how to interact with the server using curl in the bat\curl.bat file.

    The server came pre-configured with 3 users that you can use for authentication purpose (the user 
    management was out-of-scope and so there isn't an API to modify the users... if you want you have
    to connect to the db with an sql client!). The users are:
    - login-name: codato, password: gianni, locale: it-IT (it's me!) 
    - login-name: trump , password: donal , locale: en-US
    - login-name: biden , password: joe   , locale: en-US
EOM
}



sub welcome
{
    print <<EOM;

Welcome to the Phone Number Exercise CLI
Type 'help' for the list of available commands with a brief explanation
Type 'help <command>' to a detailed explanation of a single command
Type 'quit' or 'exit' to stop the CLI
EOM
}



sub description