package Bio::Phylo::Taxa::TaxaLinker;
use Bio::Phylo::Mediators::TaxaMediator;
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Util::CONSTANT '_TAXA_';
use strict;

sub set_taxa {
    my ( $self, $taxa ) = @_;
    if ( defined $taxa ) {
        if ( UNIVERSAL::can( $taxa, '_type' ) && $taxa->_type == _TAXA_ ) {
            $self->info("setting taxa '$taxa'");
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
        $self->info("re-setting taxa link");
        Bio::Phylo::Mediators::TaxaMediator->remove_link( '-many' => $self );
    }
    $self->check_taxa;
    return $self;
}

sub get_taxa {
    my $self = shift;
    $self->debug("getting taxa");
    return Bio::Phylo::Mediators::TaxaMediator->get_link( '-source' => $self );
}

sub check_taxa {
    Bio::Phylo::Util::Exceptions::NotImplemented->throw(
        'error' => 'Not implemented!'
    );
}

sub _cleanup { 
    my $self = shift;
    $self->info("cleaning up '$self'"); 
}

1;
