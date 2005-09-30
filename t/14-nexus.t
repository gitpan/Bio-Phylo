# $Id: 14-nexus.t,v 1.7 2005/09/27 12:00:33 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 5;
use Bio::Phylo::IO qw(parse unparse);

eval { parse( -format => 'nexus', -file => 't/testparse.nex' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::BadString' ), 'test 1' );

eval { parse( -format => 'nexus', -file => 't/testparse_bad.nex' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::BadFormat' ), 'test 2' );

eval { parse( -format => 'nexus', -file => 't/testparse_taxa_bad.nex' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::BadFormat' ), 'test 3' );

ok( parse( -format => 'nexus', -file => 't/testparse_trees.nex' ), 'test 4' );

eval { parse( -format => 'nexus', -file => 't/BAD' ) };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::FileError' ), 'test 5' );
