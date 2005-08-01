# $Id: 17-parse.t,v 1.4 2005/07/31 11:13:54 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 6;
use Bio::Phylo::Parsers;
my $parser = new Bio::Phylo::Parsers;
$parser->VERBOSE( -level => 0 );
ok( !$parser->parse(), '1 parse no opts' );
ok( !$parser->parse( 'A', 'B', 'C' ), '2 parse wrong args' );
ok( !$parser->parse( -format => 'none' ), '3 parse bad format' );
ok( !$parser->parse( -format => 'nexus', -string => 'blah' ),
    '4 parse cannot string' );
ok( !$parser->parse( -string => 'blah' ), '5 parse no format' );
ok( $parser->parse( -format => 'taxlist', -file => 't/taxa.dat' ),
    '6 parse taxon list' );
