# $Id: Treedrawer.pm 3387 2007-03-25 16:06:50Z rvosa $
# Subversion: $Rev: 192 $
package Bio::Phylo::Treedrawer;
use strict;
use Bio::Phylo::Forest::Tree;
use Bio::Phylo::Forest::Node;
use Bio::Phylo::Util::CONSTANT qw(_TREE_ looks_like_number);
my @fields = qw(WIDTH HEIGHT MODE SHAPE PADDING NODE_RADIUS TEXT_HORIZ_OFFSET TEXT_VERT_OFFSET TEXT_WIDTH TREE _SCALEX _SCALEY SCALE FORMAT);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Treedrawer - An object-oriented facade for drawing trees.

=head1 SYNOPSIS

 use Bio::Phylo::IO 'parse';
 use Bio::Phylo::Treedrawer;

 my $string = '((A:1,B:2)n1:3,C:4)n2:0;';
 my $tree = parse( -format => 'newick', -string => $string )->first;

 my $treedrawer = Bio::Phylo::Treedrawer->new(
    -width  => 800,
    -height => 600,
    -shape  => 'CURVY', # curvogram
    -mode   => 'PHYLO', # cladogram
    -format => 'SVG'
 );

 $treedrawer->set_scale_options(
    -width => '100%',
    -major => '10%', # major cross hatch interval
    -minor => '2%',  # minor cross hatch interval
    -label => 'MYA',
 );

 $treedrawer->set_tree($tree);
 print $treedrawer->draw;

=head1 DESCRIPTION

This module prepares a tree object for drawing (calculating coordinates for
nodes) and calls the appropriate format-specific drawer.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $treedrawer = Bio::Phylo::Treedrawer->new(
               %args 
           );
 Function: Initializes a Bio::Phylo::Treedrawer object.
 Alias   :
 Returns : A Bio::Phylo::Treedrawer object.
 Args    : none.

=cut

sub new {
    my $class = shift;
    my $self = {
        'WIDTH'             => 500,
        'HEIGHT'            => 500,
        'MODE'              => 'PHYLO',
        'SHAPE'             => 'CURVY',
        'PADDING'           => 50,
        'NODE_RADIUS'       => 1,
        'TEXT_HORIZ_OFFSET' => 6,
        'TEXT_VERT_OFFSET'  => 4,
        'TEXT_WIDTH'        => 150,
        'TREE'              => undef,
        '_SCALEX'           => 1,
        '_SCALEY'           => 1,
        'FORMAT'            => 'Svg',
        'SCALE'             => undef,
    };
    bless $self, $class;
    
    if (@_) {
        my %opts = @_;
        for my $key ( keys %opts ) {
            my $mutator = lc $key;
            $mutator =~ s/^-/set_/;
            $self->$mutator( $opts{$key} );
        }
    }
    return $self;
}

=back

=head2 MUTATORS

=over

=item set_format()

 Type    : Mutator
 Title   : set_format
 Usage   : $treedrawer->set_format('Svg');
 Function: Sets the drawer submodule.
 Returns :
 Args    : Name of an image format (currently 
           only Svg supported)

=cut

sub set_format {
    my ( $self, $format ) = @_;
    $format = ucfirst( lc( $format ) );
    my $class = __PACKAGE__ . '::' . $format;
    eval "require $class";
    if ( not $@ ) {
        $self->{'FORMAT'} = $format;
        return $self;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            'error' => "'$format' is not a valid image format"
        );
    }    
}

=item set_width()

 Type    : Mutator
 Title   : set_width
 Usage   : $treedrawer->set_width(1000);
 Function: sets the width of the drawer canvas.
 Returns :
 Args    : Integer width in pixels.

=cut

sub set_width {
    my ( $self, $width ) = @_;
    if ( looks_like_number $width && $width > 0 ) {
        $self->{'WIDTH'} = $width;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadNumber->throw(
            'error' => "'$width' is not a valid image width"
        );
    }
    return $self;
}

=item set_height()

 Type    : Mutator
 Title   : set_height
 Usage   : $treedrawer->set_height(1000);
 Function: sets the height of the canvas.
 Returns :
 Args    : Integer height in pixels.

=cut

sub set_height {
    my ( $self, $height ) = @_;
    if ( looks_like_number $height && $height > 0 ) {
        $self->{'HEIGHT'} = $height;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadNumber->throw(
            'error' => "'$height' is not a valid image height"
        );
    }
    return $self;
}

