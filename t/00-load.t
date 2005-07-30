# $Id: 00-load.t,v 1.3 2005/07/22 00:46:29 rvosa Exp $
use Test::More tests => 1;

BEGIN {
    use_ok('Bio::Phylo');
}
diag("Testing Bio::Phylo $Bio::Phylo::VERSION, Perl $]");
