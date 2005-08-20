# $Id: Matrices.pm,v 1.7 2005/08/11 19:41:12 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Matrices;
use strict;
use warnings;
use base 'Bio::Phylo::Listable';

# One line so MakeMaker sees it.
use Bio::Phylo;  our $VERSION = $Bio::Phylo::VERSION;

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 148 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
$VERSION .= '_' . $rev;
use vars qw($VERSION);

my $VERBOSE = 1;

=head1 NAME

Bio::Phylo::Matrices - An object-oriented module for matrices holding
phylogenetic data

=head1 SYNOPSIS

 use Bio::Phylo::Matrices;
 my $matrices = new Bio::Phylo::Matrices;

=head1 DESCRIPTION

The Bio::Phylo::Matrices object models a set of matrices. It inherits from
the Bio::Phylo::Listable object, and so the filtering methods of that object
are available to apply to a set of matrices.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $matrices = new Bio::Phylo::Matrices;
 Function: Initializes a Bio::Phylo::Matrices object.
 Returns : A Bio::Phylo::Matrices object.
 Args    : none.

=cut

sub new {
    my $class = $_[0];
    my $self  = [];
    bless( $self, $class );
    return $self;
}

=back

=head2 CONTAINER

=over

=item container

 Type    : Internal method
 Title   : container
 Usage   : $matrices->container;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container {
    return 'PHYLO';
}

=item container_type

 Type    : Internal method
 Title   : container_type
 Usage   : $matrices->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'MATRICES';
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
