# $Id: Listable.pm,v 1.23 2005/09/29 20:31:17 rvosa Exp $
# Subversion: $Rev: 185 $
package Bio::Phylo::Listable;
use strict;
use warnings;
use base 'Bio::Phylo';
use Bio::Phylo::CONSTANT qw(:all);
use fields qw(ENTITIES
              INDEX);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Listable - Abstract class for listable/iterator objects.

=head1 SYNOPSIS

 No direct usage, abstract class. Methods documented here are available for
 all objects that inherit from it.

=head1 DESCRIPTION

A listable object is an object that contains multiple smaller objects of the
same type. For example: a tree contains nodes, so it's a listable object.

This class contains methods that are useful for all listable objects: Matrices,
Matrix objects, Alignment objects, Taxa, Forest, Tree objects.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $obj = Bio::Phylo::Listable->new;
 Function: Instantiates a Bio::Phylo::Listable object
 Returns : A Bio::Phylo::Listable object.
 Args    : none

=cut

sub new {
    my Bio::Phylo::Listable $self = shift;
    unless (ref $self) {
        $self = fields::new($self);
    }
    $self->{'ENTITIES'} = [];
    $self->{'INDEX'}    = undef;
    return $self;
}

=back

=head2 ARRAY METHODS

=over

=item insert()

 Type    : Object method
 Title   : insert
 Usage   : $obj->insert($other_obj);
 Function: Pushes an object into its container.
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.

=cut

sub insert {
    my ( $self, $obj ) = @_;
    my ( $sref, $oref ) = ( ref $self, ref $obj );
    if ( $oref && $obj->can('_container') ) {
        if ( $self->_type == $obj->_container ) {
            push @{$self->{'ENTITIES'}}, $obj;
        }
        else {
            Bio::Phylo::Exceptions::ObjectMismatch->throw(
                error => "\"$sref\" objects don't accept \"$oref\" objects"
            );
        }
    }
    else {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => "\"$sref\" objects don't accept \"$oref\" objects"
        );
    }
    return $self;
}

=item cross_reference()

The cross_reference method links node and datum objects to the taxa they apply
to. After crossreferencing a matrix with a taxa object, every datum object has
a reference to a taxon object stored in its C<< datum->{TAXON} >> field, and
every taxon object has a list of references to datum objects stored in its
C<< taxon->{DATA} >> field.

 Type    : Generic method
 Title   : cross_reference
 Usage   : $obj->cross_reference($taxa);
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
                        if ( $_->_type == _DATUM_ ) {
                            $taxon->set_data($_);
                        }
                        if ( $_->_type == _NODE_ ) {
                            $taxon->set_nodes($_);
                        }
                    }
                }
            }
            else {
                Bio::Phylo::Exceptions::ObjectMismatch->throw(
                    error => "$selfref can't link to $taxref"
                );
            }
        }
        return $self;
    }
    else {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => "$taxref does not contain taxa"
        );
    }
}

=item get_entities()

Returns a reference to an array of objects contained by the listable object.

 Type    : Generic query
 Title   : get_entities
 Usage   : my @entities = @{ $obj->get_entities };
 Function: Retrieves all entities in the invocant.
 Returns : A reference to a list of Bio::Phylo::* objects.
 Args    : none.

=cut

sub get_entities {
    return $_[0]->{'ENTITIES'};
}

=back

=head2 ITERATOR METHODS

=over

=item first()

Jumps to the first element contained by the listable object.

 Type    : Iterator
 Title   : first
 Usage   : my $first_obj = $obj->first;
 Function: Retrieves the first entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

sub first {
    my $self = shift;
    $self->{'INDEX'} = 0;
    return $self->{'ENTITIES'}->[$self->{'INDEX'}];
}

=item last()

Jumps to the last element contained by the listable object.

 Type    : Iterator
 Title   : last
 Usage   : my $last_obj = $obj->last;
 Function: Retrieves the last entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

sub last {
    my $self = shift;
    $self->{'INDEX'} = $#{$self->{'ENTITIES'}};
    return $self->{'ENTITIES'}->[$self->{'INDEX'}];
}

=item current()

Returns the current focal element of the listable object.

 Type    : Iterator
 Title   : current
 Usage   : my $current_obj = $obj->current;
 Function: Retrieves the current focal entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

sub current {
    my $self = shift;
    if ( ! defined $self->{'INDEX'} ) {
    	$self->{'INDEX'} = 0;
    }
    return $self->{'ENTITIES'}->[$self->{'INDEX'}];
}

=item next()

Returns the next focal element of the listable object.

 Type    : Iterator
 Title   : next
 Usage   : my $next_obj = $obj->next;
 Function: Retrieves the next focal entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

sub next {
    my $self = shift;
    if ( ! defined $self->{'INDEX'} ) {
    	$self->{'INDEX'} = 0;
    	return $self->{'ENTITIES'}->[$self->{'INDEX'}];
    }
    elsif ( ( $self->{'INDEX'} + 1 ) <= $#{ $self->{'ENTITIES'} } ) {
        $self->{'INDEX'}++;
        return $self->{'ENTITIES'}->[$self->{'INDEX'}];
    }
    else {
        return;
    }
}

=item previous()

Returns the next previous element of the listable object.

 Type    : Iterator
 Title   : previous
 Usage   : my $previous_obj = $obj->previous;
 Function: Retrieves the previous focal entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

sub previous {
    my $self = shift;
    if ( ! $self->{'INDEX'} ) { # either undef or 0
    	return;
    }
    elsif ( ( $self->{'INDEX'} - 1 ) >= 0 ) {
        $self->{'INDEX'}--;
        return $self->{'ENTITIES'}->[$self->{'INDEX'}];
    }
    else {
        return;
    }
}

