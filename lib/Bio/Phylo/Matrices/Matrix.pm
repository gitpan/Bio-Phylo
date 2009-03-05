# $Id: Matrix.pm 844 2009-03-05 00:07:26Z rvos $
package Bio::Phylo::Matrices::Matrix;
use vars '@ISA';
use strict;
use Bio::Phylo::Factory;
use Bio::Phylo::Taxa::TaxaLinker;
use Bio::Phylo::IO qw(unparse);
use Bio::Phylo::Util::CONSTANT qw(:objecttypes looks_like_hash);
use Bio::Phylo::Util::Exceptions qw(throw);
use Bio::Phylo::Matrices::TypeSafeData;
use Bio::Phylo::Matrices::Datum;
use UNIVERSAL qw(isa);
@ISA = qw(
  Bio::Phylo::Matrices::TypeSafeData
  Bio::Phylo::Taxa::TaxaLinker
);

eval { require Bio::Align::AlignI };
if ( not $@ ) {
	push @ISA, 'Bio::Align::AlignI';
}
else {
	undef($@);
}
my $LOADED_WRAPPERS = 0;


{
	my $CONSTANT_TYPE      = _MATRIX_;
	my $CONSTANT_CONTAINER = _MATRICES_;
	my $logger             = __PACKAGE__->get_logger;
	my $factory            = Bio::Phylo::Factory->new;
	my @inside_out_arrays  = \(
		my (
			%type,  
			%charlabels,
			%statelabels,
			%gapmode,
			%matchchar,
			%polymorphism,
			%case_sensitivity,
		)
	);

=head1 NAME

Bio::Phylo::Matrices::Matrix - Character state matrix

=head1 SYNOPSIS

 use Bio::Phylo::Factory;
 my $fac = Bio::Phylo::Factory->new;

 # instantiate taxa object
 my $taxa = $fac->create_taxa;
 for ( 'Homo sapiens', 'Pan paniscus', 'Pan troglodytes' ) {
     $taxa->insert( $fac->create_taxon( '-name' => $_ ) );
 }

 # instantiate matrix object, 'standard' data type. All categorical
 # data types follow semantics like this, though with different
 # symbols in lookup table and matrix
 my $standard_matrix = $fac->create_matrix(
     '-type'   => 'STANDARD',
     '-taxa'   => $taxa,
     '-lookup' => { 
         '-' => [],
         '0' => [ '0' ],
         '1' => [ '1' ],
         '?' => [ '0', '1' ],
     },
     '-labels' => [ 'Opposable big toes', 'Opposable thumbs', 'Not a pygmy' ],
     '-matrix' => [
         [ 'Homo sapiens'    => '0', '1', '1' ],
         [ 'Pan paniscus'    => '1', '1', '0' ],
         [ 'Pan troglodytes' => '1', '1', '1' ],
     ],
 );
 
 # note: complicated constructor for mixed data!
 my $mixed_matrix = Bio::Phylo::Matrices::Matrix->new( 
    
    # if you want to create 'mixed', value for '-type' is array ref...
    '-type' =>  [ 
    
        # ...with first field 'mixed'...                
        'mixed',
        
        # ...second field is an array ref...
        [
            
            # ...with _ordered_ key/value pairs...
            'dna'      => 10, # value is length of type range
            'standard' => 10, # value is length of type range
            
            # ... or, more complicated, value is a hash ref...
            'rna'      => {
                '-length' => 10, # value is length of type range
                
                # ...value for '-args' is an array ref with args 
                # as can be passed to 'unmixed' datatype constructors,
                # for example, here we modify the lookup table for
                # rna to allow both 'U' (default) and 'T'
                '-args'   => [
                    '-lookup' => {
                        'A' => [ 'A'                     ],
                        'C' => [ 'C'                     ],
                        'G' => [ 'G'                     ],
                        'U' => [ 'U'                     ],
                        'T' => [ 'T'                     ],
                        'M' => [ 'A', 'C'                ],
                        'R' => [ 'A', 'G'                ],
                        'S' => [ 'C', 'G'                ],
                        'W' => [ 'A', 'U', 'T'           ],
                        'Y' => [ 'C', 'U', 'T'           ],
                        'K' => [ 'G', 'U', 'T'           ],
                        'V' => [ 'A', 'C', 'G'           ],
                        'H' => [ 'A', 'C', 'U', 'T'      ],
                        'D' => [ 'A', 'G', 'U', 'T'      ],
                        'B' => [ 'C', 'G', 'U', 'T'      ],
                        'X' => [ 'G', 'A', 'U', 'T', 'C' ],
                        'N' => [ 'G', 'A', 'U', 'T', 'C' ],
                    },
                ],
            },
        ],
    ],
 );
 
 # prints 'mixed(Dna:1-10, Standard:11-20, Rna:21-30)'
 print $mixed_matrix->get_type;

=head1 DESCRIPTION

This module defines a container object that holds
L<Bio::Phylo::Matrices::Datum> objects. The matrix
object inherits from L<Bio::Phylo::Listable>, so the
methods defined there apply here.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

Matrix constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $matrix = Bio::Phylo::Matrices::Matrix->new;
 Function: Instantiates a Bio::Phylo::Matrices::Matrix
           object.
 Returns : A Bio::Phylo::Matrices::Matrix object.
 Args    : -type   => optional, but if used must be FIRST argument, 
                      defines datatype, one of dna|rna|protein|
                      continuous|standard|restriction|[ mixed => [] ]

           -taxa   => optional, link to taxa object
           -lookup => character state lookup hash ref
           -labels => array ref of character labels
           -matrix => two-dimensional array, first element of every
                      row is label, subsequent are characters

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
		my $self = $class->SUPER::new( '-tag' => 'characters', @_ );
		return $self;
	}

=item new_from_bioperl()

Matrix constructor from Bio::Align::AlignI argument.

 Type    : Constructor
 Title   : new_from_bioperl
 Usage   : my $matrix = 
           Bio::Phylo::Matrices::Matrix->new_from_bioperl(
               $aln           
           );
 Function: Instantiates a 
           Bio::Phylo::Matrices::Matrix object.
 Returns : A Bio::Phylo::Matrices::Matrix object.
 Args    : An alignment that implements Bio::Align::AlignI

=cut
	
	sub new_from_bioperl {
	    my ( $class, $aln, @args ) = @_;
		if ( isa( $aln, 'Bio::Align::AlignI' ) ) {
		    $aln->unmatch;
		    $aln->map_chars('\.','-');
		    my @seqs = $aln->each_seq;
		    my ( $type, $missing, $gap, $matchchar ); 
		    if ( $seqs[0] ) {
		    	$type = $seqs[0]->alphabet || $seqs[0]->_guess_alphabet || 'dna';
		    }
		    else {
		    	$type = 'dna';
		    }
			my $self = $factory->create_matrix( 
				'-type' => $type,
				'-special_symbols' => {
			    	'-missing'   => $aln->missing_char || '?',
			    	'-matchchar' => $aln->match_char   || '.',
			    	'-gap'       => $aln->gap_char     || '-',					
				},
				@args 
			);			
			# XXX create raw getter/setter pairs for annotation, accession, consensus_meta source
			for my $field ( qw(description accession id annotation consensus_meta score source) ) {
				$self->$field( $aln->$field );
			}			
			my $to = $self->get_type_object;			
            for my $seq ( @seqs ) {
            	my $datum = Bio::Phylo::Matrices::Datum->new_from_bioperl(
            		$seq, '-type_object' => $to
            	);                                         	
                $self->insert($datum);
            }
            return $self;
		}
		else {
			throw 'ObjectMismatch' => 'Not a bioperl alignment!';
		}
	}

