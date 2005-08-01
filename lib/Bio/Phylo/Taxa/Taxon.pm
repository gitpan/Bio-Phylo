# $Id: Taxon.pm,v 1.4 2005/08/01 23:06:18 rvosa Exp $
# Subversion: $Rev: 147 $
package Bio::Phylo::Taxa::Taxon;
use strict;
use warnings;
use base 'Bio::Phylo';

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

Bio::Phylo::Taxa::Taxon - An object-oriented module for managing a single taxon.

=head1 SYNOPSIS

 my $taxon = Bio::Phylo::Taxa::Taxon->new(
    -name=>'Homo_sapiens',
    -desc=>'Canonical taxon'
 );

=head1 DESCRIPTION

The taxon object models a single operational taxonomic unit. It is useful for
cross-referencing datum objects and tree nodes.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $taxon = new Bio::Phylo::Taxa::Taxon;
 Function: Initializes a Bio::Phylo::Taxa::Taxon object.
 Returns : A Bio::Phylo::Taxa::Taxon object.
 Args    : none.

=cut

sub new {
    my $class = shift;
    my %args  = @_ if @_;
    my $self  = {};
    $self->{'NAME'}  = $args{'-name'}       if $args{'-name'};
    $self->{'DESC'}  = $args{'-desc'}       if $args{'-desc'};
    $self->{'NODES'} = @{ $args{'-nodes'} } if $args{'-nodes'};
    $self->{'DATA'}  = @{ $args{'-data'} }  if $args{'-data'};
    bless( $self, $class );
    return $self;
}

=back

=head2 MUTATORS

=over

=item set_name()

 Type    : Mutator
 Title   : set_name
 Usage   : $taxon->set_name($newname);
 Function: Assigns a taxon's name.
 Returns :
 Args    : $newname must not contain [;|,|:|(|)]

=cut

sub set_name {
    my $self = $_[0];
    my $name = $_[1];
    my $ref  = ref $self;
    if ( $name =~ m/([;|,|:|\(|\)])/ ) {
        $self->COMPLAIN("\"$name\" is a bad name format for $ref names: $@");
        return;
    }
    else {
        $self->{'NAME'} = $name;
    }
}

=item set_desc()

 Type    : Mutator
 Title   : set_desc
 Usage   : $taxon->set_desc($newdesc);
 Function: Assigns a description of the current taxon.
 Returns :
 Args    : A SCALAR string of arbitrary length

=cut

sub set_desc {
    my $self = $_[0];
    $self->{'DESC'} = $_[1];
}

=item set_data()

 Type    : Mutator
 Title   : set_data
 Usage   : $taxon->set_data($datum);
 Function: Associates data with the current taxon.
 Returns :
 Args    : Must be an object of type Bio::Phylo::Matrices::Datum

=cut

sub set_data {
    my $self  = $_[0];
    my $datum = $_[1];
    if ( $datum->can('container_type') && $datum->container_type eq 'DATUM' ) {
        push( @{ $self->{'DATA'} }, $datum );
    }
    else {
        $self->COMPLAIN(
            "Sorry, data must be of type Bio::Phylo::Matrices::Datum: $@");
        return;
    }
}

=item set_nodes()

 Type    : Mutator
 Title   : set_nodes
 Usage   : $taxon->set_nodes($node);
 Function: Associates tree nodes with the current taxon.
 Returns :
 Args    : A Bio::Phylo::Trees::Node object

=cut

sub set_nodes {
    my $self = $_[0];
    my $node = $_[1];
    my $ref  = ref $node;
    if ( $node->can('container_type') && $node->container_type eq 'NODE' ) {
        push( @{ $self->{'NODES'} }, $node );
    }
    else {
        $self->COMPLAIN("$ref doesn't look like a node: $@");
        return;
    }
}

=back

=head2 ACCESSORS

=over

=item get_name()

 Type    : Accessor
 Title   : get_name
 Usage   : $name = $taxon->get_name();
 Function: Retrieves a taxon's name.
 Returns : SCALAR
 Args    :

=cut

sub get_name {
    return $_[0]->{'NAME'};
}

=item get_desc()

 Type    : Accessor
 Title   : get_desc
 Usage   : $desc = $taxon->get_desc();
 Function: Assigns a description of the current taxon.
 Returns : SCALAR
 Args    :

=cut

sub get_desc {
    return $_[0]->{'DESC'};
}

=item get_data()

 Type    : Accessor
 Title   : get_data
 Usage   : @data = $taxon->get_data();
 Function: Retrieves data associated with the current taxon.
 Returns : An ARRAY of Bio::Phylo::Matrices::Datum objects.
 Args    :

=cut

sub get_data {
    return $_[0]->{'DATA'};
}

=item get_nodes()

 Type    : Accessor
 Title   : get_nodes
 Usage   : @nodes = $taxon->get_nodes();
 Function: Retrieves tree nodes associated with the current taxon.
 Returns : An ARRAY of Bio::Phylo::Trees::Node objects
 Args    :

=cut

sub get_nodes {
    return $_[0]->{'NODES'};
}

=back

=head2 CONTAINER

=over

=item container

 Type    : Internal method
 Title   : container
 Usage   : $taxon->container;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container {
    return 'TAXA';
}

=item container_type

 Type    : Internal method
 Title   : container_type
 Usage   : $taxon->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'TAXON';
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
