package Rest::App;
# the purpose of this package is to wrap the Mojo application inside a Moose class instance

use Moose;

BEGIN { push(@INC, '.', 'src'); };

use Utils::Log;


has 'unwrapMojoApp' => (isa => 'Mojolicious::Lite', is => 'ro', required => 1);

my $singleton = Rest::App->new(unwrapMojoApp => Rest::App::Mojo->new);
sub getInstance
{   return $singleton;
}

sub setValidator
{   my $self = shift; my($validatorName) = @_;
    Utils::Log::getLogger()->info("Rest::App::setValidator: changing application validator to $validatorName");

    my $validator = Logic::ValidatorManager->getInstance->getValidator($validatorName || 'simple');
    $singleton->unwrapMojoApp->{_global_application_context}->validator($validator);
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
my $get_hard_coded_user = Persistence::DataSourceManager::getDataSource('users')->selectUser('codato');



sub checkNumbers
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::App::Mojo::Logic::checkNumbers invoked");

    # extract the file uploaded
    my $csvPhonesFileContent = $c->param('phoneNumbersList');
    if (!(defined($csvPhonesFileContent))) 
    {   $csvPhonesFileContent = $c->param('phoneNumbersFile')->slurp;
    }

    # invoke the right business logic and catch the result
    my $appLogic = $c->app->{_global_application_context};
    my $validatorResultList = $appLogic->checkNumbers($csvPhonesFileContent, $get_hard_coded_user);
    
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
    my $appLogic = $c->app->{_global_application_context};
    my $validatorResult = $appLogic->checkSingleNumber($phoneNumber, $get_hard_coded_user);
    
    # convert the result in json
    $c->render(json => $build_response_object_from_validator->($validatorResult));
}


sub testSingleNumber
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::App::Mojo::Logic::testSingleNumber invoked");
    $c->render(template => 'testSingleNumber');
};



package Rest::App::Mojo;
# this package is the real Mojo app

use Mojolicious::Lite;

use Logic::ValidatorManager;
use Persistence::Repository::PhoneNumber;
use Logic::AppLogic;
use Utils::Log;
use Utils::Config;


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

# set-up application logic components: validation layer and persistence layer
my $validator   = Logic::ValidatorManager->getInstance->getValidator(Utils::Config::getValidatorName());
my $database    = Persistence::Repository::PhoneNumber->new;
my $appLogic    = Logic::AppLogic->new(db => $database, validator => $validator);
app->{_global_application_context} = $appLogic;

# connect the http server log to the entire application log
app->log(Utils::Log::getLogger());
app->log->info('Rest::App::Mojo: application is now ready!');

app->config(morbo => { pid_file => 'tmp/server.pid' });

# return the application object for use with "morbo/hypnotoad" server and alike
app; 