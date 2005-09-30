# $Id: 17-parse.t,v 1.8 2005/09/27 12:00:34 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 6;
use Bio::Phylo::IO qw(parse unparse);

eval { parse() };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::OddHash' ), '1 parse no opts' );

eval { parse( 'A', 'B', 'C' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::OddHash' ), '2 parse wrong args' );

eval { parse( -format => 'none' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::BadArgs' ), '3 parse bad format' );

eval { parse( -format => 'nexus', -string => 'blah' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::BadArgs' ),
    '4 parse cannot string' );

eval { parse( -string => 'blah' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::BadArgs' ), '5 parse no format' );

ok( parse( -format => 'taxlist', -file => 't/taxa.dat' ),
    '6 parse taxon list' );
