# $Id: Newick.pm,v 1.4 2005/08/01 23:06:19 rvosa Exp $
# Subversion: $Rev: 147 $
package Bio::Phylo::Unparsers::Newick;
use strict;
use warnings;
use Bio::Phylo::Trees::Tree;
use base 'Bio::Phylo::Unparsers';

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 147 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.02';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);
*unparse = \&to_string;

=head1 NAME

Bio::Phylo::Unparsers::Newick - An object-oriented module for unparsing tree
objects into Newick formatted strings.

=head1 SYNOPSIS

 my $newick = new Bio::Phylo::Unparsers::Newick;
 my $string = $newick->unparse($tree);

=head1 DESCRIPTION

This module turns a tree object into a newick formatted (parenthetical) tree
description.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $newick = new Bio::Phylo::Unparsers::Newick;
 Function: Initializes a Bio::Phylo::Unparsers::Newick object.
 Returns : A Bio::Phylo::Unparsers::Newick object.
 Args    : none.

=back

=cut

sub new {
    my $class = $_[0];
    my $self  = {};
    bless( $self, $class );
    return $self;
}

=head2 UNPARSER

=over

=item to_string($tree), unparse

 Type    : Wrapper
 Title   : to_string($tree)
 Usage   : $newick->to_string($tree);
 Function: Prepares for the recursion to unparse the tree object into a
           newick string.
 Alias   :
 Returns : SCALAR
 Args    : Bio::Phylo::Trees::Tree

=cut

sub to_string {
    my $self   = shift;
    my %opts   = @_;
    my $tree   = $opts{-phylo};
    my $n      = $tree->get_root;
    my $string = $self->_to_string( $tree, $n );
    return $string;
}

=item _to_string(Bio::Phylo::Trees::Tree, Bio::Phylo::Trees::Node)

 Type    : Unparser
 Title   : _to_string
 Usage   : $newick->_to_string($tree, $node);
 Function: Unparses the tree object into a newick string.
 Alias   :
 Returns : SCALAR
 Args    : A Bio::Phylo::Trees::Tree object. Optional: A Bio::Phylo::Trees::Node
           object, the starting point for recursion.

=cut

{
    my $string = "";

    sub _to_string {
        my ( $self, $tree, $n ) = @_;
        if ( !defined $n->get_parent ) {
            if ( $n->get_branch_length ) {
                $string = $n->get_name . ':' . $n->get_branch_length . ';';
            }
            else { $string = $n->get_name . ';'; }
        }
        elsif ( !$n->get_previous_sister ) {
            if ( $n->get_branch_length ) {
                $string = $n->get_name . ':' . $n->get_branch_length . $string;
            }
            else { $string = $n->get_name . $string; }
        }
        else {
            if ( $n->get_branch_length ) {
                $string =
                  $n->get_name . ':' . $n->get_branch_length . ',' . $string;
            }
            else { $string = $n->get_name . ',' . $string; }
        }
        if ( $n->get_first_daughter ) {
            $n      = $n->get_first_daughter;
            $string = ')' . $string;
            $self->_to_string( $tree, $n );
            while ( $n->get_next_sister ) {
                $n = $n->get_next_sister;
                $self->_to_string( $tree, $n );
            }
            $string = '(' . $string;
        }
    }
}

=back

=head2 CONTAINER

=over

=item container

 Type    : Internal method
 Title   : container
 Usage   : $newick->container;
 Function:
 Alias   :
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
 Alias   :
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'NEWICK';
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>

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
