# $Id: Matrix.pm,v 1.6 2005/08/09 12:36:13 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Matrices::Matrix;
use strict;
use warnings;
use base 'Bio::Phylo::Listable';

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

Bio::Phylo::Matrices::Matrix - An object-oriented module for phylogenetic data.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Matrix;
 my $matrix = new Bio::Phylo::Matrices::Matrix;

=head1 DESCRIPTION

 This module is only used in combination with Phylo, Phylo::Parsers
 and Phylo::Trees::Node

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $matrix = new Bio::Phylo::Matrices::Matrix;
 Function: Instantiates a Bio::Phylo::Matrices::Matrix object.
 Returns : A Bio::Phylo::Matrices::Matrix object.
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

=item container()

 Type    : Internal method
 Title   : container
 Usage   : $matrix->container;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container {
    return 'MATRICES';
}

=item container_type()

 Type    : Internal method
 Title   : container_type
 Usage   : $matrix->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'MATRIX';
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
