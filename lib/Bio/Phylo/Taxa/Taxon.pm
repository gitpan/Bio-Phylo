# $Id: Taxon.pm 1343 2006-06-13 19:41:41Z rvosa $
# Subversion: $Rev: 177 $
package Bio::Phylo::Taxa::Taxon;
use strict;
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Taxa::CDAT;
use Scalar::Util qw(weaken blessed);
use Bio::Phylo::Util::CONSTANT qw(_DATUM_ _NODE_ _TAXON_ _TAXA_);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo Bio::Phylo::Taxa::CDAT);
{

    # inside out class arrays
    my @nodes;
    my @data;

    # $fields hashref necessary for object construction and destruction
    my $fields = {
        '-nodes' => \@nodes,
        '-data'  => \@data,
    };

=head1 NAME

Bio::Phylo::Taxa::Taxon - The operational taxonomic unit.

=head1 SYNOPSIS

 use Bio::Phylo::IO qw(parse);
 use Bio::Phylo::Taxa;
 use Bio::Phylo::Taxa::Taxon;

 # array of names
 my @apes = qw(
     Homo_sapiens
     Pan_paniscus
     Pan_troglodytes
     Gorilla_gorilla
 );

 # newick string
 my $str = '(((Pan_paniscus,Pan_troglodytes),';
 $str   .= 'Homo_sapiens),Gorilla_gorilla);';

 # create tree object
 my $tree = parse(
    -format => 'newick',
    -string => $str
 )->first;

 # instantiate taxa object
 my $taxa = Bio::Phylo::Taxa->new;

 # instantiate taxon objects, insert in taxa object
 foreach( @apes ) {
    my $taxon = Bio::Phylo::Taxa::Taxon->new(
        -name => $_,
    );
    $taxa->insert($taxon);
 }

 # crossreference tree and taxa
 $tree->crossreference($taxa);

 # iterate over nodes
 while ( my $node = $tree->next ) {

    # check references
    if ( $node->get_taxon ) {

        # prints crossreferenced tips
        print "match: ", $node->get_name, "\n";
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
 Function: Instantiates a Bio::Phylo::Taxa::Taxon
           object.
 Returns : A Bio::Phylo::Taxa::Taxon object.
 Args    : none.

=cut

    sub new {
        my $class = shift;
        my $self  = Bio::Phylo::Taxa::Taxon->SUPER::new(@_);
        bless $self, __PACKAGE__;
        if (@_) {
            my %opt;
            eval { %opt = @_; };
            if ($@) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
            }
            else {
                while ( my ( $key, $value ) = each %opt ) {
                    if ( $fields->{$key} ) {
                        $fields->{$key}->[$$self] = $value;
                        if ( ref $value && $value->can('_type') ) {
                            my $type = $value->_type;
                            if ( $type == _DATUM_ || $type == _NODE_ ) {
                                weaken( $fields->{$key}->[$$self] );
                            }
                        }
                        delete $opt{$key};
                    }
                }
                @_ = %opt;
            }
        }
        $nodes[$$self] = {};
        $data[$$self]  = {};
        return $self;
    }

=back

=head2 MUTATORS

=over

=item set_data()

 Type    : Mutator
 Title   : set_data
 Usage   : $taxon->set_data( $datum );
 Function: Associates data with
           the current taxon.
 Returns : Modified object.
 Args    : Must be an object of type
           Bio::Phylo::Matrices::Datum

=cut

    sub set_data {
        my ( $self, $datum ) = @_;
        if (   blessed $datum
            && $datum->can('_type')
            && $datum->_type == _DATUM_ )
        {
            if ( $datum->_get_container && $datum->_get_container->get_taxa ) {
                if ( $datum->_get_container->get_taxa != $self->_get_container )
                {
                    Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                        error => "Attempt to link to taxon from wrong block" );
                }
                $datum->_get_container->set_taxa( $self->_get_container );
            }
            $data[$$self]->{$datum} = $datum;
            weaken( $data[$$self]->{$datum} );
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => "\"$datum\" doesn't look like a datum object" );
        }
        return $self;
    }

=item set_nodes()

 Type    : Mutator
 Title   : set_nodes
 Usage   : $taxon->set_nodes($node);
 Function: Associates tree nodes
           with the current taxon.
 Returns : Modified object.
 Args    : A Bio::Phylo::Forest::Node object

=cut

    sub set_nodes {
        my ( $self, $node ) = @_;
        if ( blessed $node && $node->can('_type') && $node->_type == _NODE_ ) {
            if (   $node->_get_container
                && $node->_get_container->_get_container
                && $node->_get_container->_get_container->get_taxa )
            {
                if ( $node->_get_container->_get_container->get_taxa !=
                    $self->_get_container )
                {
                    Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                        error => "Attempt to link to taxon from wrong block" );
                }
                $node->_get_container->_get_container->set_taxa(
                    $self->_get_container );
            }
            $nodes[$$self]->{$node} = $node;
            weaken( $nodes[$$self]->{$node} );
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => "\"$node\" doesn't look like a node object" );
        }
        return $self;
    }

=item unset_datum()

 Type    : Mutator
 Title   : unset_datum
 Usage   : $taxon->unset_datum($node);
 Function: Disassociates datum from
           the invocant taxon (i.e.
           removes reference).
 Returns : Modified object.
 Args    : A Bio::Phylo::Matrix::Datum object

=cut

    sub unset_datum {
        my ( $self, $datum ) = @_;

        # no need for type checking really. If it's there, it gets killed,
        # otherwise skips silently
        delete $data[$$self]->{$datum};
        return $self;
    }

=item unset_node()

 Type    : Mutator
 Title   : unset_node
 Usage   : $taxon->unset_node($node);
 Function: Disassociates tree node from
           the invocant taxon (i.e.
           removes reference).
 Returns : Modified object.
 Args    : A Bio::Phylo::Forest::Node object

=cut

    sub unset_node {
        my ( $self, $node ) = @_;

        # no need for type checking really. If it's there, it gets killed,
        # otherwise skips silently
        delete $nodes[$$self]->{$node};
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_data()

 Type    : Accessor
 Title   : get_data
 Usage   : @data = @{ $taxon->get_data };
 Function: Retrieves data associated
           with the current taxon.
 Returns : An ARRAY reference of
           Bio::Phylo::Matrices::Datum
           objects.
 Args    : None.

=cut

    sub get_data {
        my $self = shift;
        my @tmp  = values %{ $data[$$self] };
        return \@tmp;
    }

=item get_nodes()

 Type    : Accessor
 Title   : get_nodes
 Usage   : @nodes = @{ $taxon->get_nodes };
 Function: Retrieves tree nodes associated
           with the current taxon.
 Returns : An ARRAY reference of
           Bio::Phylo::Trees::Node objects
 Args    : None.

=cut

    sub get_nodes {
        my $self = shift;
        my @tmp  = values %{ $nodes[$$self] };
        return \@tmp;
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
        foreach ( keys %{$fields} ) {
            delete $fields->{$_}->[$$self];
        }
        $self->SUPER::DESTROY;
        return 1;
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

The taxon objects inherits from the L<Bio::Phylo> object. The methods defined
there are also applicable to the taxon object.

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

$Id: Taxon.pm 1343 2006-06-13 19:41:41Z rvosa $

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

}
1;
