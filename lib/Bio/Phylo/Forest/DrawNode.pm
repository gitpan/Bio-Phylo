package Bio::Phylo::Forest::DrawNode;
use strict;
use Bio::Phylo::Forest::Node;
use vars '@ISA';
@ISA=qw(Bio::Phylo::Forest::Node);
{
	# @fields array necessary for object destruction
	my @fields = \( 
	    my ( 
	        %x, 
	        %y, 
	        %radius, 
	        %node_colour,
	        %node_shape,
	        %node_image,	        
	        %branch_color,
	        %branch_shape,
            %branch_width,	
            %branch_style,
	        %font_face,
	        %font_size,
	        %font_style,
	        %url,
	        %text_horiz_offset,
	        %text_vert_offset,
	    ) 	
	);

=head1 NAME

Bio::Phylo::Forest::DrawNode - Tree node with extra methods for tree drawing

=head1 SYNOPSIS

 # see Bio::Phylo::Forest::Node

=head1 DESCRIPTION

This module defines a node object and its methods. The node is fairly
syntactically rich in terms of navigation, and additional getters are provided to
further ease navigation from node to node. Typical first daughter -> next sister
traversal and recursion is possible, but there are also shrinkwrapped methods
that return for example all terminal descendants of the focal node, or all
internals, etc.

Node objects are inserted into tree objects, although technically the tree
object is only a container holding all the nodes together. Unless there are
orphans all nodes can be reached without recourse to the tree object.

In addition, this subclass of the default node object L<Bio::Phylo::Forest::Node>
has getters and setters for drawing trees and nodes, e.g. X/Y coordinates, font
and text attributes, etc.

=head1 METHODS

=head2 MUTATORS

=over

=item set_x()

 Type    : Mutator
 Title   : set_x
 Usage   : $node->set_x($x);
 Function: Sets x
 Returns : $self
 Args    : x

=cut

    sub set_x {
        my ( $self, $x ) = @_;
        my $id = $self->get_id;
        $x{$id} = $x;
        return $self;
    }

=item set_y()

 Type    : Mutator
 Title   : set_y
 Usage   : $node->set_y($y);
 Function: Sets y
 Returns : $self
 Args    : y

=cut

    sub set_y {
        my ( $self, $y ) = @_;
        my $id = $self->get_id;
        $y{$id} = $y;
        return $self;
    }

=item set_radius()

 Type    : Mutator
 Title   : set_radius
 Usage   : $node->set_radius($radius);
 Function: Sets radius
 Returns : $self
 Args    : radius

=cut

    sub set_radius {
        my ( $self, $radius ) = @_;
        my $id = $self->get_id;
        $radius{$id} = $radius;
        return $self;
    }

=item set_node_colour()

 Type    : Mutator
 Title   : set_node_colour
 Usage   : $node->set_node_colour($node_colour);
 Function: Sets node_colour
 Returns : $self
 Args    : node_colour

=cut

    sub set_node_colour {
        my ( $self, $node_colour ) = @_;
        my $id = $self->get_id;
        $node_colour{$id} = $node_colour;
        return $self;
    }

=item set_node_shape()

 Type    : Mutator
 Title   : set_node_shape
 Usage   : $node->set_node_shape($node_shape);
 Function: Sets node_shape
 Returns : $self
 Args    : node_shape

=cut

    sub set_node_shape {
        my ( $self, $node_shape ) = @_;
        my $id = $self->get_id;
        $node_shape{$id} = $node_shape;
        return $self;
    }

=item set_node_image()

 Type    : Mutator
 Title   : set_node_image
 Usage   : $node->set_node_image($node_image);
 Function: Sets node_image
 Returns : $self
 Args    : node_image

=cut

    sub set_node_image {
        my ( $self, $node_image ) = @_;
        my $id = $self->get_id;
        $node_image{$id} = $node_image;
        return $self;
    }

=item set_branch_color()

 Type    : Mutator
 Title   : set_branch_color
 Usage   : $node->set_branch_color($branch_color);
 Function: Sets branch_color
 Returns : $self
 Args    : branch_color

=cut

    sub set_branch_color {
        my ( $self, $branch_color ) = @_;
        my $id = $self->get_id;
        $branch_color{$id} = $branch_color;
        return $self;
    }

=item set_branch_shape()

 Type    : Mutator
 Title   : set_branch_shape
 Usage   : $node->set_branch_shape($branch_shape);
 Function: Sets branch_shape
 Returns : $self
 Args    : branch_shape

=cut

    sub set_branch_shape {
        my ( $self, $branch_shape ) = @_;
        my $id = $self->get_id;
        $branch_shape{$id} = $branch_shape;
        return $self;
    }

=item set_branch_width()

 Type    : Mutator
 Title   : set_branch_width
 Usage   : $node->set_branch_width($branch_width);
 Function: Sets branch width
 Returns : $self
 Args    : branch_width

=cut

    sub set_branch_width {
        my ( $self, $branch_width ) = @_;
        my $id = $self->get_id;
        $branch_width{$id} = $branch_width;
        $self->_apply_to_nodes( 'set_branch_width', $branch_width );                        
        return $self;
    }

=item set_branch_style()

 Type    : Mutator
 Title   : set_branch_style
 Usage   : $node->set_branch_style($branch_style);
 Function: Sets branch style
 Returns : $self
 Args    : branch_style

=cut

    sub set_branch_style {
        my ( $self, $branch_style ) = @_;
        my $id = $self->get_id;
        $branch_style{$id} = $branch_style;
        return $self;
    } 

=item set_font_face()

 Type    : Mutator
 Title   : set_font_face
 Usage   : $node->set_font_face($font_face);
 Function: Sets font_face
 Returns : $self
 Args    : font_face

=cut

    sub set_font_face {
        my ( $self, $font_face ) = @_;
        my $id = $self->get_id;
        $font_face{$id} = $font_face;
        return $self;
    }

=item set_font_size()

 Type    : Mutator
 Title   : set_font_size
 Usage   : $node->set_font_size($font_size);
 Function: Sets font_size
 Returns : $self
 Args    : font_size

=cut

    sub set_font_size {
        my ( $self, $font_size ) = @_;
        my $id = $self->get_id;
        $font_size{$id} = $font_size;
        return $self;
    }

=item set_font_style()

 Type    : Mutator
 Title   : set_font_style
 Usage   : $node->set_font_style($font_style);
 Function: Sets font_style
 Returns : $self
 Args    : font_style

=cut

    sub set_font_style {
        my ( $self, $font_style ) = @_;
        my $id = $self->get_id;
        $font_style{$id} = $font_style;
        return $self;
    }

=item set_url()

 Type    : Mutator
 Title   : set_url
 Usage   : $node->set_url($url);
 Function: Sets url
 Returns : $self
 Args    : url

=cut

    sub set_url {
        my ( $self, $url ) = @_;
        my $id = $self->get_id;
        $url{$id} = $url;
        return $self;
    }

=item set_text_horiz_offset()

 Type    : Mutator
 Title   : set_text_horiz_offset
 Usage   : $node->set_text_horiz_offset($text_horiz_offset);
 Function: Sets text_horiz_offset
 Returns : $self
 Args    : text_horiz_offset

=cut

    sub set_text_horiz_offset {
        my ( $self, $text_horiz_offset ) = @_;
        my $id = $self->get_id;
        $text_horiz_offset{$id} = $text_horiz_offset;
        return $self;
    }

=item set_text_vert_offset()

 Type    : Mutator
 Title   : set_text_vert_offset
 Usage   : $node->set_text_vert_offset($text_vert_offset);
 Function: Sets text_vert_offset
 Returns : $self
 Args    : text_vert_offset

=cut

    sub set_text_vert_offset {
        my ( $self, $text_vert_offset ) = @_;
        my $id = $self->get_id;
        $text_vert_offset{$id} = $text_vert_offset;
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_x()

 Type    : Accessor
 Title   : get_x
 Usage   : my $x = $node->get_x();
 Function: Gets x
 Returns : x
 Args    : NONE

=cut

    sub get_x {
        my $self = shift;
        my $id = $self->get_id;
        return $x{$id};
    }

=item get_y()

 Type    : Accessor
 Title   : get_y
 Usage   : my $y = $node->get_y();
 Function: Gets y
 Returns : y
 Args    : NONE

=cut

    sub get_y {
        my $self = shift;
        my $id = $self->get_id;
        return $y{$id};
    }

=item get_radius()

 Type    : Accessor
 Title   : get_radius
 Usage   : my $radius = $node->get_radius();
 Function: Gets radius
 Returns : radius
 Args    : NONE

=cut

    sub get_radius {
        my $self = shift;
        my $id = $self->get_id;
        return $radius{$id};
    }

=item get_node_colour()

 Type    : Accessor
 Title   : get_node_colour
 Usage   : my $node_colour = $node->get_node_colour();
 Function: Gets node_colour
 Returns : node_colour
 Args    : NONE

=cut

    sub get_node_colour {
        my $self = shift;
        my $id = $self->get_id;
        return $node_colour{$id};
    }

=item get_node_shape()

 Type    : Accessor
 Title   : get_node_shape
 Usage   : my $node_shape = $node->get_node_shape();
 Function: Gets node_shape
 Returns : node_shape
 Args    : NONE

=cut

    sub get_node_shape {
        my $self = shift;
        my $id = $self->get_id;
        return $node_shape{$id};
    }

=item get_node_image()

 Type    : Accessor
 Title   : get_node_image
 Usage   : my $node_image = $node->get_node_image();
 Function: Gets node_image
 Returns : node_image
 Args    : NONE

=cut

    sub get_node_image {
        my $self = shift;
        my $id = $self->get_id;
        return $node_image{$id};
    }

=item get_branch_color()

 Type    : Accessor
 Title   : get_branch_color
 Usage   : my $branch_color = $node->get_branch_color();
 Function: Gets branch_color
 Returns : branch_color
 Args    : NONE

=cut

    sub get_branch_color {
        my $self = shift;
        my $id = $self->get_id;
        return $branch_color{$id};
    }

=item get_branch_shape()

 Type    : Accessor
 Title   : get_branch_shape
 Usage   : my $branch_shape = $node->get_branch_shape();
 Function: Gets branch_shape
 Returns : branch_shape
 Args    : NONE

=cut

    sub get_branch_shape {
        my $self = shift;
        my $id = $self->get_id;
        return $branch_shape{$id};
    }

=item get_branch_width()

 Type    : Accessor
 Title   : get_branch_width
 Usage   : my $branch_width = $node->get_branch_width();
 Function: Gets branch_width
 Returns : branch_width
 Args    : NONE

=cut

    sub get_branch_width {
        my $self = shift;
        my $id = $self->get_id;
        return $branch_width{$id};
    }

=item get_branch_style()

 Type    : Accessor
 Title   : get_branch_style
 Usage   : my $branch_style = $node->get_branch_style();
 Function: Gets branch_style
 Returns : branch_style
 Args    : NONE

=cut

    sub get_branch_style {
        my $self = shift;
        my $id = $self->get_id;
        return $branch_style{$id};
    }

=item get_font_face()

 Type    : Accessor
 Title   : get_font_face
 Usage   : my $font_face = $node->get_font_face();
 Function: Gets font_face
 Returns : font_face
 Args    : NONE

=cut

    sub get_font_face {
        my $self = shift;
        my $id = $self->get_id;
        return $font_face{$id};
    }

=item get_font_size()

 Type    : Accessor
 Title   : get_font_size
 Usage   : my $font_size = $node->get_font_size();
 Function: Gets font_size
 Returns : font_size
 Args    : NONE

=cut

    sub get_font_size {
        my $self = shift;
        my $id = $self->get_id;
        return $font_size{$id};
    }

=item get_font_style()

 Type    : Accessor
 Title   : get_font_style
 Usage   : my $font_style = $node->get_font_style();
 Function: Gets font_style
 Returns : font_style
 Args    : NONE

=cut

    sub get_font_style {
        my $self = shift;
        my $id = $self->get_id;
        return $font_style{$id};
    }

=item get_url()

 Type    : Accessor
 Title   : get_url
 Usage   : my $url = $node->get_url();
 Function: Gets url
 Returns : url
 Args    : NONE

=cut

    sub get_url {
        my $self = shift;
        my $id = $self->get_id;
        return $url{$id};
    }

=item get_text_horiz_offset()

 Type    : Accessor
 Title   : get_text_horiz_offset
 Usage   : my $text_horiz_offset = $node->get_text_horiz_offset();
 Function: Gets text_horiz_offset
 Returns : text_horiz_offset
 Args    : NONE

=cut

    sub get_text_horiz_offset {
        my $self = shift;
        my $id = $self->get_id;
        return $text_horiz_offset{$id};
    }

=item get_text_vert_offset()

 Type    : Accessor
 Title   : get_text_vert_offset
 Usage   : my $text_vert_offset = $node->get_text_vert_offset();
 Function: Gets text_vert_offset
 Returns : text_vert_offset
 Args    : NONE

=cut

    sub get_text_vert_offset {
        my $self = shift;
        my $id = $self->get_id;
        return $text_vert_offset{$id};
    }

=back

=head2 SERIALIZERS

=over

=item to_json()

Serializes object to JSON string

 Type    : Serializer
 Title   : to_json()
 Usage   : print $obj->to_json();
 Function: Serializes object to JSON string
 Returns : String 
 Args    : None
 Comments:

=cut

    sub to_json {
        my $node = shift;
        my %args = (
            'get_x'                 => 'x',
            'get_y'                 => 'y',
            'get_radius'            => 'radius',
            'get_node_colour'       => 'node_colour',
            'get_node_shape'        => 'node_shape',
            'get_node_image'        => 'image',
            'get_branch_color'      => 'branch_color',
            'get_branch_shape'      => 'branch_shape',
            'get_branch_width'      => 'width',
            'get_branch_style'      => 'style',
            'get_font_face'         => 'font_face',
            'get_font_size'         => 'font_size',
            'get_font_style'        => 'font_style',
            'get_url'               => 'url',
            'get_text_horiz_offset' => 'horiz_offset',
            'get_text_vert_offset'  => 'vert_offset',
        );
        return $node->SUPER::to_json(%args);
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
		my $id = $self->get_id;
		for my $field (@fields) {
			delete $field->{$id};
		}
	}

=back

=cut

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:30 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Forest::DrawNode inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Forest::DrawNode also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::Forest::Node

Bio::Phylo::Forest::DrawNode inherits from superclass L<Bio::Phylo::Forest::Node>. 
Below are the public methods (if any) from this superclass.

=over

=item calc_max_nodes_to_tips()

Calculates maximum number of nodes to tips.

 Type    : Calculation
 Title   : calc_max_nodes_to_tips
 Usage   : my $max_nodes_to_tips =
           $node->calc_max_nodes_to_tips;
 Function: Returns the maximum number
           of nodes from $node to tips.
 Returns : INT
 Args    : NONE

=item calc_max_path_to_tips()

Calculates longest path to tips.

 Type    : Calculation
 Title   : calc_max_path_to_tips
 Usage   : my $max_path_to_tips =
           $node->calc_max_path_to_tips;
 Function: Returns the path length from
           $node to the tallest tip.
 Returns : FLOAT
 Args    : NONE

=item calc_min_nodes_to_tips()

Calculates minimum number of nodes to tips.

 Type    : Calculation
 Title   : calc_min_nodes_to_tips
 Usage   : my $min_nodes_to_tips =
           $node->calc_min_nodes_to_tips;
 Function: Returns the minimum number of
           nodes from $node to tips.
 Returns : INT
 Args    : NONE

=item calc_min_path_to_tips()

Calculates shortest path to tips.

 Type    : Calculation
 Title   : calc_min_path_to_tips
 Usage   : my $min_path_to_tips =
           $node->calc_min_path_to_tips;
 Function: Returns the path length from
           $node to the shortest tip.
 Returns : FLOAT
 Args    : NONE

=item calc_nodal_distance()

Calculates node distance between invocant and argument.

 Type    : Calculation
 Title   : calc_nodal_distance
 Usage   : my $nodal_distance =
           $node->calc_nodal_distance($other_node);
 Function: Returns the number of nodes
           between $node and $other_node.
 Returns : INT
 Args    : Bio::Phylo::Forest::Node

=item calc_nodes_to_root()

Calculates number of nodes to root.

 Type    : Calculation
 Title   : calc_nodes_to_root
 Usage   : my $nodes_to_root =
           $node->calc_nodes_to_root;
 Function: Returns the number of nodes
           from $node to the root.
 Returns : INT
 Args    : NONE

=item calc_path_to_root()

Calculates path to root.

 Type    : Calculation
 Title   : calc_path_to_root
 Usage   : my $path_to_root =
           $node->calc_path_to_root;
 Function: Returns the sum of branch
           lengths from $node to the root.
 Returns : FLOAT
 Args    : NONE

=item calc_patristic_distance()

Calculates patristic distance between invocant and argument.

 Type    : Calculation
 Title   : calc_patristic_distance
 Usage   : my $patristic_distance =
           $node->calc_patristic_distance($other_node);
 Function: Returns the patristic distance
           between $node and $other_node.
 Returns : FLOAT
 Args    : Bio::Phylo::Forest::Node

=item can_contain()

Test if argument(s) can be a child/children of invocant.

 Type    : Test
 Title   : can_contain
 Usage   : if ( $parent->can_contain(@children) ) {
              # do something
           }
 Function: Test if arguments can be children of invocant.
 Returns : BOOLEAN
 Args    : An array of Bio::Phylo::Forest::Node objects;
 Comments: This method is an override of 
           Bio::Phylo::Listable::can_contain. Since node
           objects hold a list of their children, they
           inherit from the listable class and so they
           need to be able to validate the contents
           of that list before they are inserted.

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : Optional: a hash of code references to 
           override reflection-based getter/setter copying

           my $clone = $object->clone(  
               'set_forest' => sub {
                   my ( $self, $clone ) = @_;
                   for my $forest ( @{ $self->get_forests } ) {
                       $clone->set_forest( $forest );
                   }
               },
               'set_matrix' => sub {
                   my ( $self, $clone ) = @_;
                   for my $matrix ( @{ $self->get_matrices } ) {
                       $clone->set_matrix( $matrix );
                   }
           );

 Comments: Cloning is currently experimental, use with caution.
           It works on the assumption that the output of get_foo
           called on the invocant is to be provided as argument
           to set_foo on the clone - such as 
           $clone->set_name( $self->get_name ). Sometimes this 
           doesn't work, for example where this symmetry doesn't
           exist, or where the return value of get_foo isn't valid
           input for set_foo. If such a copy fails, a warning is 
           emitted. To make sure all relevant attributes are copied
           into the clone, additional code references can be 
           provided, as in the example above. Typically, this is
           done by overrides of this method in child classes.

=item collapse()

Collapse node.

 Type    : Mutator
 Title   : collapse
 Usage   : $node->collapse;
 Function: Attaches invocant's children to invocant's parent.
 Returns : Modified object.
 Args    : NONE
 Comments: If defined, adds invocant's branch 
           length to that of its children. If
           $node is in a tree, removes itself
           from that tree.

=item get_ancestors()

Gets invocant's ancestors.

 Type    : Query
 Title   : get_ancestors
 Usage   : my @ancestors = @{ $node->get_ancestors };
 Function: Returns an array reference of ancestral nodes,
           ordered from young to old (i.e. $ancestors[-1] is root).
 Returns : Array reference of Bio::Phylo::Forest::Node
           objects.
 Args    : NONE

=item get_branch_length()

Gets invocant's branch length.

 Type    : Accessor
 Title   : get_branch_length
 Usage   : my $branch_length = $node->get_branch_length;
 Function: Retrieves a node's branch length.
 Returns : FLOAT
 Args    : NONE
 Comments: Test for "defined($node->get_branch_length)"
           for zero-length (but defined) branches. Testing
           "if ( $node->get_branch_length ) { ... }"
           yields false for zero-but-defined branches!

=item get_child()

Gets invocant's i'th child.

 Type    : Query
 Title   : get_child
 Usage   : my $child = $node->get_child($i);
 Function: Returns the child at index $i
 Returns : A Bio::Phylo::Forest::Node object.
 Args    : An index (integer) $i
 Comments: if no index is specified, first
           child is returned

=item get_children()

Gets invocant's immediate children.

 Type    : Query
 Title   : get_children
 Usage   : my @children = @{ $node->get_children };
 Function: Returns an array reference of immediate
           descendants, ordered from left to right.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : NONE

=item get_descendants()

Gets invocant's descendants.

 Type    : Query
 Title   : get_descendants
 Usage   : my @descendants = @{ $node->get_descendants };
 Function: Returns an array reference of
           descendants, recursively ordered
           breadth first.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : none.

=item get_first_daughter()

Gets invocant's first daughter.

 Type    : Accessor
 Title   : get_first_daughter
 Usage   : my $f_daughter = $node->get_first_daughter;
 Function: Retrieves a node's leftmost daughter.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=item get_internals()

Gets invocant's internal descendants.

 Type    : Query
 Title   : get_internals
 Usage   : my @internals = @{ $node->get_internals };
 Function: Returns an array reference
           of internal descendants.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : NONE

=item get_last_daughter()

Gets invocant's last daughter.

 Type    : Accessor
 Title   : get_last_daughter
 Usage   : my $l_daughter = $node->get_last_daughter;
 Function: Retrieves a node's rightmost daughter.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=item get_leftmost_terminal()

Gets invocant's leftmost terminal descendant.

 Type    : Query
 Title   : get_leftmost_terminal
 Usage   : my $leftmost_terminal =
           $node->get_leftmost_terminal;
 Function: Returns the leftmost
           terminal descendant of $node.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=item get_mrca()

Gets invocant's most recent common ancestor shared with argument.

 Type    : Query
 Title   : get_mrca
 Usage   : my $mrca = $node->get_mrca($other_node);
 Function: Returns the most recent common ancestor
           of $node and $other_node.
 Returns : Bio::Phylo::Forest::Node
 Args    : A Bio::Phylo::Forest::Node
           object in the same tree.

=item get_next_sister()

Gets invocant's next sister.

 Type    : Accessor
 Title   : get_next_sister
 Usage   : my $n_sister = $node->get_next_sister;
 Function: Retrieves a node's next sister (to the right).
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=item get_parent()

Gets invocant's parent.

 Type    : Accessor
 Title   : get_parent
 Usage   : my $parent = $node->get_parent;
 Function: Retrieves a node's parent.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=item get_previous_sister()

Gets invocant's previous sister.

 Type    : Accessor
 Title   : get_previous_sister
 Usage   : my $p_sister = $node->get_previous_sister;
 Function: Retrieves a node's previous sister (to the left).
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=item get_rightmost_terminal()

Gets invocant's rightmost terminal descendant

 Type    : Query
 Title   : get_rightmost_terminal
 Usage   : my $rightmost_terminal =
           $node->get_rightmost_terminal;
 Function: Returns the rightmost
           terminal descendant of $node.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=item get_sisters()

Gets invocant's sisters.

 Type    : Query
 Title   : get_sisters
 Usage   : my @sisters = @{ $node->get_sisters };
 Function: Returns an array reference of sisters,
           ordered from left to right.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : NONE

=item get_terminals()

Gets invocant's terminal descendants.

 Type    : Query
 Title   : get_terminals
 Usage   : my @terminals = @{ $node->get_terminals };
 Function: Returns an array reference
           of terminal descendants.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : NONE

=item get_tree()

Returns the tree invocant belongs to

 Type    : Query
 Title   : get_tree
 Usage   : my $tree = $node->get_tree;
 Function: Returns the tree $node belongs to
 Returns : Bio::Phylo::Forest::Tree
 Args    : NONE

=item is_ancestor_of()

Tests if invocant is ancestor of argument.

 Type    : Test
 Title   : is_ancestor_of
 Usage   : if ( $node->is_ancestor_of($grandchild) ) {
              # do something
           }
 Function: Returns true if the node
           is an ancestor of the argument.
 Returns : BOOLEAN
 Args    : putative descendant - a
           Bio::Phylo::Forest::Node object.

=item is_child_of()

Tests if invocant is child of argument.

 Type    : Test
 Title   : is_child_of
 Usage   : if ( $node->is_child_of($parent) ) {
              # do something
           }
 Function: Returns true if the node is
           a child of the argument.
 Returns : BOOLEAN
 Args    : putative parent - a
           Bio::Phylo::Forest::Node object.

=item is_descendant_of()

Tests if invocant is descendant of argument.

 Type    : Test
 Title   : is_descendant_of
 Usage   : if ( $node->is_descendant_of($grandparent) ) {
              # do something
           }
 Function: Returns true if the node is
           a descendant of the argument.
 Returns : BOOLEAN
 Args    : putative ancestor - a
           Bio::Phylo::Forest::Node object.

=item is_first()

Tests if invocant is first sibling in left-to-right order.

 Type    : Test
 Title   : is_first
 Usage   : if ( $node->is_first ) {
              # do something
           }
 Function: Returns true if first sibling 
           in left-to-right order.
 Returns : BOOLEAN
 Args    : NONE

=item is_internal()

Tests if invocant is an internal node.

 Type    : Test
 Title   : is_internal
 Usage   : if ( $node->is_internal ) {
              # do something
           }
 Function: Returns true if node
           has children (i.e. is internal).
 Returns : BOOLEAN
 Args    : NONE

=item is_last()

Tests if invocant is last sibling in left-to-right order.

 Type    : Test
 Title   : is_last
 Usage   : if ( $node->is_last ) {
              # do something
           }
 Function: Returns true if last sibling 
           in left-to-right order.
 Returns : BOOLEAN
 Args    : NONE

=item is_outgroup_of()

Test if invocant is outgroup of argument nodes.

 Type    : Test
 Title   : is_outgroup_of
 Usage   : if ( $node->is_outgroup_of(\@ingroup) ) {
              # do something
           }
 Function: Tests whether the set of
           \@ingroup is monophyletic
           with respect to the $node.
 Returns : BOOLEAN
 Args    : A reference to an array of
           Bio::Phylo::Forest::Node objects;
 Comments: This method is essentially the same as
           &Bio::Phylo::Forest::Tree::is_monophyletic.

=item is_root()

Tests if invocant is a root.

 Type    : Test
 Title   : is_root
 Usage   : if ( $node->is_root ) {
              # do something
           }
 Function: Returns true if node is a root       
 Returns : BOOLEAN
 Args    : NONE

=item is_sister_of()

Tests if invocant is sister of argument.

 Type    : Test
 Title   : is_sister_of
 Usage   : if ( $node->is_sister_of($sister) ) {
              # do something
           }
 Function: Returns true if the node is
           a sister of the argument.
 Returns : BOOLEAN
 Args    : putative sister - a
           Bio::Phylo::Forest::Node object.

=item is_terminal()

Tests if invocant is a terminal node.

 Type    : Test
 Title   : is_terminal
 Usage   : if ( $node->is_terminal ) {
              # do something
           }
 Function: Returns true if node has
           no children (i.e. is terminal).
 Returns : BOOLEAN
 Args    : NONE

=item new()

Node constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $node = Bio::Phylo::Forest::Node->new;
 Function: Instantiates a Bio::Phylo::Forest::Node object
 Returns : Bio::Phylo::Forest::Node
 Args    : All optional:
           -parent          => $parent,
           -taxon           => $taxon,
           -branch_length   => 0.423e+2,
           -first_daughter  => $f_daughter,
           -last_daughter   => $l_daughter,
           -next_sister     => $n_sister,
           -previous_sister => $p_sister,
           -name            => 'node_name',
           -desc            => 'this is a node',
           -score           => 0.98,
           -generic         => {
                -posterior => 0.98,
                -bootstrap => 0.80
           }

=item new_from_bioperl()

Node constructor from bioperl L<Bio::Tree::NodeI> argument.

 Type    : Constructor
 Title   : new_from_bioperl
 Usage   : my $node =
           Bio::Phylo::Forest::Node->new_from_bioperl(
               $bpnode
           );
 Function: Instantiates a Bio::Phylo::Forest::Node object
           from a bioperl node object.
 Returns : Bio::Phylo::Forest::Node
 Args    : An objects that implements Bio::Tree::NodeI
 Notes   : The following BioPerl properties are copied:
           BioPerl output:        Bio::Phylo output:
           ------------------------------------------------
           id                     get_name
           branch_length          get_branch_length
           description            get_desc
           bootstrap              get_generic('bootstrap')
           
           In addition all BioPerl tags and values are copied
           to set_generic( 'tag' => 'value' );

=item prune_child()

Sets argument as invocant's parent.

 Type    : Mutator
 Title   : prune_child
 Usage   : $parent->prune_child($child);
 Function: Removes $child (and its descendants) from $parent's children
 Returns : Modified object.
 Args    : A valid argument is Bio::Phylo::Forest::Node object.

=item set_branch_length()

Sets argument as invocant's branch length.

 Type    : Mutator
 Title   : set_branch_length
 Usage   : $node->set_branch_length(0.423e+2);
 Function: Assigns a node's branch length.
 Returns : Modified object.
 Args    : If no argument is given, the
           current branch length is set
           to undefined. A valid argument
           is a number in any of Perl's formats.

=item set_child()

Sets argument as invocant's child.

 Type    : Mutator
 Title   : set_child
 Usage   : $node->set_child($child);
 Function: Assigns a new child to $node
 Returns : Modified object.
 Args    : A valid argument consists of a
           Bio::Phylo::Forest::Node object.

=item set_first_daughter()

Sets argument as invocant's first daughter.

 Type    : Mutator
 Title   : set_first_daughter
 Usage   : $node->set_first_daughter($f_daughter);
 Function: Assigns a node's leftmost daughter.
 Returns : Modified object.
 Args    : Undefines the first daughter if no
           argument given. A valid argument is
           a Bio::Phylo::Forest::Node object.

=item set_last_daughter()

Sets argument as invocant's last daughter.

 Type    : Mutator
 Title   : set_last_daughter
 Usage   : $node->set_last_daughter($l_daughter);
 Function: Assigns a node's rightmost daughter.
 Returns : Modified object.
 Args    : A valid argument consists of a
           Bio::Phylo::Forest::Node object. If
           no argument is given, the value is
           set to undefined.

=item set_next_sister()

Sets argument as invocant's next sister.

 Type    : Mutator
 Title   : set_next_sister
 Usage   : $node->set_next_sister($n_sister);
 Function: Assigns or retrieves a node's
           next sister (to the right).
 Returns : Modified object.
 Args    : A valid argument consists of a
           Bio::Phylo::Forest::Node object.
           If no argument is given, the
           value is set to undefined.

=item set_node_below()

Sets new (unbranched) node below invocant.

 Type    : Mutator
 Title   : set_node_below
 Usage   : my $new_node = $node->set_node_below;
 Function: Creates a new node below $node
 Returns : New node if tree was modified, undef otherwise
 Args    : NONE

=item set_parent()

Sets argument as invocant's parent.

 Type    : Mutator
 Title   : set_parent
 Usage   : $node->set_parent($parent);
 Function: Assigns a node's parent.
 Returns : Modified object.
 Args    : If no argument is given, the current
           parent is set to undefined. A valid
           argument is Bio::Phylo::Forest::Node
           object.

=item set_previous_sister()

Sets argument as invocant's previous sister.

 Type    : Mutator
 Title   : set_previous_sister
 Usage   : $node->set_previous_sister($p_sister);
 Function: Assigns a node's previous sister (to the left).
 Returns : Modified object.
 Args    : A valid argument consists of
           a Bio::Phylo::Forest::Node object.
           If no argument is given, the value
           is set to undefined.

=item set_root_below()

Reroots below invocant.

 Type    : Mutator
 Title   : set_root_below
 Usage   : $node->set_root_below;
 Function: Creates a new tree root below $node
 Returns : New root if tree was modified, undef otherwise
 Args    : NONE
 Comments: Implementation incomplete: returns spurious 
           results when $node is grandchild of current root.

=item set_tree()

Sets what tree invocant belongs to

 Type    : Mutator
 Title   : set_tree
 Usage   : $node->set_tree($tree);
 Function: Sets what tree invocant belongs to
 Returns : Invocant
 Args    : Bio::Phylo::Forest::Tree
 Comments: This method is called automatically 
           when inserting or deleting nodes in
           trees.

=item to_json()

Serializes object to JSON string

 Type    : Serializer
 Title   : to_json()
 Usage   : print $obj->to_json();
 Function: Serializes object to JSON string
 Returns : String 
 Args    : None
 Comments:

=item to_newick()

Serializes subtree subtended by invocant to newick string.

 Type    : Serializer
 Title   : to_newick
 Usage   : my $newick = $obj->to_newick;
 Function: Turns the invocant object into a newick string.
 Returns : SCALAR
 Args    : takes same arguments as Bio::Phylo::Unparsers::Newick
 Comments: takes same arguments as Bio::Phylo::Unparsers::Newick

=item to_xml()

Serializes invocant to xml.

 Type    : Serializer
 Title   : to_xml
 Usage   : my $xml = $obj->to_xml;
 Function: Turns the invocant object (and its descendants )into an XML string.
 Returns : SCALAR
 Args    : NONE

=item visit_breadth_first()

Visits nodes breadth first

 Type    : Visitor method
 Title   : visit_breadth_first
 Usage   : $tree->visit_breadth_first( -pre => sub{ ... }, -post => sub { ... } );
 Function: Visits nodes in a breadth first traversal, executes handlers
 Returns : $tree
 Args    : Optional handlers in the order in which they would be executed on an internal node:
			
            # first event handler, is executed when node is reached in recursion
            -pre            => sub { print "pre: ",            shift->get_name, "\n" },
            
            # is executed if node has a sister, before sister is processed
            -pre_sister     => sub { print "pre_sister: ",     shift->get_name, "\n" }, 
            
            # is executed if node has a sister, after sister is processed
            -post_sister    => sub { print "post_sister: ",    shift->get_name, "\n" },         
            
            # is executed if node has no sister
            -no_sister      => sub { print "no_sister: ",      shift->get_name, "\n" },             
            
            # is executed whether or not node has sisters, if it does have sisters
            # they're processed first   
            -in             => sub { print "in: ",             shift->get_name, "\n" },         
            
            # is executed if node has a daughter, but before that daughter is processed
            -pre_daughter   => sub { print "pre_daughter: ",   shift->get_name, "\n" },
            
            # is executed if node has a daughter, after daughter has been processed 
            -post_daughter  => sub { print "post_daughter: ",  shift->get_name, "\n" },
            
            # is executed if node has no daughter
            -no_daughter    => sub { print "no_daughter: ",    shift->get_name, "\n" },                         
            
            # is executed last          
            -post           => sub { print "post: ",           shift->get_name, "\n" },
            
            # specifies traversal order, default 'ltr' means first_daugher -> next_sister
            # traversal, alternate value 'rtl' means last_daughter -> previous_sister traversal
            -order          => 'ltr', # ltr = left-to-right, 'rtl' = right-to-left
 Comments: 

=item visit_depth_first()

Visits nodes depth first

 Type    : Visitor method
 Title   : visit_depth_first
 Usage   : $tree->visit_depth_first( -pre => sub{ ... }, -post => sub { ... } );
 Function: Visits nodes in a depth first traversal, executes subs
 Returns : $tree
 Args    : Optional:
            # first event handler, is executed when node is reached in recursion
            -pre            => sub { print "pre: ",            shift->get_name, "\n" },
                        
            # is executed if node has a daughter, but before that daughter is processed
            -pre_daughter   => sub { print "pre_daughter: ",   shift->get_name, "\n" },
            
            # is executed if node has a daughter, after daughter has been processed 
            -post_daughter  => sub { print "post_daughter: ",  shift->get_name, "\n" },
            
            # is executed if node has no daughter
            -no_daughter    => sub { print "no_daughter: ",    shift->get_name, "\n" },                         

            # is executed whether or not node has sisters, if it does have sisters
            # they're processed first   
            -in             => sub { print "in: ",             shift->get_name, "\n" },

            # is executed if node has a sister, before sister is processed
            -pre_sister     => sub { print "pre_sister: ",     shift->get_name, "\n" }, 
            
            # is executed if node has a sister, after sister is processed
            -post_sister    => sub { print "post_sister: ",    shift->get_name, "\n" },         
            
            # is executed if node has no sister
            -no_sister      => sub { print "no_sister: ",      shift->get_name, "\n" }, 
            
            # is executed last          
            -post           => sub { print "post: ",           shift->get_name, "\n" },
            
            # specifies traversal order, default 'ltr' means first_daugher -> next_sister
            # traversal, alternate value 'rtl' means last_daughter -> previous_sister traversal
            -order          => 'ltr', # ltr = left-to-right, 'rtl' = right-to-left
 Comments: 

=item visit_level_order()

Visits nodes in a level order traversal.

 Type    : Visitor method
 Title   : visit_level_order
 Usage   : $tree->visit_level_order( sub{...} );
 Function: Visits nodes in a level order traversal, executes sub
 Returns : $tree
 Args    : A subroutine reference that operates on visited nodes.
 Comments:

=back

=head2 SUPERCLASS Bio::Phylo::Taxa::TaxonLinker

Bio::Phylo::Forest::DrawNode inherits from superclass L<Bio::Phylo::Taxa::TaxonLinker>. 
Below are the public methods (if any) from this superclass.

=over

=item get_taxon()

Retrieves the Bio::Phylo::Taxa::Taxon object linked to the invocant.

 Type    : Accessor
 Title   : get_taxon
 Usage   : my $taxon = $obj->get_taxon;
 Function: Retrieves the Bio::Phylo::Taxa::Taxon
           object linked to the invocant.
 Returns : Bio::Phylo::Taxa::Taxon
 Args    : NONE
 Comments:

=item set_taxon()

Links the invocant object to a taxon object.

 Type    : Mutator
 Title   : set_taxon
 Usage   : $obj->set_taxon( $taxon );
 Function: Links the invocant object
           to a taxon object.
 Returns : Modified $obj
 Args    : A Bio::Phylo::Taxa::Taxon object.

=item unset_taxon()

Unlinks the invocant object from any taxon object.

 Type    : Mutator
 Title   : unset_taxon
 Usage   : $obj->unset_taxon();
 Function: Unlinks the invocant object
           from any taxon object.
 Returns : Modified $obj
 Args    : NONE

=back

=head2 SUPERCLASS Bio::Phylo::Listable

Bio::Phylo::Forest::DrawNode inherits from superclass L<Bio::Phylo::Listable>. 
Below are the public methods (if any) from this superclass.

=over

=item add_set()

 Type    : Mutator
 Title   : add_set
 Usage   : $obj->add_set($set)
 Function: Associates a Bio::Phylo::Set object with the invocant
 Returns : Invocant
 Args    : A Bio::Phylo::Set object

=item add_to_set()

 Type    : Mutator
 Title   : add_to_set
 Usage   : $listable->add_to_set($obj,$set);
 Function: Adds first argument to the second argument
 Returns : Invocant
 Args    : $obj - an object to add to $set
           $set - the Bio::Phylo::Set object to add to
 Notes   : this method assumes that $obj is already 
           part of the invocant. If that assumption is
           violated a warning message is printed.

=item can_contain()

Tests if argument can be inserted in invocant.

 Type    : Test
 Title   : can_contain
 Usage   : &do_something if $listable->can_contain( $obj );
 Function: Tests if $obj can be inserted in $listable
 Returns : BOOL
 Args    : An $obj to test

=item clear()

Empties container object.

 Type    : Object method
 Title   : clear
 Usage   : $obj->clear();
 Function: Clears the container.
 Returns : A Bio::Phylo::Listable object.
 Args    : Note.
 Note    : 

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : None.
 Comments: Cloning is currently experimental, use with caution.

=item contains()

Tests whether the invocant object contains the argument object.

 Type    : Test
 Title   : contains
 Usage   : if ( $obj->contains( $other_obj ) ) {
               # do something
           }
 Function: Tests whether the invocant object 
           contains the argument object
 Returns : BOOLEAN
 Args    : A Bio::Phylo::* object

=item cross_reference()

The cross_reference method links node and datum objects to the taxa they apply
to. After crossreferencing a matrix with a taxa object, every datum object has
a reference to a taxon object stored in its C<$datum-E<gt>get_taxon> field, and
every taxon object has a list of references to datum objects stored in its
C<$taxon-E<gt>get_data> field.

 Type    : Generic method
 Title   : cross_reference
 Usage   : $obj->cross_reference($taxa);
 Function: Crossreferences the entities 
           in the invocant with names 
           in $taxa
 Returns : string
 Args    : A Bio::Phylo::Taxa object
 Comments:

=item current()

Returns the current focal element of the listable object.

 Type    : Iterator
 Title   : current
 Usage   : my $current_obj = $obj->current;
 Function: Retrieves the current focal 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item current_index()

Returns the current internal index of the invocant.

 Type    : Generic query
 Title   : current_index
 Usage   : my $last_index = $obj->current_index;
 Function: Returns the current internal 
           index of the invocant.
 Returns : An integer
 Args    : none.

=item delete()

Deletes argument from invocant object.

 Type    : Object method
 Title   : delete
 Usage   : $obj->delete($other_obj);
 Function: Deletes an object from its container.
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.
 Note    : Be careful with this method: deleting 
           a node from a tree like this will 
           result in undefined references in its 
           neighbouring nodes. Its children will 
           have their parent reference become 
           undef (instead of pointing to their 
           grandparent, as collapsing a node would 
           do). The same is true for taxon objects 
           that reference datum objects: if the 
           datum object is deleted from a matrix 
           (say), the taxon will now hold undefined 
           references.

=item first()

Jumps to the first element contained by the listable object.

 Type    : Iterator
 Title   : first
 Usage   : my $first_obj = $obj->first;
 Function: Retrieves the first 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item get_by_index()

Gets element defined by argument index from invocant container.

 Type    : Query
 Title   : get_by_index
 Usage   : my $contained_obj = $obj->get_by_index($i);
 Function: Retrieves the i'th entity 
           from a listable object.
 Returns : An entity stored by a listable 
           object (or array ref for slices).
 Args    : An index or range. This works 
           the way you dereference any perl
           array including through slices, 
           i.e. $obj->get_by_index(0 .. 10)>
           $obj->get_by_index(0, -1) 
           and so on.
 Comments: Throws if out-of-bounds

=item get_by_name()

Gets first element that has argument name

 Type    : Visitor predicate
 Title   : get_by_name
 Usage   : my $found = $obj->get_by_name('foo');
 Function: Retrieves the first contained object
           in the current Bio::Phylo::Listable 
           object whose name is 'foo'
 Returns : A Bio::Phylo::* object.
 Args    : A name (string)

=item get_by_regular_expression()

Gets elements that match regular expression from invocant container.

 Type    : Visitor predicate
 Title   : get_by_regular_expression
 Usage   : my @objects = @{ 
               $obj->get_by_regular_expression(
                    -value => $method,
                    -match => $re
            ) };
 Function: Retrieves the data in the 
           current Bio::Phylo::Listable 
           object whose $method output 
           matches $re
 Returns : A list of Bio::Phylo::* objects.
 Args    : -value => any of the string 
                     datum props (e.g. 'get_type')
           -match => a compiled regular 
                     expression (e.g. qr/^[D|R]NA$/)

=item get_by_value()

Gets elements that meet numerical rule from invocant container.

 Type    : Visitor predicate
 Title   : get_by_value
 Usage   : my @objects = @{ $obj->get_by_value(
              -value => $method,
              -ge    => $number
           ) };
 Function: Iterates through all objects 
           contained by $obj and returns 
           those for which the output of 
           $method (e.g. get_tree_length) 
           is less than (-lt), less than 
           or equal to (-le), equal to 
           (-eq), greater than or equal to 
           (-ge), or greater than (-gt) $number.
 Returns : A reference to an array of objects
 Args    : -value => any of the numerical 
                     obj data (e.g. tree length)
           -lt    => less than
           -le    => less than or equals
           -eq    => equals
           -ge    => greater than or equals
           -gt    => greater than

=item get_entities()

Returns a reference to an array of objects contained by the listable object.

 Type    : Generic query
 Title   : get_entities
 Usage   : my @entities = @{ $obj->get_entities };
 Function: Retrieves all entities in the invocant.
 Returns : A reference to a list of Bio::Phylo::* 
           objects.
 Args    : none.

=item get_index_of()

Returns the index of the argument in the list,
or undef if the list doesn't contain the argument

 Type    : Generic query
 Title   : get_index_of
 Usage   : my $i = $listable->get_index_of($obj)
 Function: Returns the index of the argument in the list,
           or undef if the list doesn't contain the argument
 Returns : An index or undef
 Args    : A contained object

=item get_logger()

Gets a logger object.

 Type    : Accessor
 Title   : get_logger
 Usage   : my $logger = $obj->get_logger;
 Function: Returns a Bio::Phylo::Util::Logger object
 Returns : Bio::Phylo::Util::Logger
 Args    : None

=item get_sets()

 Type    : Accessor
 Title   : get_sets
 Usage   : my @sets = @{ $obj->get_sets() };
 Function: Retrieves all associated Bio::Phylo::Set objects
 Returns : Invocant
 Args    : None

=item insert()

Pushes an object into its container.

 Type    : Object method
 Title   : insert
 Usage   : $obj->insert($other_obj);
 Function: Pushes an object into its container.
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.

=item insert_at_index()

Inserts argument object in invocant container at argument index.

 Type    : Object method
 Title   : insert_at_index
 Usage   : $obj->insert_at_index($other_obj, $i);
 Function: Inserts $other_obj at index $i in container $obj
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.

=item is_in_set()

 Type    : Test
 Title   : is_in_set
 Usage   : @do_something if $listable->is_in_set($obj,$set);
 Function: Returns whether or not the first argument is listed in the second argument
 Returns : Boolean
 Args    : $obj - an object that may, or may not be in $set
           $set - the Bio::Phylo::Set object to query
 Notes   : This method makes two assumptions:
           i) the $set object is associated with the invocant,
              i.e. add_set($set) has been called previously
           ii) the $obj object is part of the invocant
           If either assumption is violated a warning message
           is printed.

=item last()

Jumps to the last element contained by the listable object.

 Type    : Iterator
 Title   : last
 Usage   : my $last_obj = $obj->last;
 Function: Retrieves the last 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item last_index()

Returns the highest valid index of the invocant.

 Type    : Generic query
 Title   : last_index
 Usage   : my $last_index = $obj->last_index;
 Function: Returns the highest valid 
           index of the invocant.
 Returns : An integer
 Args    : none.

=item next()

Returns the next focal element of the listable object.

 Type    : Iterator
 Title   : next
 Usage   : my $next_obj = $obj->next;
 Function: Retrieves the next focal 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item notify_listeners()

Notifies listeners of changed contents.

 Type    : Utility method
 Title   : notify_listeners
 Usage   : $object->notify_listeners;
 Function: Notifies listeners of changed contents.
 Returns : Invocant.
 Args    : NONE.
 Comments:

=item previous()

Returns the previous element of the listable object.

 Type    : Iterator
 Title   : previous
 Usage   : my $previous_obj = $obj->previous;
 Function: Retrieves the previous 
           focal entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item remove_from_set()

 Type    : Mutator
 Title   : remove_from_set
 Usage   : $listable->remove_from_set($obj,$set);
 Function: Removes first argument from the second argument
 Returns : Invocant
 Args    : $obj - an object to remove from $set
           $set - the Bio::Phylo::Set object to remove from
 Notes   : this method assumes that $obj is already 
           part of the invocant. If that assumption is
           violated a warning message is printed.

=item remove_set()

 Type    : Mutator
 Title   : remove_set
 Usage   : $obj->remove_set($set)
 Function: Removes association between a Bio::Phylo::Set object and the invocant
 Returns : Invocant
 Args    : A Bio::Phylo::Set object

=item set_listener()

Attaches a listener (code ref) which is executed when contents change.

 Type    : Utility method
 Title   : set_listener
 Usage   : $object->set_listener( sub { my $object = shift; } );
 Function: Attaches a listener (code ref) which is executed when contents change.
 Returns : Invocant.
 Args    : A code reference.
 Comments: When executed, the code reference will receive $object
           (the invocant) as its first argument.

=item visit()

Iterates over objects contained by invocant, executes argument
code reference on each.

 Type    : Visitor predicate
 Title   : visit
 Usage   : $obj->visit( 
               sub{ print $_[0]->get_name, "\n" } 
           );
 Function: Implements visitor pattern 
           using code reference.
 Returns : The invocant, possibly modified.
 Args    : a CODE reference.

=back

=head2 SUPERCLASS Bio::Phylo::Util::XMLWritable

Bio::Phylo::Forest::DrawNode inherits from superclass L<Bio::Phylo::Util::XMLWritable>. 
Below are the public methods (if any) from this superclass.

=over

=item add_dictionary()

 Type    : Mutator
 Title   : add_dictionary
 Usage   : $obj->add_dictionary($dict);
 Function: Adds a dictionary attachment to the object
 Returns : $self
 Args    : Bio::Phylo::Dictionary

=item get_attributes()

Retrieves attributes for the element.

 Type    : Accessor
 Title   : get_attributes
 Usage   : my %attrs = %{ $obj->get_attributes };
 Function: Gets the xml attributes for the object;
 Returns : A hash reference
 Args    : None.
 Comments: throws ObjectMismatch if no linked taxa object 
           can be found

=item get_dictionaries()

Retrieves the dictionaries for the element.

 Type    : Accessor
 Title   : get_dictionaries
 Usage   : my @dicts = @{ $obj->get_dictionaries };
 Function: Retrieves the dictionaries for the element.
 Returns : An array ref of Bio::Phylo::Dictionary objects
 Args    : None.

=item get_namespaces()

 Type    : Accessor
 Title   : get_namespaces
 Usage   : my %ns = %{ $obj->get_namespaces };
 Function: Retrieves the known namespaces
 Returns : A hash of prefix/namespace key/value pairs, or
           a single namespace if a single, optional
           prefix was provided as argument
 Args    : Optional - a namespace prefix

=item get_tag()

Retrieves tag name for the element.

 Type    : Accessor
 Title   : get_tag
 Usage   : my $tag = $obj->get_tag;
 Function: Gets the xml tag name for the object;
 Returns : A tag name
 Args    : None.

=item get_xml_id()

Retrieves xml id for the element.

 Type    : Accessor
 Title   : get_xml_id
 Usage   : my $id = $obj->get_xml_id;
 Function: Gets the xml id for the object;
 Returns : An xml id
 Args    : None.

=item get_xml_tag()

Retrieves tag string

 Type    : Accessor
 Title   : get_xml_tag
 Usage   : my $str = $obj->get_xml_tag;
 Function: Gets the xml tag for the object;
 Returns : A tag, i.e. pointy brackets
 Args    : Optional: a true value, to close an empty tag

=item is_identifiable()

By default, all XMLWritable objects are identifiable when serialized,
i.e. they have a unique id attribute. However, in some cases a serialized
object may not have an id attribute (governed by the nexml schema). This
method indicates whether that is the case.

 Type    : Test
 Title   : is_identifiable
 Usage   : if ( $obj->is_identifiable ) { ... }
 Function: Indicates whether IDs are generated
 Returns : BOOLEAN
 Args    : NONE

=item remove_dictionary()

 Type    : Mutator
 Title   : remove_dictionary
 Usage   : $obj->remove_dictionary($dict);
 Function: Removes a dictionary attachment from the object
 Returns : $self
 Args    : Bio::Phylo::Dictionary

=item set_attributes()

Assigns attributes for the element.

 Type    : Mutator
 Title   : set_attributes
 Usage   : $obj->set_attributes( 'foo' => 'bar' )
 Function: Sets the xml attributes for the object;
 Returns : $self
 Args    : key/value pairs or a hash ref

=item set_identifiable()

By default, all XMLWritable objects are identifiable when serialized,
i.e. they have a unique id attribute. However, in some cases a serialized
object may not have an id attribute (governed by the nexml schema). For
such objects, id generation can be explicitly disabled using this method.
Typically, this is done internally - you will probably never use this method.

 Type    : Mutator
 Title   : set_identifiable
 Usage   : $obj->set_tag(0);
 Function: Enables/disables id generation
 Returns : $self
 Args    : BOOLEAN

=item set_namespaces()

 Type    : Mutator
 Title   : set_namespaces
 Usage   : $obj->set_namespaces( 'dwc' => 'http://www.namespaceTBD.org/darwin2' );
 Function: Adds one or more prefix/namespace pairs
 Returns : $self
 Args    : One or more prefix/namespace pairs, as even-sized list, 
           or as a hash reference, i.e.:
           $obj->set_namespaces( 'dwc' => 'http://www.namespaceTBD.org/darwin2' );
           or
           $obj->set_namespaces( { 'dwc' => 'http://www.namespaceTBD.org/darwin2' } );
 Notes   : This is a global for the XMLWritable class, so that in a recursive
 		   to_xml call the outermost element contains the namespace definitions.
 		   This method can also be called as a static class method, i.e.
 		   Bio::Phylo::Util::XMLWritable->set_namespaces(
 		   'dwc' => 'http://www.namespaceTBD.org/darwin2');

=item set_tag()

This method is usually only used internally, to define or alter the
name of the tag into which the object is serialized. For example,
for a Bio::Phylo::Forest::Node object, this method would be called 
with the 'node' argument, so that the object is serialized into an
xml element structure called <node/>

 Type    : Mutator
 Title   : set_tag
 Usage   : $obj->set_tag('node');
 Function: Sets the tag name
 Returns : $self
 Args    : A tag name (must be a valid xml element name)

=item set_xml_id()

This method is usually only used internally, to store the xml id
of an object as it is parsed out of a nexml file - this is for
the purpose of round-tripping nexml info sets.

 Type    : Mutator
 Title   : set_xml_id
 Usage   : $obj->set_xml_id('node345');
 Function: Sets the xml id
 Returns : $self
 Args    : An xml id (must be a valid xml NCName)

=item to_xml()

Serializes invocant to XML.

 Type    : XML serializer
 Title   : to_xml
 Usage   : my $xml = $obj->to_xml;
 Function: Serializes $obj to xml
 Returns : An xml string
 Args    : None

=back

=head2 SUPERCLASS Bio::Phylo

Bio::Phylo::Forest::DrawNode inherits from superclass L<Bio::Phylo>. 
Below are the public methods (if any) from this superclass.

=over

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : None.
 Comments: Cloning is currently experimental, use with caution.

=item get()

Attempts to execute argument string as method on invocant.

 Type    : Accessor
 Title   : get
 Usage   : my $treename = $tree->get('get_name');
 Function: Alternative syntax for safely accessing
           any of the object data; useful for
           interpolating runtime $vars.
 Returns : (context dependent)
 Args    : a SCALAR variable, e.g. $var = 'get_name';

=item get_desc()

Gets invocant description.

 Type    : Accessor
 Title   : get_desc
 Usage   : my $desc = $obj->get_desc;
 Function: Returns the object's description (if any).
 Returns : A string
 Args    : None

=item get_generic()

Gets generic hashref or hash value(s).

 Type    : Accessor
 Title   : get_generic
 Usage   : my $value = $obj->get_generic($key);
           or
           my %hash = %{ $obj->get_generic() };
 Function: Returns the object's generic data. If an
           argument is used, it is considered a key
           for which the associated value is returned.
           Without arguments, a reference to the whole
           hash is returned.
 Returns : A string or hash reference.
 Args    : None

=item get_id()

Gets invocant's UID.

 Type    : Accessor
 Title   : get_id
 Usage   : my $id = $obj->get_id;
 Function: Returns the object's unique ID
 Returns : INT
 Args    : None

=item get_internal_name()

Gets invocant's 'fallback' name (possibly autogenerated).

 Type    : Accessor
 Title   : get_internal_name
 Usage   : my $name = $obj->get_internal_name;
 Function: Returns the object's name (if none was set, the name
           is a combination of the $obj's class and its UID).
 Returns : A string
 Args    : None

=item get_logger()

Gets a logger object.

 Type    : Accessor
 Title   : get_logger
 Usage   : my $logger = $obj->get_logger;
 Function: Returns a Bio::Phylo::Util::Logger object
 Returns : Bio::Phylo::Util::Logger
 Args    : None

=item get_name()

Gets invocant's name.

 Type    : Accessor
 Title   : get_name
 Usage   : my $name = $obj->get_name;
 Function: Returns the object's name.
 Returns : A string
 Args    : None

=item get_obj_by_id()

Attempts to fetch an in-memory object by its UID

 Type    : Accessor
 Title   : get_obj_by_id
 Usage   : my $obj = Bio::Phylo->get_obj_by_id($uid);
 Function: Fetches an object from the IDPool cache
 Returns : A Bio::Phylo object 
 Args    : A unique id

=item get_score()

Gets invocant's score.

 Type    : Accessor
 Title   : get_score
 Usage   : my $score = $obj->get_score;
 Function: Returns the object's numerical score (if any).
 Returns : A number
 Args    : None

=item new()

The Bio::Phylo root constructor, is rarely used directly. Rather, many other 
objects in Bio::Phylo internally go up the inheritance tree to this constructor. 
The arguments shown here can therefore also be passed to any of the child 
classes' constructors, which will pass them on up the inheritance tree. Generally, 
constructors in Bio::Phylo subclasses can process as arguments all methods that 
have set_* in their names. The arguments are named for the methods, but "set_" 
has been replaced with a dash "-", e.g. the method "set_name" becomes the 
argument "-name" in the constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $phylo = Bio::Phylo->new;
 Function: Instantiates Bio::Phylo object
 Returns : a Bio::Phylo object 
 Args    : Optional, any number of setters. For example,
 		   Bio::Phylo->new( -name => $name )
 		   will call set_name( $name ) internally

=item set_desc()

Sets invocant description.

 Type    : Mutator
 Title   : set_desc
 Usage   : $obj->set_desc($desc);
 Function: Assigns an object's description.
 Returns : Modified object.
 Args    : Argument must be a string.

=item set_generic()

Sets generic key/value pair(s).

 Type    : Mutator
 Title   : set_generic
 Usage   : $obj->set_generic( %generic );
 Function: Assigns generic key/value pairs to the invocant.
 Returns : Modified object.
 Args    : Valid arguments constitute:

           * key/value pairs, for example:
             $obj->set_generic( '-lnl' => 0.87565 );

           * or a hash ref, for example:
             $obj->set_generic( { '-lnl' => 0.87565 } );

           * or nothing, to reset the stored hash, e.g.
                $obj->set_generic( );

=item set_name()

Sets invocant name.

 Type    : Mutator
 Title   : set_name
 Usage   : $obj->set_name($name);
 Function: Assigns an object's name.
 Returns : Modified object.
 Args    : Argument must be a string, will be single 
           quoted if it contains [;|,|:\(|\)] 
           or spaces. Preceding and trailing spaces
           will be removed.

=item set_score()

Sets invocant score.

 Type    : Mutator
 Title   : set_score
 Usage   : $obj->set_score($score);
 Function: Assigns an object's numerical score.
 Returns : Modified object.
 Args    : Argument must be any of
           perl's number formats, or undefined
           to reset score.

=item to_json()

Serializes object to JSON string

 Type    : Serializer
 Title   : to_json()
 Usage   : print $obj->to_json();
 Function: Serializes object to JSON string
 Returns : String 
 Args    : None
 Comments:

=item to_string()

Serializes object to general purpose string

 Type    : Serializer
 Title   : to_string()
 Usage   : print $obj->to_string();
 Function: Serializes object to general purpose string
 Returns : String 
 Args    : None
 Comments: This is YAML

=back

=cut

# podinherit_stop_token_do_not_remove

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Forest::Node>

This object inherits from L<Bio::Phylo::Forest::Node>, so methods
defined there are also applicable here.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: DrawNode.pm 844 2009-03-05 00:07:26Z rvos $

=cut

}
1;