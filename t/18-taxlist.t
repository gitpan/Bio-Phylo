# $Id: 18-taxlist.t 1185 2006-05-26 09:04:17Z rvosa $
use strict;
use warnings;
use Test::More tests => 1;
use Bio::Phylo;
use Bio::Phylo::Parsers::Taxlist;
ok( my $taxlist = Bio::Phylo::Parsers::Taxlist->_new, '1 init obj' );