=item last_index()

Returns the highest valid index of the invocant.

 Type    : Generic query
 Title   : last_index
 Usage   : my $last_index = $obj->last_index;
 Function: Returns the highest valid index of the invocant.
 Returns : An integer
 Args    : none.

=cut

sub last_index {
    my $self = shift;
    return $#{$self->{'ENTITIES'}};
}

=item get_by_index()

The get_by_index method is used to retrieve the i'th entity contained by a
listable object.

 Type    : Query
 Title   : get_by_index
 Usage   : my $contained_obj = $obj->get_by_index($i);
 Function: Retrieves the i'th entity from a listable object.
 Returns : An entity stored by a listable object.
 Args    : An index;
 Comments: Throws if out-of-bounds

=cut

sub get_by_index {
    my $self = shift;
    my $i    = shift;
    my $returnvalue;
    eval { $returnvalue = $self->{'ENTITIES'}->[$i]; };
    if ($@) {
        Bio::Phylo::Exceptions::OutOfBounds->throw(
            error => 'index out of bounds'
        );
    }
    else {
        return $returnvalue;
    }
}

=back

=head2 VISITOR METHODS

=over

=item get_by_value()

The get_by_value method can be used to filter out objects contained by the
listable object that meet a numerical condition.

 Type    : Visitor predicate
 Title   : get_by_value
 Usage   : my @objects = @{ $obj->get_by_value(
              -value => $method,
              -ge    => $number
           ) };
 Function: Iterates through all objects contained by $obj and returns those
           for which the output of $method (e.g. get_tree_length) is less than
           (-lt), less than or equal to (-le), equal to (-eq), greater than or
           equal to (-ge), or greater than (-gt) $number.
 Returns : A reference to an array of objects
 Args    : -value => any of the numerical obj data (e.g. tree length)
           -lt    => less than
           -le    => less than or equals
           -eq    => equals
           -ge    => greater than or equals
           -gt    => greater than

=cut

sub get_by_value {
    my $self = shift;
    my %o    = @_;
    my @results;
    foreach my $e ( @{ $self->get_entities } ) {
        if ( $o{ -eq } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) == $o{ -eq } ) {
                push @results, $e;
            }
        }
        if ( $o{ -le } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) <= $o{ -le } ) {
                push @results, $e;
            }
        }
        if ( $o{ -lt } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) < $o{ -lt } ) {
                push @results, $e;
            }
        }
        if ( $o{ -ge } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) >= $o{ -ge } ) {
                push @results, $e;
            }
        }
        if ( $o{ -gt } ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) > $o{ -gt } ) {
                push @results, $e;
            }
        }
    }
    return \@results;
}

=item get_by_regular_expression()

The get_by_regular_expression method can be used to filter out objects contained
by the listable object that match a regular expression.

 Type    : Visitor predicate
 Title   : get_by_regular_expression
 Usage   : my @objects = @{ $obj->get_by_regular_expression(
                -value => $method,
                -match => $re
            ) };
 Function: Retrieves the data in the current
           Bio::Phylo::Listable object whose $method output matches $re
 Returns : A list of Bio::Phylo::* objects.
 Args    : -value => any of the string datum props (e.g. 'get_type')
           -match => a compiled regular expression (e.g. qr/^[D|R]NA$/)

=cut

sub get_by_regular_expression {
    my $self = shift;
    my %o    = @_;
    my @matches;
    foreach my $e ( @{ $self->get_entities } ) {
        if ( $o{-match} && ref $o{-match} eq 'Regexp' ) {
            if ( $e->get( $o{-value} ) && $e->get( $o{-value} ) =~ $o{-match} ) {
                push @matches, $e;
            }
        }
        else {
            Bio::Phylo::Exceptions::BadArgs->throw(
                error => 'need a regular expression to evaluate'
            );
        }
    }
    return \@matches;
}

=back

=head1 SEE ALSO

=head2 Objects inheriting from Bio::Phylo::Listable

=over

=item L<Bio::Phylo::Forest>

Iterate over a set of trees.

=item L<Bio::Phylo::Forest::Tree>

Iterate over nodes in a tree.

=item L<Bio::Phylo::Matrices>

Iterate over a set of matrices.

=item L<Bio::Phylo::Matrices::Matrix>

Iterate over the datum objects in a matrix.

=item L<Bio::Phylo::Matrices::Alignment>

Iterate over the sequences in an alignment.

=item L<Bio::Phylo::Taxa>

Iterate over a set of taxa.

=back

=head2 Superclass

=over

=item L<Bio::Phylo>

The listable class inherits from L<Bio::Phylo>, so look there for more methods
applicable to L<Bio::Phylo::Listable> objects and subclasses.

=back

Also see the manual: L<Bio::Phylo::Manual>.

=head1 FORUM

CPAN hosts a discussion forum for Bio::Phylo. If you have trouble using this
module the discussion forum is a good place to start posting questions (NOT bug
reports, see below): L<http://www.cpanforum.com/dist/Bio-Phylo>

=head1 BUGS

Please report any bugs or feature requests to C<< bug-bio-phylo@rt.cpan.org >>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>. I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes. Be sure to include the following in your request or comment, so that
I know what version you're using:

$Id: Listable.pm,v 1.23 2005/09/29 20:31:17 rvosa Exp $

=head1 AUTHOR

Rutger Vos,

=over

=item email: C<< rvosa@sfu.ca >>

=item web page: L<http://www.sfu.ca/~rvosa/>

=back

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed from
BioPerl L<http://www.bioperl.org>, and CIPRES L<http://www.phylo.org> and
FAB* L<http://www.sfu.ca/~fabstar> for comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
