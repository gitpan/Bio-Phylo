# $Id: Pagel.pm,v 1.6 2005/08/09 12:36:13 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Unparsers::Pagel;
use strict;
use warnings;
use Bio::Phylo::Trees::Tree;
use base 'Bio::Phylo::Unparsers';

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

=head1 NAME

Bio::Phylo::Unparsers::Pagel - An object-oriented module for unparsing tree
objects into Newick formatted strings.

=head1 SYNOPSIS

 my $pagel = new Bio::Phylo::Unparsers::Pagel;
 my $string = $pagel->unparse($tree);

=head1 DESCRIPTION

This module unparses a Bio::Phylo data structure into an input file for
Discrete/Continuous/Multistate. The pagel file format (as it is interpreted
here) consists of:

 * first line: the number of tips, the number of characters
 * subsequent lines: offspring name, parent name, branch length, character
 state(s).

During unparsing, the tree is randomly resolved, and branch lengths are
formatted to %f floats (i.e. integers, decimal point, integers).

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $pagel = new Bio::Phylo::Unparsers::Pagel;
 Function: Initializes a Bio::Phylo::Unparsers::Pagel object.
 Alias   :
 Returns : A Bio::Phylo::Unparsers::Pagel object.
 Args    : none.

=back

=cut

sub new {
    my $class = shift;
    my $self  = {};
    if (@_) {
        my %opts = @_;
        foreach my $key ( keys %opts ) {
            my $localkey = uc($key);
            $localkey =~ s/-//;
            unless ( ref $opts{$key} ) {
                $self->{$localkey} = uc( $opts{$key} );
            }
            else {
                $self->{$localkey} = $opts{$key};
            }
        }
    }
    bless( $self, $class );
    return $self;
}

=head2 UNPARSER

=over

=item to_string($tree)

 Type    : Unparser
 Title   : to_string($tree)
 Usage   : $pagel->to_string($tree);
 Function: Unparses a Bio::Phylo::Tree object into a pagel formatted string.
 Returns : SCALAR
 Args    : Bio::Phylo::Tree

=cut

sub to_string {
    my $self = shift;
    my $tree = $self->{'PHYLO'};
    $tree->resolve;
    my ( $charcounter, $string ) = 0;
    foreach my $node ( @{ $tree->get_entities } ) {
        if ( $node->get_parent ) {
            $string .=
              $node->get_name . ',' . $node->get_parent->get_name . ',';
            if ( $node->get_branch_length ) {
                $string .= sprintf( "%f", $node->get_branch_length );
            }
            else {
                $string .= sprintf( "%f", 0 );
            }
            if ( $node->get_taxon ) {
                my $taxon = $node->get_taxon;
                foreach ( @{ $taxon->data } ) {
                    $string .= ',' . $_->char;
                    $charcounter++;
                }
            }
            $string .= "\n";
        }
        else {
            next;
        }
    }
    my $header = $tree->calc_number_of_terminals . " ";
    $header .= $charcounter / $tree->calc_number_of_terminals;
    $string = $header . "\n" . $string;
    return $string;
}

=back

=head2 CONTAINER

=over

=item container

 Type    : Internal method
 Title   : container
 Usage   : $pagel->container;
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
 Usage   : $pagel->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'PAGEL';
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
