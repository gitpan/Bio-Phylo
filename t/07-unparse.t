# $Id: 07-unparse.t,v 1.4 2005/07/31 11:13:51 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 11;
use Bio::Phylo::Unparsers;
use Bio::Phylo::Parsers;

my $data;
while (<DATA>) {
    $data .= $_;
}

my $parser = new Bio::Phylo::Parsers;

ok( my $phylo = new Bio::Phylo::Unparsers, '1 instantiate object' );

ok( my $trees = $parser->parse(
    -string => $data,
    -format => 'newick' ),
'2 parse newick string' );

ok( my $treeset = $trees->get_entities, '3 get trees' );

ok( $phylo->unparse(
    -phylo => $treeset->[0],
    -format => 'newick' ) . "\n",
'4 unparse first tree as newick' );

ok( $phylo->unparse(
    -phylo => $treeset->[1],
    -format => 'newick' ) . "\n",
'5 unparse second tree as newick' );

ok( $phylo->unparse(
    -phylo => $treeset->[0],
    -format => 'pagel' ) . "\n",
'6 unparse first tree as pagel' );

ok( $phylo->unparse(
    -phylo => $treeset->[1],
    -format => 'pagel' ) . "\n",
'7 unparse second tree as pagel' );

my $pagel  = new Bio::Phylo::Unparsers::Pagel;
my $newick = new Bio::Phylo::Unparsers::Newick;

ok( $pagel->container,       '8 get container' );
ok( $pagel->container_type,  '9 get container type' );
ok( $newick->container,      '10 get container' );
ok( $newick->container_type, '11 get container type' );
__DATA__
(H:1,(G:1,(F:1,(E:1,(D:1,(C:1,(A:1,B:1):1):1):1):1):1):1):1;
(((A,B),(C,D,E,F))no_prev,((G,H),(I,J)));
