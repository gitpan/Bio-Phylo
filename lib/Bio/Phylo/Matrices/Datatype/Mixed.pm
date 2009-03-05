# $Id: Mixed.pm 844 2009-03-05 00:07:26Z rvos $
package Bio::Phylo::Matrices::Datatype::Mixed;
use strict;
use Bio::Phylo::Matrices::Datatype;
use Bio::Phylo::Util::Exceptions 'throw';
use vars '@ISA';
@ISA = qw(Bio::Phylo::Matrices::Datatype);

{

=head1 NAME

Bio::Phylo::Matrices::Datatype::Mixed - Validator subclass,
no serviceable parts inside

=head1 DESCRIPTION

The Bio::Phylo::Matrices::Datatype::* classes are used to validate data
contained by L<Bio::Phylo::Matrices::Matrix> and L<Bio::Phylo::Matrices::Datum>
objects.

=cut   

    my @fields = \( my ( %range, %missing, %gap ) );
    
    sub _new { 
        my ( $package, $self, $ranges ) = @_;
        if ( not UNIVERSAL::isa( $ranges, 'ARRAY' ) ) {
            throw 'BadArgs' => "No type ranges specified for 'mixed' data type!"; 
        }
        my $id = $self->get_id;
        $range{   $id } = [];
        $missing{ $id } = '?';
        $gap{     $id } = '-';
        my $start = 0;
        for ( my $i = 0; $i <= ( $#{ $ranges } - 1 ); $i += 2 ) {
            my $type = $ranges->[ $i     ];
            my $arg  = $ranges->[ $i + 1 ];
            my ( @args, $length );
            if ( UNIVERSAL::isa( $arg, 'HASH' ) ) {
                $length = $arg->{'-length'};
                @args   = @{ $arg->{'-args'} };
            }
            else {
                $length = $arg;
            }
            my $end = $length + $start - 1;
            my $obj = Bio::Phylo::Matrices::Datatype->new( $type, @args );
            $range{$id}->[$_] = $obj for ( $start .. $end );
            $start = ++$end;
        }
        return bless $self, $package;
    }

=head1 METHODS

=head2 MUTATORS

=over

=item set_missing()

Sets the symbol for missing data.

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
        if ( not $missing eq $self->get_gap ) {
        	$missing{ $self->get_id } = $missing;
        }
        else {
        	throw 'BadArgs' => "Missing character '$missing' already in use as gap character";
        }        
        return $self;
    }

=item set_gap()

Sets the symbol for gaps.

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

=item get_missing()

Returns the object's missing data symbol.

 Type    : Accessor
 Title   : get_missing
 Usage   : my $missing = $obj->get_missing;
 Function: Returns the object's missing data symbol
 Returns : A string
 Args    : None

=cut

    sub get_missing { return $missing{ shift->get_id } }

=item get_gap()

Returns the object's gap symbol.

 Type    : Accessor
 Title   : get_gap
 Usage   : my $gap = $obj->get_gap;
 Function: Returns the object's gap symbol
 Returns : A string
 Args    : None

=cut

    sub get_gap { return $gap{ shift->get_id } }
    
    my $get_ranges = sub { $range{ shift->get_id } };

=item get_type()

Returns the object's datatype as string.

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $obj->get_type;
 Function: Returns the object's datatype
 Returns : A string
 Args    : None

=cut

    sub get_type {
        my $self = shift;
        my $string = 'mixed(';
        my $last;
        my $range = $self->$get_ranges;
        MODEL_RANGE_CHECK: for my $i ( 0 .. $#{ $range } ) {
            if ( $i == 0 ) {
                $string .= $range->[$i]->get_type . ":1-";
                $last = $range->[$i];
            }
            elsif ( $range->[$i] != $last ) {
                $last = $range->[$i];
                $string .= "$i, " . $last->get_type . ":" . ( $i + 1 ) . "-";
            }
            else {
                next MODEL_RANGE_CHECK;
            }		
        }
        $string .= scalar( @{ $range } ) . ")";
        return $string;
    }

=item get_type_for_site()

Returns type object for site number.

 Type    : Accessor
 Title   : get_type_for_site
 Usage   : my $type = $obj->get_type_for_site(1);
 Function: Returns data type object for site
 Returns : A Bio::Phylo::Matrices::Datatype object
 Args    : None

=cut

    sub get_type_for_site {
        my ( $self, $i ) = @_;     
        if ( exists $range{ $self->get_id }->[$i] ) {
        	return $range{ $self->get_id }->[$i];
        }
        else {
        	return $range{ $self->get_id }->[-1];
        }
    }    

=back

=head2 TESTS

=over

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
		my ( $self, $obj ) = @_;
		my $id = $self->get_id;
		return 1 if $id == $obj->get_id;
		return 0 if $self->get_type    ne $obj->get_type;
		return 0 if $self->get_gap     ne $obj->get_gap;
		return 0 if $self->get_missing ne $obj->get_missing;
		for my $i ( 0 .. $#{ $range{ $self->get_id } } ) {
			if ( my $subtype = $range{ $self->get_id }->[$i] ) {
				return 0 if not $subtype->is_same( $obj->get_type_for_site($i) );
			}
		}
		return 1;		
	}