=item set_mode()

 Type    : Mutator
 Title   : set_mode
 Usage   : $treedrawer->set_mode('clado');
 Function: Sets the tree mode, i.e. cladogram 
           or phylogram.
 Returns : Invocant.
 Args    : String, [clado|phylo]

=cut

sub set_mode {
    my ( $self, $mode ) = @_;
    if ( $mode =~ m/^(?:clado|phylo)$/i ) {
        $self->{'MODE'} = uc $mode;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            'error' => "'$mode' is not a valid drawing mode"
        );
    }
    return $self;
}

=item set_shape()

 Type    : Mutator
 Title   : set_shape
 Usage   : $treedrawer->set_shape('rect');
 Function: Sets the tree shape, i.e. 
           rectangular, diagonal or curvy.
 Returns : Invocant.
 Args    : String, [rect|diag|curvy]

=cut

sub set_shape {
    my ( $self, $shape ) = @_;
    if ( $shape =~ m/^(?:rect|diag|curvy)$/i ) {
        $self->{'SHAPE'} = uc $shape;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            'error' => "'$shape' is not a valid drawing shape"
        );
    }
    return $self;
}

=item set_padding()

 Type    : Mutator
 Title   : set_padding
 Usage   : $treedrawer->set_padding(100);
 Function: Sets the canvas padding.
 Returns :
 Args    : Integer value in pixels.

=cut

sub set_padding {
    my ( $self, $padding ) = @_;
    if ( looks_like_number $padding && $padding > 0 ) {
        $self->{'PADDING'} = $padding;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadNumber->throw(
            'error' => "'$padding' is not a valid padding value"
        );
    }
    return $self;
}

=item set_node_radius()

 Type    : Mutator
 Title   : set_node_radius
 Usage   : $treedrawer->set_node_radius(20);
 Function: Sets the node radius in pixels.
 Returns :
 Args    : Integer value in pixels.

=cut

sub set_node_radius {
    my ( $self, $radius ) = @_;
    if ( looks_like_number $radius && $radius >= 0 ) {
        $self->{'NODE_RADIUS'} = $radius;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadNumber->throw(
            'error' => "'$radius' is not a valid node radius value"
        );
    }
    return $self;
}

=item set_text_horiz_offset()

 Type    : Mutator
 Title   : set_text_horiz_offset
 Usage   : $treedrawer->set_text_horiz_offset(5);
 Function: Sets the distance between 
           tips and text, in pixels.
 Returns :
 Args    : Integer value in pixels.

=cut

sub set_text_horiz_offset {
    my ( $self, $offset ) = @_;
    if ( looks_like_number $offset ) {
        $self->{'TEXT_HORIZ_OFFSET'} = $offset;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadNumber->throw(
            'error' => "'$offset' is not a valid text horizontal offset value"
        );
    }
    return $self;
}

=item set_text_vert_offset()

 Type    : Mutator
 Title   : set_text_vert_offset
 Usage   : $treedrawer->set_text_vert_offset(3);
 Function: Sets the text baseline 
           relative to the tips, in pixels.
 Returns :
 Args    : Integer value in pixels.

=cut

sub set_text_vert_offset {
    my ( $self, $offset ) = @_;
    if ( looks_like_number $offset ) {
        $self->{'TEXT_VERT_OFFSET'} = $offset;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadNumber->throw(
            'error' => "'$offset' is not a valid text vertical offset value"
        );
    }
    return $self;
}

=item set_text_width()

 Type    : Mutator
 Title   : set_text_width
 Usage   : $treedrawer->set_text_width(150);
 Function: Sets the canvas width for 
           terminal taxon names.
 Returns :
 Args    : Integer value in pixels.

=cut

sub set_text_width {
    my ( $self, $width ) = @_;
    if ( looks_like_number $width && $width > 0 ) {
        $self->{'TEXT_WIDTH'} = $width;
    }
    else {
        Bio::Phylo::Util::Exceptions::BadNumber->throw(
            'error' => "'$width' is not a valid text width value"
        );
    }
    return $self;
}

=item set_tree()

 Type    : Mutator
 Title   : set_tree
 Usage   : $treedrawer->set_tree($tree);
 Function: Sets the Bio::Phylo::Forest::Tree 
           object to unparse.
 Returns :
 Args    : A Bio::Phylo::Forest::Tree object.

