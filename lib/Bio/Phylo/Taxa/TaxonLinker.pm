package Bio::Phylo::Taxa::TaxonLinker;
use Bio::Phylo::Mediators::TaxaMediator;
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Util::CONSTANT qw(_TAXON_);
use Scalar::Util qw(blessed);
use strict;

sub set_taxon {
    my ( $self, $taxon ) = @_;
    if ( defined $taxon ) {
        if ( UNIVERSAL::can( $taxon, '_type' ) && $taxon->_type == _TAXON_ ) {
            $self->info("setting taxon '$taxon'");
            Bio::Phylo::Mediators::TaxaMediator->set_link( 
                '-one'  => $taxon, 
                '-many' => $self,
            );
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                'error' => 'Not a taxon!'
            );
        }
    }
    else {
        $self->info("re-setting taxon link");
        Bio::Phylo::Mediators::TaxaMediator->remove_link( '-many' => $self );
    }
    return $self;
}

sub get_taxon {
    my $self = shift;
    $self->debug("getting taxon");
    return Bio::Phylo::Mediators::TaxaMediator->get_link( '-source' => $self );
}

sub _cleanup { 
    my $self = shift;
    $self->info("cleaning up '$self'"); 
}


1;
