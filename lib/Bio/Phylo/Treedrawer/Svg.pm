# $Id: Svg.pm 3331 2007-03-20 23:59:42Z rvosa $
# Subversion: $Rev: 192 $
package Bio::Phylo::Treedrawer::Svg;
use strict;
use constant PI => '3.14159265358979323846';
use SVG (
    '-nocredits' => 1,
    '-inline'    => 1,
    '-indent'    => '    ',
);
my @fields = qw(TREE SVG DRAWER);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;
my %colors;

=head1 NAME

Bio::Phylo::Treedrawer::Svg - Creates svg tree drawings. No serviceable parts
inside.

=head1 DESCRIPTION

This module creates a scalable vector graphic from a Bio::Phylo::Trees::Tree
object. It is called by the L<Bio::Phylo::Treedrawer> object, so look there to
learn how to create tree drawings. (For extra per-node formatting, attach a hash 
reference to the node, like so: 
$node->set_generic( 'svg' => { 'stroke' => 'red' } ), which outlines
the node, and branch leading up to it, in red.)


=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $svg = Bio::Phylo::Treedrawer::SVG->_new(%args);
 Function: Initializes a Bio::Phylo::Treedrawer::SVG object.
 Alias   :
 Returns : A Bio::Phylo::Treedrawer::SVG object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = shift;
    my $self = {};
    my %opt;
    eval { %opt = @_; };
    if ($@) {
        Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
    }
    $self->{'TREE'}   = $opt{'-tree'};
    $self->{'DRAWER'} = $opt{'-drawer'};
    return bless $self, $class;
}

=begin comment

 Type    : Internal method.
 Title   : _draw
 Usage   : $svg->_draw;
 Function: Main drawing method.
 Returns :
 Args    : None.

=end comment

=cut

sub _draw {
    my $self = shift;
    $self->{'SVG'} = SVG->new(
        'width'  => $self->{'DRAWER'}->get_width,
        'height' => $self->{'DRAWER'}->get_height
    );
    $self->{'SVG'}->tag( 'style', type => 'text/css' )
      ->CDATA( "\n\tpolyline { fill: none; stroke: black; stroke-width: 2 }\n"
          . "\tpath { fill: none; stroke: black; stroke-width: 2 }\n"
          . "\tline { fill: none; stroke: black; stroke-width: 2 }\n"
          . "\tcircle.node_circle  {}\n"
          . "\tcircle.taxon_circle {}\n"
          . "\ttext.node_text      {}\n"
          . "\ttext.taxon_text     {}\n"
          . "\tline.scale_bar      {}\n"
          . "\ttext.scale_label    {}\n"
          . "\tline.scale_major    {}\n"
          . "\tline.scale_minor    {}\n" );
    foreach my $node ( @{ $self->{'TREE'}->get_entities } ) {
        my $cx = int $node->get_generic('x');
        my $cy = int $node->get_generic('y');
        my $r  = int $self->{'DRAWER'}->get_node_radius;
        my $x  =
          int( $node->get_generic('x') +
              $self->{'DRAWER'}->get_text_horiz_offset );
        my $y =
          int(
            $node->get_generic('y') + $self->{'DRAWER'}->get_text_vert_offset );
        if ( my $style = $node->get_generic('svg') ) {
            $self->{'SVG'}->tag(
                'circle',
                'cx'    => $cx,
                'cy'    => $cy,
                'r'     => $r,
                'style' => $style,
                'class' => $node->is_terminal ? 'taxon_circle' : 'node_circle',
            );
            $self->{'SVG'}->tag(
                'text',
                'x'     => $x,
                'y'     => $y,
                'style' => $style,
                'class' => $node->is_terminal ? 'taxon_text' : 'node_text',
            )->cdata( $node->get_name ? $node->get_name : ' ' );
        }
        else {
            $self->{'SVG'}->tag(
                'circle',
                'cx'    => $cx,
                'cy'    => $cy,
                'r'     => $r,
                'class' => $node->is_terminal ? 'taxon_circle' : 'node_circle',
            );
            $self->{'SVG'}->tag(
                'text',
                'x'     => $x,
                'y'     => $y,
                'class' => $node->is_terminal ? 'taxon_text' : 'node_text',
            )->cdata( $node->get_name ? $node->get_name : ' ' );
        }
        if ( $node->get_parent ) {
            $self->_draw_line($node);
        }
    }
    $self->_draw_pies;
    $self->_draw_scale;
    $self->_draw_legend;
    undef %colors;
    return $self->{'SVG'}->render;
}

