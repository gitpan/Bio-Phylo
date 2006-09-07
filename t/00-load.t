# $Id: 00-load.t 1185 2006-05-26 09:04:17Z rvosa $
use Test::More tests => 1;

BEGIN {
    use_ok('Bio::Phylo');
}
diag("Testing Bio::Phylo $Bio::Phylo::VERSION, Perl $]");