=cut

sub set_tree {
    my ( $self, $tree ) = @_;
    my $type;
    eval { $type = $tree->_type };
    if ( ! $@ && $type == _TREE_ ) {
        $self->{'TREE'} = $tree->negative_to_zero;
    }
    else {
        Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
            'error' => "'$tree' is not a valid tree"
        );
    }
    return $self;
}

=item set_scale_options()

 Type    : Mutator
 Title   : set_scale_options
 Usage   : $treedrawer->set_scale_options(
                -width => 400,
                -major => '10%', # major cross hatch interval
                -minor => '2%',  # minor cross hatch interval
                -label => 'MYA',
            );
 Function: Sets the options for time (distance) scale
 Returns :
 Args    : -width => (if a number, like 100, pixel 
                      width is assumed, if a percentage, 
                      scale width relative to longest root
                      to tip path)
           -major => ( ditto, value for major tick marks )
           -minor => ( ditto, value for minor tick marks )
           -label => ( text string displayed next to scale )

=cut

sub set_scale_options {
    my $self = shift;
    if ( ( @_ && !scalar @_ % 2 ) || ( scalar @_ == 1 && ref $_[0] eq 'HASH' ) ) {
        my %o; # %options
        if ( scalar @_ == 1 && ref $_[0] eq 'HASH' ) {
            %o = %{ $_[0] };
        }
        else {
            %o = @_;
        }
        if ( looks_like_number $o{'-width'} or $o{'-width'} =~ m/^\d+%$/ ) {
            $self->{'SCALE'}->{'-width'} = $o{'-width'};
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                error => "\"$o{'-width'}\" is invalid for '-width'" );
        }
        if ( looks_like_number $o{'-major'} or $o{'-major'} =~ m/^\d+%$/ ) {
            $self->{'SCALE'}->{'-major'} = $o{'-major'};
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                error => "\"$o{'-major'}\" is invalid for '-major'" );
        }
        if ( looks_like_number $o{'-minor'} or $o{'-minor'} =~ m/^\d+%$/ ) {
            $self->{'SCALE'}->{'-minor'} = $o{'-minor'};
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                error => "\"$o{'-minor'}\" is invalid for '-minor'" );
        }
        $self->{'SCALE'}->{'-label'} = $o{'-label'};
    }
    else {
        Bio::Phylo::Util::Exceptions::OddHash->throw(
            error => 'Odd number of elements in hash assignment' );
    }
    return $self;
}

=back

=head2 ACCESSORS

=over

=item get_format()

 Type    : Mutator
 Title   : get_format
 Usage   : my $format = $treedrawer->get_format;
 Function: Gets the image format.
 Returns :
 Args    : None.

=cut

sub get_format { shift->{'FORMAT'} }

=item get_width()

 Type    : Mutator
 Title   : get_width
 Usage   : my $width = $treedrawer->get_width;
 Function: Gets the width of the drawer canvas.
 Returns :
 Args    : None.

=cut

sub get_width { shift->{'WIDTH'} }

=item get_height()

 Type    : Accessor
 Title   : get_height
 Usage   : my $height = $treedrawer->get_height;
 Function: Gets the height of the canvas.
 Returns :
 Args    : None.

=cut

sub get_height { shift->{'HEIGHT'} }

=item get_mode()

 Type    : Accessor
 Title   : get_mode
 Usage   : my $mode = $treedrawer->get_mode('clado');
 Function: Gets the tree mode, i.e. cladogram or phylogram.
 Returns :
 Args    : None.

=cut

sub get_mode { shift->{'MODE'} }

=item get_shape()

 Type    : Accessor
 Title   : get_shape
 Usage   : my $shape = $treedrawer->get_shape;
 Function: Gets the tree shape, i.e. rectangular, 
           diagonal or curvy.
 Returns :
 Args    : None.

=cut

sub get_shape { shift->{'SHAPE'} }

=item get_padding()

 Type    : Accessor
 Title   : get_padding
 Usage   : my $padding = $treedrawer->get_padding;
 Function: Gets the canvas padding.
 Returns :
 Args    : None.

=cut

sub get_padding { shift->{'PADDING'} }

=item get_node_radius()

 Type    : Accessor
 Title   : get_node_radius
 Usage   : my $node_radius = $treedrawer->get_node_radius;
 Function: Gets the node radius in pixels.
 Returns : SCALAR
 Args    : None.

