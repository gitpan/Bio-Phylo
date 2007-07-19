# $Id: TaxaLinker.pm 4234 2007-07-17 13:41:02Z rvosa $
package Bio::Phylo::Taxa::TaxaLinker;
use Bio::Phylo::Mediators::TaxaMediator;
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Util::CONSTANT '_TAXA_';
use Bio::Phylo::Util::Logger;
use strict;

my $logger = Bio::Phylo::Util::Logger->new;

=head1 NAME

Bio::Phylo::Taxa::TaxaLinker - Superclass for objects that link to taxa objects.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Matrix;
 use Bio::Phylo::Taxa;

 my $matrix = Bio::Phylo::Matrices::Matrix->new;
 my $taxa = Bio::Phylo::Taxa->new;

 if ( $matrix->isa('Bio::Phylo::Taxa::TaxaLinker') ) {
    $matrix->set_taxa( $taxa );
 }

=head1 DESCRIPTION

This module is a superclass for objects that link to L<Bio::Phylo::Taxa> objects.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

TaxaLinker constructor.

 Type    : Constructor
 Title   : new
 Usage   : # no direct usage
 Function: 
 Returns :
 Args    :

=cut

#    sub new {
#        # could be child class
#        my $class = shift;       
#        
#        # notify user
#        $class->info("constructor called for '$class'");           
#        
#        # go up inheritance tree, eventually get an ID
#        my $self = $class->SUPER::new( @_ );
#
#		# register with mediator
#		Bio::Phylo::Mediators::TaxaMediator->register($self);
#		
#		# done
#		return $self;        
#      
#    }

=back



=head2 MUTATORS

=over

=item set_taxa()

Associates invocant with Bio::Phylo::Taxa argument.

 Type    : Mutator
 Title   : set_taxa
 Usage   : $obj->set_taxa( $taxa );
 Function: Links the invocant object
           to a taxa object.
 Returns : Modified $obj
 Args    : A Bio::Phylo::Taxa object.

=cut

sub set_taxa {
    my ( $self, $taxa ) = @_;
    if ( defined $taxa ) {
        if ( UNIVERSAL::can( $taxa, '_type' ) && $taxa->_type == _TAXA_ ) {
            $logger->info("setting taxa '$taxa'");
            Bio::Phylo::Mediators::TaxaMediator->set_link( 
                '-one'  => $taxa, 
                '-many' => $self,
            );
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                'error' => 'Not a taxa object!'
            );
        }
    }
    else {
        $logger->info("re-setting taxa link");
        Bio::Phylo::Mediators::TaxaMediator->remove_link( '-many' => $self );
    }
    $self->check_taxa;
    return $self;
}

=item unset_taxa()

Removes association between invocant and Bio::Phylo::Taxa object.

 Type    : Mutator
 Title   : unset_taxa
 Usage   : $obj->unset_taxa();
 Function: Removes the link between invocant object and taxa
 Returns : Modified $obj
 Args    : NONE

=cut

sub unset_taxa {
	my $self = shift;
	$logger->info( "unsetting taxa" );
	$self->set_taxa();
	return $self;
}

=back

=head2 ACCESSORS

=over

=item get_taxa()

Retrieves association between invocant and Bio::Phylo::Taxa object.

 Type    : Accessor
 Title   : get_taxa
 Usage   : my $taxa = $obj->get_taxa;
 Function: Retrieves the Bio::Phylo::Taxa
           object linked to the invocant.
 Returns : Bio::Phylo::Taxa
 Args    : NONE
 Comments: This method returns the Bio::Phylo::Taxa
           object to which the invocant is linked.
           The returned object can therefore contain
           *more* taxa than are actually in the matrix.

=cut

sub get_taxa {
    my $self = shift;
    $logger->debug("getting taxa");
    return Bio::Phylo::Mediators::TaxaMediator->get_link( '-source' => $self );
}

=item check_taxa()

Performs sanity check on taxon relationships.

 Type    : Interface method
 Title   : check_taxa
 Usage   : $obj->check_taxa
 Function: Performs sanity check on taxon relationships
 Returns : $obj
 Args    : NONE

=cut

sub check_taxa {
    Bio::Phylo::Util::Exceptions::NotImplemented->throw(
        'error' => 'Not implemented!'
    );
}

sub _cleanup { 
    my $self = shift;
    $logger->debug("cleaning up '$self'"); 
}

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Matrices::Matrix>

The matrix object subclasses L<Bio::Phylo::Taxa::TaxaLinker>.

=item L<Bio::Phylo::Forest>

The forest object subclasses L<Bio::Phylo::Taxa::TaxaLinker>.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>.

=back

=head1 REVISION

 $Id: TaxaLinker.pm 4234 2007-07-17 13:41:02Z rvosa $

=cut

1;
