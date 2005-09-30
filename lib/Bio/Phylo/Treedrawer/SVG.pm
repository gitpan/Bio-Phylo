# $Id: Svg.pm,v 1.4 2005/09/29 20:31:18 rvosa Exp $
# Subversion: $Rev: 192 $
package Bio::Phylo::Treedrawer::SVG;
use strict;
use warnings;
use SVG;
use fields qw(TREE SVG DRAWER);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Treedrawer::SVG - Creates svg tree drawings. No serviceable parts
inside.

=head1 DESCRIPTION

This module creates a scalable vector graphic from a Bio::Phylo::Trees::Tree
object. It is called by the L<Bio::Phylo::Treedrawer> object, so look there to
learn how to create tree drawings.

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
    my Bio::Phylo::Treedrawer::SVG $self = shift;
    my %opt;
    eval { %opt = @_; };
    if ( $@ ) {
        Bio::Phylo::Exceptions::OddHash->throw(
            error => $@
        );
    }
    unless (ref $self) {
        $self = fields::new($self);
    }
    $self->{'TREE'}   = $opt{'-tree'};
    $self->{'DRAWER'} = $opt{'-drawer'};
    return $self;
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
        width  => $self->{'DRAWER'}->get_width,
        height => $self->{'DRAWER'}->get_height
    );
    $self->{'SVG'}->tag( 'style', type => 'text/css' )->CDATA(
        "\n\tpolyline { fill: none; stroke: black; stroke-width: 2 }\n" .
        "\tpath { fill: none; stroke: black; stroke-width: 2 }\n" .
        "\tline { fill: none; stroke: black; stroke-width: 2 }\n"
    );
    foreach my $node ( @{ $self->{'TREE'}->get_entities } ) {
        $self->{'SVG'}->tag('circle',
            'cx' => int $node->get_generic('x'),
            'cy' => int $node->get_generic('y'),
            'r'  => int $self->{'DRAWER'}->get_node_radius
        );
        $self->{'SVG'}->tag('text',
            'x'  => int ( $node->get_generic('x') + $self->{'DRAWER'}->get_text_horiz_offset ),
            'y'  => int ( $node->get_generic('y') + $self->{'DRAWER'}->get_text_vert_offset )
        )->cdata( $node->get_name );
        if ( $node->get_parent ) {
            $self->_draw_line($node);
        }
    }
    return $self->{'SVG'}->render;
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
    my $node_hash = $node->get_generic;
    my $pnode_hash = $node->get_parent->get_generic;
    my ( $x1, $x2 ) = ( int $pnode_hash->{'x'}, int $node_hash->{'x'} );
    my ( $y1, $y2 ) = ( int $pnode_hash->{'y'}, int $node_hash->{'y'} );
    if ( $self->{'DRAWER'}->get_shape eq 'CURVY' ) {
        my $points = qq{M$x1,$y1 C$x1,$y2 $x2,$y2 $x2,$y2};
        $self->{'SVG'}->path( d => $points );
    }
    elsif ( $self->{'DRAWER'}->get_shape eq 'RECT' ) {
        my $points = qq{$x1,$y1 $x1,$y2 $x2,$y2};
        $self->{'SVG'}->polyline( points => $points );
    }
    elsif ( $self->{'DRAWER'}->get_shape eq 'DIAG' ) {
        $self->{'SVG'}->line( 'x1' => $x1, 'y1' => $y1, 'x2' => $x2, 'y2' => $y2 );
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

$Id: Svg.pm,v 1.4 2005/09/29 20:31:18 rvosa Exp $

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
