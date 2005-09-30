# $Id: Node.pm,v 1.10 2005/09/29 20:31:17 rvosa Exp $
# Subversion: $Rev: 177 $
package Bio::Phylo::Forest::Node;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use Bio::Phylo::CONSTANT qw(_TREE_ _NODE_ _TAXON_);
use base 'Bio::Phylo';
use fields qw(PARENT
              TAXON
              BRANCH_LENGTH
              FIRST_DAUGHTER
              LAST_DAUGHTER
              NEXT_SISTER
              PREVIOUS_SISTER);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Forest::Node - The tree node object.

=head1 SYNOPSIS

 # some way to get nodes:
 use Bio::Phylo::IO;
 my $string = '((A,B),C);';
 my $forest = Bio::Phylo::IO->parse(
    -format => 'newick',
    -string => $string
 );
 print ref $forest; # prints 'Bio::Phylo::Forest'
 
 foreach my $tree ( @{ $forest->get_entities } ) {
    print ref $tree; # prints 'Bio::Phylo::Forest::Tree'
    
    foreach my $node ( @{ $tree->get_entities } ) {
       print ref $node; # prints 'Bio::Phylo::Forest::Node'
       
       # node has a parent, i.e. is not root
       if ( $node->get_parent ) {
          $node->set_branch_length(1);
       }
       
       # node is root
       else {
          $node->set_branch_length(0);
       }
    }
 }
 
 

=head1 DESCRIPTION

This module defines a node object and its methods. The node is fairly 
syntactically rich in terms of navigation, and additional getters are provided to
further ease navigation from node to node. Typical first daughter -> next sister
traversal and recursion is possible, but there are also shrinkwrapped methods
that return for example all terminal descendants of the focal node, or all
internals, etc.
    Node objects are inserted into tree objects, although technically the tree
object is only a container holding all the nodes together. Unless there are
orphans all nodes can be reached without recourse to the tree object.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $node = Bio::Phylo::Forest::Node->new;
 Function: Instantiates a Bio::Phylo::Forest::Node object
 Returns : Bio::Phylo::Forest::Node
 Args    : All optional:
           -parent          => $parent (Bio::Phylo::Forest::Node object)
           -taxon           => $taxon (Bio::Phylo::Taxa::Taxon object)
           -branch_length   => 0.423e+2 (a valid perl number format)
           -first_daughter  => $f_daughter (Bio::Phylo::Forest::Node object)
           -last_daughter   => $l_daughter (Bio::Phylo::Forest::Node object)
           -next_sister     => $n_sister (Bio::Phylo::Forest::Node object)
           -previous_sister => $p_sister (Bio::Phylo::Forest::Node object)
           -name            => 'node_name' (a string)
           -desc            => 'this is a node' (a string)
           -score           => 0.98 (a valid perl number format)
           -generic         => {
                -posterior => 0.98,
                -bootstrap => 0.80
           } (a hash reference)

=cut

