#!/usr/bin/perl
# $Id: LRmb.pl,v 1.2 2005/08/09 12:36:12 rvosa Exp $
# Subversion: $Rev: 163 $
use strict;
use warnings;
use IPC::Open2;
use vars qw(%metadata $infile);
my (
    $infile,  $mrbayes, $ngen,     $iterations, $nsamp,
    $nchains, $temp,    $continue, $verbose
  )
  = ( "infile.nex", "MrBayes3_0b4", 1000, 100, 20, 4, 0.2, 0, 0 );
my $help = <<"EOF";
LRmb v.1.0 Rutger Vos, Simon Fraser University, 2005
Explanation: LRmb communicates with MrBayes to implement ratchet commands.
Usage: LRmb -g[number] -i[number] -s[number] -c[number] -t[number] -f[infile] -m[path] -v
Where the options are:
	-g number of generations per iteration (default: $ngen)
	-i number of iterations (default: $iterations)
	-s percentage of characters to jackknife (default: $nsamp)
	-f a nexus formatted file (default: $infile)
	-m the full path to the MrBayes executable (default: $mrbayes)
	-c number of chains (default: $nchains)
	-t temperature (default: $temp)
	-v verbose to outfile.txt
	-h this message and exit
EOF
if ( $#ARGV != 6 && $#ARGV != 7 && @ARGV ) {
    print $help;
    exit(0);
}
unless (@ARGV) {
    while ( !$continue ) {
        system("clear") if eval( system("cls") );
        print qq{
===========================================================================
LRmb v.1.0 Rutger Vos, Simon Fraser University, 2005
Explanation: LRmb communicates with MrBayes to implement ratchet commands.
1. number of generations:		$ngen
2. number of iterations:		$iterations
3. % of characters to jaccknife:	$nsamp
4. path to file:			$infile
5. path to MrBayes:			$mrbayes
6. number of chains:			$nchains
7. temperature:				$temp
8. continue 
9. quit\n};
        print qq{0. verbose				ON\n} if $verbose;
        print qq{0. verbose				OFF\n} unless $verbose;
        print qq{Choose an option: };
      INTERACT: while (<>) {
            if (/^1$/) {
                print qq{Enter number of generations: };
                while (<>) {
                    if (/^([0-9]+\.?[0-9]*)$/) {
                        $ngen = $1;
                        last INTERACT;
                    }
                    else {
                        print qq{Bad value!\nEnter number of generations: };
                    }
                }
            }
            elsif (/^2$/) {
                print qq{Enter number of iterations: };
                while (<>) {
                    if (/^([0-9]+\.?[0-9]*)$/) {
                        $iterations = $1;
                        last INTERACT;
                    }
                    else {
                        print qq{Bad value!\nEnter number of iterations: };
                    }
                }
            }
            elsif (/^3$/) {
                print qq{Enter % of characters to jackknife: };
                while (<>) {
                    if (/^([0-9]+\.?[0-9]*)$/) {
                        $nsamp = $1;
                        last INTERACT;
                    }
                    else {
                        print
                          qq{Bad value!\nEnter % of characters to jackknife: };
                    }
                }
            }
            elsif (/^4$/) {
                print qq{Enter path to infile: };
                while (<>) {
                    if ( /^(.+)$/ && -T $1 ) {
                        my $free = 1;
                        if ( -T "$1.t" ) {
                            print qq{Bad name - $1.t already exists\n};
                            $free = 0;
                        }
                        if ( -T "$1.p" ) {
                            print qq{Bad name - $1.p already exists\n};
                            $free = 0;
                        }
                        if ( -T "$1.t.log" ) {
                            print qq{Bad name - $1.t.log already exists\n};
                            $free = 0;
                        }
                        if ( -T "$1.p.log" ) {
                            print qq{Bad name - $1.p.log already exists\n};
                            $free = 0;
                        }
                        if ($free) {
                            $infile = $1;
                            open( TREELOG, ">$1.t" );
                            open( PLOG,    ">$1.p" );
                            close TREELOG;
                            close PLOG;
                            last INTERACT;
                        }
                    }
                    else {
                        print qq{Not found!\nEnter path to infile: };
                    }
                }
            }
            elsif (/^5$/) {
                print qq{Enter path to MrBayes: };
                while (<>) {
                    if ( /^(.+)$/ && -x $1 ) {
                        $mrbayes = $1;
                        last INTERACT;
                    }
                    else {
                        print qq{Not found!\nEnter path to MrBayes: };
                    }
                }
            }
            elsif (/^6$/) {
                print qq{Enter number of chains: };
                while (<>) {
                    if (/^([0-9]+\.?[0-9]*)$/) {
                        $nchains = $1;
                        last INTERACT;
                    }
                    else {
                        print qq{Bad value!\nEnter number of chains: };
                    }
                }
            }
            elsif (/^7$/) {
                print qq{Enter temperature: };
                while (<>) {
                    if (/^([0-9]+\.?[0-9]*)$/) {
                        $temp = $1;
                        last INTERACT;
                    }
                    else {
                        print qq{Bad value!\nEnter temperature: };
                    }
                }
            }
            elsif (/^8$/) {
                print qq{Are you sure? (y/n): };
                while (<>) {
                    if (/^y$/i) {
                        $continue = 1;
                        last INTERACT;
                    }
                    if (/^n$/i) {
                        last INTERACT;
                    }
                }
            }
            elsif (/^9$/) {
                print qq{Are you sure? (y/n): };
                while (<>) {
                    exit(0)       if /^y$/i;
                    last INTERACT if /^n$/i;
                }
            }
            elsif (/^0$/) {
                print qq{Log all to outfile.txt? (y/n): };
                while (<>) {
                    if (/^y$/i) {
                        $verbose = 1;
                        last INTERACT;
                    }
                    if (/^n$/i) {
                        $verbose = 0;
                        last INTERACT;
                    }
                }
            }
            else {
                print qq{Not a valid option!};
            }
        }
    }
}
else {
    foreach (@ARGV) {
        if (/-g([0-9]+)/) {
            $ngen = $1;
        }
        elsif (/-i([0-9]+)/) {
            $iterations = $1;
        }
        elsif (/-s([0-9]+)/) {
            $nsamp = $1;
        }
        elsif (/-f(.+)/) {
            $infile = $1;
        }
        elsif (/-m(.+)/) {
            $mrbayes = $1;
        }
        elsif (/-t([0-9]+)/) {
            $temp = $1;
        }
        elsif (/-c([0-9]+)/) {
            $nchains = $1;
        }
        elsif (/-v/) {
            $verbose = 1;
        }
        elsif ( /-h/ || /--help/ ) {
            print $help;
            exit(0);
        }
        else {
            print qq{Invalid option\n};
            print $help;
            exit(0);
        }
    }
}
&parse_nex($infile);
#####LOOPING WITH MRBAYES#####
my $pid = open2( \*RDRFH, \*WTRFH, $mrbayes );
open( STDOUT, ">>outfile.txt" ) if $verbose;
for ( my $iter = 1 ; $iter <= $iterations ; $iter++ ) {
    print WTRFH qq{execute $infile;\n};
    while (<RDRFH>) {
        print;
        last if /Exiting data block/;
    }
    if ( $iter > 1 ) {
        my $usertree = &usertree;
        print WTRFH qq{usertree=$usertree\n};
        while (<RDRFH>) {
            print;
            last if /Expecting  command/;
        }
    }
    if ( $iter % 2 == 1 ) {
        print WTRFH qq{include 1-$metadata{'nchar'};\n};
        while (<RDRFH>) {
            print;
            last if /Expecting  command/;
        }
    }
    elsif ( $iter % 2 == 0 ) {
        my @weights = &resample( $iter % 2 );
        my $set     = "";
        for ( my $x = 0 ; $x <= $#weights ; $x++ ) {
            $set = $set . ( $x + 1 ) . " " if $weights[$x] > 1;
        }
        print WTRFH qq{exclude $set;\n};
        while (<RDRFH>) {
            print;
            last if /Expecting  command/;
        }
    }
    if ( $iter > 1 ) {
        print WTRFH
          qq{mcmc nchains=$nchains temp=$temp ngen=$ngen startingtree=user;\n};
    }
    else {
        print WTRFH
qq{mcmc nchains=$nchains temp=$temp ngen=$ngen startingtree=random;\n};
    }
    while (<RDRFH>) {
        print;
        if (/File \"$infile.t\" already exists/) {
            open( TFILE, "<$infile.t" );
            open( TLOG,  ">>$infile.t.log" );
            while (<TFILE>) {
                print TLOG;
            }
            close TFILE;
            close TLOG;
            last;
        }
    }
    print WTRFH qq{y\n};
    while (<RDRFH>) {
        print;
        if (/File \"$infile.p\" already exists/) {
            open( PFILE, "<$infile.p" );
            open( PLOG,  ">>$infile.p.log" );
            while (<PFILE>) {
                print PLOG;
            }
            close PFILE;
            close PLOG;
            last;
        }
    }
    print WTRFH qq{y\n};
    while (<RDRFH>) {
        print;

        #print OUTFILE $_;
        last if /^\s*$ngen\s+--/;
    }
    print WTRFH qq{n\n};
}
print WTRFH qq{quit\n};
close WTRFH;
close RDRFH;
kill -9, $pid;
print qq{Done!\n};
exit(0);
#####CREATE RESAMPLED WEIGHT SET#####
sub resample {
    my ( $switch, @weights ) = $_[0];
    for ( my $x = 0 ; $x < $metadata{'nchar'} ; $x++ ) {
        $weights[$x] = 1;
    }
    return @weights if $switch;
    for (
        my $x = 0 ;
        $x < int( ( $metadata{'nchar'} * ( $nsamp / 100 ) ) + 0.5 ) ;
        $x++
      )
    {
        $weights[ int( rand $metadata{'nchar'} ) ]++;
    }
    return @weights;
}
#####CREATE USERTREE#####
sub usertree {
    my ( @taxa, $tree );
    open( TREEFILE, "$infile.t" );
    while (<TREEFILE>) {
        chomp;
        if (/^\s+([0-9]+)\s+(.+)[,|;]\s*/) {
            $taxa[$1] = $2;
        }
        if (/^\s+tree\s+rep\.$ngen\s+=\s+(.*)$/) {
            $tree = $1;
        }
    }
    for ( my $x = 1 ; $x <= $metadata{'ntax'} ; $x++ ) {
        $tree =~ s/^(.*[,|\(])$x([,|\)].*)$/$1$taxa[$x]$2/;
    }
    return $tree;
}
#####NEXUS FILE PARSING SUBROUTINE######
sub parse_nex {
    my ( $infile, $comment, $data ) = ( @_, 0 );
    open( INFILE, $infile );

    # STRIPPING COMMENTS FROM INFILE
    while (<INFILE>) {
        my $temp = $_;
        if ( $_ =~ /\[/ && $_ !~ /\]/ ) {
            $temp =~ s/^(.*)\[.*$/$1/;
            $comment++;
        }
        elsif ( $_ =~ /\]/ && $_ !~ /\[/ && $comment == 1 ) {
            $temp =~ s/^.*\](.*)$/$1/;
            $comment--;
        }
        elsif ( $_ =~ /^.*\[.*\].*$/ ) {
            $temp =~ s/^(.*)\[.*\](.*)$/$1$2/;
        }
        $data .= $temp unless $comment or $temp =~ /^\s*$/;
    }

    # COLLECTING NTAX
    if ( $data =~ /\bntax\s*=\s*([0-9]+)\b/i ) {
        $metadata{'ntax'} = $1;
    }

    # COLLECTING NCHAR
    if ( $data =~ /\bnchar\s*=\s*([0-9]+)\b/i ) {
        $metadata{'nchar'} = $1;
    }

    # COLLECTING DATATYPE
    if ( $data =~ /\bdatatype\s*=\s*([a-z][A-Z]+)\b/i ) {
        $metadata{'datatype'} = $1;
    }

    # COLLECTING MISSING
    if ( $data =~ /\bmissing\s*=\s*(.+)\b/i ) {
        $metadata{'missing'} = $1;
    }

    # COLLECTING GAP
    if ( $data =~ /\bgap\s*=\s*(.+)\b/i ) {
        $metadata{'gap'} = $1;
    }

    # STATUS REPORT
    print qq{
    [! This is how I interpreted the data. Make sure this is correct:
    The data is of type $metadata{'datatype'}, consisting of $metadata{'nchar'} characters, for $metadata{'ntax'} taxa.]
    };
}