=back

=head2 MUTATORS

=over

=item set_special_symbols

Sets three special symbols in one call

 Type    : Mutator
 Title   : set_special_symbols
 Usage   : $matrix->set_special_symbols( 
 		       -missing   => '?', 
 		       -gap       => '-', 
 		       -matchchar => '.' 
 		   );
 Function: Assigns state labels.
 Returns : $self
 Args    : Three args (with distinct $x, $y and $z):
  		       -missing   => $x, 
 		       -gap       => $y, 
 		       -matchchar => $z
 Notes   : This method is here to ensure
           you don't accidentally use the
           same symbol for missing AND gap

=cut

	sub set_special_symbols {
		my $self = shift;
		my %args;
		if ( ( @_ == 1 && ref($_[0]) eq 'HASH' && ( %args = %{$_[0]} ) ) || ( %args = looks_like_hash @_ ) ) {
			if ( ! defined $args{'-missing'} || ! defined $args{'-gap'} || ! defined $args{'-matchchar'} ) {
				throw 'BadArgs' => 'Need -missing => $x, -gap => $y, -matchchar => $z arguments, not '."@_";
			}
			my %values = map { $_ => 1 } values %args;
			my @values = keys %values;
			if ( scalar @values < 3 ) {
				throw 'BadArgs' => 'Symbols must be distinct, not ' . join(', ', values %args);
			}
			my %old_special_symbols = ( 
				$self->get_missing   => 'set_missing',
				$self->get_gap       => 'set_gap',
				$self->get_matchchar => 'set_matchchar',
			);	
			my %new_special_symbols = (
				$args{'-missing'}    => 'set_missing',
				$args{'-gap'}        => 'set_gap',
				$args{'-matchchar'}  => 'set_matchchar',
			);
			my %dummies;
			while ( %new_special_symbols ) {
				for my $sym ( keys %new_special_symbols ) {
					if ( not $old_special_symbols{$sym} ) {
						my $method = $new_special_symbols{$sym};
						$self->$method($sym);
						delete $new_special_symbols{$sym};
					}
					elsif ( $old_special_symbols{$sym} eq $new_special_symbols{$sym} ) {
						delete $new_special_symbols{$sym};
					}
					else {
						DUMMY: for my $dummy ( qw(! @ $ % ^ & *) ) {
							if ( ! $new_special_symbols{$dummy} && ! $old_special_symbols{$dummy} && ! $dummies{$dummy} ) {
								my $method = $old_special_symbols{$sym};
								$self->$method($dummy);
								$dummies{$dummy} = 1;
								delete $old_special_symbols{$sym};
								$old_special_symbols{$dummy} = $method;
								last DUMMY;
							}
						}
					}
				}
			}
		}
		return $self;
	}

=item set_statelabels()

