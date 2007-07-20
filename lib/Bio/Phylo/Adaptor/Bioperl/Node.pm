# $Id: Node.pm 4265 2007-07-20 14:14:44Z rvosa $
package Bio::Phylo::Adaptor::Bioperl::Node;
use Bio::Phylo::Adaptor;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Adaptor);

eval { require Bio::Tree::NodeI };
if ( not $@ ) {
    push @ISA, 'Bio::Tree::NodeI';
}

=head1 NAME

Bio::Phylo::Adaptor::Bioperl::Node - Adaptor class for bioperl compatibility

=head1 SYNOPSIS

 use Bio::Phylo::Forest::Node;
 use Bio::Phylo::Adaptor;

 my $node = Bio::Phylo::Forest::Node->new;

 $Bio::Phylo::COMPAT = 'Bioperl';

 my $bpnode = Bio::Phylo::Adaptor->new($node);

 print "compatible!" if $bpnode->isa('Bio::Tree::NodeI');

=head1 DESCRIPTION

This class wraps L<Bio::Phylo::Forest::Node> objects to give them an interface
compatible with bioperl.

=head1 METHODS

=over

=item add_Descendent()

Adds a descendent to a node.

 Title   : add_Descendent
 Usage   : $node->add_Descendant($node);
 Function: Adds a descendent to a node
 Returns : number of current descendents for this node
 Args    : Bio::Node::NodeI

=cut

sub add_Descendent { 
    my $adaptor = shift;
    my $self = $$adaptor;
    my $child = shift;
    $self->set_child( $child ); 
    return scalar @{ $self->get_children };
}

=item each_Descendent()

All the descendents for this Node.

 Title   : each_Descendent
 Usage   : my @nodes = $node->each_Descendent;
 Function: all the descendents for this Node (but not their descendents 
					      i.e. not a recursive fetchall)
 Returns : Array of Bio::Tree::NodeI objects
 Args    : none

=cut

sub each_Descendent { 
    my $adaptor = shift;
    my $self = $$adaptor;
    my $children = $self->get_children;
    return defined @$children ? @$children : ();
}

=item get_all_Descendents()

Recursively fetch all the nodes and their descendents.

 Title   : get_all_Descendents($sortby)
 Usage   : my @nodes = $node->get_all_Descendents;
 Function: Recursively fetch all the nodes and their descendents
           *NOTE* This is different from each_Descendent
 Returns : Array or Bio::Tree::NodeI objects
 Args    : $sortby [optional] "height", "creation" or coderef to be used
           to sort the order of children nodes.

=item get_Descendents()

Alias to get_all_Descendents for backward compatibility.

=cut

*get_Descendents = \&get_all_Descendents;

sub get_all_Descendents { 
    my $adaptor = shift;
    my $self = $$adaptor;
    return @{ $self->get_descendants };
}

=item is_Leaf()

Get Leaf status.

 Title   : is_Leaf
 Usage   : if( $node->is_Leaf ) 
 Function: Get Leaf status
 Returns : boolean
 Args    : none

=cut

sub is_Leaf { 
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->is_terminal;
}

=item descendent_count()

Counts the number of descendents a node has.

 Title   : descendent_count
 Usage   : my $count = $node->descendent_count;
 Function: Counts the number of descendents a node has 
           (and all of their subnodes)
 Returns : integer
 Args    : none

=cut

sub descendent_count { 
    my $adaptor = shift;
    my $self = $$adaptor;
    return scalar @{ $self->get_descendants };
}

=item to_string()

For debugging, provide a node as a string.

 Title   : to_string
 Usage   : my $str = $node->to_string()
 Function: For debugging, provide a node as a string
 Returns : string
 Args    : none

=cut

sub to_string { 
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->to_xml;
}

=item height()

Returns the height of the tree starting at this.

 Title   : height
 Usage   : my $len = $node->height
 Function: Returns the height of the tree starting at this
           node.  Height is the maximum branchlength.
 Returns : The longest length (weighting branches with branch_length) to a leaf
 Args    : none

=cut

sub height { 
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->calc_max_path_to_tips;
}

=item branch_length()

Get/Set the branch length.

 Title   : branch_length
 Usage   : $obj->branch_length()
 Function: Get/Set the branch length
 Returns : value of branch_length
 Args    : newvalue (optional)

=cut

sub branch_length {
    my $adaptor = shift;
    my $self = $$adaptor;
    my $bl = shift;
    if ( defined $bl ) {
        $self->set_branch_length( $bl );
    }
    $self->get_branch_length;
}

=item id()

The human readable identifier for the node.

 Title   : id
 Usage   : $obj->id($newval)
 Function: The human readable identifier for the node 
 Returns : value of human readable id
 Args    : newvalue (optional)


=cut

sub id { 
    my $adaptor = shift;
    my $self = $$adaptor;
    my $name = shift;
    if ( defined $name ) {
        $self->set_name( $name );
    }
    $self->get_name;
}

=item internal_id()

