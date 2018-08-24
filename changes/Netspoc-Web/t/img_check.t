
use strict;
use warnings;
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

#my $button = $driver->find_element('btn_services_tab-btnEl');
#
#my @two = $driver->find_child_elements($button, "//img", 'xpath');
#for (my $i = 0; $i < @two; $i++){ 
#	print "$i: $two[$i]\n"; 
#	print $driver->execute_script("return arguments[0].complete && typeof arguments[0].naturalWidth != \"undefined\" && arguments[0].naturalWidth > 0", $two[$i]) . "\n";
#}
#
#my @kopu = $driver->find_elements('img', 'tag_name');
#
#for (my $i = 0; $i < @kopu; $i++){
#	print "$i: $kopu[$i]\n";
#	print $driver->execute_script("return arguments[0].complete && typeof arguments[0].naturalWidth != \"undefined\" && arguments[0].naturalWidth > 0", $kopu[$i]) . "\n";
#}

done_testing();
$driver->quit();

