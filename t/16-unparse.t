# $Id: 16-unparse.t,v 1.3 2005/07/22 00:46:32 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 4;
use Bio::Phylo::Unparsers;
Bio::Phylo->VERBOSE( -level => 0 );
ok( !Bio::Phylo::Unparsers->unparse() );
ok( !Bio::Phylo::Unparsers->unparse( 'A', 'B', 'C' ) );
ok( !Bio::Phylo::Unparsers->unparse( -format => 'bogus', -phylo => 'bogus' ) );
ok( !Bio::Phylo::Unparsers->unparse( -tokkie => 'bogus', -phylo => 'bogus' ) );
