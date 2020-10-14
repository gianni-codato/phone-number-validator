use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Moose;

use Data::Dumper;
use JSON;

use Rest::App;


my $restApp = Rest::App->getInstance();
is(blessed($restApp), 'Rest::App', 'testing restful application creation');

my $mojoApp = $restApp->unwrapMojoApp;
is(blessed($mojoApp), 'Mojolicious::Lite', 'testing mojo application retrieve');

my $t = Test::Mojo->new($mojoApp);
ok(defined($t), 'created a mojo test object');

$t->post_ok('/checkSingleNumber', form => { id => 103343262, number => 27478342944 })
   ->status_is(200, 'check response status')
   ->json_is(
        {   validation => 
            {   algoritm            => 'simple',
                result              => 'ACCEPTABLE',
                statusCode          => 'OK',
                statusDescription   => 'N/A',
            },
            phoneNumber =>
            {   id                  => 103343262,
                originalNumber      => '27478342944',
                normalizedNumber    => '+(27) 478 342944',
            }
        });
# diag(Dumper($t->tx->res));


my $csvContent = <<'EOF';
id,sms_phone
1033432,27478342944
10334326,27478342944
EOF
$t->post_ok('/checkNumbers', form => { phoneNumbersList => $csvContent })
   ->status_is(200, 'check response status')
   ->json_is(
        [   {   validation => 
                {   algoritm            => 'simple',
                    result              => 'ACCEPTABLE',
                    statusCode          => 'OK',
                    statusDescription   => 'N/A',
                },
                phoneNumber =>
                {   id                  => 1033432,
                    originalNumber      => '27478342944',
                    normalizedNumber    => '+(27) 478 342944',
                }
            },
            {   validation => 
                {   algoritm            => 'simple',
                    result              => 'ACCEPTABLE',
                    statusCode          => 'OK',
                    statusDescription   => 'N/A',
                },
                phoneNumber =>
                {   id                  => 10334326,
                    originalNumber      => '27478342944',
                    normalizedNumber    => '+(27) 478 342944',
                }
            },
        ]);
# diag(Dumper($t->tx->res));


my $file_name = 't/Pre-selezione. South_African_Mobile_Numbers.csv';
open(my $fh, '<:encoding(UTF-8)', $file_name);
binmode($fh);
local $/;
my $text = <$fh>;
# diag("contenuto del file: ", $text);
my $form = { phoneNumbersFile => { filename => $file_name, content => $text } };
$t->post_ok('/checkNumbers', form => $form)
    ->status_is(200, 'check response status');
# my $body = $t->tx->res->body;
# diag(Dumper($body));


$restApp->setValidator('standard');
$t->post_ok('/checkSingleNumber', form => { id => 103343262, number => 27478342944 })
   ->status_is(200, 'check response status');
diag(Dumper($t->tx->res->body));

done_testing();