#!/usr/bin/perl
# $Id: dnd2svg.pl 3387 2007-03-25 16:06:50Z rvosa $
# Subversion: $Rev: 145 $
# This script draws the newick tree description in the input file as a
# scalable vector drawing.
#
# usage:
# perl dnd2svg.pl <tree file>

use lib '/Users/rvosa/src/bioperl/bioperl-live';
use lib '/Users/rvosa/CIPRES-and-deps/cipres-1.0.1/build/lib/perl/lib';
use lib '/Users/rvosa/CIPRES-and-deps/cipres-1.0.1/framework/perl/phylo/lib';

use strict;
use warnings;
use CGI 'Vars';
use Pod::Usage;
use Pod::Text;
use Getopt::Long;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Treedrawer;
use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;

# we will collect all possible tree drawer arguments and pass them to
# the Bio::Phylo::Treedrawer->new constructor
my $args = {
    '-file'               => undef,
    '-mode'               => undef,
    '-shape'              => undef,
    '-width'              => undef,
    '-height'             => undef,
    '-string'             => undef,
    '-padding'            => undef,
    '-text_width'         => undef,
    '-node_radius'        => undef,
    '-text_vert_offset'   => undef,
    '-text_horiz_offset'  => undef,
    '-scale_width'        => undef,
    '-scale_major'        => undef,
    '-scale_minor'        => undef,
    '-scale_label'        => undef,
};

# first collect all available arguments from the command line (i.e. @ARGV)
GetOptions(
    'file=s'              => \$args->{ '-file'              },
    'mode=s'              => \$args->{ '-mode'              },
    'shape=s'             => \$args->{ '-shape'             },
    'width=i'             => \$args->{ '-width'             },
    'string=s'            => \$args->{ '-string'            },
    'height=i'            => \$args->{ '-height'            },
    'padding=i'           => \$args->{ '-padding'           },
    'text_width=i'        => \$args->{ '-text_width'        },
    'node_radius=i'       => \$args->{ '-node_radius'       },
    'text_vert_offset=i'  => \$args->{ '-text_vert_offset'  },
    'text_horiz_offset=i' => \$args->{ '-text_horiz_offset' },
    'scale_width=s'       => \$args->{ '-scale_width'       },
    'scale_major=s'       => \$args->{ '-scale_major'       },
    'scale_minor=s'       => \$args->{ '-scale_minor'       },
    'scale_label=s'       => \$args->{ '-scale_label'       },
    'help'                => sub { pod2usage },
);

# then overwrite in the event we're running through CGI (i.e. from $ENV{'QUERY_STRING'});
my $cgi = CGI->new;
if ( defined $cgi->param( 'help' ) ) {
    print 'Content-type: text/plain', "\n\n";
    pod2text( $0 );
    exit 0;
}
for my $key ( keys %{ $args } ) {
    my $newkey = $key;
    $newkey =~ s/^-//;
    my $val = $cgi->param( $newkey );
    if ( defined $val ) {
        $args->{$key} = $val;
    }
    if ( not defined $args->{$key} ) {
        delete $args->{$key};
    }
}

# we'll get the tree string either from file or from string
if ( defined $args->{'-file'} ) {
    $args->{'-tree'} = parse(
        '-format' => 'newick',
        '-file'   => $args->{'-file'},
    )->first;
}
elsif ( defined $args->{'-string'} ) {
    $args->{'-string'} .= ';' if $args->{'-string'} !~ qr/;$/;
    $args->{'-tree'} = parse(
        '-format' => 'newick',
        '-string' => $args->{'-string'},
    )->first;    
}
if ( not $args->{'-tree'} ) {
    die "you didn't provide a (correct) tree source!\n Args:", Dumper( $args, $cgi->param );
}
else {
    delete $args->{'-string'};
    delete $args->{'-file'}; 
}

# collect and transform the scale_options, we need to have them all, or none
$args->{'-scale_options'} = {};
SCALE_OPTIONS_KEY: for my $key ( grep { /^-scale_/ } keys %{ $args } ) {
    if ( $key =~ qr/=.$/ ) {
        delete $args->{$key};
        next SCALE_OPTIONS_KEY;
    }
    if ( my $val = $args->{$key} ) {
        my $newkey = $key;
        $newkey =~ s/^-scale_//;
        $args->{'-scale_options'}->{ '-' . $newkey } = $val;
        delete $args->{$key};
    }
}
if (
            $args->{'-scale_options'}->{'-major'}
        xor $args->{'-scale_options'}->{'-minor'}
        xor $args->{'-scale_options'}->{'-width'}
        xor $args->{'-scale_options'}->{'-label'}
    ) {
    die
        "Need none or all arguments (width, major, minor, label) for scale bar"
}

# apparently none were provided, so no scale
if ( not scalar keys %{ $args->{'-scale_options'} } ) {
    delete $args->{'-scale_options'};
}

# attempt to draw
eval {
    print
        'Content-Type: image/svg+xml',
        "\n\n",
        Bio::Phylo::Treedrawer->new( %$args )->draw  
};
if ( $@ ) {
    if ( UNIVERSAL::isa( $@, 'Bio::Phylo::Util::Exceptions' ) ) {
        die ref $@, "\n\n", $@->message, "\n\n", $@->trace->as_string;
    }
    else {
        die $@;
    }
}

__END__

=head1 NAME

dnd2svg.pl - draws newick trees as svg drawings.

=head1 SYNOPSIS

=over 4

=item B<perl dnd2svg.pl> [C<<options>>]

=back

=head1 OPTIONS

=head2 TREE INPUT OPTIONS

