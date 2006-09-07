# $Id: 15-table.t 1652 2006-07-13 02:08:23Z rvosa $
use strict;
use warnings;
use Test::More tests => 2;
use Bio::Phylo::Parsers::Table;
use Bio::Phylo::IO qw(parse unparse);
Bio::Phylo->VERBOSE( -level => 0 );

ok( 
    my $table = Bio::Phylo::Parsers::Table->_new, 
    '1 init' 
);

my $string = do { local $/; <DATA> };
ok(
    parse(
        -format    => 'table',
        -type      => 'STANDARD',
        -separator => '\t',
        -string    => $string,
    ),
    '2 parse table'
);

__DATA__
taxon_1	1	1	2
taxon_2	2	1	2
taxon_3	2	2	2
taxon_4	1	2	1
taxon_5	2	1	1
taxon_6	1	1	2
taxon_7	1	2	2
taxon_8	1	2	1
taxon_9	1	1	1
taxon_10	2	1	1
