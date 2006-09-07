# $Id: Listable.pm 1723 2006-07-20 07:27:45Z rvosa $
package Bio::Phylo::Listable;
use strict;
use Bio::Phylo;
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Util::CONSTANT qw(:all);
use Scalar::Util qw(blessed);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo);
{

    # inside out class arrays
    my @entities;
    my @index;

    # $fields hashref necessary for object destruction
    my $fields = {
        '-entities' => \@entities,
        '-index'    => \@index,
    };

=head1 NAME

Bio::Phylo::Listable - Parent class for listable/iterator objects.

=head1 SYNOPSIS

 No direct usage, parent class. Methods documented here 
 are available for all objects that inherit from it.

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
        my $class = shift;
        my ( $package, $filename, $line ) = caller;        
        $package = $class if $package eq 'main';
        my @array;
        tie @array, $package, @_;
        return bless \@array, $package;
    }
    
    sub TIEARRAY {
        my $class = shift;
        my $self = __PACKAGE__->SUPER::new( @_ );
        bless $self, $class;
        $entities[ $self->get_id ] = [];
        if ( @_ ) {
            my %opt;
            eval { %opt = @_; };
            if ( $@ ) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( 
                    'error' => $@,                
                );
            }
            else {
                while ( my ( $key, $value ) = each %opt ) {
                    if ( $fields->{$key} ) {
                        $fields->{$key}->[ $self->get_id ] = $value;
                        delete $opt{$key};
                    }
                }
                @_ = %opt;
            }
        }
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
        $self = tied @$self if UNIVERSAL::isa( $self, 'ARRAY' );
        my ( $sref, $oref ) = ( ref $self, ref $obj );
        if ( $oref && $obj->can('_container') ) {
            if ( $self->_type == $obj->_container ) {
                if ( $self->can('get_type') && $obj->can('get_type') ) {                    
                    my ( $stype, $otype ) = ( $self->get_type, $obj->get_type );
                    if ( $stype !~ m/^$otype$/i ) {
                        Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                              error => 
                              sprintf(
                                  'Data type mismatch for %s and %s: %s vs. %s', 
                                  $sref, $oref, $stype, $otype
                              )
                        );
                    }
                }                
                push @{ $entities[ $self->get_id ] }, $obj;
                $obj->_set_container($self);
            }
            else {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw( 
                    error => 
                    sprintf(
                        '%s objects don\'t accept %s objects',
                        $sref, $oref
                    )
                );
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error =>                     
                sprintf(
                    '%s objects don\'t accept %s objects',
                    $sref, $oref
                )
            );
        }
        $self->_flush_cache;
        return $self;
    }
    
=item insert_at_index()

 Type    : Object method
 Title   : insert_at_index
 Usage   : $obj->insert_at_index($other_obj, $i);
 Function: Inserts $other_obj at index $i in container $obj
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.

=cut    
    
    sub insert_at_index {
        my ( $self, $obj, $index ) = @_;
        $self = tied @$self if UNIVERSAL::isa( $self, 'ARRAY' );
        my ( $sref, $oref ) = ( ref $self, ref $obj );
        if ( $oref && $obj->can('_container') ) {
            if ( $self->_type == $obj->_container ) {
                if ( $self->can('get_type') && $obj->can('get_type') ) {                    
                    my ( $stype, $otype ) = ( $self->get_type, $obj->get_type );
                    if ( $stype !~ m/^$otype$/i ) {
                        Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                              error => 
                              sprintf(
                                  'Data type mismatch for %s and %s: %s vs. %s', 
                                  $sref, $oref, $stype, $otype
                              )
                        );
                    }
                }                
                $entities[ $self->get_id ]->[$index] = $obj;
                $obj->_set_container($self);
            }
            else {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw( 
                    error => 
                    sprintf(
                        '"%s" objects don\'t accept "%s" objects',
                        $sref, $oref
                    )
                );
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error =>                     
                sprintf(
                    '"%s" objects don\'t accept "%s" objects',
                    $sref, $oref
                )
            );
        }
        $self->_flush_cache;
        return $self;
    }    

=item delete()

 Type    : Object method
 Title   : delete
 Usage   : $obj->delete($other_obj);
 Function: Deletes an object from its container.
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.
 Note    : Be careful with this method: deleting 
           a node from a tree like this will 
           result in undefined references in its 
           neighbouring nodes. Its children will 
           have their parent reference become 
           undef (instead of pointing to their 
           grandparent, as collapsing a node would 
           do). The same is true for taxon objects 
           that reference datum objects: if the 
           datum object is deleted from a matrix 
           (say), the taxon will now hold undefined 
           references.
           
