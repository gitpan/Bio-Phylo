#!/usr/bin/perl
# $Id: bremer.pl 1185 2006-05-26 09:04:17Z rvosa $
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
