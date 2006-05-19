#!/usr/bin/perl
# $Id: dnd2svg.pl,v 1.4 2005/08/01 23:06:12 rvosa Exp $
# Subversion: $Rev: 145 $
# This script draws the newick tree description in the input file as a
# scalable vector drawing.
#
# usage:
# perl dnd2svg.pl <tree file>
use strict;
use warnings;
use Bio::Phylo::Parsers;
use Bio::Phylo::Unparsers;
my $parser   = new Bio::Phylo::Parsers;
my $unparser = new Bio::Phylo::Unparsers;
my $tree     = $parser->parse( -format => 'newick', -file => $ARGV[0] )->first;
my $svg      = $unparser->unparse(
    -format      => 'svg',
    -height      => ( ( ( $tree->calc_number_of_terminals + 2 ) * 25 ) + 50 ),
    -width       => 500,
    -node_radius => 1,
    -mode        => 'PHYLO',
    -padding     => 50,
    -text_horiz_offset => 6,
    -text_vert_offset  => 4,
    -text_width        => 150,
    -shape             => 'CURVY',
    -phylo             => $tree
);
print $svg;