=cut

    sub delete {
        my ( $self, $obj ) = @_;
        if (   ref $obj
            && $obj->can('_container')
            && $obj->_container == $self->_type )
        {
            my $occurence_counter = 0;
            if ( my $i = $index[ $self->get_id ] ) {
                for my $j ( 0 .. $i ) {
                    if ( $entities[ $self->get_id ]->[$j] == $obj ) {
                        $occurence_counter++;
                    }
                }
            }
            my @modified = grep { $_ != $obj } @{ $entities[ $self->get_id ] };
            $entities[ $self->get_id ] = \@modified;
            $index[ $self->get_id ] -= $occurence_counter;
            $self->_flush_cache;
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => "Invocant object cannot contain argument object", );
        }
        return $self;
    }

=item cross_reference()

The cross_reference method links node and datum objects to the taxa they apply
to. After crossreferencing a matrix with a taxa object, every datum object has
a reference to a taxon object stored in its C<$datum-E<gt>get_taxon> field, and
every taxon object has a list of references to datum objects stored in its
C<$taxon-E<gt>get_data> field.

 Type    : Generic method
 Title   : cross_reference
 Usage   : $obj->cross_reference($taxa);
 Function: Crossreferences the entities 
           in the invocant with names 
           in $taxa
 Returns : string
 Args    : A Bio::Phylo::Taxa object
 Comments:

=cut

    sub cross_reference {
        my ( $self, $taxa ) = @_;
        my ( $selfref, $taxref ) = ( ref $self, ref $taxa );
        if ( $taxa->can('get_entities') ) {
            my $ents = $self->get_entities;
            if ( $ents && @{$ents} ) {
                foreach ( @{$ents} ) {
                    if ( $_->can('get_name') && $_->can('set_taxon') ) {
                        my $tax = $taxa->get_entities;
                        if ( $tax && @{$tax} ) {
                            foreach my $taxon ( @{$tax} ) {
                                if ( not $taxon->get_name or not $_->get_name )
                                {
                                    next;
                                }
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
                    }
                    else {
                        Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                            error => "$selfref can't link to $taxref" );
                    }
                }
            }
            if ( $self->_type == _TREE_ ) {
                $self->_get_container->set_taxa($taxa);
            }
            elsif ( $self->_type == _MATRIX_ ) {
                $self->set_taxa($taxa);
            }
            return $self;
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => "$taxref does not contain taxa" );
        }
    }

=item get_entities()

Returns a reference to an array of objects contained by the listable object.

 Type    : Generic query
 Title   : get_entities
 Usage   : my @entities = @{ $obj->get_entities };
 Function: Retrieves all entities in the invocant.
 Returns : A reference to a list of Bio::Phylo::* 
           objects.
 Args    : none.

=cut

    sub get_entities {
        my $self = shift;
        return $entities[ $self->get_id ];
    }

=item contains()

 Type    : Test
 Title   : contains
 Usage   : if ( $obj->contains( $other_obj ) ) {
               # do something
           }
 Function: Tests whether the invocant object 
           contains the argument object
 Returns : BOOLEAN
 Args    : A Bio::Phylo::* object
 
=cut

    sub contains {
        my ( $self, $obj ) = @_;
        if ( blessed $obj ) {
            foreach my $ent ( @{ $self->get_entities } ) {
                return 1 if $ent == $obj;
            }
            return 0;
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                error => "\"$obj\" is not a blessed object!" );
        }
    }

=back

=head2 ITERATOR METHODS

=over

=item first()

Jumps to the first element contained by the listable object.

 Type    : Iterator
 Title   : first
 Usage   : my $first_obj = $obj->first;
 Function: Retrieves the first 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

    sub first {
        my $self = shift;
        $index[ $self->get_id ] = 0;
        return $entities[ $self->get_id ]->[0];
    }

=item last()

Jumps to the last element contained by the listable object.

 Type    : Iterator
 Title   : last
 Usage   : my $last_obj = $obj->last;
 Function: Retrieves the last 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

    sub last {
        my $self = shift;
        $index[ $self->get_id ] = $#{ $entities[ $self->get_id ] };
        return $entities[ $self->get_id ]->[-1];
    }

=item current()

Returns the current focal element of the listable object.

 Type    : Iterator
 Title   : current
 Usage   : my $current_obj = $obj->current;
 Function: Retrieves the current focal 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

    sub current {
        my $self = shift;
        if ( !defined $index[ $self->get_id ] ) {
            $index[ $self->get_id ] = 0;
        }
        return $entities[ $self->get_id ]->[ $index[ $self->get_id ] ];
    }

=item next()

