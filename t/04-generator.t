# $Id: 04-generator.t,v 1.6 2005/09/20 13:22:53 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 16;    #iterating over 10 generated trees
use Bio::Phylo;
use Bio::Phylo::Generator;

ok( my $gen = new Bio::Phylo::Generator, '1 init' );

Bio::Phylo::Generator->VERBOSE( -level => 0 );

ok( $gen->gen_rand_pure_birth(
    -model => 'yule',
    -tips => 10,
    -trees => 10 ),
'2 gen yule' );

ok( $gen->gen_rand_pure_birth(
    -model => 'hey',
    -tips => 10,
    -trees => 10 ),
'3 gen hey' );

ok( $gen->gen_exp_pure_birth(
    -model => 'yule',
    -tips => 10,
    -trees => 10 ),
'4 gen yule' );

ok( $gen->gen_exp_pure_birth(
    -model => 'hey',
    -tips => 10,
    -trees => 10 ),
'5 gen hey' );

eval {
   $gen->gen_exp_pure_birth( -model => 'dummy', -tips => 10, -trees => 10 )
};
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::BadFormat' ),
'6 ! gen' );

eval {
   $gen->gen_rand_pure_birth( -model => 'dummy', -tips => 10, -trees => 10 )
};
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::BadFormat' ),
'7 ! gen' );

ok( my $trees = $gen->gen_equiprobable(
    -tips => 32,
    -trees => 5 ),
'8 gen tree' );

my @trees = @{ $trees->get_entities };
my $tree  = shift(@trees);
my @n     = @{ $tree->get_entities };
my ( $node1, $node2, $node3 );

while (1) {
    ( $node1, $node2, $node3 ) = (
        $n[ rand( scalar @n ) ],
        $n[ rand( scalar @n ) ],
        $n[ rand( scalar @n ) ]
    );
    last if $node1->is_internal && $node2->is_internal && $node3->is_internal;
}
my $root  = $tree->get_root;
my $lmt   = $root->get_leftmost_terminal;
my $newbl = $lmt->get_branch_length;
$newbl *= 10;
$lmt->set_branch_length($newbl);
ok( $node1->calc_min_path_to_tips,  '9  cmptt' );
ok( $node2->calc_min_path_to_tips,  '10 cmptt' );
ok( $node3->calc_min_path_to_tips,  '11 cmptt' );
ok( $node1->calc_min_nodes_to_tips, '12 cmptt' );
ok( $node2->calc_min_nodes_to_tips, '13 cmptt' );
ok( $node3->calc_min_nodes_to_tips, '14 cmptt' );
$lmt->set_branch_length();
ok( $root->calc_max_path_to_tips, '15 cmaxptt' );
ok( $gen->DESTROY,                '16 destroy' );
