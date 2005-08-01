# $Id: Svg.pm,v 1.4 2005/08/01 23:06:19 rvosa Exp $
# Subversion: $Rev: 147 $
package Bio::Phylo::Unparsers::Svg;
use strict;
use warnings;
use Bio::Phylo::Trees::Tree;
use Bio::Phylo::Trees::Node;
use SVG;
use base 'Bio::Phylo::Unparsers';

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 147 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.02';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);

=head1 NAME

Bio::Phylo::Unparsers::Svg - An object-oriented module for unparsing tree
objects into SVG vector drawings.

=head1 SYNOPSIS

 my $svg = Bio::Phylo::Unparsers::Svg->new(%options);
 my $string = $svg->build_svg();

=head1 DESCRIPTION

This module unparses a Bio::Phylo::Trees::Tree object into a scalable vector
graphic.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $svg = Bio::Phylo::Unparsers::Svg->new(%args);
 Function: Initializes a Bio::Phylo::Unparsers::Svg object.
 Alias   :
 Returns : A Bio::Phylo::Unparsers::Svg object.
 Args    : none.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    $self->{'WIDTH'}             = 800;
    $self->{'HEIGHT'}            = 600;
    $self->{'MODE'}              = 'PHYLO';
    $self->{'SHAPE'}             = 'RECT';
    $self->{'PADDING'}           = 50;
    $self->{'NODE_RADIUS'}       = 4;
    $self->{'TEXT_HORIZ_OFFSET'} = 5;
    $self->{'TEXT_VERT_OFFSET'}  = 5;
    $self->{'TEXT_WIDTH'}        = 100;
    $self->{'PHYLO'}             = undef;
    $self->{'SCALEX'}            = 1;
    $self->{'SCALEY'}            = 1;
    if (@_) {
        my %opts = @_;
        foreach my $key ( keys %opts ) {
            my $localkey = uc($key);
            $localkey =~ s/-//;
            unless ( ref $opts{$key} ) {
                $self->{$localkey} = uc( $opts{$key} );
            }
            else {
                $self->{$localkey} = $opts{$key};
            }
        }
    }
    bless $self, $class;
    return $self;
}

=item width()

 Type    : Accessor / Mutator
 Title   : width()
 Usage   : $svg->width(1000);
 Function: gets/sets the width of the svg canvas.
 Returns :
 Args    : SCALAR width in pixels.

=cut

sub width {
    my $self = shift;
    $self->{'WIDTH'} = $_[0] if $_[0];
    return $self->{'WIDTH'};
}

=item height()

 Type    : Accessor / Mutator
 Title   : height()
 Usage   : $svg->height(1000);
 Function: gets/sets the height of the svg canvas.
 Returns :
 Args    : SCALAR height in pixels.

=cut

sub height {
    my $self = shift;
    $self->{'HEIGHT'} = $_[0] if $_[0];
    return $self->{'HEIGHT'};
}

=item mode()

 Type    : Accessor / Mutator
 Title   : mode()
 Usage   : $svg->mode($mode);
 Function: gets/sets the tree mode, i.e. cladogram or phylogram.
 Returns :
 Args    : SCALAR string, [clado|phylo]

=cut

sub mode {
    my $self = shift;
    $self->{'MODE'} = uc( $_[0] ) if $_[0];
    return $self->{'MODE'};
}

=item shape()

 Type    : Accessor / Mutator
 Title   : shape()
 Usage   : $svg->shape($shape);
 Function: gets/sets the tree shape, i.e. rectangular, diagonal or curvy.
 Returns :
 Args    : SCALAR string, [rect|diag|curvy]

=cut

sub shape {
    my $self = shift;
    $self->{'SHAPE'} = uc( $_[0] ) if $_[0];
    return $self->{'SHAPE'};
}

=item padding()

 Type    : Accessor / Mutator
 Title   : padding()
 Usage   : $svg->padding($padding);
 Function: gets/sets the canvas padding.
 Returns :
 Args    : SCALAR value in pixels.

