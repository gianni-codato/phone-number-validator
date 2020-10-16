BEGIN { push(@INC, '.', 'src'); };
use Rest::App;
Rest::App::getInstance();