# $Id: Taxon.pm 844 2009-03-05 00:07:26Z rvos $
package Bio::Phylo::Taxa::Taxon;
use strict;
use Bio::Phylo::Util::XMLWritable;
use Bio::Phylo::Util::CONSTANT qw(_DATUM_ _NODE_ _TAXON_ _TAXA_ looks_like_object);
use Bio::Phylo::Mediators::TaxaMediator;
use vars qw(@ISA);

# classic @ISA manipulation, not using 'base'
@ISA = qw(Bio::Phylo::Util::XMLWritable);
{
	
	my $TYPE_CONSTANT      = _TAXON_;
	my $CONTAINER_CONSTANT = _TAXA_;
	my $DATUM_CONSTANT     = _DATUM_;
	my $NODE_CONSTANT      = _NODE_;

	my $logger   = __PACKAGE__->get_logger;
	my $mediator = 'Bio::Phylo::Mediators::TaxaMediator';

=head1 NAME

Bio::Phylo::Taxa::Taxon - Operational taxonomic unit

=head1 SYNOPSIS

 use Bio::Phylo::IO qw(parse);
 use Bio::Phylo::Factory;
 my $fac = Bio::Phylo::Factory->new;

 # array of names
 my @apes = qw(
     Homo_sapiens
     Pan_paniscus
     Pan_troglodytes
     Gorilla_gorilla
 );

 # newick string
 my $str = '(((Pan_paniscus,Pan_troglodytes),';
 $str   .= 'Homo_sapiens),Gorilla_gorilla);';

 # create tree object
 my $tree = parse(
    -format => 'newick',
    -string => $str
 )->first;

 # instantiate taxa object
 my $taxa = $fac->create_taxa;

 # instantiate taxon objects, insert in taxa object
 foreach( @apes ) {
    my $taxon = $fac->create_taxon(
        -name => $_,
    );
    $taxa->insert($taxon);
 }

 # crossreference tree and taxa
 $tree->crossreference($taxa);

 # iterate over nodes
 while ( my $node = $tree->next ) {

    # check references
    if ( $node->get_taxon ) {

        # prints crossreferenced tips
        print "match: ", $node->get_name, "\n";
    }
 }

=head1 DESCRIPTION

The taxon object models a single operational taxonomic unit. It is useful for
cross-referencing datum objects and tree nodes.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

Taxon constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $taxon = Bio::Phylo::Taxa::Taxon->new;
 Function: Instantiates a Bio::Phylo::Taxa::Taxon
           object.
 Returns : A Bio::Phylo::Taxa::Taxon object.
 Args    : none.

=cut

    sub new {
        # could be child class
        my $class = shift;
        
        # notify user
        $logger->info("constructor called for '$class'");
        
        # go up inheritance tree, eventually get an ID
        return $class->SUPER::new( '-tag' => 'otu', @_ );
    }

=back

=head2 MUTATORS

=over

=item set_data()

Associates argument data with invocant.

 Type    : Mutator
 Title   : set_data
 Usage   : $taxon->set_data( $datum );
 Function: Associates data with
           the current taxon.
 Returns : Modified object.
 Args    : Must be an object of type
           Bio::Phylo::Matrices::Datum

=cut

    sub set_data {
        my ( $self, $datum ) = @_;
        if ( looks_like_object $datum, $DATUM_CONSTANT ) {
            $mediator->set_link( 
                    '-one'  => $self, 
                    '-many' => $datum, 
            );
        }
        return $self;
    }

=item set_nodes()

Associates argument node with invocant.

 Type    : Mutator
 Title   : set_nodes
 Usage   : $taxon->set_nodes($node);
 Function: Associates tree nodes
           with the current taxon.
 Returns : Modified object.
 Args    : A Bio::Phylo::Forest::Node object

=cut

    sub set_nodes {
        my ( $self, $node ) = @_;
        if ( looks_like_object $node, $NODE_CONSTANT ) {        
            $mediator->set_link( 
                '-one'  => $self, 
                '-many' => $node, 
            );
        }       
        return $self;
    }

=item unset_datum()

Removes association between argument data and invocant.

 Type    : Mutator
 Title   : unset_datum
 Usage   : $taxon->unset_datum($node);
 Function: Disassociates datum from
           the invocant taxon (i.e.
           removes reference).
 Returns : Modified object.
 Args    : A Bio::Phylo::Matrix::Datum object

=cut

    sub unset_datum {
        my ( $self, $datum ) = @_;
        $mediator->remove_link( 
            '-one'  => $self, 
            '-many' => $datum,
        );
        return $self;
    }

=item unset_node()

Removes association between argument node and invocant.

 Type    : Mutator
 Title   : unset_node
 Usage   : $taxon->unset_node($node);
 Function: Disassociates tree node from
           the invocant taxon (i.e.
           removes reference).
 Returns : Modified object.
 Args    : A Bio::Phylo::Forest::Node object

=cut

    sub unset_node {
        my ( $self, $node ) = @_;
        $mediator->remove_link( 
            '-one'  => $self, 
            '-many' => $node,
        );
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_data()

Retrieves associated datum objects.

 Type    : Accessor
 Title   : get_data
 Usage   : @data = @{ $taxon->get_data };
 Function: Retrieves data associated
           with the current taxon.
 Returns : An ARRAY reference of
           Bio::Phylo::Matrices::Datum
           objects.
 Args    : None.

=cut

    sub get_data {
        my $self = shift;
        return $mediator->get_link( 
            '-source' => $self, 
            '-type'   => $DATUM_CONSTANT,
        );
    }

=item get_nodes()

Retrieves associated node objects.

 Type    : Accessor
 Title   : get_nodes
 Usage   : @nodes = @{ $taxon->get_nodes };
 Function: Retrieves tree nodes associated
           with the current taxon.
 Returns : An ARRAY reference of
           Bio::Phylo::Trees::Node objects
 Args    : None.

=cut

    sub get_nodes {
        my $self = shift;
        return $mediator->get_link( 
            '-source' => $self, 
            '-type'   => $NODE_CONSTANT,
        );
    }

=begin comment

Taxon destructor.

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

=end comment

=cut

    sub DESTROY {
        my $self = shift;
        
        # notify user
        #$logger->debug("destructor called for '$self'");
        
        # recurse up inheritance tree for cleanup
        $self->SUPER::DESTROY;
    }

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $taxon->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _container { $CONTAINER_CONSTANT }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $taxon->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _type { $TYPE_CONSTANT }

=back

=cut

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:57 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Taxa::Taxon inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Taxa::Taxon also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::Util::XMLWritable

Bio::Phylo::Taxa::Taxon inherits from superclass L<Bio::Phylo::Util::XMLWritable>. 
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

Bio::Phylo::Taxa::Taxon inherits from superclass L<Bio::Phylo>. 
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

The taxon objects inherits from the L<Bio::Phylo> object. The methods defined
there are also applicable to the taxon object.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: Taxon.pm 844 2009-03-05 00:07:26Z rvos $

=cut

}
1;
