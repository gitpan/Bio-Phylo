# $Id: Listable.pm,v 1.6 2005/08/09 12:36:12 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Listable;
use strict;
use warnings;
use base 'Bio::Phylo';

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

Bio::Phylo::Listable - A base module for analyzing and manipulating phylogenetic
trees.

=head1 SYNOPSIS

 No direct usage, abstract class.

=head1 DESCRIPTION

A listable object is an object that contains multiple smaller objects of the
same type. For example: a tree contains nodes, so it's a listable object.

This class contains methods that are useful for all listable objects: Matrices,
Matrix objects, Taxa, Trees, Tree objects.

The underlying assumption is, as of now, that listable objects are blessed
anonymous arrays.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $obj = new Bio::Phylo::Listable;
 Function: Instantiates a Bio::Phylo::Listable object
 Returns : A Bio::Phylo::Listable object.
 Args    : none

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless( $self, $class );
    return $self;
}

=item insert($obj)

Since listable objects are arrays, we can simply add to them (e.g. adding a node
to a tree, without regard to how it is connected to others) by using push. To
make sure we're pushing the right objects into the array we have to check their
type. Since we don't want to test for ref (might break if we subclass) I created
these container and container_type methods, that simply return a string saying
what object is its container (e.g. for a node a TREE is its container), and what
type of container the invocant object is (so for a node the NODE string is
returned).

 Type    : Object method
 Title   : insert(Bio::Phylo::*)
 Usage   : $invocant->insert($obj);
 Function: Adds an object to the invocant.
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.

=cut

sub insert {
    my ( $self, $obj ) = @_;
    my ( $sref, $oref ) = ( ref $self, ref $obj );
    if ( $oref && $obj->can('container') ) {
        push( @{$self}, $obj ) if $self->container_type eq $obj->container;
    }
    else {
        $self->COMPLAIN("\"$sref\" objects don't accept \"$oref\" objects: $@");
        return;
    }
    return $self;
}

=item cross_reference(Bio::Phylo::Taxa)

The cross_reference method links node and datum objects to the taxa they apply
to. After crossreferencing a matrix with a taxa object every datum object has
a reference to a taxon object stored in its datum->[TAXON] field, and every
taxon object has a list of references to datum objects stored in its
taxon->[DATA] field.

 Type    : Generic method
 Title   : cross_reference(Bio::Phylo::Taxa)
 Usage   : $invocant->cross_reference($taxa);
 Function: Crossreferences the entities in the invocant with names in $taxa
 Returns : string
 Args    : A Bio::Phylo::Taxa object
 Comments:

=cut

sub cross_reference {
    my ( $self, $taxa ) = @_;
    my ( $selfref, $taxref ) = ( ref $self, ref $taxa );
    if ( $taxa->can('get_entities') ) {
        foreach ( @{ $self->get_entities } ) {
            if ( $_->can('get_name') && $_->can('set_taxon') ) {
                foreach my $taxon ( @{ $taxa->get_entities } ) {
                    if ( $taxon->get_name eq $_->get_name ) {
                        $_->set_taxon($taxon);
                        if ( $_->container_type eq 'DATUM' ) {
                            $taxon->set_data($_);
                        }
                        if ( $_->container_type eq 'NODE' ) {
                            $taxon->set_nodes($_);
                        }
                    }
                }
            }
            else {
                $self->COMPLAIN("$selfref can't link to $taxref: $@");
                return;
            }
        }
        return $self;
    }
    else {
        $self->COMPLAIN("$taxref does not contain taxa: $@");
        return;
    }
}

=item get_entities()

Returns the full array of objects contained by the listable object.

 Type    : Generic query
 Title   : get_data
 Usage   : $invocant->get_entities;
 Function: Retrieves all entities in the invocant.
 Returns : A list of Bio::Phylo::* objects.
 Args    : none.

=cut

sub get_entities {
    my $self = shift;
    return $self;    # passes by ref
}

=item first()

Jumps to the first element contained by the listable object.

 Type    : Generic query
 Title   : first
 Usage   : $invocant->first;
 Function: Retrieves the first entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

sub first {
    my $self = shift;
    return $self->[0];
}

