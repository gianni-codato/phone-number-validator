package Logic::ValidatorManager;

use Moose;

use Logic::Validator::Simple;
use Logic::Validator::Standard;


# class properties
my $singleton = Logic::ValidatorManager->new();



# this is a class method, not an instance method!
sub getInstance
{   my $class = shift;
    # TODO manage exceptions!!!
    die("cannot invoke this sub on a class instance") if ($class ne __PACKAGE__);
    return $singleton;
}

my $validatorsList = 
{   'simple'    => Logic::Validator::Simple->new(name => 'simple'),
    'standard'  => Logic::Validator::Standard->new(name => 'standard'),
};


sub getValidator
{   my $self = shift; my($name) = @_;
    return $validatorsList->{$name};
}

1;