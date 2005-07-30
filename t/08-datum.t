# $Id: 08-datum.t,v 1.3 2005/07/22 00:46:31 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 37;
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Taxa::Taxon;
use Bio::Phylo::Trees;
ok( my $datum = new Bio::Phylo::Matrices::Datum, '1 initialize' );
$datum->VERBOSE( -level => 0 );

# the name method
ok( !$datum->set_name(':'), '2 bad name' );
ok( $datum->set_name('OK'), '3 good name' );
ok( $datum->get_name,       '4 retrieve name' );

# the node method
ok( !$datum->set_taxon('BAD!'),                  '5 bad node ref' );
ok( !$datum->set_taxon( new Bio::Phylo::Trees ),      '6 bad node ref' );
ok( $datum->set_taxon( new Bio::Phylo::Taxa::Taxon ), '7 good node ref' );
ok( $datum->get_taxon,                           '8 retrieve node ref' );

# the desc method
ok( $datum->set_desc('OK'), '9 set desc' );
ok( $datum->get_desc, '10 get desc' );

# the weight method
ok( !$datum->set_weight('BAD!'), '11 bad weight' );
ok( $datum->set_weight(1),       '12 good weight' );
ok( $datum->get_weight,          '13 retrieve weight' );

# char w/o type
ok( !$datum->set_char('A'), '14 char without type' );

# the type method
ok( !$datum->set_type('BAD!'), '15 bad type' );
ok( $datum->set_type('DNA'),   '16 good type' );
ok( $datum->get_type,          '17 retrieve type' );

# testing char types
$datum->set_type('DNA');
ok( $datum->set_char('A'), '18 good DNA' );
ok( !$datum->set_char('I'), '19 bad DNA' );
$datum->set_type('RNA');
ok( $datum->set_char('A'), '20 good RNA' );
ok( !$datum->set_char('I'), '21 bad RNA' );
$datum->set_type('STANDARD');
ok( $datum->set_char('1'), '22 good STANDARD' );
ok( !$datum->set_char('B'), '23 bad STANDARD' );
$datum->set_type('PROTEIN');
ok( $datum->set_char('A'), '24 good PROTEIN' );
ok( !$datum->set_char('J'), '25 bad PROTEIN' );
$datum->set_type('NUCLEOTIDE');
ok( $datum->set_char('A'), '26 good NUCLEOTIDE' );
ok( !$datum->set_char('I'), '27 bad NUCLEOTIDE' );
$datum->set_type('CONTINUOUS');
ok( $datum->set_char('-1.43345e+34'), '28 good CONTINUOUS' );
ok( !$datum->set_char('B'),           '29 bad CONTINUOUS' );
ok( $datum->get_char,                 '30 retrieve character' );

# the position method
ok( !$datum->set_position('BAD!'), '31 bad weight' );
ok( $datum->set_position(1),       '32 good weight' );
ok( $datum->get_position,          '33 retrieve weight' );

# the get method
ok( !$datum->get('frobnicate'), '34 bad get' );
ok( $datum->get('get_type'),    '35 good get' );
ok( $datum->container,          '36 container' );
ok( $datum->container_type,     '37 container type' );
