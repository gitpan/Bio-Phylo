# $Id: 18-taxlist.t,v 1.4 2005/07/31 11:13:54 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 3;
use Bio::Phylo;
use Bio::Phylo::Parsers::Taxlist;
ok( my $taxlist = new Bio::Phylo::Parsers::Taxlist, '1 init obj' );
ok( $taxlist->container,      '2 get container' );
ok( $taxlist->container_type, '3 get container type' );
