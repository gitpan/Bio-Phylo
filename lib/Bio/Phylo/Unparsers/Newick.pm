# $Id: Newick.pm 843 2009-03-04 23:50:27Z rvos $
package Bio::Phylo::Unparsers::Newick;
use strict;
use Bio::Phylo::Forest::Tree;
use Bio::Phylo::IO;
use vars qw(@ISA);

@ISA=qw(Bio::Phylo::IO);

=head1 NAME

Bio::Phylo::Unparsers::Newick - Serializer used by Bio::Phylo::IO, no serviceable parts inside

=head1 DESCRIPTION

This module turns a tree object into a newick formatted (parenthetical) tree
description. It is called by the L<Bio::Phylo::IO> facade, don't call it
directly. You can pass the following additional arguments to the unparse
call:
	
	# by default, names for tips are derived from $node->get_name, if 
	# 'internal' is specified, uses $node->get_internal_name, if 'taxon'
	# uses $node->get_taxon->get_name, if 'taxon_internal' uses 
	# $node->get_taxon->get_internal_name, if $key, uses $node->get_generic($key)
	-tipnames => one of (internal|taxon|taxon_internal|$key)
	
	# for things like a translate table in nexus, or to specify truncated
	# 10-character names, you can pass a translate mapping as a hashref.
	# to generate the translated names, the strings obtained following the
	# -tipnames rules are used.
	-translate => { Homo_sapiens => 1, Pan_paniscus => 2 }	
	
	# array ref used to specify keys, which are embedded as key/value pairs (where
	# the value is obtained from $node->get_generic($key)) in comments, 
	# formatted depending on '-nhxstyle', which could be 'nhx' (default), i.e.
	# [&&NHX:$key1=$value1:$key2=$value2] or 'mesquite', i.e. 
	# [% $key1 = $value1, $key2 = $value2 ]
	-nhxkeys => [ $key1, $key2 ]	
	
	# if set, appends labels to internal nodes (names obtained from the same
	# source as specified by '-tipnames')
	-nodelabels => 1
	
	# specifies a formatting style / dialect
	-nhxstyle => one of (mesquite|nhx)
	
	# specifies a branch length sprintf number formatting template, default is %f
	-blformat => '%e'

=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $newick = Bio::Phylo::Unparsers::Newick->_new;
 Function: Initializes a Bio::Phylo::Unparsers::Newick object.
 Returns : A Bio::Phylo::Unparsers::Newick object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = shift;
    my $self  = {};
    if (@_) {
        my %opts = @_;
        foreach my $key ( keys %opts ) {
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
 Title   : _to_string($tree)
 Usage   : $newick->_to_string($tree);
 Function: Prepares for the recursion to unparse the tree object into a
           newick string.
 Alias   :
 Returns : SCALAR
 Args    : Bio::Phylo::Forest::Tree

=end comment

=cut

sub _to_string {
    my $self = shift;
    my $tree = $self->{'PHYLO'};
    my $root = $tree->get_root;
    my %args;
    for my $key ( qw(TRANSLATE TIPNAMES NHXKEYS NODELABELS BLFORMAT NHXSTYLE) ) {
    	if ( my $val = $self->{$key} ) {
    		my $arg = '-' . lc($key);
    		$args{$arg} = $val;
    	}
    } 
    return $root->to_newick( %args );
}

=begin comment

 Type    : Unparser
 Title   : __to_string
 Usage   : $newick->__to_string($tree, $node);
 Function: Unparses the tree object into a newick string.
 Alias   :
 Returns : SCALAR
 Args    : A Bio::Phylo::Forest::Tree object. Optional: A Bio::Phylo::Forest::Node
           object, the starting point for recursion.

=end comment

=cut

{
    my $string = q{};
    #no warnings 'uninitialized';

    sub __to_string {
        my ( $self, $tree, $n ) = @_;
        if ( !$n->get_parent ) {
            if ( defined $n->get_branch_length ) {
                $string = $n->get_name . ':' . $n->get_branch_length . ';';
            }
            else {
                $string = $n->get_name ? $n->get_name . ';' : ';';
            }
        }
        elsif ( !$n->get_previous_sister ) {
            if ( defined $n->get_branch_length ) {
                $string = $n->get_name . ':' . $n->get_branch_length . $string;
            }
            else { $string = $n->get_name . $string; }
        }
        else {
            if ( defined $n->get_branch_length ) {
                $string =
                  $n->get_name . ':' . $n->get_branch_length . ',' . $string;
            }
            else { $string = $n->get_name . ',' . $string; }
        }
        if ( $n->get_first_daughter ) {
            $n      = $n->get_first_daughter;
            $string = ')' . $string;
            $self->__to_string( $tree, $n );
            while ( $n->get_next_sister ) {
                $n = $n->get_next_sister;
                $self->__to_string( $tree, $n );
            }
            $string = '(' . $string;
        }
    }
}

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:58 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Unparsers::Newick inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Unparsers::Newick also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::IO

Bio::Phylo::Unparsers::Newick inherits from superclass L<Bio::Phylo::IO>. 
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

The newick unparser is called by the L<Bio::Phylo::IO> object.
Look there to learn how to unparse newick strings.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: Newick.pm 843 2009-03-04 23:50:27Z rvos $

=cut

1;
