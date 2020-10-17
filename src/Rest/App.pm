package Rest::App;
# the purpose of this package is to build the Mojo application and its context 
# as a singleton service instance for the entire project


use Mojolicious::Lite;
use Rest::AppController;
use Logic::ValidatorManager;
use Logic::AppLogic;
use Utils::Log;
use Utils::Config;


my $app_instance;   # the singleton Mojolicious::Lite instance
my $app_context;    # the singleton Logic::AppLogic instance

my $build_app_instance; # private sub pre-declaration
my $build_app_context; # private sub pre-declaration

sub getInstance
{   
    if (!defined($app_instance)) 
    {   $app_instance = $build_app_instance->();
        $app_context = $build_app_context->();
    }
    return $app_instance;
}
sub getContext
{
    if (!defined($app_instance)) 
    {   $app_instance = $build_app_instance->();
        $app_context = $build_app_context->();
    }
    return $app_context;
}



sub setValidator
{   my($validatorName) = @_;
    Utils::Log::getLogger()->info("Rest::App::setValidator: changing application validator to $validatorName");

    my $validator = Logic::ValidatorManager->getInstance->getValidator($validatorName || 'simple');
    getContext()->validator($validator);
}


$build_app_instance = sub
{
    # CORS stuffs
    app->hook(before_dispatch => sub 
    {   my $c = shift;
        my $headers = $c->res->headers;
        $headers->header('Access-Control-Allow-Origin'  => '*');
        $headers->header('Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
        $headers->header('Access-Control-Max-Age'       => 3600);
        $headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization, X-Requested-With');
    });

    # set-up routes
    any ['GET'  ] => '/'                            => \&Rest::AppController::home;
    any ['POST' ] => '/checkNumbers'                => \&Rest::AppController::checkNumbers;
    any ['POST' ] => '/checkSingleNumber'           => \&Rest::AppController::checkSingleNumber;
    any ['GET'  ] => '/testSingleNumber'            => \&Rest::AppController::testSingleNumber;
    any ['GET'  ] => '/getSingleNumberById'         => \&Rest::AppController::getSingleNumberById;
    any ['GET'  ] => '/getSingleNumberAuditById'    => \&Rest::AppController::getSingleNumberAuditById;
    any ['POST' ] => '/authenticate'                => \&Rest::AppController::authenticate;
    any ['OPTIONS'] => '/'                          => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/checkNumbers'              => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/checkSingleNumber'         => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/testSingleNumber'          => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/getSingleNumberById'       => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/getSingleNumberAuditById'  => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/authenticate'              => { text => 'OPTIONS!' };
    
    # connect the http server log to the entire application log
    my $logger = Utils::Log::getLogger();
    $logger->info('Rest::App::Mojo: application is now ready!');
    app->log($logger);

    # return the application object for use with "morbo/hypnotoad" server and alike
    return app;
};


$build_app_context = sub
{
    # set-up application validation layer
    my $validator   = Logic::ValidatorManager->getInstance->getValidator(Utils::Config::getValidatorName());
    my $app_logic   = Logic::AppLogic->new(validator => $validator);
    
    return $app_logic;
};