=cut

sub padding {
    my $self = shift;
    $self->{'PADDING'} = $_[0] if $_[0];
    return $self->{'PADDING'};
}

=item node_radius()

 Type    : Accessor / Mutator
 Title   : node_radius()
 Usage   : $svg->node_radius($node_radius);
 Function: gets/sets the node radius in pixels.
 Returns :
 Args    : SCALAR value in pixels.

=cut

sub node_radius {
    my $self = shift;
    $self->{'NODE_RADIUS'} = $_[0] if $_[0];
    return $self->{'NODE_RADIUS'};
}

=item text_horiz_offset()

 Type    : Accessor / Mutator
 Title   : text_horiz_offset()
 Usage   : $svg->text_horiz_offset($text_horiz_offset);
 Function: gets/sets the distance between tips and text, in pixels.
 Returns :
 Args    : SCALAR value in pixels.

=cut

sub text_horiz_offset {
    my $self = shift;
    $self->{'TEXT_HORIZ_OFFSET'} = $_[0] if $_[0];
    return $self->{'TEXT_HORIZ_OFFSET'};
}

=item text_vert_offset()

 Type    : Accessor / Mutator
 Title   : text_vert_offset()
 Usage   : $svg->text_vert_offset($text_vert_offset);
 Function: gets/sets the text baseline relative to the tips, in pixels.
 Returns :
 Args    : SCALAR value in pixels.

=cut

sub text_vert_offset {
    my $self = shift;
    $self->{'TEXT_VERT_OFFSET'} = $_[0] if $_[0];
    return $self->{'TEXT_VERT_OFFSET'};
}

=item text_width()

 Type    : Accessor / Mutator
 Title   : text_width()
 Usage   : $svg->text_width($text_width);
 Function: gets/sets the canvas width for terminal taxon names.
 Returns :
 Args    : SCALAR value in pixels.

=cut

sub text_width {
    my $self = shift;
    $self->{'TEXT_WIDTH'} = $_[0] if $_[0];
    return $self->{'TEXT_WIDTH'};
}

=item tree()

 Type    : Accessor / Mutator
 Title   : tree()
 Usage   : $svg->tree($tree);
 Function: gets/sets the Bio::Phylo::Trees::Tree object to unparse.
 Returns :
 Args    : A Bio::Phylo::Trees::Tree object.

=cut

sub tree {
    my $self = shift;
    $self->{'PHYLO'} = $_[0] if $_[0];
    return $self->{'PHYLO'};
}

=item _scalex()

 Type    : Internal method.
 Title   : _scalex()
 Usage   : $svg->_scalex($scalex);
 Function:
 Returns :
 Args    :

=cut

sub _scalex {
    my $self = shift;
    $self->{'SCALEX'} = $_[0] if $_[0];
    return $self->{'SCALEX'};
}

=item _scaley()

 Type    : Internal method.
 Title   : _scaley()
 Usage   : $svg->_scaley($scaley);
 Function:
 Returns :
 Args    :

=cut

sub _scaley {
    my $self = shift;
    $self->{'SCALEY'} = $_[0] if $_[0];
    return $self->{'SCALEY'};
}

=item to_string()

 Type    : Unparsers
 Title   : to_string()
 Usage   : $svg->to_string(%options);
 Function: Unparses a Bio::Phylo::Trees::Tree object into an SVG vector drawing.
 Returns : SCALAR
 Args    :

=cut

