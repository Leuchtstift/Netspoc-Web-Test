
use strict;
use warnings;
use lib 't';
use Test::More;    #tests => 28;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::WebElement;
use PolicyWeb::Init qw/$SERVER $port/;
use PolicyWeb::FrontendTest;

#use Selenium::Remote::Driver;
#use Selenium::ActionChains;
#use Selenium::Waiter;
#use Data::Dumper;
#use Try::Tiny;

##############################################################################
#
# Test description:
# -----------------
#
# - go to tab "Eigene Netze"
# - check buttons and grid header beeing present
# - check sytax of grids
#	- check correct resources are displayed after selecting networks
# - check selection and cancel mechanic is functioning properly
#			button changes and
#			services are correctly displayed in services tab
#
##############################################################################

PolicyWeb::Init::prepare_export();
PolicyWeb::Init::prepare_runtime_no_login();

my $driver =
		PolicyWeb::FrontendTest->new(
														browser_name   => 'chrome',
														proxy          => { proxyType => 'direct', },
														default_finder => 'id',
														javascript     => 1,
														extra_capabilities => { nativeEvents => 'false' },
		);

$driver->set_implicit_wait_timeout(200);
$driver->login_as_guest_and_choose_owner('x');

if (!$driver->PolicyWeb::FrontendTest::find_top_buttons()) {
	BAIL_OUT("tab buttons missing");
}

my $b_own_networks = $driver->find_element('btn_own_networks_tab');
$b_own_networks->click;

# todo: bessere lösung als folgende finden
#ok(eval{$driver->find_element('//div[text()="Netzauswaahl"]', 'xpath')},"found text:\t'Netzauswahl'");

$driver->find_element_ok('//div[text()="Netzauswahl"]', 'xpath',
												 "found text:\t'Netzauswahl'");
$driver->find_element_ok('btn_confirm_network_selection',
												 "found button:\tconfirm selection");
$driver->find_element_ok('btn_cancel_network_selection',
												 "found button:\tcancel selection");

# test own networks grid
my $grid = $driver->find_element('grid_own_networks');
ok($grid, "found grid:\tnetwork");

my @grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');

# check form
my @regex = (
				 '(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)',
				 '(network)|(interface):\.*', 'x|y|z'
);

ok(check_sytax_grid(\@grid_cells, \4, \1, \@regex),
	 "own networks grid looks fine");

# find grid head
my @grid_heads =
		$driver->find_elements(
					'//*[contains(@id, "headercontainer") and contains(@id, "target")]',
					"xpath");
@grid_heads = grep { $_->get_text ne "" } @grid_heads;
my @grid_head_left = $driver->find_child_elements($grid_heads[0],
																									'x-column-header', 'class');
my @grid_head_right = $driver->find_child_elements($grid_heads[1],
																									'x-column-header', 'class');

ok(@grid_head_left,  "found header:\tleft grid");
ok(@grid_head_right, "found header:\tright grid");

ok(is_order_after_change(\$grid, \4, \1, \@grid_head_left, \0),
	 "own networks grid order changes correctly");

# back to standart
$grid_head_left[1]->click;

@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');

my $r_grid = $driver->find_element('//*[contains(@id, "networkresources")]',
																	 'xpath');

ok($r_grid, "found grid:\tnetworkresources");

$driver->find_element_ok('//span[text()="Enthaltene Ressourcen"]',
												 'xpath',
												 "found text:\t'Enthaltene Ressourcen'"
);

# grid should be empty, if no own network is selected
my @resources_grid
		= $driver->find_child_elements($r_grid, 'x-grid-cell', 'class');
ok(!@resources_grid, "no networkresources, if no network is selected");

# select network 'Big' and 'Kunde'
select_by_name(\@grid_cells, \4, \2, \"network:Big");

ok($driver->find_element('x-grid-group-hd', 'class')->get_text
			 =~ /network:Big/,
	 "found group:\tnetwork:Big"
);

my @names
		= ('host:B10', 'host:Range', 'interface:asa.Big', 'interface:u.Big');
ok(grid_cointains(\$r_grid, \3, \1, \@names),
	 "networkresources are corret for network:Big");

$grid_head_right[1]->click;

ok(is_order_after_change(\$r_grid, \3, \0, \@grid_head_right, \1),
	 "resources grid order changes correctly");

select_by_name(\@grid_cells, \4, \2, \"network:Kunde");

ok($driver->find_element('x-grid-group-hd', 'class')->get_text
			 =~ /network:Big/,
	 "found group:\tnetwork:Kunde"
);

