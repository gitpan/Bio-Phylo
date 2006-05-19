# $Id: Nexus.pm,v 1.24 2006/05/19 02:08:58 rvosa Exp $
# Subversion: $Rev: 195 $
package Bio::Phylo::Parsers::Nexus;
use strict;
use Bio::Phylo::Taxa::Taxon;
use Bio::Phylo::Taxa;
use Bio::Phylo::Matrices::Matrix;
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Matrices;
use Bio::Phylo::Parsers::Newick;
use base 'Bio::Phylo::IO';

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Parsers::Nexus - Parses nexus files. No serviceable parts inside.

=head1 DESCRIPTION

This module parses nexus files. It is called by the L<Bio::Phylo::IO> module,
there is no direct usage. The parser can only handle files with a single tree,
taxon, and characters block. It returns a reference to an array containing one
or more taxa, trees and matrices objects.

=begin comment

 Type    : Constructor
 Title   : new
 Usage   : my $newick = new Bio::Phylo::Parsers::Nexus;
 Function: Initializes a Bio::Phylo::Parsers::Nexus object.
 Returns : A Bio::Phylo::Parsers::Nexus object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = $_[0];
    my $self  = {};
    bless( $self, $class );
    return $self;
}

=begin comment

 Type    : Wrapper
 Title   : from_handle(\*FH)
 Usage   : $nexus->from_handle(\*FH);
 Function: Does all the parser magic, from a file handle
 Returns : L<Phylo>
 Args    : \*FH = file handle

=end comment

=cut

sub _from_handle {
    my $self = shift;
    my %opts = @_;
    my @output;
    my ( $t, $parsed, $comm, $data, $taxa, $char, $translate, $trees ) =
      $self->_parse_handle( $opts{-handle} );
    if ( @{$taxa} ) {
        my $taxa_obj = $self->_parse_taxa( $taxa, $parsed );
        return unless $taxa_obj;
        push( @output, $taxa_obj );
        my $matrix_obj = $self->_parse_char( $char, $taxa, $parsed ) if $char;
        return unless $matrix_obj;
        push( @output, $matrix_obj );
        my $trees_obj = $self->_parse_trees( $trees, $translate ) if $trees;
        return unless $trees_obj;
        push( @output, $trees_obj );
    }
    my $comm_obj = $self->_parse_comm($comm) if $comm;
    return unless $comm_obj;
    push( @output, $comm_obj );
    return \@output;
}

=begin comment

This method needs to be able to handle multiple tree blocks and multiple
characters blocks. Also, where matches are performed on patterns that are
potentially multiple words (e.g. NTAX = 10 instead of NTAX=10) it is assumed
that all words are on the same line. This is not a requirement of the nexus
specification, but it seemed easier. This needs to be changed.

 Type    : Parsers
 Title   : parse_handle(\*FH)
 Usage   : $nexus->parse_handle(\*FH);
 Function: Creates (file) handle, dispatches parser functions.
 Returns : Local arrays.
 Args    : \*FH is a reference to a file handle

=end comment

=cut

