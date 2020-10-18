use strict;
use warnings;

use Mojo::Server::Morbo;
use App::Prove;
use File::Basename qw( fileparse );
use File::Spec;
use File::Path qw( remove_tree );


welcome();
setupPath();
getCommand();



sub setupPath
{   # to avoid problems with directories handling with prove (App::Prove)
    # all the operations made by this CLI are done from the 'src/'' directory
    # of the project: so we get the absolute path of the 'src/' and move there
    my($basename, $path) = fileparse($0);
    my $abs_pth = File::Spec->rel2abs($path);
    chdir($abs_pth);
    push(@INC, '.');

    $ENV{PHONE_NUMBER_DATASOURCE_DIR} = '../work/data';
    $ENV{PHONE_NUMBER_LOG_DIR} = '../work/log';
    $ENV{PHONE_NUMBER_SRC_DIR} = '.';
    $ENV{PHONE_NUMBER_LOG_LEVEL} = 'debug';
}



sub getCommand
{   my $printPrompt = sub { print "\n> " }; 
    
    $printPrompt->();
    while (my $input = <STDIN>)
    {   chomp($input);
        my($command, @params) = split(' ', $input);

        if ($command eq 'help')
        {   help(@params);
        }
        elsif ($command eq 'exit' || $command eq 'quit')
        {   print "See you soon!";
            exit(0);
        }
        elsif ($command eq 'description')
        {   description();
        }
        elsif ($command eq 'setup')
        {   setup();
            print "\nsetup completed";
        }
        elsif ($command eq 'run-tests')
        {   (my $prove = App::Prove->new)->process_args('-I.', '../t');
            $prove->run;
        }
        elsif ($command eq 'start-server')
        {   $ENV{PHONE_NUMBER_VALIDATOR} = 'standardI18n';
            Mojo::Server::Morbo->new->run('Rest/App.pl');
        }
        else
        {   print "unrecognized command '$command'";
        }

        $printPrompt->();
    }
}



sub setup
{   my($userName, $userPassword, $language) = @_;

    remove_tree('../work');
    eval " # forzo la creazione dei database
        use Persistence::DataSourceManager;
        Persistence::DataSourceManager->getDataSource('users');
    ";
    die($@) if $@;
}



sub help 
{   my($command) = @_;

    print <<EOM if (!defined($command) || $command =~ m|\s*|);
Here are the available commands (other then help/quit/exit):

    description
        print a general description of this project (user manual) and related technical information (reference guide)
    
    setup
        the setup command prepares the enviroment for running the server: it create the databases in the work/data
        directory and prepare the log directory (in work/log). If you run setup after you have used the server, the 
        project is re-configured again to its initial state and you will lose the previous configuration and data.
        If you forgot to run setup before 'start-server', don't worry, the application will do it for you (so setup
        is really useful only to clean-up the state of the project and restart from scratch after you played with
        the server).
    
    run-tests 
        runs the unit tests and display the results; read the description for more informations about tests 
        and how to run them from the command line

    start-server
        runs one instance of the server (against which you can send requests with your favourite client --e.g. 
        curl-- or you can validate phone numbers using a browser); type CTRL+Inter to stop the server; read the 
        description for more informations about how to start the server from the command line (this way you have
        more control over the server configuration)
EOM
}



sub welcome
{
    print <<EOM;

Welcome to the Phone Number Exercise CLI
Type 'help' for the list of available commands with a brief explanation
Type 'quit' or 'exit' to stop the CLI
EOM
}



