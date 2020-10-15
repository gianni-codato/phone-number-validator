use strict;
use warnings;

my $welcome_msg = <<EOM;
Welcome to the Phone Number Exercise CLI
Type 'help' for the list of available commands
EOM

print $welcome_msg;
getCommand();



sub getCommand()
{   print "\n> ";
    while (my $command = <>)
    {   if ($command eq 'help')
        {
        }
        elsif ($command eq 'help')
        {
        }
        elsif ($command eq 'help')
        {
        }
        elsif ($command eq 'help')
        {
        }
        elsif ($command eq 'help')
        {
        }
        else
        {   # errore
        }
    }
}

# HELP
# INIT (per i db?)
# DEPLOY ?
# RUN TEST use App::Prove; (my $a = App::Prove->new)->process_args('-Isrc', 't'); $a->run;
# SERVER START use Mojo::Server::Morbo; Mojo::Server::Morbo->new->run('src/Rest/App.pm');
# SERVER STOP

# EXIT

