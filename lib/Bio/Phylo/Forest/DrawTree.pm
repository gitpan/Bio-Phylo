package Bio::Phylo::Forest::DrawTree;
use strict;
use Bio::Phylo::Forest::Tree;
use Bio::Phylo::Forest::DrawNode;
use Bio::Phylo::Util::CONSTANT qw(looks_like_hash);
use vars '@ISA';
@ISA=qw(Bio::Phylo::Forest::Tree);
{
	# @fields array necessary for object destruction
	my @fields = \( 
	    my ( 
            %width,
            %height,
            %node_radius,
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
            %margin,
            %margin_top,
            %margin_bottom,
            %margin_left,
            %margin_right,
            %padding,
            %padding_top,
            %padding_bottom,
            %padding_left,
            %padding_right,
            %mode,
            %shape,
            %text_horiz_offset,
            %text_vert_offset,
	    ) 	
	);

=head1 NAME

Bio::Phylo::Forest::DrawTree - Tree with extra methods for tree drawing

=head1 SYNOPSIS

 # see Bio::Phylo::Forest::Tree

=head1 DESCRIPTION

The object models a phylogenetic tree, a container of Bio::Phylo::For-
est::Node objects. The tree object inherits from Bio::Phylo::Listable,
so look there for more methods.

In addition, this subclass of the default tree object L<Bio::Phylo::Forest::Tree>
has getters and setters for drawing trees, e.g. font and text attributes, etc.

=head1 METHODS

=head2 CONSTRUCTORS

=over

=item new()

Tree constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $tree = Bio::Phylo::Forest::DrawTree->new;
 Function: Instantiates a Bio::Phylo::Forest::DrawTree object.
 Returns : A Bio::Phylo::Forest::DrawTree object.
 Args    : No required arguments.

=cut

    sub new {
        my $class = shift;
        my %args = looks_like_hash @_;
        if ( not $args{'-tree'} ) {
            return $class->SUPER::new( @_ );
        }
        else {
            my $tree = $args{'-tree'};
            my $self = $tree->clone;
            bless $self, $class;
            $self->visit(sub{bless shift, 'Bio::Phylo::Forest::DrawNode'});
            delete $args{'-tree'};
            for my $key ( keys %args ) {
                my $method = $key;
                $method =~ s/^-/set_/;
                $self->$method( $args{$key} );
            }
            return $self;
        }    
    }

=back

=head2 MUTATORS

=over

=item set_width()

 Type    : Mutator
 Title   : set_width
 Usage   : $tree->set_width($width);
 Function: Sets width
 Returns : $self
 Args    : width

=cut

    sub set_width {
        my ( $self, $width ) = @_;
        my $id = $self->get_id;
        $width{$id} = $width;
        $self->_redraw;
        return $self;
    }

=item set_height()

 Type    : Mutator
 Title   : set_height
 Usage   : $tree->set_height($height);
 Function: Sets height
 Returns : $self
 Args    : height

=cut

    sub set_height {
        my ( $self, $height ) = @_;
        my $id = $self->get_id;
        $height{$id} = $height;
        $self->_redraw;        
        return $self;
    }

=item set_node_radius()

 Type    : Mutator
 Title   : set_node_radius
 Usage   : $tree->set_node_radius($node_radius);
 Function: Sets node_radius
 Returns : $self
 Args    : node_radius

=cut

    sub set_node_radius {
        my ( $self, $node_radius ) = @_;
        my $id = $self->get_id;
        $node_radius{$id} = $node_radius;
        $self->_apply_to_nodes( 'set_radius', $node_radius );
        return $self;
    }

=item set_node_colour()

 Type    : Mutator
 Title   : set_node_colour
 Usage   : $tree->set_node_colour($node_colour);
 Function: Sets node_colour
 Returns : $self
 Args    : node_colour

=cut

    sub set_node_colour {
        my ( $self, $node_colour ) = @_;
        my $id = $self->get_id;
        $node_colour{$id} = $node_colour;
        $self->_apply_to_nodes( 'set_node_colour', $node_colour );        
        return $self;
    }

=item set_node_shape()

 Type    : Mutator
 Title   : set_node_shape
 Usage   : $tree->set_node_shape($node_shape);
 Function: Sets node_shape
 Returns : $self
 Args    : node_shape

=cut

    sub set_node_shape {
        my ( $self, $node_shape ) = @_;
        my $id = $self->get_id;
        $node_shape{$id} = $node_shape;
        $self->_apply_to_nodes( 'set_node_shape', $node_shape );
        return $self;
    }

=item set_node_image()

 Type    : Mutator
 Title   : set_node_image
 Usage   : $tree->set_node_image($node_image);
 Function: Sets node_image
 Returns : $self
 Args    : node_image

=cut

    sub set_node_image {
        my ( $self, $node_image ) = @_;
        my $id = $self->get_id;
        $node_image{$id} = $node_image;
        $self->_apply_to_nodes( 'set_node_image', $node_image );        
        return $self;
    }

=item set_branch_color()

 Type    : Mutator
 Title   : set_branch_color
 Usage   : $tree->set_branch_color($branch_color);
 Function: Sets branch_color
 Returns : $self
 Args    : branch_color

=cut

    sub set_branch_color {
        my ( $self, $branch_color ) = @_;
        my $id = $self->get_id;
        $branch_color{$id} = $branch_color;
        $self->_apply_to_nodes( 'set_branch_color', $branch_color );                
        return $self;
    }

=item set_branch_shape()

 Type    : Mutator
 Title   : set_branch_shape
 Usage   : $tree->set_branch_shape($branch_shape);
 Function: Sets branch_shape
 Returns : $self
 Args    : branch_shape

=cut

    sub set_branch_shape {
        my ( $self, $branch_shape ) = @_;
        my $id = $self->get_id;
        $branch_shape{$id} = $branch_shape;
        $self->_apply_to_nodes( 'set_branch_shape', $branch_shape );                        
        return $self;
    }

=item set_branch_width()

 Type    : Mutator
 Title   : set_branch_width
 Usage   : $tree->set_branch_width($branch_width);
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
 Usage   : $tree->set_branch_style($branch_style);
 Function: Sets branch style
 Returns : $self
 Args    : branch_style

=cut

    sub set_branch_style {
        my ( $self, $branch_style ) = @_;
        my $id = $self->get_id;
        $branch_style{$id} = $branch_style;
        $self->_apply_to_nodes( 'set_branch_style', $branch_style );                        
        return $self;
    }    

=item set_font_face()

 Type    : Mutator
 Title   : set_font_face
 Usage   : $tree->set_font_face($font_face);
 Function: Sets font_face
 Returns : $self
 Args    : font face, Verdana, Arial, Serif

=cut

    sub set_font_face {
        my ( $self, $font_face ) = @_;
        my $id = $self->get_id;
        $font_face{$id} = $font_face;
        $self->_apply_to_nodes( 'set_font_face', $font_face );                                
        return $self;
    }

=item set_font_size()

 Type    : Mutator
 Title   : set_font_size
 Usage   : $tree->set_font_size($font_size);
 Function: Sets font_size
 Returns : $self
 Args    : Font size in pixels

=cut

    sub set_font_size {
        my ( $self, $font_size ) = @_;
        my $id = $self->get_id;
        $font_size{$id} = $font_size;
        $self->_apply_to_nodes( 'set_font_size', $font_size );                                        
        return $self;
    }

=item set_font_style()

 Type    : Mutator
 Title   : set_font_style
 Usage   : $tree->set_font_style($font_style);
 Function: Sets font_style
 Returns : $self
 Args    : Font style, e.g. Italic

=cut

    sub set_font_style {
        my ( $self, $font_style ) = @_;
        my $id = $self->get_id;
        $font_style{$id} = $font_style;
        $self->_apply_to_nodes( 'set_font_style', $font_style );                                        
        return $self;
    }

=item set_margin()

 Type    : Mutator
 Title   : set_margin
 Usage   : $tree->set_margin($margin);
 Function: Sets margin
 Returns : $self
 Args    : margin

=cut

    sub set_margin {
        my ( $self, $margin ) = @_;
        my $id = $self->get_id;
        $margin{$id} = $margin;
        for my $setter ( qw(top bottom left right) ) {
            my $method = 'set_margin_' . $setter;
            $self->$method( $margin );
        }   
        $self->_redraw;        
        return $self;
    }

=item set_margin_top()

 Type    : Mutator
 Title   : set_margin_top
 Usage   : $tree->set_margin_top($margin_top);
 Function: Sets margin_top
 Returns : $self
 Args    : margin_top

=cut

    sub set_margin_top {
        my ( $self, $margin_top ) = @_;
        my $id = $self->get_id;
        $margin_top{$id} = $margin_top;
        $self->_redraw;        
        return $self;
    }

=item set_margin_bottom()

 Type    : Mutator
 Title   : set_margin_bottom
 Usage   : $tree->set_margin_bottom($margin_bottom);
 Function: Sets margin_bottom
 Returns : $self
 Args    : margin_bottom

=cut

    sub set_margin_bottom {
        my ( $self, $margin_bottom ) = @_;
        my $id = $self->get_id;
        $margin_bottom{$id} = $margin_bottom;
        $self->_redraw;        
        return $self;
    }

=item set_margin_left()

 Type    : Mutator
 Title   : set_margin_left
 Usage   : $tree->set_margin_left($margin_left);
 Function: Sets margin_left
 Returns : $self
 Args    : margin_left

=cut

    sub set_margin_left {
        my ( $self, $margin_left ) = @_;
        my $id = $self->get_id;
        $margin_left{$id} = $margin_left;
        $self->_redraw;        
        return $self;
    }

=item set_margin_right()

 Type    : Mutator
 Title   : set_margin_right
 Usage   : $tree->set_margin_right($margin_right);
 Function: Sets margin_right
 Returns : $self
 Args    : margin_right

=cut

    sub set_margin_right {
        my ( $self, $margin_right ) = @_;
        my $id = $self->get_id;
        $margin_right{$id} = $margin_right;
        $self->_redraw;        
        return $self;
    }

=item set_padding()

 Type    : Mutator
 Title   : set_padding
 Usage   : $tree->set_padding($padding);
 Function: Sets padding
 Returns : $self
 Args    : padding

=cut

    sub set_padding {
        my ( $self, $padding ) = @_;
        my $id = $self->get_id;
        $padding{$id} = $padding;
        for my $setter ( qw(top bottom left right) ) {
            my $method = 'set_padding_' . $setter;
            $self->$method( $padding );
        }
        $self->_redraw;        
        return $self;
    }

=item set_padding_top()

 Type    : Mutator
 Title   : set_padding_top
 Usage   : $tree->set_padding_top($padding_top);
 Function: Sets padding_top
 Returns : $self
 Args    : padding_top

=cut

    sub set_padding_top {
        my ( $self, $padding_top ) = @_;
        my $id = $self->get_id;
        $padding_top{$id} = $padding_top;
        $self->_redraw;        
        return $self;
    }

=item set_padding_bottom()

 Type    : Mutator
 Title   : set_padding_bottom
 Usage   : $tree->set_padding_bottom($padding_bottom);
 Function: Sets padding_bottom
 Returns : $self
 Args    : padding_bottom

=cut

    sub set_padding_bottom {
        my ( $self, $padding_bottom ) = @_;
        my $id = $self->get_id;
        $padding_bottom{$id} = $padding_bottom;
        $self->_redraw;        
        return $self;
    }

=item set_padding_left()

 Type    : Mutator
 Title   : set_padding_left
 Usage   : $tree->set_padding_left($padding_left);
 Function: Sets padding_left
 Returns : $self
 Args    : padding_left

=cut

    sub set_padding_left {
        my ( $self, $padding_left ) = @_;
        my $id = $self->get_id;
        $padding_left{$id} = $padding_left;
        $self->_redraw;        
        return $self;
    }

=item set_padding_right()

 Type    : Mutator
 Title   : set_padding_right
 Usage   : $tree->set_padding_right($padding_right);
 Function: Sets padding_right
 Returns : $self
 Args    : padding_right

=cut

    sub set_padding_right {
        my ( $self, $padding_right ) = @_;
        my $id = $self->get_id;
        $padding_right{$id} = $padding_right;
        $self->_redraw;        
        return $self;
    }

=item set_mode()

 Type    : Mutator
 Title   : set_mode
 Usage   : $tree->set_mode($mode);
 Function: Sets mode
 Returns : $self
 Args    : mode, e.g. 'CLADO' or 'PHYLO'

=cut

    sub set_mode {
        my ( $self, $mode ) = @_;
        my $id = $self->get_id;
        $mode{$id} = $mode;
        $self->_redraw;        
        return $self;
    }

=item set_shape()

 Type    : Mutator
 Title   : set_shape
 Usage   : $tree->set_shape($shape);
 Function: Sets shape
 Returns : $self
 Args    : shape, e.g. 'RECT', 'CURVY', 'DIAG'

=cut

    sub set_shape {
        my ( $self, $shape ) = @_;
        my $id = $self->get_id;
        $shape{$id} = $shape;
        return $self;
    }

=item set_text_horiz_offset()

 Type    : Mutator
 Title   : set_text_horiz_offset
 Usage   : $tree->set_text_horiz_offset($text_horiz_offset);
 Function: Sets text_horiz_offset
 Returns : $self
 Args    : text_horiz_offset

=cut

    sub set_text_horiz_offset {
        my ( $self, $text_horiz_offset ) = @_;
        my $id = $self->get_id;
        $text_horiz_offset{$id} = $text_horiz_offset;
        $self->_apply_to_nodes( 'set_text_horiz_offset', $text_horiz_offset );       
        return $self;
    }

=item set_text_vert_offset()

 Type    : Mutator
 Title   : set_text_vert_offset
 Usage   : $tree->set_text_vert_offset($text_vert_offset);
 Function: Sets text_vert_offset
 Returns : $self
 Args    : text_vert_offset

=cut

    sub set_text_vert_offset {
        my ( $self, $text_vert_offset ) = @_;
        my $id = $self->get_id;
        $text_vert_offset{$id} = $text_vert_offset;
        $self->_apply_to_nodes( 'set_text_vert_offset', $text_vert_offset );        
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_width()

 Type    : Accessor
 Title   : get_width
 Usage   : my $width = $tree->get_width();
 Function: Gets width
 Returns : width
 Args    : NONE

=cut

    sub get_width {
        my $self = shift;
        my $id = $self->get_id;
        return $width{$id};
    }

=item get_height()

 Type    : Accessor
 Title   : get_height
 Usage   : my $height = $tree->get_height();
 Function: Gets height
 Returns : height
 Args    : NONE

=cut

    sub get_height {
        my $self = shift;
        my $id = $self->get_id;
        return $height{$id};
    }

=item get_node_radius()

 Type    : Accessor
 Title   : get_node_radius
 Usage   : my $node_radius = $tree->get_node_radius();
 Function: Gets node_radius
 Returns : node_radius
 Args    : NONE

=cut

    sub get_node_radius {
        my $self = shift;
        my $id = $self->get_id;
        return $node_radius{$id};
    }

=item get_node_colour()

 Type    : Accessor
 Title   : get_node_colour
 Usage   : my $node_colour = $tree->get_node_colour();
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
 Usage   : my $node_shape = $tree->get_node_shape();
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
 Usage   : my $node_image = $tree->get_node_image();
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
 Usage   : my $branch_color = $tree->get_branch_color();
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
 Usage   : my $branch_shape = $tree->get_branch_shape();
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
 Usage   : my $branch_width = $tree->get_branch_width();
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
 Usage   : my $branch_style = $tree->get_branch_style();
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
 Usage   : my $font_face = $tree->get_font_face();
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
 Usage   : my $font_size = $tree->get_font_size();
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
 Usage   : my $font_style = $tree->get_font_style();
 Function: Gets font_style
 Returns : font_style
 Args    : NONE

=cut

    sub get_font_style {
        my $self = shift;
        my $id = $self->get_id;
        return $font_style{$id};
    }

=item get_margin()

 Type    : Accessor
 Title   : get_margin
 Usage   : my $margin = $tree->get_margin();
 Function: Gets margin
 Returns : margin
 Args    : NONE

=cut

    sub get_margin {
        my $self = shift;
        my $id = $self->get_id;
        return $margin{$id};
    }

=item get_margin_top()

 Type    : Accessor
 Title   : get_margin_top
 Usage   : my $margin_top = $tree->get_margin_top();
 Function: Gets margin_top
 Returns : margin_top
 Args    : NONE

=cut

    sub get_margin_top {
        my $self = shift;
        my $id = $self->get_id;
        return $margin_top{$id};
    }

=item get_margin_bottom()

 Type    : Accessor
 Title   : get_margin_bottom
 Usage   : my $margin_bottom = $tree->get_margin_bottom();
 Function: Gets margin_bottom
 Returns : margin_bottom
 Args    : NONE

=cut

    sub get_margin_bottom {
        my $self = shift;
        my $id = $self->get_id;
        return $margin_bottom{$id};
    }

=item get_margin_left()

 Type    : Accessor
 Title   : get_margin_left
 Usage   : my $margin_left = $tree->get_margin_left();
 Function: Gets margin_left
 Returns : margin_left
 Args    : NONE

=cut

    sub get_margin_left {
        my $self = shift;
        my $id = $self->get_id;
        return $margin_left{$id};
    }

=item get_margin_right()

 Type    : Accessor
 Title   : get_margin_right
 Usage   : my $margin_right = $tree->get_margin_right();
 Function: Gets margin_right
 Returns : margin_right
 Args    : NONE

=cut

    sub get_margin_right {
        my $self = shift;
        my $id = $self->get_id;
        return $margin_right{$id};
    }

=item get_padding()

 Type    : Accessor
 Title   : get_padding
 Usage   : my $padding = $tree->get_padding();
 Function: Gets padding
 Returns : padding
 Args    : NONE

=cut

    sub get_padding {
        my $self = shift;
        my $id = $self->get_id;
        return $padding{$id};
    }

=item get_padding_top()

 Type    : Accessor
 Title   : get_padding_top
 Usage   : my $padding_top = $tree->get_padding_top();
 Function: Gets padding_top
 Returns : padding_top
 Args    : NONE

=cut

    sub get_padding_top {
        my $self = shift;
        my $id = $self->get_id;
        return $padding_top{$id};
    }

=item get_padding_bottom()

 Type    : Accessor
 Title   : get_padding_bottom
 Usage   : my $padding_bottom = $tree->get_padding_bottom();
 Function: Gets padding_bottom
 Returns : padding_bottom
 Args    : NONE

=cut

    sub get_padding_bottom {
        my $self = shift;
        my $id = $self->get_id;
        return $padding_bottom{$id};
    }

=item get_padding_left()

 Type    : Accessor
 Title   : get_padding_left
 Usage   : my $padding_left = $tree->get_padding_left();
 Function: Gets padding_left
 Returns : padding_left
 Args    : NONE

=cut

    sub get_padding_left {
        my $self = shift;
        my $id = $self->get_id;
        return $padding_left{$id};
    }

=item get_padding_right()

 Type    : Accessor
 Title   : get_padding_right
 Usage   : my $padding_right = $tree->get_padding_right();
 Function: Gets padding_right
 Returns : padding_right
 Args    : NONE

=cut

    sub get_padding_right {
        my $self = shift;
        my $id = $self->get_id;
        return $padding_right{$id};
    }

=item get_mode()

 Type    : Accessor
 Title   : get_mode
 Usage   : my $mode = $tree->get_mode();
 Function: Gets mode
 Returns : mode
 Args    : NONE

=cut

    sub get_mode {
        my $self = shift;
        my $id = $self->get_id;
        if ( $self->is_cladogram ) {
            $mode{$id} = 'CLADO';
        }
        return $mode{$id};
    }

=item get_shape()

 Type    : Accessor
 Title   : get_shape
 Usage   : my $shape = $tree->get_shape();
 Function: Gets shape
 Returns : shape
 Args    : NONE

=cut

    sub get_shape {
        my $self = shift;
        my $id = $self->get_id;
        return $shape{$id};
    }

=item get_text_horiz_offset()

 Type    : Accessor
 Title   : get_text_horiz_offset
 Usage   : my $text_horiz_offset = $tree->get_text_horiz_offset();
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
 Usage   : my $text_vert_offset = $tree->get_text_vert_offset();
 Function: Gets text_vert_offset
 Returns : text_vert_offset
 Args    : NONE

=cut

    sub get_text_vert_offset {
        my $self = shift;
        my $id = $self->get_id;
        return $text_vert_offset{$id};
    }

=begin comment

This method re-computes the node coordinates

=end comment

=cut

    sub _redraw {
        my $self = shift;
        my ( $width, $height ) = ( $self->get_width, $self->get_height );
        my $tips_seen = 0;
        my $total_tips = $self->calc_number_of_terminals();
        my $tallest = $self->get_root->calc_max_path_to_tips;
        my $maxnodes = $self->get_root->calc_max_nodes_to_tips;
        my $is_clado = $self->get_mode =~ m/^c/i;
        $self->visit_depth_first(
            '-post' => sub {
                my $node = shift;
                my ( $x, $y );
                if ( $node->is_terminal ) {
                    $tips_seen++;
                    $y = ( $height / $total_tips ) * $tips_seen;
                    $x = $is_clado 
                        ? $width 
                        : ($width/$tallest)*$node->calc_path_to_root;
                }
                else {
                    my @children = @{ $node->get_children };
                    $y += $_->get_y for @children;
                    $y /= scalar @children;
                    $x = $is_clado 
                        ? $width - (($width/$maxnodes)*$node->calc_max_nodes_to_tips)
                        : ($width/$tallest)*$node->calc_path_to_root;
                }
                $node->set_y( $y ); 
                $node->set_x( $x );
            }
        );
    }

=begin comment

This method applies settings for nodes globally.

=end comment

=cut

    sub _apply_to_nodes {
        my ( $self, $method, $value ) = @_;
        $self->visit(sub{shift->$method($value)});
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
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:34 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Forest::DrawTree inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Forest::DrawTree also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::Forest::Tree

Bio::Phylo::Forest::DrawTree inherits from superclass L<Bio::Phylo::Forest::Tree>. 
Below are the public methods (if any) from this superclass.

=over

=item calc_branching_times()

Calculates branching times.

 Type    : Calculation
 Title   : calc_branching_times
 Usage   : my $branching_times = 
           $tree->calc_branching_times;
 Function: Returns a two-dimensional array. 
           The first dimension consists of 
           the "records", so that in the 
           second dimension $AoA[$first][0] 
           contains the internal node references, 
           and $AoA[$first][1] the branching 
           time of the internal node. The 
           records are orderered from root to 
           tips by time from the origin.
 Returns : SCALAR[][] or FALSE
 Args    : NONE

=item calc_es() 

Calculates the Equal Splits value for each terminal

 Type    : Calculation
 Title   : calc_es
 Usage   : my $es = $tree->calc_es();
 Function: Returns the Equal Splits value for each terminal
 Returns : HASHREF
 Args    : NONE

=item calc_fiala_stemminess()

Calculates stemminess measure of Fiala and Sokal (1985).

 Type    : Calculation
 Title   : calc_fiala_stemminess
 Usage   : my $fiala_stemminess = 
           $tree->calc_fiala_stemminess;
 Function: Calculates stemminess measure 
           Fiala and Sokal (1985).
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Fiala, K.L. and 
           R.R. Sokal, 1985. Factors 
           determining the accuracy of 
           cladogram estimation: evaluation 
           using computer simulation. 
           Evolution, 39: 609-622

=item calc_fp() 

Calculates the Fair Proportion value for each terminal.

 Type    : Calculation
 Title   : calc_fp
 Usage   : my $fp = $tree->calc_fp();
 Function: Returns the Fair Proportion 
           value for each terminal
 Returns : HASHREF
 Args    : NONE

=item calc_gamma()

Calculates the Pybus gamma statistic.

 Type    : Calculation
 Title   : calc_gamma
 Usage   : my $gamma = $tree->calc_gamma();
 Function: Calculates the Pybus gamma statistic
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Pybus, O.G. and 
           Harvey, P.H., 2000. Testing
           macro-evolutionary models using 
           incomplete molecular phylogenies. 
           Proc. R. Soc. Lond. B 267, 2267-2272

=item calc_i2()

Calculates I2 imbalance.

 Type    : Calculation
 Title   : calc_i2
 Usage   : my $ci2 = $tree->calc_i2;
 Function: Calculates I2 imbalance.
 Returns : FLOAT
 Args    : NONE
 Comments:

=item calc_imbalance()

Calculates Colless' coefficient of tree imbalance.

 Type    : Calculation
 Title   : calc_imbalance
 Usage   : my $imbalance = $tree->calc_imbalance;
 Function: Calculates Colless' coefficient 
           of tree imbalance.
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Colless, D.H., 1982. 
           The theory and practice of phylogenetic 
           systematics. Systematic Zoology 31(1): 100-104

=item calc_ltt()

Calculates lineage-through-time data points.

 Type    : Calculation
 Title   : calc_ltt
 Usage   : my $ltt = $tree->calc_ltt;
 Function: Returns a two-dimensional array. 
           The first dimension consists of the 
           "records", so that in the second 
           dimension $AoA[$first][0] contains 
           the internal node references, and
           $AoA[$first][1] the branching time 
           of the internal node, and $AoA[$first][2] 
           the cumulative number of lineages over
           time. The records are orderered from 
           root to tips by time from the origin.
 Returns : SCALAR[][] or FALSE
 Args    : NONE

=item calc_number_of_internals()

Calculates the number of internal nodes.

 Type    : Calculation
 Title   : calc_number_of_internals
 Usage   : my $number_of_internals = 
           $tree->calc_number_of_internals;
 Function: Calculates the number 
           of internal nodes.
 Returns : INT
 Args    : NONE

=item calc_number_of_nodes()

Calculates the number of nodes.

 Type    : Calculation
 Title   : calc_number_of_nodes
 Usage   : my $number_of_nodes = 
           $tree->calc_number_of_nodes;
 Function: Calculates the number of 
           nodes (internals AND terminals).
 Returns : INT
 Args    : NONE

=item calc_number_of_terminals()

Calculates the number of terminal nodes.

 Type    : Calculation
 Title   : calc_number_of_terminals
 Usage   : my $number_of_terminals = 
           $tree->calc_number_of_terminals;
 Function: Calculates the number 
           of terminal nodes.
 Returns : INT
 Args    : NONE

=item calc_pe()

Calculates the Pendant Edge value for each terminal.

 Type    : Calculation
 Title   : calc_pe
 Usage   : my $es = $tree->calc_pe();
 Function: Returns the Pendant Edge value for each terminal
 Returns : HASHREF
 Args    : NONE

=item calc_redundancy()

Calculates the amount of shared (redundant) history on the total.

 Type    : Calculation
 Title   : calc_redundancy
 Usage   : my $redundancy = 
           $tree->calc_redundancy;
 Function: Calculates the amount of shared 
           (redundant) history on the total.
 Returns : FLOAT
 Args    : NONE
 Comments: Redundancy is calculated as
 1 / ( treelength - height / ( ntax * height - height ) )

=item calc_resolution()

Calculates tree resolution.

 Type    : Calculation
 Title   : calc_resolution
 Usage   : my $resolution = 
           $tree->calc_resolution;
 Function: Calculates the total number 
           of internal nodes over the
           total number of internal nodes 
           on a fully bifurcating
           tree of the same size.
 Returns : FLOAT
 Args    : NONE

=item calc_rohlf_stemminess()

Calculates stemminess measure from Rohlf et al. (1990).

 Type    : Calculation
 Title   : calc_rohlf_stemminess
 Usage   : my $rohlf_stemminess = 
           $tree->calc_rohlf_stemminess;
 Function: Calculates stemminess measure 
           from Rohlf et al. (1990).
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Rohlf, F.J., 
           W.S. Chang, R.R. Sokal, J. Kim, 
           1990. Accuracy of estimated 
           phylogenies: effects of tree 
           topology and evolutionary model. 
           Evolution, 44(6): 1671-1684

=item calc_shapley()

Calculates the Shapley value for each terminal.

 Type    : Calculation
 Title   : calc_shapley
 Usage   : my $es = $tree->calc_shapley();
 Function: Returns the Shapley value for each terminal
 Returns : HASHREF
 Args    : NONE

=item calc_symdiff()

Calculates the symmetric difference metric between invocant and argument.

 Type    : Calculation
 Title   : calc_symdiff
 Usage   : my $symdiff = 
           $tree->calc_symdiff($other_tree);
 Function: Returns the symmetric difference 
           metric between $tree and $other_tree, 
           sensu Penny and Hendy, 1985.
 Returns : SCALAR
 Args    : A Bio::Phylo::Forest::Tree object
 Comments: Trees in comparison must span 
           the same set of terminal taxa
           or results are meaningless.

=item calc_total_paths()

Calculates the sum of all root-to-tip path lengths.

 Type    : Calculation
 Title   : calc_total_paths
 Usage   : my $total_paths = 
           $tree->calc_total_paths;
 Function: Calculates the sum of all 
           root-to-tip path lengths.
 Returns : FLOAT
 Args    : NONE

=item calc_tree_height()

Calculates the height of the tree.

 Type    : Calculation
 Title   : calc_tree_height
 Usage   : my $tree_height = 
           $tree->calc_tree_height;
 Function: Calculates the height 
           of the tree.
 Returns : FLOAT
 Args    : NONE
 Comments: For ultrametric trees this 
           method returns the height, but 
           this is done by averaging over 
           all root-to-tip path lengths, so 
           for additive trees the result 
           should consequently be interpreted
           differently.

=item calc_tree_length()

Calculates the sum of all branch lengths.

 Type    : Calculation
 Title   : calc_tree_length
 Usage   : my $tree_length = 
           $tree->calc_tree_length;
 Function: Calculates the sum of all branch 
           lengths (i.e. the tree length).
 Returns : FLOAT
 Args    : NONE

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

=item exponentiate()

Raises branch lengths to argument.

 Type    : Tree manipulator
 Title   : exponentiate
 Usage   : $tree->exponentiate($power);
 Function: Raises branch lengths to $power.
 Returns : The modified invocant.
 Args    : A $power in any of perl's number formats.

=item get_internals()

Get internal nodes.

 Type    : Query
 Title   : get_internals
 Usage   : my @internals = @{ $tree->get_internals };
 Function: Retrieves all internal nodes 
           in the Bio::Phylo::Forest::Tree object.
 Returns : An array reference of 
           Bio::Phylo::Forest::Node objects.
 Args    : NONE
 Comments: If the tree is valid, this method 
           retrieves the same set of nodes as 
           $node->get_internals($root). However, 
           because there is no recursion it may 
           be faster. Also, the node method by 
           the same name does not see orphans.

=item get_mrca()

Get most recent common ancestor of argument nodes.

 Type    : Query
 Title   : get_mrca
 Usage   : my $mrca = $tree->get_mrca(\@nodes);
 Function: Retrieves the most recent 
           common ancestor of \@nodes
 Returns : Bio::Phylo::Forest::Node
 Args    : A reference to an array of 
           Bio::Phylo::Forest::Node objects 
           in $tree.

=item get_root()

Get root node.

 Type    : Query
 Title   : get_root
 Usage   : my $root = $tree->get_root;
 Function: Retrieves the first orphan in 
           the current Bio::Phylo::Forest::Tree
           object - which should be the root.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=item get_tallest_tip()

Retrieves the node furthest from the root. 

 Type    : Query
 Title   : get_tallest_tip
 Usage   : my $tip = $tree->get_tallest_tip;
 Function: Retrieves the node furthest from the
           root in the current Bio::Phylo::Forest::Tree
           object.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE
 Comments: If the tree has branch lengths, the tallest tip is
           based on root-to-tip path length, else it is based
           on number of nodes to root

=item get_terminals()

Get terminal nodes.

 Type    : Query
 Title   : get_terminals
 Usage   : my @terminals = @{ $tree->get_terminals };
 Function: Retrieves all terminal nodes in
           the Bio::Phylo::Forest::Tree object.
 Returns : An array reference of 
           Bio::Phylo::Forest::Node objects.
 Args    : NONE
 Comments: If the tree is valid, this method 
           retrieves the same set of nodes as 
           $node->get_terminals($root). However, 
           because there is no recursion it may 
           be faster. Also, the node method by 
           the same name does not see orphans.

=item is_binary()

Test if tree is bifurcating.

 Type    : Test
 Title   : is_binary
 Usage   : if ( $tree->is_binary ) {
              # do something
           }
 Function: Tests whether the invocant 
           object is bifurcating.
 Returns : BOOLEAN
 Args    : NONE

=item is_clade()

Tests if argument (node array ref) forms a clade.

 Type    : Test
 Title   : is_clade
 Usage   : if ( $tree->is_clade(\@tips) ) {
              # do something
           }
 Function: Tests whether the set of 
           \@tips forms a clade
 Returns : BOOLEAN
 Args    : A reference to an array of 
           Bio::Phylo::Forest::Node objects.
 Comments:

=item is_cladogram()

Tests if tree is a cladogram (i.e. no branch lengths)

 Type    : Test
 Title   : is_cladogram
 Usage   : if ( $tree->is_cladogram() ) {
              # do something
           }
 Function: Tests whether the tree is a 
           cladogram (i.e. no branch lengths)
 Returns : BOOLEAN
 Args    : NONE
 Comments:

=item is_default()

Test if tree is default tree.

 Type    : Test
 Title   : is_default
 Usage   : if ( $tree->is_default ) {
              # do something
           }
 Function: Tests whether the invocant 
           object is the default tree in the forest.
 Returns : BOOLEAN
 Args    : NONE

=item is_monophyletic()

Tests if first argument (node array ref) is monophyletic with respect
to second argument.

 Type    : Test
 Title   : is_monophyletic
 Usage   : if ( $tree->is_monophyletic(\@tips, $node) ) {
              # do something
           }
 Function: Tests whether the set of \@tips is
           monophyletic w.r.t. $outgroup.
 Returns : BOOLEAN
 Args    : A reference to a list of nodes, and a node.
 Comments: This method is essentially the
           same as 
           &Bio::Phylo::Forest::Node::is_outgroup_of.

=item is_paraphyletic()

 Type    : Test
 Title   : is_paraphyletic
 Usage   : if ( $tree->is_paraphyletic(\@nodes,$node) ){ }
 Function: Tests whether or not a given set of nodes are paraphyletic
           (representing the full clade) given an outgroup
 Returns : [-1,0,1] , -1 if the group is not monophyletic
                       0 if the group is not paraphyletic
                       1 if the group is paraphyletic
 Args    : Array ref of node objects which are in the tree,
           Outgroup to compare the nodes to

=item is_rooted()

Test if tree is rooted.

 Type    : Test
 Title   : is_rooted
 Usage   : if ( $tree->is_rooted ) {
              # do something
           }
 Function: Tests whether the invocant 
           object is rooted.
 Returns : BOOLEAN
 Args    : NONE
 Comments: A tree is considered unrooted if:
           - set_as_unrooted has been set, or
           - the basal split is a polytomy

=item is_ultrametric()

Test if tree is ultrametric.

 Type    : Test
 Title   : is_ultrametric
 Usage   : if ( $tree->is_ultrametric(0.01) ) {
              # do something
           }
 Function: Tests whether the invocant is 
           ultrametric.
 Returns : BOOLEAN
 Args    : Optional margin between pairwise 
           comparisons (default = 0).
 Comments: The test is done by performing 
           all pairwise comparisons for
           root-to-tip path lengths. Since many 
           programs introduce rounding errors 
           in branch lengths the optional argument is
           available to test TRUE for nearly 
           ultrametric trees. For example, a value 
           of 0.01 indicates that no pairwise
           comparison may differ by more than 1%. 
           Note: behaviour is undefined for 
           negative branch lengths.

=item keep_tips()

Keeps argument nodes from invocant (i.e. prunes all others).

 Type    : Tree manipulator
 Title   : keep_tips
 Usage   : $tree->keep_tips(\@taxa);
 Function: Keeps specified taxa from invocant.
 Returns : The pruned Bio::Phylo::Forest::Tree object.
 Args    : An array ref of taxon names or a Bio::Phylo::Taxa object
 Comments:

=item log_transform()

Log argument base transform branch lengths.

 Type    : Tree manipulator
 Title   : log_transform
 Usage   : $tree->log_transform($base);
 Function: Log $base transforms branch lengths.
 Returns : The modified invocant.
 Args    : A $base in any of perl's number formats.

=item negative_to_zero()

Converts negative branch lengths to zero.

 Type    : Tree manipulator
 Title   : negative_to_zero
 Usage   : $tree->negative_to_zero;
 Function: Converts negative branch 
           lengths to zero.
 Returns : The modified invocant.
 Args    : NONE
 Comments:

=item new()

Tree constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $tree = Bio::Phylo::Forest::Tree->new;
 Function: Instantiates a Bio::Phylo::Forest::Tree object.
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : No required arguments.

=item new_from_bioperl()

Tree constructor from Bio::Tree::TreeI argument.

 Type    : Constructor
 Title   : new_from_bioperl
 Usage   : my $tree = 
           Bio::Phylo::Forest::Tree->new_from_bioperl(
               $bptree           
           );
 Function: Instantiates a 
           Bio::Phylo::Forest::Tree object.
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : A tree that implements Bio::Tree::TreeI

=item prune_tips()

Prunes argument nodes from invocant.

 Type    : Tree manipulator
 Title   : prune_tips
 Usage   : $tree->prune_tips(\@taxa);
 Function: Prunes specified taxa from invocant.
 Returns : A pruned Bio::Phylo::Forest::Tree object.
 Args    : A reference to an array of taxon names.
 Comments:

=item remove_unbranched_internals()

Collapses internal nodes with fewer than 2 children.

 Type    : Tree manipulator
 Title   : remove_unbranched_internals
 Usage   : $tree->remove_unbranched_internals;
 Function: Collapses internal nodes 
           with fewer than 2 children.
 Returns : The modified invocant.
 Args    : NONE
 Comments:

=item resolve()

Randomly breaks polytomies.

 Type    : Tree manipulator
 Title   : resolve
 Usage   : $tree->resolve;
 Function: Randomly breaks polytomies by inserting 
           additional internal nodes.
 Returns : The modified invocant.
 Args    :
 Comments:

=item scale()

Scales the tree to the specified height.

 Type    : Tree manipulator
 Title   : scale
 Usage   : $tree->scale($height);
 Function: Scales the tree to the 
           specified height.
 Returns : The modified invocant.
 Args    : $height = a numerical value 
           indicating root-to-tip path length.
 Comments: This method uses the 
           $tree->calc_tree_height method, and 
           so for additive trees the *average* 
           root-to-tip path length is scaled to
           $height (i.e. some nodes might be 
           taller than $height, others shorter).

=item set_as_default()

Sets tree to be the default tree in a forest

 Type    : Mutator
 Title   : set_as_default
 Usage   : $tree->set_as_default;
 Function: Sets tree to be default tree in forest
 Returns : $tree
 Args    : NONE
 Comments: This is a flag to indicate that the invocant
           is the default tree in a forest, i.e. to
           capture the '*' token in nexus files.

=item set_as_unrooted()

Sets tree to be interpreted as unrooted.

 Type    : Mutator
 Title   : set_as_unrooted
 Usage   : $tree->set_as_unrooted;
 Function: Sets tree to be interpreted as unrooted.
 Returns : $tree
 Args    : NONE
 Comments: This is a flag to indicate that the invocant
           is interpreted to be unrooted (regardless of
           topology). The object is otherwise unaltered,
           this method is only here to capture things such
           as the [&U] token in nexus files.

=item set_not_default()

Sets tree to NOT be the default tree in a forest

 Type    : Mutator
 Title   : set_not_default
 Usage   : $tree->set_not_default;
 Function: Sets tree to not be default tree in forest
 Returns : $tree
 Args    : NONE
 Comments: This is a flag to indicate that the invocant
           is the default tree in a forest, i.e. to
           capture the '*' token in nexus files.

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

Serializes invocant to newick string.

 Type    : Stringifier
 Title   : to_newick
 Usage   : my $string = $tree->to_newick;
 Function: Turns the invocant tree object 
           into a newick string
 Returns : SCALAR
 Args    : NONE

=item to_svg()

Serializes invocant to SVG.

 Type    : Serializer
 Title   : to_svg
 Usage   : my $svg = $obj->to_svg;
 Function: Turns the invocant object into an SVG string.
 Returns : SCALAR
 Args    : Same args as the Bio::Phylo::Treedrawer constructor

=item to_xml()

Serializes invocant to xml.

 Type    : Serializer
 Title   : to_xml
 Usage   : my $xml = $obj->to_xml;
 Function: Turns the invocant object into an XML string.
 Returns : SCALAR
 Args    : NONE

=item ultrametricize()

Sets all root-to-tip path lengths equal.

 Type    : Tree manipulator
 Title   : ultrametricize
 Usage   : $tree->ultrametricize;
 Function: Sets all root-to-tip path 
           lengths equal by stretching
           all terminal branches to the 
           height of the tallest node.
 Returns : The modified invocant.
 Args    : NONE
 Comments: This method is analogous to 
           the 'ultrametricize' command
           in Mesquite, i.e. no rate smoothing 
           or anything like that happens, just 
           a lengthening of terminal branches.

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
			
			# is executed whether or not node has sisters, if it does have sisters
			# they're processed first	
			-in             => sub { print "in: ",             shift->get_name, "\n" },			
			
			# is executed if node has a daughter, but before that daughter is processed
			-pre_daughter   => sub { print "pre_daughter: ",   shift->get_name, "\n" },
			
			# is executed if node has a daughter, after daughter has been processed	
			-post_daughter  => sub { print "post_daughter: ",  shift->get_name, "\n" },				
			
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
  Args    : Optional handlers in the order in which they would be executed on an internal node:
			
			# first event handler, is executed when node is reached in recursion
			-pre            => sub { print "pre: ",            shift->get_name, "\n" },

			# is executed if node has a daughter, but before that daughter is processed
			-pre_daughter   => sub { print "pre_daughter: ",   shift->get_name, "\n" },
			
			# is executed if node has a daughter, after daughter has been processed	
			-post_daughter  => sub { print "post_daughter: ",  shift->get_name, "\n" },

			# is executed whether or not node has sisters, if it does have sisters
			# they're processed first	
			-in             => sub { print "in: ",             shift->get_name, "\n" },
			
			# is executed if node has a sister, before sister is processed
			-pre_sister     => sub { print "pre_sister: ",     shift->get_name, "\n" },	
			
			# is executed if node has a sister, after sister is processed
			-post_sister    => sub { print "post_sister: ",    shift->get_name, "\n" },							
			
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

=head2 SUPERCLASS Bio::Phylo::Listable

Bio::Phylo::Forest::DrawTree inherits from superclass L<Bio::Phylo::Listable>. 
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

Bio::Phylo::Forest::DrawTree inherits from superclass L<Bio::Phylo::Util::XMLWritable>. 
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

Bio::Phylo::Forest::DrawTree inherits from superclass L<Bio::Phylo>. 
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

=item L<Bio::Phylo::Forest::Tree>

This object inherits from L<Bio::Phylo::Forest::Tree>, so methods
defined there are also applicable here.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: DrawTree.pm 844 2009-03-05 00:07:26Z rvos $

=cut

}
1;