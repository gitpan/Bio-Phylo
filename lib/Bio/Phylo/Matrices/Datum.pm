# $Id: Datum.pm 4265 2007-07-20 14:14:44Z rvosa $
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
use Bio::Phylo::Util::Logger;

@ISA = qw(
    Bio::Phylo::Matrices::TypeSafeData 
    Bio::Phylo::Taxa::TaxonLinker 
);

{

	my $logger = Bio::Phylo::Util::Logger->new;
	
	my $TYPE_CONSTANT      = _DATUM_;
	my $CONTAINER_CONSTANT = _MATRIX_;

    my @fields = \( 
    	my %weight, 
    	my %char, 
    	my %position, 
    	my %annotations, 
    );

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

Datum object constructor.

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
           -pos    => 2,


=cut

    sub new {
        # could be child class
        my $class = shift;
        
        # notify user
        $logger->info("constructor called for '$class'");
        
        # go up inheritance tree, eventually get an ID
        my $self = $class->SUPER::new( '-type' => 'standard', @_ );
        
        # adapt (or not, if $Bio::Phylo::COMPAT is not set)
        return Bio::Phylo::Adaptor->new( $self );
    }

=back

=head2 MUTATORS

=over

=item set_weight()

Sets invocant weight.

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

Sets character state(s)

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
               * an array of characters;
 Comments: Note that on assigning characters to a datum,
           previously set annotations are removed.

=cut

    sub set_char { 
        my $self = shift;
        my @data;
        for my $arg ( @_ ) {
        	if ( UNIVERSAL::isa( $arg, 'ARRAY') ) {
        		push @data, @{ $arg };
        	}
        	else {
        		push @data, @{ $self->get_type_object->split( $arg ) };
        	}
        }
        if ( $self->can_contain( @data ) ) {
        	$self->clear();
        	$self->insert( $_, 1 ) for @data;
        }
        else {
        	Bio::Phylo::Util::Exceptions::InvalidData->throw(
                'error' => 'Invalid data!',
            );
        }
        return $self;
    }

=item set_position()

Set invocant starting position.

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

Sets single annotation.

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

Sets list of annotations.

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

Gets invocant weight.

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

Gets characters.

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
        my @data = @{ $self->get_entities };
        if ( @data ) {
            return wantarray ? @data : $self->get_type_object->join( \@data );
        }
        else {
            return wantarray ? () : '';
        }
    }

=item get_position()

Gets invocant starting position.

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

Retrieves character annotation (hashref).

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

Gets invocant number of characters.

 Type    : Accessor
 Title   : get_length
 Usage   : my $length = $datum->get_length;
 Function: Retrieves a datum's length.
 Returns : a SCALAR integer.
 Args    : NONE

=cut

    sub get_length {
        my $self = shift;
        my @char = $self->get_char;
        $logger->info( "Chars: @char" );
        my $length = 0;
        if ( my $matrix = $self->_get_container ) {
        	for my $datum ( @{ $matrix->get_entities } ) {
        		my $thislength = scalar @{ $datum->get_entities };
        		$length = $thislength if $thislength > $length;
        	}
        	return $length;
        }
        else {
        	return $self->last_index + 1;
        }
    }

=item get_by_index()

Gets state at argument index.

 Type    : Accessor
 Title   : get_by_index
 Usage   : my $val = $datum->get_by_index($i);
 Function: Retrieves state at index $i.
 Returns : a character state.
 Args    : INT

=cut
    
    sub get_by_index {
    	my ( $self, $index ) = @_;
    	my $val = $self->SUPER::get_by_index( $index );
    	return defined $val ? $val : $self->get_type_object->get_missing;
    }

=back

=head2 TESTS

=over

=item can_contain()

Tests if invocant can contain argument.

 Type    : Test
 Title   : can_contain
 Usage   : &do_something if $datum->can_contain( @args );
 Function: Tests if $datum can contain @args
 Returns : BOOLEAN
 Args    : One or more arguments as can be provided to set_char

=cut

	sub can_contain {
		my $self = shift;
		if ( my $obj = $self->get_type_object ) {
			return $obj->is_valid( @_ );
		}	
		else {
			Bio::Phylo::Util::Exceptions::Generic->throw
		}
	}

=back

=head2 METHODS

=over

=item reverse()

Reverses contents.

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

Appends argument to invocant.

 Type    : Method
 Title   : reverse
 Usage   : $datum->concat($datum1);
 Function: Appends $datum1 to $datum
 Returns : Returns modified $datum
 Args    : NONE

=cut

    sub concat {
        my ( $self, @data ) = @_;
        $logger->info("concatenating objects");
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

Validates invocant data contents.

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

    sub slice {
    	my $self  = shift;
    	my $start = int $_[0];
    	my $end   = int $_[1];
    	my @chars = $self->get_char;
    	my $pos   = $self->get_position;
    	my $slice - $self->copy_atts;
    }    
        
    sub _type { $TYPE_CONSTANT }
        
    sub _container { $CONTAINER_CONSTANT }
        
    sub _cleanup {
        my $self = shift;
        $logger->info("cleaning up '$self'");
        my $id = $self->get_id;
        for my $field ( @fields ) {
            delete $field->{$id};
        }
    }
    
    sub FETCHSIZE {
    	my $self = shift;
    	if ( my $matrix = $self->_get_container ) {
    		return $matrix->get_ntax - 1;
    	}
    	else {
    		return $self->get_length - 1;
    	}
    }
    
    sub FETCH {
        my ( $self, $index ) = @_;
        my $val = $self->get_by_index( $index );
        return defined $val ? $val : $self->get_type_object->get_missing;
    }
        
}

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Taxa::TaxonLinker>

This object inherits from L<Bio::Phylo::Taxa::TaxonLinker>, so the methods
defined therein are also applicable to L<Bio::Phylo::Matrices::Datum> objects.

=item L<Bio::Phylo::Matrices::TypeSafeData>

This object inherits from L<Bio::Phylo::Matrices::TypeSafeData>, so the methods
defined therein are also applicable to L<Bio::Phylo::Matrices::Datum> objects.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>.

=back

=head1 REVISION

 $Id: Datum.pm 4265 2007-07-20 14:14:44Z rvosa $

=cut

1;