sub to_string {
    my $self = shift;
    if (@_) {
        my %opts = @_;
        foreach my $key ( keys %opts ) {
            my $localkey = uc($key);
            $localkey =~ s/-//;
            unless ( ref $opts{$key} ) {
                $self->{$localkey} = uc( $opts{$key} );
            }
            else {
                $self->{$localkey} = $opts{$key};
            }
        }
    }
    my $tree    = $self->tree;
    my $root    = $tree->get_root;
    my $maxpath =
        $self->mode eq 'CLADO'
      ? $root->calc_max_nodes_to_tips
      : $root->calc_max_path_to_tips;
    my $scalex =
      ( $self->width - ( ( 2 * $self->padding ) + $self->text_width ) ) /
      $maxpath;
    $self->_scalex($scalex);
    my $tips = $tree->calc_number_of_terminals;
    my $scaley = ( $self->height - ( 2 * $self->padding ) ) / ( $tips + 1 );
    $self->_scaley($scaley);

    if ( $self->mode eq 'CLADO' ) {
        $self->_x_positions_clado;
    }
    else {
        $self->_x_positions;
    }
    $self->_y_terminals($root);
    $self->_y_internals;
    $self->_classes;
    my $string = $self->_to_string;
    foreach ( @{ $tree->get_entities } ) {
        undef %{$_};
    }
    undef @{$tree};
    return $string;
}

=item _x_positions()

 Type    : Internal method.
 Title   : _x_positions()
 Usage   : $svg->_x_positions();
 Function:
 Returns :
 Args    :

=cut

sub _x_positions {
    my $self    = shift;
    my $tree    = $self->tree;
    my $root    = $tree->get_root;
    my $scalex  = $self->_scalex;
    my $padding = $self->padding;
    foreach my $e ( @{ $tree->get_entities } ) {
        my $x = ( $e->calc_path_to_root * $scalex ) + $padding;
        $e->set_generic( x => $x );
    }
}

=item _x_positions_clado()

 Type    : Internal method.
 Title   : _x_positions_clado()
 Usage   : $svg->_x_positions_clado();
 Function:
 Returns :
 Args    :

=cut

sub _x_positions_clado {
    my $self    = shift;
    my $tree    = $self->tree;
    my $root    = $tree->get_root;
    my $longest = $root->calc_max_nodes_to_tips;
    my $scalex  = $self->_scalex;
    foreach my $e ( @{ $tree->get_terminals } ) {
        $e->set_generic( x => ( ( $longest - 1 ) * $scalex ) );
    }
    foreach my $e ( @{ $tree->get_internals } ) {
        my $longest1 = 0;
        foreach my $f ( @{ $tree->get_entities } ) {
            my ( $q, $current1 ) = ( $f, 0 );
            if ( !$q->get_first_daughter && $q->get_parent ) {
                while ($q) {
                    $current1++;
                    $q = $q->get_parent;
                    if (   $q
                        && $q == $e
                        && $current1 > $longest1 )
                    {
                        $longest1 = $current1;
                    }
                }
            }
        }
        my $xc = $longest - $longest1 - 1;
        $e->set_generic( x => ( $xc * $self->_scalex ) );
    }
}

=item _y_terminals()

 Type    : Internal method.
 Title   : _y_terminals()
 Usage   : $svg->_y_terminals();
 Function:
 Returns :
 Args    :

=cut

