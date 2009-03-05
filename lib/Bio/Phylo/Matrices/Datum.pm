# $Id: Datum.pm 844 2009-03-05 00:07:26Z rvos $
package Bio::Phylo::Matrices::Datum;
use vars '@ISA';
use strict;
use Bio::Phylo::Taxa::TaxonLinker;
use Bio::Phylo::Util::Exceptions 'throw';
use Bio::Phylo::Matrices::TypeSafeData;
use Bio::Phylo::Util::CONSTANT qw(:objecttypes looks_like_number looks_like_hash);
use UNIVERSAL qw(isa can);
@ISA = qw(
  Bio::Phylo::Matrices::TypeSafeData
  Bio::Phylo::Taxa::TaxonLinker
);

eval { require Bio::Seq };
if ( not $@ ) {
	push @ISA, 'Bio::Seq';
}
else {
	undef($@);
}
my $LOADED_WRAPPERS = 0;

{
    my $logger             = __PACKAGE__->get_logger;
    my $TYPE_CONSTANT      = _DATUM_;
    my $CONTAINER_CONSTANT = _MATRIX_;
    my @fields             = \( my ( %weight, %position, %annotations ) );

=head1 NAME

Bio::Phylo::Matrices::Datum - Character state sequence

=head1 SYNOPSIS

 use Bio::Phylo::Factory;
 my $fac = Bio::Phylo::Factory->new;

 # instantiating a datum object...
 my $datum = $fac->create_datum(
    -name   => 'Tooth comb size,
    -type   => 'STANDARD',
    -desc   => 'number of teeth in lower jaw comb',
    -pos    => 1,
    -weight => 2,
    -char   => [ 6 ],
 );

 # ...and linking it to a taxon object
 my $taxon = $fac->create_taxon(
     -name => 'Lemur_catta'
 );
 $datum->set_taxon( $taxon );

 # instantiating a matrix...
 my $matrix = $fac->create_matrix;

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
        
		if ( not $LOADED_WRAPPERS ) {
			eval do { local $/; <DATA> };
			die $@ if $@;
			$LOADED_WRAPPERS++;
		}        

        # go up inheritance tree, eventually get an ID
        my $self = $class->SUPER::new( '-tag' => 'row', @_ );
        return $self;
    }

=item new_from_bioperl()

Datum constructor from Bio::Seq argument.

 Type    : Constructor
 Title   : new_from_bioperl
 Usage   : my $datum = 
           Bio::Phylo::Matrices::Datum->new_from_bioperl($seq);
 Function: Instantiates a 
           Bio::Phylo::Matrices::Datum object.
 Returns : A Bio::Phylo::Matrices::Datum object.
 Args    : A Bio::Seq (or similar) object

