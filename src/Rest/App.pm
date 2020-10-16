package Rest::App;
# the purpose of this package is to wrap the Mojo application inside a Moose class instance

BEGIN { push(@INC, '.', 'src'); };

use Utils::Log;


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


package Rest::App::Mojo::Logic;
# the purpose of this package is to expose the subs that implement the logic behind the rest
# interface; every sub play the role of an adapter that extract the parameters from the request,
# invoke che right business logic functionality providing those parameters, capture the result
# and build the response with that result

use Model::PhoneNumber;
use Utils::Log;


sub home
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::App::Mojo::Logic::home invoked");
    $c->render(text => 'Welcome Home!');
}


my $build_phone_number = sub
{   my($id, $rawNum) = @_;
    return Model::PhoneNumber->new(id => $id, rawNum => $rawNum);
};

my $build_response_object_from_validator = sub
{   my($validatorResult) = @_;
    return 
    {   validation => 
        {   algoritm            => $validatorResult->validator->name,
            result              => $validatorResult->resultType,
            statusCode          => $validatorResult->resultCode,
            statusDescription   => $validatorResult->resultDescription,
        },
        phoneNumber =>
        {   id                  => $validatorResult->phoneNumber->id,
            originalNumber      => $validatorResult->phoneNumber->rawNum,
            normalizedNumber    => $validatorResult->normalizedNumber,
        }
    };
};



# TODO: user management... work in progress!
my $hard_coded_user;
my $get_hard_coded_user = sub
{   $hard_coded_user = Persistence::DataSourceManager::getDataSource('users')->selectUser('codato') if (!defined($hard_coded_user));
    return $hard_coded_user;
};



sub checkNumbers
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::App::Mojo::Logic::checkNumbers invoked");

    # extract the file uploaded
    my $csvPhonesFileContent = $c->param('phoneNumbersList');
    if (!(defined($csvPhonesFileContent))) 
    {   $csvPhonesFileContent = $c->param('phoneNumbersFile')->slurp;
    }

    # invoke the right business logic and catch the result
    my $validatorResultList = Rest::App::getContext()->checkNumbers($csvPhonesFileContent, $get_hard_coded_user->());
    
    my $response_object = [];
    push(@$response_object, $build_response_object_from_validator->($_)) for @$validatorResultList;
    
    # convert the result in json
    $c->render(json => $response_object);
}


sub checkSingleNumber
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::App::Mojo::Logic::checkSingleNumber invoked");
    
    # extract parameters from request and convert them into a phone number
    my $phoneNumber = $build_phone_number->($c->param('id'), $c->param('number'));
    Utils::Log::debugWithDump('Rest::App::Mojo::Logic::checkSingleNumber: phoneNumber=', $phoneNumber);

    # invoke the right business logic and catch the result
    my $validatorResult = Rest::App::getContext()->checkSingleNumber($phoneNumber, $get_hard_coded_user);
    
    # convert the result in json
    $c->render(json => $build_response_object_from_validator->($validatorResult));
}


sub testSingleNumber
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::App::Mojo::Logic::testSingleNumber invoked");
    $c->render(template => 'testSingleNumber');
};


package Rest::App;

use Mojolicious::Lite;

use Logic::ValidatorManager;
use Logic::AppLogic;
use Utils::Log;
use Utils::Config;

$build_app_instance = sub
{
    # CORS stuff
    app->hook(before_dispatch => sub 
    {   my $c = shift;
        my $headers = $c->res->headers;
        $headers->header('Access-Control-Allow-Origin'  => '*');
        $headers->header('Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
        $headers->header('Access-Control-Max-Age'       => 3600);
        $headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization, X-Requested-With');
    });

    # set-up routes
    any ['GET'  ] => '/'                     => \&Rest::App::Mojo::Logic::home;
    any ['POST' ] => '/checkNumbers'         => \&Rest::App::Mojo::Logic::checkNumbers;
    any ['POST' ] => '/checkSingleNumber'    => \&Rest::App::Mojo::Logic::checkSingleNumber;
    any ['GET'  ] => '/testSingleNumber'     => \&Rest::App::Mojo::Logic::testSingleNumber;
    any ['OPTIONS'] => '/'                   => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/checkNumbers'       => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/checkSingleNumber'  => { text => 'OPTIONS!' };
    any ['OPTIONS'] => '/testSingleNumber'   => { text => 'OPTIONS!' };

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