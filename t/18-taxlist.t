# $Id: 18-taxlist.t 4186 2007-07-11 02:15:56Z rvosa $
use strict;
use warnings;
use Test::More tests => 1;
use Bio::Phylo;
use Bio::Phylo::Parsers::Taxlist;
ok( my $taxlist = Bio::Phylo::Parsers::Taxlist->_new, '1 init obj' );
