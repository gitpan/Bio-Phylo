# $Id: 15-table.t,v 1.3 2005/07/22 00:46:32 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 4;
use Bio::Phylo::Parsers;
use Bio::Phylo::Parsers::Table;
Bio::Phylo->VERBOSE( -level => 0 );
ok( my $table = new Bio::Phylo::Parsers::Table, '1 init' );
ok( $table->container,      '2 get container' );
ok( $table->container_type, '3 get container type' );
my $parser = new Bio::Phylo::Parsers;
ok(
    $parser->parse(
        -format    => 'table',
        -type      => 'STANDARD',
        -separator => '\t',
        -file      => 't/data.dat'
    ),
    '4 parse table'
);
