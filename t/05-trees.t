# $Id: 05-trees.t,v 1.4 2005/07/31 11:13:51 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 13;
use Bio::Phylo::Parsers;

my $data;
while (<DATA>) {
    $data .= $_;
}

ok( my $phylo = new Bio::Phylo::Parsers );

$phylo->VERBOSE( -level => 0 );

ok( my $trees = $phylo->parse(
    -string => $data,
    -format => 'newick' )
);

ok( $trees->get_by_value(
    -value  => 'calc_tree_length',
    -lt => 15 )
);

ok( ! scalar @{$trees->get_by_value(
    -value => 'calc_tree_length',
    -lt => 1 )}
);

ok( $trees->get_by_value(
    -value => 'calc_tree_length',
    -le => 14 )
);

ok( $trees->get_by_value(
    -value  => 'calc_tree_length',
    -gt => 5 )
);

ok( ! scalar @{$trees->get_by_value(
    -value => 'calc_tree_length',
    -gt => 30 )}
);

ok( $trees->get_by_value(
    -value  => 'calc_tree_length',
    -ge => 14 )
);

ok( ! scalar @{$trees->get_by_value(
    -value => 'calc_tree_length',
    -ge => 30 )}
);

ok( $trees->get_by_value(
    -value => 'calc_tree_length',
    -eq => 14 )
);

ok( !$trees->insert('BAD!') );
ok( $trees->container );
ok( $trees->container_type );

__DATA__
((H:1,I:1):1,(G:1,(F:0.01,(E:0.3,(D:2,(C:0.1,(A:1,B:1)cherry:1):1):1):1):1):1):0;
(H:1,(G:1,(F:1,(E:1,(D:1,(C:1,(A:1,B:1):1):1):1):1):1):1):0;
