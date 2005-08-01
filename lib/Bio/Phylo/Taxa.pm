# $Id: Taxa.pm,v 1.4 2005/08/01 23:06:16 rvosa Exp $
# Subversion: $Rev: 147 $
package Bio::Phylo::Taxa;
use strict;
use warnings;
use base 'Bio::Phylo::Listable';

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

=head1 NAME

Bio::Phylo::Taxa - An object-oriented module for managing taxa.

=head1 SYNOPSIS

 use Bio::Phylo::Taxa;
 my $taxa = new Bio::Phylo::Taxa;

=head1 DESCRIPTION

The Bio::Phylo::Taxa object models a set of operational taxonomic units. The
object subclasses the Bio::Phylo::Listable object, and so the filtering
methods of that class are available.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $taxa = new Bio::Phylo::Taxa;
 Function: Initializes a Bio::Phylo::Taxa object.
 Returns : A Bio::Phylo::Taxa object.
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
 Usage   : $taxa->container;
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
 Usage   : $taxa->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'TAXA';
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
