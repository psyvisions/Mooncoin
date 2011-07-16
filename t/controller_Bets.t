use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'Room' }
BEGIN { use_ok 'Room::Controller::Bets' }

ok( request('/bets')->is_success, 'Request should succeed' );
done_testing();
