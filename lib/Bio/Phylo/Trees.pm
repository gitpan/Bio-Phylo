# $Id: Trees.pm,v 1.6 2005/07/26 21:05:38 rvosa Exp $
# Subversion: $Rev: 132 $
package Bio::Phylo::Trees;
use strict;
use warnings;
use base qw(Bio::Phylo::Listable);

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 132 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.01';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);

=head1 NAME

Bio::Phylo::Trees - An object-oriented module for phylogenetic trees

=head1 SYNOPSIS

 use Bio::Phylo::Trees;
 my $trees = new Bio::Phylo::Trees;

=head1 DESCRIPTION

The Bio::Phylo::Trees object models a set of trees. The object subclasses the
Bio::Phylo::Listable object, and so the set of trees can be filtered
using the methods therein.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $trees = new Bio::Phylo::Trees;
 Function: Instantiates a Bio::Phylo::Trees object.
 Returns : A Bio::Phylo::Trees object.
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
 Usage   : $trees->container;
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
 Usage   : $trees->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'TREES';
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Phylo>.
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
