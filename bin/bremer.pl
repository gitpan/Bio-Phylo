#!/usr/bin/perl
# $Id: bremer.pl 3394 2007-03-26 17:22:28Z rvosa $
# Subversion: $Rev: 145 $
use strict;
use warnings;
my ( $node, $percentage, $iterations, $nchar, $treefile );
foreach (@ARGV) {
    s/-(.)//;
    $node       = $_ if $1 eq "l";
    $percentage = $_ if $1 eq "p";
    $iterations = $_ if $1 eq "i";
    $nchar      = $_ if $1 eq "n";
    $treefile   = $_ if $1 eq "f";
    if ( $1 eq "h" ) {
        print qq{usage: perl bremer.pl -f<treefile>\n};
        print qq{                      -l<nodelabel>\n};
        print qq{                      -p<% of chars to reweight>\n};
        print qq{                      -i<number of iterations>\n};
        print qq{                      -n<number of characters>\n};
        print qq{                      -h<this message>\n};
        exit;
    }
}
open( TREEFILE, $treefile ) || die "Could not open tree file\n";
my @trees = (<TREEFILE>);
close(TREEFILE);
foreach (@trees) {
    print qq{[starting new tree]\n};
    print qq{#nexus\n};
    print qq{begin paup;\n};
    print qq{[**** starting commands ****]\n};
    print qq{[!*************************************];\n};
    print qq{[!* --------- Bremer Ratchet -------- *];\n};
    print qq{[!*             Rutger Vos            *];\n};
    print qq{[!*      Simon Fraser University      *];\n};
    print qq{[!*             May, 2003             *];\n};
    print qq{[!* Based on Kevin Nixon's Parsimony  *];\n};
    print qq{[!* Ratchet as described in: Nixon,   *];\n};
    print qq{[!* K. C. 1999. The Parsimony Ratchet *];\n};
    print qq{[!* a new method for rapid parsimony  *];\n};
    print qq{[!* analysis. Cladistics 15: 407-414. *];\n};
    print qq{[!*************************************];\n};
    print qq{log file=paupratchet.log;\n};
    print qq{set increase=auto;\n};
    print qq{set warntree=no;\n};
    print qq{set warnreset=no;\n};
    chomp;
    my $tree = $_;
    my @nodes;
    my @all = split(/[,|(+|)+|;]/);
    foreach (@all) { push( @nodes, $_ ) if /$node\d+/; }

    foreach (@nodes) {
        my ( $subtree, $brackets, $current, $clade ) = ( $tree, 0, $_, "" );
        $subtree =~ s/$_[,|\)].*$//;
        print qq{[!Exclusion commands for $current]\n};
        my $x = length($subtree);
        do {
            $x--;
            $brackets++ if substr( $subtree, $x, 1 ) eq "(";
            $brackets-- if substr( $subtree, $x, 1 ) eq ")";
            $clade = substr( $subtree, $x, 1 ) . $clade;
        } until $brackets == 0;
        my @taxa;
        @all = split( /[,|(+|)+|;]/, $clade );
        foreach (@all) { push( @taxa, $_ ) unless /$node\d+/ or /^$/; }
        $" = ",";
        print "constraints $current (monophyly) = ((@taxa));\n";
        $" = " ";
        print
qq{hsearch status=no enforce=yes constraints=$current timelimit=90 converse=yes nrep=1 swap=tbr start=stepwise addseq=random nchuck=1 chuckscore=1;\n};
        print qq{savetrees file=mydata.tre replace;\n};
        print qq{savetrees file=mydata.tmp replace;\n};

        for ( my $x = 1 ; $x <= $iterations ; $x++ ) {
            print qq{[!Starting iteration $x]\n};
            my $sample = int( $nchar * ( $percentage / 100 ) );

            #$sample =~ s/(\d+)\.\d+/$1/;
            my @characters;
            for ( 1 .. $nchar ) {
                push( @characters, $_ );
            }
            my @reweighted;
            my $tmp = $nchar;
            for ( 1 .. $sample ) {
                push( @reweighted, splice( @characters, rand int($tmp), 1 ) );
                $tmp--;
            }
            @reweighted = sort { $a <=> $b } @reweighted;
            print qq{weights 2: @reweighted;\n};
            print qq{pset mstaxa=uncertain;\n};
            print
qq{hsearch status=no enforce=yes constraints=$current timelimit=90 converse=yes start=1 swap=tbr multrees=no;\n};
            print qq{[!Restoring weights];\n};
            print qq{weights 1: 1-$nchar;\n};
            print qq{pset mstaxa=uncertain;\n};
            print
qq{hsearch status=no enforce=yes constraints=$current timelimit=90 converse=yes start=1 swap=tbr multrees=no;\n};
            print qq{savetrees file=mydata.tmp replace;\n};
            print qq{gettrees file=mydata.tre mode=7;\n};
            print qq{savetrees file=mydata.tre replace;\n};
            print qq{gettrees file=mydata.tmp mode=3 warntree=no;\n};
        }
        print qq{[**** stopping commands ****]\n};
        print qq{gettrees file=mydata.tre mode=3;\n};
        print qq{[!Shortest trees under converse constraints for $current];\n};
        print qq{pscores all;\n};
        print qq{[!**********************************];\n};
        print qq{[! COMPLETED BREMER SEARCHES];\n};
        print qq{[! FOR: $current];\n};
        print qq{[! THIS PROCEDURE WILL NOW CONTINUE];\n};
        print qq{[! WITH THE NEXT CONSTRAINED NODE];\n};
        print qq{[!**********************************];\n};
    }
    print qq{log stop;\n};
    print qq{end;\n};
}

__END__

=head1 NAME

bremer.pl - creates paup commands to calculate bremer values using
parsimony ratchet.

=head1 SYNOPSIS

=over

=item B<perl bremer.pl>

B<-f>F<<treefile>>

B<-l>C<nodelabel>

B<-p>C<% of chars to reweight>

B<-i>C<number of iterations>

B<-n>C<number of characters>

[ B<-h> ]

=back

=head1 DESCRIPTION

The bremer.pl program takes a newick formatted tree from a file, looks for all
labels whose basename is C<nodelabel> (e.g. if the basename is C<node>, it'll
look for C<node1>, C<node2>, and so on). It will then print out paup commands
that run, for each found node, a parsimony ratchet search for the number of
iterations specified with B<-i>, reweighting a fraction (B<-p>) of the B<-n>
characters. The ratchet search is performed using an inverse monophyly
constraint on the tips subtended by the focal node, and so the difference
between the length of shortest tree found during this ratchet search and the
shortest unconstrained tree is the bremer value for the focal node.

=head1 OPTIONS AND ARGUMENTS

Note that there are no spaces between the option flags and their values.

=over

=item B<-f>F<<treefile>>

A text file containing at least one newick formatted tree description with
labelled nodes.

=item B<-l>C<nodelabel>

Base name of the nodes for which to write ratchet commands.

=item B<-p>C<% of chars to reweight>

Number of characters to reweight during ratchet searches.

=item B<-i>C<number of iterations>

Number of iterations for each ratchet search.

=item B<-n>C<number of characters>

Total number of characters in matrix.

=item C<-h>

Print help message and quit.

=back

=head1 FILES

The program requires a valid newick-formatted labelled tree file.

=head1 SEE ALSO

Rutger Vos: L<http://search.cpan.org/~rvosa>

=cut

