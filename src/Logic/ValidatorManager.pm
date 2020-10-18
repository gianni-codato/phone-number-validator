package Logic::ValidatorManager;
# this package provides a mean to get the correct validator instance to all other modules of the application

use Moose;

use Logic::Validator::Simple;
use Logic::Validator::Standard;
use Logic::Validator::StandardI18n;
use Utils::Log;


# class properties
my $singleton = Logic::ValidatorManager->new();



# this is a class method, not an instance method!
sub getInstance
{   my $class = shift;
    # TODO manage exceptions!!!
    die("cannot invoke this sub on a class instance") if ($class ne __PACKAGE__);
    return $singleton;
}


# private validator cache
my $validatorsList = 
{   'simple'        => Logic::Validator::Simple->new(name => 'simple'),
    'standard'      => Logic::Validator::Standard->new(name => 'standard'),
    'standardI18n'  => Logic::Validator::StandardI18n->new(name => 'standardI18n'),
};

sub getValidator
{   my $self = shift; my($name) = @_;
    Utils::Log::getLogger()->debug("Logic::ValidatorManager: getValidator($name)");
    return $validatorsList->{$name};
}

1;