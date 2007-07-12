# $Id: Node.pm 4162 2007-07-11 01:35:39Z rvosa $
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

This class wraps Bio::Phylo node objects to give them an interface
compatible with bioperl.

=head1 METHODS

=over

=item add_Descendent()

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

 Title   : get_all_Descendents($sortby)
 Usage   : my @nodes = $node->get_all_Descendents;
 Function: Recursively fetch all the nodes and their descendents
           *NOTE* This is different from each_Descendent
 Returns : Array or Bio::Tree::NodeI objects
 Args    : $sortby [optional] "height", "creation" or coderef to be used
           to sort the order of children nodes.

=cut

sub get_all_Descendents { 
    my $adaptor = shift;
    my $self = $$adaptor;
    return @{ $self->get_descendants };
}

=item is_Leaf()

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

 Title   : invalidate_height
 Usage   : private helper method
 Function: Invalidate our cached value of the node height in the tree
 Returns : nothing
 Args    : none

=cut

sub invalidate_height {}

=item add_tag_value()

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

=item L<Bio::Tree::NodeI>

Bio::Phylo::Adaptor::Bioperl::Node is an adaptor that makes Bio::Phylo
nodes compatible with the L<Bio::Tree::NodeI> interface.

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

$Id: Node.pm 4162 2007-07-11 01:35:39Z rvosa $

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