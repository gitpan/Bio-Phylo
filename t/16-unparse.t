# $Id: 16-unparse.t,v 1.8 2006/02/21 00:23:01 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 4;
use Bio::Phylo::IO qw(parse unparse);
Bio::Phylo->VERBOSE( -level => 0 );

eval { unparse() };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Util::Exceptions::OddHash' ) );

eval { unparse( 'A', 'B', 'C' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Util::Exceptions::OddHash' ) );

eval { unparse( -format => 'bogus', -phylo => 'bogus' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Util::Exceptions::ExtensionError' ) );

eval { unparse( -tokkie => 'bogus', -phylo => 'bogus' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Util::Exceptions::BadFormat' ) );
