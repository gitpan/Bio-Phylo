# $Id: Taxa.pm 4193 2007-07-11 20:26:06Z rvosa $
package Bio::Phylo::Taxa;
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Util::CONSTANT qw(_NONE_ _TAXA_ _FOREST_ _MATRIX_);
use Scalar::Util qw(weaken blessed);
use Bio::Phylo::Mediators::TaxaMediator;

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo::Listable);
{

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
        # could be child class
        my $class = shift;
        
        # notify user
        $class->info("constructor called for '$class'");
        
        # recurse up inheritance tree, get ID
        my $self = $class->SUPER::new( @_ );
        
        # local fields would be set here
        
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
        $self->debug( "setting forest $forest" );
        my $type;
        eval { $type = $forest->_type };
        if ( not $@ and $type == _FOREST_ ) {
        	$forest->set_taxa( $self );
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                'error' => 'Not a forest object!'
            );        	
        }      
        return $self;
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
        $self->debug( "setting matrix $matrix" );
        my $type;
        eval { $type = $matrix->_type };
        if ( not $@ and $type == _MATRIX_ ) {
        	$matrix->set_taxa( $self );
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                'error' => 'Not a matrix object!'
            );        	
        }      
        return $self;
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
        $self->debug( "unsetting forest $forest" );
        my $type;
        eval { $type = $forest->_type };
        if ( not $@ and $type == _FOREST_ ) {
        	$forest->unset_taxa();
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                'error' => 'Not a forest object!'
            );        	
        }      
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
        $self->debug( "unsetting matrix $matrix" );
        my $type;
        eval { $type = $matrix->_type };
        if ( not $@ and $type == _MATRIX_ ) {
        	$matrix->unset_taxa();
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                'error' => 'Not a matrix object!'
            );        	
        }      
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
        return Bio::Phylo::Mediators::TaxaMediator->get_link( 
            '-source' => $self, 
            '-type'   => _FOREST_,
        );
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
        return Bio::Phylo::Mediators::TaxaMediator->get_link( 
            '-source' => $self, 
            '-type'   => _MATRIX_,
        );
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

=item to_nexus()

 Type    : Format convertor
 Title   : to_nexus
 Usage   : my $block = $taxa->to_nexus;
 Function: Converts $taxa into a nexus taxa block.
 Returns : Nexus taxa block (SCALAR).
 Args    : -links => 1 (optional, adds 'TITLE' token)
 Comments:

=cut    

	sub to_nexus {
		my $self = shift;
		my %args = @_;
		my $nexus = "BEGIN TAXA;\n";
		$nexus .=   "[! Taxa block written by " . ref($self) . " " . $self->VERSION . " on " . localtime() . " ]\n";
		if ( $args{'-links'} ) {
			$nexus .= "\tTITLE " . $self->get_internal_name . ";\n";
		} 
		$nexus .= "\tDIMENSIONS NTAX=" . $self->get_ntax . ";\n";
		$nexus .= "\tTAXLABELS\n";
		$nexus .= "\t\t" . $_->get_internal_name . "\n" for @{ $self->get_entities };
		$nexus .= "\t;\nEND;\n";
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
        
        # notify user
        $self->info("destructor called for '$self'");
        
        # recurse up inheritance tree for cleanup
        $self->SUPER::DESTROY;
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

$Id: Taxa.pm 4193 2007-07-11 20:26:06Z rvosa $

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