sub _parse_handle {
    my $self   = shift;
    my $handle = $_[0];
    my ( %t, %parsed, @comm, @data, @taxa, @char, @translate, @trees );
    while ( readline($handle) ) {
        my $line = $_;
        foreach ( split( /\s+/, $_ ) ) {
            $t{comm}++ if m/\[\s*[^%]/o;
            if ( !$t{comm} ) {
                $t{nexus} = 1 if m/#nexus/oi;
                $t{begin} = 1 if m/begin/oi;
                if ( m/data\s*;/oi && $t{begin} ) {
                    ( $t{data}, $t{begin} ) = ( $t{begin}, $t{data} );
                }
                if ( m/taxa\s*;/oi && $t{begin} ) {
                    ( $t{taxa}, $t{begin} ) = ( $t{begin}, $t{taxa} );
                }
                if ( m/characters\s*;/oi && $t{begin} ) {
                    ( $t{char}, $t{begin} ) = ( $t{begin}, $t{char} );
                }
                if ( m/trees\s*;/oi && $t{begin} ) {
                    ( $t{trees}, $t{begin} ) = ( $t{begin}, $t{trees} );
                }
                $t{taxlabels} = 1 if m/taxlabels/oi && $t{taxa};
                $t{translate} = 1 if m/translate/oi && $t{trees};
                $t{matrix}    = 1 if m/matrix/oi    && ( $t{data} || $t{char} );
                if ( $line =~ /ntax\s*=\s*(\d+)\b/oi
                    && ( $t{taxa} || $t{data} ) )
                {
                    $parsed{ntax} = $1;
                }    # fix this
                if ( $line =~ /nchar\s*=\s*(\d+)\b/oi
                    && ( $t{char} || $t{data} ) )
                {
                    $parsed{nchar} = $1;
                }    #
                if ( $line =~ /datatype\s*=\s*(\w+)\b/oi
                    && ( $t{char} || $t{data} ) )
                {
                    $parsed{datatype} = $1;
                }    #
                if (m/(end|endblock)\s*;/oi) {
                    $t{data}  = 0 if $t{data};
                    $t{taxa}  = 0 if $t{taxa};
                    $t{char}  = 0 if $t{char};
                    $t{trees} = 0 if $t{trees};
                }
                if ( $t{translate} ) {
                    my $token = $_;
                    $token =~ s/[;|,]//;
                    push( @translate, $token )
                      if $token && $token !~ /translate/oi;
                }
                if ( $t{taxlabels} ) {
                    my $token = $_;
                    $token =~ s/[;|,]//;
                    push( @taxa, $token ) if $token && $token !~ /taxlabels/oi;
                }
                if ( $t{matrix} ) {
                    my $token = $_;
                    $token =~ s/[;|,]//;
                    push( @char, $_ ) if $token && $token !~ /matrix/oi;
                }
                if ( $t{trees} && !$t{translate} ) {
                    push( @trees, $_ ) unless m/trees/oi;
                }
                $t{taxlabels} = 0 if m/;/o && $t{taxlabels};
                $t{translate} = 0 if m/;/o && $t{translate};
                $t{matrix}    = 0 if m/;/o && $t{matrix};
            }
            else { push( @comm, $_ ); }
            $t{comm}-- if m/\]/o && $t{comm};
        }
    }
    return ( \%t, \%parsed, \@comm, \@data, \@taxa, \@char, \@translate,
        \@trees );
}

=begin comment

 Type    : Parsers
 Title   : _parse_taxa(\@taxa)
 Usage   : $nexus->_parse_taxa(\@taxa);
 Function: Creates Bio::Phylo::Taxa object from array of taxon names.
 Returns : A Bio::Phylo::Taxa object
 Args    : A reference to an array holding taxon names.

=end comment

=cut

sub _parse_taxa {
    my $self = shift;
    my ( $taxlist, $parsed ) = @_;
    my $taxa = new Bio::Phylo::Taxa;
    if ( $parsed->{ntax} != scalar @{$taxlist} ) {
        my ( $exp, $obs ) = ( $parsed->{ntax}, scalar @{$taxlist} );
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => "observed ($obs) and expected ($exp) ntax unequal" );
    }
    foreach ( @{$taxlist} ) {
        my $taxon = new Bio::Phylo::Taxa::Taxon;
        $taxon->set_name($_);
        $taxa->insert($taxon);
    }
    return $taxa;
}

=begin comment

 Type    : Parsers
 Title   : _parse_char(\@chars)
 Usage   : $nexus->_parse_char(\@chars);
 Function: Creates Bio::Phylo::Matrices::Matrix object from a character state
           matrix.
 Returns : A Bio::Phylo::Matrices::Matrix object
 Args    : A reference to an array holding a character state matrix.

=end comment

=cut

