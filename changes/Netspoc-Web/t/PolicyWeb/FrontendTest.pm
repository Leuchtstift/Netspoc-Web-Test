
use strict;
use warnings;

package PolicyWeb::FrontendTest;

use base ("Test::Selenium::Remote::Driver");
use parent 'Exporter';    # imports and subclasses Exporter
use Selenium::Waiter qw/wait_until/;
use File::Temp qw/ tempfile tempdir /;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;
use PolicyWeb::Init qw( $port $SERVER);
use Data::Dumper;

our @EXPORT = qw(
        login_as_guest
        select_combobox_item
        get_grid_cell_value
        ip2numeric
        numeric2ip
        error
);

sub find_top_buttons {
    my ($driver) = @_;
    $driver->find_element_ok('btn_services_tab', "found button:\tservices tab");
    $driver->find_element_ok('btn_own_networks_tab', "found button:\town networks tab");
    $driver->find_element_ok('btn_diff_tab', "found button:\tdiff tab");
    $driver->find_element_ok('btn_entitlement_tab', "found button:\tentitlement tab");
    $driver->find_element_ok('//div[text()="Stand"]', 'xpath', "found text:\t'Stand'");

    # historycombo...
    # -> button zum auswaehlen usw
    # "Verantwortungsbereich"
    # ownercombo
    # "Abmelden"
}

# tries to login with given username and password
sub login {
    my ($driver, $name, $pass) = @_;
    return if !$name;

    my $base_url = "http://$SERVER:$port/index.html";
    $driver->get($base_url);

    $driver->find_element('//input[@name="email"]', "xpath");
    $driver->send_keys_to_active_element($name);

    if ($pass) {
        $driver->find_element('//input[@name="pass"]', "xpath")->click;
        $driver->send_keys_to_active_element($pass);
    }

    $driver->find_element('//input[@value="Login"]', "xpath")->click;
}

sub login_as_guest {
    my $driver = shift;
    $driver->login('guest');
}

sub login_as_guest_and_choose_owner {
    my ($driver, $owner) = @_;
    $driver->login_as_guest();

    # The two waits below are necessary to avoid a race condition.
    # Without them, sometimes the combo box has not been rendered
    # yet and an error that "triggerEl of undefined cannot be found"
    # is raised.
    my $window = wait_until { $driver->find_element('win_owner') };
    wait_until { $driver->find_child_element($window, 'combo_initial_owner') };
    $driver->select_combobox_item('combo_initial_owner', $owner);
}

sub get_grid_cell_value_by_field_name {
    my ($driver, $grid_id, $row, $field_name) = @_;
    my $script = "return Ext.getCmp(\"$grid_id\").getStore().getAt($row).get('$field_name');";
    return $driver->execute_script($script);
}

sub get_grid_cell_value_by_row_and_column_index {
    my ($driver, $grid_id, $row, $col) = @_;
    my $script = "return Ext.getCmp(\"$grid_id\").headerCt.columnManager.columns[$col].dataIndex;";
    my $field_name = $driver->execute_script($script);
    return $driver->get_grid_cell_value_by_field_name($grid_id, $row, $field_name);
}

sub select_grid_row_by_index {
    my ($driver, $id, $row_index) = @_;
}

sub select_grid_row_by_content {
    my ($driver, $id, $to_match) = @_;
}

sub select_combobox_item {
    my ($driver, $combo_id, $item) = @_;

    my $combo_query
            = "Ext.ComponentQuery.query(\"combobox[id='$combo_id']\")[0]";
    my $combo_trigger_id = "return " . $combo_query . ".triggerEl.first().id";
    my $dropdown_id      = "return " . $combo_query . ".picker.id";

    my $id_string = $driver->execute_script($combo_trigger_id);

    #$driver->click_element_ok($id_string, 'id', "Clicked on owner combo open trigger");
    $driver->find_element($id_string, 'id')->click;

    my $list_id = $driver->execute_script($dropdown_id);

    #Create a relative xpath to the boundlist item
    my $li = "//div[contains(\@id,'" . $list_id . "')]//li[contains(text(),'" . $item . "')]";

    #Select the dropdown item
    #$driver->click_element_ok($li, 'xpath', "Selected item $item from combo box");
    $driver->find_element($li, 'xpath')->click;
}

sub ip2numeric {

    # Convert IP address to numerical value.

    $_ = shift;

    if (m/\G(\d+)\.(\d+)\.(\d+)\.(\d+)/gc) {
        if ($1 > 255 or $2 > 255 or $3 > 255 or $4 > 255) {
            error("Invalid IP address");
        }
        return unpack 'N', pack 'C4', $1, $2, $3, $4;
    }
    else {
        error("Expected IP address");
    }
}

