# $Id: 02-newick.t,v 1.8 2005/09/27 12:00:33 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 3;
use Bio::Phylo;
use Bio::Phylo::IO qw(parse);

open( my $fh, '>', 'tree.dnd' ) or die "$!";
while (<DATA>) {
    print $fh $_;
}
close $fh;

ok( my $phylo = Bio::Phylo->new, '1 init' );
ok( !Bio::Phylo->VERBOSE( -level => 0 ), '2 set terse' );
ok( Bio::Phylo::IO->parse( -file => 'tree.dnd', -format => 'newick' ), '3 parse' );

unlink 'tree.dnd';

__DATA__
(H:1,(G:1,(F:1,(E:1,(D:1,(C:1,(A:1,B):1):1):1):1):1):1):0;
