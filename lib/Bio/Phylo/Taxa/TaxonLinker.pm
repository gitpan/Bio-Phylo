package Bio::Phylo::Taxa::TaxonLinker;
use Bio::Phylo::Mediators::TaxaMediator;
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Util::CONSTANT qw(_TAXON_);
use Scalar::Util qw(blessed);
use strict;

=head1 NAME

Bio::Phylo::Taxa::TaxonLinker - Superclass for objects that link to taxa objects.

=head1 SYNOPSIS

 use Bio::Phylo::Forest::Node;
 use Bio::Phylo::Taxa::Taxon;

 my $node  = Bio::Phylo::Forest::Node->new;
 my $taxon = Bio::Phylo::Taxa::Taxon->new;

 if ( $node->isa('Bio::Phylo::Taxa::TaxonLinker') ) {
    $node->set_taxa( $taxon );
 }

=head1 DESCRIPTION

This module is a superclass for objects that link to L<Bio::Phylo::Taxa::Taxon>
objects.

=head1 METHODS

=head2 MUTATORS

=over

=item set_taxon()

 Type    : Mutator
 Title   : set_taxon
 Usage   : $obj->set_taxon( $taxon );
 Function: Links the invocant object
           to a taxon object.
 Returns : Modified $obj
 Args    : A Bio::Phylo::Taxa::Taxon object.

=cut

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

=item unset_taxon()

 Type    : Mutator
 Title   : unset_taxon
 Usage   : $obj->unset_taxon();
 Function: Unlinks the invocant object
           from any taxon object.
 Returns : Modified $obj
 Args    : NONE

=cut

sub unset_taxon {
	my $self = shift;
	$self->debug( "unsetting taxon" );
	$self->set_taxon();
	return $self;
}

=back

=head2 ACCESSORS

=over

=item get_taxon()

 Type    : Accessor
 Title   : get_taxon
 Usage   : my $taxon = $obj->get_taxon;
 Function: Retrieves the Bio::Phylo::Taxa::Taxon
           object linked to the invocant.
 Returns : Bio::Phylo::Taxa::Taxon
 Args    : NONE
 Comments:

=cut

sub get_taxon {
    my $self = shift;
    $self->debug("getting taxon");
    return Bio::Phylo::Mediators::TaxaMediator->get_link( '-source' => $self );
}

sub _cleanup { 
    my $self = shift;
    $self->info("cleaning up '$self'"); 
}

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Matrices::Datum>

The datum object subclasses L<Bio::Phylo::Taxa::TaxonLinker>.

=item L<Bio::Phylo::Forest::Node>

The node object subclasses L<Bio::Phylo::Taxa::TaxonLinker>.

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

$Id: TaxonLinker.pm 4175 2007-07-11 02:13:51Z rvosa $

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