=cut
    
    sub new_from_bioperl {
    	my ( $class, $seq, @args ) = @_;
    	my $type = $seq->alphabet || $seq->_guess_alphabet || 'dna';
    	my $self = $class->new( '-type' => $type, @args );
        
        # copy seq string
        my $seqstring = $seq->seq;
        if ( $seqstring and $seqstring =~ /\S/ ) {
        	eval { $self->set_char( $seqstring ) };
        	if ( $@ and UNIVERSAL::isa($@,'Bio::Phylo::Util::Exceptions::InvalidData') ) {
        		$logger->error(
        			"\nAn exception of type Bio::Phylo::Util::Exceptions::InvalidData was caught\n\n".
        			$@->description                                                                  .
        			"\n\nThe BioPerl sequence object contains invalid data ($seqstring)\n"           .
        			"I cannot store this string, I will continue instantiating an empty object.\n"   .
        			"---------------------------------- STACK ----------------------------------\n"  .
        			$@->trace->as_string                                                             .
        			"\n--------------------------------------------------------------------------"
        		);
        	}
        }                
        
        # copy name
        my $name = $seq->display_id;
        $self->set_name( $name ) if defined $name;
                
        # copy desc
        my $desc = $seq->desc;   
        $self->set_desc( $desc ) if defined $desc;   
        for my $field ( qw(start end strand) ) {
        	$self->$field( $seq->$field );
        } 	
        return $self;
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
        my $id = $$self;
        $weight = 1 if not defined $weight;
        if ( looks_like_number $weight ) {
            $weight{$id} = $weight;
            $logger->info("setting weight '$weight'");
        }
        elsif ( !looks_like_number $weight ) {
            throw 'BadNumber' => 'Not a number!';
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
        my $name = $self->get_internal_name;
        my $length = ref $_[0] ? join( '', @{ $_[0] } ) : join( '', @_ );
        $logger->info("setting $name $length chars '@_'");
        my @data;
        for my $arg (@_) {
            if ( isa( $arg, 'ARRAY' ) ) {
                push @data, @{$arg};
            }
            else {
                push @data, @{ $self->get_type_object->split($arg) };
            }
        }
        my $missing  = $self->get_missing;
        my $position = $self->get_position;
        for ( 1 .. $position - 1 ) {
            unshift @data, $missing;
        }
        my @char = @{ $self->get_entities }; # store old data for rollback
        eval {
            $self->clear;
            $self->insert( @data );
        };
        if ( $@ ) {
        	$self->clear;
        	eval { $self->insert(@char) };
			undef($@);
			throw 'InvalidData' => sprintf(
					'Invalid data for row %s (type %s: %s)',
					$self->get_internal_name, $self->get_type, join( ' ', @data )
			);
		}
		$self->set_annotations;
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
        $pos = 1 if not defined $pos;
        if ( looks_like_number $pos && $pos >= 1 && $pos / int($pos) == 1 ) {
            $position{$$self} = $pos;
            $logger->info("setting position '$pos'");
        }
        else {
        	throw 'BadNumber' => "'$pos' not a positive integer!";
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
            my %opt = looks_like_hash @_;
            if ( not exists $opt{'-char'} ) {
                throw 'BadArgs' => "No character to annotate specified!";
            }
            my $i   = $opt{'-char'};
            my $id  = $$self;
            my $pos = $self->get_position;
            my $len = $self->get_length;
            if ( $i > ( $pos + $len ) || $i < $pos ) {
                throw 'OutOfBounds' => "Specified char ($i) does not exist!";
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
        	throw 'BadArgs' => "No character to annotate specified!";
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
           the character list. If no
           argument given, annotations
           are reset.
 Comments: Use this method to annotate
           multiple characters. To
           annotate a single character,
           use 'set_annotation' (see
           above).

=cut

    sub set_annotations {
        my $self = shift;
        my @anno;
        if ( scalar @_ == 1 and UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
        	@anno = @{ $_[0] };
        }
        else {
			@anno = @_;
        }
        if ( @anno ) {
            my $id = $$self;
            my $max_index = $self->get_length - 1;
            for my $i ( 0 .. $#anno ) {
                if ( $i > $max_index ) {
                    throw 'OutOfBounds' => "Specified char ($i) does not exist!";
                }
                else {
                    if ( isa( $anno[$i], 'HASH' ) ) {
                        $annotations{$id}->[$i] = {}
                          if !$annotations{$id}->[$i];
                        while ( my ( $k, $v ) = each %{ $anno[$i] } ) {
                            $annotations{$id}->[$i]->{$k} = $v;
                        }
                    }
                    else {
                        next;
                    }
                }
            }
        }
        else {
        	$annotations{$$self} = [];
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
        my $self   = shift;
        my $weight = $weight{$$self};
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
        if (@data) {
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
        my $pos  = $position{$$self};
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
        my $id   = $$self;
        if (@_) {
            my %opt = looks_like_hash @_;
            if ( not exists $opt{'-char'} ) {
            	throw 'BadArgs' => "No character to return annotation for specified!";
            }
            my $i   = $opt{'-char'};
            my $pos = $self->get_position;
            my $len = $self->get_length;
            if ( $i < $pos || $i > ( $pos + $len ) ) {
            	throw 'OutOfBounds' => "Specified char ($i) does not exist!";
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

=item get_annotations()

Retrieves character annotations (array ref).

 Type    : Accessor
 Title   : get_annotations
 Usage   : my @anno = @{ $datum->get_annotation() };
 Function: Retrieves annotations
 Returns : ARRAY
 Args    : NONE

=cut

    sub get_annotations {
        my $self = shift;
        return $annotations{$$self} || [];
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
#        $logger->info("Chars: @char");
        if ( my $matrix = $self->_get_container ) {
            return $matrix->get_nchar;
        }
        else {
            return scalar( @{ $self->get_entities } ) + $self->get_position - 1;
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
        my $offset = $self->get_position - 1;
        return $self->get_type_object->get_missing if $offset > $index;
        my $val = $self->SUPER::get_by_index( $index - $offset );
        return defined $val ? $val : $self->get_type_object->get_missing;
    }
    
=item get_index_of()

Returns the index of the first occurrence of the 
state observation in the datum or undef if the datum 
doesn't contain the argument

 Type    : Generic query
 Title   : get_index_of
 Usage   : my $i = $datum->get_index_of($state)
 Function: Returns the index of the first occurrence of the 
           state observation in the datum or undef if the datum 
		   doesn't contain the argument
 Returns : An index or undef
 Args    : A contained object

=cut

	sub get_index_of {
		my ( $self, $obj ) = @_;
		my $is_numerical = $self->get_type =~ m/^(Continuous|Standard|Restriction)$/;
		my $i = 0;
		for my $ent ( @{ $self->get_entities } ) {
			if ( $is_numerical ) {
				return $i if $obj == $ent;
			}
			else {
				return $i if $obj eq $ent;
			}
			$i++;
		}
		return undef;
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
        my @data = @_;
        if ( my $obj = $self->get_type_object ) {
            if ( $obj->isa('Bio::Phylo::Matrices::Datatype::Mixed') ) {
                my @split;
                for my $datum (@data) {
                    if ( can( $datum, 'get_char' ) ) {
                        my @tmp = $datum->get_char();
                        my $i   = $datum->get_position() - 1;
                        for (@tmp) {
                            $split[ $i++ ] = $_;
                        }
                    }
                    elsif ( isa( $datum, 'ARRAY' ) ) {
                        push @split, @{$datum};
                    }
                    else {
                        my $subtype = $obj->get_type_for_site( scalar(@split) );
                        push @split, @{ $subtype->split($datum) };
                    }
                }

                #return 1;
                for my $i ( 1 .. scalar(@split) ) {
                    my $subtype = $obj->get_type_for_site( $i - 1 );
                    next if $subtype->is_valid( $split[ $i - 1 ] );
                    throw 'InvalidData' => sprintf(
                            'Invalid char %s at pos %s for type %s',
                            $split[ $i - 1 ],
                            $i, $subtype->get_type,
                    );
                }
                return 1;
            }
            else {
                return $obj->is_valid(@data);
            }
        }
        else {
            throw 'API' => "No associated type object found,\n" 
                         . "this is a bug - please report - thanks";
        }
    }

=back

=head2 CALCULATIONS

=over

=item calc_state_counts()

Calculates occurrences of states.

 Type    : Calculation
 Title   : calc_state_counts
 Usage   : my %counts = %{ $datum->calc_state_counts };
 Function: Calculates occurrences of states.
 Returns : Hashref: keys are states, values are counts
 Args    : Optional - one or more states to focus on

=cut

	sub calc_state_counts {
		my $self = shift;
		my %counts;
		if ( @_ ) {
			my %focus = map { $_ => 1 } @_;
			my @char = $self->get_char;
			for my $c ( @char ) {
				if ( exists $focus{$c} ) {
					if ( not exists $counts{$c} ) {
						$counts{$c} = 1;
					}
					else {
						$counts{$c}++;
					}
				}
			}
		}
		else {
			my @char = $self->get_char;
			for my $c ( @char ) {
				if ( not exists $counts{$c} ) {
					$counts{$c} = 1;
				}
				else {
					$counts{$c}++;
				}
			}		
		}
		return \%counts;
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
        my $self     = shift;
        my @char     = $self->get_char;
        my @reversed = reverse(@char);
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
        my $self_i     = $self->get_position - 1;
        my $self_j     = $self->get_length - 1 + $self_i;
        @newchars[ $self_i .. $self_j ] = @self_chars;
        for my $datum (@data) {
            my @chars = $datum->get_char;
            my $i     = $datum->get_position - 1;
            my $j     = $datum->get_length - 1 + $i;
            @newchars[ $i .. $j ] = @chars;
        }
        my $missing = $self->get_missing;
        for my $i ( 0 .. $#newchars ) {
            $newchars[$i] = $missing if !defined $newchars[$i];
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
        if ( !$self->get_type_object->is_valid($self) ) {
            throw 'InvalidData' => 'Invalid data!';
        }
    }

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : None.
 Comments: Cloning is currently experimental, use with caution.

=cut

	sub clone {
		my $self = shift;
		my %subs = @_;
		
		# some extra logic to copy characters from source to target
		$subs{'set_char'} = 0;
		
		# some logic to copy annotations
		$subs{'set_annotation'} = 0;
		
		return $self->SUPER::clone(%subs);
	
	}

=item to_xml()

Serializes datum to nexml format.

 Type    : Format convertor
 Title   : to_xml
 Usage   : my $xml = $datum->to_xml;
 Function: Converts datum object into a nexml element structure.
 Returns : Nexml block (SCALAR).
 Args    : -chars   => [] # optional, an array ref of character IDs
           -states  => {} # optional, a hash ref of state IDs
           -symbols => {} # optional, a hash ref of symbols

=cut

	sub to_xml {
		my $self = shift;
		my %args = looks_like_hash @_;
		my $char_ids = $args{'-chars'};
		my $state_ids = $args{'-states'};
		if ( my $taxon = $self->get_taxon ) {
			$self->set_attributes( 'otu' => $taxon->get_xml_id );
		}
		my @char = $self->get_char;
		my ( $missing, $gap ) = ( $self->get_missing, $self->get_gap );
		my $xml = $self->get_xml_tag;
		
		if ( not $args{'-compact'} ) {
			for my $i ( 0 .. $#char ) {
				if ( $missing ne $char[$i] and $gap ne $char[$i] ) {
					my ( $c, $s );
					if ( $char_ids and $char_ids->[$i] ) {
						$c = $char_ids->[$i];
					}
					else {
						$c = $i;
					}
					if ( $state_ids and $state_ids->{uc $char[$i]} ) {
						$s = $state_ids->{uc $char[$i]};
					}
					else {
						$s = uc $char[$i];
					}
					$xml .= sprintf('<cell char="%s" state="%s" />', $c, $s);
				}
			}
		}
		else {
			my @tmp = map { uc $_ } @char;
			my $seq = $self->get_type_object->join(\@tmp);
			$xml .= '<seq>' . $seq . '</seq>';	
		}
		
		$xml .= sprintf('</%s>', $self->get_tag);
		return $xml;
	}

=item copy_atts()

 Not implemented!

=cut

    sub copy_atts { }    # XXX not implemented

=item complement()

 Not implemented!

=cut

    sub complement { }   # XXX not implemented

=item slice()

 Not implemented!

=cut

    sub slice {          # XXX not implemented
        my $self  = shift;
        my $start = int $_[0];
        my $end   = int $_[1];
        my @chars = $self->get_char;
        my $pos   = $self->get_position;
        my $slice - $self->copy_atts;
    }
    sub _type      { $TYPE_CONSTANT }
    sub _container { $CONTAINER_CONSTANT }

    sub _cleanup {
        my $self = shift;
        $logger->info("cleaning up '$self'");
        if ( defined( my $id = $$self ) ) {
	        for my $field (@fields) {
	            delete $field->{$id};
	        }
        }
    }

}

=back

=cut

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:42 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Matrices::Datum inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Matrices::Datum also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::Matrices::TypeSafeData

Bio::Phylo::Matrices::Datum inherits from superclass L<Bio::Phylo::Matrices::TypeSafeData>. 
Below are the public methods (if any) from this superclass.

=over

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : NONE

=item get_gap()

Get gap symbol.

 Type    : Accessor
 Title   : get_gap
 Usage   : my $gap = $obj->get_gap;
 Function: Returns the object's gap symbol
 Returns : A string
 Args    : None

=item get_lookup()

Get ambiguity lookup table.

 Type    : Accessor
 Title   : get_lookup
 Usage   : my $lookup = $obj->get_lookup;
 Function: Returns the object's lookup hash
 Returns : A hash reference
 Args    : None

=item get_missing()

Get missing data symbol.

 Type    : Accessor
 Title   : get_missing
 Usage   : my $missing = $obj->get_missing;
 Function: Returns the object's missing data symbol
 Returns : A string
 Args    : None

=item get_type()

Get data type.

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $obj->get_type;
 Function: Returns the object's datatype
 Returns : A string
 Args    : None

=item get_type_object()

Get data type object.

 Type    : Accessor
 Title   : get_type_object
 Usage   : my $obj = $obj->get_type_object;
 Function: Returns the object's linked datatype object
 Returns : A subclass of Bio::Phylo::Matrices::Datatype
 Args    : None

=item new()

TypeSafeData constructor.

 Type    : Constructor
 Title   : new
 Usage   : No direct usage, is called by child class;
 Function: Instantiates a Bio::Phylo::Matrices::TypeSafeData
 Returns : a Bio::Phylo::Matrices::TypeSafeData child class
 Args    : -type        => (data type - required)
           Optional:
           -missing     => (the symbol for missing data)
           -gap         => (the symbol for gaps)
           -lookup      => (a character state lookup hash)
           -type_object => (a datatype object)

=item set_gap()

Set gap data symbol.

 Type    : Mutator
 Title   : set_gap
 Usage   : $obj->set_gap('-');
 Function: Sets the symbol for gaps
 Returns : Modified object.
 Args    : Argument must be a single
           character, default is '-'

=item set_lookup()

Set ambiguity lookup table.

 Type    : Mutator
 Title   : set_lookup
 Usage   : $obj->set_gap($hashref);
 Function: Sets the symbol for gaps
 Returns : Modified object.
 Args    : Argument must be a hash
           reference that maps allowed
           single character symbols
           (including ambiguity symbols)
           onto the equivalent set of
           non-ambiguous symbols

=item set_missing()

Set missing data symbol.

 Type    : Mutator
 Title   : set_missing
 Usage   : $obj->set_missing('?');
 Function: Sets the symbol for missing data
 Returns : Modified object.
 Args    : Argument must be a single
           character, default is '?'

=item set_type()

Set data type.

 Type    : Mutator
 Title   : set_type
 Usage   : $obj->set_type($type);
 Function: Sets the object's datatype.
 Returns : Modified object.
 Args    : Argument must be a string, one of
           continuous, custom, dna, mixed,
           protein, restriction, rna, standard

=item set_type_object()

Set data type object.

 Type    : Mutator
 Title   : set_type_object
 Usage   : $obj->set_gap($obj);
 Function: Sets the datatype object
 Returns : Modified object.
 Args    : Argument must be a subclass
           of Bio::Phylo::Matrices::Datatype

=item validate()

Validates the object's contents

 Type    : Interface method
 Title   : validate
 Usage   : $obj->validate
 Function: Validates the object's contents
 Returns : True or throws Bio::Phylo::Util::Exceptions::InvalidData
 Args    : None
 Comments: This is an interface method, i.e. this class doesn't
           implement the method, child classes have to

=back

=head2 SUPERCLASS Bio::Phylo::Listable

Bio::Phylo::Matrices::Datum inherits from superclass L<Bio::Phylo::Listable>. 
Below are the public methods (if any) from this superclass.

=over

=item add_set()

 Type    : Mutator
 Title   : add_set
 Usage   : $obj->add_set($set)
 Function: Associates a Bio::Phylo::Set object with the invocant
 Returns : Invocant
 Args    : A Bio::Phylo::Set object

=item add_to_set()

 Type    : Mutator
 Title   : add_to_set
 Usage   : $listable->add_to_set($obj,$set);
 Function: Adds first argument to the second argument
 Returns : Invocant
 Args    : $obj - an object to add to $set
           $set - the Bio::Phylo::Set object to add to
 Notes   : this method assumes that $obj is already 
           part of the invocant. If that assumption is
           violated a warning message is printed.

=item can_contain()

Tests if argument can be inserted in invocant.

 Type    : Test
 Title   : can_contain
 Usage   : &do_something if $listable->can_contain( $obj );
 Function: Tests if $obj can be inserted in $listable
 Returns : BOOL
 Args    : An $obj to test

=item clear()

Empties container object.

 Type    : Object method
 Title   : clear
 Usage   : $obj->clear();
 Function: Clears the container.
 Returns : A Bio::Phylo::Listable object.
 Args    : Note.
 Note    : 

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : None.
 Comments: Cloning is currently experimental, use with caution.

=item contains()

Tests whether the invocant object contains the argument object.

 Type    : Test
 Title   : contains
 Usage   : if ( $obj->contains( $other_obj ) ) {
               # do something
           }
 Function: Tests whether the invocant object 
           contains the argument object
 Returns : BOOLEAN
 Args    : A Bio::Phylo::* object

=item cross_reference()

The cross_reference method links node and datum objects to the taxa they apply
to. After crossreferencing a matrix with a taxa object, every datum object has
a reference to a taxon object stored in its C<$datum-E<gt>get_taxon> field, and
every taxon object has a list of references to datum objects stored in its
C<$taxon-E<gt>get_data> field.

 Type    : Generic method
 Title   : cross_reference
 Usage   : $obj->cross_reference($taxa);
 Function: Crossreferences the entities 
           in the invocant with names 
           in $taxa
 Returns : string
 Args    : A Bio::Phylo::Taxa object
 Comments:

=item current()

Returns the current focal element of the listable object.

 Type    : Iterator
 Title   : current
 Usage   : my $current_obj = $obj->current;
 Function: Retrieves the current focal 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item current_index()

Returns the current internal index of the invocant.

 Type    : Generic query
 Title   : current_index
 Usage   : my $last_index = $obj->current_index;
 Function: Returns the current internal 
           index of the invocant.
 Returns : An integer
 Args    : none.

=item delete()

Deletes argument from invocant object.

 Type    : Object method
 Title   : delete
 Usage   : $obj->delete($other_obj);
 Function: Deletes an object from its container.
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.
 Note    : Be careful with this method: deleting 
           a node from a tree like this will 
           result in undefined references in its 
           neighbouring nodes. Its children will 
           have their parent reference become 
           undef (instead of pointing to their 
           grandparent, as collapsing a node would 
           do). The same is true for taxon objects 
           that reference datum objects: if the 
           datum object is deleted from a matrix 
           (say), the taxon will now hold undefined 
           references.

=item first()

Jumps to the first element contained by the listable object.

 Type    : Iterator
 Title   : first
 Usage   : my $first_obj = $obj->first;
 Function: Retrieves the first 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item get_by_index()

Gets element defined by argument index from invocant container.

 Type    : Query
 Title   : get_by_index
 Usage   : my $contained_obj = $obj->get_by_index($i);
 Function: Retrieves the i'th entity 
           from a listable object.
 Returns : An entity stored by a listable 
           object (or array ref for slices).
 Args    : An index or range. This works 
           the way you dereference any perl
           array including through slices, 
           i.e. $obj->get_by_index(0 .. 10)>
           $obj->get_by_index(0, -1) 
           and so on.
 Comments: Throws if out-of-bounds

=item get_by_name()

Gets first element that has argument name

 Type    : Visitor predicate
 Title   : get_by_name
 Usage   : my $found = $obj->get_by_name('foo');
 Function: Retrieves the first contained object
           in the current Bio::Phylo::Listable 
           object whose name is 'foo'
 Returns : A Bio::Phylo::* object.
 Args    : A name (string)

=item get_by_regular_expression()

Gets elements that match regular expression from invocant container.

 Type    : Visitor predicate
 Title   : get_by_regular_expression
 Usage   : my @objects = @{ 
               $obj->get_by_regular_expression(
                    -value => $method,
                    -match => $re
            ) };
 Function: Retrieves the data in the 
           current Bio::Phylo::Listable 
           object whose $method output 
           matches $re
 Returns : A list of Bio::Phylo::* objects.
 Args    : -value => any of the string 
                     datum props (e.g. 'get_type')
           -match => a compiled regular 
                     expression (e.g. qr/^[D|R]NA$/)

=item get_by_value()

Gets elements that meet numerical rule from invocant container.

 Type    : Visitor predicate
 Title   : get_by_value
 Usage   : my @objects = @{ $obj->get_by_value(
              -value => $method,
              -ge    => $number
           ) };
 Function: Iterates through all objects 
           contained by $obj and returns 
           those for which the output of 
           $method (e.g. get_tree_length) 
           is less than (-lt), less than 
           or equal to (-le), equal to 
           (-eq), greater than or equal to 
           (-ge), or greater than (-gt) $number.
 Returns : A reference to an array of objects
 Args    : -value => any of the numerical 
                     obj data (e.g. tree length)
           -lt    => less than
           -le    => less than or equals
           -eq    => equals
           -ge    => greater than or equals
           -gt    => greater than

=item get_entities()

Returns a reference to an array of objects contained by the listable object.

 Type    : Generic query
 Title   : get_entities
 Usage   : my @entities = @{ $obj->get_entities };
 Function: Retrieves all entities in the invocant.
 Returns : A reference to a list of Bio::Phylo::* 
           objects.
 Args    : none.

=item get_index_of()

Returns the index of the argument in the list,
or undef if the list doesn't contain the argument

 Type    : Generic query
 Title   : get_index_of
 Usage   : my $i = $listable->get_index_of($obj)
 Function: Returns the index of the argument in the list,
           or undef if the list doesn't contain the argument
 Returns : An index or undef
 Args    : A contained object

=item get_logger()

Gets a logger object.

 Type    : Accessor
 Title   : get_logger
 Usage   : my $logger = $obj->get_logger;
 Function: Returns a Bio::Phylo::Util::Logger object
 Returns : Bio::Phylo::Util::Logger
 Args    : None

=item get_sets()

 Type    : Accessor
 Title   : get_sets
 Usage   : my @sets = @{ $obj->get_sets() };
 Function: Retrieves all associated Bio::Phylo::Set objects
 Returns : Invocant
 Args    : None

=item insert()

Pushes an object into its container.

 Type    : Object method
 Title   : insert
 Usage   : $obj->insert($other_obj);
 Function: Pushes an object into its container.
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.

=item insert_at_index()

Inserts argument object in invocant container at argument index.

 Type    : Object method
 Title   : insert_at_index
 Usage   : $obj->insert_at_index($other_obj, $i);
 Function: Inserts $other_obj at index $i in container $obj
 Returns : A Bio::Phylo::Listable object.
 Args    : A Bio::Phylo::* object.

=item is_in_set()

 Type    : Test
 Title   : is_in_set
 Usage   : @do_something if $listable->is_in_set($obj,$set);
 Function: Returns whether or not the first argument is listed in the second argument
 Returns : Boolean
 Args    : $obj - an object that may, or may not be in $set
           $set - the Bio::Phylo::Set object to query
 Notes   : This method makes two assumptions:
           i) the $set object is associated with the invocant,
              i.e. add_set($set) has been called previously
           ii) the $obj object is part of the invocant
           If either assumption is violated a warning message
           is printed.

=item last()

Jumps to the last element contained by the listable object.

 Type    : Iterator
 Title   : last
 Usage   : my $last_obj = $obj->last;
 Function: Retrieves the last 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item last_index()

Returns the highest valid index of the invocant.

 Type    : Generic query
 Title   : last_index
 Usage   : my $last_index = $obj->last_index;
 Function: Returns the highest valid 
           index of the invocant.
 Returns : An integer
 Args    : none.

=item next()

Returns the next focal element of the listable object.

 Type    : Iterator
 Title   : next
 Usage   : my $next_obj = $obj->next;
 Function: Retrieves the next focal 
           entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item notify_listeners()

Notifies listeners of changed contents.

 Type    : Utility method
 Title   : notify_listeners
 Usage   : $object->notify_listeners;
 Function: Notifies listeners of changed contents.
 Returns : Invocant.
 Args    : NONE.
 Comments:

=item previous()

Returns the previous element of the listable object.

 Type    : Iterator
 Title   : previous
 Usage   : my $previous_obj = $obj->previous;
 Function: Retrieves the previous 
           focal entity in the invocant.
 Returns : A Bio::Phylo::* object
 Args    : none.

=item remove_from_set()

 Type    : Mutator
 Title   : remove_from_set
 Usage   : $listable->remove_from_set($obj,$set);
 Function: Removes first argument from the second argument
 Returns : Invocant
 Args    : $obj - an object to remove from $set
           $set - the Bio::Phylo::Set object to remove from
 Notes   : this method assumes that $obj is already 
           part of the invocant. If that assumption is
           violated a warning message is printed.

=item remove_set()

 Type    : Mutator
 Title   : remove_set
 Usage   : $obj->remove_set($set)
 Function: Removes association between a Bio::Phylo::Set object and the invocant
 Returns : Invocant
 Args    : A Bio::Phylo::Set object

=item set_listener()

Attaches a listener (code ref) which is executed when contents change.

 Type    : Utility method
 Title   : set_listener
 Usage   : $object->set_listener( sub { my $object = shift; } );
 Function: Attaches a listener (code ref) which is executed when contents change.
 Returns : Invocant.
 Args    : A code reference.
 Comments: When executed, the code reference will receive $object
           (the invocant) as its first argument.

=item visit()

Iterates over objects contained by invocant, executes argument
code reference on each.

 Type    : Visitor predicate
 Title   : visit
 Usage   : $obj->visit( 
               sub{ print $_[0]->get_name, "\n" } 
           );
 Function: Implements visitor pattern 
           using code reference.
 Returns : The invocant, possibly modified.
 Args    : a CODE reference.

=back

=head2 SUPERCLASS Bio::Phylo::Util::XMLWritable

Bio::Phylo::Matrices::Datum inherits from superclass L<Bio::Phylo::Util::XMLWritable>. 
Below are the public methods (if any) from this superclass.

=over

=item add_dictionary()

 Type    : Mutator
 Title   : add_dictionary
 Usage   : $obj->add_dictionary($dict);
 Function: Adds a dictionary attachment to the object
 Returns : $self
 Args    : Bio::Phylo::Dictionary

=item get_attributes()

Retrieves attributes for the element.

 Type    : Accessor
 Title   : get_attributes
 Usage   : my %attrs = %{ $obj->get_attributes };
 Function: Gets the xml attributes for the object;
 Returns : A hash reference
 Args    : None.
 Comments: throws ObjectMismatch if no linked taxa object 
           can be found

=item get_dictionaries()

Retrieves the dictionaries for the element.

 Type    : Accessor
 Title   : get_dictionaries
 Usage   : my @dicts = @{ $obj->get_dictionaries };
 Function: Retrieves the dictionaries for the element.
 Returns : An array ref of Bio::Phylo::Dictionary objects
 Args    : None.

=item get_namespaces()

 Type    : Accessor
 Title   : get_namespaces
 Usage   : my %ns = %{ $obj->get_namespaces };
 Function: Retrieves the known namespaces
 Returns : A hash of prefix/namespace key/value pairs, or
           a single namespace if a single, optional
           prefix was provided as argument
 Args    : Optional - a namespace prefix

=item get_tag()

Retrieves tag name for the element.

 Type    : Accessor
 Title   : get_tag
 Usage   : my $tag = $obj->get_tag;
 Function: Gets the xml tag name for the object;
 Returns : A tag name
 Args    : None.

=item get_xml_id()

Retrieves xml id for the element.

 Type    : Accessor
 Title   : get_xml_id
 Usage   : my $id = $obj->get_xml_id;
 Function: Gets the xml id for the object;
 Returns : An xml id
 Args    : None.

=item get_xml_tag()

Retrieves tag string

 Type    : Accessor
 Title   : get_xml_tag
 Usage   : my $str = $obj->get_xml_tag;
 Function: Gets the xml tag for the object;
 Returns : A tag, i.e. pointy brackets
 Args    : Optional: a true value, to close an empty tag

=item is_identifiable()

By default, all XMLWritable objects are identifiable when serialized,
i.e. they have a unique id attribute. However, in some cases a serialized
object may not have an id attribute (governed by the nexml schema). This
method indicates whether that is the case.

 Type    : Test
 Title   : is_identifiable
 Usage   : if ( $obj->is_identifiable ) { ... }
 Function: Indicates whether IDs are generated
 Returns : BOOLEAN
 Args    : NONE

=item remove_dictionary()

 Type    : Mutator
 Title   : remove_dictionary
 Usage   : $obj->remove_dictionary($dict);
 Function: Removes a dictionary attachment from the object
 Returns : $self
 Args    : Bio::Phylo::Dictionary

=item set_attributes()

Assigns attributes for the element.

 Type    : Mutator
 Title   : set_attributes
 Usage   : $obj->set_attributes( 'foo' => 'bar' )
 Function: Sets the xml attributes for the object;
 Returns : $self
 Args    : key/value pairs or a hash ref

=item set_identifiable()

By default, all XMLWritable objects are identifiable when serialized,
i.e. they have a unique id attribute. However, in some cases a serialized
object may not have an id attribute (governed by the nexml schema). For
such objects, id generation can be explicitly disabled using this method.
Typically, this is done internally - you will probably never use this method.

 Type    : Mutator
 Title   : set_identifiable
 Usage   : $obj->set_tag(0);
 Function: Enables/disables id generation
 Returns : $self
 Args    : BOOLEAN

=item set_namespaces()

 Type    : Mutator
 Title   : set_namespaces
 Usage   : $obj->set_namespaces( 'dwc' => 'http://www.namespaceTBD.org/darwin2' );
 Function: Adds one or more prefix/namespace pairs
 Returns : $self
 Args    : One or more prefix/namespace pairs, as even-sized list, 
           or as a hash reference, i.e.:
           $obj->set_namespaces( 'dwc' => 'http://www.namespaceTBD.org/darwin2' );
           or
           $obj->set_namespaces( { 'dwc' => 'http://www.namespaceTBD.org/darwin2' } );
 Notes   : This is a global for the XMLWritable class, so that in a recursive
 		   to_xml call the outermost element contains the namespace definitions.
 		   This method can also be called as a static class method, i.e.
 		   Bio::Phylo::Util::XMLWritable->set_namespaces(
 		   'dwc' => 'http://www.namespaceTBD.org/darwin2');

=item set_tag()

This method is usually only used internally, to define or alter the
name of the tag into which the object is serialized. For example,
for a Bio::Phylo::Forest::Node object, this method would be called 
with the 'node' argument, so that the object is serialized into an
xml element structure called <node/>

 Type    : Mutator
 Title   : set_tag
 Usage   : $obj->set_tag('node');
 Function: Sets the tag name
 Returns : $self
 Args    : A tag name (must be a valid xml element name)

=item set_xml_id()

This method is usually only used internally, to store the xml id
of an object as it is parsed out of a nexml file - this is for
the purpose of round-tripping nexml info sets.

 Type    : Mutator
 Title   : set_xml_id
 Usage   : $obj->set_xml_id('node345');
 Function: Sets the xml id
 Returns : $self
 Args    : An xml id (must be a valid xml NCName)

=item to_xml()

Serializes invocant to XML.

 Type    : XML serializer
 Title   : to_xml
 Usage   : my $xml = $obj->to_xml;
 Function: Serializes $obj to xml
 Returns : An xml string
 Args    : None

=back

=head2 SUPERCLASS Bio::Phylo

Bio::Phylo::Matrices::Datum inherits from superclass L<Bio::Phylo>. 
Below are the public methods (if any) from this superclass.

=over

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : None.
 Comments: Cloning is currently experimental, use with caution.

=item get()

Attempts to execute argument string as method on invocant.

 Type    : Accessor
 Title   : get
 Usage   : my $treename = $tree->get('get_name');
 Function: Alternative syntax for safely accessing
           any of the object data; useful for
           interpolating runtime $vars.
 Returns : (context dependent)
 Args    : a SCALAR variable, e.g. $var = 'get_name';

=item get_desc()

Gets invocant description.

 Type    : Accessor
 Title   : get_desc
 Usage   : my $desc = $obj->get_desc;
 Function: Returns the object's description (if any).
 Returns : A string
 Args    : None

=item get_generic()

Gets generic hashref or hash value(s).

 Type    : Accessor
 Title   : get_generic
 Usage   : my $value = $obj->get_generic($key);
           or
           my %hash = %{ $obj->get_generic() };
 Function: Returns the object's generic data. If an
           argument is used, it is considered a key
           for which the associated value is returned.
           Without arguments, a reference to the whole
           hash is returned.
 Returns : A string or hash reference.
 Args    : None

=item get_id()

Gets invocant's UID.

 Type    : Accessor
 Title   : get_id
 Usage   : my $id = $obj->get_id;
 Function: Returns the object's unique ID
 Returns : INT
 Args    : None

=item get_internal_name()

Gets invocant's 'fallback' name (possibly autogenerated).

 Type    : Accessor
 Title   : get_internal_name
 Usage   : my $name = $obj->get_internal_name;
 Function: Returns the object's name (if none was set, the name
           is a combination of the $obj's class and its UID).
 Returns : A string
 Args    : None

=item get_logger()

Gets a logger object.

 Type    : Accessor
 Title   : get_logger
 Usage   : my $logger = $obj->get_logger;
 Function: Returns a Bio::Phylo::Util::Logger object
 Returns : Bio::Phylo::Util::Logger
 Args    : None

=item get_name()

Gets invocant's name.

 Type    : Accessor
 Title   : get_name
 Usage   : my $name = $obj->get_name;
 Function: Returns the object's name.
 Returns : A string
 Args    : None

=item get_obj_by_id()

Attempts to fetch an in-memory object by its UID

 Type    : Accessor
 Title   : get_obj_by_id
 Usage   : my $obj = Bio::Phylo->get_obj_by_id($uid);
 Function: Fetches an object from the IDPool cache
 Returns : A Bio::Phylo object 
 Args    : A unique id

=item get_score()

Gets invocant's score.

 Type    : Accessor
 Title   : get_score
 Usage   : my $score = $obj->get_score;
 Function: Returns the object's numerical score (if any).
 Returns : A number
 Args    : None

=item new()

The Bio::Phylo root constructor, is rarely used directly. Rather, many other 
objects in Bio::Phylo internally go up the inheritance tree to this constructor. 
The arguments shown here can therefore also be passed to any of the child 
classes' constructors, which will pass them on up the inheritance tree. Generally, 
constructors in Bio::Phylo subclasses can process as arguments all methods that 
have set_* in their names. The arguments are named for the methods, but "set_" 
has been replaced with a dash "-", e.g. the method "set_name" becomes the 
argument "-name" in the constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $phylo = Bio::Phylo->new;
 Function: Instantiates Bio::Phylo object
 Returns : a Bio::Phylo object 
 Args    : Optional, any number of setters. For example,
 		   Bio::Phylo->new( -name => $name )
 		   will call set_name( $name ) internally

=item set_desc()

Sets invocant description.

 Type    : Mutator
 Title   : set_desc
 Usage   : $obj->set_desc($desc);
 Function: Assigns an object's description.
 Returns : Modified object.
 Args    : Argument must be a string.

=item set_generic()

Sets generic key/value pair(s).

 Type    : Mutator
 Title   : set_generic
 Usage   : $obj->set_generic( %generic );
 Function: Assigns generic key/value pairs to the invocant.
 Returns : Modified object.
 Args    : Valid arguments constitute:

           * key/value pairs, for example:
             $obj->set_generic( '-lnl' => 0.87565 );

           * or a hash ref, for example:
             $obj->set_generic( { '-lnl' => 0.87565 } );

           * or nothing, to reset the stored hash, e.g.
                $obj->set_generic( );

=item set_name()

Sets invocant name.

 Type    : Mutator
 Title   : set_name
 Usage   : $obj->set_name($name);
 Function: Assigns an object's name.
 Returns : Modified object.
 Args    : Argument must be a string, will be single 
           quoted if it contains [;|,|:\(|\)] 
           or spaces. Preceding and trailing spaces
           will be removed.

=item set_score()

Sets invocant score.

 Type    : Mutator
 Title   : set_score
 Usage   : $obj->set_score($score);
 Function: Assigns an object's numerical score.
 Returns : Modified object.
 Args    : Argument must be any of
           perl's number formats, or undefined
           to reset score.

=item to_json()

Serializes object to JSON string

 Type    : Serializer
 Title   : to_json()
 Usage   : print $obj->to_json();
 Function: Serializes object to JSON string
 Returns : String 
 Args    : None
 Comments:

=item to_string()

Serializes object to general purpose string

 Type    : Serializer
 Title   : to_string()
 Usage   : print $obj->to_string();
 Function: Serializes object to general purpose string
 Returns : String 
 Args    : None
 Comments: This is YAML

=back

=head2 SUPERCLASS Bio::Phylo::Taxa::TaxonLinker

Bio::Phylo::Matrices::Datum inherits from superclass L<Bio::Phylo::Taxa::TaxonLinker>. 
Below are the public methods (if any) from this superclass.

=over

=item get_taxon()

Retrieves the Bio::Phylo::Taxa::Taxon object linked to the invocant.

 Type    : Accessor
 Title   : get_taxon
 Usage   : my $taxon = $obj->get_taxon;
 Function: Retrieves the Bio::Phylo::Taxa::Taxon
           object linked to the invocant.
 Returns : Bio::Phylo::Taxa::Taxon
 Args    : NONE
 Comments:

=item set_taxon()

Links the invocant object to a taxon object.

 Type    : Mutator
 Title   : set_taxon
 Usage   : $obj->set_taxon( $taxon );
 Function: Links the invocant object
           to a taxon object.
 Returns : Modified $obj
 Args    : A Bio::Phylo::Taxa::Taxon object.

=item unset_taxon()

Unlinks the invocant object from any taxon object.

 Type    : Mutator
 Title   : unset_taxon
 Usage   : $obj->unset_taxon();
 Function: Unlinks the invocant object
           from any taxon object.
 Returns : Modified $obj
 Args    : NONE

=back

=cut

# podinherit_stop_token_do_not_remove

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Taxa::TaxonLinker>

This object inherits from L<Bio::Phylo::Taxa::TaxonLinker>, so the methods
defined therein are also applicable to L<Bio::Phylo::Matrices::Datum> objects.

=item L<Bio::Phylo::Matrices::TypeSafeData>

This object inherits from L<Bio::Phylo::Matrices::TypeSafeData>, so the methods
defined therein are also applicable to L<Bio::Phylo::Matrices::Datum> objects.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: Datum.pm 844 2009-03-05 00:07:26Z rvos $

=cut

1;
__DATA__

my $DEFAULT_NAME = 'DEFAULT';

sub meta_names {
    my ($self) = @_;
    my @r;
    my $names = $self->get_generic('meta') || {};
    foreach  ( sort keys %{ $names } ) {
        push (@r, $_) unless $_ eq $DEFAULT_NAME;
    }
    unshift @r, $DEFAULT_NAME if $names->{$DEFAULT_NAME};
    return @r;
}

sub get_SeqFeatures { $logger->warn }

sub get_all_SeqFeatures { $logger->warn }

sub feature_count { $logger->warn }

sub seq {
    my $self = shift;
    my $seq = $self->get_char;
    return $seq;
}

# from primary seq
sub subseq {
   my ($self,$start,$end,$replace) = @_;

   if( ref($start) && $start->isa('Bio::LocationI') ) {
       my $loc = $start;
       $replace = $end; # do we really use this anywhere? scary. HL
       my $seq = "";
       foreach my $subloc ($loc->each_Location()) {
	   my $piece = $self->subseq($subloc->start(),
				     $subloc->end(), $replace);
	   if($subloc->strand() < 0) {
	       $piece = Bio::PrimarySeq->new('-seq' => $piece)->revcom()->seq();
	   }
	   $seq .= $piece;
       }
       return $seq;
   } elsif(  defined  $start && defined $end ) {
       if( $start > $end ){
	   $self->throw("Bad start,end parameters. Start [$start] has to be ".
			"less than end [$end]");
       }
       if( $start <= 0 ) {
	   $self->throw("Bad start parameter ($start). Start must be positive.");
       }
       if( $end > $self->length ) {
	   $self->throw("Bad end parameter ($end). End must be less than the total length of sequence (total=".$self->length.")");
       }

       # remove one from start, and then length is end-start
       $start--;
       if( defined $replace ) {
	   return substr( $self->seq(), $start, ($end-$start), $replace);
       } else {
	   return substr( $self->seq(), $start, ($end-$start));
       }
   } else {
       $self->warn("Incorrect parameters to subseq - must be two integers or a Bio::LocationI object. Got:", $self,$start,$end,$replace);
       return;
   }
}

sub write_GFF { $logger->warn }

sub annotation { $logger->warn }

sub species { $logger->warn }

sub primary_seq { $logger->warn }

sub accession_number { $logger->warn }

sub alphabet {
    my $self = shift;
    my $type = $self->get_type;
    return lc $type;
}

sub can_call_new { $logger->warn }

sub desc {
    my ( $self, $desc ) = @_;
    if ( defined $desc ) {
        $self->set_desc( $desc );
    }
    return $self->get_desc;
}

sub display_id { shift->get_name }

sub id { shift->get_name }

sub is_circular { $logger->warn }

sub length { shift->get_length }

sub moltype { shift->alphabet }

sub primary_id { $logger->warn }

sub revcom { $logger->warn }

sub translate { $logger->warn }

sub trunc { $logger->warn }

sub get_nse{
   my ($self,$char1,$char2) = @_;

   $char1 ||= "/";
   $char2 ||= "-";

   $self->throw("Attribute id not set") unless defined($self->id());
   $self->throw("Attribute start not set") unless defined($self->start());
   $self->throw("Attribute end not set") unless defined($self->end());

   return $self->id() . $char1 . $self->start . $char2 . $self->end ;

}

sub strand {
	my ( $self, $strand ) = @_;
	if ( defined $strand ) {
		$self->set_generic( 'strand' => $strand );
	}
	return $self->get_generic( 'strand' );
}

sub start {
	my ( $self, $start ) = @_;
	if ( defined $start ) {
		$self->set_position( $start );
	}
	return $self->get_position;
}

sub end {
	my ( $self, $end ) = @_;
	if ( defined $end ) {
		$self->set_generic( 'end' => $end );
	}
	$end = $self->get_generic( 'end' );
	if ( defined $end ) {
		return $end;
	}
	else {
		return scalar( @{ $self->get_entities } ) + $self->get_position - 1;
	}
}