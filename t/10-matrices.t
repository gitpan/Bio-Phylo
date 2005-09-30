# $Id: 10-matrices.t,v 1.10 2005/09/25 21:27:31 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 10;
use Bio::Phylo;
use Bio::Phylo::Matrices;
use Bio::Phylo::Matrices::Matrix;
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Taxa;
use Bio::Phylo::Taxa::Taxon;
ok( my $matrices = new Bio::Phylo::Matrices, '1 initialize obj' );
$matrices->VERBOSE( -level => 0 );

eval { $matrices->insert };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::ObjectMismatch' ), '2 insert empty' );

eval { $matrices->insert('BAD!') };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::ObjectMismatch' ), '3 insert bad' );

ok( $matrices->insert( new Bio::Phylo::Matrices::Matrix ), '4 insert good' );
ok( $matrices->get_entities,                          '5 get matrices' );
ok( ! $matrices->_container,                          '6 container' );
ok( $matrices->_type,                                 '7 container_type' );
my $taxon1 = new Bio::Phylo::Taxa::Taxon;
$taxon1->set_name('taxon1');
my $taxon2 = new Bio::Phylo::Taxa::Taxon;
$taxon2->set_name('taxon2');
my $taxa = new Bio::Phylo::Taxa;
$taxa->insert($taxon1);
$taxa->insert($taxon2);
my $datum1 = new Bio::Phylo::Matrices::Datum;
$datum1->set_name('taxon1');
my $datum3 = new Bio::Phylo::Matrices::Datum;
$datum3->set_name('taxon3');
my $matrix = new Bio::Phylo::Matrices::Matrix;
$matrix->insert($datum1);
$matrix->insert($datum3);
ok( $matrix->cross_reference($taxa), '8 cross ref m -> t' );

eval { $matrix->cross_reference('BAD') };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::ObjectMismatch' ), '9 cross ref m -> t' );

ok(
    $matrix->get_by_regular_expression(
        -value => 'get_name',
        -match => qr/^taxon1$/
    ),
    '10 get by regular expression'
);