# grid should now contain more
push(@names, ('host:k', 'interface:asa.Kunde'));

ok(grid_cointains(\$r_grid, \3, \1, \@names),
	 "networkresources are corret for network:Big and network:Kunde");

# for checking correct syntax
my @res_reg = (
				 '(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)',
				 '(host)|(interface):\.*', 'x|y|z|'
);

# reload grid
@resources_grid
		= $driver->find_child_elements($r_grid, 'x-grid-cell', 'class');
ok(check_sytax_grid(\@resources_grid, \3, \0, \@res_reg),
	 "resources grids looks fine");

$driver->find_child_element($r_grid, '//div[contains(@id, "network:Big")]',
														'xpath')->click;

# grid should now contain less
@names = ('host:k', 'interface:asa.Kunde');

ok(grid_cointains(\$r_grid, \3, \1, \@names),
	 "networkresources are corret while network:Big is collapsed");

$driver->find_element('btn_cancel_network_selection')->click;

ok($driver->find_child_elements($r_grid, 'x-grid-cell', 'class'),
	 "network selection canceled");

my $bont_b
		= $driver->find_element('btn_own_networks_tab')->get_text
		=~ "Eigene Netze"
		and $driver->find_element('btn_own_networks_tab')
		->Selenium::Remote::WebElement::get_attribute('class')
		=~ /icon-computer_connect/;

#should be disabled
my $boncc_b = $driver->find_element('btn_confirm_network_selection')
		->Selenium::Remote::WebElement::get_attribute('class') =~ /x-disabled/;
$boncc_b &= $driver->find_element('btn_cancel_network_selection')
		->Selenium::Remote::WebElement::get_attribute('class') =~ /x-disabled/;

select_by_name(\@grid_cells, \4, \2, \"network:KUNDE1");

#should be enabled
$boncc_b &= !($driver->find_element('btn_confirm_network_selection')
			->Selenium::Remote::WebElement::get_attribute('class') =~ /x-disabled/);
$boncc_b &= !($driver->find_element('btn_cancel_network_selection')
			->Selenium::Remote::WebElement::get_attribute('class') =~ /x-disabled/);

$driver->find_element('btn_confirm_network_selection')->click;

#only confirm should be disabled
$boncc_b &= $driver->find_element('btn_confirm_network_selection')
		->Selenium::Remote::WebElement::get_attribute('class') =~ /x-disabled/;
$boncc_b &= !($driver->find_element('btn_cancel_network_selection')
			->Selenium::Remote::WebElement::get_attribute('class') =~ /x-disabled/);

#'Eigene Netze' should've changed to 'Ausgewählte Netze'
$bont_b
		&= $driver->find_element('btn_own_networks_tab')->get_text
		=~ "Ausgew.hlte Netze"
		and $driver->find_element('btn_own_networks_tab')
		->Selenium::Remote::WebElement::get_attribute('class')
		=~ /icon-exclamation/;

$driver->find_element('btn_services_tab')->click;

$driver->find_element('btn_own_services-btnIconEl')->click;

my @service_grid =
		$driver->find_child_elements($driver->find_element('grid_services'),
																 'x-grid-cell', 'class');

ok((scalar @service_grid == 1 and $service_grid[0]->get_text eq 'Test11'),
	 "found services:\tonly Test11");

$driver->find_element('btn_own_networks_tab')->click;

$driver->find_element('btn_cancel_network_selection')->click;

#should return to standard
$boncc_b &= $driver->find_element('btn_confirm_network_selection')
		->Selenium::Remote::WebElement::get_attribute('class') =~ /x-disabled/;
$boncc_b &= $driver->find_element('btn_cancel_network_selection')
		->Selenium::Remote::WebElement::get_attribute('class') =~ /x-disabled/;
$bont_b
		= $driver->find_element('btn_own_networks_tab')->get_text
		=~ "Eigene Netze"
		and $driver->find_element('btn_own_networks_tab')
		->Selenium::Remote::WebElement::get_attribute('class')
		=~ /icon-computer_connect/;

ok($bont_b, "button own network tab changed name and icon correctly");
ok(
	$boncc_b,
	"buttons confirm and cancel network selection changed disabled status correctly"
);

$driver->find_element('btn_services_tab')->click;

@service_grid =
		$driver->find_child_elements($driver->find_element('grid_services'),
																 'x-grid-cell', 'class');

ok((scalar @service_grid == 12), "found services:\tall 12");