BEGIN {
    my $tips = 0.00000000000001;

    sub _y_terminals {
        my $self = shift;
        my $node = $_[0];
        if ( !$node->get_first_daughter ) {
            $tips++;
            $node->set_generic(
                y => ( ( $tips * $self->_scaley ) + $self->padding ) );
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

=item _y_internals()

 Type    : Internal method.
 Title   : _y_internals()
 Usage   : $svg->_y_internals();
 Function:
 Returns :
 Args    :

=cut

sub _y_internals {
    my $self = shift;
    my $tree = $self->tree;
    while ( !$tree->get_root->get_generic('y') ) {
        foreach my $e ( @{ $tree->get_internals } ) {
            my $y1 = $e->get_first_daughter->get_generic('y');
            my $y2 = $e->get_last_daughter->get_generic('y');
            if ( $y1 && $y2 ) {
                my $y = ( $y1 + $y2 ) / 2;
                $e->set_generic( y => $y );
            }
        }
    }
}

=item _classes()

 Type    : Internal method.
 Title   : _classes()
 Usage   : $svg->_classes();
 Function:
 Returns :
 Args    :

=cut

sub _classes {
    my $self = shift;
    my $tree = $self->tree;
    foreach my $node ( @{ $tree->get_entities } ) {
        my @classes;
        push( @classes, $node->get_name );
        my $anc = $node->get_ancestors;
        if ($anc) {
            foreach ( @{$anc} ) {
                push( @classes, $_->get_name );
            }
        }
        push( @classes, 'int' )  if $node->is_internal;
        push( @classes, 'term' ) if $node->is_terminal;
        $node->set_generic( classes => \@classes );
    }
}

=item _to_string()

 Type    : Internal method.
 Title   : _to_string()
 Usage   : $svg->_to_string();
 Function:
 Returns :
 Args    :

=cut

sub _to_string {
    my $self = shift;
    my ( $tree, $mode, $shape ) = ( $self->tree, $self->mode, $self->shape );
    my $svg = SVG->new(
        width   => $self->width,
        height  => $self->height,
        -indent => '    '
    );
    $svg->tag( 'style', type => 'text/css' )->CDATA( $self->_css );
    foreach my $e ( @{ $tree->get_entities } ) {
        my $name = $e->get_name;
        $name =~ s/_/ /g;
        my $x2      = $e->get_generic('x');
        my $y2      = $e->get_generic('y');
        my $classes = "@{$e->get_generic('classes')}";
        $svg->text(
            id     => ( $e->get_name . $shape . 'T' . $mode ),
            class  => $classes,
            x      => ( $x2 + $self->text_horiz_offset ),
            y      => ( $y2 + $self->text_vert_offset ),
            -cdata => $name
        );
        if ( $e->get_parent ) {
            my $x1 = $e->get_parent->get_generic('x');
            my $y1 = $e->get_parent->get_generic('y');
            if ( $shape eq 'RECT' ) {
                my $id     = $e->get_name . $shape . 'Po' . $mode;
                my $points = qq{$x1,$y1 $x1,$y2 $x2,$y2};
                $svg->polyline(
                    points => $points,
                    id     => $id,
                    class  => $classes
                );
            }
            elsif ( $shape eq 'CURVY' ) {
                my $id     = $e->get_name . $shape . 'Pa' . $mode;
                my $points = qq{M$x1,$y1 C$x1,$y2 $x2,$y2 $x2,$y2};
                $svg->path(
                    d     => $points,
                    id    => $id,
                    class => $classes
                );
            }
            elsif ( $shape eq 'DIAG' ) {
                $svg->line(
                    id    => ( $e->get_name . $shape . 'L' . $mode ),
                    class => $classes,
                    x1    => $x1,
                    y1    => $y1,
                    x2    => $x2,
                    y2    => $y2
                );
            }
        }
        $svg->circle(
            id    => ( $e->get_name . $shape . 'C' . $mode ),
            class => $classes,
            cx    => $x2,
            cy    => $y2,
            r     => $self->node_radius
        );
    }
    $svg = $self->_timeline($svg);
    $svg->xmlify;
}

=item _css()

 Type    : Internal method.
 Title   : _css()
 Usage   : $svg->_css();
 Function:
 Returns :
 Args    :

=cut

sub _css {
    my $self = shift;
    my ( $tree, $shape ) = ( $self->tree, $self->shape );
    my $css = qq{\n\n/* global CSS selectors */\n.int, .term { }\n};
    $css .= qq{text.term { font: italic 15px serif }\n};
    $css .= qq{text.int { font: normal 12px sans-serif }\n};
    if ( $shape eq 'RECT' ) {
        $css .= qq{polyline { fill: none; stroke: black; stroke-width: 2 }\n};
    }
    elsif ( $shape eq 'CURVY' ) {
        $css .= qq{path { fill: none; stroke: black; stroke-width: 2 }\n};
    }
    elsif ( $shape eq 'DIAG' ) {
        $css .= qq{line { fill: none; stroke: black; stroke-width: 2 }\n};
    }
    if ( $self->mode eq 'PHYLO' ) {
        $css .= qq{line.scale { fill: none; stroke: black; stroke-width: 2 }\n};
        $css .= qq{text.scale { font: normal 12px sans-serif }\n};
    }
    $css .= qq{circle { fill: white; stroke: black; stroke-width: 2 }\n\n};
    my $mode = ucfirst( $self->mode );
    foreach my $e ( @{ $tree->get_entities } ) {
        my $name = $e->get_name;
        $css .= qq{/* } . $name . qq{ */\n};
        $css .= qq{.} . $name . qq{ {  }\n};
        $css .= qq{text.} . $name . qq{ { }\n};
        if ( $shape eq 'CURVY' ) {
            $css .= qq{path.} . $name . qq{ { }\n};
            $css .= qq{text#} . $name . qq{CURVYT} . $mode . qq{ { }\n};
            $css .= qq{path#} . $name . qq{CURVYPa} . $mode . qq{ { }\n};
            $css .= qq{circle#} . $name . qq{CURVYC} . $mode . qq{ { }\n};
        }
        elsif ( $shape eq 'RECT' ) {
            $css .= qq{polyline.} . $name . qq{ { }\n};
            $css .= qq{text#} . $name . qq{RECTT} . $mode . qq{ { }\n};
            $css .= qq{polyline#} . $name . qq{RECTPo} . $mode . qq{ { }\n};
            $css .= qq{circle#} . $name . qq{RECTC} . $mode . qq{ { }\n};
        }
        elsif ( $shape eq 'DIAG' ) {
            $css .= qq{line.} . $name . qq{ { }\n};
            $css .= qq{text#} . $name . qq{DIAGT} . $mode . qq{ { }\n};
            $css .= qq{line#} . $name . qq{DIAGL} . $mode . qq{ { }\n};
            $css .= qq{circle#} . $name . qq{DIAGC} . $mode . qq{ { }\n};
        }
        $css .= qq{circle.} . $name . qq{ { }\n\n};
    }
    return $css;
}

=item _timeline()

 Type    : Internal method.
 Title   : _timeline()
 Usage   : $svg->_timeline();
 Function:
 Returns :
 Args    :

=cut

sub _timeline {
    my ( $self, $svg ) = @_;
    if ( $self->mode eq 'PHYLO' ) {
        my $y  = ( $self->height - $self->padding + 35 );
        my $x1 = $self->padding;
        my $x2 = ( $self->width - ( $self->padding + $self->text_width ) );
        my $scalewidth = $x2 - $x1;
        my $treewidth  = $self->tree->get_root->calc_max_path_to_tips;
        my $unit       = $scalewidth / $treewidth;
        $svg->line(
            class => 'scale',
            x1    => $x1,
            y1    => $y,
            x2    => $x2,
            y2    => $y
        );
        my $i       = $x2;
        my $counter = 0;
        $svg->text(
            class  => 'scale',
            x      => ( $i + 10 ),
            y      => ( $y + 10 ),
            -cdata => 'MYA'
        );

        while ( $i > $x1 ) {
            if ( ( $counter % 5 ) == 0 ) {
                $svg->line(
                    class => 'scale',
                    x1    => $i,
                    y1    => $y,
                    x2    => $i,
                    y2    => ( $y + 15 )
                );
                $svg->text(
                    class  => 'scale',
                    x      => ( $i - 3 ),
                    y      => ( $y + 30 ),
                    -cdata => $counter
                );
            }
            else {
                $svg->line(
                    class => 'scale',
                    x1    => $i,
                    y1    => $y,
                    x2    => $i,
                    y2    => ( $y + 10 )
                );
            }
            $i -= $unit;
            $counter++;
        }
    }
    return $svg;
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed
from BioPerl L<http://www.bioperl.org>, and CIPRES
L<http://www.phylo.org> and FAB* L<http://www.sfu.ca/~fabstar> for
comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
