# $Id: Datum.pm,v 1.30 2006/05/19 02:08:56 rvosa Exp $
package Bio::Phylo::Matrices::Datum;
use strict;
use Bio::Phylo::Forest::Node;
use Bio::Phylo::Util::IDPool;
use Scalar::Util qw(looks_like_number weaken blessed);
use Bio::Phylo::Util::CONSTANT qw(_DATUM_ _MATRIX_ _TAXON_ symbol_ok type_ok);
use XML::Simple;

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo);
{

    # inside out class arrays
    my @taxon;
    my @weight;
    my @type;
    my @char;
    my @pos;
    my @annotations;

    # $fields hashref necessary for object destruction
    my $fields = {
        '-taxon'  => \@taxon,
        '-weight' => \@weight,
        '-type'   => \@type,
        '-char'   => \@char,
        '-pos'    => \@pos,
        '-note'   => \@annotations,
    };

=head1 NAME

Bio::Phylo::Matrices::Datum - The single observations object.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Matrix;
 use Bio::Phylo::Matrices::Datum;
 use Bio::Phylo::Taxa::Taxon;

 # instantiating a datum object...
 my $datum = Bio::Phylo::Matrices::Datum->new(
    -name   => 'Tooth comb size,
    -type   => 'STANDARD',
    -desc   => 'number of teeth in lower jaw comb',
    -pos    => 1,
    -weight => 2,
    -char   => [ 6 ],
 );

 # ...and linking it to a taxon object
 my $taxon = Bio::Phylo::Taxa::Taxon->new( 
     -name => 'Lemur_catta' 
 );
 $datum->set_taxon( $taxon );
 
 # instantiating a matrix...
 my $matrix = Bio::Phylo::Matrices::Matrix->new;
 
 # ...and insert datum in matrix
 $matrix->insert($datum);

=head1 DESCRIPTION

The datum object models a single observation or a sequence of observations, 
which can be linked to a taxon object.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $datum = Bio::Phylo::Matrices::Datum->new;
 Function: Instantiates a Bio::Phylo::Matrices::Datum 
           object.
 Returns : A Bio::Phylo::Matrices::Datum object.
 Args    : None required. Optional:
           -taxon  => $taxon,
           -weight => 0.234,
           -type   => DNA,
           -char   => [ 'G','A','T','T','A','C','A' ],
           -pos    => 2,
 

=cut

    sub new {
        my $class = shift;
        my $self  = __PACKAGE__->SUPER::new(@_);

# the basic design is like this: every datum holds an array
# reference with characters, i.e. $char[$$self] = [ 'A', 'C', 'G' ];
# these characters can then be annotated, individually, using the
# @annotations array, e.g.:
# $annotations[$$self] = [ { -codonpos => 1 }, { -codonpos => 2 }, { -codonpos => 3 } ];
# this way, individual characters inside the @char array can be richly
# annotated without having to spawn individual objects for every character
# in a sequence.
        $char[$$self]        = [];
        $annotations[$$self] = [];
        bless $self, $class;
        if (@_) {
            my %opt;
            eval { %opt = @_; };
            if ($@) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
            }
            else {
                while ( my ( $key, $value ) = each %opt ) {
                    if ( $fields->{$key} ) {
                        $fields->{$key}->[$$self] = $value;
                        if ( blessed $value && $value->can('_type') ) {
                            my $type = $value->_type;
                            if ( $type == _TAXON_ ) {
                                weaken( $fields->{$key}->[$$self] );
                            }
                        }
                        delete $opt{$key};
                    }
                }
                @_ = %opt;
            }
        }
        return $self;
    }

=back

=head2 MUTATORS

=over

=item set_taxon()

 Type    : Mutator
 Title   : set_taxon
 Usage   : $datum->set_taxon($taxon);
 Function: Assigns the taxon a datum refers to.
 Returns : Modified object.
 Args    : $taxon must be a Bio::Phylo::Taxa::Taxon 
           object.

=cut

    sub set_taxon {
        my ( $self, $taxon ) = @_;
        if ( defined $taxon ) {
            if ( $taxon->can('_type') && $taxon->_type == _TAXON_ ) {
                if ( $self->_get_container && $self->_get_container->get_taxa )
                {
                    if ( $taxon->_get_container !=
                        $self->_get_container->get_taxa )
                    {
                        Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                            error =>
                              "Attempt to link datum to taxon from wrong block"
                        );
                    }
                }
                $taxon[$$self] = $taxon;
                weaken( $taxon[$$self] );
                if ( $self->_get_container ) {
                    $self->_get_container->set_taxa( $taxon->_get_container );
                }
            }
            else {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    error => "\"$taxon\" doesn't look like a taxon" );
            }
        }
        else {
            $taxon[$$self] = undef;
        }
        $self->_flush_cache;
        return $self;
    }

