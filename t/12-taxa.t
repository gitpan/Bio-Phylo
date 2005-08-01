# $Id: 12-taxa.t,v 1.4 2005/07/31 11:13:52 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 4;
use Bio::Phylo::Taxa;
ok( my $taxa = new Bio::Phylo::Taxa, '1 initialize object' );
$taxa->VERBOSE( -level => 0 );
ok( !$taxa->insert('Bad!'), '2 insert bad object' );
ok( $taxa->container,       '3 container' );
ok( $taxa->container_type,  '4 container_type' );