Sets argument state labels.

 Type    : Mutator
 Title   : set_statelabels
 Usage   : $matrix->set_statelabels( [ [ 'state1', 'state2' ] ] );
 Function: Assigns state labels.
 Returns : $self
 Args    : ARRAY, or nothing (to reset);
           The array is two-dimensional, 
           the first index is to indicate
           the column the labels apply to,
           the second dimension the states
           (sorted numerically or alphabetically,
           depending on what's appropriate)

=cut

	sub set_statelabels {
		my ( $self, $statelabels ) = @_;
		
		# it's an array ref, but what about its contents?
		if ( isa( $statelabels, 'ARRAY' ) ) {
			for my $col ( @{$statelabels} ) {
				if ( not isa( $col, 'ARRAY') ) {
					throw 'BadArgs' => "statelabels must be a two dimensional array ref";
				}
			}
		}

		# it's defined but not an array ref
		elsif ( defined $statelabels && ! isa( $statelabels, 'ARRAY' ) ) {
			throw 'BadArgs' => "statelabels must be a two dimensional array ref";
		}

		# it's either a valid array ref, or nothing, i.e. a reset
		$statelabels{$$self} = $statelabels || [];
		return $self;		
	}

=item set_charlabels()

Sets argument character labels.

 Type    : Mutator
 Title   : set_charlabels
 Usage   : $matrix->set_charlabels( [ 'char1', 'char2', 'char3' ] );
 Function: Assigns character labels.
 Returns : $self
 Args    : ARRAY, or nothing (to reset);

=cut

	sub set_charlabels {
		my ( $self, $charlabels ) = @_;

		# it's an array ref, but what about its contents?
		if ( isa( $charlabels, 'ARRAY' ) ) {
			for my $label ( @{$charlabels} ) {
				if ( ref $label ) {
					throw 'BadArgs' => "charlabels must be an array ref of scalars";
				}
			}
		}

		# it's defined but not an array ref
		elsif ( defined $charlabels && ! isa( $charlabels, 'ARRAY' ) ) {
			throw 'BadArgs' => "charlabels must be an array ref of scalars";
		}

		# it's either a valid array ref, or nothing, i.e. a reset
		$charlabels{$$self} = defined $charlabels ? $charlabels : [];
		return $self;
	}

=item set_gapmode()

Defines matrix gapmode.

 Type    : Mutator
 Title   : set_gapmode
 Usage   : $matrix->set_gapmode( 1 );
 Function: Defines matrix gapmode ( false = missing, true = fifth state )
 Returns : $self
 Args    : boolean

=cut

	sub set_gapmode {
		my ( $self, $gapmode ) = @_;
		$gapmode{$$self} = !!$gapmode;
		return $self;
	}

=item set_matchchar()

Assigns match symbol.

 Type    : Mutator
 Title   : set_matchchar
 Usage   : $matrix->set_matchchar( $match );
 Function: Assigns match symbol (default is '.').
 Returns : $self
 Args    : ARRAY

=cut

	sub set_matchchar {
		my ( $self, $match ) = @_;
		my $missing = $self->get_missing;
		my $gap     = $self->get_gap;
		if ( $match eq $missing ) {
			throw 'BadArgs' => "Match character '$match' already in use as missing character";
		}
		elsif ( $match eq $gap ) {
			throw 'BadArgs' => "Match character '$match' already in use as gap character";
		}
		else {
			$matchchar{$$self} = $match;
		}
		return $self;
	}

=item set_polymorphism()

Defines matrix 'polymorphism' interpretation.

 Type    : Mutator
 Title   : set_polymorphism
 Usage   : $matrix->set_polymorphism( 1 );
 Function: Defines matrix 'polymorphism' interpretation
           ( false = uncertainty, true = polymorphism )
 Returns : $self
 Args    : boolean

=cut

	sub set_polymorphism {
		my ( $self, $poly ) = @_;
		$polymorphism{$$self} = !!$poly;
		return $self;
	}

=item set_raw()

Set contents using two-dimensional array argument.

 Type    : Mutator
 Title   : set_raw
 Usage   : $matrix->set_raw( [ [ 'taxon1' => 'acgt' ], [ 'taxon2' => 'acgt' ] ] );
 Function: Syntax sugar to define $matrix data contents.
 Returns : $self
 Args    : A two-dimensional array; first dimension contains matrix rows,
           second dimension contains taxon name / character string pair.

=cut

	sub set_raw {
		my ( $self, $raw ) = @_;
		if ( defined $raw ) {
			if ( isa( $raw, 'ARRAY' ) ) {
				my @rows;
				for my $row ( @{$raw} ) {
					if ( defined $row ) {
						if ( isa( $row, 'ARRAY' ) ) {
							my $matrixrow = $factory->create_datum(
								'-type_object' => $self->get_type_object,
								'-name'        => $row->[0],
								'-char' => join( ' ', @$row[ 1 .. $#{$row} ] ),
							);
							push @rows, $matrixrow;
						}
						else {
							throw 'BadArgs' => "Raw matrix row must be an array reference";
						}
					}
				}
				$self->clear;
				$self->insert($_) for @rows;
			}
			else {
				throw 'BadArgs' => "Raw matrix must be an array reference";
			}
		}
		return $self;
	}

=item set_respectcase()

Defines matrix case sensitivity interpretation.

 Type    : Mutator
 Title   : set_respectcase
 Usage   : $matrix->set_respectcase( 1 );
 Function: Defines matrix case sensitivity interpretation
           ( false = disregarded, true = "respectcase" )
 Returns : $self
 Args    : boolean

=cut

	sub set_respectcase {
		my ( $self, $case_sensitivity ) = @_;
		$case_sensitivity{$$self} = !!$case_sensitivity;
		return $self;
	}

=back

=head2 ACCESSORS

=over

=item get_special_symbols()

Retrieves hash ref for missing, gap and matchchar symbols

 Type    : Accessor
 Title   : get_special_symbols
 Usage   : my %syms = %{ $matrix->get_special_symbols };
 Function: Retrieves special symbols
 Returns : HASH ref, e.g. { -missing => '?', -gap => '-', -matchchar => '.' }
 Args    : None.

=cut

	sub get_special_symbols {
		my $self = shift;
		return {
			'-missing'   => $self->get_missing,
			'-matchchar' => $self->get_matchchar,
			'-gap'       => $self->get_gap
		};
	}

=item get_statelabels()

Retrieves state labels.

 Type    : Accessor
 Title   : get_statelabels
 Usage   : my @statelabels = @{ $matrix->get_statelabels };
 Function: Retrieves state labels.
 Returns : ARRAY
 Args    : None.

=cut

	sub get_statelabels { $statelabels{ ${ $_[0] } } || [] }

=item get_charlabels()

Retrieves character labels.

 Type    : Accessor
 Title   : get_charlabels
 Usage   : my @charlabels = @{ $matrix->get_charlabels };
 Function: Retrieves character labels.
 Returns : ARRAY
 Args    : None.

=cut

	sub get_charlabels { $charlabels{ ${ $_[0] } } || [] }

=item get_gapmode()

Returns matrix gapmode.

 Type    : Accessor
 Title   : get_gapmode
 Usage   : do_something() if $matrix->get_gapmode;
 Function: Returns matrix gapmode ( false = missing, true = fifth state )
 Returns : boolean
 Args    : none

=cut

	sub get_gapmode { $gapmode{ ${ $_[0] } } }

=item get_matchchar()

Returns matrix match character.

 Type    : Accessor
 Title   : get_matchchar
 Usage   : my $char = $matrix->get_matchchar;
 Function: Returns matrix match character (default is '.')
 Returns : SCALAR
 Args    : none

=cut

	sub get_matchchar { $matchchar{ ${ $_[0] } } || '.' }

=item get_nchar()

Calculates number of characters.

 Type    : Accessor
 Title   : get_nchar
 Usage   : my $nchar = $matrix->get_nchar;
 Function: Calculates number of characters (columns) in matrix (if the matrix
           is non-rectangular, returns the length of the longest row).
 Returns : INT
 Args    : none

=cut

	sub get_nchar {
		my $self  = shift;
		my $nchar = 0;
#		my $i     = 1;
		for my $row ( @{ $self->get_entities } ) {
			my $rowlength = scalar( @{ $row->get_entities } ) + $row->get_position - 1;
# 			$logger->debug(
# 				sprintf( "counted %s chars in row %s", $rowlength, $i++ ) );
			$nchar = $rowlength if $rowlength > $nchar;
		}
		return $nchar;
	}

=item get_ntax()

Calculates number of taxa (rows) in matrix.

 Type    : Accessor
 Title   : get_ntax
 Usage   : my $ntax = $matrix->get_ntax;
 Function: Calculates number of taxa (rows) in matrix
 Returns : INT
 Args    : none

=cut

	sub get_ntax { scalar @{ shift->get_entities } }

=item get_polymorphism()

Returns matrix 'polymorphism' interpretation.

 Type    : Accessor
 Title   : get_polymorphism
 Usage   : do_something() if $matrix->get_polymorphism;
 Function: Returns matrix 'polymorphism' interpretation
           ( false = uncertainty, true = polymorphism )
 Returns : boolean
 Args    : none

=cut

	sub get_polymorphism { $polymorphism{ ${ $_[0] } } }

=item get_raw()

Retrieves a 'raw' (two-dimensional array) representation of the matrix's contents.

 Type    : Accessor
 Title   : get_raw
 Usage   : my $rawmatrix = $matrix->get_raw;
 Function: Retrieves a 'raw' (two-dimensional array) representation
           of the matrix's contents.
 Returns : A two-dimensional array; first dimension contains matrix rows,
           second dimension contains taxon name and characters.
 Args    : NONE

=cut

	sub get_raw {
		my $self = shift;
		my @raw;
		for my $row ( @{ $self->get_entities } ) {
			my @row;
			push @row, $row->get_name;
			my @char = $row->get_char;
			push @row, @char;
			push @raw, \@row;
		}
		return \@raw;
	}

=item get_respectcase()

Returns matrix case sensitivity interpretation.

 Type    : Accessor
 Title   : get_respectcase
 Usage   : do_something() if $matrix->get_respectcase;
 Function: Returns matrix case sensitivity interpretation
           ( false = disregarded, true = "respectcase" )
 Returns : boolean
 Args    : none

=cut

	sub get_respectcase { $case_sensitivity{ ${ $_[0] } } }

=back

=head2 METHODS

=over

=item bootstrap()

Creates bootstrapped clone.

 Type    : Utility method
 Title   : bootstrap
 Usage   : my $bootstrap = $object->bootstrap;
 Function: Creates bootstrapped clone.
 Returns : A bootstrapped clone of the invocant.
 Args    : NONE
 Comments: The bootstrapping algorithm uses perl's random number
           generator to create a new series of indices (without
           replacement) of the same length as the original matrix.
           These indices are first sorted, then applied to the 
           cloned sequences. Annotations (if present) stay connected
           to the resampled cells.

=cut

	sub bootstrap {
		my $self = shift;		
		my $clone = $self->clone;
		my $nchar = $clone->get_nchar;
		my @indices;
		push @indices, int(rand($nchar)) for ( 1 .. $nchar );
		@indices = sort { $a <=> $b } @indices;
		for my $row ( @{ $clone->get_entities } ) {
			my @anno = @{ $row->get_annotations };	
			my @char = @{ $row->get_entities };
			my @resampled = @char[@indices];
			$row->set_char(@resampled);
			if ( @anno ) {
				my @re_anno = @anno[@indices];
				$row->set_annotations(@re_anno);
			}
		}
		my @labels = @{ $clone->get_charlabels };
		if ( @labels ) {
			my @re_labels = @labels[@indices];
			$clone->set_charlabels(\@re_labels);
		}
		return $clone;
	}

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : NONE

=cut

	sub clone {
		my $self = shift;
		$logger->info("cloning $self");
		my %subs = @_;
				
		# we'll clone datum objects, so no raw copying
		$subs{'set_raw'} = sub {};
		
		# we'll use the set/get_special_symbols method
		$subs{'set_missing'}   = sub {};
		$subs{'set_gap'}       = sub {};
		$subs{'set_matchchar'} = sub {};
		
		return $self->SUPER::clone(%subs);
	
	} 

=item to_xml()

Serializes matrix to nexml format.

 Type    : Format convertor
 Title   : to_xml
 Usage   : my $data_block = $matrix->to_xml;
 Function: Converts matrix object into a nexml element structure.
 Returns : Nexml block (SCALAR).
 Args    : Optional:
 		   -compact => 1 (for compact representation of matrix)

=cut

	sub to_xml {
		my $self = shift;		
		my ( %args, $ids_for_states );
		if ( @_ ) {
			%args = @_;
		}
		my $type = $self->get_type;
		my $verbosity = $args{'-compact'} ? 'Seqs' : 'Cells';
		my $xsi_type = 'nex:' . ucfirst($type) . $verbosity;
		$self->set_attributes( 'xsi:type' => $xsi_type );
		my $xml = $self->get_xml_tag;
		my $normalized = $self->_normalize_symbols;
		
		# skip <format/> block in compact mode
		if ( not $args{'-compact'} ) {
			
			# the format block
			$xml .= "\n<format>";
			my $to = $self->get_type_object;
			$ids_for_states = $to->get_ids_for_states(1);
			
			# write state definitions
			$xml .= $to->to_xml($normalized);
			
			# write column definitions
			if ( %{ $ids_for_states } ) {
				$xml .= $self->_write_char_labels( $to->get_xml_id );
			}
			else {
				$xml .= $self->_write_char_labels();
			}
			$xml .= "\n</format>";
		}
		
		# the matrix block
		$xml .= "\n<matrix>";
		my @char_ids;
		for ( 0 .. $self->get_nchar ) {
			push @char_ids, 'c' . ($_+1);
		}
		
		# write rows
		for my $row ( @{ $self->get_entities } ) {
			$xml .= "\n" . $row->to_xml(
				'-states'  => $ids_for_states,
				'-chars'   => \@char_ids,
				'-symbols' => $normalized,
				%args,
			);
		}
		$xml .= "\n</matrix>";
		$xml .= "\n" . sprintf( '</%s>', $self->get_tag );
		return $xml;
	}
	
	sub _normalize_symbols {
		my $self = shift;
		if ( $self->get_type =~ /^standard$/i ) {
			my $to = $self->get_type_object;
			my $lookup = $self->get_lookup;
			my @states = keys %{ $lookup };
			if ( my @letters = sort { $a cmp $b } grep { /[a-z]/i } @states ) {
				my @numbers  = sort { $a <=> $b } grep { /^\d+$/ } @states;
				my $i = $numbers[-1];
				my %map = map { $_ => ++$i } @letters;	
				return \%map;			
			}
			else {
				return {};
			}			
		}
		else {
			return {};
		}
	}
	
	sub _write_char_labels {
		my ( $self, $states_id ) = @_;
		my $xml = '';
		my $labels = $self->get_charlabels;
		for my $i ( 1 .. $self->get_nchar ) {
			my $char_id = 'c' . $i;
			my $label   = $labels->[ $i - 1 ];
			
			# have state definitions (categorical data)
			if ( $states_id ) {
				if ( $label ) {
					$xml .= "\n" . sprintf('<char id="%s" label="%s" states="%s"/>', $char_id, $label, $states_id);
				}
				else {
					$xml .= "\n" . sprintf('<char id="%s" states="%s"/>', $char_id, $states_id);
				}
			}
			
			# must be continuous characters (because no state definitions)
			else {
				if ( $label ) {
					$xml .= "\n" . sprintf('<char id="%s" label="%s"/>', $char_id, $label);
				}
				else {
					$xml .= "\n" . sprintf('<char id="%s"/>', $char_id);
				}
			}
		}	
		return $xml;	
	}

=item to_nexus()

Serializes matrix to nexus format.

 Type    : Format convertor
 Title   : to_nexus
 Usage   : my $data_block = $matrix->to_nexus;
 Function: Converts matrix object into a nexus data block.
 Returns : Nexus data block (SCALAR).
 Args    : The following options are available:
 
            # if set, writes TITLE & LINK tokens
            '-links' => 1
            
            # if set, writes block as a "data" block (deprecated, but used by mrbayes),
            # otherwise writes "characters" block (default)
            -data_block => 1
            
            # if set, writes "RESPECTCASE" token
            -respectcase => 1
            
            # if set, writes "GAPMODE=(NEWSTATE or MISSING)" token
            -gapmode => 1
            
            # if set, writes "MSTAXA=(POLYMORPH or UNCERTAIN)" token
            -polymorphism => 1
            
            # if set, writes character labels
            -charlabels => 1
            
            # if set, writes state labels
            -statelabels => 1
            
            # if set, writes mesquite-style charstatelabels
            -charstatelabels => 1
            
            # by default, names for sequences are derived from $datum->get_name, if 
            # 'internal' is specified, uses $datum->get_internal_name, if 'taxon'
            # uses $datum->get_taxon->get_name, if 'taxon_internal' uses 
            # $datum->get_taxon->get_internal_name, if $key, uses $datum->get_generic($key)
            -seqnames => one of (internal|taxon|taxon_internal|$key)

=cut

	sub to_nexus {
		my $self   = shift;
		$logger->info("writing to nexus: $self");
		my %args   = @_;
		my $nchar  = $self->get_nchar;
		my $string = sprintf "BEGIN %s;\n",
		  $args{'-data_block'} ? 'DATA' : 'CHARACTERS';
		$string .=
		    "[! Characters block written by "
		  . ref($self) . " "
		  . $self->VERSION . " on "
		  . localtime() . " ]\n";

		# write links
		if ( $args{'-links'} ) {
			$string .= sprintf "\tTITLE %s;\n", $self->get_internal_name;
			$string .= sprintf "\tLINK TAXA=%s;\n",
			  $self->get_taxa->get_internal_name
			  if $self->get_taxa;
		}

	 	# dimensions token line - data block defines NTAX, characters block doesn't
		if ( $args{'-data_block'} ) {
			$string .= "\tDIMENSIONS NTAX=" . $self->get_ntax() . ' ';
			$string .= 'NCHAR=' . $nchar . ";\n";
		}
		else {
			$string .= "\tDIMENSIONS NCHAR=" . $nchar . ";\n";
		}

		# format token line
		$string .= "\tFORMAT DATATYPE=" . $self->get_type();
		$string .= ( $self->get_respectcase ? " RESPECTCASE" : "" )
		  if $args{'-respectcase'};    # mrbayes no like
		$string .= " MATCHCHAR=" . $self->get_matchchar if $self->get_matchchar;
		$string .= " MISSING=" . $self->get_missing();
		$string .= " GAP=" . $self->get_gap()           if $self->get_gap();
		$string .= ";\n";

		# options token line (mrbayes no like)
		if ( $args{'-gapmode'} or $args{'-polymorphism'} ) {
			$string .= "\tOPTIONS ";
			$string .=
			  "GAPMODE=" . ( $self->get_gapmode ? "NEWSTATE " : "MISSING " )
			  if $args{'-gapmode'};
			$string .= "MSTAXA="
			  . ( $self->get_polymorphism ? "POLYMORPH " : "UNCERTAIN " )
			  if $args{'-polymorphism'};
			$string .= ";\n";
		}

		# charlabels token line
		if ( $args{'-charlabels'} ) {
			my $charlabels;
			if ( my @labels = @{ $self->get_charlabels } ) {
				my $i = 1;
				for my $label (@labels) {
					$charlabels .= $label =~ /\s/ ? "\n\t\t [$i] '$label'" : "\n\t\t [$i] $label";
					$i++;
				}
				$string .= "\tCHARLABELS$charlabels\n\t;\n";
			}
		}
		
		# statelabels token line
		if ( $args{'-statelabels'} ) {
		    my $statelabels;
		    if ( my @labels = @{ $self->get_statelabels } ) {
		        my $i = 1;
		        for my $labelset ( @labels ) {
		            $statelabels .= "\n\t\t $i";
		            for my $label ( @{ $labelset } ) {
		                $statelabels .= $label =~ /\s/ ? "\n\t\t\t'$label'" : "\n\t\t\t$label";
		                $i++;
		            }
		            $statelabels .= ',';
		        }
		        $string .= "\tSTATELABELS$statelabels\n\t;\n";
		    }
		}
		
		# charstatelabels token line
		if ( $args{'-charstatelabels'} ) {
		    my @charlabels = @{ $self->get_charlabels };
		    my @statelabels = @{ $self->get_statelabels };
		    if ( @charlabels and @statelabels ) {
		        my $charstatelabels;
		        my $nlabels = $self->get_nchar - 1;
		        for my $i ( 0 .. $nlabels ) {
		            $charstatelabels .= "\n\t\t" . ( $i + 1 );
		            if ( my $label = $charlabels[$i] ) {
		                $charstatelabels .= $label =~ /\s/ ? " '$label' /" : " $label /";
		            }
		            else {
		                $charstatelabels .= " ' ' /";
		            }
		            if ( my $labelset = $statelabels[$i] ) {
		                for my $label ( @{ $labelset } ) {
		                    $charstatelabels .= $label =~ /\s/ ? " '$label'" : " $label";
		                }
		            }
		            else {
		                $charstatelabels .= " ' '";
		            }
		            $charstatelabels .= $i == $nlabels ? "\n\t;" : ',';
		        }
		        $string .= "\tCHARSTATELABELS$charstatelabels\n\t;\n";
		    }
		}

		# ...and write matrix!
		$string .= "\tMATRIX\n";
		my $length = 0;
		foreach my $datum ( @{ $self->get_entities } ) {
			$length = length( $datum->get_name )
			  if length( $datum->get_name ) > $length;
		}
		$length += 4;
		my $sp = ' ';
		foreach my $datum ( @{ $self->get_entities } ) {
			$string .= "\t\t";

			# construct name
			my $name;
			if ( not $args{'-seqnames'} ) {
				$name = $datum->get_name;
			}
			elsif ( $args{'-seqnames'} =~ /^internal$/i ) {
				$name = $datum->get_internal_name;
			}
			elsif ( $args{'-seqnames'} =~ /^taxon/i and $datum->get_taxon ) {
				if ( $args{'-seqnames'} =~ /^taxon_internal$/i ) {
					$name = $datum->get_taxon->get_internal_name;
				}
				elsif ( $args{'-seqnames'} =~ /^taxon$/i ) {
					$name = $datum->get_taxon->get_name;
				}
			}
			else {
				$name = $datum->get_generic( $args{'-seqnames'} );
			}
			$name = $datum->get_internal_name if not $name;
			$string .= $name . ( $sp x ( $length - length($name) ) );
			my @characters;
			for my $i ( 0 .. ( $nchar - 1 ) ) {
				push @characters, $datum->get_by_index($i);
			}
			$string .= $self->get_type_object->join( \@characters ) . "\n";
		}
		$string .= "\t;\nEND;\n";
		return $string;
	}

=item insert()

Insert argument in invocant.

 Type    : Listable method
 Title   : insert
 Usage   : $matrix->insert($datum);
 Function: Inserts $datum in $matrix.
 Returns : Modified object
 Args    : A datum object
 Comments: This method re-implements the method by the same
           name in Bio::Phylo::Listable

=cut

	sub insert {
		my ( $self, $obj ) = @_;
		my $obj_container;
		eval { $obj_container = $obj->_container };
		if ( $@ || $obj_container != $self->_type ) {
			throw 'ObjectMismatch' => 'object not a datum object!';
		}
		$logger->info("inserting '$obj' in '$self'");
		if ( !$self->get_type_object->is_same( $obj->get_type_object ) ) {
			throw 'ObjectMismatch' => 'object is of wrong data type';
		}
		my $taxon1 = $obj->get_taxon;
		for my $ents ( @{ $self->get_entities } ) {
			if ( $obj->get_id == $ents->get_id ) {
				throw 'ObjectMismatch' => 'row already inserted';
			}
			if ($taxon1) {
				my $taxon2 = $ents->get_taxon;
				if ( $taxon2 && $taxon1->get_id == $taxon2->get_id ) {
					$logger->warn('datum linking to same taxon already existed, concatenating instead');
					$ents->concat($obj);
					return $self;
				}
			}
		}
		$self->SUPER::insert( $obj );
		return $self;
	}

=item validate()

Validates the object's contents.

 Type    : Method
 Title   : validate
 Usage   : $obj->validate
 Function: Validates the object's contents
 Returns : True or throws Bio::Phylo::Util::Exceptions::InvalidData
 Args    : None
 Comments: This method implements the interface method by the same
           name in Bio::Phylo::Matrices::TypeSafeData

=cut

	sub validate {
		my $self = shift;
		for my $row ( @{ $self->get_entities } ) {
			$row->validate;
		}
	}

=item compress_lookup()

Removes unused states from lookup table

 Type    : Method
 Title   : validate
 Usage   : $obj->compress_lookup
 Function: Removes unused states from lookup table
 Returns : $self
 Args    : None

=cut

	sub compress_lookup {
		my $self = shift;
		my $to = $self->get_type_object;
		my $lookup = $to->get_lookup;
		my %seen;
		for my $row ( @{ $self->get_entities } ) {
			my @char = $row->get_char;
			$seen{$_}++ for (@char);
		}
		for my $state ( keys %{ $lookup } ) {
			if ( not exists $seen{$state} ) {
				delete $lookup->{$state};
			}
		}
		$to->set_lookup($lookup);
		return $self;
	}

=item check_taxa()

Validates taxa associations.

 Type    : Method
 Title   : check_taxa
 Usage   : $obj->check_taxa
 Function: Validates relation between matrix and taxa block 
 Returns : Modified object
 Args    : None
 Comments: This method implements the interface method by the same
           name in Bio::Phylo::Taxa::TaxaLinker

=cut

	sub check_taxa {
		my $self = shift;

		# is linked to taxa
		if ( my $taxa = $self->get_taxa ) {
			my %taxa =
			  map { $_->get_internal_name => $_ } @{ $taxa->get_entities };
		  ROW_CHECK: for my $row ( @{ $self->get_entities } ) {
				if ( my $taxon = $row->get_taxon ) {
					next ROW_CHECK if exists $taxa{ $taxon->get_name };
				}
				my $name = $row->get_name;
				if ( exists $taxa{$name} ) {
					$row->set_taxon( $taxa{$name} );
				}
				else {
					my $taxon = $factory->create_taxon( -name => $name );
					$taxa{$name} = $taxon;
					$taxa->insert($taxon);
					$row->set_taxon($taxon);
				}
			}
		}

		# not linked
		else {
			for my $row ( @{ $self->get_entities } ) {
				$row->set_taxon();
			}
		}
		return $self;
	}

=item make_taxa()

Creates a taxa block from the objects contents if none exists yet.

 Type    : Method
 Title   : make_taxa
 Usage   : my $taxa = $obj->make_taxa
 Function: Creates a taxa block from the objects contents if none exists yet.
 Returns : $taxa
 Args    : NONE

=cut

	sub make_taxa {
		my $self = shift;
		if ( my $taxa = $self->get_taxa ) {
			return $taxa;
		}
		else {
			my %taxa;
			my $taxa = $factory->create_taxa;
			for my $row ( @{ $self->get_entities } ) {
				my $name = $row->get_internal_name;
				if ( not $taxa{$name} ) {
					$taxa{$name} = $factory->create_taxon( '-name' => $name );
				}
			}
			$taxa->insert( map { $taxa{$_} } sort { $a cmp $b } keys %taxa );
			$self->set_taxa( $taxa );
			return $taxa;
		}
	}	
	
	sub _type      { $CONSTANT_TYPE }
	sub _container { $CONSTANT_CONTAINER }

	sub _cleanup {
		my $self = shift;
		$logger->info("cleaning up '$self'");
		my $id = $$self;
		for (@inside_out_arrays) {
			delete $_->{$id} if defined $id and exists $_->{$id};
		}
	}

=back

=cut

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:44 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Matrices::Matrix inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Matrices::Matrix also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::Matrices::TypeSafeData

Bio::Phylo::Matrices::Matrix inherits from superclass L<Bio::Phylo::Matrices::TypeSafeData>. 
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

Bio::Phylo::Matrices::Matrix inherits from superclass L<Bio::Phylo::Listable>. 
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

Bio::Phylo::Matrices::Matrix inherits from superclass L<Bio::Phylo::Util::XMLWritable>. 
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

Bio::Phylo::Matrices::Matrix inherits from superclass L<Bio::Phylo>. 
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

=head2 SUPERCLASS Bio::Phylo::Taxa::TaxaLinker

Bio::Phylo::Matrices::Matrix inherits from superclass L<Bio::Phylo::Taxa::TaxaLinker>. 
Below are the public methods (if any) from this superclass.

=over

=item check_taxa()

Performs sanity check on taxon relationships.

 Type    : Interface method
 Title   : check_taxa
 Usage   : $obj->check_taxa
 Function: Performs sanity check on taxon relationships
 Returns : $obj
 Args    : NONE

=item get_taxa()

Retrieves association between invocant and Bio::Phylo::Taxa object.

 Type    : Accessor
 Title   : get_taxa
 Usage   : my $taxa = $obj->get_taxa;
 Function: Retrieves the Bio::Phylo::Taxa
           object linked to the invocant.
 Returns : Bio::Phylo::Taxa
 Args    : NONE
 Comments: This method returns the Bio::Phylo::Taxa
           object to which the invocant is linked.
           The returned object can therefore contain
           *more* taxa than are actually in the matrix.

=item make_taxa()

Creates a taxa block from the objects contents if none exists yet.

 Type    : Decorated interface method
 Title   : make_taxa
 Usage   : my $taxa = $obj->make_taxa
 Function: Creates a taxa block from the objects contents if none exists yet.
 Returns : $taxa
 Args    : NONE

=item set_taxa()

Associates invocant with Bio::Phylo::Taxa argument.

 Type    : Mutator
 Title   : set_taxa
 Usage   : $obj->set_taxa( $taxa );
 Function: Links the invocant object
           to a taxa object.
 Returns : Modified $obj
 Args    : A Bio::Phylo::Taxa object.

=item unset_taxa()

Removes association between invocant and Bio::Phylo::Taxa object.

 Type    : Mutator
 Title   : unset_taxa
 Usage   : $obj->unset_taxa();
 Function: Removes the link between invocant object and taxa
 Returns : Modified $obj
 Args    : NONE

=back

=cut

# podinherit_stop_token_do_not_remove

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Taxa::TaxaLinker>

This object inherits from L<Bio::Phylo::Taxa::TaxaLinker>, so the
methods defined therein are also applicable to L<Bio::Phylo::Matrices::Matrix>
objects.

=item L<Bio::Phylo::Matrices::TypeSafeData>

This object inherits from L<Bio::Phylo::Matrices::TypeSafeData>, so the
methods defined therein are also applicable to L<Bio::Phylo::Matrices::Matrix>
objects.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: Matrix.pm 844 2009-03-05 00:07:26Z rvos $

=cut

}
1;

__DATA__

my %CONSERVATION_GROUPS = (
            'strong' => [ qw(
						 STA
						 NEQK
						 NHQK
						 NDEQ
						 QHRK
						 MILV
						 MILF
						 HY
						 FYW )],
				'weak' => [ qw(
                      CSA
					       ATV
					       SAG
					       STNK
					       STPA
					       SGND
					       SNDEQK
					       NDEQHK
					       NEQHRK
					       FVLIM
					       HFY )],);

sub description {
	my ( $self, $desc ) = @_;
	if ( defined $desc ) {
		$self->set_desc( $desc );
	}
	return $self->get_desc;
}

sub score {
	my ( $self, $score ) = @_;
	if ( defined $score ) {
		$self->set_score( $score );
	}
	return $self->get_score;
}

sub add_seq {
    my ( $self, $seq, $order ) = @_;
    $self->insert( $seq );
}

sub remove_seq {
    my ( $self, $seq ) = @_;
    $self->delete( $seq );
}

sub purge {
 $logger->warn 
}

sub sort_alphabetically {
    my $self = shift;
    my @sorted = map  { $_->[0] }
                 sort { $a->[1] cmp $b->[1] }
                 map  { [ $_, $_->get_name ] }
                 @{ $self->get_entities };
    $self->clear;
    $self->insert(@sorted);
    return @sorted;
}

sub each_seq {
    my $self = shift;
    return @{ $self->get_entities };
}

sub each_alphabetically {
    my $self = shift;
    return map  { $_->[0] }
           sort { $a->[1] cmp $b->[1] }
           map  { [ $_, $_->get_name ] } @{ $self->get_entities };
}

sub each_seq_with_id {
    my ( $self, $name ) = @_;
    return @{ 
        $self->get_by_regular_expression(
            '-value' => 'get_name',
            '-match' => qr/^\Q$name\E$/
        )
    }
}

sub get_seq_by_pos {
    my ( $self, $pos ) = @_;
    return $self->get_by_index( $pos - 1 );
}

sub select {
    my ( $self, $start, $end ) = @_;
    my $clone = $self->clone;
    my @contents = @{ $clone->get_entities };
    my @deleteme;
    for my $i ( 0 .. $#contents ) {
        if ( $i < $start - 1 or $i > $end - 1 ) {
            push @deleteme, $contents[$i];
        }
    }
    $clone->delete( $_ ) for @deleteme;
    return $clone;
}

sub select_noncont {
    my ( $self, @indices ) = @_;
    my $clone = $self->clone;
    my @contents = @{ $clone->get_entities };
    my ( @deleteme, %keep );
    %keep = map { ( $_ - 1 ) => 1 } @indices;
    for my $i ( 0 .. $#contents ) {
        if ( not exists $keep{$i} ) {
            push @deleteme, $contents[$i];
        }
    }
    $clone->delete( $_ ) for @deleteme;
    return $clone;
}

sub slice {
    my ( $self, $start, $end, $include_gapped ) = @_;
    my $clone = $self->clone;
    my $gap = $self->get_gap;
    SEQ: for my $seq ( @{ $clone->get_entities } ) {
        my @char = $self->get_char;
        my @slice = splice @char, ( $start - 1 ), ( $end - $start - 1 );
        if ( not $include_gapped ) {
            if ( not grep { $_ !~ /^\Q$gap\E$/ } @slice ) {
                next SEQ;
            }
        }
        $seq->set_char(@slice);
    }
}

sub map_chars {
    my ( $self, $from, $to ) = @_;
    for my $seq ( @{ $self->get_entities } ) {
        my @char = $seq->get_char;
        for my $c ( @char ) {
            $c =~ s/$from/$to/;
        }
        $seq->set_char( @char );
    }
}

sub uppercase {
    my $self = shift;
    for my $seq ( @{ $self->get_entities } ) {
        my @char = $seq->get_char;
        my @uc = map { uc $_ } @char;
        $seq->set_char(@uc);
    }
}

# from simplealign
sub match_line {
	my ($self,$matchlinechar, $strong, $weak) = @_;
	my %matchchars = ('match'    => $matchlinechar || '*',
							  'weak'     => $weak          || '.',
							  'strong'   => $strong        || ':',
							  'mismatch' => ' ',
						  );

	my @seqchars;
	my $alphabet;
	foreach my $seq ( $self->each_seq ) {
		push @seqchars, [ split(//, uc ($seq->seq)) ];
		$alphabet = $seq->alphabet unless defined $alphabet;
	}
	my $refseq = shift @seqchars;
	# let's just march down the columns
	my $matchline;
 POS:
	foreach my $pos ( 0..$self->length ) {
		my $refchar = $refseq->[$pos];
		my $char = $matchchars{'mismatch'};
		unless( defined $refchar ) {
			last if $pos == $self->length; # short circuit on last residue
			# this in place to handle jason's soon-to-be-committed
			# intron mapping code
			goto bottom;
		}
		my %col = ($refchar => 1);
		my $dash = ($refchar eq '-' || $refchar eq '.' || $refchar eq ' ');
		foreach my $seq ( @seqchars ) {
			next if $pos >= scalar @$seq;
			$dash = 1 if( $seq->[$pos] eq '-' || $seq->[$pos] eq '.' ||
							  $seq->[$pos] eq ' ' );
			$col{$seq->[$pos]}++ if defined $seq->[$pos];
		}
		my @colresidues = sort keys %col;

		# if all the values are the same
		if( $dash ) { $char =  $matchchars{'mismatch'} }
		elsif( @colresidues == 1 ) { $char = $matchchars{'match'} }
		elsif( $alphabet eq 'protein' ) { # only try to do weak/strong
			# matches for protein seqs
	    TYPE:
			foreach my $type ( qw(strong weak) ) {
				# iterate through categories
				my %groups;
				# iterate through each of the aa in the col
				# look to see which groups it is in
				foreach my $c ( @colresidues ) {
					foreach my $f ( grep { index($_,$c) >= 0 } @{$CONSERVATION_GROUPS{$type}} ) {
						push @{$groups{$f}},$c;
					}
				}
			 GRP:
				foreach my $cols ( values %groups ) {
					@$cols = sort @$cols;
					# now we are just testing to see if two arrays
					# are identical w/o changing either one
					# have to be same len
					next if( scalar @$cols != scalar @colresidues );
					# walk down the length and check each slot
					for($_=0;$_ < (scalar @$cols);$_++ ) {
						next GRP if( $cols->[$_] ne $colresidues[$_] );
					}
					$char = $matchchars{$type};
					last TYPE;
				}
			}
		}
	 bottom:
		$matchline .= $char;
	}
	return $matchline;
}

sub match {
    my ( $self, $match ) = @_;
    if ( defined $match ) {
        $self->set_matchchar($match);
    }
    else {
        $self->set_matchchar('.');
    }
    $match = $self->get_matchchar;
    my $lookup = $self->get_type_object->get_lookup->{$match} = [ $match ];    
    my @seqs = @{ $self->get_entities };
    my @firstseq = $seqs[0]->get_char;
    for my $i ( 1 .. $#seqs ) {
        my @char = $seqs[$i]->get_char;
        for my $j ( 0 .. $#char ) {
            if ( $char[$j] eq $firstseq[$j] ) {
                $char[$j] = $match;
            }
        }
        $seqs[$i]->set_char(@char);
    }
    1;
}

sub unmatch {
    my ( $self, $match ) = @_;
    if ( defined $match ) {
        $self->set_matchchar($match);
    }
    else {
        $self->set_matchchar('.');
    }
    $match = $self->get_matchchar;
    my @seqs = @{ $self->get_entities };
    my @firstseq = $seqs[0]->get_char;
    for my $i ( 1 .. $#seqs ) {
        my @char = $seqs[$i]->get_char;
        for my $j ( 0 .. $#char ) {
            if ( $char[$j] eq $match ) {
                $char[$j] = $firstseq[$j];
            }
        }
        $seqs[$i]->set_char(@char);
    }
    1;
}

sub id {
    my ( $self, $name ) = @_;
    if ( defined $name ) {
        $self->set_name( $name );
    }
    return $self->get_name;
}

sub missing_char {
    my ( $self, $missing ) = @_;
    if ( defined $missing ) {
        $self->set_missing( $missing );
    }
    return $self->get_missing;
}

sub match_char {
    my ( $self, $match ) = @_;
    if ( defined $match ) {
        $self->set_matchchar( $match );
    }
    return $self->get_matchchar;
}

sub gap_char {
    my ( $self, $gap ) = @_;
    if ( defined $gap ) {
        $self->set_gap( $gap );
    }
    return $self->get_gap;
}

sub symbol_chars {
    my ( $self, $includeextra ) = @_;
	my %seen;
	for my $row ( @{ $self->get_entities } ) {
		my @char = $row->get_char;
		$seen{$_} = 1 for @char;
	}
    return keys %seen if $includeextra;
    my $special_values = $self->get_special_symbols;
    my %special_keys   = map { $_ => 1 } values %{ $special_values };
    return grep { ! $special_keys{$_} } keys %seen;
}

sub consensus_string {
	my $self = shift;
	my $to = $self->get_type_object;
	my $ntax = $self->get_ntax;
	my $nchar = $self->get_nchar;
	my @consensus;
	for my $i ( 0 .. $ntax - 1 ) {
		my ( @column, %column );
		for my $j ( 0 .. $nchar - 1 ) {
			$column{ $self->get_by_index($i)->get_by_index($j) } = 1;
		}
		@column = keys %column;
		push @consensus, $to->get_symbol_for_states(@column);
	}
	return join '', @consensus;
}

sub consensus_iupac {
 $logger->warn 
}

sub is_flush { 1 }

sub length { shift->get_nchar }

sub maxname_length { $logger->warn }

sub no_residues { $logger->warn }

sub no_sequences {
    my $self = shift;
    return scalar @{ $self->get_entities };
}

sub percentage_identity { $logger->warn }

# from simplealign
sub average_percentage_identity{
   my ($self,@args) = @_;

   my @alphabet = ('A','B','C','D','E','F','G','H','I','J','K','L','M',
                   'N','O','P','Q','R','S','T','U','V','W','X','Y','Z');

   my ($len, $total, $subtotal, $divisor, $subdivisor, @seqs, @countHashes);

   if (! $self->is_flush()) {
       throw 'Generic' => "All sequences in the alignment must be the same length";
   }

   @seqs = $self->each_seq();
   $len = $self->length();

   # load the each hash with correct keys for existence checks

   for( my $index=0; $index < $len; $index++) {
       foreach my $letter (@alphabet) {
       		$countHashes[$index] = {} if not $countHashes[$index];
	   $countHashes[$index]->{$letter} = 0;
       }
   }
   foreach my $seq (@seqs)  {
       my @seqChars = split //, $seq->seq();
       for( my $column=0; $column < @seqChars; $column++ ) {
	   my $char = uc($seqChars[$column]);
	   if (exists $countHashes[$column]->{$char}) {
	       $countHashes[$column]->{$char}++;
	   }
       }
   }

   $total = 0;
   $divisor = 0;
   for(my $column =0; $column < $len; $column++) {
       my %hash = %{$countHashes[$column]};
       $subdivisor = 0;
       foreach my $res (keys %hash) {
	   $total += $hash{$res}*($hash{$res} - 1);
	   $subdivisor += $hash{$res};
       }
       $divisor += $subdivisor * ($subdivisor - 1);
   }
   return $divisor > 0 ? ($total / $divisor )*100.0 : 0;
}

# from simplealign
sub overall_percentage_identity{
   my ($self, $length_measure) = @_;

   my @alphabet = ('A','B','C','D','E','F','G','H','I','J','K','L','M',
                   'N','O','P','Q','R','S','T','U','V','W','X','Y','Z');

   my ($len, $total, @seqs, @countHashes);

   my %enum = map {$_ => 1} qw (align short long);

   throw 'Generic' => "Unknown argument [$length_measure]" 
       if $length_measure and not $enum{$length_measure};
   $length_measure ||= 'align';

   if (! $self->is_flush()) {
       throw 'Generic' => "All sequences in the alignment must be the same length";
   }

   @seqs = $self->each_seq();
   $len = $self->length();

   # load the each hash with correct keys for existence checks
   for( my $index=0; $index < $len; $index++) {
       foreach my $letter (@alphabet) {
       		$countHashes[$index] = {} if not $countHashes[$index];
	   $countHashes[$index]->{$letter} = 0;
       }
   }
   foreach my $seq (@seqs)  {
       my @seqChars = split //, $seq->seq();
       for( my $column=0; $column < @seqChars; $column++ ) {
	   my $char = uc($seqChars[$column]);
	   if (exists $countHashes[$column]->{$char}) {
	       $countHashes[$column]->{$char}++;
	   }
       }
   }

   $total = 0;
   for(my $column =0; $column < $len; $column++) {
       my %hash = %{$countHashes[$column]};
       foreach ( values %hash ) {
	   next if( $_ == 0 );
	   $total++ if( $_ == scalar @seqs );
	   last;
       }
   }

   if ($length_measure eq 'short') {
       ## find the shortest length
       $len = 0;
       foreach my $seq ($self->each_seq) {
           my $count = $seq->seq =~ tr/[A-Za-z]//;
           if ($len) {
               $len = $count if $count < $len;
           } else {
               $len = $count;
           }
       }
   }
   elsif ($length_measure eq 'long') {
       ## find the longest length
       $len = 0;
       foreach my $seq ($self->each_seq) {
           my $count = $seq->seq =~ tr/[A-Za-z]//;
           if ($len) {
               $len = $count if $count > $len;
           } else {
               $len = $count;
           }
       }
   }

   return ($total / $len ) * 100.0;
}

sub column_from_residue_number {
    my ( $self, $seqname, $resnumber ) = @_;
    my $col;
    if ( my $seq = $self->get_by_name($seqname) ) {
        my $gap  = $seq->get_gap;
        my @char = $seq->get_char;
        for my $i ( 0 .. $#char ) {
            $col++ if $char[$i] ne $gap;
            if ( $col + 1 == $resnumber ) {
                return $i + 1;
            }
        }
    }
}

sub displayname {
    my ( $self, $name, $disname ) = @_;
	my $seq;
	$self->visit( sub{ $seq = $_[0] if $_[0]->get_nse eq $name } );
    $self->throw("No sequence with name [$name]") unless $seq;
	my $disnames = $self->get_generic( 'displaynames' ) || {};
    if ( $disname and  $name ) {
    	$disnames->{$name} = $disname;
		return $disname;
    }
    elsif( defined $disnames->{$name} ) {
		return  $disnames->{$name};
    } 
    else {
		return $name;
    }
}

# from SimpleAlign
sub maxdisplayname_length {
    my $self = shift;
    my $maxname = (-1);
    my ($seq,$len);
    foreach $seq ( $self->each_seq() ) {
		$len = CORE::length $self->displayname($seq->get_nse());	
		if( $len > $maxname ) {
		    $maxname = $len;
		}
    }
    return $maxname;
}

# from SimpleAlign
sub set_displayname_flat {
    my $self = shift;
    my ($nse,$seq);

    foreach $seq ( $self->each_seq() ) {
	$nse = $seq->get_nse();
	$self->displayname($nse,$seq->id());
    }
    return 1;
}

sub set_displayname_count { $logger->warn }

sub set_displayname_normal { $logger->warn }

sub accession {
	my ( $self, $acc ) = @_;
	if ( defined $acc ) {
		$self->set_generic( 'accession' => $acc );
	}
	return $self->get_generic( 'accession' );
}

sub source {
	my ( $self, $source ) = @_;
	if ( defined $source ) {
		$self->set_generic( 'source' => $source );
	}
	return $self->get_generic( 'source' );
}

sub annotation {
	my ( $self, $anno ) = @_;
	if ( defined $anno ) {
		$self->set_generic( 'annotation' => $anno );
	}
	return $self->get_generic( 'annotation' );
}

sub consensus_meta {
	my ( $self, $meta ) = @_;
	if ( defined $meta ) {
		$self->set_generic( 'consensus_meta' => $meta );
	}
	return $self->get_generic( 'consensus_meta' );
}

# XXX this might be removed, and instead inherit from SimpleAlign
sub max_metaname_length {
    my $self = shift;
    my $maxname = (-1);
    my ($seq,$len);
    
    # check seq meta first
    for $seq ( $self->each_seq() ) {
        next if !$seq->isa('Bio::Seq::MetaI' || !$seq->meta_names);
        for my $mtag ($seq->meta_names) {
            $len = CORE::length $mtag;
            if( $len > $maxname ) {
                $maxname = $len;
            }
        }
    }
    
    # alignment meta
    for my $meta ($self->consensus_meta) {
        next unless $meta;
        for my $name ($meta->meta_names) {
            $len = CORE::length $name;
            if( $len > $maxname ) {
                $maxname = $len;
            }
        }
    }

    return $maxname;
}



