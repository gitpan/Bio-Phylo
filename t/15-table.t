# $Id: 15-table.t,v 1.7 2005/09/27 12:00:33 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 2;
use Bio::Phylo::Parsers::Table;
use Bio::Phylo::IO qw(parse unparse);
Bio::Phylo->VERBOSE( -level => 0 );
ok( my $table = Bio::Phylo::Parsers::Table->_new, '1 init' );
ok(
    parse(
        -format    => 'table',
        -type      => 'STANDARD',
        -separator => '\t',
        -file      => 't/data.dat'
    ),
    '2 parse table'
);