sub new {
    my $class = shift;
    my $self = fields::new($class);
    $self->SUPER::new(@_);
    if (@_) {
        my %opts;
        eval { %opts = @_; };
        if ($@) {
            Bio::Phylo::Exceptions::OddHash->throw(
                error => $@
            );
        }
        while ( my ( $key, $value ) = each %opts ) {
            my $localkey = uc substr $key, 1;
            eval { $self->{$localkey} = $value; };
            if ($@) {
                Bio::Phylo::Exceptions::BadArgs->throw(
                    error => "invalid field specified: $key ($localkey)"
                );
            }
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
 Usage   : $node->set_taxon($taxon);
 Function: Assigns taxon crossreferenced with node.
 Returns : Modified object.
 Args    : If no argument is given, the currently assigned taxon is set to
           undefined. A valid argument is a Bio::Phylo::Taxa::Taxon object.

=cut

sub set_taxon {
    my $node = $_[0];
    if ( $_[1] ) {
        my $taxon = $_[1];
        my $ref   = ref $taxon;
        if ( !$taxon->can('_type') || $taxon->_type != _TAXON_ ) {
            Bio::Phylo::Exceptions::ObjectMismatch->throw(
                error => "$ref doesn't look like a taxon"
            );
        }
        else {
            $node->{'TAXON'} = $taxon;
        }
    }
    else {
        $node->{'TAXON'} = undef;
    }
    return $node;
}

=item set_branch_length()

 Type    : Mutator
 Title   : branch_length
 Usage   : $node->set_branch_length(0.423e+2);
 Function: Assigns or retrieves a node's branch length.
 Returns : Modified object.
 Args    : If no argument is given, the current branch length is set to
           undefined. A valid argument is a number in any of Perl's formats.

=cut

sub set_branch_length {
    my $node = $_[0];
    if ( defined $_[1] ) {
        my $branchlength = $_[1];
        if ( looks_like_number $branchlength ) {
            $node->{'BRANCH_LENGTH'} = $branchlength;
        }
        else {
            Bio::Phylo::Exceptions::BadNumber->throw(
                error => "Branch length \"$branchlength\" is a bad number"
            );
        }
    }
    else {
        $node->{'BRANCH_LENGTH'} = undef;
    }
    return $node;
}

=item set_parent()

 Type    : Mutator
 Title   : parent
 Usage   : $node->set_parent($parent);
 Function: Assigns a node's parent.
 Returns : Modified object.
 Args    : If no argument is given, the current parent is set to undefined. A
           valid argument is Bio::Phylo::Forest::Node object.

=cut

sub set_parent {
    my $node = $_[0];
    if ( $_[1] ) {
        my $parent = $_[1];
        if ( ref $parent && $parent->can('set_parent') ) {
            $node->{'PARENT'} = $parent;
        }
        else {
            my $ref = ref $node;
            Bio::Phylo::Exceptions::ObjectMismatch->throw(
                error => "parents can only be $ref objects"
            );
        }
    }
    else {
        $node->{'PARENT'} = undef;
    }
    return $node;
}

=item set_first_daughter()

 Type    : Mutator
 Title   : set_first_daughter
 Usage   : $node->set_first_daughter($f_daughter);
 Function: Assigns a node's leftmost daughter.
 Returns : Modified object.
 Args    : Undefines the first daughter if no argument given. A valid argument
           is a Bio::Phylo::Forest::Node object.

=cut

sub set_first_daughter {
    my $node = $_[0];
    if ( $_[1] ) {
        my $first_daughter = $_[1];
        if ( ref $first_daughter && $first_daughter->can('set_first_daughter') )
        {
            $node->{'FIRST_DAUGHTER'} = $first_daughter;
        }
        else {
            my $ref = ref $node;
            Bio::Phylo::Exceptions::ObjectMismatch->throw(
                error => "first_daughters can only be $ref objects"
            );
        }
    }
    else {
        $node->{'FIRST_DAUGHTER'} = undef;
    }
    return $node;
}

=item set_last_daughter()

 Type    : Mutator
 Title   : set_last_daughter
 Usage   : $node->set_last_daughter($l_daughter);
 Function: Assigns a node's rightmost daughter.
 Returns : Modified object.
 Args    : A valid argument consists of a Bio::Phylo::Forest::Node object. If
           no argument is given, the value is set to undefined.

=cut

sub set_last_daughter {
    my $node = $_[0];
    if ( $_[1] ) {
        my $last_daughter = $_[1];
        if ( ref $last_daughter && $last_daughter->can('set_last_daughter') ) {
            $node->{'LAST_DAUGHTER'} = $last_daughter;
        }
        else {
            my $ref = ref $node;
            Bio::Phylo::Exceptions::ObjectMismatch->throw(
                error => "last_daughters can only be $ref objects"
            );
        }
    }
    else {
        $node->{'LAST_DAUGHTER'} = undef;
    }
    return $node;
}

=item set_next_sister()

 Type    : Mutator
 Title   : set_next_sister
 Usage   : $node->set_next_sister($n_sister);
 Function: Assigns or retrieves a node's next sister (to the right).
 Returns : Modified object.
 Args    : A valid argument consists of a Bio::Phylo::Forest::Node object. If
           no argument is given, the value is set to undefined.

=cut

sub set_next_sister {
    my $node = $_[0];
    if ( $_[1] ) {
        my $next_sister = $_[1];
        if ( ref $next_sister && $next_sister->can('set_next_sister') ) {
            $node->{'NEXT_SISTER'} = $next_sister;
        }
        else {
            my $ref = ref $node;
            Bio::Phylo::Exceptions::ObjectMismatch->throw(
                error => "next_sisters can only be $ref objects"
            );
        }
    }
    else {
        $node->{'NEXT_SISTER'} = undef;
    }
    return $node;
}

=item set_previous_sister()

 Type    : Mutator
 Title   : set_previous_sister
 Usage   : $node->set_previous_sister($p_sister);
 Function: Assigns a node's previous sister (to the left).
 Returns : Modified object.
 Args    : A valid argument consists of a Bio::Phylo::Forest::Node object. If
           no argument is given, the value is set to undefined.

=cut

sub set_previous_sister {
    my $node = $_[0];
    if ( $_[1] ) {
        my $previous_sister = $_[1];
        if ( ref $previous_sister
            && $previous_sister->can('set_previous_sister') )
        {
            $node->{'PREVIOUS_SISTER'} = $previous_sister;
        }
        else {
            my $ref = ref $node;
            Bio::Phylo::Exceptions::ObjectMismatch->throw(
                error => "previous_sisters can only be $ref objects"
            );
        }
    }
    else {
        $node->{'PREVIOUS_SISTER'} = undef;
    }
    return $node;
}

=back

=head2 ACCESSORS

=over

=item get_name()

 Type    : Accessor
 Title   : get_name
 Usage   : my $name = $node->get_name;
 Function: Retrieves a node's name.
 Returns : SCALAR
 Args    : NONE

=cut

sub get_name {
    return $_[0]->{'NAME'};
}

=item get_taxon()

 Type    : Accessor
 Title   : get_taxon
 Usage   : my $taxon = $node->get_taxon;
 Function: Retrieves taxon crossreferenced with node.
 Returns : Bio::Phylo::Taxa::Taxon
 Args    : NONE

=cut

sub get_taxon {
    return $_[0]->{'TAXON'};
}

=item get_branch_length()

 Type    : Accessor
 Title   : get_branch_length
 Usage   : my $branch_length = $node->get_branch_length;
 Function: Retrieves a node's branch length.
 Returns : FLOAT
 Args    : NONE
 Comments: Test for "defined($node->get_branch_length)" for zero-length (but
           defined) branches. Testing "if ( $node->get_branch_length ) { ... }"
           yields false for zero-but-defined branches!

=cut

sub get_branch_length {
    return $_[0]->{'BRANCH_LENGTH'};
}

=item get_parent()

 Type    : Accessor
 Title   : get_parent
 Usage   : my $parent = $node->get_parent;
 Function: Retrieves a node's parent.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

sub get_parent {
    return $_[0]->{'PARENT'};
}

=item get_first_daughter()

 Type    : Accessor
 Title   : get_first_daughter
 Usage   : my $f_daughter = $node->get_first_daughter;
 Function: Retrieves a node's leftmost daughter.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

sub get_first_daughter {
    return $_[0]->{'FIRST_DAUGHTER'};
}

=item get_last_daughter()

 Type    : Accessor
 Title   : get_last_daughter
 Usage   : my $l_daughter = $node->get_last_daughter;
 Function: Retrieves a node's rightmost daughter.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

sub get_last_daughter {
    return $_[0]->{'LAST_DAUGHTER'};
}

=item get_next_sister()

 Type    : Accessor
 Title   : get_next_sister
 Usage   : my $n_sister = $node->get_next_sister;
 Function: Retrieves a node's next sister (to the right).
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

sub get_next_sister {
    return $_[0]->{'NEXT_SISTER'};
}

=item get_previous_sister()

 Type    : Accessor
 Title   : get_previous_sister
 Usage   : my $p_sister = $node->get_previous_sister;
 Function: Retrieves a node's previous sister (to the left).
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

sub get_previous_sister {
    return $_[0]->{'PREVIOUS_SISTER'};
}

=item get_ancestors()

 Type    : Query
 Title   : get_ancestors
 Usage   : my @ancestors = @{ $node->get_ancestors };
 Function: Returns an array reference of ancestral nodes,
           ordered from young to old.
 Returns : Array reference of Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

sub get_ancestors {
    my $node = $_[0];
    my @ancestors;
    if ( $node->get_parent ) {
        $node = $node->get_parent;
        while ($node) {
            push @ancestors, $node;
            $node = $node->get_parent;
        }
        return \@ancestors;
    }
    else {
        return;
    }
}

=item get_sisters()

 Type    : Query
 Title   : get_sisters
 Usage   : my @sisters = @{ $node->get_sisters };
 Function: Returns an array reference of sisters, ordered from left to right.
 Returns : Array reference of Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

sub get_sisters {
    my $node    = $_[0];
    my @sisters = $node->get_parent->get_children;
    return \@sisters;
}

=item get_children()

 Type    : Query
 Title   : get_children
 Usage   : my @children = @{ $node->get_children };
 Function: Returns an array reference of immediate descendants,
           ordered from left to right.
 Returns : Array reference of Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

sub get_children {
    my $node = $_[0];
    my @children;
    my $fd = $node->get_first_daughter;
    if ($fd) {
        while ($fd) {
            push @children, $fd;
            $fd = $fd->get_next_sister;
        }
        return \@children;
    }
    else {
        return;
    }
}

=item get_descendants()

 Type    : Query
 Title   : get_descendants
 Usage   : my @descendants = @{ $node->get_descendants };
 Function: Returns an array reference of descendants,
           recursively ordered breadth first.
 Returns : Array reference of Bio::Phylo::Forest::Node objects.
 Args    : none.

=cut

sub get_descendants {
    my $root    = $_[0];
    my @current = ($root);
    my @desc;
    while ( $root->_desc(@current) ) {
        @current = $root->_desc(@current);
        push @desc, @current;
    }
    return \@desc;
}

=begin comment

 Type    : Internal method
 Title   : _desc
 Usage   : $node->_desc(\@nodes);
 Function: Performs recursion for Bio::Phylo::Forest::Node::get_descendants()
 Returns : A Bio::Phylo::Forest::Node object.
 Args    : A Bio::Phylo::Forest::Node object.
 Comments: This method works in conjunction with
           Bio::Phylo::Forest::Node::get_descendants() - the latter simply calls
           the former with a set of nodes, and the former returns their
           children. Bio::Phylo::Forest::Node::get_descendants() then calls
           Bio::Phylo::Forest::Node::_desc with this set of children, and so on
           until all nodes are terminals. A first_daughter ->
           next_sister postorder traversal in a single method would
           have been more elegant - though not more efficient, in
           terms of visited nodes.

=end comment

=cut

sub _desc {
    my $root    = shift;
    my @current = @_;
    my @return;
    foreach (@current) {
        my $children = $_->get_children;
        if ( $children ) {
            push @return, @{$children};
        }
    }
    return @return;
}

=item get_terminals()

 Type    : Query
 Title   : get_terminals
 Usage   : my @terminals = @{ $node->get_terminals };
 Function: Returns an array reference of terminal descendants.
 Returns : Array reference of Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

sub get_terminals {
    my $node = $_[0];
    my @terminals;
    my $desc = $node->get_descendants;
    if ( scalar @{$desc} ) {
        foreach ( @{$desc} ) {
            if ( $_->is_terminal ) {
                push @terminals, $_;
            }
        }
    }
    return \@terminals;
}

=item get_internals()

 Type    : Query
 Title   : get_internals
 Usage   : my @internals = @{ $node->get_internals };
 Function: Returns an array reference of internal descendants.
 Returns : Array reference of Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

sub get_internals {
    my $node = $_[0];
    my @internals;
    my $desc = $node->get_descendants;
    if ( scalar @{$desc} ) {
        foreach ( @{$desc} ) {
            if ( $_->is_internal ) {
                push @internals, $_;
            }
        }
    }
    return \@internals;
}

=item get_mrca()

 Type    : Query
 Title   : get_mrca
 Usage   : my $mrca = $node->get_mrca($other_node);
 Function: Returns the most recent common ancestor
           of $node and $other_node.
 Returns : Bio::Phylo::Forest::Node
 Args    : A Bio::Phylo::Forest::Node object in the same tree.

=cut

sub get_mrca {
    my $node              = $_[0];
    my $other_node        = $_[1];
    my $node_parent       = $node->get_ancestors;
    my $other_node_parent = $other_node->get_ancestors;
    for my $i ( 0 .. $#{$node_parent} ) {
        for my $j ( 0 .. $#{$other_node_parent} ) {
            if ( $node_parent->[$i] == $other_node_parent->[$j] ) {
                return $node_parent->[$i];
            }
        }
    }
    return;
}

=item get_leftmost_terminal()

 Type    : Query
 Title   : get_leftmost_terminal
 Usage   : my $leftmost_terminal = $node->get_leftmost_terminal;
 Function: Returns the leftmost terminal descendant of $node.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

sub get_leftmost_terminal {
    my $node = $_[0];
    while ($node) {
        if ( $node->get_first_daughter ) {
            $node = $node->get_first_daughter;
        }
        else {
            last;
        }
    }
    return $node;
}

=item get_rightmost_terminal()

 Type    : Query
 Title   : get_rightmost_terminal
 Usage   : my $rightmost_terminal = $node->get_rightmost_terminal;
 Function: Returns the rightmost terminal descendant of $node.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

sub get_rightmost_terminal {
    my $node = $_[0];
    while ($node) {
        if ( $node->get_last_daughter ) {
            $node = $node->get_last_daughter;
        }
        else {
            last;
        }
    }
    return $node;
}

=item get_generic()

 Type    : Accessor
 Title   : get_generic
 Usage   : my $generic_value = $node->get_generic($key);
           # or
           my %generic_hash  = %{ $node->get_generic };
           # such that
           $generic_hash{$key} == $generic_value;
 Function: Retrieves value of a generic key/value pair attached to $node, given
           $key. If no $key is given, a reference to the entire hash is
           returned.
 Returns : A SCALAR string, or a HASH ref
 Args    : Key/value pairs are stored in a hashref. If
           $node->set_generic(posterior => 0.3543) has been set, the value
           can be retrieved using $node->get_generic('posterior'); if multiple
           key/value pairs were set, e.g. $node->set_generic( x => 12, y => 80)
           and $node->get_generic is called without arguments, a hash reference
           { x => 12, y => 80 } is returned.

=cut

sub get_generic {
    if ( $_[1] ) {
        return $_[0]->{'GENERIC'}->{ $_[1] };
    }
    else {
        return $_[0]->{'GENERIC'};
    }
}

=back

=head2 TESTS

=over

=item is_terminal()

 Type    : Test
 Title   : is_terminal
 Usage   : if ( $node->is_terminal ) {
              # do something
           }
 Function: Returns true if node has no children (i.e. is terminal).
 Returns : BOOLEAN
 Args    : NONE

=cut

sub is_terminal {
    my $node = $_[0];
    if ( !$node->get_first_daughter ) {
        return 1;
    }
    else {
        return;
    }
}

=item is_internal()

 Type    : Test
 Title   : is_internal
 Usage   : if ( $node->is_internal ) {
              # do something
           }
 Function: Returns true if node has children (i.e. is internal).
 Returns : BOOLEAN
 Args    : NONE

=cut

sub is_internal {
    my $node = $_[0];
    if ( $node->get_first_daughter ) {
        return 1;
    }
    else {
        return;
    }
}

=item is_descendant_of()

 Type    : Test
 Title   : is_descendant_of
 Usage   : if ( $node->is_descendant_of($grandparent) ) {
              # do something
           }
 Function: Returns true if the node is a descendant of the argument.
 Returns : BOOLEAN
 Args    : putative ancestor - a Bio::Phylo::Forest::Node object.

=cut

sub is_descendant_of {
    my ( $node, $parent ) = @_;
    while ($node) {
        if ( $node->get_parent ) {
            $node = $node->get_parent;
        }
        else {
            return;
        }
        if ( $node == $parent ) {
            return 1;
        }
    }
}

=item is_ancestor_of()

 Type    : Test
 Title   : is_ancestor_of
 Usage   : if ( $node->is_ancestor_of($grandchild) ) {
              # do something
           }
 Function: Returns true if the node is an ancestor of the argument.
 Returns : BOOLEAN
 Args    : putative descendant - a Bio::Phylo::Forest::Node object.

=cut

sub is_ancestor_of {
    my ( $node, $child ) = @_;
    if ( $child->is_descendant_of($node) ) {
        return 1;
    }
    else {
        return;
    }
}

=item is_sister_of()

 Type    : Test
 Title   : is_sister_of
 Usage   : if ( $node->is_sister_of($sister) ) {
              # do something
           }
 Function: Returns true if the node is a sister of the argument.
 Returns : BOOLEAN
 Args    : putative sister - a Bio::Phylo::Forest::Node object.

=cut

sub is_sister_of {
    my ( $node, $sis ) = @_;
    if (   $node->get_parent
        && $sis->get_parent
        && $node->get_parent == $sis->get_parent )
    {
        return 1;
    }
    else {
        return;
    }
}

=item is_outgroup_of()

 Type    : Test
 Title   : is_outgroup_of
 Usage   : if ( $node->is_outgroup_of(\@ingroup) ) {
              # do something
           }
 Function: Tests whether the set of \@ingroup is monophyletic
           with respect to the $node.
 Returns : BOOLEAN
 Args    : A reference to an array of Bio::Phylo::Forest::Node objects;
 Comments: This method is essentially the same as
           &Bio::Phylo::Forest::Tree::is_monophyletic.

=cut

sub is_outgroup_of {
    my ( $outgroup, $nodes ) = @_;
    for my $i ( 0 .. $#{$nodes} ) {
        for my $j ( ( $i + 1 ) .. $#{$nodes} ) {
            my $mrca = $nodes->[$i]->get_mrca( $nodes->[$j] );
            return if $mrca->is_ancestor_of($outgroup);
        }
    }
    return 1;
}

=back

=head2 CALCULATIONS

=over

=item calc_path_to_root()

 Type    : Calculation
 Title   : calc_path_to_root
 Usage   : my $path_to_root = $node->calc_path_to_root;
 Function: Returns the sum of branch lengths from $node to the root.
 Returns : FLOAT
 Args    : NONE

=cut

sub calc_path_to_root {
    my $node = $_[0];
    my $path = 0;
    while ($node) {
        if ( defined $node->get_branch_length ) {
            $path += $node->get_branch_length;
        }
        $node = $node->get_parent;
    }
    return $path;
}

=item calc_nodes_to_root()

 Type    : Calculation
 Title   : calc_nodes_to_root
 Usage   : my $nodes_to_root = $node->calc_nodes_to_root;
 Function: Returns the number of nodes from $node to the root.
 Returns : INT
 Args    : NONE

=cut

sub calc_nodes_to_root {
    my $node  = $_[0];
    my $nodes = 0;
    while ($node) {
        $nodes++;
        $node = $node->get_parent;
    }
    return $nodes;
}

=item calc_max_nodes_to_tips()

 Type    : Calculation
 Title   : calc_max_nodes_to_tips
 Usage   : my $max_nodes_to_tips = $node->calc_max_nodes_to_tips;
 Function: Returns the maximum number of nodes from $node to tips.
 Returns : INT
 Args    : NONE

=cut

sub calc_max_nodes_to_tips {
    my $node = $_[0];
    my ( $nodes, $maxnodes ) = ( 0, 0 );
    foreach my $child ( @{ $node->get_terminals } ) {
        $nodes = 0;
        while ( $child != $node ) {
            $nodes++;
            $child = $child->get_parent;
        }
        if ( $nodes > $maxnodes ) {
            $maxnodes = $nodes;
        }
    }
    return $maxnodes;
}

=item calc_min_nodes_to_tips()

 Type    : Calculation
 Title   : calc_min_nodes_to_tips
 Usage   : my $min_nodes_to_tips = $node->calc_min_nodes_to_tips;
 Function: Returns the minimum number of nodes from $node to tips.
 Returns : INT
 Args    : NONE

=cut

sub calc_min_nodes_to_tips {
    my $node = $_[0];
    my ( $nodes, $minnodes );
    foreach my $child ( @{ $node->get_terminals } ) {
        $nodes = 0;
        while ( $child != $node ) {
            $nodes++;
            $child = $child->get_parent;
        }
        if ( !$minnodes ) {
            $minnodes = $nodes;
        }
        if ( $nodes <= $minnodes ) {
            $minnodes = $nodes;
        }
    }
    return $minnodes;
}

=item calc_max_path_to_tips()

 Type    : Calculation
 Title   : calc_max_path_to_tips
 Usage   : my $max_path_to_tips = $node->calc_max_path_to_tips;
 Function: Returns the path length from $node to the tallest tip.
 Returns : FLOAT
 Args    : NONE

=cut

sub calc_max_path_to_tips {
    my $node = $_[0];
    my ( $length, $maxlength ) = ( 0, 0 );
    foreach my $child ( @{ $node->get_terminals } ) {
        $length = 0;
        while ( $child != $node ) {
            my $branch_length = $child->get_branch_length;
            if ( defined $branch_length ) {
                $length += $branch_length;
            }
            $child = $child->get_parent;
        }
        if ( $length > $maxlength ) {
            $maxlength = $length ;
        }
    }
    return $maxlength;
}

=item calc_min_path_to_tips()

 Type    : Calculation
 Title   : calc_min_path_to_tips
 Usage   : my $min_path_to_tips = $node->calc_min_path_to_tips;
 Function: Returns the path length from $node to the shortest tip.
 Returns : FLOAT
 Args    : NONE

=cut

sub calc_min_path_to_tips {
    my $node = $_[0];
    my ( $length, $minlength );
    foreach my $child ( @{ $node->get_terminals } ) {
        $length = 0;
        while ( $child != $node ) {
            my $branch_length = $child->get_branch_length;
            if ( defined $branch_length ) {
                $length += $branch_length;
            }
            $child = $child->get_parent;
        }
        if ( !$minlength ) {
            $minlength = $length;
        }
        if ( $length < $minlength ) {
            $minlength = $length ;
        }
    }
    return $minlength;
}

=item calc_patristic_distance()

 Type    : Calculation
 Title   : calc_patristic_distance
 Usage   : my $patristic_distance = $node->calc_patristic_distance($other_node);
 Function: Returns the patristic distance
           between $node and $other_node.
 Returns : FLOAT
 Args    : Bio::Phylo::Forest::Node

=cut

sub calc_patristic_distance {
    my ( $node, $other_node ) = @_;
    my $patristic_distance;
    my $mrca = $node->get_mrca($other_node);
    while ( $node != $mrca ) {
        my $branch_length = $node->get_branch_length;
        if ( defined $branch_length ) {
            $patristic_distance += $branch_length;
        }
        $node = $node->get_parent;
    }
    while ( $other_node != $mrca ) {
        my $branch_length = $other_node->get_branch_length;
        if ( defined $branch_length ) {
            $patristic_distance += $branch_length;
        }
        $other_node = $other_node->get_parent;
    }
    return $patristic_distance;
}

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $node->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

sub _container { _TREE_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $node->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

sub _type { _NODE_ }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

This object inherits from L<Bio::Phylo>, so the methods defined
therein are also applicable to L<Bio::Phylo::Node> objects.

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

$Id: Node.pm,v 1.10 2005/09/29 20:31:17 rvosa Exp $

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
