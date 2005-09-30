# $Id: 12-taxa.t,v 1.9 2005/09/25 21:27:31 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 4;
use Bio::Phylo::Taxa;
ok( my $taxa = new Bio::Phylo::Taxa, '1 initialize object' );
$taxa->VERBOSE( -level => 0 );

eval { $taxa->insert('Bad!') };
ok( UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::ObjectMismatch' ), '2 insert bad object' );

ok( ! $taxa->_container,    '3 container' );
ok( $taxa->_type,           '4 container_type' );
