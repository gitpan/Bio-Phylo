# $Id: Taxa.pm 1721 2006-07-20 03:43:06Z rvosa $
package Bio::Phylo::Taxa;
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Util::CONSTANT qw(_NONE_ _TAXA_ _FOREST_ _MATRIX_);
use Scalar::Util qw(weaken blessed);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo::Listable);
{

    # inside-out class arrays
    my @forests;
    my @matrices;

    # $fields hashref necessary for object destruction
    my $fields = {
        '-forests'  => \@forests,
        '-matrices' => \@matrices,
    };

=head1 NAME

Bio::Phylo::Taxa - An object-oriented module for managing taxa.

=head1 SYNOPSIS

 use Bio::Phylo::Taxa;
 use Bio::Phylo::Taxa::Taxon;
 
 # A mesquite-style default
 # taxa block for 10 taxa.
 my $taxa  = Bio::Phylo::Taxa->new;
 for my $i ( 1 .. 10 ) {
     my $taxon = Bio::Phylo::Taxa::Taxon->new(
         '-name' => 'taxon_' . $i,
     );
     $taxa->insert( $taxon );
 }

=head1 DESCRIPTION

The Bio::Phylo::Taxa object models a set of operational taxonomic units. The
object subclasses the Bio::Phylo::Listable object, and so the filtering
methods of that class are available.

A taxa object can link to multiple forest and matrix objects.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $taxa = Bio::Phylo::Taxa->new;
 Function: Instantiates a Bio::Phylo::Taxa object.
 Returns : A Bio::Phylo::Taxa object.
 Args    : none.

=cut

    sub new {
        my ( $class, $self ) = shift;
        $self = Bio::Phylo::Taxa->SUPER::new(@_);
        bless $self, __PACKAGE__;
        $forests[ $self->get_id ]  = {};
        $matrices[ $self->get_id ] = {};
        if (@_) {
            my %opt;
            eval { %opt = @_; };
            if ($@) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
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
        $self->_set_super;
        return $self;
    }

=back

=head2 MUTATORS

=over

=item set_forest()

 Type    : Mutator
 Title   : set_forest
 Usage   : $taxa->set_forest( $forest );
 Function: Associates forest with the 
           invocant taxa object (i.e. 
           creates reference).
 Returns : Modified object.
 Args    : A Bio::Phylo::Forest object 
 Comments: A taxa object can link to multiple 
           forest and matrix objects.

=cut

    sub set_forest {
        my ( $self, $forest ) = @_;
        if (   blessed $forest
            && $forest->can('_type')
            && $forest->_type == _FOREST_ )
        {
            $forests[ $self->get_id ]->{$forest} = $forest;
            weaken( $forests[ $self->get_id ]->{$forest} );
            $forest->set_taxa($self) if $forest->get_taxa != $self;
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => "\"$forest\" doesn't look like a forest object" );
        }
    }

=item set_matrix()

 Type    : Mutator
 Title   : set_matrix
 Usage   : $taxa->set_matrix($matrix);
 Function: Associates matrix with the 
           invocant taxa object (i.e. 
           creates reference).
 Returns : Modified object.
 Args    : A Bio::Phylo::Matrices::Matrix object
 Comments: A taxa object can link to multiple 
           forest and matrix objects. 

=cut

    sub set_matrix {
        my ( $self, $matrix ) = @_;
        if (   blessed $matrix
            && $matrix->can('_type')
            && $matrix->_type == _MATRIX_ )
        {
            $matrices[ $self->get_id ]->{$matrix} = $matrix;
            weaken( $matrices[ $self->get_id ]->{$matrix} );
            if ( $matrix->get_taxa ) {
                $matrix->set_taxa($self) if $matrix->get_taxa != $self;
            }
            else {
                $matrix->set_taxa($self);
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => "\"$matrix\" doesn't look like a matrix object" );
        }
    }

=item unset_forest()

 Type    : Mutator
 Title   : unset_forest
 Usage   : $taxa->unset_forest($forest);
 Function: Disassociates forest from the 
           invocant taxa object (i.e. 
           removes reference).
 Returns : Modified object.
 Args    : A Bio::Phylo::Forest object

=cut

    sub unset_forest {
        my ( $self, $forest ) = @_;

        # no need for type checking really. If it's there, it gets killed,
        # otherwise skips silently
        delete $forests[ $self->get_id ]->{$forest};
        return $self;
    }

=item unset_matrix()

 Type    : Mutator
 Title   : unset_matrix
 Usage   : $taxa->unset_matrix($matrix);
 Function: Disassociates matrix from the 
           invocant taxa object (i.e. 
           removes reference).
 Returns : Modified object.
 Args    : A Bio::Phylo::Matrices::Matrix object

=cut

    sub unset_matrix {
        my ( $self, $matrix ) = @_;

        # no need for type checking really. If it's there, it gets killed,
        # otherwise skips silently
        delete $matrices[ $self->get_id ]->{$matrix};
        return $self;
    }


=back

=head2 ACCESSORS

=over

=item get_forests()

 Type    : Accessor
 Title   : get_forests
 Usage   : @forests = @{ $taxa->get_forests };
 Function: Retrieves forests associated 
           with the current taxa object.
 Returns : An ARRAY reference of 
           Bio::Phylo::Forest objects.
 Args    : None.
 
=cut

    sub get_forests {
        my $self = shift;
        my @tmp  = values %{ $forests[ $self->get_id ] };
        return \@tmp;
    }

=item get_matrices()

 Type    : Accessor
 Title   : get_matrices
 Usage   : @matrices = @{ $taxa->get_matrices };
 Function: Retrieves matrices associated 
           with the current taxa object.
 Returns : An ARRAY reference of 
           Bio::Phylo::Matrices::Matrix objects.
 Args    : None.

=cut

    sub get_matrices {
        my $self = shift;
        my @tmp  = values %{ $matrices[ $self->get_id ] };
        return \@tmp;
    }

=item get_ntax()

 Type    : Accessor
 Title   : get_ntax
 Usage   : my $ntax = $taxa->get_ntax;
 Function: Retrieves the number of taxa for the invocant.
 Returns : INT
 Args    : None.
 Comments:

=cut

    sub get_ntax {
        my $self = shift;
        return scalar @{ $self->get_entities };
    }

=back

=head2 METHODS

=over

=item merge_by_name()

 Type    : Method
 Title   : merge_by_name
 Usage   : $taxa->merge_by_name($other_taxa);
 Function: Merges two taxa objects such that 
           internally different taxon objects 
           with the same name become a single
           object with the combined references 
           to datum objects and node objects 
           contained by the two.           
 Returns : A merged Bio::Phylo::Taxa object.
 Args    : A Bio::Phylo::Taxa object.

=cut

    sub merge_by_name {
        my ( $self, $other_taxa ) = @_;
        if (   $other_taxa
            && $other_taxa->can('_type')
            && $other_taxa->_type == _TAXA_ )
        {
            my %self = map { $_->get_name => $_ } @{ $self->get_entities };
            my %other =
              map { $_->get_name => $_ } @{ $other_taxa->get_entities };
            my $new = Bio::Phylo::Taxa->new;
            foreach my $name ( keys %self ) {
                my $taxon = Bio::Phylo::Taxa::Taxon->new( '-name' => $name );
                foreach my $datum ( @{ $self{$name}->get_data } ) {
                    $datum->set_taxon($taxon);
                    $taxon->set_datum($datum);
                }
                foreach my $node ( @{ $self{$name}->get_nodes } ) {
                    $node->set_taxon($taxon);
                    $taxon->set_node($node);
                }
                if ( exists $other{$name} ) {
                    foreach my $datum ( @{ $other{$name}->get_data } ) {
                        $datum->set_taxon($taxon);
                        $taxon->set_datum($datum);
                    }
                    foreach my $node ( @{ $other{$name}->get_nodes } ) {
                        $node->set_taxon($taxon);
                        $taxon->set_node($node);
                    }
                }
                $new->insert($taxon);
            }
            return $new;
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => "\"$other_taxa\" is not a Taxa object" );
        }
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
        $self->_del_from_super;
        $self->SUPER::DESTROY;
        return 1;
    }

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $taxa->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _container { _NONE_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $taxa->_type;
 Function:
 Returns : SCALAR
 Args    :

=end comment

=cut

    sub _type { _TAXA_ }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Listable>

The L<Bio::Phylo::Taxa> object inherits from the L<Bio::Phylo::Listable>
object. Look there for more methods applicable to the taxa object.

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

$Id: Taxa.pm 1721 2006-07-20 03:43:06Z rvosa $

=head1 AUTHOR

Rutger Vos,

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

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

}
1;