sub _parse_char {
    my $self = shift;
    my ( $charlist, $taxa, $parsed ) = @_;
    my $matrix = new Bio::Phylo::Matrices::Matrix;
    my $datatype;
    if ( $parsed->{datatype} ) { $datatype = uc( $parsed->{datatype} ); }
    else { $datatype = 'STANDARD'; }
    my ( $charstring, $name );
    for my $i ( 0 .. $#{$charlist} ) {
        my $pattern = $charlist->[$i];
        $pattern =~ s/\?/\\?/go;
        if ( grep( /^$pattern$/, @{$taxa} ) ) {
            if ($name) {
                my ( $obs, $exp ) = ( length($charstring), $parsed->{nchar} );
                if ( $obs != $exp ) {
                    Bio::Phylo::Util::Exceptions::BadFormat->throw( error =>
"observed ($obs) and expected ($exp) nchar unequal for $name"
                    );
                }

                #                for my $j ( 0 .. length($charstring) ) {
                my $datum = Bio::Phylo::Matrices::Datum->new(
                    '-name' => $name,
                    '-pos'  => 1,
                    '-type' => $datatype,
                    '-char' => $charstring,
                );

          #                    $datum->set_name($name);
          #                    $datum->set_position( $j + 1 );
          #                    $datum->set_type($datatype);
          #                    $datum->set_char( substr( $charstring, $j, 1 ) );
                $matrix->insert($datum);

                #                }
            }
            $charstring = undef;
            $name       = $charlist->[$i];
        }
        else {
            if ($charstring) { $charstring .= $charlist->[$i]; }
            else { $charstring = $charlist->[$i]; }
        }
    }
    my $matrices = new Bio::Phylo::Matrices;
    $matrices->insert($matrix);
    return $matrices;
}

=begin comment

 Type    : Parsers
 Title   : _parse_trees(\@trees)
 Usage   : $nexus->_parse_trees(\@trees);
 Function: Creates Bio::Phylo::Forest object from an array of trees.
 Returns : A Bio::Phylo::Forest object
 Args    : A reference to an array holding newick trees.

=end comment

=cut

sub _parse_trees {
    my $self = shift;
    my ( $tlist, $translate ) = ( $_[0], $_[1] );
    my ( $nstring, @translist ) = ("");
    if ($translate) {
        for my $i ( 0 .. $#{$translate} ) {
            push( @translist, $translate->[$i] ) if ( $i % 2 );
        }
    }
    my $tliststring = '';
    $tliststring .= $_ foreach ( @{$tlist} );
    $tliststring =~ s/\[.*?\]//g;
    foreach ( split( /;/, $tliststring ) ) {
        next unless /\(.*\)/i;
        s/^.*\=\s*(.*)$/$1/;
        $nstring .= $_ . ";";
    }
    my $nparser = Bio::Phylo::Parsers::Newick->_new;
    my $trees   =
      $nparser->_from_string( -format => 'newick', -string => $nstring );
    if (@translist) {
        foreach my $tree ( @{ $trees->get_entities } ) {
          NODE: foreach my $node ( @{ $tree->get_entities } ) {
                for my $i ( 0 .. $#translist ) {
                    if ( $node->is_terminal && $node->get_name == ( $i + 1 ) ) {
                        $node->set_name( $translist[$i] );
                        next NODE;
                    }
                }
            }
        }
    }
    return $trees;
}

=begin comment

 Type    : _parse_comm
 Title   : _parse_comm()
 Usage   : $nexus->_parse_comm();
 Function: Parses nexus comments
 Returns : Nothing yet.
 Args    : none.

=end comment

=cut

sub _parse_comm {
    my ( $self, $comm ) = @_;
    return join( ' ', @{$comm} );
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The nexus parser is called by the L<Bio::Phylo::IO> object. Look there for
examples of file parsing and manipulation.

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

$Id: Nexus.pm,v 1.24 2006/05/19 02:08:58 rvosa Exp $

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
