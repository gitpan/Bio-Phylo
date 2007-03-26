use Bio::Phylo::Treedrawer;
use Bio::Phylo::IO;
use Test::More tests => 1;

my $treedrawer = Bio::Phylo::Treedrawer->new(
    -width  => 400,
    -height => 600,
    -shape  => 'CURVY', # curvogram
    -mode   => 'CLADO', # cladogram
    -format => 'SVG'
);

my $tree = Bio::Phylo::IO->parse(
    -format => 'newick',
    -string => '((A,B),C);'
)->first;

$treedrawer->set_tree($tree);
$treedrawer->set_padding(50);

ok( $treedrawer->draw, '1: check drawing from synopsis' );
