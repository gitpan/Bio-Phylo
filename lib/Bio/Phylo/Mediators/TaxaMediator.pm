package Bio::Phylo::Mediators::TaxaMediator;
use strict;
use warnings;
use Scalar::Util qw(weaken);
use Bio::Phylo;
use Bio::Phylo::Util::Exceptions;

my $logger = 'Bio::Phylo';
my $self;
my ( @object, @relationship );

=head1 NAME

Bio::Phylo::Taxa::TaxaMediator - Mediator class to manage links between objects.

=head1 SYNOPSIS

 # no direct usage

=head1 DESCRIPTION

This module manages links between taxon objects and other objects linked to 
them. It is an implementation of the Mediator design pattern (e.g. see 
L<Relationship Manager Pattern|http://www.atug.com/andypatterns/RM.htm>,
L<Mediator|http://home.earthlink.net/~huston2/dp/mediator.html>,
L<Mediator Design Pattern|http://sern.ucalgary.ca/courses/SENG/443/W02/assignments/Mediator/>).

Methods defined in this module are meant only for internal usage by Bio::Phylo.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $mediator = Bio::Phylo::Taxa::TaxaMediator->new;
 Function: Instantiates a Bio::Phylo::Taxa::TaxaMediator
           object.
 Returns : A Bio::Phylo::Taxa::TaxaMediator object (singleton).
 Args    : None.

=cut

sub new {
    # could be child class
    my $class  = shift;
    
    # notify user
    $logger->info("constructor called for '$class'");
    
    # singleton class
    if ( not $self ) {
        $logger->debug("first time instantiation of singleton");
        $self = \$class;
        bless $self, $class;
    }
    
    return $self;
}

=back

=head2 METHODS

=over

=item register()

 Type    : Method
 Title   : register
 Usage   : $mediator->register( $obj );
 Function: Stores an object in mediator's cache
 Returns : $self
 Args    : An object, $obj
 Comments: This method is called every time an object is instantiated.

=cut

sub register {
    my ( $self, $obj ) = @_;
    
    # notify user
    $logger->info("registering object '$obj'");

    my $id = $obj->get_id;
    $object[ $id ] = $obj;
    weaken $object[ $id ];
    return $self;
}

=item unregister()

 Type    : Method
 Title   : unregister
 Usage   : $mediator->unregister( $obj );
 Function: Cleans up mediator's cache of $obj and $obj's relations
 Returns : $self
 Args    : An object, $obj
 Comments: This method is called every time an object is destroyed.

=cut

sub unregister {
    my ( $self, $obj ) = @_;
    
    # notify user
    $logger->info("unregistering object '$obj'");
    
    my $id = $obj->get_id;
    if ( exists $object[ $id ] ) {
        if ( exists $relationship[ $id ] ) {
            
            # notify user
            $logger->info("deleting one-to-many relationship for '$obj'");
            
            delete $relationship[ $id ];
        }
        else {
            LINK_SEARCH: for my $relation ( @relationship ) {
                if ( exists $relation->{$id} ) {
                    
                    # notify user
                    $logger->info("deleting one-to-one relationship for '$obj'");
                    
                    delete $relation->{$id};
                    last LINK_SEARCH;
                }
            }
        }
        
        # notify user
        $logger->info("deleting '$id' from mediator cache");
        
        delete $object[ $id ];
    }
    return $self;
}

=item set_link()

 Type    : Method
 Title   : set_link
 Usage   : $mediator->set_link( -one => $obj1, -many => $obj2 );
 Function: Creates link between objects
 Returns : $self
 Args    : -one  => $obj1 (source of a one-to-many relationship)
           -many => $obj2 (target of a one-to-many relationship)
 Comments: This method is called from within, for example, set_taxa
           method calls. A call like $taxa->set_matrix( $matrix ),
           and likewise a call like $matrix->set_taxa( $taxa ), are 
           both internally rerouted to:

           $mediator->set_link( 
                -one  => $taxa, 
                -many => $matrix 
           );

=cut

sub set_link {
    my $self = shift;
    my %opt = @_;
    my ( $one, $many ) = ( $opt{'-one'}, $opt{'-many'} );
    my ( $one_id, $many_id ) = ( $one->get_id, $many->get_id );
    
    # notify user
    $logger->info("setting link between '$one' and '$many'");
    
    # delete any previously existing link
    LINK_SEARCH: for my $relation ( @relationship ) {
        if ( exists $relation->{$many_id} ) {
            delete $relation->{$many_id};
            
            # notify user
            $logger->info("deleting previous link");
            
            last LINK_SEARCH;
        }
    }
    
    # initialize new hash if not exist
    $relationship[$one_id] = {} if not $relationship[$one_id];
    my $relation = $relationship[$one_id];
    
    # value is type so that can retrieve in get_link
    $relation->{$many_id} = $many->_type;
    
    return $self;

}

=item get_link()

 Type    : Method
 Title   : get_link
 Usage   : $mediator->get_link( 
               -source => $obj, 
               -type   => _CONSTANT_,
           );
 Function: Retrieves link between objects
 Returns : Linked object
 Args    : -source => $obj (required, the source of the link)
           -type   => a constant from Bio::Phylo::Util::CONSTANT

           (-type is optional, used to filter returned results in 
           one-to-many query).

 Comments: This method is called from within, for example, get_taxa
           method calls. A call like $matrix->get_taxa()
           and likewise a call like $forest->get_taxa(), are 
           both internally rerouted to:

           $mediator->get_link( 
               -source => $self # e.g. $matrix or $forest           
           );

           A call like $taxa->get_matrices() is rerouted to:

           $mediator->get_link( -source => $taxa, -type => _MATRIX_ );

=cut

sub get_link {
    my $self = shift;
    my %opt = @_;
    my $id = $opt{'-source'}->get_id;
    
    # have to get many objects
    if ( defined $opt{'-type'} ) {
        my $relation = $relationship[ $id ];
        return if not $relation;
        my @result;
        for my $key ( keys %{ $relation } ) {
            push @result, $object[ $key ] if $relation->{$key} == $opt{'-type'};
        }
        return \@result;
    }
    else {
        LINK_SEARCH: for my $i ( 0 .. $#relationship ) {
            my $relation = $relationship[ $i ];
            if ( exists $relation->{$id} ) {
                return $object[ $i ];
            }
        }
    }
}

=item remove_link()

 Type    : Method
 Title   : remove_link
 Usage   : $mediator->remove_link( -one => $obj1, -many => $obj2 );
 Function: Creates link between objects
 Returns : $self
 Args    : -one  => $obj1 (source of a one-to-many relationship)
           -many => $obj2 (target of a one-to-many relationship)

           (-many argument is optional)

 Comments: This method is called from within, for example, 
           unset_taxa method calls. A call like $matrix->unset_taxa() 
           is rerouted to:

           $mediator->remove_link( -many => $matrix );

           A call like $taxa->unset_matrix( $matrix ); is rerouted to:

           $mediator->remove_link( -one => $taxa, -many => $matrix );


=cut

sub remove_link {
    my $self = shift;
    my %opt = @_;
    my ( $one, $many ) = ( $opt{'-one'}, $opt{'-many'} );
    if ( $one ) {
        my $id = $one->get_id;
        my $relation = $relationship[ $id ];
        return if not $relation;
        delete $relation->{ $opt{'-many'}->get_id };
    }
    else {
        my $id = $many->get_id;
        LINK_SEARCH: for my $relation ( @relationship ) {
            if ( exists $relation->{$id} ) {
                delete $relation->{$id};
                last LINK_SEARCH;
            }
        }
    }
}

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>.

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

$Id: TaxaMediator.pm 3293 2007-03-17 17:12:43Z rvosa $

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