=item set_weight()

 Type    : Mutator
 Title   : set_weight
 Usage   : $datum->set_weight($weight);
 Function: Assigns a datum's weight.
 Returns : Modified object.
 Args    : The $weight argument must be a 
           number in any of Perl's number
           formats.

=cut

    sub set_weight {
        my ( $self, $weight ) = @_;
        if ( defined $weight ) {
            if ( !looks_like_number $weight ) {
                Bio::Phylo::Util::Exceptions::BadNumber->throw(
                    error => "\"$weight\" is a bad number format" );
            }
            else {
                $weight[$$self] = $weight;
            }
        }
        else {
            $weight[$$self] = undef;
        }
        return $self;
    }

=item set_type()

 Type    : Mutator
 Title   : set_type
 Usage   : $datum->set_type($type);
 Function: Assigns a datum's type.
 Returns : Modified object.
 Args    : $type must be one of [DNA|RNA|STANDARD|
           PROTEIN|NUCLEOTIDE|CONTINUOUS]. If DNA, 
           RNA or NUCLEOTIDE is defined, the
           subsequently set char is validated against 
           the IUPAC nucleotide one letter codes. If 
           PROTEIN is defined, the char is validated 
           against IUPAC one letter amino acid codes. 
           Likewise, a STANDARD char has to be a single 
           integer [0-9], while for CONTINUOUS all of 
           Perl's number formats are allowed.

=cut

    sub set_type {
        my ( $self, $type ) = @_;
        if ( $type && !type_ok($type) ) {
            Bio::Phylo::Util::Exceptions::BadFormat->throw(
                error => "\"$type\" is a bad data type" );
        }
        elsif ( !$type ) {
            $type[$$self] = undef;
        }
        else {
            $type[$$self] = uc $type;
        }
        return $self;
    }

=item set_char()

 Type    : Mutator
 Title   : set_char
 Usage   : $datum->set_char($char);
 Function: Assigns a datum's character value.
 Returns : Modified object.
 Args    : The $char argument is checked against 
           the allowed ranges for the various 
           character types: IUPAC nucleotide (for 
           types of DNA|RNA|NUCLEOTIDE), IUPAC 
           single letter amino acid codes (for type 
           PROTEIN), integers (STANDARD) or any of perl's
           decimal formats (CONTINUOUS). The $char can be: 
               * a single character;
               * a string of characters;
               * an array reference of characters;
 Comments: Note that on assigning characters to a datum,
           previously set annotations are removed.               