#$driver->move_to_element($driver->find_element('//*[@id="gridcolumn-1071-triggerEl"]', 'xpath'));
#sleep 5;
#$driver->click_element_ok('//*[@id="gridcolumn-1071-triggerEl"]', 'class', 'ok');
#sleep 10;

#for (my $i = 0; $i < @resources_grid; $i++) {
#	print "res($i): " . $resources_grid[$i]->get_text . "\n";
#}

done_testing();
$driver->quit();

sub print_table {
	my ($origin, $empty) = @_;

	my @table = $driver->find_child_elements($origin, './/*', 'xpath');
	print !$empty . "\n";
	if (!$empty) {
		@table = grep { $_->get_text =~ /(.|\s)*\S(.|\s)*/ } @table;
	}
	print "-----\ntable size: " . scalar @table . "\n";
	for (my $i = 0; $i < @table; $i++) {
		print "->\t$i: $table[$i]\n";
		print $table[$i]->get_text . "\n";
	}
	print "\n-----\n";
}

sub select_by_name {
	my @grid_cells = @{ (shift) };
	my $line       = ${ (shift) };
	my $offset     = ${ (shift) };
	my $name       = ${ (shift) };

	for (my $i = $line; $i < @grid_cells; $i += $line) {
		my $a = $grid_cells[ $i + $offset ]->get_text;
		if ($a eq $name) {
			$grid_cells[$i]->click;
			return;
		}
	}
	BAIL_OUT("$name not found");
}

sub grid_cointains {
	my $grid_parent = ${ (shift) };
	my $line        = ${ (shift) };
	my $offset      = ${ (shift) };
	my @search      = @{ (shift) };

	my @grid_cells
			= $driver->find_child_elements($grid_parent, 'x-grid-cell', 'class');

	if (!scalar @grid_cells) {
		print "grid is empty\n";
		return 0;
	}

	for (my $i = 0; $i < @grid_cells; $i += $line) {
		my $ok = 0;
		for (my $j = 0; $j < @search; $j++) {
			if ($grid_cells[ $i + $offset ]->get_text eq $search[$j]) {
				$ok = 1;
			}
		}
		if (!$ok) {
			print "------------\n"
					. $grid_cells[ $i + $offset ]->get_text
					. "\n------------\n";
			return 0;
		}

		#		$ok eq 1 || return 0;
	}
	return 1;
}

sub is_grid_in_order {
	my @grid_cells = @{ (shift) };
	my $line       = ${ (shift) };
	my $order      = ${ (shift) };
	my $column     = ${ (shift) };

	for (my $i = $line; $i < @grid_cells; $i += $line) {

		#		print "i: ".$i."\n";
		my $a = $grid_cells[ $i + $column ]->get_text;
		my $b = $grid_cells[ $i + $column - $line ]->get_text;
		if (($a cmp $b) eq $order) {
			print "('$a' cmp '$b') ne '$order'\n";
			return 0;
		}
	}

	return 1;

}

sub check_sytax_grid {
	my @grid_cells = @{ (shift) };
	my $line       = ${ (shift) };
	my $offset     = ${ (shift) };
	my @regex      = @{ (shift) };

	if (!scalar @grid_cells) {
		print "grid is empty\n";
		return 0;
	}

	for (my $i = $offset; $i < @grid_cells; $i += $line) {
		for (my $j = 0; $j < scalar @regex; $j++) {
			if (!eval { $grid_cells[ $i + $j ]->get_text =~ /$regex[$j]/ }) {
				return 0;
			}
		}
	}
	return 1;
}

# check if order is correct after sorting them
sub is_order_after_change {
	my $grid        = ${ (shift) };
	my $line        = ${ (shift) };
	my $offset      = ${ (shift) };
	my @grid_heads  = @{ (shift) };
	my $head_offset = ${ (shift) };

	# check if order is correct
	# first column
	my @grid_cells
			= $driver->find_child_elements($grid, 'x-grid-cell', 'class');
	is_grid_in_order(\@grid_cells, \$line, \-1, \$offset)
			|| (return 0);
	$grid_heads[ $offset + $head_offset ]->click;

	# grid has to be reloaded
	@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
	is_grid_in_order(\@grid_cells, \$line, \1, \$offset)
			|| (return 0);

	for (my $i = $offset + 1; $i < $line; $i++) {

		$grid_heads[ $i + $head_offset ]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		is_grid_in_order(\@grid_cells, \$line, \-1, \$i)
				|| (return 0);

		$grid_heads[ $i + $head_offset ]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		is_grid_in_order(\@grid_cells, \$line, \1, \$i)
				|| (return 0);
	}

	return 1;
}
