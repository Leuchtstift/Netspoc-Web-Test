
use strict;
use warnings;

use lib 't';
use Test::More;
use Selenium::Remote::Driver;
#use Selenium::Firefox::Profile;
#use Selenium::Remote::WDKeys;
use Selenium::Remote::WebElement;

use Selenium::Waiter;
use Test::Selenium::Remote::Driver;
use PolicyWeb::Init qw/$SERVER $port/;
use PolicyWeb::FrontendTest;

use Data::Dumper;

use Try::Tiny;

# todo:
#	test change password from login screen
# finish own networks


PolicyWeb::Init::prepare_export();
PolicyWeb::Init::prepare_runtime_no_login();

my $base_url = "http://$SERVER:$port";


my $driver = Test::Selenium::Remote::Driver->new(
    browser_name   => 'chrome',
    proxy => {
        proxyType => 'direct',
    },
    base_url       => $base_url,
    default_finder => 'id',
    javascript     => 1,
    );

#$driver->debug_on();


$driver->get( 'index.html' );

if (find_login()){
	# wrong user data

	login('not_guest', 'password');
	
	ok($driver->get_current_url() =~ /backend\/login/ , "refused false login credentials");
	
	$driver->go_back();

	login("guest");
	ok($driver->get_page_source() =~ /Fehler/ == 0, "successfully logged in as guest");

	choose_owner('x');
	

#	if (find_top_buttons()) {own_networks();}
}

done_testing();


#eval { for(;;) { print $driver->get_active_element()->get_attribute('id')."\n"; sleep 1; } } or do { print "browser closed\n"; };

$driver->quit();



# checks if elements needed to login are present.
# return 1, if true.
sub find_login {
	my $a = $driver->find_element_ok( '//input[@name="email"]', "xpath", "found input box:	email" );
	my $b = $driver->find_element_ok( '//input[@name="pass"]', "xpath", "found input box:	password" );
	my $c = $driver->find_element_ok( '//input[@value="Login"]', "xpath", "found button:	login");
	return $a && $b && $c; 
}


# tries to login with given username and password
sub login{
	my ($name, $pass) = @_;
	return if !$name;

	my $mailField = $driver->find_element('//input[@name="email"]', "xpath");
	$mailField->clear();
	$driver->send_keys_to_active_element($name);

	if($pass){
		$driver->find_element('//input[@name="pass"]', "xpath") -> click;
		$driver->send_keys_to_active_element($pass);
	}

	$driver->find_element('//input[@value="Login"]', "xpath") -> click;
}


sub choose_owner{
	my ($owner) = @_;
	my $window = wait_until { $driver->find_element( 'win_owner' ) };
	wait_until { $driver->find_child_element( $window, 'combo_initial_owner' ) };
  $driver->PolicyWeb::FrontendTest::select_combobox_item( 'combo_initial_owner', $owner );
}

sub find_top_buttons{
	$driver->find_element_ok('btn_services_tab', "found button:	services tab");
	$driver->find_element_ok('btn_own_networks_tab', "found button:	own networks tab");
	$driver->find_element_ok('btn_diff_tab', "found button:	diff tab");
	$driver->find_element_ok('btn_entitlement_tab', "found button:	entitlement tab");

	# "Stand"
	# historycombo...
	# -> button zum auswaehlen usw
	# "Verantwortungsbereich"
	# ownercombo
	# "Abmelden"
}

