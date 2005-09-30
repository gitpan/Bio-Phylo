# $Id: 13-listable.t,v 1.7 2005/09/20 13:22:54 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 7;
use Bio::Phylo;
use Bio::Phylo::Taxa;
use Bio::Phylo::Taxa::Taxon;
use Bio::Phylo::Forest;
use Bio::Phylo::Forest::Tree;
ok( my $listable = new Bio::Phylo::Listable, '1 initialize object' );
my $trees = new Bio::Phylo::Forest;
$trees->VERBOSE( -level => 0 );
my $tree = new Bio::Phylo::Forest::Tree;
$trees->insert($tree);
my $taxa  = new Bio::Phylo::Taxa;
my $taxon = new Bio::Phylo::Taxa::Taxon;
$taxa->insert($taxon);

eval { $trees->cross_reference($taxa) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::ObjectMismatch' ), '2 bad crossref' );

eval { $taxa->cross_reference($taxa) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::ObjectMismatch' ),  '3 bad crossref' );

eval { $taxa->insert($tree) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::ObjectMismatch' ),'4 insert obj bad' );

ok( $trees->first,                   '5 get first tree' );
ok( $trees->last,                    '6 get last tree' );
ok( $tree->cross_reference($taxa),   '7 good crossref' );
