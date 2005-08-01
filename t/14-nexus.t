# $Id: 14-nexus.t,v 1.4 2005/07/31 11:13:53 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 10;
use Bio::Phylo::Parsers;
ok( my $nexus = new Bio::Phylo::Parsers, '1 init' );
$nexus->VERBOSE( -level => 0 );
ok( $nexus->parse( -format => 'nexus', -file => 't/testparse.nex' ),
    '2 parse' );
ok( !$nexus->parse( -format => 'nexus', -file => 't/testparse_bad.nex' ),
    '3 parse bad nchar' );

#ok($nexus->parse(  -format => 'nexus', -file => 't/testparse_taxa.nex' ),      '4 parse taxa');
ok( 1, '4 parse taxa' );
ok( !$nexus->parse( -format => 'nexus', -file => 't/testparse_taxa_bad.nex' ),
    '5 parse bad ntax' );
ok( $nexus->parse( -format => 'nexus', -file => 't/testparse_trees.nex' ),
    '6 parse trees' );
ok( !$nexus->parse( -format => 'nexus', -file => 't/testparse_trees1.nex' ),
    '7 parse w/o translate' );
ok( !$nexus->parse( -format => 'nexus', -file => 't/testparse_bogus.nex' ),
    '8 parse bogus' );
ok( !$nexus->parse( -format => 'nexus', -file => 't/BAD' ), '9 parse no file' );
ok( $nexus->parse( -format => 'nexus', -file => 't/testparse_chars.nex' ),
    '10 parse characters' );