sub own_networks{
	my $b_own_networks = $driver->find_element('btn_own_networks_tab');
	$b_own_networks->click;

	#Netzauswahl
	$driver->find_element_ok('btn_confirm_network_selection', "found button:	confirm selection");
	$driver->find_element_ok('btn_cancel_network_selection', "found button:	cancel selection");

	# test own networks grid
	my $grid = $driver->find_element('grid_own_networks');
	if (ok($grid, "found grid:	network")){

		my @grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		my $grid_ok = 1;
 
 		# check form
		for (my $i=0; $i<@grid_cells; $i+=4){
			my $line = "$i: ".$grid_cells[$i+1]->get_text.',	'.$grid_cells[$i+2]->get_text.',	'.$grid_cells[$i+3]->get_text;
			# ip address
			$grid_ok &= ($grid_cells[$i+1]->get_text =~ /(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)\.(1\d\d|\d\d|\d)/);
			# network name
			$grid_ok &= ($grid_cells[$i+2]->get_text =~ /(network)|(interface):\.*/);
			# owner
			$grid_ok &= ($grid_cells[$i+3]->get_text =~ /x|y|z/);
		}

		# find grid head
		my @grid_heads = $driver->find_elements('//*[contains(@id, "headercontainer") and contains(@id, "target")]', "xpath");
		@grid_heads = grep { $_->get_text ne ""} @grid_heads;
		my @grid_head_left 	= $driver->find_child_elements($grid_heads[0], 'x-column-header', 'class');
		my @grid_head_right = $driver->find_child_elements($grid_heads[1], 'x-column-header', 'class');
		
		ok(@grid_head_left, "found:		left grid head");
		ok(@grid_head_right, "found:		right grid head");

		# check if order is correct
		# first column
		$grid_ok &= is_grid_in_order(\@grid_cells, \4, \-1, \1);
		$grid_head_left[1]->click;
		# reload grid
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		$grid_ok &= is_grid_in_order(\@grid_cells, \4, \1, \1);

		# second column
		$grid_head_left[2]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		$grid_ok &= is_grid_in_order(\@grid_cells, \4, \-1, \2);
		$grid_head_left[2]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		$grid_ok &= is_grid_in_order(\@grid_cells, \4, \1, \2);

		# third column
		$grid_head_left[3]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		$grid_ok &= is_grid_in_order(\@grid_cells, \4, \-1, \3);
		$grid_head_left[3]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
		$grid_ok &= is_grid_in_order(\@grid_cells, \4, \1, \3);

		ok($grid_ok, "grid_own_networks looks fine");
		
		# back to standart
		$grid_head_left[1]->click;
		@grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');

		# find grid for network resources
		my $r_grid = $driver->find_element('//*[contains(@id, "networkresources")]', 'xpath');
		if(ok($r_grid, "found grid:	networkresources")){
			# grid should be empty, if no own network is selected
			my @resources_grid = $driver->find_child_elements($r_grid, 'x-grid-cell', 'class');
			ok(!@resources_grid, "no networkresources, if no network is selected");
			
			# select network 'Big' and 'Kunde'
			if (select_by_name(\@grid_cells, \4, \"network:Big") && select_by_name(\@grid_cells, \4, \"network:Kunde")){
				for (my $i = 0; $i < @resources_grid; $i++){
				#	print "res($i): ".$resources_grid[$i]->get_text."\n";
				}
			}
		}
	}
}

# Beispiel für Resourcen-Gruppe:
# class="x-grid-groupe-title" style>Network:Big (4 Elemente)



sub select_by_name{
	my @grid_cells = @{(shift)};
	my $offset = ${(shift)};
	my $name = ${(shift)};

	for (my $i = $offset; $i<@grid_cells; $i+=$offset){
		my $a = $grid_cells[$i+2]->get_text;
		if ($a eq $name){ 			
			$grid_cells[$i]->click;
			return 1;
		}
	}
	return 0;
}


sub is_grid_in_order{
	my @grid_cells = @{(shift)};
	my $offset = ${(shift)};
	my $order = ${(shift)};
	my $column = ${(shift)}; 
	
	for (my $i = $offset; $i<@grid_cells; $i+=$offset){
#		print "i: ".$i."\n";
		my $a = $grid_cells[$i+$column]->get_text;
		my $b = $grid_cells[$i+$column-$offset]->get_text;
		if (($a cmp $b) eq $order) {return 0}
	}

	return 1;

}