sub description
{
    print <<EOM;

User Manual
========

General description
--------
    As requested in the exercise text, this project implements a service designed for the validation and store of telephone 
    numbers of the South Africa state.

    Every phone number processed by the service is uniquely identified by a code, that is modelled as an integer number 
    called 'id': in the realization of this project I imagined that this id is a key to be used to connect the phone number
    to some other system, e.g. a customer database; in other words I supposed that the id is not a simply auto-generated
    integer numeber attached to a phone number, but it has a 'real meaning' (e.g. it identifies a customer for which I need
    to store and validate his/her own main phone number). With this in mind the service exposes the following functionalities:
    1- acquire the phone number connected to an id
        If the id is new (not already present into the db) it's stored along with the phone into the db, otherwise the supplied
        phone number replaces the old one present (e.g. a customer has changed its phone number); the old numeber is not 
        completly lost because every phone number aquisition operation is logged into an audit area of the db.
        On every aquisition operation the phone number is validated (see below for more infos about validation) and the 
        result is both saved into the db and provided to the service caller.
        The aquisition can be done on a single pair of id + phone (suitable for manual operations) or on a list (suitable for
        bulk operations); in case of a single phone number, besides the service endpoint, also a simple web page with a form
        is provided (as requested by the exercise).
    2- recover the phone number connected to an id
        Starting from an id the service caller can read both the currently (last) associated phone number and the history of
        all phone numbers that have been previously existed (in both cases with its validation informations).

Authentication
--------
    The service can work in two different ways:
    1- authenticated mode
        In this mode the caller has the right to access the store, both for reading (point 2 of the 'Genaral description'
        paragraph) and for writing (point 1).
    2- unauthenticated mode
        In this mode the caller cannot access the store, so he/she/it cannot either acquire nor modify any information about 
        any id; so the only thing that is allowed to do is to check for the validity of a single number or a list of numbers
        (to keep the things simple the endpoint for unauthenticated mode are the same as for authenticated mode and the
        different level of authorization access to the db is automatically managed by the service business logic)
    
    Technically, in the former case the service caller has to authenticate itself before all, throgh a specific service
    endpoint call: the authentication is done by supplying a login code and a password that are validated against a "user
    area" stored in the db (the passwords are hashed but without any salt, strong encryption, etc.... in the end this is only
    an exercise!). If the validation is done succesfully the service returns a JWT token that the caller have to include in
    the following calls.

    The server came pre-configured with 3 users that you can use for authentication purpose (the user management was 
    out-of-scope for this exercise and so there isn't an API to modify the users... if you want you have to connect to the db
    with an sql client!). The users are:
    - login-name: codato, password: gianni, locale: it-IT (it's me!) 
    - login-name: trump , password: donal , locale: en-US
    - login-name: biden , password: joe   , locale: en-US

Validation
--------
    The phone number schema for South Africa is +27 xxx yyyyyy (source: wikipedia). So the basic validation rule is that
    the number must have 9 digits (without the international prefix) or 11 digits (but the firts two are 27).

    Moreover I imagined that this service could be exposed to different clients (e.g. in a B2B environment where there are
    more third parties phone numbers providers) and so there could be the need to customize the validation rules (e.g.
    a provider is guaranteed to supply numbers with the correct format while an other provider can supply numbers that
    are stored with additional informations in its own systems and should be corrected). So every server instance can
    be customized with a different validation engine (called validators).
    The server came pre-configured with 3 validators (all apply at least the basic validation rule described above):
    - simple: 
        it is the 'stricter' one because it apply only the basic validation rule; it's suitable for situations in which
        the phone number source is realible about the data supplied
    - standard:
        besides the basic rules it tries to correct number that have '_DELETED_' additional information included; that
        additional information seems to refer to the fact that the number was deleted (and when, in a 'UNIX style 
        timestamp'); I supposed that the additional information was related to the business of the provider of the phone
        number (the caller) but the phone number sould be anyway stored into the db after correction (as an acceptable one)
    - standardI18n
        it's like the standard validator but the description of every number validation that is returned to the caller
        is internationalized; this validator is suitable for a human interaction (while the standard one can be used
        in a system-to-system interaction where only the return codes are used and not the description).
        The server came pre-configured with 2 masseges sets: 'it-IT' for italian and 'en-US' for english. 
        The information about the locale to use is stored within every user. For unauthenticated accesses a configurable
        server-wide default is used


Reference Guide
========

Server
--------
    The application realized in this project is based on the Mojolicious Lite framework and has been tested with the 
    'morbo' server (a standard development server for Mojo ecosystem).

    The server can be easily started with the start-server CLI command, using the default configuration (see below).
    You can also start the server directly from cmd.exe: change the current working dir in the 'src' folder of the
    project and type 'morbo Rest/App.pl' at the prompt. With the latter way you can change the configuration,
    setting the environment variable before starting the server (see the file bat/start-server.bat as an example: it
    will start the server with standardI18n validator, that is not the default). After the server is up and running 
    it prints the address on which is listening (e.g. http://localhost:3000) and you can start doing request to it
    through an http client.
    
    The http://localhost:3000/v1/testSingleNumber endpoint is meant for browser interaction while the other
    endpoints constituite the core API and maybe are best queryed with somenthing like curl: you can find some
    examples on how to interact with the server using curl in the bat/curl-example.bat file.

    The configuration of the server is done through environment variables:
    - PHONE_NUMBER_LOG_LEVEL (default: debug for unit-tests, info for normal use)
        the minimun level of logging made by the server; the increasing level list is: debug, info, warn, error and fatal
    - PHONE_NUMBER_LOG_DIR (dafault: work/log directory of the project)
        the directory where the log file (application.log) is written; the log messages are always appended
    - PHONE_NUMBER_DATASOURCE_DIR (dafault: work/data directory of the project)
        the directory where the databases are located
    - PHONE_NUMBER_VALIDATOR (default: standard)
        the validator to use with the server (the CLI start-server command forces standardI18n)
    - PHONE_NUMBER_DEFAULT_LANGUAGE_CODE (dafault: en-US)
        the language code to use for unauthenticated accesses


Tests
--------
    The run-tests command of the CLI runs all the unit test shipped with the project (in the t folder).
    Every file in the t folder is a suit of related tests concerning the same piece of the application.

    The tests don't corrupt the data that are in the permanent storage because they use 'mocked data'
    databases (this is achieved through in-memory db that are created on-the-fly when necessary).

    Tests can also be run directly from the command line (without this CLI), using the standard 'prove'
    utility; you can see the file bat/run-tests.bat to get an idea about that.


API reference
--------
    The available endpoint (with the relative http methods) are listed here below:

    GET  /
        simply returns a welcome message (useful for testing server responsiveness)

    POST /v1/authenticate
        request parameters: 'loginName' and 'password'
        output response: the JWT token

    POST /v1/checkSingleNumber
        request parameters: 'id' and 'number'
        output response: a JSON object with the result of the validation (see below)
    POST /v1/checkNumbers
        this endpoint expects to receive a csv-formated content in which every line has the id e the phone number;
        the content can be supplied both as a string parameter (name 'phoneNumbersList') and as a file upload 
        parameter (name: 'phoneNumbersFile'); the header line of the csv content is optional; 
        output response: an array of JSON objects (see below), each of which represents the result of the validation for every line

    GET /v1/getSingleNumberById
        request parameters: 'id'
        output response: a JSON object with the result of the last validation for this id (see below)
    GET /v1/getSingleNumberAuditById
        request parameters: 'id'
        output response: an array of JSON objects (see below), each of wich represents the result of the validations
        made on the object historically, added with audit informations (the user who made the action and when)
    
    GET /v1/testSingleNumber
        return an html page with a form by which you can validate a single number

    The result of the validation is a JSON object with the following structure:
    {
        "phoneNumber": {
            "id": "103218982",
            "normalizedNumber": "+(27) 123 123123",
            "originalNumber": "27123123123"
        },
        "validation": {
            "algoritm": "standardI18n",
            "result": "ACCEPTABLE",
            "statusCode": "A1",
            "statusDescription": "The number is correct"
        }
        "audit" : {
            "loginName": "codato",
            "timestamp":"Sun Oct 18 11:29:01 2020"
        }
    }
    The "audit" field is present only for getSingleNumberAuditById calls.
    The "result" field can contain 3 values: ACCEPTABLE, CORRECTED, INCORRECT
    The "statusCode" and "statusDescription" are validator specific. For 'simple' validator statusCode can be
    'OK' or 'KO' and resultDescription is always N/A. For 'standard'/'standardI18n' validators the codes are:
    - I1: The phone number is incorrect because is neither 'deleted' one (i.e. with '_DELETE_'  informations) 
        nor a 'simple' one (without); e.g. 27123123123_DELETED_123456789_DELETED_123456789
    - I2: The phone number has an incorrect format (it doesen't respect the base validation rule)
    - I3: The phone number is absent
    - C1: The phone number can be corrected: has 'delete information' (but without date/time details)
    - C2: The phone number can be corrected: has 'delete information' with date/time details (that are reported 
        only in the description)
    - C3: The phone number can be corrected even if has invalid 'delete information'; e.g. 27123123123_DELETED_a
    - A1: The phone number is correct

Source code
--------
    The code inside the 'src' is organized as follows:
    - 'Utils'
        contains cross-cutting code that can be used by all other modules (logging and configuration)
    - 'Mojo'
        contains a copy of the Mojo::JWT module; it's here only to avoid external dependencies for this project
    - 'Persistence'
        contains all the necessary to connect to the databases and to initialize the databases; the project
        uses 3 differt databases (one for users, one for phone numbers, and one for i18n) and the specific 
        code for every database is in a differet module in the Repository subdir; that code include all the
        queryies that can be done and al the transformation from result-set to model objects (a minimal ORM...)
    - 'Model'
        contains the class that define the domain of this project; the class are defined throgh the use
        of the Moose module (a way to use a 'standard object oriented' paradigm in Perl)
    - 'Logic'
        contains the classes that realize the business logic of the project; in particular the validators
        mechanism; in this packages ther're only reference to model and persistence object and nothing
        that refers to the way this logic is made usable (could be used by other code, by a service, with
        any type of transport protocol and format, etc.)
    - 'Rest'
        this package expose the logic features throught a series of service endpoint

TODOs
--------
    The main open issue in this project is that, due to the lack of time, the exceptions management and
    checks against less common conditions are minimal.
EOM
}
