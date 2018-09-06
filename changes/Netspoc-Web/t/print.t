
use strict;
use warnings;
use lib 't';
use Test::More;    #tests => 5;
use Selenium::Remote::WDKeys;
use Selenium::Waiter qw/wait_until/;
use PolicyWeb::Init;
use PolicyWeb::FrontendTest;

my $driver = PolicyWeb::FrontendTest->new(
								browser_name       => 'chrome',
								proxy              => { proxyType => 'direct', },
								default_finder     => 'id',
								javascript         => 1,
								extra_capabilities => { nativeEvents => 'false' }
								);

prepare_export();
prepare_runtime();

$driver->set_implicit_wait_timeout(200);
$driver->login_as_guest_and_choose_owner('x');