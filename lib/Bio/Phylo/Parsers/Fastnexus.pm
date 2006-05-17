# $Id: Fastnexus.pm,v 1.4 2006/04/12 22:38:23 rvosa Exp $
# Subversion: $Rev: 195 $
package Bio::Phylo::Parsers::Fastnexus;
use strict;
use Bio::Phylo::Taxa;
use Bio::Phylo::Taxa::Taxon;
use Bio::Phylo::Forest;
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Matrices::Matrix;
use Bio::Phylo::IO qw(parse);
use Bio::Phylo::Util::CONSTANT qw(_MATRIX_ _FOREST_ _TAXA_);
use Bio::Phylo::Util::Exceptions;
use Scalar::Util qw(blessed);
use IO::String;

# TODO: handle interleaved, handle ambiguity, mixed?

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo::IO);

=head1 NAME

Bio::Phylo::Parsers::Fastnexus - Parses nexus files. No serviceable parts inside.

=head1 DESCRIPTION

This module parses nexus files. It is called by the L<Bio::Phylo::IO> module,
there is no direct usage. The parser can handle files and strings with multiple
tree, taxon, and characters blocks whose links are defined using Mesquite's
"TITLE = 'some_name'" and "LINK TAXA = 'some_name'" tokens.

The parser returns a reference to an array containing one or more taxa, trees
and matrices objects. Nexus comments are stripped, spaces in single quoted
strings are replaced with underscores, private nexus blocks (and the
'assumptions' block) are skipped. It currently doesn't handle 'interleaved'
matrices and 'mixed' data.

=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $nexus = Bio::Phylo::Parsers::Fastnexus->_new;
 Function: Initializes a Bio::Phylo::Parsers::Fastnexus object.
 Returns : A Bio::Phylo::Parsers::Fastnexus object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = shift;

    # this is a dispatch table whose sub references are invoked
    # during parsing. the keys match the tokens upon which the
    # respective subs are called. Underscored fields are for parsing
    # context.
    my $self = {
        '_current'   => undef,
        '_previous'  => undef,
        '_begin'     => undef,
        '_ntax'      => undef,
        '_nchar'     => undef,
        '_gap'       => undef,
        '_missing'   => undef,
        '_i'         => undef,
        '_tree'      => undef,
        '_treename'  => undef,
        '_treestart' => undef,
        '_row'       => undef,
        '_found'           => 0,
        '_tokens'          => [],
        '_context'         => [],
        '_translate'       => [],
        '_symbols'         => [],
        '_charstatelabels' => [],
        '_matrix'          => {},
        '_matrixtype'      => undef,
        'begin'            => \&_begin,
        'taxa'             => \&_taxa,
        'title'            => \&_title,
        'dimensions'       => \&_dimensions,
        'ntax'             => \&_ntax,
        'taxlabels'        => \&_taxlabels,
        'data'             => \&_data,
        'characters'       => \&_characters,
        'nchar'            => \&_nchar,
        'format'           => \&_format,
        'datatype'         => \&_datatype,
        'gap'              => \&_gap,
        'missing'          => \&_missing,
        'charstatelabels'  => \&_charstatelabels,
        'symbols'          => \&_symbols,
        'items'            => \&_items,
        'matrix'           => \&_matrix,
        'trees'            => \&_trees,
        'translate'        => \&_translate,
        'tree'             => \&_tree,
        'utree'            => \&_tree,
        'end'              => \&_end,
        '#nexus'           => \&_nexus,
        'link'             => \&_link,
        ';'                => \&_semicolon,
        'interleave' => sub { Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => 'Sorry, no interleaved matrices',
        )},
    };
    bless $self, $class;
    return $self;
}

=begin comment

 Type    : Wrapper
 Title   : _from_handle(\*FH)
 Usage   : $nexus->_from_handle(\*FH);
 Function: Does all the parser magic, from a file handle
 Returns : L<Phylo>
 Args    : \*FH = file handle

=end comment

=cut

# trickery to get it to parse strings as well, uses IO::String
*_from_string = \&_from_handle;

