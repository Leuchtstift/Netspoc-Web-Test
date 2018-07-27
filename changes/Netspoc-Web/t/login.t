
use strict;
use warnings;

use lib 't';
use Test::More;
use Selenium::Remote::Driver;
use Selenium::Firefox::Profile;
use Selenium::Remote::WDKeys;
use Selenium::Waiter;
use Test::Selenium::Remote::Driver;
use PolicyWeb::Init qw/$SERVER $port/;
use PolicyWeb::FrontendTest;
use Data::Dumper;

=head
my $profile = Selenium::Firefox::Profile->new();
$profile->set_preference(
    "network.proxy.type" => 0
    );

my $driver = Selenium::Remote::Driver->new(
    firefox_profile => $profile,
    base_url        => $base_url,
    default_finder  => 'id'
    );
=cut

PolicyWeb::Init::prepare_export();
PolicyWeb::Init::prepare_runtime_no_login();

my $base_url = "http://$SERVER:$port";

my $driver =
        Test::Selenium::Remote::Driver->new(browser_name => 'chrome',
                                                                                proxy => { proxyType => 'direct', },
                                                                                base_url       => $base_url,
                                                                                default_finder => 'id',
                                                                                javascript     => 1,
        );

$driver->get('index.html');

if (find_login()) {

    $driver->send_keys_to_active_element('not_guest');

# my $login_button = $driver->find_element( '//input[@value="Login"]', "xpath" );

    $driver->click_element_ok('//input[@value="Login"]', "xpath",
                                                        "login button");

    ok($driver->get_current_url() =~ /backend\/login/,
         "login as not_guest failed");

    $driver->get('index.html');

    $driver->send_keys_to_active_element('guest');

    $driver->find_element('//input[@value="Login"]', "xpath")->click;

    ok($driver->get_current_url() =~ /app.html/, "login as guest successeful");
}

$driver->quit;
done_testing();
exit 0;

# checks if elements needed to login are present.
# return 1, if true.
sub find_login {
    my $a = $driver->find_element_ok('//input[@name="email"]', "xpath",
                                                                     "found input box:\temail");
    my $b = $driver->find_element_ok('//input[@name="pass"]', "xpath",
                                                                     "found input box:\tpassword");
    my $c = $driver->find_element_ok('//input[@value="Login"]', "xpath",
                                                                     "found button:\tlogin");
    return $a && $b && $c;
}
