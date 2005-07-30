# $Id: 02-newick.t,v 1.3 2005/07/22 00:46:29 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 6;
use Bio::Phylo;
use Bio::Phylo::Parsers;
open( TEMP, '>tree.dnd' );
while (<DATA>) {
    print TEMP $_;
}
close TEMP;
ok( my $phylo = new Bio::Phylo::Parsers, '1 init' );
ok( !Bio::Phylo->VERBOSE( -level => 0 ), '2 set terse' );
ok( !$phylo->parse( -file => '--> error OK here! <--', -format => 'newick' ),
    '3 parse' );
ok( $phylo->parse( -file => 'tree.dnd', -format => 'newick' ), '4 parse' );
my $newick = new Bio::Phylo::Parsers::Newick;
ok( $newick->container );
ok( $newick->container_type );
unlink 'tree.dnd';
__DATA__
(H:1,(G:1,(F:1,(E:1,(D:1,(C:1,(A:1,B):1):1):1):1):1):1):0;

