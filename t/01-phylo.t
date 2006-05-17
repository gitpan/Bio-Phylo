# $Id: 01-phylo.t,v 1.4 2005/07/31 11:13:50 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 4;
use Bio::Phylo;
my $data;
while (<DATA>) {
    $data .= $_;
}
ok( my $phylo = new Bio::Phylo,          '1 init' );
ok( !Bio::Phylo->VERBOSE( -level => 0 ), '2 set terse' );
ok( $phylo->VERSION,                     '3 version number' );
ok( $phylo->CITATION,                    '4 citation' );
__DATA__
(H:1,(G:1,(F:1,(E:1,(D:1,(C:1,(A:1,B:1):1):1):1):1):1):1):0;
(H:1,(G:1,(F:1,((C:1,(A:1,B:1):1):1,(D:1,E:1):1):1):1):1):0;