=cut

    sub set_char {
        my ( $self, $char ) = @_;
        if ( my $type = $self->get_type ) {
            if ($char) {
                if ( symbol_ok( '-type' => $type, '-char' => $char ) ) {
                    if ( $type !~ m/^CONTINUOUS$/i ) {
                        if ( not ref $char and length($char) > 1 ) {
                            $char[$$self] = [ split( //, $char ) ];
                        }
                        elsif ( not ref $char and length($char) == 1 ) {
                            $char[$$self] = [$char];
                        }
                        elsif ( ref $char eq 'ARRAY' ) {
                            $char[$$self] = $char;
                        }
                    }
                    else {
                        if ( not ref $char and not looks_like_number $char ) {
                            $char[$$self] = [ split( /\s+/, $char ) ];
                        }
                        elsif ( not ref $char and looks_like_number $char ) {
                            $char[$$self] = [$char];
                        }
                        elsif ( ref $char eq 'ARRAY' ) {
                            $char[$$self] = $char;
                        }
                    }
                }
                else {
                    Bio::Phylo::Util::Exceptions::BadString->throw(
                        error => "\"$char\" is not a valid \"$type\" symbol" );
                }
            }
            else {
                $char[$$self] = undef;
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::BadFormat->throw(
                error => 'please define the data type first' );
        }
        $annotations[$$self] = [];
        return $self;
    }

=item set_position()

 Type    : Mutator
 Title   : set_position
 Usage   : $datum->set_position($pos);
 Function: Assigns a datum's position.
 Returns : Modified object.
 Args    : $pos must be an integer.

=cut

    sub set_position {
        my ( $self, $pos ) = @_;
        if ( defined $pos and $pos !~ m/^\d+$/ ) {
            Bio::Phylo::Util::Exceptions::BadNumber->throw(
                error => "\"$pos\" is bad. Positions must be integers" );
        }
        else {
            $pos[$$self] = $pos;
        }
        return $self;
    }

=item set_annotation()

 Type    : Mutator
 Title   : set_annotation
 Usage   : $datum->set_annotation( 
               -char       => 1, 
               -annotation => { -codonpos => 1 } 
           );
 Function: Assigns an annotation to a 
           character in the datum.
 Returns : Modified object.
 Args    : Required: -char       => $int
           Optional: -annotation => $hashref
 Comments: Use this method to annotate
           a single character. To annotate
           multiple characters, use
           'set_annotations' (see below).

=cut

    sub set_annotation {
        my $self = shift;
        if (@_) {
            my %opt;
            eval { %opt = @_ };
            if ($@) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
            }
            if ( not exists $opt{'-char'} ) {
                Bio::Phylo::Util::Exceptions::BadArgs->throw(
                    error => "No character to annotate specified!" );
            }
            my $i = $opt{'-char'};
            if ( not exists $char[$$self]->[$i] ) {
                Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                    error => "Specified char ($i) does not exist!" );
            }
            if ( exists $opt{'-annotation'} ) {
                my $note = $opt{'-annotation'};
                $annotations[$$self]->[$i] = {} if !$annotations[$$self]->[$i];
                while ( my ( $k, $v ) = each %{$note} ) {
                    $annotations[$$self]->[$i]->{$k} = $v;
                }
            }
            else {
                $annotations[$$self]->[$i] = undef;
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                error => "No character to annotate specified!" );
        }
        return $self;
    }

=item set_annotations()

 Type    : Mutator
 Title   : set_annotations
 Usage   : $datum->set_annotations( 
               { '-codonpos' => 1 }, 
               { '-codonpos' => 2 }, 
               { '-codonpos' => 3 },              
           );
 Function: Assign annotations to
           characters in the datum.
 Returns : Modified object.
 Args    : Hash references, where 
           position in the argument
           list matches that of the
           specified characters in 
           the character list.
 Comments: Use this method to annotate
           multiple characters. To
           annotate a single character,
           use 'set_annotation' (see
           above).

=cut

    sub set_annotations {
        my $self = shift;
        if (@_) {
            for my $i ( 0 .. $#_ ) {
                if ( not exists $char[$$self]->[$i] ) {
                    Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                        error => "Specified char ($i) does not exist!" );
                }
                else {
                    if ( ref $_[$i] eq 'HASH' ) {
                        $annotations[$$self]->[$i] = {}
                          if !$annotations[$$self]->[$i];
                        while ( my ( $k, $v ) = each %{ $_[$i] } ) {
                            $annotations[$$self]->[$i]->{$k} = $v;
                        }
                    }
                    else {
                        next;
                    }
                }
            }
        }
    }

=back

=head2 ACCESSORS

=over

=item get_taxon()

 Type    : Accessor
 Title   : get_taxon
 Usage   : my $taxon = $datum->get_taxon;
 Function: Retrieves the taxon a datum refers to.
 Returns : Bio::Phylo::Taxa::Taxon
 Args    : NONE

=cut

    sub get_taxon {
        my $self = shift;
        return $taxon[$$self];
    }

=item get_weight()

 Type    : Accessor
 Title   : get_weight
 Usage   : my $weight = $datum->get_weight;
 Function: Retrieves a datum's weight.
 Returns : FLOAT
 Args    : NONE

=cut

    sub get_weight {
        my $self = shift;
        return $weight[$$self];
    }

=item get_type()

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $datum->get_type;
 Function: Retrieves a datum's type.
 Returns : One of [DNA|RNA|STANDARD|PROTEIN|
           NUCLEOTIDE|CONTINUOUS]
 Args    : NONE

=cut

    sub get_type {
        my $self = shift;
        return $type[$$self];
    }

=item get_char()

 Type    : Accessor
 Title   : get_char
 Usage   : my $char = $datum->get_char;
 Function: Retrieves a datum's character value.
 Returns : In scalar context, returns a single 
           character, or a string of characters 
           (e.g. a DNA sequence, or a space 
           delimited series of continuous characters). 
           In list context, returns a list of characters
           (of zero or more characters).
 Args    : NONE

=cut

    sub get_char {
        my $self = shift;
        if ( $self->get_type and $self->get_type !~ m/^CONTINUOUS$/i ) {
            return wantarray ? @{ $char[$$self] } : join '', @{ $char[$$self] };
        }
        else {
            return wantarray ? @{ $char[$$self] } : join ' ',
              @{ $char[$$self] };
        }
    }

