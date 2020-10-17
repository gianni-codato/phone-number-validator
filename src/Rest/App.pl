# this script is a bridge between the Rest::App module and starter scripts like morbo or hypnotoad
# with this script you can run the application directly from the command line: "morbo src/Rest/App.pl"

BEGIN { push(@INC, '.', 'src'); };
use Rest::App;
Rest::App::getInstance(); # return the app object