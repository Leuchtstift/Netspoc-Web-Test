
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

# left and right panel
my $lp;
my $rp;
eval {
	$lp = $driver->find_element('grid_services');
	$rp = $driver->find_element('//div[contains(@id, "cardprintactive")]', 'xpath');
} or do { BAIL_OUT("service tab panels not found\n$@"); };

# all buttons from the service tab
my @l_btns = $driver->find_child_elements($lp, 'x-btn-icon-el', 'class');
my @r_btns = $driver->find_child_elements($rp, 'x-btn-icon-el', 'class');

# cannot check further without buttons
if (!check_service_buttons(\@l_btns, \@r_btns)) 
{BAIL_OUT("buttons are missing");}

# go to own services tab
$l_btns[0]->click;

my @l_grid = check_own_services_grid($lp);

test4($rp, \@l_grid, $r_btns[0], $r_btns[1]);





sleep 2;

done_testing();
$driver->quit();



sub test4{
	my $panel 	= shift;
	my @sergri 	= @{(shift)};
	my $det_bnt	= shift;
	my $use_bnt	= shift;
	
	$driver->select_by_name(\@sergri, \1, \0, \"Test4");

	ok($driver->find_child_element(
		$panel, '//table[@id="cb_expand_users" and not(contains(@class, "x-form-cb-checked"))]',"xpath"), 
		"found checkbox:\texpand user (unchecked)");
	ok($driver->find_child_element(
		$panel, '//*[(text()="Namen statt IPs")and not(contains(@class, "x-form-cb-checked"))]',"xpath"), 
		"found checkbox:\t'Namen statt IPs' (unchecked)");

	#####

	# service details

	my $details = $driver->find_child_element($panel, './/div[contains(@id, "servicedetails")]', 'xpath');

	ok($details->get_text =~ 'Name:\sBeschreibung:\sVerantwortung:', "found panel:\tservice details");

	my @pseudo_input = $driver->find_child_elements($details, './/input[not(contains(@id, "hidden"))]', 'xpath');
	#for (my $i = 0; $i < @pseudo_input; $i++) { print "$i: ". $pseudo_input[$i]->get_attribute('id'). ", " . $pseudo_input[$i]->get_value . "\n"; }
	ok($pseudo_input[0]->get_value eq 'Test4', "Name:\tTest4");
	ok($pseudo_input[1]->get_value eq 'Your foo', "Beschreibung:\tYour foo");
	ok($pseudo_input[2]->get_value eq 'y', "Verantwortung:\ty");

	#####

	my $grid = $driver->find_child_element($panel, 'grid_rules');
	my @gch = $driver->find_child_elements($grid, './/*[contains(@class, "x-column-header") and not(contains(@id, "El"))]', 'xpath');
	my @gcc = $driver->find_child_elements($grid, './/td', 'xpath');
	#for (my $i = 0; $i < @gch; $i++) { print "$i: ". $gch[$i]->get_attribute('id'). ", " . $gch[$i]->get_text . "\n"; }
	#for (my $i = 0; $i < @gcc; $i++) { print "$i: ". $gcc[$i]->get_attribute('id'). ", " . $gcc[$i]->get_text . "\n"; }
	
	#####
	
	# check header	
	my $is_ok = 1;
	$is_ok &= $gch[0]->get_text eq "Aktion"; 
	$is_ok &= $gch[1]->get_text eq "Quelle"; 
	$is_ok &= $gch[2]->get_text eq "Ziel"; 
	$is_ok &= $gch[3]->get_text eq "Protokoll"; 
	ok($is_ok, "details grid header are correct");
	
	#####

	# check syntax in grid
	my @regex = ('permit', 'User', '(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)', '(udp|tcp)\s\d+');
	$is_ok = 1;
	$is_ok = $driver->check_sytax_grid(\@gcc, \5, \0, \@regex);
	
	$driver->find_child_element($panel, 'cb_expand_users')->click;	
	#regex matches anschauen
	$regex[1] = '((1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)(\-\/(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d))?)';
	@gcc = $driver->find_child_elements($grid, './/td', 'xpath');
	$is_ok &= $driver->check_sytax_grid(\@gcc, \5, \0, \@regex);

	$driver->find_child_element($panel, '//*[(text()="Namen statt IPs")]', 'xpath')->click;
	$regex[1] = '(any:.+|network:.+|interface:.+|host:.+)';
	$regex[2] = '(any:.+|network:.+|interface:.+|host:.+)';
	@gcc = $driver->find_child_elements($grid, './/td', 'xpath');
	$is_ok &= $driver->check_sytax_grid(\@gcc, \5, \0, \@regex);
	
	ok($is_ok, "detail grid syntax ok");

	#####
	
	# Verantwortliche
	my $omail = $driver->find_child_element($panel, 'ownerEmails');
	
}

