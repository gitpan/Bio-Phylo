package Bio::Phylo::Matrices::Datum;
use vars '@ISA';
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Taxa::TaxonLinker;
use Bio::Phylo::Util::XMLWritable;
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Matrices::TypeSafeData;
use Bio::Phylo::Adaptor;
use Bio::Phylo::Util::CONSTANT qw(:objecttypes looks_like_number);
@ISA = qw(
    Bio::Phylo::Listable 
    Bio::Phylo::Taxa::TaxonLinker 
    Bio::Phylo::Util::XMLWritable
    Bio::Phylo::Matrices::TypeSafeData 
);

{

    my ( %weight, %char, %position, %annotations );
    my @fields = ( \%weight, \%char, \%position, \%annotations );

=head1 NAME

Bio::Phylo::Matrices::Datum - The character state sequence object.

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
        # could be child class
        my $class = shift;
        
        # notify user
        $class->info("constructor called for '$class'");
        
        # go up inheritance tree, eventually get an ID
        my $self = $class->SUPER::new( '-type' => 'standard', @_ );
        
        # adapt (or not, if $Bio::Phylo::COMPAT is not set)
        return Bio::Phylo::Adaptor->new( $self );
    }

=back

=head2 MUTATORS

=over

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
        my $id = $self->get_id;
        if ( defined $weight && looks_like_number $weight ) {
            $weight{$id} = $weight;
        }
        elsif ( defined $weight && ! looks_like_number $weight ) {
            Bio::Phylo::Util::Exceptions::BadNumber->throw(
                'error' => 'Not a number!',
            );
        }
        else {
            $weight{$id} = 1;
        }
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
        if ( not UNIVERSAL::isa( $char, 'ARRAY' ) ) {
            my $array = $self->get_type_object->split( $char );
            $char{ $self->get_id } = $array;
        }
        else {
            $char{ $self->get_id } = $char;
        }
        $self->validate;
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
        if ( looks_like_number $pos && $pos >= 1 && $pos / int($pos) == 1 ) {
            $position{ $self->get_id } = $pos;
        }
        else {
            Bio::Phylo::Util::Exceptions::BadNumber->throw(
                'error' => "'$pos' not a positive integer!",
            );
        }
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
            my $id = $self->get_id;
            if ( $i > ( $self->get_position + $self->get_length ) || $i < $self->get_position ) {
                Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                    error => "Specified char ($i) does not exist!" );
            }
            if ( exists $opt{'-annotation'} ) {
                my $note = $opt{'-annotation'};
                $annotations{$id}->[$i] = {} if !$annotations{$id}->[$i];
                while ( my ( $k, $v ) = each %{$note} ) {
                    $annotations{$id}->[$i]->{$k} = $v;
                }
            }
            else {
                $annotations{$id}->[$i] = undef;
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
            my $id = $self->get_id;
            for my $i ( 0 .. $#_ ) {
                if ( not exists $char{$id}->[$i] ) {
                    Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                        error => "Specified char ($i) does not exist!" );
                }
                else {
                    if ( ref $_[$i] eq 'HASH' ) {
                        $annotations{$id}->[$i] = {}
                          if !$annotations{$id}->[$i];
                        while ( my ( $k, $v ) = each %{ $_[$i] } ) {
                            $annotations{$id}->[$i]->{$k} = $v;
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
        my $weight = $weight{ $self->get_id };
        return defined $weight ? $weight : 1;
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
        my $id = $self->get_id;
        if ( $char{$id} ) {
            return wantarray ? @{ $char{$id} } : $self->get_type_object->join( $char{$id} );
        }
        else {
            return wantarray ? () : '';
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
        my $pos = $position{ $self->get_id };
        return defined $pos ? $pos : 1;
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
        my $id = $self->get_id;
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
            if ( $i < $self->get_position || $i > ( $self->get_position + $self->get_length ) ) {
                Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                    error => "Specified char ($i) does not exist!", );
            }
            if ( exists $opt{'-key'} ) {
                return $annotations{$id}->[$i]->{ $opt{'-key'} };
            }
            else {
                return $annotations{$id}->[$i];
            }
        }
        else {
            return $annotations{$id};
        }
    }

=item get_length()

 Type    : Accessor
 Title   : get_length
 Usage   : my $length = $datum->get_length;
 Function: Retrieves a datum's length.
 Returns : a SCALAR integer.
 Args    : NONE

=cut

    sub get_length {
        my $self = shift;
        my @chars = $self->get_char;
        return scalar @chars;
    }

=back

=head2 METHODS

=over

=item reverse()

 Type    : Method
 Title   : reverse
 Usage   : $datum->reverse;
 Function: Reverses a datum's contained characters
 Returns : Returns modified $datum
 Args    : NONE

=cut

    sub reverse {
        my $self = shift;
        my @char = $self->get_char;
        my @reversed = reverse( @char );
        $self->set_char( \@reversed );
    }

=item concat()

 Type    : Method
 Title   : reverse
 Usage   : $datum->concat($datum1);
 Function: Appends $datum1 to $datum
 Returns : Returns modified $datum
 Args    : NONE

=cut

    sub concat {
        my ( $self, @data ) = @_;
        $self->info("concatenating objects");
        my @newchars;
        my @self_chars = $self->get_char;
        my $self_i = $self->get_position - 1;
        my $self_j = $self->get_length - 1 + $self_i;
        @newchars[ $self_i .. $self_j ] = @self_chars;
        for my $datum ( @data ) {
            my @chars = $datum->get_char;
            my $i = $datum->get_position - 1;
            my $j = $datum->get_length - 1 + $i;
            @newchars[ $i .. $j ] = @chars;
        }
        my $missing = $self->get_missing;
        for my $i ( 0 .. $#newchars ) {
            $newchars[$i] = $missing if ! defined $newchars[$i];
        }
        $self->set_char( \@newchars );
    }

=item validate()

 Type    : Method
 Title   : validate
 Usage   : $datum->validate;
 Function: Validates character data contained by $datum
 Returns : True or throws Bio::Phylo::Util::Exceptions::InvalidData
 Args    : NONE

=cut

    sub validate {
        my $self = shift;
        if ( ! $self->get_type_object->is_valid( $self ) ) {
            Bio::Phylo::Util::Exceptions::InvalidData->throw(
                'error' => 'Invalid data!',
            );
        }
    }

=item copy_atts()

 Not implemented!

=cut

    sub copy_atts {}

=item complement()

 Not implemented!

=cut

    sub complement {}

=item slice()

 Not implemented!

=cut

    sub slice {}    

        
    sub _type { _DATUM_ }
        
    sub _container { _MATRIX_ }
        
    sub _cleanup {
        my $self = shift;
        $self->info("cleaning up '$self'");
        my $id = $self->get_id;
        for my $field ( @fields ) {
            delete $field->{$id};
        }
    }
        
}

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

$Id: Datum.pm 3386 2007-03-24 16:22:25Z rvosa $

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