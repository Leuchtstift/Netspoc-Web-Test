
use strict;
use warnings;
use lib 't';
use Test::More; #tests => 5;
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

# left and right panel
my $lp;
my $rp;
eval{
	$lp = $driver->find_element('grid_services');
	$rp = $driver->find_element('//div[contains(@id, "cardprintactive")]', 'xpath');
}or do{BAIL_OUT("service tab panels not found\n$@");};

# all buttons from the service tab
my @l_btns = $driver->find_child_elements($lp, 'x-btn-icon-el', 'class');
my @r_btns = $driver->find_child_elements($rp, 'x-btn-icon-el', 'class');

# cannot check further without buttons
if (!check_service_buttons(\@l_btns, \@r_btns)) {BAIL_OUT("buttons are missing");}

# go to own services tab
$l_btns[0]->click;

my $grid_head = $driver->find_element('x-column-header-text', 'class');
ok($grid_head->get_text =~ 'Dienstname\s\(Anzahl:\s\d+\)', "found header:\town services grid");

my @l_grid = $driver->find_child_elements($lp, './/*[contains(@class, "x-grid-row")]', 'xpath');

ok($grid_head->get_text =~ /([0-9]+)/ ? ($1 eq scalar @l_grid) : 0, "header contains number of elements");

check_own_services_grid(@l_grid);




done_testing();
$driver->quit();




sub check_own_services_grid {
	my @grid = @_;

	my $is_ok = 1;

	$is_ok &= $grid[0]->get_text eq "Test1";
	$is_ok &= $grid[1]->get_text eq "Test10";
	$is_ok &= $grid[2]->get_text eq "Test11";
	$is_ok &= $grid[3]->get_text eq "Test2";
	$is_ok &= $grid[4]->get_text eq "Test3";
	$is_ok &= $grid[5]->get_text eq "Test3a";
	$is_ok &= $grid[6]->get_text eq "Test4";
	$is_ok &= $grid[7]->get_text eq "Test5";
	$is_ok &= $grid[8]->get_text eq "Test6";
	$is_ok &= $grid[9]->get_text eq "Test7";
	$is_ok &= $grid[10]->get_text eq "Test8";
	$is_ok &= $grid[11]->get_text eq "Test9";

	#for (my $i = 0; $i < @l_grid; $i++) { print "$i: ". $l_grid[$i]->get_attribute('id'). ", " . $l_grid[$i]->get_text . "\n"; }
	
	ok ($is_ok, "grid contains all tests services");


}


sub check_service_buttons {
	my @left_buttons 	= @{ (shift) };
	my @right_buttons = @{ (shift) };

	my $is_ok = 1;

	# check buttons on left panel
	$is_ok &= ok($left_buttons[0]->get_attribute('id') eq "btn_own_services-btnIconEl", "found button:\t'Eigene'");
	$is_ok &= ok($driver->find_child_element($left_buttons[1], '//span[text()="Genutzte"]', 'xpath',), "found button:\t'Genutzte'");
	$is_ok &= ok($driver->find_child_element($left_buttons[2], '//span[text()="Nutzbare"]', 'xpath',), "found button:\t'Nutzbare'");
	$is_ok &= ok($driver->find_child_element($left_buttons[3], '//span[text()="Suche"]', 'xpath',), "found button:\t'Suche'");
	$is_ok &= ok($left_buttons[4]->get_attribute('id') =~ "print-all", "found button:\tprint all");
	$is_ok &= ok($left_buttons[5]->get_attribute('id') =~ "printbutton", "found button:\tprint");
	
	# check buttons on right panel
	$is_ok &= ok($driver->find_child_element($right_buttons[0], '//span[text()="Details zum Dienst"]', 'xpath',), "found button:\t'Details zum Dienst'");
	$is_ok &= ok($driver->find_child_element($right_buttons[1], '//span[text()="Benutzer (User) des Dienstes"]', 'xpath',), "found button:\t'Benutzer (User) des Dienstes'");
	$is_ok &= ok($right_buttons[2]->get_attribute('id') eq "btn_print_rules-btnIconEl", "found button:\tprint rules");
	$is_ok &= ok($driver->find_child_element($right_buttons[3], '//span[contains(@class, icon-add)]', 'xpath',), "found button:\tadd user to service");
	$is_ok &= ok($driver->find_child_element($right_buttons[4], '//span[contains(@class, icon-delete)]', 'xpath',), "found button:\tdelete user from service");

	# what is $right_buttons[5]?
	#for (my $i = 0; $i < @right_buttons; $i++) { print "$i: ". $right_buttons[$i]->get_attribute('id'). ", " . $right_buttons[$i]->get_text . "\n"; }

	return $is_ok;
}