sub check_own_services_grid {
	my $panel = shift;

	my @grid = $driver->find_child_elements($panel, './/*[contains(@class, "x-grid-row")]', 'xpath');

#	for (my $i = 0; $i < @grid; $i++) { print "$i: ". $grid[$i]->get_attribute('id'). ", " . $grid[$i]->get_text . "\n"; }

	my $grid_head	= $driver->find_child_element($panel, 'x-column-header-inner', 'class');
	my $head_text =	$driver->find_child_element($grid_head,
													 './/span[contains(@class,"x-column-header-text")]', 'xpath');
	ok($head_text->get_text =~ 'Dienstname\s\(Anzahl:\s\d+\)', "found header:\town services grid");
	ok($head_text->get_text =~ /([0-9]+)/ ? ($1 eq scalar @grid) : 0, "header contains number of elements");

	my @contains = ("Test1", "Test10", "Test11", "Test2",
									"Test3", "Test3a", "Test4",  "Test5",
									"Test6", "Test7",  "Test8",  "Test9"
								);
	if (!ok($driver->grid_contains(\$panel, \1, \0, \@contains), "grid contains all tests services")){	
		BAIL_OUT("own services missing test");
	}

	my $is_ok = 1;
	$is_ok &= $driver->is_grid_in_order(\@grid, \1, \1, \-1, \0);
	$driver->move_to(element => $grid_head);
	sleep 1;   # without 1sec sleep cursor clicks on info window from tab button
	$driver->click;
	@grid	= $driver->find_child_elements($panel, './/*[contains(@class, "x-grid-row")]', 'xpath');
	$is_ok &= $driver->is_grid_in_order(\@grid, \1, \1, \1, \0);
	if (!ok($is_ok, "grid changes correctly")) { BAIL_OUT("own service grid"); }

	return @grid;
}

# nicht gut, muesste komplett ueberarbeitet werden
# buttons muessen derzeit in der gegeben reinfolge existieren
sub check_service_buttons {
	my @left_buttons  = @{ (shift) };
	my @right_buttons = @{ (shift) };

	my $is_ok = 1;

	# check buttons on left panel
	$is_ok&= ok($left_buttons[0]->get_attribute('id') eq "btn_own_services-btnIconEl",
							"found button:\t'Eigene'");
	$is_ok &= ok($driver->find_child_element($left_buttons[1], '//span[text()="Genutzte"]', 'xpath'),
							"found button:\t'Genutzte'");
	$is_ok &= ok($driver->find_child_element($left_buttons[2], '//span[text()="Nutzbare"]', 'xpath'),
							"found button:\t'Nutzbare'");
	$is_ok &= ok($driver->find_child_element($left_buttons[3], '//span[text()="Suche"]', 'xpath'),
							"found button:\t'Suche'");
	$is_ok &= ok($left_buttons[4]->get_attribute('id') =~ "print-all",
							 "found button:\tprint all");
	$is_ok &= ok($left_buttons[5]->get_attribute('id') =~ "printbutton",
							 "found button:\tprint");

	# check buttons on right panel
	$is_ok &= ok($driver->find_child_element($right_buttons[0], '//span[text()="Details zum Dienst"]','xpath'),
							 "found button:\t'Details zum Dienst'");
	$is_ok &= ok($driver->find_child_element($right_buttons[1], '//span[text()="Benutzer (User) des Dienstes"]', 'xpath'),
							 "found button:\t'Benutzer (User) des Dienstes'");
	$is_ok &= ok($right_buttons[2]->get_attribute('id') eq "btn_print_rules-btnIconEl",
				"found button:\tprint rules");
	$is_ok &= ok($driver->find_child_element($right_buttons[3], '//span[contains(@class, icon-add)]', 'xpath'),
							 "found button:\tadd user to service");
	$is_ok &= ok($driver->find_child_element($right_buttons[4], '//span[contains(@class, icon-delete)]', 'xpath'),
							 "found button:\tdelete user from service");
	
	# what is $right_buttons[5]?
	# for (my $i = 0; $i < @right_buttons; $i++) { print "$i: ". $right_buttons[$i]->get_attribute('id'). ", " . $right_buttons[$i]->get_text . "\n"; }

	return $is_ok;
}
