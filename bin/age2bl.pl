#!/usr/bin/perl
# $Id: age2bl.pl 1185 2006-05-26 09:04:17Z rvosa $
# Subversion: $Rev: 145 $
use strict;
use warnings;

#use Data::Dumper;
#use YAML;
my ( %node, $root );
if ( !@ARGV ) {
    &help;
}
else {
    unless ( $#ARGV == 2 || $#ARGV == 1 ) {
        print qq{Wrong number of arguments.\n};
        &help;
    }
    if ( $ARGV[0] =~ /^-h$/ || $ARGV[0] =~ /^-\?$/ || $ARGV[0] =~ /^--help$/ ) {
        &help;
    }
    if ( $ARGV[0] =~ /^-a.+$/ && $ARGV[1] =~ /^-t.+$/ ) {
        my ( $agefile, $treefile ) =
          ( substr( $ARGV[0], 2 ), substr( $ARGV[1], 2 ) );
        if ( -T $agefile ) {
            &parseages($agefile);
        }
        else {
            print qq{Age file $agefile not found.\n};
            &help;
        }
        if ( -T $treefile ) {
            &parsetreefile($treefile);
        }
        else {
            print qq{Tree file $treefile not found.\n};
            &help;
        }
    }
    else {
        print qq{Bad arguments.\n};
        &help;
    }
}

sub parsetreefile {
    open( TREEFILE, $_[0] );
    while (<TREEFILE>) {
        chomp;
        s/\s//g;
        &parsetree($_);
        &age2bl;
        print &to_string($root);
    }
    close TREEFILE;
}

sub parsetree {
    my ( $tree, @entities ) = $_[0];
    foreach ( grep /\w/, split( /[\(|,|\)|;]+/, $tree ) ) {
        if (/(.+):.+/) {
            push( @entities, $1 ) if $1;
        }
        else {
            push( @entities, $_ );
        }
    }
    foreach my $entity (@entities) {
        my ( $subtree, $depth ) = ( $tree, 0 );
        $subtree =~ s/^.*[,|\)|\(]$entity([,|:|\)|;].*)$/$1/;
        for my $x ( 0 .. length($subtree) ) {
            $depth--
              if substr( $subtree, $x, 1 ) eq ')'
              || substr( $subtree, $x, 1 ) eq ';';
            $depth++ if substr( $subtree, $x, 1 ) eq '(';
            if ( $depth == -1 ) {
                $subtree = substr( $subtree, $x++ );
                last;
            }
        }
        $subtree =~ s/^\)(.+?)[:|,|;|\)].*$/$1/;
        $node{$entity}{parent} = \%{ $node{$subtree} }
          if !$node{$entity}{parent} && $subtree ne ';';
        $node{$subtree}{first_daughter} = \%{ $node{$entity} }
          if !$node{$subtree}{first_daughter} && $subtree ne ';';
        $node{$entity}{name} = $entity;
    }
    for my $i ( 0 .. $#entities ) {
        unless ( $node{ $entities[$i] }{parent} ) {
            $root = \%{ $node{ $entities[$i] } };
            next;
        }
        for my $j ( ( $i + 1 ) .. $#entities ) {
            if (   $node{ $entities[$j] }{parent}
                && $node{ $entities[$i] }{parent} ==
                $node{ $entities[$j] }{parent} )
            {
                $node{ $entities[$i] }{next_sister} =
                  \%{ $node{ $entities[$j] } };
                last;
            }
        }
    }
}

sub parseages {
    open( AGEFILE, $_[0] );
    while (<AGEFILE>) {
        chomp;
        if (/^(.+)\t(.+)$/) {
            $node{$1}{age} = $2;
        }
    }
    close AGEFILE;
}

sub age2bl {
    foreach ( keys %node ) {
        $node{$_}{age} = 0 unless $node{$_}{age};
        if ( $node{$_}{parent} ) {
            $node{$_}{branch_length} =
              $node{$_}{parent}->{age} - $node{$_}{age};
        }
        else {
            $node{$_}{branch_length} = 0;
        }
    }
}
{
    my $counter = 0;
    my $string;

    sub to_string {
        my $node = $_[0];
        $counter++;
        if ( !$node->{parent} ) {
            $string = $node->{name} . ':' . $node->{branch_length} . ';';
        }
        elsif ( $node->{parent} && $node == $node->{parent}{first_daughter} ) {
            $string = $node->{name} . ':' . $node->{branch_length} . $string;
        }
        elsif ( $node->{parent} && $node != $node->{parent}{first_daughter} ) {
            $string =
              $node->{name} . ':' . $node->{branch_length} . ',' . $string;
        }
        if ( !$node->{first_daughter} ) {
        }
        else {
            $node   = $node->{first_daughter};
            $string = ')' . $string;
            &to_string($node);
            while ( $node->{next_sister} ) {
                $node = $node->{next_sister};
                &to_string($node);
            }
            $string = '(' . $string;
        }
        my @nodes = keys %node;
        return $string if $counter == $#nodes;
    }
}

sub help {
    print qq{NAME: age2bl v1.0 5/22/2005 by Rutger A. Vos\n\n};
    print qq{DESCRIPTION: Converts newick tree file and age\n};
    print qq{file to tree(s) with branch lengths (nodes must\n};
    print qq{be tagged and match tags in age file).\n\n};
    print qq{USAGE: age2bl -a[agefile] -t[treefile]\n\n};
    exit 0;
}
