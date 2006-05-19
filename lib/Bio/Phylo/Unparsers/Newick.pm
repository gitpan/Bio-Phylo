# $Id: Newick.pm,v 1.20 2006/03/07 20:54:16 rvosa Exp $
# Subversion: $Rev: 190 $
package Bio::Phylo::Unparsers::Newick;
use strict;
use warnings;
use Bio::Phylo::Forest::Tree;
use base 'Bio::Phylo::IO';

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Unparsers::Newick - Unparses newick trees. No serviceable parts
inside.

=head1 DESCRIPTION

This module turns a tree object into a newick formatted (parenthetical) tree
description. It is called by the L<Bio::Phylo::IO> facade, don't call it
directly.

=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $newick = Bio::Phylo::Unparsers::Newick->_new;
 Function: Initializes a Bio::Phylo::Unparsers::Newick object.
 Returns : A Bio::Phylo::Unparsers::Newick object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = shift;
    my $self  = {};
    if (@_) {
        my %opts = @_;
        foreach my $key ( keys %opts ) {
            my $localkey = uc $key;
            $localkey =~ s/-//;
            unless ( ref $opts{$key} ) {
                $self->{$localkey} = uc $opts{$key};
            }
            else {
                $self->{$localkey} = $opts{$key};
            }
        }
    }
    bless $self, $class;
    return $self;
}

=begin comment

 Type    : Wrapper
 Title   : _to_string($tree)
 Usage   : $newick->_to_string($tree);
 Function: Prepares for the recursion to unparse the tree object into a
           newick string.
 Alias   :
 Returns : SCALAR
 Args    : Bio::Phylo::Forest::Tree

=end comment

=cut

sub _to_string {
    my $self   = shift;
    my $tree   = $self->{'PHYLO'};
    my $n      = $tree->get_root;
    my $string = $self->__to_string( $tree, $n );
    return $string;
}

=begin comment

 Type    : Unparser
 Title   : __to_string
 Usage   : $newick->__to_string($tree, $node);
 Function: Unparses the tree object into a newick string.
 Alias   :
 Returns : SCALAR
 Args    : A Bio::Phylo::Forest::Tree object. Optional: A Bio::Phylo::Forest::Node
           object, the starting point for recursion.

=end comment

=cut

{
    my $string = q{};
    no warnings 'uninitialized';

    sub __to_string {
        my ( $self, $tree, $n ) = @_;
        if ( !$n->get_parent ) {
            if ( defined $n->get_branch_length ) {
                $string = $n->get_name . ':' . $n->get_branch_length . ';';
            }
            else {
                $n->get_name ? $string = $n->get_name . ';' : $string = ';';
            }
        }
        elsif ( !$n->get_previous_sister ) {
            if ( defined $n->get_branch_length ) {
                $string = $n->get_name . ':' . $n->get_branch_length . $string;
            }
            else { $string = $n->get_name . $string; }
        }
        else {
            if ( defined $n->get_branch_length ) {
                $string =
                  $n->get_name . ':' . $n->get_branch_length . ',' . $string;
            }
            else { $string = $n->get_name . ',' . $string; }
        }
        if ( $n->get_first_daughter ) {
            $n      = $n->get_first_daughter;
            $string = ')' . $string;
            $self->__to_string( $tree, $n );
            while ( $n->get_next_sister ) {
                $n = $n->get_next_sister;
                $self->__to_string( $tree, $n );
            }
            $string = '(' . $string;
        }
    }
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The newick unparser is called by the L<Bio::Phylo::IO|Bio::Phylo::IO> object.
Look there to learn how to unparse newick strings.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual|Bio::Phylo::Manual>.

=back

=head1 FORUM

CPAN hosts a discussion forum for Bio::Phylo. If you have trouble
using this module the discussion forum is a good place to start
posting questions (NOT bug reports, see below):
L<http://www.cpanforum.com/dist/Bio-Phylo>

=head1 BUGS

Please report any bugs or feature requests to C<< bug-bio-phylo@rt.cpan.org >>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>. I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes. Be sure to include the following in your request or comment, so that
I know what version you're using:

$Id: Newick.pm,v 1.20 2006/03/07 20:54:16 rvosa Exp $

=head1 AUTHOR

Rutger A. Vos,

=over

=item email: C<< rvosa@sfu.ca >>

=item web page: L<http://www.sfu.ca/~rvosa/>

=back

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed
from BioPerl L<http://www.bioperl.org>, and CIPRES
L<http://www.phylo.org> and FAB* L<http://www.sfu.ca/~fabstar>
for comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger A. Vos, All Rights Reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;
