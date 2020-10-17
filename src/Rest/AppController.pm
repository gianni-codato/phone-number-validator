package Rest::AppController;
# the purpose of this package is to expose the subs that implement the logic behind the rest
# interface; every sub play the role of an adapter that extract the parameters from the request,
# invoke che right business logic functionality providing those parameters, capture the result
# and build the response with that result

use Model::PhoneNumber;
use Utils::Log;
use Mojo::JWT;


sub home
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::AppController::home invoked");
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

my $secret = 'this is not realy a secret!';
my $get_auth_user_from_request_sub = sub
{   my($req) = @_;

    return undef unless my $headerAuth = $req->headers->header('Authorization');
    return undef unless $headerAuth =~ m|^Bearer (.+)$|; my $jwtToken = $1;    
    return undef unless my $claims = Mojo::JWT->new(secret => $secret)->decode($jwtToken);
    return undef unless my $loginName = $claims->{loginName};

    my $userDataSource = Persistence::DataSourceManager::getDataSource('users');
    return undef unless my $user = $userDataSource->selectUser($loginName);
    return $user;
};



# TODO: check -> process
sub checkNumbers
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::AppController::checkNumbers invoked");

    # extract the file uploaded
    my $csvPhonesFileContent = $c->param('phoneNumbersList');
    if (!(defined($csvPhonesFileContent))) 
    {   $csvPhonesFileContent = $c->param('phoneNumbersFile')->slurp;
    }

    # invoke the right business logic and catch the result
    my $user = $get_auth_user_from_request_sub->($c->req);
    my $validatorResultList = Rest::App::getContext()->checkNumbers($csvPhonesFileContent, $user);
    
    my $response_object = [];
    push(@$response_object, $build_response_object_from_validator->($_)) for @$validatorResultList;
    
    # convert the result in json
    $c->render(json => $response_object);
}



# TODO: check -> process
sub checkSingleNumber
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::AppController::checkSingleNumber invoked");
    
    # extract parameters from request and convert them into a phone number
    my $phoneNumber = $build_phone_number->($c->param('id'), $c->param('number'));
    Utils::Log::debugWithDump('Rest::AppController::checkSingleNumber: phoneNumber=', $phoneNumber);

    # invoke the right business logic and catch the result
    my $user = $get_auth_user_from_request_sub->($c->req);
    my $validatorResult = Rest::App::getContext()->checkSingleNumber($phoneNumber, $user);
    
    # convert the result in json
    $c->render(json => $build_response_object_from_validator->($validatorResult));
}



# return the html page with a form to test for checking a single number
sub testSingleNumber
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::AppController::testSingleNumber invoked");
    $c->render(template => 'testSingleNumber');
}



sub getSingleNumberById
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::AppController::getSingleNumberById invoked");
    
    my $id = $c->param('id');   # extract parameters from request
    
    # invoke the right business logic and catch the result
    my $user = $get_auth_user_from_request_sub->($c->req);
    my $result = Rest::App::getContext()->getNumberById($id, $user);
    Utils::Log::debugWithDump('Rest::AppController::getSingleNumberById: result=', $result);
    
    # convert the result in json
    $c->render(json => $build_response_object_from_validator->($result));
}

sub getSingleNumberAuditById
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::AppController::getSingleNumberAuditById invoked");
    
    my $id = $c->param('id');   # extract parameters from request
    
    # invoke the right business logic and catch the result
    my $user = $get_auth_user_from_request_sub->($c->req);
    my $result = Rest::App::getContext()->getAuditNumberById($id, $user);
    Utils::Log::debugWithDump('Rest::AppController::getSingleNumberAuditById: result=', $result);
    
    # convert the result in json
    my @response_object = map
    {   my $response_object = $build_response_object_from_validator->($_);
        $response_object->{audit} = 
        {   loginName => $_->{loginName},
            timestamp => $_->{timestamp},
        };
        $response_object;
    } @$result;

    $c->render(json => \@response_object);
}



sub authenticate
{   my $c = shift;
    Utils::Log::getLogger()->info("Rest::AppController::authenticate invoked");

    my $loginName = $c->param('loginName');
    my $password = $c->param('password');

    my $user = Rest::App::getContext()->authenticate($loginName, $password);
    if (defined($user))
    {   my $jwtToken = Mojo::JWT->new(claims => { loginName => $user->loginName }, secret => $secret)->encode;
        $c->render(text => $jwtToken);
        return
    }

    # TODO: error
    $c->render(text => '');
    return; # not authenticated
}


1;