Returns the internal unique id for this Node.

 Title   : internal_id
 Usage   : my $internalid = $node->internal_id
 Function: Returns the internal unique id for this Node
 Returns : unique id
 Args    : none

=cut

sub internal_id { 
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->get_id;
}

=item description()

Get/Set the description string.

 Title   : description
 Usage   : $obj->description($newval)
 Function: Get/Set the description string
 Returns : value of description
 Args    : newvalue (optional)

=cut

sub description { 
    my $adaptor = shift;
    my $self = $$adaptor;
    my $desc = shift;
    if ( defined $desc ) {
        $self->set_desc( $desc );
    }
    return $self->get_desc;
}

=item bootstrap()

Get/Set the bootstrap value.

 Title   : bootstrap
 Usage   : $obj->bootstrap($newval)
 Function: Get/Set the bootstrap value
 Returns : value of bootstrap
 Args    : newvalue (optional)


=cut

sub bootstrap {
    my $adaptor = shift;
    my $self = $$adaptor;
    my $bootstrap = shift;
    if ( defined $bootstrap ) {
        $self->set_generic( 'bootstrap' => $bootstrap );
    }
    return $self->get_generic( 'bootstrap' );
}

=item ancestor()

Get/Set the ancestor node pointer for a Node.

 Title   : ancestor
 Usage   : my $node = $node->ancestor;
 Function: Get/Set the ancestor node pointer for a Node
 Returns : Null if this is top level node
 Args    : none

=cut

sub ancestor { 
    my $adaptor = shift;
    my $self = $$adaptor;
    my $parent = shift;
    if ( defined $parent ) {
        $self->set_parent( $parent );
    }
    return $self->get_parent;
}

=item invalidate_height()

Invalidate our cached value of the node height in the tree.

 Title   : invalidate_height
 Usage   : private helper method
 Function: Invalidate our cached value of the node height in the tree
 Returns : nothing
 Args    : none

=cut

sub invalidate_height {}

=item add_tag_value()

Adds a tag value to a node.

 Title   : add_tag_value
 Usage   : $node->add_tag_value($tag,$value)
 Function: Adds a tag value to a node 
 Returns : number of values stored for this tag
 Args    : $tag   - tag name
           $value - value to store for the tag

=cut

sub add_tag_value {
    my $adaptor = shift;
    my $self = $$adaptor;
    my ( $k, $v ) = @_;
    $self->set_generic( $k => $v );
    return scalar @{ keys %{ $self->get_generic } };
}

=item remove_tag()

Remove the tag and all values for this tag.

 Title   : remove_tag
 Usage   : $node->remove_tag($tag)
 Function: Remove the tag and all values for this tag
 Returns : boolean representing success (0 if tag does not exist)
 Args    : $tag - tagname to remove


=cut

sub remove_tag { 
    my $adaptor = shift;
    my $self = $$adaptor;
    my $key = shift;
    $self->set_generic( $key => undef );
    return;
}

=item remove_all_tags()

Removes all tags.

 Title   : remove_all_tags
 Usage   : $node->remove_all_tags()
 Function: Removes all tags 
 Returns : None
 Args    : None

=cut

sub remove_all_tags { 
    my $adaptor = shift;
    my $self = $$adaptor;
    $self->set_generic( {} );
}

=item get_all_tags()

Gets all the tag names for this Node.

 Title   : get_all_tags
 Usage   : my @tags = $node->get_all_tags()
 Function: Gets all the tag names for this Node
 Returns : Array of tagnames
 Args    : None

=cut

sub get_all_tags { 
    my $adaptor = shift;
    my $self = $$adaptor;
    return keys %{ $self->get_generic };
}

=item get_tag_values()

Gets the values for given tag.

 Title   : get_tag_values
 Usage   : my @values = $node->get_tag_value($tag)
 Function: Gets the values for given tag ($tag)
 Returns : Array of values or empty list if tag does not exist
 Args    : $tag - tag name

=cut

sub get_tag_values { 
    my $adaptor = shift;
    my $self = $$adaptor;
    my $key = shift;
    return $self->get_generic( $key );
}

=item has_tag()

Boolean test if tag exists in the Node.

 Title   : has_tag
 Usage   : $node->has_tag($tag)
 Function: Boolean test if tag exists in the Node
 Returns : Boolean
 Args    : $tag - tagname


=cut

sub has_tag { 
    my $adaptor = shift;
    my $self = $$adaptor;
    my $key = shift;
    my $hash = $self->get_generic;
    return exists $hash->{$key};
}

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Adaptor>

The base class for the adaptor architecture, instantiates the appropriate
wrapper depending on $Bio::Phylo::COMPAT

=item L<Bio::Tree::NodeI>

Bio::Phylo::Adaptor::Bioperl::Node is an adaptor that makes Bio::Phylo
nodes compatible with the L<Bio::Tree::NodeI> interface.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual|Bio::Phylo::Manual>.

=back

=head1 REVISION

 $Id: Node.pm 4265 2007-07-20 14:14:44Z rvosa $

=cut

1;