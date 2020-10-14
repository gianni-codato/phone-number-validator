package Rest::App;
# the purpose of this package is to wrap the Mojo application inside Moose class instance

use Moose;

has 'unwrapMojoApp' => (isa => 'Mojolicious::Lite', is => 'ro', required => 1);

my $singleton = Rest::App->new(unwrapMojoApp => Rest::App::Mojo->new);
sub getInstance
{   return $singleton;
}

sub setValidator
{   my $self = shift; my($validatorName) = @_;

    my $validator = Logic::ValidatorManager->getInstance->getValidator($validatorName || 'simple');
    $singleton->unwrapMojoApp->{personal_session}->validator($validator);
    
}


package Rest::App::Mojo::Logic;
# the purpose of this package is to expose the subs that implement the logic behind the rest
# interface; every sub play the role of an adapter che extract the parameters from the request,
# invoke che right business logic functionality providing the params, capture the result and
# build the response with the result

use Model::PhoneNumber;

sub home
{   my $c = shift;
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


sub checkNumbers
{   my $c = shift;

    # extract the file uploaded
    my $csvPhonesFileContent = $c->param('phoneNumbersList');
    if (!(defined($csvPhonesFileContent))) 
    {   $csvPhonesFileContent = $c->param('phoneNumbersFile')->slurp;
    }

    # invoke the right business logic and catch the result
    my $appLogic = $c->app->{personal_session};
    my $validatorResultList = $appLogic->checkNumbers($csvPhonesFileContent);
    
    my $response_object = [];
    push(@$response_object, $build_response_object_from_validator->($_)) for @$validatorResultList;
    
    # convert the result in json
    $c->render(json => $response_object);
}


sub checkSingleNumber
{   my $c = shift;
    
    # extract parameters from request and convert them into a phone number
    my $phoneNumber = $build_phone_number->($c->param('id'), $c->param('number'));

    # invoke the right business logic and catch the result
    my $appLogic = $c->app->{personal_session};
    my $validatorResult = $appLogic->checkSingleNumber($phoneNumber);
    
    # convert the result in json
    $c->render(json => $build_response_object_from_validator->($validatorResult));
}


sub testSingleNumber
{   my $c = shift;
    $c->render(template => 'diProva');
};


package Rest::App::Mojo;
# this package is the real Mojolicious app

use Mojolicious::Lite;

use Logic::ValidatorManager;
use Persistence::Repository::PhoneNumber;
use Logic::AppLogic;

get     '/'                     => \&Rest::App::Mojo::Logic::home;
post    '/checkNumbers'         => \&Rest::App::Mojo::Logic::checkNumbers;
post    '/checkSingleNumber'    => \&Rest::App::Mojo::Logic::checkSingleNumber;
get     '/testSingleNumber'     => \&Rest::App::Mojo::Logic::testSingleNumber;

my $validator   = Logic::ValidatorManager->getInstance->getValidator($ENV{PHONE_NUMBER_VALIDATOR} || 'simple');
my $database    = Persistence::Repository::PhoneNumber->new;
my $appLogic    = Logic::AppLogic->new(db => $database, validator => $validator);
app->{personal_session} = $appLogic;


# return the application object for use with "morbo" server and alike
app; 