=item get_position()

 Type    : Accessor
 Title   : get_position
 Usage   : my $pos = $datum->get_position;
 Function: Retrieves a datum's position.
 Returns : a SCALAR integer.
 Args    : NONE

=cut

    sub get_position {
        my $self = shift;
        return $pos[$$self];
    }

=item get_annotation()

 Type    : Accessor
 Title   : get_annotation
 Usage   : $datum->get_annotation( 
               '-char' => 1, 
               '-key'  => '-codonpos',
           );
 Function: Retrieves an annotation to 
           a character in the datum.
 Returns : SCALAR or HASH
 Args    : Optional: -char => $int
           Optional: -key => $key

=cut

    sub get_annotation {
        my $self = shift;
        if (@_) {
            my %opt;
            eval { %opt = @_ };
            if ($@) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@, );
            }
            if ( not exists $opt{'-char'} ) {
                Bio::Phylo::Util::Exceptions::BadArgs->throw(
                    error => "No character to return annotation for specified!",
                );
            }
            my $i = $opt{'-char'};
            if ( not exists $char[$$self]->[$i] ) {
                Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                    error => "Specified char ($i) does not exist!", );
            }
            if ( exists $opt{'-key'} ) {
                return $annotations[$$self]->[$i]->{ $opt{'-key'} };
            }
            else {
                return $annotations[$$self]->[$i];
            }
        }
        else {
            return $annotations[$$self];
        }
    }

=back

=head2 METHODS

=over

=item copy_atts()

 Type    : Method
 Title   : copy_atts
 Usage   : my $copy = $datum->copy_atts;
 Function: Creates an empty copy of invocant 
           (i.e. no data, but all the
           attributes).
 Returns : Bio::Phylo::Matrices::Datum 
           (shallow copy)
 Args    : None

=cut 

    sub copy_atts {
        my $self = shift;
        my $copy = __PACKAGE__->new;

        # Bio::Phylo::Matrices::Datum atts
        $copy->set_taxon( $self->get_taxon );
        $copy->set_weight( $self->get_weight );
        $copy->set_type( $self->get_type );
        $copy->set_position( $self->get_position );

        # Bio::Phylo atts
        $copy->set_name( $self->get_name );
        $copy->set_desc( $self->get_desc );
        $copy->set_score( $self->get_score );
        $copy->set_generic( %{ $self->get_generic } ) if $self->get_generic;
    }

=item reverse()

 Type    : Method
 Title   : reverse
 Usage   : my $reversed = $datum->reverse;
 Function: Reverse a datum's character string.
 Returns : Reversed datum.
 Args    : NONE

=cut

    sub reverse {
        my $self  = shift;
        my @chars = reverse @{ $char[$$self] };
        $char[$$self] = \@chars;
        return $self;
    }

=item to_xml()

 Type    : Format converter
 Title   : to_xml
 Usage   : my $xml = $datum->to_xml;
 Function: Reverse a datum's XML representation.
 Returns : Valid XML string.
 Args    : NONE

=cut

    sub to_xml {
        my $self = shift;
        my $xml;
        foreach my $k ( keys %{$fields} ) {
            my $tag = $k;
            $tag =~ s/^-(.*)$/$1/;
            $xml .= '<' . $tag . '>';
            $xml .= XMLout( $fields->{$k}->[$$self] );
            $xml .= '</' . $tag . '>';
        }
        return $xml;
    }

    # TODO: trim, splice, complement, concat, translate - implement PrimarySeqI?

=back

=head2 DESTRUCTOR

=over

=item DESTROY()

 Type    : Destructor
 Title   : DESTROY
 Usage   : $phylo->DESTROY
 Function: Destroys Phylo object
 Alias   :
 Returns : TRUE
 Args    : none
 Comments: You don't really need this, 
           it is called automatically when
           the object goes out of scope.

=cut

    sub DESTROY {
        my $self = shift;
        foreach ( keys %{$fields} ) {
            delete $fields->{$_}->[$$self];
        }
        $self->SUPER::DESTROY;
        return 1;
    }

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $datum->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _container { _MATRIX_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $datum->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _type { _DATUM_ }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

This object inherits from L<Bio::Phylo>, so the methods defined
therein are also applicable to L<Bio::Phylo::Matrices::Datum> objects.

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

$Id: Datum.pm,v 1.30 2006/05/19 02:08:56 rvosa Exp $

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

}
1;