The treedrawer needs at least one of the following: a tree file from which
it reads the first newick tree to draw, or a newick string.

=over 8

=item B<-file> F<<tree file>>

=item B<-string> C<<newick string>>

=back

=head2 TREE MODE AND SHAPE

The tree drawer has two drawing modes: C<clado>, which draws a cladogram, and
C<phylo> for phylograms. If the tree does not specify branch lengths, C<clado>
is silently chosen.

=over 8

=item B<-mode> C<<clado|phylo>>

=item B<-shape> C<<curvy|rect|diag>>

=back

=head2 IMAGE DIMENSIONS

Image width and height apply to the entire SVG canvas, padding specifies the
minimal distance of drawn elements from the edge of the canvas.

=over 8

=item B<-width> C<<image width in pixels>>

=item B<-height> C<<image height in pixels>>

=item B<-padding> C<<image padding in pixels>>

=back

=head2 TAXON NAME OPTIONS

Text width specifies the space allocated for text between the tallest tip of
the tree and the right edge of the canvas. Vertical and horizontal offset
specify the distance of the left corner of the taxon name (the "baseline") from
the node.

=over 8

=item B<-text_width> C<<taxon name text width>>

=item B<-text_vert_offset> C<<taxon name vertical offset>>

=item B<-text_horiz_offset>  C<<taxon name horizontal offset>>

=back

=head2 SCALE BAR OPTIONS

A scale bar can be used to show, for example, time in MYA from the root
to the tip. You can either omit these options entirely (in which case no
bar will be drawn) or you have to specify them all. The bar width can be
specified as an integer, meaning pixels, or as a percentage, meaning the
width relative to the longest root-to-tip path length. Likewise, major and
minor ticks can be specified in pixels or percentages. The label argument
is used to specify a string, e.g. "MYA", to be displayed next to the scale bar.

=over 8

=item B<-scale_width> C<<scale bar width>>

=item B<-scale_minor> C<<scale minor ticks>>

=item B<-scale_major> C<<scale major ticks>>

=item B<-scale_label> C<<scale bar label>>

=back

=head2 MISCELLANEOUS OPTIONS

=over 8

=item B<-node_radius> C<<node radius in pixels>>

=item B<-help>

=back

=head1 DESCRIPTION

dnd2svg.pl is a program that draws newick trees (from file or string) as svg
vector drawings. It can be used from the command line or as a CGI program. The
OPTIONS section describes the options and arguments that can
be provided on the command line, the html snippet below gives an example of how
the script can be called through CGI and how the command line arguments map
onto input element names.

Note that the html example below is fairly crude, some options could be better
presented as menus with a limited number of choices (but are left as an exercise
for the reader).

Additionally, this help document can be accessed through CGI by passing the
script a help=1 argument, e.g. L<http://localhost/cgi-bin/dnd2svg.pl?help=1>

    <!-- html snippet starts here -->
    <html>
    <head>
        <title>dnd2svg CGI form example</title>
        <style type="text/css">
        div { text-align:right }
        form { width:45%; display:inline; float:left }
        iframe { width:45%; display:inline; float:right; height:500px }
        </style>
    </head>
    <body>
        <form action="http://localhost/cgi-bin/dnd2svg.pl" method="get" target="view">
            <div>
                <label for="string">Newick string</label>
                <input type="text" name="string" id="string" value="((a:1,b:1):1,c:1):0;" />
            </div>
            <div>
                <label for="mode">Drawing mode</label>
                <input type="text" name="mode" id="mode" value="phylo" />
            </div>
            <div>
                <label for="shape">Tree shape</label>
                <input type="text" name="shape" id="shape" value="curvy" />
            </div>
            <div>
                <label for="width">Image width</label>
                <input type="text" name="width" id="width" value="400" />
            </div>
            <div>
                <label for="height">Image height</label>
                <input type="text" name="height" id="height" value="300" />
            </div>
            <div>
                <label for="padding">Padding</label>
                <input type="text" name="padding" id="padding" value="10" />
            </div>
            <div>
                <label for="text_width">Text width</label>
                <input type="text" name="text_width" id="text_width" value="100" />
            </div>
            <div>
                <label for="node_radius">Node radius</label>
                <input type="text" name="node_radius" id="node_radius" value="5" />
            </div>
            <div>
                <label for="text_vert_offset">Text vertical offset</label>
                <input type="text" name="text_vert_offset" id="text_vert_offset" value="5" />
            </div>
            <div>
                <label for="text_horiz_offset">Text horizontal offset</label>
                <input type="text" name="text_horiz_offset" id="text_horiz_offset" value="10" />
            </div>
            <div>
                <label for="scale_width">Scale width</label>
                <input type="text" name="scale_width" id="scale_width" value="100%" />
            </div>
            <div>
                <label for="scale_major">Scale major</label>
                <input type="text" name="scale_major" id="scale_major" value="40%" />
            </div>
            <div>
                <label for="scale_minor">Scale minor</label>
                <input type="text" name="scale_minor" id="scale_minor" value="4%" />
            </div>
            <div>
                <label for="scale_label">Scale label</label>
                <input type="text" name="scale_label" id="scale_label" value="MYA" />
            </div>
            <div><input type="submit" name="Submit" value="Submit" /></div>
        </form>
        <iframe name="view"></iframe>
    </body>
    </html>
    <!-- html snippet ends here -->

=head1 SEE ALSO

Rutger Vos: L<http://search.cpan.org/~rvosa>

=head1 WARNINGS AND ERRORS

dnd2svg.pl uses L<CGI::Carp> to mark up fatal messages in HTML and send them
back to the browser. This is useful for CGI debugging.

=cut