Returns the next focal element of the listable object.

 Type    : Iterator
 Title   : next
 Usage   : my $next_obj = $obj->next;
 Function: Retrieves the next focal 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

    sub next {
        my $self = shift;
        if ( !defined $index[ $self->get_id ] ) {
            $index[ $self->get_id ] = 0;
            return $entities[ $self->get_id ]->[ $index[ $self->get_id ] ];
        }
        elsif ( ( $index[ $self->get_id ] + 1 ) <= $#{ $entities[ $self->get_id ] } ) {
            $index[ $self->get_id ]++;
            return $entities[ $self->get_id ]->[ $index[ $self->get_id ] ];
        }
        else {
            return;
        }
    }

=item previous()

Returns the previous element of the listable object.

 Type    : Iterator
 Title   : previous
 Usage   : my $previous_obj = $obj->previous;
 Function: Retrieves the previous 
           focal entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=cut

    sub previous {
        my $self = shift;
        if ( !$index[ $self->get_id ] ) {    # either undef or 0
            return;
        }
        elsif ( ( $index[ $self->get_id ] - 1 ) >= 0 ) {
            $index[ $self->get_id ]--;
            return $entities[ $self->get_id ]->[ $index[ $self->get_id ] ];
        }
        else {
            return;
        }
    }

=item current_index()

Returns the current internal index of the invocant.

 Type    : Generic query
 Title   : current_index
 Usage   : my $last_index = $obj->current_index;
 Function: Returns the current internal 
           index of the invocant.
 Returns : An integer
 Args    : none.

=cut

    sub current_index {
        my $self = shift;
        defined $index[ $self->get_id ] ? return $index[ $self->get_id ] : return 0;
    }

=item last_index()

Returns the highest valid index of the invocant.

 Type    : Generic query
 Title   : last_index
 Usage   : my $last_index = $obj->last_index;
 Function: Returns the highest valid 
           index of the invocant.
 Returns : An integer
 Args    : none.

=cut

    sub last_index {
        my $self = shift;
        return $#{ $entities[ $self->get_id ] };
    }

=item get_by_index()

The get_by_index method is used to retrieve the i'th entity contained by a
listable object.

 Type    : Query
 Title   : get_by_index
 Usage   : my $contained_obj = $obj->get_by_index($i);
 Function: Retrieves the i'th entity 
           from a listable object.
 Returns : An entity stored by a listable 
           object (or array ref for slices).
 Args    : An index or range. This works 
           the way you dereference any perl
           array including through slices, 
           i.e. C<$obj-E<gt>get_by_index(0 .. 10)>
           C<$obj-E<gt>get_by_index(0, -1)> 
           and so on.
 Comments: Throws if out-of-bounds