=item is_valid()

Returns true if argument only contains valid characters

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
        my $datum = $_[0];
        my $is_datum_object;
        my ( $start, $end );
        if ( UNIVERSAL::can( $datum, 'get_position') and UNIVERSAL::can( $datum, 'get_length' ) ) {
        	( $start, $end ) = ( $datum->get_position - 1, $datum->get_length - 1 );
        	$is_datum_object = 1;
        }
        else {
        	$start = 0;
        	$end = $#_;
        }     
        my $ranges = $self->$get_ranges;
        my $type;
		MODEL_RANGE_CHECK: for my $i ( $start .. $end ) {
    		if ( not $type ) {
        		$type = $ranges->[$i];
            }
		    elsif ( $type != $ranges->[$i] ) {
    		    #die; # needs to slice
    		    return 1; # TODO
        	}
            else {
	            next MODEL_RANGE_CHECK;
	    	   }
    	}
    	if ( $is_datum_object ) {
        	return $type->is_valid( $datum );
    	}
    	else {
    		return 1; # FIXME
    	}
    }
    
    sub DESTROY {
        my $self = shift;
        my $id = $self->get_id;
        for my $field ( @fields ) {
            delete $field->{$id};
        }
    }

}

=back

=cut

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:50 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Matrices::Datatype::Mixed inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Matrices::Datatype::Mixed also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::Matrices::Datatype

Bio::Phylo::Matrices::Datatype::Mixed inherits from superclass L<Bio::Phylo::Matrices::Datatype>. 
Below are the public methods (if any) from this superclass.

=over

=item get_gap()

Gets gap symbol.

 Type    : Accessor
 Title   : get_gap
 Usage   : my $gap = $obj->get_gap;
 Function: Returns the object's gap symbol
 Returns : A string
 Args    : None

=item get_ids_for_states()

Gets state-to-id mapping

 Type    : Accessor
 Title   : get_ids_for_states
 Usage   : my %ids = %{ $obj->get_ids_for_states };
 Function: Returns the object's datatype
 Returns : A hash reference, keyed on state, with UID values
 Args    : None

=item get_logger()

Gets a logger object.

 Type    : Accessor
 Title   : get_logger
 Usage   : my $logger = $obj->get_logger;
 Function: Returns a Bio::Phylo::Util::Logger object
 Returns : Bio::Phylo::Util::Logger
 Args    : None

=item get_lookup()

Gets state lookup table.

 Type    : Accessor
 Title   : get_lookup
 Usage   : my $lookup = $obj->get_lookup;
 Function: Returns the object's lookup hash
 Returns : A hash reference
 Args    : None

=item get_missing()

Gets missing data symbol.

 Type    : Accessor
 Title   : get_missing
 Usage   : my $missing = $obj->get_missing;
 Function: Returns the object's missing data symbol
 Returns : A string
 Args    : None

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

=item get_type()

Gets data type as string.

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $obj->get_type;
 Function: Returns the object's datatype
 Returns : A string
 Args    : None

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

=item join()

Joins argument array ref of characters following appropriate rules.

 Type    : Utility method
 Title   : join
 Usage   : $obj->join($arrayref)
 Function: Joins $arrayref into a string
 Returns : A string
 Args    : An array reference

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

=item set_gap()

Sets gap symbol.

 Type    : Mutator
 Title   : set_gap
 Usage   : $obj->set_gap('-');
 Function: Sets the symbol for gaps
 Returns : Modified object.
 Args    : Argument must be a single
           character, default is '-'

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

=item set_missing()

Sets missing data symbol.

 Type    : Mutator
 Title   : set_missing
 Usage   : $obj->set_missing('?');
 Function: Sets the symbol for missing data
 Returns : Modified object.
 Args    : Argument must be a single
           character, default is '?'

=item split()

Splits argument string of characters following appropriate rules.

 Type    : Utility method
 Title   : split
 Usage   : $obj->split($string)
 Function: Splits $string into characters
 Returns : An array reference of characters
 Args    : A string

=item to_xml()

Serializes invocant to XML.

 Type    : XML serializer
 Title   : to_xml
 Usage   : my $xml = $obj->to_xml;
 Function: Serializes $obj to xml
 Returns : An xml string
 Args    : None

=back

=head2 SUPERCLASS Bio::Phylo::Util::XMLWritable

Bio::Phylo::Matrices::Datatype::Mixed inherits from superclass L<Bio::Phylo::Util::XMLWritable>. 
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

Bio::Phylo::Matrices::Datatype::Mixed inherits from superclass L<Bio::Phylo>. 
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

=item L<Bio::Phylo::Matrices::Datatype>

This object inherits from L<Bio::Phylo::Matrices::Datatype>, so the methods defined
therein are also applicable to L<Bio::Phylo::Matrices::Datatype::Mixed>
objects.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: Mixed.pm 844 2009-03-05 00:07:26Z rvos $

=cut

1;