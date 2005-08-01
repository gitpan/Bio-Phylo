#!/usr/bin/perl
# $Id: postmb.pl,v 1.1 2005/08/01 23:06:14 rvosa Exp $
# Subversion: $Rev: 145 $
use strict;

#use warnings;
# global variables
my ( $basename, $outfile, $continue, $found, $suffix ) =
  ( "infile", "outfile", 0, 0, "" );
my ( @samples, @vars );
my $help = <<"EOF";
postmb v.1.0 Rutger Vos, Simon Fraser University, 2005
Explanation: Parses and summarizes MrBayes log files (also from LRmb).
Usage: PostAnalysis -b[base name] -o[outfile] [-h]
Where the options are:
    -b base name to which *.t, *.p suffix is added (now: $basename, $found logs)
    -o outfile (now: $outfile)
    -h this message and exit
EOF
print $help && exit(0) if $#ARGV > 2;

# interactive or commandline mode
if (@ARGV) {
    &commandline();
}
else {
    &interactive();
}

# parsing files
open( OUTFILE, ">$outfile" );
if ( $continue && -T "$basename.t$suffix" && -T "$basename.p$suffix" ) {
    if ( &treefile() != &paramfile() ) {
        print STDERR qq{Number of trees and parameter samples doesn't match!\n};
    }
    push( @vars, 'tree_id', 'param_id', 'tree_gen', 'tree' );
    print OUTFILE qq{sample\t};
    foreach (@vars) { print OUTFILE qq{$_\t} }
    print OUTFILE qq{\n};
    for ( 0 .. $#samples ) {
        print OUTFILE $_ + 1 . "\t";
        foreach my $var (@vars) {
            print OUTFILE $samples[$_]{$var} . "\t";
        }
        print OUTFILE qq{\n};
        if ( $samples[$_]{'Gen'} != $samples[$_]{'tree_gen'} ) {
            print STDERR qq{Non-matching generation index in sample $_\n};
        }
        if ( $samples[$_]{'param_id'} != $samples[$_]{'tree_id'} ) {
            print STDERR qq{Non-matching tree and param ids in sample $_\n};
        }
    }
}
close OUTFILE;

# menu subs
sub basename {
    print qq{Enter path to base file: };
    while (<>) {
        if ( /^(.+)$/ && -T $1 ) {
            $found = 0;
            foreach ( ".t", ".p", ".t.log", ".p.log" ) {
                if ( -T "$1$_" ) {
                    $found++;
                    print qq{Found $1$_\n};
                    $suffix = ".log" if $_ =~ /log/;
                }
            }
            if ($found) {
                $basename = $1;
                print qq{Found $found log(s)\nPress any key... };
                while (<>) { return $basename if /^.*$/; }
            }
            else { print qq{No log files found!\nEnter path to base file: }; }
        }
        else { print qq{No base file found!\nEnter path to base file: }; }
    }
    return $basename;
}

sub outfile {
    print qq{Specify output file name: };
    while (<>) {
        if ( /^(.+$)/i && !-e $1 ) {
            $outfile = $1;
            last;
        }
        else { print qq{File can't be created.\nSpecify a free name: }; }
    }
    return $outfile;
}

sub continuesub {
    print qq{Are you sure? (y/n): };
    while (<>) {
        $continue = 1 if /^y$/i;
        last if /^.+$/i;
    }
    return $continue;
}

sub quit {
    print qq{Are you sure? (y/n): };
    while (<>) {
        return 1 if /^y$/i;
        last     if /^n$/i;
    }
    return 0;
}

# interactive sub
sub interactive {
    while ( !$continue ) {
        system("cls") if eval { system("clear"); };
        $found = 0;
        foreach ( ".t", ".p", ".t.log", ".p.log" ) {
            $found++ if -T "$basename$_";
        }
        print qq{
============================================================
PostAnalysis v.1.0 Rutger Vos, Simon Fraser University, 2005
1. base name: $basename ($found logs)\n2. outfile: $outfile\n3. continue\n4. quit
Choose an option: };
      INTERACT: while (<>) {
            if (/^1$/) {
                $basename = &basename();
                last INTERACT;
            }
            elsif (/^2$/) {
                $outfile = &outfile();
                last INTERACT;
            }
            elsif (/^3$/) {
                $continue = &continuesub();
                last INTERACT;
            }
            elsif (/^4$/) {
                exit(0) if &quit();
                last INTERACT;
            }
            else { print qq{Not a valid option!\nChoose an option: }; }
        }
    }
}

# commandline sub
sub commandline {
    foreach (@ARGV) {
        if ( /^-b(.+)$/i && -T $1 && -T "$1.t" && -T "$1.p" ) {
            $basename = $1;
            $suffix = ".log" if -T "$basename.t.log" && -T "$basename.p.log";
        }
        elsif ( /^-b(.+)$/i && !-T $1 ) {
            print qq{File not found!\n};
            print $help;
            exit(0);
        }
        elsif (/^-o(.+)$/i) {
            if ( -e $1 ) {
                print qq{File already exists!\n};
                print $help;
                exit(0);
            }
            else {
                $outfile = $1;
            }
        }
        elsif ( /^-h$/i || /--help/i ) {
            print $help;
            exit(0);
        }
        else {
            print qq{Invalid option\n};
            print $help;
            exit(0);
        }
    }
    $continue = 1;
}

# parse subroutines
sub treefile {
    my ( $i, $treesample, @taxa, $id ) = ( 0, 0 );
    print qq{Parsing tree file: $basename.t$suffix, line $i};
    open( TREELOG, "$basename.t$suffix" );
    while (<TREELOG>) {
        chomp;
        print qq{\b} x length("$i") . ++$i;
        if (/^\s*\[ID\:\s*([0-9]+)\]\s*$/) {
            $id = $1;
        }
        elsif (/^\s*([0-9]+)\s+(.+)[,|;]\s*$/) {
            $taxa[$1] = $2;
        }
        elsif (/^\s*tree\srep\.([0-9]+)\s*=\s*(.+)$/) {
            my ( $gen, $tree ) = ( $1, $2 );
            for ( my $j = 1 ; $j <= $#taxa ; $j++ ) {
                $tree =~ s/([,|\(])$j([,|\)|:])/$1$taxa[$j]$2/;
            }
            $samples[$treesample]{'tree_id'}  = $id   if $id;
            $samples[$treesample]{'tree_gen'} = $gen  if $gen;
            $samples[$treesample]{'tree'}     = $tree if $tree;
            $treesample++;
        }
    }
    print qq{\n};
    close TREELOG;
    return $treesample;
}

sub paramfile {
    my ( $i, $paramsample, $id, @params, ) = ( 0, 0 );
    print qq{Parsing parameter file: $basename.p$suffix, line $i};
    open( PLOG, "$basename.p$suffix" );
    while (<PLOG>) {
        chomp;
        print qq{\b} x length("$i") . ++$i;
        if (/^\s*\[ID\:\s*([0-9]+)\]\s*$/) {
            $id = $1;
        }
        elsif (/^\s*Gen.*$/) {
            @vars = split();
        }
        elsif (/^\s*[0-9]+.*$/) {
            @params = split();
            for ( 0 .. $#vars ) {
                $samples[$paramsample]{ $vars[$_] } = $params[$_];
            }
            $samples[$paramsample]{'param_id'} = $id;
            $paramsample++;
        }
    }
    print qq{\n};
    close PLOG;
    return $paramsample;
}
