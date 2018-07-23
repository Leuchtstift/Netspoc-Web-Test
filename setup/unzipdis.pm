#!/usr/bin/env perl
use Archive::Extract;
foreach my $filepath (@ARGV){
    my $archive = Archive::Extract->new( archive => $filepath );
    $archive->extract;
}