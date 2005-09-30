# $Id: Taxon.pm,v 1.20 2005/09/29 20:31:18 rvosa Exp $
# Subversion: $Rev: 177 $
package Bio::Phylo::Taxa::Taxon;
use strict;
use warnings;
use base 'Bio::Phylo';
use Bio::Phylo::CONSTANT qw(_DATUM_ _NODE_ _TAXON_ _TAXA_);
use fields qw(NODES
              DATA);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Taxa::Taxon - The operational taxonomic unit.

=head1 SYNOPSIS

 use Bio::Phylo::IO;
 use Bio::Phylo::Taxa;
 use Bio::Phylo::Taxa::Taxon;
 
 my @taxa = qw(Homo_sapiens Pan_paniscus Pan_troglodytes Gorilla_gorilla);
 my $str = '(((Pan_paniscus,Pan_troglodytes),Homo_sapiens),Gorilla_gorilla);';
 
 # create tree object
 my $tree = Bio::Phylo::IO->parse(
    -format => 'newick',
    -string => $str
 )->first;

 # instantiate taxa object
 my $taxa = Bio::Phylo::Taxa->new;

 # instantiate taxon objects, insert in taxa object
 foreach( @taxa ) {
    my $taxon = Bio::Phylo::Taxa::Taxon->new( -name => $_ );
    $taxa->insert($taxon);
 }
 
 # crossreference tree and taxa
 $tree->crossreference($taxa);
 
 foreach my $node ( @{ $tree->get_entities } ) {
    if ( $node->get_taxon ) {
        print "match: ", $node->get_name, "\n";  #prints crossreferenced tips
    }
 }

=head1 DESCRIPTION

The taxon object models a single operational taxonomic unit. It is useful for
cross-referencing datum objects and tree nodes.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $taxon = Bio::Phylo::Taxa::Taxon->new;
 Function: Initializes a Bio::Phylo::Taxa::Taxon object.
 Returns : A Bio::Phylo::Taxa::Taxon object.
 Args    : none.

=cut

sub new {
    my $class = shift;
    my $self = fields::new($class);
    $self->SUPER::new(@_);
    if (@_) {
        my %opts;
        eval { %opts = @_; };
        if ($@) {
            Bio::Phylo::Exceptions::OddHash->throw(
                error => $@
            );
        }
        while ( my ( $key, $value ) = each %opts ) {
            my $localkey = uc substr $key, 1;
            eval { $self->{$localkey} = $value; };
            if ($@) {
                Bio::Phylo::Exceptions::BadArgs->throw(
                    error => "invalid field specified: $key ($localkey)"
                );
            }
        }
    }
    return $self;
}

=back

=head2 MUTATORS

=over

=item set_data()

 Type    : Mutator
 Title   : set_data
 Usage   : $taxon->set_data($datum);
 Function: Associates data with the current taxon.
 Returns : Modified object.
 Args    : Must be an object of type Bio::Phylo::Matrices::Datum

=cut

sub set_data {
    my $self  = $_[0];
    my $datum = $_[1];
    if ( $datum->can('_type') && $datum->_type == _DATUM_ ) {
        push @{ $self->{'DATA'} }, $datum;
    }
    else {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => 'sorry, data must be of type Bio::Phylo::Matrices::Datum'
        );
    }
    return $self;
}

=item set_nodes()

 Type    : Mutator
 Title   : set_nodes
 Usage   : $taxon->set_nodes($node);
 Function: Associates tree nodes with the current taxon.
 Returns : Modified object.
 Args    : A Bio::Phylo::Trees::Node object

=cut

sub set_nodes {
    my $self = $_[0];
    my $node = $_[1];
    my $ref  = ref $node;
    if ( $node->can('_type') && $node->_type == _NODE_ ) {
        push @{ $self->{'NODES'} }, $node;
    }
    else {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => "$ref doesn't look like a node"
        );
    }
    return $self;
}

=back

=head2 ACCESSORS

=over

=item get_data()

 Type    : Accessor
 Title   : get_data
 Usage   : @data = @{ $taxon->get_data };
 Function: Retrieves data associated with the current taxon.
 Returns : An ARRAY reference of Bio::Phylo::Matrices::Datum objects.
 Args    :

=cut

sub get_data {
    return $_[0]->{'DATA'};
}

=item get_nodes()

 Type    : Accessor
 Title   : get_nodes
 Usage   : @nodes = @{ $taxon->get_nodes };
 Function: Retrieves tree nodes associated with the current taxon.
 Returns : An ARRAY reference of Bio::Phylo::Trees::Node objects
 Args    :

=cut

sub get_nodes {
    return $_[0]->{'NODES'};
}

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $taxon->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

sub _container { _TAXA_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $taxon->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

sub _type { _TAXON_ }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

The taxon objects inherits from the L<Bio::Phylo|Bio::Phylo> object. The methods
defined there are also applicable to the taxon object.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual|Bio::Phylo::Manual>.

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

$Id: Taxon.pm,v 1.20 2005/09/29 20:31:18 rvosa Exp $

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
