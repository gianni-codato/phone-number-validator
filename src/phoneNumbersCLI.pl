use strict;
use warnings;

use Mojo::Server::Morbo;
use App::Prove;
use File::Basename qw( fileparse );
use File::Spec;

use TAP::Harness;

# get the absolute path of the 'src' dir of the project; needed for @INC
my($basename, $path) = fileparse($0);
my $abs_pth = File::Spec->rel2abs($path);
print "\n$abs_pth\n";
push(@INC, $abs_pth);
chdir($abs_pth);

my $help_msg;
my $welcome_msg;


my $server_instance;
my $server_pid;


sub getCommand
{   my $printPrompt = sub { print "\n> " }; 
    
    $printPrompt->();
    while (my $input = <STDIN>)
    {   chomp($input);
        print "\n<$input>";
        my($command, @params) = split(' ', $input);

        if ($command eq 'help')
        {   print $help_msg;
        }
        elsif ($command eq 'exit' || $command eq 'quit')
        {   print "See you soon!";
            exit(0);
        }
        elsif ($command eq 'setup')
        {   setup(@params);
        }
        elsif ($command eq 'run-tests')
        {   # (my $prove = App::Prove->new)->process_args('-I' . $abs_pth, $abs_pth . '/../t/');
            # $prove->run;
            TAP::Harness
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




$help_msg = <<EOM;
The format of every command is:
    <command> [parameters]

Here are the commands details (other then help/quit/exit):

    setup [user-name user-password language]
        prepare the enviroment for running the server;
        every time you run the setup command the project is re-configured again to its initial state and you
        will lose the previous configuration and data; type 'help setup' for more information about parameters
    
    run-tests 
        run the unit tests and display the results; type 'help run-tests' for more informations about tests 
        and how to run them from the command line

    start-server [validator-type]
        run one instance of the server (against which you can send requests with your favourite client --e.g. 
        curl-- or you can validate phone numbers using a browser); type CTRL+Inter to stop the server; type 
        'help start-server' for more informations about the validator-type parameter and how to start the
        server from the command line (this way you have more control over the server configuration)



        
        
        Tests can also be run directly from the command line (without this CLI), using the standard 'prove' utility; type
        prove -I<src-path> <test-path>
        where <src-path> is the path to the 'src' directory of the project, while <test-path> is the path to the 't' dir
        (if your current dir is the root of the project simply type 'prove -Isrc t').
EOM



$welcome_msg = <<EOM;

Welcome to the Phone Number Exercise CLI
Type 'help' for the list of available commands with a brief explanation
Type 'help <command>' to a detailed explanation of a single command and its parameters
Type 'quit' or 'exit' to stop the CLI
EOM
print $welcome_msg;
getCommand();
