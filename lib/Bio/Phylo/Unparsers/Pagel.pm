# $Id: Pagel.pm,v 1.19 2005/09/29 20:31:18 rvosa Exp $
# Subversion: $Rev: 191 $
package Bio::Phylo::Unparsers::Pagel;
use strict;
use warnings;
use Bio::Phylo::Forest::Tree;
use base 'Bio::Phylo::IO';

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Unparsers::Pagel - Unparses pagel data files. No serviceable parts
inside.

=head1 DESCRIPTION

This module unparses a Bio::Phylo data structure into an input file for
Discrete/Continuous/Multistate. The pagel file format (as it is interpreted
here) consists of:

=over

=item first line

the number of tips, the number of characters

=item subsequent lines

offspring name, parent name, branch length, character state(s).

=back

During unparsing, the tree is randomly resolved, and branch lengths are
formatted to %f floats (i.e. integers, decimal point, integers).

The pagel module is called by the L<Bio::Phylo::IO|Bio::Phylo::IO> object, so
look there to learn how to create Pagel formatted files.

=begin comment

 Type    : Constructor
 Title   : new
 Usage   : my $pagel = new Bio::Phylo::Unparsers::Pagel;
 Function: Initializes a Bio::Phylo::Unparsers::Pagel object.
 Alias   :
 Returns : A Bio::Phylo::Unparsers::Pagel object.
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

 Type    : Unparser
 Title   : to_string($tree)
 Usage   : $pagel->to_string($tree);
 Function: Unparses a Bio::Phylo::Tree object into a pagel formatted string.
 Returns : SCALAR
 Args    : Bio::Phylo::Tree

=end comment

=cut

sub _to_string {
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
                foreach ( @{ $taxon->get_data } ) {
                    $string .= ',' . $_->get_char;
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

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The pagel unparser is called by the L<Bio::Phylo::IO|Bio::Phylo::IO> object.
Look there to learn how to create pagel formatted files.

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

$Id: Pagel.pm,v 1.19 2005/09/29 20:31:18 rvosa Exp $

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
