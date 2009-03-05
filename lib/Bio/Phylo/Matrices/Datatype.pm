# $Id: Datatype.pm 844 2009-03-05 00:07:26Z rvos $
package Bio::Phylo::Matrices::Datatype;
use Bio::Phylo::Util::XMLWritable;
use Bio::Phylo::Util::Exceptions 'throw';
use Bio::Phylo::Util::CONSTANT 'looks_like_hash';
use strict;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Util::XMLWritable);

{
 
 	my $logger = __PACKAGE__->get_logger;
    
    my @fields = \( my ( %lookup, %missing, %gap ) );

=head1 NAME

Bio::Phylo::Matrices::Datatype - Validator of character state data

=head1 SYNOPSIS

 # No direct usage

=head1 DESCRIPTION

This is a superclass for objects that validate character data. Objects that
inherit from this class (typically those in the
Bio::Phylo::Matrices::Datatype::* namespace) can check strings and arrays of
character data for invalid symbols, and split and join strings and arrays
in a way appropriate for the type (on whitespace for continuous data,
on single characters for categorical data).
L<Bio::Phylo::Matrices::Matrix> objects and L<Bio::Phylo::Matrices::Datum>
internally delegate validation of their contents to these datatype objects;
there is no normal usage in which you'd have to deal with datatype objects 
directly.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

Datatype constructor.

 Type    : Constructor
 Title   : new
 Usage   : No direct usage, is called by TypeSafaData classes;
 Function: Instantiates a Datatype object
 Returns : a Bio::Phylo::Matrices::Datatype child class
 Args    : $type (optional, one of continuous, custom, dna,
           mixed, protein, restriction, rna, standard)

=cut

    sub new {
        my $package = shift;
        my $type = ucfirst( lc( shift ) );
        if ( not $type ) {
        	throw 'BadArgs' => "No subtype specified!";
        }
        if ( $type eq 'Nucleotide' ) {
            $logger->warn("'nucleotide' datatype requested, using 'dna'");
            $type = 'Dna';
        }
        my $typeclass = __PACKAGE__ . '::' . $type;
        my $self      = __PACKAGE__->SUPER::new( '-tag' => 'states' ); 
        eval "require $typeclass";
        if ( $@ ) {
        	throw 'BadFormat' => "'$type' is not a valid datatype";
        }
        else {
            return $typeclass->_new( $self, @_ );
        }
    }
    
    sub _new { 
        my $class = shift;
        my $self  = shift;
        my ( $lookup, $missing, $gap );
        {
            no strict 'refs';
            $lookup  = ${ $class . '::LOOKUP'  };
            $missing = ${ $class . '::MISSING' }; 
            $gap     = ${ $class . '::GAP'     };
            use strict;
        }
        bless $self, $class;
        $self->set_lookup(  $lookup  ) if defined $lookup;
        $self->set_missing( $missing ) if defined $missing;
        $self->set_gap(     $gap     ) if defined $gap;
        
		# process further args
		while ( my @args = looks_like_hash @_ ) {

			my $key   = shift @args;
			my $value = shift @args;

			# notify user
			$logger->debug("processing arg '$key'");

			# don't access data structures directly, call mutators
			# in child classes or __PACKAGE__
			my $mutator = $key;
			$mutator =~ s/^-/set_/;

			# backward compat fixes:
			$mutator =~ s/^set_pos$/set_position/;
			$mutator =~ s/^set_matrix$/set_raw/;
			
			# bad argument?
			eval {
				$self->$mutator($value);
			};
			if ( $@ and not ref $@ and $@ =~ m/^Can't locate object method/ ) {
				throw 'UnknownMethod' => "Processing argument '$key' as method '$mutator' failed: $@";
			}
			elsif ( UNIVERSAL::isa( $@, 'Bio::Phylo::Util::Exceptions') ) {
				$@->rethrow;
			}
		}         
        
        return $self;
    }

=back

=head2 MUTATORS

=over

=item set_lookup()

Sets state lookup table.

 Type    : Mutator
 Title   : set_lookup
 Usage   : $obj->set_lookup($hashref);
 Function: Sets the state lookup table.
 Returns : Modified object.
 Args    : Argument must be a hash
           reference that maps allowed
           single character symbols
           (including ambiguity symbols)
           onto the equivalent set of
           non-ambiguous symbols

=cut

    sub set_lookup {
        my ( $self, $lookup ) = @_;
        my $id = $$self;
        
        # we have a value
        if ( defined $lookup ) {
            if ( UNIVERSAL::isa( $lookup, 'HASH' ) ) {
                $lookup{$id} = $lookup;
            }
            else {
            	throw 'BadArgs' => "lookup must be a hash reference";
            }
        }
        
        # no value, so must be a reset
        else {
            $lookup{$id} = $self->get_lookup;
        }
        return $self;
    }

=item set_missing()

Sets missing data symbol.

 Type    : Mutator
 Title   : set_missing
 Usage   : $obj->set_missing('?');
 Function: Sets the symbol for missing data
 Returns : Modified object.
 Args    : Argument must be a single
           character, default is '?'

=cut

    sub set_missing {
        my ( $self, $missing ) = @_;
        my $id = $$self;
        if ( $missing ne $self->get_gap ) {
        	$missing{$id} = $missing;
        }
        else {
        	throw 'BadArgs' => "Missing character '$missing' already in use as gap character";
        }
        return $self;
    }

=item set_gap()

Sets gap symbol.

 Type    : Mutator
 Title   : set_gap
 Usage   : $obj->set_gap('-');
 Function: Sets the symbol for gaps
 Returns : Modified object.
 Args    : Argument must be a single
           character, default is '-'

=cut

    sub set_gap {
        my ( $self, $gap ) = @_;
        if ( not $gap eq $self->get_missing ) {
        	$gap{ $self->get_id } = $gap;
        }
        else {
        	throw 'BadArgs' => "Gap character '$gap' already in use as missing character";
        }
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_type()

Gets data type as string.

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $obj->get_type;
 Function: Returns the object's datatype
 Returns : A string
 Args    : None

=cut

    sub get_type {
        my $type = ref shift;
        $type =~ s/.*:://;
        return $type;
    }

=item get_ids_for_states()

Gets state-to-id mapping

 Type    : Accessor
 Title   : get_ids_for_states
 Usage   : my %ids = %{ $obj->get_ids_for_states };
 Function: Returns the object's datatype
 Returns : A hash reference, keyed on state, with UID values
 Args    : None

=cut
    
    sub get_ids_for_states {
    	my $self = shift;
    	if ( my $lookup = $self->get_lookup ) {
    		my $i = 1;
    		my $ids_for_states = {};
    		my ( @states, @tmp_cats ); 
    		my @tmp = sort { $a->[1] <=> $b->[1] } 
    		           map { [ $_, scalar @{ $lookup->{$_} } ] } 
    		         keys %{ $lookup };
    		for my $state ( @tmp ) {
    			my $count = $state->[1];
    			my $sym   = $state->[0];
    			if ( not $tmp_cats[$count] ) {
    				$tmp_cats[$count] = [];
    			}
    			push @{ $tmp_cats[$count] }, $sym;
    		}
    		for my $cat ( @tmp_cats ) {
    			if ( $cat ) {
    				my @sorted = sort { $a cmp $b } @{ $cat };
    				push @states, @sorted;
    			}
    		}
    		for my $state ( @states ) {
    			my $id = $i++;
    			$ids_for_states->{$state} = $_[0] ? "s${id}" : $id;
    		}
    		return $ids_for_states;
    	}
    	else {
    		return {};
    	}
    }

=item get_symbol_for_states()

Gets ambiguity symbol for a set of states

 Type    : Accessor
 Title   : get_symbol_for_states
 Usage   : my $state = $obj->get_symbol_for_states('A','C');
 Function: Returns the ambiguity symbol for a set of states
 Returns : A symbol (SCALAR)
 Args    : A set of symbols
 Comments: If no symbol exists in the lookup
           table for the given set of states,
           a new - numerical - one is created

=cut

	sub get_symbol_for_states {
		my $self = shift;
		my @syms = @_;
		my $lookup = $self->get_lookup;
		if ( $lookup ) {
			my @lookup_syms = keys %{ $lookup };
			SYM: for my $sym ( @lookup_syms ) {
				my @states = @{ $lookup->{$sym} };
				if ( scalar @syms == scalar @states ) {
					my $seen_all = 0;
					for my $i ( 0 .. $#syms ) {
						my $seen = 0;
						for my $j ( 0 .. $#states ) {
							if ( $syms[$i] eq $states[$j] ) {
								$seen++;
								$seen_all++;
							}
						}
						next SYM if not $seen;
					}
					# found existing symbol
					return $sym if $seen_all == scalar @syms;
				}
			}
			# create new symbol
			my $sym;
			
			if ( $self->get_type !~ /standard/i ) {
				my $sym = 0;
				while ( exists $lookup->{$sym} ) {
					$sym++;
				}
			}
			else {
				LETTER: for my $char ( 'A' .. 'Z' ) {
					if ( not exists $lookup->{$char} ) {
						$sym = $char;
						last LETTER;
					}
				}
			}
			
			$lookup->{$sym} = \@syms;
			$self->set_lookup($lookup);
			return $sym;
		}
		else {
			$logger->info("No lookup table!");
			return;
		}
	}

=item get_lookup()

Gets state lookup table.

 Type    : Accessor
 Title   : get_lookup
 Usage   : my $lookup = $obj->get_lookup;
 Function: Returns the object's lookup hash
 Returns : A hash reference
 Args    : None

=cut

    sub get_lookup {
        my $self = shift;
        my $id = $self->get_id;
        if ( exists $lookup{$id} ) {
            return $lookup{$id};
        }
        else {
           my $class = ref $self;
           my $lookup;
           {
                no strict 'refs';
                $lookup = ${ $class . '::LOOKUP'  };
                use strict;
           }
           $self->set_lookup( $lookup );
           return $lookup;
        }
    }

=item get_missing()

Gets missing data symbol.

 Type    : Accessor
 Title   : get_missing
 Usage   : my $missing = $obj->get_missing;
 Function: Returns the object's missing data symbol
 Returns : A string
 Args    : None

=cut

    sub get_missing {
    	my $self = shift;
        my $missing = $missing{$$self};
        return defined $missing ? $missing : '?';
    }

=item get_gap()

Gets gap symbol.

 Type    : Accessor
 Title   : get_gap
 Usage   : my $gap = $obj->get_gap;
 Function: Returns the object's gap symbol
 Returns : A string
 Args    : None

=cut

    sub get_gap {
    	my $self = shift;    	
        my $gap = $gap{$$self};
        return defined $gap ? $gap : '-';
    }

=back

=head2 TESTS

=over

=item is_valid()

Validates argument.

 Type    : Test
 Title   : is_valid
 Usage   : if ( $obj->is_valid($datum) ) {
              # do something
           }
 Function: Returns true if $datum only contains valid characters
 Returns : BOOLEAN
 Args    : A Bio::Phylo::Matrices::Datum object

=cut

    sub is_valid {
        my $self = shift;        
        my @data;
        for my $arg ( @_ ) {
        	if ( UNIVERSAL::can( $arg, 'get_char') ) {
        		push @data, $arg->get_char;
        	}
        	elsif ( UNIVERSAL::isa( $arg, 'ARRAY') ) {
        		push @data, @{ $arg };
        	}
        	else {
        		if ( length($arg) > 1 ) {
        			push @data, @{ $self->split( $arg ) };
        		}
        		else {
        			push @data, $arg;
        		}
        	}
        }
        return 1 if not @data;
        my $lookup = $self->get_lookup;
        my ( $missing, $gap ) = ( $self->get_missing, $self->get_gap );
        CHAR_CHECK: for my $char ( @data ) {            
            next CHAR_CHECK if not defined $char;
            my $uc = uc $char;
            if ( exists $lookup->{$uc} || ( defined $missing && $uc eq $missing ) || ( defined $gap && $uc eq $gap ) ) {
                next CHAR_CHECK;
            }
            else {
                return 0;
            }
        }
        return 1;
    }

=item is_same()

Compares data type objects.

 Type    : Test
 Title   : is_same
 Usage   : if ( $obj->is_same($obj1) ) {
              # do something
           }
 Function: Returns true if $obj1 contains the same validation rules
 Returns : BOOLEAN
 Args    : A Bio::Phylo::Matrices::Datatype::* object

=cut

    sub is_same {
        my ( $self, $model ) = @_;
        $logger->info("Comparing datatype '$self' to '$model'");
        return 1 if $self->get_id   == $model->get_id;
        return 0 if $self->get_type ne $model->get_type;
        
        # check strings
        for my $prop ( qw(get_type get_missing get_gap) ) {
            my ( $self_prop, $model_prop ) = ( $self->$prop, $model->$prop );
            return 0 if defined $self_prop && defined $model_prop && $self_prop ne $model_prop;
        }
        my ( $s_lookup, $m_lookup ) = ( $self->get_lookup, $model->get_lookup );
    
        # one has lookup, other hasn't
        if ( $s_lookup && ! $m_lookup ) {
            return 0;
        }
    
        # both don't have lookup -> are continuous
        if ( ! $s_lookup && ! $m_lookup ) {
            return 1;
        }
    
        # get keys
        my @s_keys = keys %{ $s_lookup };
        my @m_keys = keys %{ $m_lookup };
    
        # different number of keys
        if ( scalar( @s_keys ) != scalar( @m_keys ) ) {
            return 0;
        }
        
        # compare keys
        for my $key ( @s_keys ) {
            if ( not exists $m_lookup->{$key} ) {
                return 0;
            }
            else {
                # compare values
                my ( %s_vals, %m_vals );
                my ( @s_vals, @m_vals );
                @s_vals = @{ $s_lookup->{$key} };
                @m_vals = @{ $m_lookup->{$key} };
                
                # different number of vals
                if ( scalar( @m_vals ) != scalar( @s_vals ) ) {
                    return 0;
                }
                
                # make hashes to compare on vals
                %s_vals = map { $_ => 1 } @s_vals;
                %m_vals = map { $_ => 1 } @m_vals;                      
                for my $val ( keys %s_vals ) {
                    return 0 if not exists $m_vals{$val};
                }
            }
        }
        return 1;
    }

=back

=head2 UTILITY METHODS

=over

=item split()

Splits argument string of characters following appropriate rules.

 Type    : Utility method
 Title   : split
 Usage   : $obj->split($string)
 Function: Splits $string into characters
 Returns : An array reference of characters
 Args    : A string

=cut

    sub split {
        my ( $self, $string ) = @_;
        my @array = CORE::split( /\s*/, $string );
        return \@array;
    }

=item join()

Joins argument array ref of characters following appropriate rules.

 Type    : Utility method
 Title   : join
 Usage   : $obj->join($arrayref)
 Function: Joins $arrayref into a string
 Returns : A string
 Args    : An array reference

=cut

    sub join {
        my ( $self, $array ) = @_;
        return CORE::join( '', @{ $array } );
    }
    
    sub _cleanup {
        my $self = shift;
        $logger->debug("cleaning up '$self'");
        my $id = $self->get_id;
        for my $field ( @fields ) {
            delete $field->{$id};
        }
    }

=back

=head2 SERIALIZERS

=over

=item to_xml()

Writes data type definitions to xml

 Type    : Serializer
 Title   : to_xml
 Usage   : my $xml = $obj->to_xml
 Function: Writes data type definitions to xml
 Returns : An xml string representation of data type definition
 Args    : None

=cut

	sub to_xml {
		my $self = shift;	
		my $xml = '';
		my $normalized = {};
		$normalized = shift if @_;
		if ( my $lookup = $self->get_lookup ) {
			$xml .= "\n" . $self->get_xml_tag;
			my $id_for_state = $self->get_ids_for_states;
			my @states = sort { $id_for_state->{$a} <=> $id_for_state->{$b} } keys %{ $id_for_state };
			for my $state ( @states ) {
				my $state_id = $id_for_state->{ $state };
				$id_for_state->{ $state } = 's' . $state_id;
			}
			for my $state ( @states ) {
				my $state_id = $id_for_state->{ $state };
				my @mapping = @{ $lookup->{$state} };
				my $symbol = exists $normalized->{$state} ? $normalized->{$state} : $state;
				
				# has ambiguity mappings
				if ( scalar @mapping > 1 ) {
					$xml .= "\n" . sprintf('<state id="%s" symbol="%s">', $state_id, $symbol);
					for my $map ( @mapping ) {
						$xml .= "\n" . sprintf( '<mapping state="%s" mstaxa="uncertainty"/>', $id_for_state->{ $map } );
					}
					$xml .= "\n</state>";
				}
				
				# no ambiguity
				else {
					$xml .= "\n" . sprintf('<state id="%s" symbol="%s"/>', $state_id, $symbol);
				}
			}
			$xml .= "\n</states>";
		}	
		return $xml;	
	}

=back

=cut

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:41 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Matrices::Datatype inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Matrices::Datatype also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::Util::XMLWritable

Bio::Phylo::Matrices::Datatype inherits from superclass L<Bio::Phylo::Util::XMLWritable>. 
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

Bio::Phylo::Matrices::Datatype inherits from superclass L<Bio::Phylo>. 
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

=cut

# podinherit_stop_token_do_not_remove

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

This object inherits from L<Bio::Phylo>, so the methods defined
therein are also applicable to L<Bio::Phylo::Matrices::Datatype> objects.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: Datatype.pm 844 2009-03-05 00:07:26Z rvos $

=cut

}

1;