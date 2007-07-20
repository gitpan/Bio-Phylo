# $Id: Tree.pm 4265 2007-07-20 14:14:44Z rvosa $
package Bio::Phylo::Adaptor::Bioperl::Tree;
use Bio::Phylo::Adaptor;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Adaptor);

eval { require Bio::Tree::TreeI };
if ( not $@ ) {
    push @ISA, 'Bio::Tree::TreeI';
}

=head1 NAME

Bio::Phylo::Adaptor::Bioperl::Tree - Adaptor class for bioperl compatibility

=head1 SYNOPSIS

 use Bio::Phylo::Adaptor;

 # some way to get a tree
 use Bio::Phylo::IO;
 my $string = '((A,B),C);';
 my $forest = Bio::Phylo::IO->parse(
    -format => 'newick',
    -string => $string
 );
 my $tree = $forest->first;

 $Bio::Phylo::COMPAT = 'Bioperl';

 my $bptree = Bio::Phylo::Adaptor->new( $tree );

 print "compatible!" if $bptree->isa('Bio::Tree::TreeI');

=head1 DESCRIPTION

This class wraps L<Bio::Phylo::Forest::Tree> objects to give them an interface
compatible with bioperl.

=head1 METHODS

=over

=item get_nodes()

Return list of Tree::NodeI objects.

 Title   : get_nodes
 Usage   : my @nodes = $tree->get_nodes()
 Function: Return list of Tree::NodeI objects
 Returns : array of Tree::NodeI objects
 Args    : (named values) hash with one value 
           order => 'b|breadth' first order or 'd|depth' first order

=cut

sub get_nodes {
    my $adaptor = shift;
    my $self = $$adaptor;
    return @{ $self->get_entities };
}

=item get_root_node()

Get the Top Node in the tree.

 Title   : get_root_node
 Usage   : my $node = $tree->get_root_node();
 Function: Get the Top Node in the tree, in this implementation
           Trees only have one top node.
 Returns : Bio::Tree::NodeI object
 Args    : none

=cut

sub get_root_node {
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->get_root;
}

=item number_nodes()

Returns the number of nodes.

 Title   : number_nodes
 Usage   : my $size = $tree->number_nodes
 Function: Returns the number of nodes
 Example :
 Returns : 
 Args    :


=cut

sub number_nodes {
    my $adaptor = shift;
    my $self = $$adaptor;
    return scalar @{ $self->get_entities };
}   

=item total_branch_length()

Returns the sum of the length of all branches.

 Title   : total_branch_length
 Usage   : my $size = $tree->total_branch_length
 Function: Returns the sum of the length of all branches
 Returns : integer
 Args    : none

=cut

sub total_branch_length {
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->calc_tree_length;
}

=item height()

Gets the height of tree.

 Title   : height
 Usage   : my $height = $tree->height
 Function: Gets the height of tree - this LOG_2($number_nodes)
           WARNING: this is only true for strict binary trees.  The TreeIO
           system is capable of building non-binary trees, for which this
           method will currently return an incorrect value!!
 Returns : integer
 Args    : none

=cut

sub height {
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->calc_tree_height;
}

=item id()

An id value for the tree.

 Title   : id
 Usage   : my $id = $tree->id();
 Function: An id value for the tree
 Returns : scalar
 Args    : 


=cut

sub id {
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->get_id;
}

=item score()

Sets the associated score with this tree.

 Title   : score
 Usage   : $obj->score($newval)
 Function: Sets the associated score with this tree
           This is a generic slot which is probably best used 
           for log likelihood or other overall tree score
 Returns : value of score
 Args    : newvalue (optional)


=cut

sub score {
    my $adaptor = shift;
    my $self = $$adaptor;
    if ( @_ ) {
        $self->set_score( shift );
    }
    return $self->get_score;
}

=item get_leaf_nodes()

Returns the leaves (tips) of the tree.

 Title   : get_leaf_nodes
 Usage   : my @leaves = $tree->get_leaf_nodes()
 Function: Returns the leaves (tips) of the tree
 Returns : Array of Bio::Tree::NodeI objects
 Args    : none


=cut

sub get_leaf_nodes {
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->get_terminals;
}

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Adaptor>

The base class for the adaptor architecture, instantiates the appropriate
wrapper depending on $Bio::Phylo::COMPAT

=item L<Bio::Tree::TreeI>

Bio::Phylo::Adaptor::Bioperl::Tree is an adaptor that makes Bio::Phylo
trees compatible with the L<Bio::Tree::TreeI> interface.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>.

=back

=head1 REVISION

 $Id: Tree.pm 4265 2007-07-20 14:14:44Z rvosa $

=cut

1;