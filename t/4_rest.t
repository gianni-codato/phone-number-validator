use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Moose;

use Data::Dumper;
use JSON;

use Rest::App;
use Utils::Log;
use File::Basename qw( basename );
use Utils::Config;

Utils::Config::setDevelopMode();
my $log = Utils::Log::getLogger();
$log->info('Executing tests: ' . basename($0));



my $mojoApp = Rest::App::getInstance();
Rest::App::setValidator('standard');
is(blessed($mojoApp), 'Mojolicious::Lite', 'testing mojo application retrieve');

my $t = Test::Mojo->new($mojoApp);
ok(defined($t), 'created a mojo test object');

$t->post_ok('/v1/checkSingleNumber', form => { id => 103343262, number => 27478342944 })
   ->status_is(200, 'checkSingleNumber: check response status')
   ->json_is(
        {   validation => 
            {   algoritm            => 'standard',
                result              => 'ACCEPTABLE',
                statusCode          => 'A1',
                statusDescription   => 'The number is correct',
            },
            phoneNumber =>
            {   id                  => 103343262,
                originalNumber      => '27478342944',
                normalizedNumber    => '+(27) 478 342944',
            }
        });
$log->debug('checkSingleNumber ' . Dumper($t->tx->res->body));


my $csvContent = <<'EOF';
id,sms_phone
1033432,27478342944
10334326,27478342944
EOF
$t->post_ok('/v1/checkNumbers', form => { phoneNumbersList => $csvContent })
   ->status_is(200, 'checkNumbers: check response status')
   ->json_is(
        [   {   validation => 
                {   algoritm            => 'standard',
                    result              => 'ACCEPTABLE',
                    statusCode          => 'A1',
                    statusDescription   => 'The number is correct',
                },
                phoneNumber =>
                {   id                  => 1033432,
                    originalNumber      => '27478342944',
                    normalizedNumber    => '+(27) 478 342944',
                }
            },
            {   validation => 
                {   algoritm            => 'standard',
                    result              => 'ACCEPTABLE',
                    statusCode          => 'A1',
                    statusDescription   => 'The number is correct',
                },
                phoneNumber =>
                {   id                  => 10334326,
                    originalNumber      => '27478342944',
                    normalizedNumber    => '+(27) 478 342944',
                }
            },
        ]);
$log->debug('checkNumbers ' . Dumper($t->tx->res->body));


my $src_dir = Utils::Config::getSrcDir();
my $file_name = $src_dir . '/../t/Pre-selezione. South_African_Mobile_Numbers.csv';
my $file_content;
{   local $/ = undef;
    open(my $fh, '<:encoding(UTF-8)', $file_name) or die("cannot open test file $file_name");
    binmode($fh);
    $file_content = <$fh>;
    $log->debug('checkNumbers - example filec content' . $file_content);
}
my $form = { phoneNumbersFile => { filename => $file_name, content => $file_content } };
$t->post_ok('/v1/checkNumbers', form => $form)
    ->status_is(200, 'checkNumbers - example file');
$log->debug('checkNumbers - example file' . Dumper($t->tx->res->body));



$t->post_ok('/v1/authenticate', form => { loginName => 'codato', password => 'gianni' })
   ->status_is(200, 'authenticate');
my $jwtToken = $t->tx->res->body;
is($jwtToken, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
            . '.eyJsb2dpbk5hbWUiOiJjb2RhdG8ifQ'
            . '.2WitgMqh2bKGYVxY_4l2O7hLjJfuQLn4RmHonDMu6uU'
            , 'authenticate: jwtToken');


my $headers = { Authorization => "Bearer $jwtToken" };
$t->post_ok('/v1/checkSingleNumber' => $headers => form => { id => 103343262, number => 27478342944 })
    ->status_is(200);
$log->debug('checkSingleNumber - with authentication' . Dumper($t->tx->res->body));



$t->post_ok('/v1/checkSingleNumber' => $headers => form => { id => 103343262, number => 27478342944 })
    ->status_is(200);

$t->get_ok('/v1/getSingleNumberById' => $headers => form => { id => 103343262 })
    ->status_is(200);

$t->get_ok('/v1/getSingleNumberAuditById' => $headers => form => { id => 103343262 })
    ->status_is(200);



done_testing();