sub _from_handle {
    my $self = shift;
    my %opts = @_;
    my $comments = 0;

    if ( $opts{'-string'} ) {
        $opts{'-handle'} = IO::String->new( $opts{'-string'} );
    }

    # only from a file handle (but can be fooled with IO::String)
    while ( readline($opts{-handle}) ) {
        chomp( my $line = $_ );

        # make spaces between punctuation and neighboring tokens (for split())
        $line =~ s/(;|=|,|\[|\])/ $1 /g;

        # strip comments, push remainder in @tokens
        foreach my $token ( split(/\s+/, $line) ) {
            $comments++ if $token eq '[';
            if ( $token !~ m/^\s*$/ and not $comments ) {
                push @{ $self->{'_tokens'} }, $token;
            }
            $comments-- if $token eq ']';
        }
    }

    # replace single quoted with underscores for split(/\s+/, $_).
    # Later on, _escape() is called to put single quotes back in
    # if string contains special characters.
    my $slurped = join( ' ', @{ $self->{'_tokens'} } );
    while ( $slurped =~ m/^([^']*?)'([^']*?)'(.*)$/ ) {
        my $begin     = $1;
        my $quoted    = $2;
        my $remainder = $3;
        $quoted =~ s/\s+/_/g;
        $slurped = $begin . $quoted . $remainder;
    }
    @{ $self->{'_tokens'} } = split(/\s+/, $slurped);

    # iterate over tokens, dispatch methods from %{ $self } table
    # This is the meat of the parsing, from here everything else is called.
    my $i = 0;
    no strict 'refs';
    while ( $i <= $#{ $self->{'_tokens'} } ) {
        if ( exists $self->{ lc( $self->{'_tokens'}->[$i] ) } ) {
            if ( ref $self->{ lc( $self->{'_tokens'}->[$i] ) } eq 'CODE' ) {
                $self->{'_previous'} = $self->{'_current'};
                $self->{'_current'} = lc( $self->{'_tokens'}->[$i] );
                # pull code ref from dispatch table
                my $c = $self->{ lc( $self->{'_tokens'}->[$i] ) };
                # invoke as object method
                $self->$c( $self->{'_tokens'}->[$i] );
                $i++;
            }
        }
        elsif ( $self->{'_current'} ) {
            my $c = $self->{ $self->{'_current'} };
            $self->$c( $self->{'_tokens'}->[$i] );
            $i++;
        }
        # note: global var $begin is switched 'on' by &_begin(), and 'off'
        # again by any one of the appropriate subsequent tokens, i.e.
        # taxa, data, characters and trees
        if ( $self->{'_begin'} and not exists $self->{ lc( $self->{'_tokens'}->[$i] ) } ) {
            my $private = $self->{'_tokens'}->[$i];
            # I think this is one of the few cases where 'until' is appropriate
            until ( lc($self->{'_tokens'}->[$i - 2]) eq 'end' && $self->{'_tokens'}->[$i - 1] eq ';' ) {
                $i++;
            }
            # here we've encountered 'end', ';' - $tokens[$i] should be 'begin'
            print "[ skipped private $private block ]\n" if $self->VERBOSE;
        }
    }

    # link matrices and forests to taxa
    my $taxa = [];
    foreach my $block ( @{ $self->{'_context'} } ) {
        if ( $block->_type == _TAXA_ ) {
            push @{ $taxa }, $block;
        }
        elsif ( $block->_type != _TAXA_ and $block->can('set_taxa') ) {
            if ( $taxa->[-1] and $taxa->[-1]->can('_type') == _TAXA_ and not $block->get_taxa ) {
                $block->set_taxa( $taxa->[-1] ); # XXX exception here?
            }
        }
    }

    return $self->{'_context'};
}

=begin comment

The following subs are called by the dispatch table stored in the object when
their respective tokens are encountered.

=end comment

=cut

sub _nexus {
    my $self = shift;
    print "#NEXUS\n" if uc($_[0]) eq '#NEXUS' and $self->VERBOSE;
}

sub _begin {
    my $self = shift;
    $self->{'_begin'} = 1;
}

sub _taxa {
    my $self = shift;
    if ( $self->{'_begin'} ) {
        push @{ $self->{'_context'} }, Bio::Phylo::Taxa->new;
        print "BEGIN TAXA" if $self->VERBOSE;
        $self->{'_begin'} = 0;
    }
    else {
        $self->{'_current'} = 'link'; # because of 'link taxa = blah' construct
    }
}

sub _title {
    my $self  = shift;
    my $token = shift;
    if ( defined $token and uc($token) ne 'TITLE' ) {
        my $title = _escape($token);
        if ( not $self->{'_context'}->[-1]->get_name ) {
            $self->{'_context'}->[-1]->set_name($title);
            print "$title" if $self->VERBOSE;
        }
    }
    elsif ( uc($token) eq 'TITLE' ) {
        print "TITLE " if $self->VERBOSE;
    }
}

sub _link {
    my $self  = shift;
    my $token = shift;
    if ( defined $token and $token !~ m/^(?:LINK|TAXA|=)$/i ) {
        my $link = _escape($token);
        if ( not $self->{'_context'}->[-1]->get_taxa ) {
            foreach my $block ( @{ $self->{'_context'} } ) {
                if ( $block->get_name and $block->get_name eq $link ) {
                    $self->{'_context'}->[-1]->set_taxa( $block );
                    last;
                }
            }
            print "TAXA = $link" if $self->VERBOSE;
        }
    }
    elsif ( uc($token) eq 'LINK' ) {
        print "LINK " if $self->VERBOSE;
    }
}

sub _dimensions {
    my $self = shift;
    print "DIMENSIONS " if $self->VERBOSE;
}

sub _ntax {
    my $self = shift;
    if ( defined $_[0] and $_[0] =~ m/^\d+$/ ) {
        $self->{'_ntax'} = shift;
        print " NTAX = ", $self->{'_ntax'} if $self->VERBOSE;
    }
}

sub _taxlabels {
    my $self = shift;
    if ( defined $_[0] and uc($_[0]) ne 'TAXLABELS' ) {
        push @{ $self->{'_taxlabels'} }, _escape(shift);
    }
}

sub _data {
    my $self = shift;
    if ( $self->{'_begin'} ) {
        push @{ $self->{'_context'} }, Bio::Phylo::Matrices::Matrix->new;
        $self->{'_begin'} = 0;
        print "BEGIN DATA" if $self->VERBOSE;
    }
}

sub _characters {
    my $self = shift;
    if ( $self->{'_begin'} ) {
        push @{ $self->{'_context'} }, Bio::Phylo::Matrices::Matrix->new;
        $self->{'_begin'} = 0;
        print "BEGIN CHARACTERS" if $self->VERBOSE;
    }
}

sub _nchar {
    my $self = shift;
    if ( defined $_[0] and $_[0] =~ m/^\d+$/ ) {
        $self->{'_nchar'} = shift;
        print " NCHAR = ", $self->{'_nchar'} if $self->VERBOSE;
    }
}

sub _format {
    my $self = shift;
    print "FORMAT " if $self->VERBOSE;
}

sub _datatype {
    my $self = shift;
    if ( defined $_[0] and $_[0] !~ m/^(?:DATATYPE|=)/i and ! $self->{'_context'}->[-1]->get_type ) {
        my $datatype = shift;
        $self->{'_context'}->[-1]->set_type( $datatype );
        print "DATATYPE = ", $datatype if $self->VERBOSE;
    }
}

sub _items {
    my $self = shift;
    print " ", shift, " " if $self->VERBOSE;
}

sub _gap {
    my $self = shift;
    if ( $_[0] !~ m/^(?:GAP|=)/i and ! $self->{'_gap'} ) {
        $self->{'_gap'} = shift;
        print " GAP = ", $self->{'_gap'} if $self->VERBOSE;
        $self->{'_context'}->[-1]->set_gap( $self->{'_gap'} );
        undef $self->{'_gap'};
    }
}

sub _missing {
    my $self = shift;
    if ( $_[0] !~ m/^(?:MISSING|=)/i and ! $self->{'_missing'} ) {
        $self->{'_missing'} = shift;
        print " MISSING = ", $self->{'_missing'} if $self->VERBOSE;
        $self->{'_context'}->[-1]->set_missing( $self->{'_missing'} );
        undef $self->{'_missing'};
    }
}

sub _symbols {
    my $self = shift;
    if ( $_[0] !~ m/^(?:SYMBOLS|=|")$/i and $_[0] =~ m/^"?(.)"?$/ ) {
        push @{ $self->{'_symbols'} }, $1;
    }
}

sub _charstatelabels {

}

sub _matrix {
    my $self  = shift;
    my $token = shift;
    if ( not defined $self->{'_matrixtype'} ) {
        $self->{'_matrixtype'} = $self->{'_context'}->[-1]->get_type;
    }

    # first token: 'MATRIX'
    if ( uc($token) eq 'MATRIX' ) {
        $self->{'_context'}->[-1]->set_ntax( $self->{'_ntax'} );
        $self->{'_context'}->[-1]->set_nchar( $self->{'_nchar'} );
        if ( $self->VERBOSE ) {
            print "MATRIX [ ",  $self->{'_context'}->[-1]->get_type;
            print " nchar: ",   $self->{'_context'}->[-1]->get_nchar;
            print " ntax: ",    $self->{'_context'}->[-1]->get_ntax;
            print " ]\n";
        }
        return;
    }

    # no taxon name, starting a new row
    elsif ( not defined $self->{'_row'} ) {
        $self->{'_row'} = _escape($token); # initialize taxon name
        $self->{'_matrix'}->{ $self->{'_row'} } = []; # initialize char array ref
        return;
    }

    # continuing row, not reached nchar
    elsif ( scalar @{ $self->{'_matrix'}->{ $self->{'_row'} } } < $self->{'_nchar'} ) {
        if ( uc $self->{'_matrixtype'} eq 'CONTINUOUS' ) {
            push @{ $self->{'_matrix'}->{ $self->{'_row'} } }, $token if $token;
        }
        else {
            push @{ $self->{'_matrix'}->{ $self->{'_row'} } }, grep {/^.$/} split(//,$token);
        }
    }

    # finishing row, reached nchar
    if ( scalar @{ $self->{'_matrix'}->{ $self->{'_row'} } } == $self->{'_nchar'} ) {
        my $taxon;

        # find / create matching taxon, matrix is linked
        if ( my $taxa = $self->{'_context'}->[-1]->get_taxa ) {
            while ( my $t = $taxa->next ) {
                if ( $t->get_name eq $self->{'_row'} ) {
                    $taxon = $t;
                }
            }

            # taxon does not exist yet
            if ( not $taxon ) {
                $taxon = Bio::Phylo::Taxa::Taxon->new(
                    '-name' => $self->{'_row'},
                );
                $taxa->insert( $taxon );
            }
        }

        # matrix is not linked
        else {

            # try to find the most recent taxa block
            my $taxa;
            for ( my $i = $#{ $self->{'_context'} }; $i >= 0; $i-- ) {
                if ( $self->{'_context'}->[$i]->_type == _TAXA_ ) {
                    $taxa = $self->{'_context'}->[$i];
                    last;
                }
            }

            # create new taxa block
            if ( not $taxa ) {
                $taxa = Bio::Phylo::Taxa->new(
                    '-name' => 'Untitled_taxa_block',
                );
            }

            # create new taxon
            $taxon = Bio::Phylo::Taxa::Taxon->new(
                '-name' => $self->{'_row'},
            );
            $taxa->insert( $taxon );
            unshift @{ $self->{'_context'} }, $taxa; # place new taxa as first
            $self->{'_context'}->[-1]->set_taxa( $taxa ); # link current block to taxa
        }

        # create new datum
        my $datum = Bio::Phylo::Matrices::Datum->new(
            '-char'  => $self->{'_matrix'}->{ $self->{'_row'} },
            '-name'  => $self->{'_row'},
            '-type'  => $self->{'_matrixtype'},
            '-taxon' => $taxon,
        );
        my @rows = keys %{ $self->{'_matrix'} };
        if ( scalar @rows < $self->{'_ntax'} ) {
            $self->{'_context'}->[-1]->_is_flat(1); # only run _flatten the last time
        }
        else {
            $self->{'_context'}->[-1]->_is_flat(0);
        }

        # insert new datum in matrix
        $self->{'_context'}->[-1]->insert($datum);

        if ( $self->VERBOSE ) {
            print $self->{'_row'}, "\t";
            if ( uc $self->{'_matrixtype'} eq 'CONTINUOUS' ) {
                print join(' ', @{ $self->{'_matrix'}->{ $self->{'_row'} } }), "\n";
            }
            else {
                print join('', @{ $self->{'_matrix'}->{ $self->{'_row'} } }), "\n";
            }
        }
        $self->{'_row'} = undef;
    }

    # Let's avoid these!
    elsif ( scalar @{ $self->{'_matrix'}->{ $self->{'_row'} } } > $self->{'_nchar'} ) {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => "More characters than expected",
        );
    }
    elsif ( not $self->{'_row'} and scalar { keys %{ $self->{'_matrix'} } } > $self->{'_ntax'} ) {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => "More taxa than expected",
        );
    }
}

sub _trees {
    my $self = shift;
    if ( $self->{'_begin'} ) {
        push @{ $self->{'_context'} }, Bio::Phylo::Forest->new;
        $self->{'_begin'} = 0;
        print "BEGIN TREES" if $self->VERBOSE;
    }
}

sub _translate {
    my $self = shift;
    if ( defined $_[0] and $_[0] =~ m/^\d+$/ ) {
        $self->{'_i'} = shift;
        if ( $self->{'_i'} == 1 ) {
            print "TRANSLATE\n", $self->{'_i'}, ' ' if $self->VERBOSE;
        }
        elsif ( $self->{'_i'} > 1 ) {
            print ",\n", $self->{'_i'}, ' ' if $self->VERBOSE;
        }
    }
    elsif ( defined $self->{'_i'} and defined $_[0] and $_[0] ne ';' ) {
        my $i = $self->{'_i'};
        $self->{'_translate'}->[$i] = _escape($_[0]);
        print $self->{'_translate'}->[$i] if $self->VERBOSE;
        $self->{'_i'} = undef;
    }
}

sub _tree {
    my $self = shift;
    if ( not $self->{'_treename'} and $_[0] !~ m/^U?TREE$/i ) {
        $self->{'_treename'} = _escape($_[0]);
    }
    if ( $_[0] eq '=' and not $self->{'_treestart'} ) {
        $self->{'_treestart'} = 1;
    }
    if ( $_[0] ne '=' and $self->{'_treestart'} ) {
        $self->{'_tree'} .= $_[0];
    }

    # tr/// returns # of replacements, hence can be used to check
    # tree description is balanced
    if ( $self->{'_treestart'} and $self->{'_tree'} and $self->{'_tree'} =~ tr/(/(/ == $self->{'_tree'} =~ tr/)/)/ ) {
        my $translated = $self->{'_tree'};
        my $translate  = $self->{'_translate'};
        for my $i ( 1 .. $#{ $translate } ) {
            $translated =~ s/(\(|,)$i(,|\)|:)/$1$translate->[$i]$2/;
        }
        my $tree_obj = parse(
            '-format' => 'fastnewick',
            '-string' => $translated . ';',
        )->first->set_name( $self->{'_treename'} );
        $self->{'_context'}->[-1]->insert( $tree_obj );
        print "TREE ", $self->{'_treename'}, " = ", $self->{'_tree'} if $self->VERBOSE;
        $self->{'_treestart'} = 0;
        $self->{'_tree'}      = undef;
        $self->{'_treename'}  = undef;
    }
}

sub _end {
    my $self = shift;
    print "END" if uc($_[0]) eq 'END' and $self->VERBOSE;
    $self->{'_translate'} = [];
}

sub _semicolon {
    my $self = shift;
    print ";\n" if $_[0] eq ';' and $self->VERBOSE;
    if ( uc $self->{'_previous'} eq 'MATRIX' ) {
        $self->{'_matrixtype'} = undef;
        $self->{'_matrix'}     = {};
        if ( not $self->{'_context'}->[-1]->get_ntax ) {
            my $taxon = {};
            foreach my $row ( @{ $self->{'_context'}->[-1]->get_entities } ) {
                $taxon->{$row->get_taxon}++;
            }
            my $ntax = scalar keys %{ $taxon };
            $self->{'_context'}->[-1]->set_ntax( $ntax );
        }
        eval { $self->{'_context'}->[-1]->validate };
        if ( $@ ) {
            $@->rethrow;
        }
    }
    elsif ( uc $self->{'_previous'} eq 'TAXLABELS' ) {
        print "TAXLABELS\n" if $self->VERBOSE;
        foreach my $name ( @{ $self->{'_taxlabels'} } ) {
            print "\t$name\n" if $self->VERBOSE;
            my $taxon = Bio::Phylo::Taxa::Taxon->new(
                '-name' => $name,
            );
            $self->{'_context'}->[-1]->insert($taxon);
        }
        $self->{'_context'}->[-1]->set_ntax( $self->{'_ntax'} );
        eval { $self->{'_context'}->[-1]->validate };
        if ( $@ ) {
            $@->rethrow;
        }
        $self->{'_taxlabels'} = [];
    }
    elsif ( uc $self->{'_previous'} eq 'SYMBOLS' ) {
        if ( $self->VERBOSE ) {
            print 'SYMBOLS = "', join(' ', @{ $self->{'_symbols'} }), '"';
        }
        $self->{'_context'}->[-1]->set_symbols( $self->{'_symbols'} );
        $self->{'_symbols'} = [];
    }
}

sub _escape {
    my $unescaped = $_[0];
    my $escaped;
    if ( $unescaped =~ m/(?:\(|\)|:|;|,)/ ) {
        $escaped = "'" . $unescaped . "'";
    }
    else {
        $escaped = $unescaped;
    }
    return $escaped;
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

$Id: Fastnexus.pm,v 1.4 2006/04/12 22:38:23 rvosa Exp $

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
