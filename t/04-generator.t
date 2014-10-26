# $Id: 04-generator.t,v 1.8 2006/02/23 07:54:41 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 9;
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

eval { $gen->gen_exp_pure_birth( -model => 'dummy', -tips => 10, -trees => 10 ); };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Util::Exceptions::BadFormat' ), '6 ! gen' );

eval { $gen->gen_rand_pure_birth( -model => 'dummy', -tips => 10, -trees => 10 ); };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Util::Exceptions::BadFormat' ), '7 ! gen' );

ok( my $trees = $gen->gen_equiprobable( -tips => 32, -trees => 5 ),  '8 gen tree' );

ok( $gen->DESTROY,                                                   '9 destroy' );