=begin comment

 Type    : Internal method.
 Title   : _draw_pies
 Usage   : $svg->_draw_pies();
 Function: Draws likelihood pies
 Returns :
 Args    : None.
 Comments: Code cribbed from SVG::PieGraph

=end comment

=cut

sub _draw_pies {
    my $self = shift;
    foreach my $node ( @{ $self->{'TREE'}->get_entities } ) {
        my $cx = int $node->get_generic('x');
        my $cy = int $node->get_generic('y');
        my $r  = int $self->{'DRAWER'}->get_node_radius;
        my $x  =
          int( $node->get_generic('x') +
              $self->{'DRAWER'}->get_text_horiz_offset );
        my $y =
          int(
            $node->get_generic('y') + $self->{'DRAWER'}->get_text_vert_offset );
        if ( my $pievalues = $node->get_generic('pie') ) {
            my @keys  = keys %{$pievalues};
            my $start = -90;
            my $total;
            foreach my $key (@keys) {
                $total += $pievalues->{$key};
            }
            my $pie = $self->{'SVG'}->tag(
                'g',
                'id'        => 'pie_' . $node->get_id,
                'transform' => "translate($cx,$cy)",
            );
            for ( my $i = 0 ; $i <= $#keys ; $i++ ) {
                next if not $pievalues->{ $keys[$i] };
                my $slice = $pievalues->{ $keys[$i] } / $total * 360;
                my $color = $colors{ $keys[$i] };
                if ( not $color ) {
                    my $gray = int( ( ( $i + 1 ) / scalar @keys ) * 256 );
                    $color = sprintf 'rgb(%d,%d,%d)', $gray, $gray, $gray;
                    $colors{ $keys[$i] } = $color;
                }
                my $do_arc  = 0;
                my $radians = $slice * PI / 180;
                $do_arc++ if $slice > 180;
                my $radius = $r - 2;
                my $ry     = ( $radius * sin($radians) );
                my $rx     = $radius * cos($radians);
                my $g      = $pie->tag( 'g', 'transform' => "rotate($start)" );
                $g->path(
                    'style' => { 'fill' => "$color", 'stroke' => 'none' },
                    'd'     =>
"M $radius,0 A $radius,$radius 0 $do_arc,1 $rx,$ry L 0,0 z"
                );
                $start += $slice;
            }
        }
    }
}

=begin comment

 Type    : Internal method.
 Title   : _draw_scale
 Usage   : $svg->_draw_scale();
 Function: Draws scale for phylograms
 Returns :
 Args    : None

=end comment

=cut

sub _draw_scale {
    my $self    = shift;
    my $drawer  = $self->{'DRAWER'};
    my $svg     = $self->{'SVG'};
    my $tree    = $self->{'TREE'};
    my $root    = $tree->get_root;
    my $rootx   = $root->get_generic('x');
    my $height  = $drawer->get_height;
    my $options = $drawer->get_scale_options;
    if ( $options ) {
        my ( $major, $minor ) = ( $options->{'-major'}, $options->{'-minor'} );
        my $width = $options->{'-width'};
        if ( $width =~ m/^(\d+)%$/ ) {
            $width =
              ( $1 / 100 ) * ( $tree->get_tallest_tip->get_generic('x') -
                  $rootx );
        }
        if ( $major =~ m/^(\d+)%$/ ) {
            $major = ( $1 / 100 ) * $width;
        }
        if ( $minor =~ m/^(\d+)%$/ ) {
            $minor = ( $1 / 100 ) * $width;
        }
        my $major_text  = 0;
        my $major_scale = ( $major / $width ) * $root->calc_max_path_to_tips;
        $svg->line(
            'class' => 'scale_bar',
            'x1'    => $rootx,
            'y1'    => ( $height - 5 ),
            'x2'    => $rootx + $width,
            'y2'    => ( $height - 5 ),
        );
        $svg->tag(
            'text',
            'x'     => ( $rootx + $width + $drawer->get_text_horiz_offset ),
            'y'     => ( $height - 5 ),
            'class' => 'scale_label',
        )->cdata( $options->{'-label'} ? $options->{'-label'} : ' ' );
        for ( my $i = $rootx; $i <= ( $rootx + $width ); $i += $major ) {
            $svg->line(
                'class' => 'scale_major',
                'x1'    => $i,
                'y1'    => ( $height - 5 ),
                'x2'    => $i,
                'y2'    => ( $height - 25 ),
            );
            $svg->tag(
                'text',
                'x'     => $i,
                'y'     => ( $height - 35 ),
                'class' => 'major_label',
            )->cdata( $major_text ? $major_text : ' ' );
            $major_text += $major_scale;
        }
        for ( my $i = $rootx; $i <= ( $rootx + $width ); $i += $minor ) {
            next if not $i % $major;
            $svg->line(
                'class' => 'scale_minor',
                'x1'    => $i,
                'y1'    => ( $height - 5 ),
                'x2'    => $i,
                'y2'    => ( $height - 15 ),
            );
        }
    }
}

