# $Id: Nexml.pm 843 2009-03-04 23:50:27Z rvos $
# Subversion: $Rev: 190 $
package Bio::Phylo::Unparsers::Nexml;
use strict;
use Bio::Phylo::IO;
use Bio::Phylo::Util::CONSTANT qw(:objecttypes looks_like_object);
use Bio::Phylo::Util::Exceptions 'throw';
use vars qw(@ISA $VERSION);
@ISA = qw(Bio::Phylo::IO);

# One line so MakeMaker sees it.
use Bio::Phylo; $VERSION = $Bio::Phylo::VERSION;

eval { require XML::Twig };
if ( $@ ) {
	throw 'ExtensionError' => "Error loading the XML::Twig extension: $@";
}

=head1 NAME

Bio::Phylo::Unparsers::Nexml - Serializer used by Bio::Phylo::IO, no serviceable parts inside

=head1 DESCRIPTION

This module serializes Taxa objects, Forest objects and Matrix objects
to NeXML.

=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $nex = Bio::Phylo::Unparsers::Nexus->_new;
 Function: Initializes a Bio::Phylo::Unparsers::Nexus object.
 Returns : A Bio::Phylo::Unparsers::Nexus object.
 Args    : none.

=end comment

=cut

sub _new {
	my $class = shift;
	my $self  = {};
	if (@_) {
		my %opts = @_;
		for my $key ( keys %opts ) {
			my $localkey = uc $key;
			$localkey =~ s/-//;
			unless ( ref $opts{$key} ) {
				$self->{$localkey} = uc $opts{$key};
			}
			else {
				$self->{$localkey} = $opts{$key};
			}
		}
	}
	bless $self, $class;
	return $self;
}

=begin comment

 Type    : Wrapper
 Title   : _to_string($matrix)
 Usage   : $nexus->_to_string($matrix);
 Function: Stringifies a matrix object into
           a nexus formatted table.
 Alias   :
 Returns : SCALAR
 Args    : Bio::Phylo::Matrices::Matrix;

=end comment

=cut

sub _to_string {
	my $self     = shift;
	my $taxa_obj = $self->{'PHYLO'};
	if ( $taxa_obj->can('_type') && $taxa_obj->_type != _TAXA_ ) {
		if ( $taxa_obj->can('make_taxa') ) {
			my $obj = $taxa_obj->make_taxa;
			my $attached_obj = $taxa_obj;
			for my $contained_obj ( @{ $attached_obj->get_entities } ) {
				if ( $contained_obj->_type == _DATUM_ ) {
					$contained_obj->set_name();
				}
				else {
					for my $node ( @{ $contained_obj->get_entities } ) {
						$node->set_name();
					}
				}
			}
			$taxa_obj = $obj;
		}
		else {
			throw 'ObjectMismatch' => "Object ($taxa_obj) is not a taxa object,\n and doesn't link to one";
		}
	}
# 	else {
# 		throw 'ObjectMismatch' => "Can't serialize $taxa_obj to nexml";
# 	}
	my $parse_twig = XML::Twig->new;
	my $nexml_twig = XML::Twig->new;
	my $nexml_root = XML::Twig::Elt->new(
		'nex:nexml',
		{
			'xmlns:nex'          => 'http://www.nexml.org/1.0',
			'version'            => '1.0',
			'generator'          => __PACKAGE__ . ' v.' . $VERSION,
			'xmlns:xsi'          => 'http://www.w3.org/2001/XMLSchema-instance',
			'xsi:schemaLocation' => 'http://www.nexml.org/1.0 http://www.nexml.org/1.0/nexml.xsd',
		}
	);
	eval {
		my $taxa_elt = $parse_twig->parse($taxa_obj->to_xml);
		$taxa_elt->root->paste($nexml_root);
	};
	die $@, $taxa_obj->to_xml if $@;

    if ( $taxa_obj->get_matrices ) {
        for my $characters_obj ( reverse @{ $taxa_obj->get_matrices } ) {
            eval {
                my $characters_elt = $parse_twig->parse($characters_obj->to_xml); 
                $characters_elt->root->paste( 'last_child', $nexml_root );
            };
            die $@, $characters_obj->to_xml if $@;
        }
	}
	if ( $taxa_obj->get_forests ) {
        for my $forest_obj ( reverse @{ $taxa_obj->get_forests } ) {		
            eval {
                my $forest_elt = $parse_twig->parse($forest_obj->to_xml);
                $forest_elt->root->paste( 'last_child', $nexml_root );
            };
            die $@, $forest_obj->to_xml if $@;
        }
	}
	$nexml_twig->set_root($nexml_root);
	$nexml_twig->set_xml_version('1.0');
	$nexml_twig->set_encoding('ISO-8859-1');
	$nexml_twig->set_pretty_print('indented');
	$nexml_twig->set_empty_tag_style('normal');	
	my $nexml_string = $nexml_twig->sprint();
	return $nexml_string;
}

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:58 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Unparsers::Nexml inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Unparsers::Nexml also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::IO

Bio::Phylo::Unparsers::Nexml inherits from superclass L<Bio::Phylo::IO>. 
Below are the public methods (if any) from this superclass.

=over

=item parse()

Parses a file or string.

 Type    : Class method
 Title   : parse
 Usage   : my $obj = Bio::Phylo::IO->parse(%options);
 Function: Creates (file) handle, 
           instantiates appropriate parser.
 Returns : A Bio::Phylo::* object
 Args    : -file    => (path),
            or
           -string  => (scalar),
           -format  => (description format),
           -(other) => (parser specific options)
 Comments: The parse method makes assumptions about 
           the capabilities of Bio::Phylo::Parsers::* 
           modules: i) their names match those of the
           -format => (blah) arguments, insofar that 
           ucfirst(blah) . '.pm' is an existing module; 
           ii) the modules implement a _from_handle, 
           or a _from_string method. Exceptions are 
           thrown if either assumption is violated. 
           
           If @ARGV contains even key/value pairs such
           as "format newick file <filename>" (note: no
           dashes) these will be prepended to @_, for
           one-liners.          

=item unparse()

Unparses object(s) to a string.

 Type    : Class method
 Title   : unparse
 Usage   : my $string = Bio::Phylo::IO->unparse(
               %options
           );
 Function: Turns Bio::Phylo object into a 
           string according to specified format.
 Returns : SCALAR
 Args    : -phylo   => (Bio::Phylo object),
           -format  => (description format),
           -(other) => (parser specific options)

=back

=cut

# podinherit_stop_token_do_not_remove

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The NeXML serializer is called by the L<Bio::Phylo::IO> object.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>.

=back

=head1 REVISION

 $Id: Nexml.pm 843 2009-03-04 23:50:27Z rvos $

=cut

1;