=cut

sub get_node_radius { shift->{'NODE_RADIUS'} }

=item get_text_horiz_offset()

 Type    : Accessor
 Title   : get_text_horiz_offset
 Usage   : my $text_horiz_offset = 
           $treedrawer->get_text_horiz_offset;
 Function: Gets the distance between 
           tips and text, in pixels.
 Returns : SCALAR
 Args    : None.

=cut

sub get_text_horiz_offset { shift->{'TEXT_HORIZ_OFFSET'} }

=item get_text_vert_offset()

 Type    : Accessor
 Title   : get_text_vert_offset
 Usage   : my $text_vert_offset = 
           $treedrawer->get_text_vert_offset;
 Function: Gets the text baseline relative 
           to the tips, in pixels.
 Returns :
 Args    : None.

=cut

sub get_text_vert_offset { shift->{'TEXT_VERT_OFFSET'} }

=item get_text_width()

 Type    : Accessor
 Title   : get_text_width
 Usage   : my $textwidth = 
           $treedrawer->get_text_width;
 Function: Returns the canvas width 
           for terminal taxon names.
 Returns :
 Args    : None.

=cut

sub get_text_width { shift->{'TEXT_WIDTH'} }

=item get_tree()

 Type    : Accessor
 Title   : get_tree
 Usage   : my $tree = $treedrawer->get_tree;
 Function: Returns the Bio::Phylo::Forest::Tree 
           object to unparse.
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : None.

=cut

sub get_tree { shift->{'TREE'} }

=item get_scale_options()

 Type    : Accessor
 Title   : get_scale_options
 Usage   : my %options = %{ 
               $treedrawer->get_scale_options  
           };
 Function: Returns the time/distance 
           scale options.
 Returns : A hash ref.
 Args    : None.

=cut

sub get_scale_options { shift->{'SCALE'} }

=begin comment

 Type    : Internal method.
 Title   : _set_scalex
 Usage   : $treedrawer->_set_scalex($scalex);
 Function:
 Returns :
 Args    :

=end comment

=cut

sub _set_scalex {
    my $self = shift;
    if ( looks_like_number $_[0] ) {
        $self->{'_SCALEX'} = $_[0];
    }
    else {
        Bio::Phylo::Util::Exceptions::BadNumber->throw(
            error => "\"$_[0]\" is not a valid number value" );
    }
    return $self;
}

sub _get_scalex { shift->{'_SCALEX'} }

=begin comment

 Type    : Internal method.
 Title   : _set_scaley
 Usage   : $treedrawer->_set_scaley($scaley);
 Function:
 Returns :
 Args    :

=end comment

=cut

sub _set_scaley {
    my $self = shift;
    if ( looks_like_number $_[0] ) {
        $self->{'_SCALEY'} = $_[0];
    }
    else {
        Bio::Phylo::Util::Exceptions::BadNumber->throw(
            error => "\"$_[0]\" is not a valid integer value" );
    }
    return $self;
}

sub _get_scaley { shift->{'_SCALEY'} }

=back

=head2 TREE DRAWING

=over

=item draw()

 Type    : Unparsers
 Title   : draw
 Usage   : my $drawing = $treedrawer->draw;
 Function: Unparses a Bio::Phylo::Forest::Tree 
           object into a drawing.
 Returns : SCALAR
 Args    :

=cut

sub draw {
    my $self = shift;
    if ( !$self->get_tree ) {
        Bio::Phylo::Util::Exceptions::BadArgs->throw(
            error => "Can't draw an undefined tree" );
    }
    my $root = $self->get_tree->get_root;
    my $tips = $self->get_tree->calc_number_of_terminals;
    my ( $width,   $height )    = ( $self->get_width,   $self->get_height );
    my ( $padding, $textwidth ) = ( $self->get_padding, $self->get_text_width );
    my $maxpath;
    if ( $self->get_mode eq 'CLADO' ) {
        $maxpath = $root->calc_max_nodes_to_tips;
    }
    elsif ( $self->get_mode eq 'PHYLO' ) {
        $maxpath = $root->calc_max_path_to_tips;
        if ( not $maxpath ) {
            $self->get_tree->warn("no branch lengths on tree, switching to clado mode");
            $self->set_mode('CLADO');
            $maxpath = $root->calc_max_nodes_to_tips;
        }
    }
    $self->_set_scalex(
        ( ( $width - ( ( 2 * $padding ) + $textwidth ) ) / $maxpath ) );
    $self->_set_scaley( ( ( $height - ( 2 * $padding ) ) / ( $tips + 1 ) ) );
    if ( $self->get_mode eq 'CLADO' ) {
        $self->_x_positions_clado;
    }
    else {
        $self->_x_positions;
    }
    $self->_y_terminals($root);
    $self->_y_internals;
    my $library = __PACKAGE__ . '::' . ucfirst( lc( $self->get_format ) );
    eval "require $library";
    if ($@) {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => "Can't load image drawer: $@" );
    }
    my $drawer = $library->_new(
        -tree   => $self->get_tree,
        -drawer => $self
    );
    $drawer->_draw;
}