=begin comment

 Type    : Internal method.
 Title   : _draw_legend
 Usage   : $svg->_draw_legend();
 Function: Draws likelihood pie legend
 Returns :
 Args    : None

=end comment

=cut

sub _draw_legend {
    my $self = shift;
    if (%colors) {
        my $svg       = $self->{'SVG'};
        my $tree      = $self->{'TREE'};
        my $draw      = $self->{'DRAWER'};
        my @keys      = keys %colors;
        my $increment =
          ( $tree->get_tallest_tip->get_generic('x') -
              $tree->get_root->get_generic('x') ) / scalar @keys;
        my $x = $tree->get_root->get_generic('x') + 5;
        foreach my $key (@keys) {
            $svg->rectangle(
                'x'      => $x,
                'y'      => ( $draw->get_height - 90 ),
                'width'  => ( $increment - 10 ),
                'height' => 10,
                'id'     => 'legend_' . $key,
                'style'  => {
                    'fill'         => $colors{$key},
                    'stroke'       => 'black',
                    'stroke-width' => '2',
                },
            );
            $svg->tag(
                'text',
                'x'     => $x,
                'y'     => ( $draw->get_height - 60 ),
                'class' => 'legend_label',
            )->cdata( $key ? $key : ' ' );
            $x += $increment;
        }
        $svg->tag(
            'text',
            'x' => (
                $tree->get_tallest_tip->get_generic('x') +
                  $draw->get_text_horiz_offset
            ),
            'y'     => ( $draw->get_height - 80 ),
            'class' => 'legend_text',
        )->cdata('Node value legend');
    }
}

=begin comment

 Type    : Internal method.
 Title   : _draw_line
 Usage   : $svg->_draw_line($node);
 Function: Draws internode between $node and $node->get_parent
 Returns :
 Args    : A node that is not the root.

=end comment

=cut

sub _draw_line {
    my ( $self, $node ) = @_;
    my $node_hash  = $node->get_generic;
    my $pnode_hash = $node->get_parent->get_generic;
    my ( $x1, $x2, $style ) =
      ( int $pnode_hash->{'x'}, int $node_hash->{'x'}, $node_hash->{'svg'} );
    my ( $y1, $y2 ) = ( int $pnode_hash->{'y'}, int $node_hash->{'y'} );
    if ( $self->{'DRAWER'}->get_shape eq 'CURVY' ) {
        my $points = qq{M$x1,$y1 C$x1,$y2 $x2,$y2 $x2,$y2};
        if ($style) {
            $self->{'SVG'}->path(
                'd'     => $points,
                'style' => $style,
            );
        }
        else {
            $self->{'SVG'}->path( 'd' => $points, );
        }
    }
    elsif ( $self->{'DRAWER'}->get_shape eq 'RECT' ) {
        my $points = qq{$x1,$y1 $x1,$y2 $x2,$y2};
        if ($style) {
            $self->{'SVG'}->polyline(
                'points' => $points,
                'style'  => $style,
            );
        }
        else {
            $self->{'SVG'}->polyline( 'points' => $points, );
        }
    }
    elsif ( $self->{'DRAWER'}->get_shape eq 'DIAG' ) {
        if ($style) {
            $self->{'SVG'}->line(
                'x1'    => $x1,
                'y1'    => $y1,
                'x2'    => $x2,
                'y2'    => $y2,
                'style' => $style,
            );
        }
        else {
            $self->{'SVG'}->line(
                'x1' => $x1,
                'y1' => $y1,
                'x2' => $x2,
                'y2' => $y2,
            );
        }
    }
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Treedrawer>

The svg treedrawer is called by the L<Bio::Phylo::Treedrawer> object. Look there
to learn how to create tree drawings.

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

$Id: Svg.pm 3331 2007-03-20 23:59:42Z rvosa $

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
