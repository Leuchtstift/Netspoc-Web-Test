
use lib 't';
use Test::More;
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

my $lp;
my $rp;
eval{
	$lp = $driver->find_element('grid_services');
	$rp = $driver->find_element('//div[contains(@id, "cardprintactive")]', 'xpath');
}or do{print $@;};

if (!($lp and $rp)){
	BAIL_OUT("whoopsi, seems there is at least one panel missing on the service tab");
}

print $lp . "\n";
print $rp . "\n";

#for (my $i = 0; $i < @rp; $i++){print "$i: $rp[$i]\n";}

done_testing();
$driver->quit();

#$driver->find_element_ok('//div[text()="Netzauswahl"]', 'xpath', "found text:\t'Netzauswahl'");

#$driver->find_element_ok('btn_own_services', "found button:\town services");

#$driver->find_element_ok('btn_cancel_network_selection', "found button:\tcancel selection");