=begin comment

 Type    : Internal method.
 Title   : _x_positions
 Usage   : $treedrawer->_x_positions;
 Function:
 Returns :
 Args    :

=end comment

=cut

sub _x_positions {
    my $self    = shift;
    my $tree    = $self->get_tree;
    my $root    = $tree->get_root;
    my $scalex  = $self->_get_scalex;
    my $padding = $self->get_padding;
    foreach my $node ( @{ $tree->get_entities } ) {
        my $x = ( $node->calc_path_to_root * $scalex ) + $padding;
        $node->set_generic( x => $x );
    }
}

=begin comment

 Type    : Internal method.
 Title   : _x_positions_clado
 Usage   : $treedrawer->_x_positions_clado;
 Function:
 Returns :
 Args    :

=end comment

=cut

sub _x_positions_clado {
    my $self    = shift;
    my $tree    = $self->get_tree;
    my $root    = $tree->get_root;
    my $longest = $root->calc_max_nodes_to_tips;
    my $scalex  = $self->_get_scalex;
    my $padding = $self->get_padding;
    for my $tip ( @{ $tree->get_terminals } ) {
        $tip->set_generic( 'x' => ( ( $longest ) * $scalex ) );
    }
    for my $internal ( @{ $tree->get_internals } ) {
        my $id = $internal->get_id;
        my $longest1 = 0;
        for my $node ( @{ $tree->get_entities } ) {
            my ( $n, $current1 ) = ( $node, 0 );
            if ( $n->is_terminal && $n->get_parent ) {
                while ( $n->get_parent ) {
                    $current1++;
                    $n = $n->get_parent;
                    if ( $n->get_id == $id && $current1 > $longest1 ) {
                        $longest1 = $current1;
                    }
                }
            }
        }
        my $xc = $longest - $longest1;
        $internal->set_generic( 'x' => ( ( $xc * $scalex ) + $padding ) );
    }
}

=begin comment

 Type    : Internal method.
 Title   : _y_terminals
 Usage   : $treedrawer->_y_terminals;
 Function:
 Returns :
 Args    : tree root

=end comment

=cut

{
    my $tips = 0.000_000_000_000_01;

    sub _y_terminals {
        my $self = shift;
        my $node = $_[0];
        if ( !$node->get_first_daughter ) {
            $tips++;
            $node->set_generic(
                y => ( ( $tips * $self->_get_scaley ) + $self->get_padding ) );
        }
        else {
            $node = $node->get_first_daughter;
            $self->_y_terminals($node);
            while ( $node->get_next_sister ) {
                $node = $node->get_next_sister;
                $self->_y_terminals($node);
            }
        }
    }
}

=begin comment

 Type    : Internal method.
 Title   : _y_internals
 Usage   : $treedrawer->_y_internals;
 Function:
 Returns :
 Args    :

=end comment

=cut

sub _y_internals {
    my $self = shift;
    my $tree = $self->get_tree;
    while ( !$tree->get_root->get_generic('y') ) {
        foreach my $e ( @{ $tree->get_internals } ) {
            my $y1 = $e->get_first_daughter->get_generic('y');
            my $y2 = $e->get_last_daughter->get_generic('y');
            if ( $y1 && $y2 ) {
                my $y = ( $y1 + $y2 ) / 2;
                $e->set_generic( 'y' => $y );
            }
        }
    }
}

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

The L<Bio::Phylo::Treedrawer> object inherits from the L<Bio::Phylo> object.
Look there for more methods applicable to the treedrawer object.

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

$Id: Treedrawer.pm 3387 2007-03-25 16:06:50Z rvosa $

=head1 AUTHOR

Rutger Vos,

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

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
