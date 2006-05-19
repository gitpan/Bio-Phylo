# $Id: 00-load.t,v 1.4 2005/07/31 11:13:50 rvosa Exp $
use Test::More tests => 1;

BEGIN {
    use_ok('Bio::Phylo');
}
diag("Testing Bio::Phylo $Bio::Phylo::VERSION, Perl $]");
