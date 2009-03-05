# $Id: 18-taxlist.t 838 2009-03-04 20:47:20Z rvos $
use strict;
#use warnings;
use Test::More tests => 1;
use Bio::Phylo;
use Bio::Phylo::Parsers::Taxlist;
ok( my $taxlist = Bio::Phylo::Parsers::Taxlist->_new, '1 init obj' );
