# $Id: Forest.pm,v 1.18 2006/04/12 22:38:22 rvosa Exp $
package Bio::Phylo::Forest;
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Util::CONSTANT qw(_NONE_ _FOREST_ _TAXA_);
use Scalar::Util qw(weaken);
use Bio::Phylo::Taxa;
use Bio::Phylo::Taxa::Taxon;

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo::Listable);

{

    # inside-out class arrays
    my @taxa;

    # $fields hashref necessary for object destruction
    my $fields = {
        '-taxa'    => \@taxa,
    };

=head1 NAME

Bio::Phylo::Forest - The forest object, a set of phylogenetic trees.

=head1 SYNOPSIS

 use Bio::Phylo::Forest;
 my $trees = Bio::Phylo::Forest->new;

=head1 DESCRIPTION

The Bio::Phylo::Forest object models a set of trees. The object subclasses the
L<Bio::Phylo::Listable> object, so look there for more methods available to
forest objects.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new

 Type    : Constructor
 Title   : new
 Usage   : my $trees = Bio::Phylo::Forest->new;
 Function: Instantiates a Bio::Phylo::Forest object.
 Returns : A Bio::Phylo::Forest object.
 Args    : None required, though see the superclass
           Bio::Phylo::Listable from which this
           object inherits.

=cut

    sub new {
        my ( $class, $self ) = shift;
        $self = Bio::Phylo::Forest->SUPER::new(@_);
        bless $self, __PACKAGE__;
        if ( @_ ) {
            my %opt;
            eval { %opt = @_; };
            if ( $@ ) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
            }
            else {
                while ( my ( $key, $value ) = each %opt ) {
                    if ( $fields->{$key} ) {
                        $fields->{$key}->[$$self] = $value;
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

=item set_taxa()

 Type    : Mutator
 Title   : set_taxa
 Usage   : $forest->set_taxa( $taxa );
 Function: Links the invocant forest
           object to a taxa object.
           Individual terminal node
           objects are linked to
           individual taxon objects
           by name, i.e. by what is
           returned by $node->get_name
 Returns : $forest
 Args    : A Bio::Phylo::Taxa object.
 Comments: This method checks whether
           any of the nodes in the trees
           in the invocant link to
           Bio::Phylo::Taxa::Taxon objects
           not contained by $taxa. If found,
           these are set to undef and the
           following message is displayed:

           "Reset X references from nodes
           to taxa outside taxa block"

=cut

    sub set_taxa {
        my ( $self, $taxa ) = @_;
        if ( defined $taxa ) {
            if ( blessed $taxa ) {
                if ( $taxa->can('_type') && $taxa->_type == _TAXA_ ) {
                    my %taxa = map { $_ => $_->get_name } @{ $taxa->get_entities };
                    my %name;
                    while ( my ( $k, $v ) = each %taxa ) {
                        next if not $k or not $v;
                        $name{$v} = $k;
                    }
                    my $replaced = 0;
                    foreach my $tree ( @{ $self->get_entities } ) {
                        foreach my $node ( @{ $tree->get_entities } ) {
                            if ( $node->get_taxon() ) {
                                my $taxon = $node->get_taxon();
                                if ( ! exists $taxa{$taxon} ) {
                                    $node->set_taxon();
                                    $replaced++;
                                }
                            }
                            elsif ( $node->is_terminal and $node->get_name and exists $name{$node->get_name} ) {
                                $node->set_taxon( $name{$node->get_name} );
                            }
                        }
                    }
                    if ( $replaced ) {
                        warn "Reset $replaced references from nodes to taxa outside taxa block";
                    }
                    $taxa[$$self] = $taxa;
                    weaken( $taxa[$$self] );
                    my %tmp = map { $_ => 1 } @{ $taxa->get_forests };
                    $taxa->set_forest( $self ) if ! exists $tmp{$self};
                }
                else {
                    Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                        error => "\"$taxa\" doesn't look like a taxa object"
                    );
                }
            }
            else {
                Bio::Phylo::Util::Exceptions::BadArgs->throw(
                    error => "\"$taxa\" is not a blessed object!"
                );
            }
        }
        else {
            $taxa[$$self] = undef;
        }
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_taxa()

 Type    : Accessor
 Title   : get_taxa
 Usage   : my $taxa = $forest->get_taxa;
 Function: Retrieves the taxa object
           linked to the invocant.
 Returns : Bio::Phylo::Taxa
 Args    : NONE

=cut

    sub get_taxa {
        my $self = shift;
        return $taxa[$$self];
    }

=back

=head2 METHODS

=over

=item to_cipres()

 Type    : Format converter
 Title   : to_cipres
 Usage   : my $cipresforest = $forest->to_cipres;
 Function: Turns the invocant forest object
           into a CIPRES CORBA compliant
           data structure
 Returns : ARRAYREF
 Args    : NONE

=cut

    sub to_cipres {
        my @cipresforest;
        foreach my $tree ( @{ $_[0]->get_entities } ) {
            push @cipresforest, $tree->to_cipres;
        }
        return \@cipresforest;
    }

=item make_taxa()

 Type    : Utility method
 Title   : make_taxa
 Usage   : my $taxa = $forest->make_taxa;
 Function: Creates a Bio::Phylo::Taxa
           object from the terminal nodes
           in invocant.
 Returns : Bio::Phylo::Taxa
 Args    : NONE
 Comments: N.B.!: the newly created taxa
           object will replace all earlier
           references to other taxa and
           taxon objects.

=cut

sub make_taxa {
    my $self = shift;
    my $taxa = Bio::Phylo::Taxa->new;
    $taxa->set_name('Untitled_taxa_block');
    $taxa->set_desc('Generated from ' . $self . ' on ' . localtime());
    my %tips;
    foreach my $tree ( @{ $self->get_entities } ) {
        foreach my $tip ( @{ $tree->get_terminals } ) {
            my $name = $tip->get_name;
            if ( ! exists $tips{$name} ) {
                my $taxon = Bio::Phylo::Taxa::Taxon->new;
                $taxon->set_name( $name );
                $tips{$name} = {
                    'tip'   => [ $tip ],
                    'taxon' => $taxon,
                };
            }
            else {
                push @{ $tips{$name}->{'tip'} }, $tip;
            }
        }
    }
    foreach my $name ( keys %tips ) {
        my $taxon = $tips{$name}->{'taxon'};
        foreach my $tip ( @{ $tips{$name}->{'tip'} } ) {
            $tip->set_taxon($taxon);
            $taxon->set_nodes($tip);
        }
        $taxa->insert($taxon);
    }
    $self->set_taxa($taxa);
    return $taxa;
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
        foreach( keys %{ $fields } ) {
            delete $fields->{$_}->[$$self];
        }
        $self->_del_from_super;
        $self->SUPER::DESTROY;
        return 1;
    }

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $trees->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _container { _NONE_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $trees->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _type { _FOREST_ }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Listable>

The forest object inherits from the L<Bio::Phylo::Listable>
object. The methods defined therein are applicable to forest objects.

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

$Id: Forest.pm,v 1.18 2006/04/12 22:38:22 rvosa Exp $

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