=item last()

Jumps to the last element contained by the listable object.

 Type    : Generic query
 Title   : last
 Usage   : $invocant->last;
 Function: Retrieves the last entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

sub last {
    my $self = shift;
    return $self->[-1];
}

=item last_index()

Jumps to the last element contained by the listable object.

 Type    : Generic query
 Title   : last_index
 Usage   : $invocant->last_index;
 Function: Returns the highest valid index of the invocant.
 Returns : An integer
 Args    : none.

=cut

sub last_index {
    my $self = shift;
    return $#{$self};
}

=item get_by_value(%options)

The get_by_value method can be used to filter out objects contained by the
listable object that meet a numerical condition.

 Type    : Generic method
 Title   : get_by_value(%options)
 Usage   : $invocant->get_by_value(-value => $value, -ge => $number );
 Function: Iterates through all objects returned by invocant and returns those
           for which their $value (e.g. tree length) is less than (-lt),
           less than or equal to (-le), equal to (-eq), greater than or equal to
           (-ge), or greater than (-gt) $number.
 Returns : A list of objects
 Args    : -value = any of the numerical obj data (e.g. tree length)
           -lt = less than
           -le = less than or equals
           -eq = equals
           -ge = greater than or equals
           -gt = greater than

=cut

sub get_by_value {
    my $self = shift;
    my %o    = @_;
    my @results;
    foreach my $e ( @{ $self->get_entities } ) {
        if ( $o{ -eq } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) == $o{ -eq } ) {
                push( @results, $e );
            }
        }
        if ( $o{ -le } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) <= $o{ -le } ) {
                push( @results, $e );
            }
        }
        if ( $o{ -lt } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) < $o{ -lt } ) {
                push( @results, $e );
            }
        }
        if ( $o{ -ge } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) >= $o{ -ge } ) {
                push( @results, $e );
            }
        }
        if ( $o{ -gt } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) > $o{ -gt } ) {
                push( @results, $e );
            }
        }
    }
    return \@results;    # pass by ref
}

=item get_by_regular_expression(%options)

The get_by_regular_expression method can be used to filter out objects contained
by the listable object that match a regular expression.

 Type    : Query
 Title   : get_by_regular_expression(-value => $varname, -match => $re)
 Usage   : $matrix->get_by_regular_expression(
                -value => type,
                -match => ^[D|R]NA$
            );
 Function: Retrieves the data in the current
           Bio::Phylo::Listable object whose $varname matches $re
 Returns : A list of Bio::Phylo::* objects.
 Args    : -value = any of the string datum props (e.g. 'type', 'char')
           -match = a regular expression without delimiters.
 Comments: In the usage example all datum objects whose type is either DNA
           or RNA are returned.

=cut

sub get_by_regular_expression {
    my $self = shift;
    my %o    = @_;
    my @matches;
    foreach my $e ( @{ $self->get_entities } ) {
        if ( $o{-match} ) {
            if ( $e->can( $o{-value} ) && $e->get( $o{-value} ) =~ $o{-match} )
            {
                push( @matches, $e );
            }
        }
        else {
            $self->COMPLAIN("Need a regular expression to evaluate: $@");
            return;
        }
    }
    return \@matches;
}

=item get_by_index($i)

The get_by_index method is used to retrieve the i'th entity contained by a
listable object.

 Type    : Query
 Title   : get_by_index($i)
 Usage   : $matrix->get_by_index($i);
 Function: Retrieves the i'the entity from a listable object.
 Returns : An entity stored by a listable object.
 Args    : An index;
 Comments: Throws if out-of-bounds

=cut

sub get_by_index {
    my $self = shift;
    my $i    = shift;
    my $returnvalue;
    eval { $returnvalue = $self->[$i]; };
    if ($@) {
        $self->COMPLAIN("index out of bounds: $@");
        return;
    }
    else {
        return $returnvalue;
    }
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>
L<http://www.sfu.ca/~rvosa/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed
from BioPerl L<http://www.bioperl.org>, and CIPRES
L<http://www.phylo.org> and FAB* L<http://www.sfu.ca/~fabstar> for
comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
