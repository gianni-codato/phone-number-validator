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
my $build_app_context;  # private sub pre-declaration

# access the singleton Mojolicious::Lite instance
sub getInstance
{   
    if (!defined($app_instance)) 
    {   $app_instance = $build_app_instance->();
        $app_context = $build_app_context->();
    }
    return $app_instance;
}
# access the singleton Logic::AppLogic instance
sub getContext
{
    if (!defined($app_instance)) 
    {   $app_instance = $build_app_instance->();
        $app_context = $build_app_context->();
    }
    return $app_context;
}


# this sub provide a way for injecting a validator programmatically (instead of using environment variable)
sub setValidator
{   my($validatorName) = @_;
    Utils::Log::getLogger()->info("Rest::App::setValidator: changing application validator to $validatorName");

    my $validator = Logic::ValidatorManager->getInstance->getValidator($validatorName || 'simple');
    getContext()->validator($validator);
}


# build the singleton Mojolicious::Lite instance
$build_app_instance = sub
{
    # for serving static content
    push @{app->static->paths} => 'Rest/static';
    push @{app->static->paths} => '/Rest/static';

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
    any ['GET'  ] => '/'                               => \&Rest::AppController::home;
    any ['POST' ] => '/v1/checkNumbers'                => \&Rest::AppController::checkNumbers;
    any ['POST' ] => '/v1/checkSingleNumber'           => \&Rest::AppController::checkSingleNumber;
    any ['GET'  ] => '/v1/testSingleNumber'            => \&Rest::AppController::testSingleNumber;
    any ['GET'  ] => '/v1/getSingleNumberById'         => \&Rest::AppController::getSingleNumberById;
    any ['GET'  ] => '/v1/getSingleNumberAuditById'    => \&Rest::AppController::getSingleNumberAuditById;
    any ['POST' ] => '/v1/authenticate'                => \&Rest::AppController::authenticate;
    any ['OPTIONS'] => '/'                             => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/v1/checkNumbers'              => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/v1/checkSingleNumber'         => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/v1/testSingleNumber'          => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/v1/getSingleNumberById'       => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/v1/getSingleNumberAuditById'  => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/v1/authenticate'              => { text => 'OPTIONS!' };
    
    # connect the http server log to the entire application log
    my $logger = Utils::Log::getLogger();
    $logger->info('Rest::App::Mojo: application is now ready!');
    app->log($logger);

    # return the application object for use with "morbo/hypnotoad" server and alike
    return app;
};


# build the singleton Logic::AppLogic instance
$build_app_context = sub
{
    # set-up application validation layer
    my $validator   = Logic::ValidatorManager->getInstance->getValidator(Utils::Config::getValidatorName());
    my $app_logic   = Logic::AppLogic->new(validator => $validator);
    
    return $app_logic;
};