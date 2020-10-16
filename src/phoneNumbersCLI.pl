use strict;
use warnings;

# use Mojo::Server::Hypnotoad;
use Mojo::Server::Morbo;

use File::Basename qw( basename );
my $basename = basename($0);

my $help_msg;
my $welcome_msg;


my $server_instance;
my $server_pid;


sub getCommand()
{   my $printPrompt = sub { print "\n> " }; 
    
    $printPrompt->();
    while (my $command = <STDIN>)
    {   chomp($command);

        if ($command eq 'help')
        {   print $help_msg;
        }
        if ($command eq 'exit' || $command eq 'quit')
        {   # TODO: stop a server
            print "See you soon!";
            exit(0);
        }
        elsif ($command eq 'setup')
        {
        }
        elsif ($command eq 'tests')
        {
        }
        elsif ($command eq 'server-start')
        {   my $pid_file_name = 'tmp/server.pid';
            
            my $server_pid = fork;
            if ($server_pid) 
            {   # I'm the child (Server)
                print("\nfather - server_pid=", $server_pid, "; \$\$=", $$);
                open FH, '>pid.pid';
                print FH $$;
                close FH;

                push(@INC, 'src');
                $server_instance = Mojo::Server::Morbo->new;
                $server_instance->run('src/Rest/App.pm');
                
            }
            else 
            {   open FH2, '<pid.pid';
                my $pid = <FH2>;
                close FH2;
                sleep(5);
                kill('INT', $pid);
            
                print("\nchild - server_pid=", $server_pid, "; \$\$=", $$);
                # I'm in the father (CLI)
                print "\nThis is the child pid = $server_pid";
            }
        }
        elsif ($command eq 'server-stop')
        {   open FH2, '<pid.pid';
            my $pid = <FH2>;
            close FH2;
            # $server_instance->stop(); # stop accepting request
            print "\ntrying to kill '$server_pid', '$pid'";
            kill('TERM', $pid);

        }
        else
        {   # errore
        }

        $printPrompt->();
    }
}

# HELP
# INIT (per i db?)
# DEPLOY ?
# RUN TEST use App::Prove; (my $a = App::Prove->new)->process_args('-Isrc', 't'); $a->run;
# SERVER START use Mojo::Server::Morbo; Mojo::Server::Morbo->new->run('src/Rest/App.pm');
# SERVER STOP

# EXIT



$help_msg = <<EOM;
Syntax:
    $basename <command> <options>

where <command> is one of following:
    help
        display this help message
    quit
    exit
        both commands terminate the CLI
    setup
        prepare the enviroment for running the server and the unit-tests;
        TODO: if you run setup again after having already used the application...
    tests
        run the unit tests and display the results
    server-start
        run one instance of the server (agaist which you can send request with your
        favourite client --e.g. curl-- or you can validate number using a browser)
    server-stop
        shutdown the istance of the running server
EOM

$welcome_msg = <<EOM;
Welcome to the Phone Number Exercise CLI
Type 'help' for the list of available commands
EOM


print $welcome_msg;
getCommand();

