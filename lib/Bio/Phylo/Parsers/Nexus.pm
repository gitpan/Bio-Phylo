# $Id: Nexus.pm,v 1.6 2005/08/09 12:36:13 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Parsers::Nexus;
use strict;
use warnings;
use Carp;
use Bio::Phylo::Taxa::Taxon;
use Bio::Phylo::Taxa;
use Bio::Phylo::Matrices::Matrix;
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Matrices;
use Bio::Phylo::Parsers::Newick;
use base 'Bio::Phylo::Parsers';

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 148 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.03';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);

=head1 NAME

Bio::Phylo::Parsers::Nexus - A library for parsing Nexus files

=head1 SYNOPSIS

 my $nexus = new Bio::Phylo::Parsers::Nexus;
 $nexus->parse(-file => 'data.nex', -format => 'nexus');

=head1 DESCRIPTION

This module parses nexus files. The parser can only handle files with a single
tree, taxon, and characters block.

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $newick = new Bio::Phylo::Parsers::Nexus;
 Function: Initializes a Bio::Phylo::Parsers::Nexus object.
 Returns : A Bio::Phylo::Parsers::Nexus object.
 Args    : none.

=cut

sub new {
    my $class = $_[0];
    my $self  = {};
    bless( $self, $class );
    return $self;
}

=back

=head2 PARSER

=over

=item from_handle(\*FH)

 Type    : Wrapper
 Title   : from_handle(\*FH)
 Usage   : $nexus->from_handle(\*FH);
 Function: Does all the parser magic, from a file handle
 Returns : L<Phylo>
 Args    : \*FH = file handle

=cut

sub from_handle {
    my $self = shift;
    my %opts = @_;
    my @output;
    my ( $t, $parsed, $comm, $data, $taxa, $char, $translate, $trees ) =
      $self->parse_handle( $opts{-handle} );
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

=item parse_handle(%options)

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

=cut

sub parse_handle {
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

=item _parse_taxa(\@taxa)

 Type    : Parsers
 Title   : _parse_taxa(\@taxa)
 Usage   : $nexus->_parse_taxa(\@taxa);
 Function: Creates Bio::Phylo::Taxa object from array of taxon names.
 Returns : A Bio::Phylo::Taxa object
 Args    : A reference to an array holding taxon names.

=cut

sub _parse_taxa {
    my $self = shift;
    my ( $taxlist, $parsed ) = @_;
    my $taxa = new Bio::Phylo::Taxa;
    if ( $parsed->{ntax} != scalar @{$taxlist} ) {
        my ( $exp, $obs ) = ( $parsed->{ntax}, scalar @{$taxlist} );
        $taxa->COMPLAIN("observed ($obs) and expected ($exp) ntax unequal: $@");
        return;
    }
    foreach ( @{$taxlist} ) {
        my $taxon = new Bio::Phylo::Taxa::Taxon;
        $taxon->set_name($_);
        $taxa->insert($taxon);
    }
    return $taxa;
}

=item _parse_char(\@chars)

 Type    : Parsers
 Title   : _parse_char(\@chars)
 Usage   : $nexus->_parse_char(\@chars);
 Function: Creates Bio::Phylo::Matrices::Matrix object from a character state
           matrix.
 Returns : A Bio::Phylo::Matrices::Matrix object
 Args    : A reference to an array holding a character state matrix.

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
                    $matrix->COMPLAIN(
"observed ($obs) and expected ($exp) nchar unequal for $name: $@"
                    );
                    return;
                }
                for my $j ( 0 .. length($charstring) ) {
                    my $datum = new Bio::Phylo::Matrices::Datum;
                    $datum->set_name($name);
                    $datum->set_position( $j + 1 );
                    $datum->set_type($datatype);
                    $datum->set_char( substr( $charstring, $j, 1 ) );
                    $matrix->insert($datum);
                }
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

=item _parse_trees(\@trees)

 Type    : Parsers
 Title   : _parse_trees(\@trees)
 Usage   : $nexus->_parse_trees(\@trees);
 Function: Creates Bio::Phylo::Trees object from an array of trees.
 Returns : A Bio::Phylo::Trees object
 Args    : A reference to an array holding newick trees.

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
    my $nparser = new Bio::Phylo::Parsers::Newick;
    my $trees   =
      $nparser->from_string( -format => 'newick', -string => $nstring );
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

=item _parse_comm()

 Type    : _parse_comm
 Title   : _parse_comm()
 Usage   : $nexus->_parse_comm();
 Function: Parses nexus comments
 Returns : Nothing yet.
 Args    : none.

=cut

sub _parse_comm {
    my ( $self, $comm ) = @_;
    return join( ' ', @{$comm} );
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>
L<http://www.sfu.ca/~rvosa/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

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
