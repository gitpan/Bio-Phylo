# $Id: Forest.pm 3386 2007-03-24 16:22:25Z rvosa $
package Bio::Phylo::Forest;
use strict;
use warnings FATAL => 'all';
use Bio::Phylo;
use Bio::Phylo::Listable;
use Bio::Phylo::Taxa::TaxaLinker;
use Bio::Phylo::Taxa::Taxon;
use Bio::Phylo::Util::CONSTANT qw(_NONE_ _FOREST_);
use vars qw($VERSION @ISA);

# set version based on svn rev
my $version = $Bio::Phylo::VERSION;
my $rev = '$Id: Forest.pm 3386 2007-03-24 16:22:25Z rvosa $';
$rev =~ s/^[^\d]+(\d+)\b.*$/$1/;
$version =~ s/_.+$/_$rev/;
$VERSION = $version;

# classic @ISA manipulation, not using 'base'
@ISA = qw(Bio::Phylo::Listable Bio::Phylo::Taxa::TaxaLinker);

{

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

=head1 METHODS

=over

=item check_taxa

 Type    : Method
 Title   : check_taxa
 Usage   : $trees->check_taxa;
 Function: Validates the taxon links of the
           nodes of the trees in $trees
 Returns : A validated Bio::Phylo::Forest object.
 Args    : None

=cut

    sub check_taxa {
        my $self = shift;
        # is linked
        if ( my $taxa = $self->get_taxa ) {
            my %taxa = map { $_->get_name => $_ } @{ $taxa->get_entities };
            for my $tree ( @{ $self->get_entities } ) {
                NODE_CHECK: for my $node ( @{ $tree->get_entities } ) {
                    if ( my $taxon = $node->get_taxon ) {
                        next NODE_CHECK if exists $taxa{$taxon->get_name};
                        $node->set_taxon() if $node->is_internal;
                    }
                    if ( $node->is_terminal ) {
                        my $name = $node->get_name;
                        if ( exists $taxa{$name} ) {
                            $node->set_taxon( $taxa{$name} );
                        }
                        else {
                            my $taxon = Bio::Phylo::Taxa::Taxon->new(
                                -name => $name
                            );
                            $taxa{$name} = $taxon;
                            $taxa->insert( $taxon );
                            $node->set_taxon( $taxon );
                        }
                    }
                }
            }
        }
        # not linked
        else {
            for my $tree ( @{ $self->get_entities } ) {
                for my $node ( @{ $tree->get_entities } ) {
                    $node->set_taxon();
                }
            }
        }
        return $self;
    }

=begin comment

 Type    : Internal method
 Title   : _cleanup
 Usage   : $trees->_cleanup;
 Function: Called during object destruction, for cleanup of instance data
 Returns : 
 Args    :

=end comment

=cut

    sub _cleanup {
        my $self = shift;
        $self->info("cleaning up '$self'");
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

$Id: Forest.pm 3386 2007-03-24 16:22:25Z rvosa $

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