=cut

    sub get_by_index {
        my $self  = shift;
        my @range = @_;
        if ( scalar @range > 1 ) {
            my @returnvalue;
            eval { @returnvalue = @{ $entities[ $self->get_id ] }[@range] };
            if ($@) {
                Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                    error => 'index out of bounds' );
            }
            return \@returnvalue;
        }
        else {
            my $returnvalue;
            eval { $returnvalue = $entities[ $self->get_id ]->[ $range[0] ] };
            if ($@) {
                Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                    error => 'index out of bounds' );
            }
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
 Function: Iterates through all objects 
           contained by $obj and returns 
           those for which the output of 
           $method (e.g. get_tree_length) 
           is less than (-lt), less than 
           or equal to (-le), equal to 
           (-eq), greater than or equal to 
           (-ge), or greater than (-gt) $number.
 Returns : A reference to an array of objects
 Args    : -value => any of the numerical 
                     obj data (e.g. tree length)
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
                if (   $e->get( $o{-value} )
                    && $e->get( $o{-value} ) == $o{ -eq } )
                {
                    push @results, $e;
                }
            }
            if ( $o{ -le } ) {
                if (   $e->get( $o{-value} )
                    && $e->get( $o{-value} ) <= $o{ -le } )
                {
                    push @results, $e;
                }
            }
            if ( $o{ -lt } ) {
                if (   $e->get( $o{-value} )
                    && $e->get( $o{-value} ) < $o{ -lt } )
                {
                    push @results, $e;
                }
            }
            if ( $o{ -ge } ) {
                if (   $e->get( $o{-value} )
                    && $e->get( $o{-value} ) >= $o{ -ge } )
                {
                    push @results, $e;
                }
            }
            if ( $o{ -gt } ) {
                if (   $e->get( $o{-value} )
                    && $e->get( $o{-value} ) > $o{ -gt } )
                {
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
 Usage   : my @objects = @{ 
               $obj->get_by_regular_expression(
                    -value => $method,
                    -match => $re
            ) };
 Function: Retrieves the data in the 
           current Bio::Phylo::Listable 
           object whose $method output 
           matches $re
 Returns : A list of Bio::Phylo::* objects.
 Args    : -value => any of the string 
                     datum props (e.g. 'get_type')
           -match => a compiled regular 
                     expression (e.g. qr/^[D|R]NA$/)

=cut

    sub get_by_regular_expression {
        my $self = shift;
        my %o    = @_;
        my @matches;
        foreach my $e ( @{ $self->get_entities } ) {
            if ( $o{-match} && ref $o{-match} eq 'Regexp' ) {
                if (   $e->get( $o{-value} )
                    && $e->get( $o{-value} ) =~ $o{-match} )
                {
                    push @matches, $e;
                }
            }
            else {
                Bio::Phylo::Util::Exceptions::BadArgs->throw(
                    error => 'need a regular expression to evaluate' );
            }
        }
        return \@matches;
    }

=item visit()

The visit method can be used to iterate over all objects in the Listable object.
At every iteration, the CODE reference in the argument is applied to the focal
object. The object enters the CODE reference as $_[0]. The objects are visited
in the order in which they were inserted in the Listable object.

 Type    : Visitor predicate
 Title   : visit
 Usage   : $obj->visit( 
               sub{ print $_[0]->get_name, "\n" } 
           );
 Function: Implements visitor pattern 
           using code reference.
 Returns : The invocant, possibly modified.
 Args    : a CODE reference.

=cut

    sub visit {
        my ( $self, $code ) = @_;
        if ( ref $code eq 'CODE' ) {
            foreach ( @{ $self->get_entities } ) {
                $code->($_);
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                error => "\"$code\" is not a CODE reference!" );
        }
        return $self;
    }

=back

=head2 DESTRUCTOR

=over

=item DESTROY()

 Type    : Destructor
 Title   : DESTROY
 Usage   : $phylo->DESTROY
 Function: Destroys Phylo object
 Alias   :
 Returns : TRUE
 Args    : none
 Comments: You don't really need this, 
           it is called automatically when
           the object goes out of scope.

=cut

    sub DESTROY {
        my $self = shift;
        if ( my $i = $self->get_id ) {
            foreach ( keys %{$fields} ) {
                delete $fields->{$_}->[$i];
            }
        }
        $self->SUPER::DESTROY;
        return 1;
    }

=begin comment

=end comment

=cut
    
    sub FETCH {
        my ( $self, $index ) = @_;
        return $entities[ $self->get_id ]->[$index];
    }
    
    sub STORE {
        my( $self, $index, $value ) = @_;
        $self->insert_at_index( $value, $index );
        $self->EXTEND( $index ) if $index > $self->FETCHSIZE();
    }
    
    sub FETCHSIZE {
        my $self = shift;
        return scalar @{ $entities[ $self->get_id ] };
    }
    
    sub STORESIZE {
        my $self  = shift;
        my $count = shift;                
        if ( $count > $self->FETCHSIZE() ) {
            foreach ( $count - $self->FETCHSIZE() .. $count ) {
                $self->STORE( $_, '' );
            }
        } 
        elsif ( $count < $self->FETCHSIZE() ) {
            foreach ( 0 .. $self->FETCHSIZE() - $count - 2 ) {
                $self->POP();
            }
        }
    }
    
    sub EXTEND {   
        my $self  = shift;
        my $count = shift;
        $self->STORESIZE( $count );
    }
    
    sub EXISTS {
        my $self  = shift;
        my $index = shift;
        return exists $entities[ $self->get_id ]->[$index];
    }
    
    sub DELETE {
        my $self  = shift;
        my $index = shift;
        return delete $entities[ $self->get_id ]->[$index];
    }
    
    sub CLEAR {
        my $self = shift;
        return $entities[ $self->get_id ] = [];
    }
    
    sub PUSH {  
        my $self = shift;
        $self->insert($_) for @_;
        return $self->FETCHSIZE();
    } 
    
    sub POP {
        my $self = shift;
        return pop @{ $entities[ $self->get_id ] };
    }
    
    sub SHIFT {
        my $self = shift;
        return shift @{ $entities[ $self->get_id ] };
    }
    
    sub UNSHIFT {
        my $self = shift;
        my @list = @_;
        my $size = scalar( @list );
        @{ $entities[ $self->get_id ] }[ $size .. $#{ $entities[ $self->get_id ] } + $size ] = @{ $entities[ $self->get_id ] };
        $self->insert_at_index( $list[$_], $_ ) for ( 0 .. $#list );
    }
    
    sub SPLICE {
        my $self   = shift;
        my $offset = shift || 0;
        my $length = shift || $self->FETCHSIZE() - $offset;
        splice @{ $entities[ $self->get_id ] }, $offset, $length;
        for my $i ( 0 .. $#_ ) {
            $self->insert_at_index( $_, $i + $offset );
        }
        return @$self[ $offset .. ( $length + $offset ) ];
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

$Id: Listable.pm 1723 2006-07-20 07:27:45Z rvosa $

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

}
1;
