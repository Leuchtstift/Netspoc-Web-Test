
use strict;
use warnings;

use lib 't';
use Test::More;
use Selenium::Remote::Driver;
use Selenium::Remote::WebElement;
use Selenium::Waiter;
use Test::Selenium::Remote::Driver;
use PolicyWeb::Init qw/$SERVER $port/;
use PolicyWeb::FrontendTest;
use Data::Dumper;
use Try::Tiny;

PolicyWeb::Init::prepare_export();
PolicyWeb::Init::prepare_runtime_no_login();

my $driver =
		PolicyWeb::FrontendTest->new(
														 browser_name   => 'chrome',
														 proxy          => { proxyType => 'direct', },
														 default_finder => 'id',
														 javascript     => 1,
														 base_url => "http://$SERVER:$port/index.html",
														 extra_capabilities => { nativeEvents => 'false' }
		);

$driver->login_as_guest_and_choose_owner('x');

if (find_top_buttons()) { own_networks(); }

done_testing();

$driver->quit();

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

sub choose_owner {
	my ($owner) = @_;
	my $window = wait_until { $driver->find_element('win_owner') };
	wait_until {
		$driver->find_child_element($window, 'combo_initial_owner')
	};
	$driver->PolicyWeb::FrontendTest::select_combobox_item(
																												'combo_initial_owner',
																												$owner);
}

sub find_top_buttons {
	$driver->find_element_ok('btn_services_tab', "found button:\tservices tab");
	$driver->find_element_ok('btn_own_networks_tab',
													 "found button:\town networks tab");
	$driver->find_element_ok('btn_diff_tab', "found button:\tdiff tab");
	$driver->find_element_ok('btn_entitlement_tab',
													 "found button:\tentitlement tab");

	$driver->find_element_ok('//div[text()="Stand"]', 'xpath', "found text:\t'Stand'");

	# historycombo...
	# -> button zum auswaehlen usw
	# "Verantwortungsbereich"
	# ownercombo
	# "Abmelden"
}

sub own_networks {
	my $b_own_networks = $driver->find_element('btn_own_networks_tab');
	$b_own_networks->click;

	#Netzauswahl
	$driver->find_element_ok('btn_confirm_network_selection',
													 "found button:\tconfirm selection");
	$driver->find_element_ok('btn_cancel_network_selection',
													 "found button:\tcancel selection");

	# test own networks grid
	my $grid = $driver->find_element('grid_own_networks');
	if (ok($grid, "found grid:\tnetwork")) {

		my @grid_cells
				= $driver->find_child_elements($grid, 'x-grid-cell', 'class');

		# check form
		my @regex = (
				 '(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)',
				 '(network)|(interface):\.*', 'x|y|z'
		);

		ok(check_sytax_grid(\@grid_cells, \4, \1, \@regex),
			 "own networks grids looks fine");

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

		ok(@grid_head_left,  "found grid:\tleft head");
		ok(@grid_head_right, "found grid:\tright head");

		ok(is_order_after_change(\$grid, \4, \1, \@grid_head_left),
			 "own networks grid order changes correctly");

		# back to standart
		$grid_head_left[1]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');

		# find grid for network resources
		my $r_grid =
				$driver->find_element('//*[contains(@id, "networkresources")]',
															'xpath');
		if (ok($r_grid, "found grid:\tnetworkresources")) {

			# grid should be empty, if no own network is selected
			my @resources_grid
					= $driver->find_child_elements($r_grid, 'x-grid-cell', 'class');
			ok(!@resources_grid, "no networkresources, if no network is selected");

			# select network 'Big' and 'Kunde'
			if (   select_by_name(\@grid_cells, \4, \2, \"network:Big")
					&& select_by_name(\@grid_cells, \4, \2, \"network:Kunde"))
			{
				@resources_grid
						= $driver->find_child_elements($r_grid, 'x-grid-cell', 'class');

				my @res_reg = (
					'(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)',
					'(host)|(interface):\.*', 'x|y|z|'
				);
				print check_sytax_grid(\@resources_grid, \3, \0, \@res_reg) . "\n";

				#for (my $i = 0; $i < @resources_grid; $i++) {
				#	print "res($i): " . $resources_grid[$i]->get_text . "\n";
				#}
			}
		}
	}
}

# Beispiel für Resourcen-Gruppe:
# class="x-grid-groupe-title" style>Network:Big (4 Elemente)

sub select_by_name {
	my @grid_cells = @{ (shift) };
	my $line       = ${ (shift) };
	my $offset     = ${ (shift) };
	my $name       = ${ (shift) };

	for (my $i = $line; $i < @grid_cells; $i += $line) {
		my $a = $grid_cells[ $i + $offset ]->get_text;
		if ($a eq $name) {
			$grid_cells[$i]->click;
			return 1;
		}
	}
	return 0;
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
		if (($a cmp $b) eq $order) { return 0 }
	}

	return 1;

}

sub check_sytax_grid {
	my @grid_cells = @{ (shift) };
	my $line       = ${ (shift) };
	my $offset     = ${ (shift) };
	my @regex      = @{ (shift) };

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
	my $grid       = ${ (shift) };
	my $line       = ${ (shift) };
	my $offset     = ${ (shift) };
	my @grid_heads = @{ (shift) };

	# check if order is correct
	# first column
	my @grid_cells
			= $driver->find_child_elements($grid, 'x-grid-cell', 'class');
	is_grid_in_order(\@grid_cells, \$line, \-1, \$offset)
			|| (return 0);

	$grid_heads[$offset]->click;

	# grid has to be reloaded
	@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
	is_grid_in_order(\@grid_cells, \$line, \1, \$offset)
			|| (return 0);

	for (my $i = $offset + 1; $i < $line; $i++) {

		$grid_heads[$i]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		is_grid_in_order(\@grid_cells, \$line, \-1, \$i)
				|| (return 0);

		$grid_heads[$i]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		is_grid_in_order(\@grid_cells, \$line, \1, \$i)
				|| (return 0);
	}

	return 1;
}