#
# Convert numerical value into an IP-address.
#
sub numeric2ip {
    my $ip = shift;
    return sprintf "%vd", pack 'N', $ip;
}

sub error {
    print STDERR @_, "\n";
}

# nur zum gucken
sub print_table {
    my ($driver, $origin, $empty) = @_;

    my @table = $driver->find_child_elements($origin, './/*', 'xpath');
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
    my $driver     = shift;
    my @grid_cells = @{ (shift) };
    my $row        = ${ (shift) };
    my $offset     = ${ (shift) };
    my $name       = ${ (shift) };

    for (my $i = $row; $i < @grid_cells; $i += $row) {
        my $a = $grid_cells[ $i + $offset ]->get_text;
        if ($a eq $name) {
            $grid_cells[$i]->click;
            return;
        }
    }
    BAIL_OUT("$name not found");
}

sub grid_contains {
    my $driver      = shift;
    my $grid_parent = ${ (shift) };
    my $row         = ${ (shift) };
    my $offset      = ${ (shift) };
    my @search      = @{ (shift) };

    my @grid_cells
            = $driver->find_child_elements($grid_parent, 'x-grid-cell', 'class');

    if (!scalar @grid_cells) {
        print "grid is empty\n";
        return 0;
    }

    for (my $i = 0; $i < @search; $i++) {
        my $ok = 0;
        for (my $j = 0; $j < @grid_cells; $j += $row) {
            if ($grid_cells[ $j + $offset ]->get_text eq $search[$i]) {
                $ok = 1;
            }
        }
        if (!$ok) {
            print "------------\n"
                    . $search[ $i + $offset ]->get_text
                    . "\n is not equal to any item"
                    . "\n------------\n";
            return 0;
        }

        #       $ok eq 1 || return 0;
    }
    return 1;
}



sub is_grid_in_order {
    my $driver     = shift;
    my @grid_cells = @{ (shift) };
    my $row        = ${ (shift) };
    my $offset     = ${ (shift) };
    my $order      = ${ (shift) };
    my $column     = ${ (shift) };

    for (my $i = $offset; $i < @grid_cells; $i += $row) {

        #       print "i: ".$i."\n";
        my $a = $grid_cells[ $i + $column ]->get_text;
        my $b = $grid_cells[ $i + $column - $row ]->get_text;
        if (($a cmp $b) eq $order) {
            print "('$a' cmp '$b') ne '$order'\n";
            return 0;
        }
    }

    return 1;

}

sub check_sytax_grid {
    my $driver     = shift;
    my @grid_cells = @{ (shift) };
    my $row        = ${ (shift) };
    my $offset     = ${ (shift) };
    my @regex      = @{ (shift) };

    if (!scalar @grid_cells) {
        print "grid is empty\n";
        return 0;
    }

    for (my $i = $offset; $i < @grid_cells; $i += $row) {
        for (my $j = 0; $j < scalar @regex; $j++) {
            if (!eval { $grid_cells[ $i + $j ]->get_text =~ /$regex[$j]/ } ) {
                return 0;
            }
        }
    }
    return 1;
}


# check if order is correct after sorting them
sub is_order_after_change {
    my $driver      = shift;
    my $grid        = ${ (shift) };
    my $row         = ${ (shift) };
    my $column      = ${ (shift) };
    my @grid_heads  = @{ (shift) };
    my $offset      = ${ (shift) };

    # check if order is correct
    # first column
    my @grid_cells
            = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
    $driver->is_grid_in_order(\@grid_cells, \$row, \$row, \-1, \$column)
            || (return 0);
    $grid_heads[ $column + $offset ]->click;

    # grid has to be reloaded
    @grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
    $driver->is_grid_in_order(\@grid_cells, \$row, \$row, \1, \$column)
            || (return 0);

    for (my $i = $column + 1; $i < $row; $i++) {

        $grid_heads[ $i + $offset ]->click;
        @grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
        $driver->is_grid_in_order(\@grid_cells, \$row, \$row, \-1, \$i)
                || (return 0);

        $grid_heads[ $i + $offset ]->click;
        @grid_cells = $driver->find_child_elements($grid, 'x-grid-cell', 'class');
        $driver->is_grid_in_order(\@grid_cells, \$row, \$row, \1, \$i)
                || (return 0);
    }

    return 1;
}

1;
