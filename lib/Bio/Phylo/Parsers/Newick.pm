# $Id: Newick.pm,v 1.6 2005/08/09 12:36:13 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Parsers::Newick;
use strict;
use warnings;
use Bio::Phylo::Trees;
use Bio::Phylo::Trees::Tree;
use Bio::Phylo::Trees::Node;
use base 'Bio::Phylo::Parsers';

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 148 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.03';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);
*from_handle = \&from_both;
*from_string = \&from_both;

=head1 NAME

Bio::Phylo::Parsers::Newick - A library for parsing phylogenetic trees in Newick
format.

=head1 SYNOPSIS

 my $newick = new Bio::Phylo::Parsers::Newick;
 my $trees = $newick->parse(-file => 'tree.dnd', -format => 'newick');

=head1 DESCRIPTION

This module parses tree descriptions in parenthetical format.

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $newick = new Bio::Phylo::Parsers::Newick;
 Function: Initializes a Bio::Phylo::Parsers::Newick object.
 Returns : A Bio::Phylo::Parsers::Newick object.
 Args    : none.

=cut

sub new {
    my $class = $_[0];
    my $self  = {};
    bless( $self, $class );
    return $self;
}

=back

=head2 PARSER

=over

=item from_both(%options), from_handle, from_string

 Type    : Wrapper
 Title   : from_both(%options)
 Usage   : $newick->from_both(%options);
 Function: Extracts trees from file, sends strings to _parse_string()
 Returns : Bio::Phylo::Trees
 Args    : -handle => (\*FH) or -string => (scalar).
 Comments:

=cut

sub from_both {
    my $self  = shift;
    my %args  = @_;
    my $trees = new Bio::Phylo::Trees;
    if ( $args{'-handle'} ) {
        while ( readline( $args{-handle} ) ) {
            chomp;
            s/\s//g;
            $trees->insert( $self->_parse_string($_) );
        }
    }
    if ( $args{'-string'} ) {
        foreach ( split( /;/, $args{'-string'} ) ) {
            chomp;
            s/\s//g;
            my $tree = $_ . ';';
            $trees->insert( $self->_parse_string($tree) );
        }
    }
    return $trees;
}

=item _parse_string($string)

 Type    : Parser
 Title   : _parse_string($string)
 Usage   : my $tree = $newick->_parse_string($string);
 Function: Creates a populated Bio::Phylo::Trees::Tree object from a newick
           string.
 Returns : A Bio::Phylo::Trees::Tree object.
 Args    : $string = a newick tree description

=cut

sub _parse_string {
    my ( $self, $string ) = @_;
    my $tree = new Bio::Phylo::Trees::Tree;
    $string = $self->_nodelabels($string);
    foreach ( grep ( /\w/, split( /[\(|,|\)|;]+/o, $string ) ) ) {
        my $node;
        if (/^(.+):(\d+\.?\d*e?[-|+]?\d*)$/oi) {
            $node = Bio::Phylo::Trees::Node->new(
                -name          => $1,
                -branch_length => $2
            );
        }
        else {
            $node = Bio::Phylo::Trees::Node->new(
                -name => $_,
            );
        }
        $tree->insert($node);
    }
    for my $i ( 0 .. $tree->last_index ) {
        my $node = $tree->get_by_index($i);
        my ( $st, $depth, $name ) = ( $string, 0, $node->get_name );
        $st =~ s/^.*[,|\)|\(]$name([,|:|\)|;].*)$/$1/;
        for my $x ( 0 .. length($st) ) {
            if ( substr( $st, $x, 1 ) eq ')' || substr( $st, $x, 1 ) eq ';' ) {
                $depth--;
            }
            if ( substr( $st, $x, 1 ) eq '(' ) {
                $depth++;
            }
            if ( $depth == -1 ) {
                $st = substr( $st, $x++ );
                last;
            }
        }
        $st =~ s/^\)(.+?)[:|,|;|\)].*$/$1/;
        for my $j ( ( $i + 1 ) .. $tree->last_index ) {
            my $p = $tree->get_by_index($j);
            if ( $p->get_name eq $st ) {
                $node->set_parent($p);
                last;
            }
        }
    }
    $tree->_analyze;
    return $tree;
}

=item _nodelabels($string)

 Type    : Internal method.
 Title   : _nodelabels($string)
 Usage   : my $labelled = $newick->_nodelabels($string);
 Function: Returns a newick string with labelled nodes
 Returns : SCALAR
 Args    : $string = a newick tree description

=cut

sub _nodelabels {
    my $self   = $_[0];
    my $string = $_[1];
    my ( $x, @x );
    while ( $string =~ /\)[:|,|;|\)]/o ) {
        foreach ( split( /[:|,|;|\)]/o, $string ) ) {
            push( @x, $1 ) if /n([0-9]+)/;
        }
        @x = sort { $a <=> $b } @x;
        $x = $x[-1];
        $string =~ s/(\))([:|,|;|\)])/$1.'n'.++$x.$2/ose;
    }
    return $string;
}

=back

=head2 CONTAINER

=over

=item container

 Type    : Internal method
 Title   : container
 Usage   : $newick->container;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container {
    return 'NONE';
}

=item container_type

 Type    : Internal method
 Title   : container_type
 Usage   : $newick->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'NEWICK';
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>
L<http://www.sfu.ca/~rvosa/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed
from BioPerl L<http://www.bioperl.org>, and CIPRES
L<http://www.phylo.org> and FAB* L<http://www.sfu.ca/~fabstar>
for comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
