use strict;
use warnings;

use Test::More;

require_ok( 'WWW::Mechanize' );

# use WWW::Mechanize ();
# my $mech = WWW::Mechanize->new();
# 
# my $url = 'http://127.0.0.1:3000/';
# $mech->get($url)->content;
# $mech->get($url . 'test')->content;
# $mech->post($url . 'insert/3/5')->content;
# 
# 
# my $file = 'Pre-selezione. South_African_Mobile_Numbers.csv';
# open my $fh, '<', $file or die;
# $/ = undef; my $data = <$fh>; close $fh;
# print $data;
# $mech->post($url . 'multiple_insert', content => $data)->content;


done_testing();