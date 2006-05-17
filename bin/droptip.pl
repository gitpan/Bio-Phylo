#!/usr/bin/perl
# $Id: droptip.pl,v 1.4 2005/08/01 23:06:13 rvosa Exp $
# Subversion: $Rev: 145 $
# This script is used to create a subtree from a larger tree. The first
# command line argument is the path to a text file containing a single
# newick tree. The second command line argument is the path to a text
# file containing a list of taxa to keep.
#
# usage:
# perl droptip.pl <tree file> <taxa file>
use strict;
use warnings;
use Bio::Phylo::Parsers;
use Bio::Phylo::Unparsers;
my $parser   = new Bio::Phylo::Parsers;
my $unparser = new Bio::Phylo::Unparsers;
my ( $tree, @taxa );
open( TAXA, $ARGV[1] );

while (<TAXA>) {
    chomp;
    push( @taxa, $_ );
}
close TAXA;
$tree = $parser->parse( -format => 'newick', -file => $ARGV[0] )->first;
$tree->keep_tips( \@taxa );
$tree->get_root->set_branch_length(0.00);
print $unparser->unparse( -phylo => $tree, -format => 'newick' );
