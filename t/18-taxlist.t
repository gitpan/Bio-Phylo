# $Id: 18-taxlist.t,v 1.6 2005/09/27 12:00:34 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 1;
use Bio::Phylo;
use Bio::Phylo::Parsers::Taxlist;
ok( my $taxlist = Bio::Phylo::Parsers::Taxlist->_new, '1 init obj' );
