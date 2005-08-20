# $Id: Node.pm,v 1.7 2005/08/11 19:41:13 rvosa Exp $
# Subversion: $Rev: 149 $
package Bio::Phylo::Trees::Node;
use strict;
use warnings;
use base 'Bio::Phylo';

# One line so MakeMaker sees it.
use Bio::Phylo;  our $VERSION = $Bio::Phylo::VERSION;

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 149 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
$VERSION .= '_' . $rev;
use vars qw($VERSION);

my $VERBOSE = 1;

=head1 NAME

Bio::Phylo::Trees::Node - An object-oriented module for nodes in phylogenetic
trees.

=head1 SYNOPSIS

 use Bio::Phylo::Trees::Node;

 my $node = Bio::Phylo::Trees::Node->new(
    -name=>'Homo_sapiens',
    -desc=>'Unstable terminal node in NJ tree',
    -branch_length=>5.04e+20
 );

=head1 DESCRIPTION

This module defines a node object and its methods. The node is fairly
syntactically rich in terms of navigation, and additional getters are
provided to further ease navigation from node to node. Typical first-
daughter -> next sister traversal and recursion is possible, but there
are also shrinkwrapped methods that return for example all terminal
descendants of the focal node, or all internals, etc.
    Node objects are inserted into tree objects, although technically
the tree object is only a container holding all the nodes together.
Unless there are orphans all nodes can be reached without recourse to
the tree object.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $node = new Bio::Phylo::Trees::Node;
 Function: Initializes a Bio::Phylo::Trees::Node object
 Returns : Bio::Phylo::Trees::Node
 Args    : none

=cut

sub new {
    my $class = shift;
    my $self  = {};
    $self->{'PARENT'}          = undef;
    $self->{'NAME'}            = undef;
    $self->{'TAXON'}           = undef;
    $self->{'DESC'}            = undef;
    $self->{'BRANCH_LENGTH'}   = undef;
    $self->{'FIRST_DAUGHTER'}  = undef;
    $self->{'LAST_DAUGHTER'}   = undef;
    $self->{'NEXT_SISTER'}     = undef;
    $self->{'PREVIOUS_SISTER'} = undef;
    $self->{'GENERIC'}         = {};
    bless( $self, $class );
    if (@_) {
        my %opts = @_;
        while ( my ( $key, $value ) = each %opts ) {
            my $localkey = uc(substr($key,1));
            if ( exists $self->{$localkey} ) {
                $self->{$localkey} = $value;
            }
            else {
                $self->COMPLAIN("invalid field specified: $@");
                return;
            }
        }
    }
    return $self;
}

=back

=head2 MUTATORS

=over

=item set_name($name)

 Type    : Mutator
 Title   : set_name
 Usage   : $node->set_name($name);
 Function: Assigns a node's name.
 Returns : NONE
 Args    : Argument must be a string that doesn't contain [;|,|:\(|\)]

=cut

sub set_name {
    my ( $node, $name ) = ( $_[0], $_[1] );
    my $ref = ref $node;
    if ( $name =~ m/([;|,|:|\(|\)])/ ) {
        $node->COMPLAIN("\"$name\" is a bad name format for $ref names: $@");
        return;
    }
    else {
        $node->{'NAME'} = $name;
    }
}

=item set_taxon($taxon)

 Type    : Mutator
 Title   : set_taxon
 Usage   : $node->set_taxon($taxon);
 Function: Assigns taxon crossreferenced with node.
 Returns : NONE
 Args    : If no argument is given, the currently assigned taxon is set to
           undefined. A valid argument is a Bio::Phylo::Taxa::Taxon object.

=cut

sub set_taxon {
    my $node = $_[0];
    if ( $_[1] ) {
        my $taxon = $_[1];
        my $ref   = ref $taxon;
        if ( !$taxon->can('container_type')
            || $taxon->container_type ne 'TAXON' )
        {
            $node->COMPLAIN("$ref doesn't look like a taxon: $@");
            return;
        }
        else {
            $node->{'TAXON'} = $taxon;
        }
    }
    else {
        $node->{'TAXON'} = undef;
    }
}

=item set_branch_length($bl)

 Type    : Mutator
 Title   : branch_length
 Usage   : $node->set_branch_length($bl);
 Function: Assigns or retrieves a node's branch length.
 Returns : NONE
 Args    : If no argument is given, the current branch length is set to
           undefined. A valid argument is a number in any of Perl's formats.

=cut

sub set_branch_length {
    my $node = $_[0];
    if ( defined($_[1]) ) {
        my $branchlength = $_[1];
        if ( $branchlength !~ m/(^[-|+]?\d+\.?\d*e?[-|+]?\d*$)/i ) {
            $node->COMPLAIN("\"$branchlength\" is a bad number format: $@");
            return;
        }
        else {
            $node->{'BRANCH_LENGTH'} = $branchlength;
        }
    }
    else {
        $node->{'BRANCH_LENGTH'} = undef;
    }
}

=item set_parent($p)

 Type    : Mutator
 Title   : parent
 Usage   : $node->set_parent($p);
 Function: Assigns a node's parent.
 Returns : NONE
 Args    : If no argument is given, the current parent is set to undefined. A
           valid argument is Bio::Phylo::Trees::Node object.

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
            $node->COMPLAIN("parents can only be $ref objects: $@");
            return;
        }
    }
    else {
        $node->{'PARENT'} = undef;
    }
}

=item set_first_daughter($fd)

 Type    : Mutator
 Title   : set_first_daughter
 Usage   : $node->set_first_daughter($fd);
 Function: Assigns a node's leftmost daughter.
 Returns : NONE
 Args    : Undefines the first daughter if no argument given. A valid argument
           is a Bio::Phylo::Trees::Node object.

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
            $node->COMPLAIN("first_daughters can only be $ref objects: $@");
            return;
        }
    }
    else {
        $node->{'FIRST_DAUGHTER'} = undef;
    }
}

=item set_last_daughter($ld)

 Type    : Mutator
 Title   : set_last_daughter
 Usage   : $node->set_last_daughter($ld);
 Function: Assigns a node's rightmost daughter.
 Returns : NONE
 Args    : A valid argument consists of a Bio::Phylo::Trees::Node object. If no
           argument is given, the value is set to undefined.

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
            $node->COMPLAIN("last_daughters can only be $ref objects: $@");
            return;
        }
    }
    else {
        $node->{'LAST_DAUGHTER'} = undef;
    }
}

=item set_next_sister($ns)

 Type    : Mutator
 Title   : set_next_sister
 Usage   : $node->set_next_sister($ns);
 Function: Assigns or retrieves a node's next sister (to the right).
 Returns : NONE
 Args    : A valid argument consists of a Bio::Phylo::Trees::Node object. If no
           argument is given, the value is set to undefined.

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
            $node->COMPLAIN("next_sisters can only be $ref objects: $@");
            return;
        }
    }
    else {
        $node->{'NEXT_SISTER'} = undef;
    }
}

=item set_previous_sister($ps)

 Type    : Mutator
 Title   : set_previous_sister
 Usage   : $node->set_previous_sister($ps);
 Function: Assigns a node's previous sister (to the left).
 Returns : NONE
 Args    : A valid argument consists of a Bio::Phylo::Trees::Node object. If no
           argument is given, the value is set to undefined.

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
            $node->COMPLAIN("previous_sisters can only be $ref objects: $@");
            return;
        }
    }
    else {
        $node->{'PREVIOUS_SISTER'} = undef;
    }
}

=item set_generic(%generic)

 Type    : Mutator
 Title   : set_generic
 Usage   : $node->set_generic(%generic);
 Function: Assigns generic key/value pairs to the invocant.
 Returns : NONE
 Args    : Valid arguments constitute key/value pairs, for example:
           $node->set_generic(posterior => 0.87565);

=cut

sub set_generic {
    my $node = shift;
    if (@_) {
        my %args;
        eval { %args = @_ };
        if ($@) {
            $node->COMPLAIN("argument not a hash: $@");
            return;
        }
        else {
            foreach my $key ( keys %args ) {
                $node->{'GENERIC'}->{$key} = $args{$key};
            }
        }
    }
    else {
        $node->{'GENERIC'} = undef;
    }
}

=back

=head2 ACCESSORS

=over

=item get_name()

 Type    : Accessor
 Title   : get_name
 Usage   : my $name = $node->get_name();
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
 Usage   : my $taxon = $node->get_taxon();
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
 Usage   : my $branch_length = $node->get_branch_length();
 Function: Retrieves a node's branch length.
 Returns : FLOAT
 Args    : NONE
 Comments: Test for defined($node->get_branch_length) for zero-length branches.

=cut

sub get_branch_length {
    return $_[0]->{'BRANCH_LENGTH'};
}

=item get_parent()

 Type    : Accessor
 Title   : get_parent
 Usage   : my $parent = $node->get_parent;
 Function: Retrieves a node's parent.
 Returns :

=cut

sub get_parent {
    return $_[0]->{'PARENT'};
}

=item get_first_daughter()

 Type    : Accessor
 Title   : get_first_daughter
 Usage   : my $first_daughter = $node->get_first_daughter();
 Function: Retrieves a node's leftmost daughter.
 Returns : A Bio::Phylo::Trees::Node object.

=cut

sub get_first_daughter {
    return $_[0]->{'FIRST_DAUGHTER'};
}

=item get_last_daughter()

 Type    : Accessor
 Title   : last_daughter
 Usage   : my $last_daughter = $node->get_last_daughter;
 Function: Retrieves a node's rightmost daughter.
 Returns : A Bio::Phylo::Trees::Node object.

=cut

sub get_last_daughter {
    return $_[0]->{'LAST_DAUGHTER'};
}

=item get_next_sister()

 Type    : Accessor
 Title   : next_sister
 Usage   : my $next_sister = $node->get_next_sister;
 Function: Retrieves a node's next sister (to the right).
 Returns : A Bio::Phylo::Trees::Node object.
 Args    : An argument of Bio::Phylo::Trees::Node is possible, but maybe
           not such a great idea. Unless you have some way of keeping
           track of all the relationships you might end up with
           circular references or orphans.

=cut

sub get_next_sister {
    return $_[0]->{'NEXT_SISTER'};
}

=item get_previous_sister()

 Type    : Accessor
 Title   : get_previous_sister
 Usage   : my $previous_sister = $node->get_previous_sister;
 Function: Retrieves a node's previous sister (to the left).
 Returns : A Bio::Phylo::Trees::Nodeobject.
 Args    : An argument of Bio::Phylo::Trees::Node is possible, but maybe
           not such a great idea. Unless you have some way of keeping
           track of all the relationships you might end up with
           circular references or orphans.

=cut

sub get_previous_sister {
    return $_[0]->{'PREVIOUS_SISTER'};
}

=item get_ancestors()

 Type    : Query
 Title   : get_ancestors
 Usage   : $node->get_ancestors;
 Function: Returns a list of ancestral nodes,
           ordered from young to old.
 Returns : List of Bio::Phylo::Trees::Node objects.
 Args    : none.

=cut

sub get_ancestors {
    my $node = $_[0];
    my @ancestors;
    if ( $node->get_parent ) {
        $node = $node->get_parent;
        while ($node) {
            push( @ancestors, $node );
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
 Usage   : $node->get_sisters;
 Function: Returns a list of sisters, ordered from left to right.
 Returns : List of Bio::Phylo::Trees::Node objects.
 Args    : none.

=cut

sub get_sisters {
    my $node    = $_[0];
    my @sisters = $node->get_parent->get_children;
    return \@sisters;
}

=item get_children()

 Type    : Query
 Title   : get_children
 Usage   : $node->get_children;
 Function: Returns a list of immediate descendants,
           ordered from left to right.
 Returns : List of Bio::Phylo::Trees::Node objects.
 Args    : none.

=cut

sub get_children {
    my $node = $_[0];
    my @children;
    my $fd = $node->get_first_daughter;
    if ($fd) {
        while ($fd) {
            push( @children, $fd );
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
 Usage   : $node->get_descendants;
 Function: Returns a list of descendants,
           recursively ordered breadth first.
 Returns : List of Bio::Phylo::Trees::Node objects.
 Args    : none.

=cut

sub get_descendants {
    my $root    = $_[0];
    my @current = ($root);
    my @desc;
    while ( $root->_desc(@current) ) {
        @current = $root->_desc(@current);
        push( @desc, @current );
    }
    return \@desc;
}

=item _desc()

 Type    : Internal method
 Title   : _desc
 Usage   : $node->_desc(\@nodes);
 Function: Performs recursion for Bio::Phylo::Trees::Node::get_descendants()
 Returns : A Bio::Phylo::Trees::Node object.
 Args    : A Bio::Phylo::Trees::Node object.
 Comments: This method works in conjunction with
           Bio::Phylo::Trees::Node::get_descendants() - the latter simply calls
           the former with a set of nodes, and the former returns their
           children. Bio::Phylo::Trees::Node::get_descendants() then calls
           Bio::Phylo::Trees::Node::_desc with this set of children, and so on
           until all nodes are terminals. A first_daughter ->
           next_sister postorder traversal in a single method would
           have been more elegant - though not more efficient, in
           terms of visited nodes.

=cut

sub _desc {
    my $root    = shift;
    my @current = @_;
    my @return;
    foreach (@current) {
        my $children = $_->get_children;
        push( @return, @{$children} ) if $children;
    }
    return @return;
}

=item get_terminals()

 Type    : Query
 Title   : get_terminals
 Usage   : $node->get_terminals;
 Function: Returns a list of terminal descendants.
 Returns : List of Bio::Phylo::Trees::Node objects.
 Args    : none.

=cut

sub get_terminals {
    my $node = $_[0];
    my @terminals;
    my $desc = $node->get_descendants;
    if ( scalar @{$desc} ) {
        foreach ( @{$desc} ) {
            if ( $_->is_terminal ) {
                push( @terminals, $_ );
            }
        }
    }
    return \@terminals;
}

=item get_internals()

 Type    : Query
 Title   : get_internals
 Usage   : $node->get_internals;
 Function: Returns a list of internal descendants.
 Returns : List of Bio::Phylo::Trees::Node objects.
 Args    : none.

=cut

sub get_internals {
    my $node = $_[0];
    my @internals;
    my $desc = $node->get_descendants;
    if ( scalar @{$desc} ) {
        foreach ( @{$desc} ) {
            if ( $_->is_internal ) {
                push( @internals, $_ );
            }
        }
    }
    return \@internals;
}

=item get_mrca(Bio::Phylo::Trees::Node)

 Type    : Query
 Title   : get_mrca(Bio::Phylo::Trees::Node)
 Usage   : $node->get_mrca($other_node);
 Function: Returns the most recent common ancestor
           of $node and $other_node.
 Returns : An Bio::Phylo::Trees::Node object.
 Args    : An Bio::Phylo::Trees::Node object.

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
 Usage   : $node->get_leftmost_terminal;
 Function: Returns the leftmost terminal descendant of $node.
 Returns : A Bio::Phylo::Trees::Node object.
 Args    : none.

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
 Usage   : $node->get_rightmost_terminal;
 Function: Returns the rightmost terminal descendant of $node.
 Returns : A Bio::Phylo::Trees::Node object.
 Args    : none.

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
 Usage   : my $get_generic = $node->get_generic($key);
 Function: Retrieves value of a generic key/value pair given $key.
 Returns : A SCALAR string
 Args    : Key/value pairs are stored as hashrefs. If
           $node->set_generic(posterior => 0.3543) has been set, the value
           can be retrieved using $node->get_generic('posterior');

=cut

sub get_generic {
    return $_[0]->{'GENERIC'}->{ $_[1] };
}

=back

=head2 TESTS

=over

=item is_terminal()

 Type    : Test
 Title   : is_terminal
 Usage   : $node->is_terminal;
 Function: Returns true if node has no children (i.e. is terminal).
 Returns : BOOLEAN
 Args    : none

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
 Usage   : $node->is_internal;
 Function: Returns true if node has children (i.e. is internal).
 Returns : BOOLEAN
 Args    : none

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

=item is_descendant_of(Bio::Phylo::Trees::Node)

 Type    : Test
 Title   : is_descendant_of
 Usage   : $node->is_descendant_of($grandparent);
 Function: Returns true if the node is a descendant of the argument.
 Returns : BOOLEAN
 Args    : putative ancestor - a Bio::Phylo::Trees::Node object.

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

=item is_ancestor_of(Bio::Phylo::Trees::Node)

 Type    : Test
 Title   : is_ancestor_of
 Usage   : $node->is_ancestor_of($grandchild);
 Function: Returns true if the node is an ancestor of the argument.
 Returns : BOOLEAN
 Args    : putative descendant - a Bio::Phylo::Trees::Node object.

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

=item is_sister_of(Bio::Phylo::Trees::Node)

 Type    : Test
 Title   : is_sister_of
 Usage   : $node->is_sister_of($sister);
 Function: Returns true if the node is a sister of the argument.
 Returns : BOOLEAN
 Args    : putative sister - a Bio::Phylo::Trees::Node object.

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

=item is_outgroup_of(\@{Bio::Phylo::Trees::Node, Bio::Phylo::Trees::Node})

 Type    : Test
 Title   : is_outgroup_of
 Usage   : $outgroup->is_outgroup_of(\@ingroup);
 Function: Tests whether the set of \@ingroup is monophyletic
           with respect to the $outgroup.
 Returns : BOOLEAN
 Args    : A reference to a list of Bio::Phylo::Trees::Node objects;
 Comments: This method is essentially the same as
           Bio::Phylo::Trees::Tree::is_monophyletic.

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
 Usage   : $node->calc_path_to_root;
 Function: Returns the sum of branch lengths from $node to the root.
 Returns : FLOAT
 Args    : none.

=cut

sub calc_path_to_root {
    my $node = $_[0];
    my $path = 0;
    while ($node) {
        if ( defined($node->get_branch_length) ) {
            $path += $node->get_branch_length;
        }
        $node = $node->get_parent;
    }
    return $path;
}

=item calc_nodes_to_root()

 Type    : Calculation
 Title   : calc_nodes_to_root
 Usage   : $node->calc_nodes_to_root;
 Function: Returns the number of nodes from $node to the root.
 Returns : INT
 Args    : none.

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
 Usage   : $node->calc_max_nodes_to_tips;
 Function: Returns the maximum number of nodes from $node to tips.
 Returns : INT
 Args    : none.

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
        $maxnodes = $nodes if $nodes > $maxnodes;
    }
    return $maxnodes;
}

=item calc_min_nodes_to_tips()

 Type    : Calculation
 Title   : calc_min_nodes_to_tips
 Usage   : $node->calc_min_nodes_to_tips;
 Function: Returns the minimum number of nodes from $node to tips.
 Returns : INT
 Args    : none.

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
        $minnodes = $nodes if !$minnodes;
        $minnodes = $nodes if $nodes <= $minnodes;
    }
    return $minnodes;
}

=item calc_max_path_to_tips()

 Type    : Calculation
 Title   : calc_max_path_to_tips
 Usage   : $node->calc_max_path_to_tips;
 Function: Returns the path length from $node to the tallest tip.
 Returns : FLOAT
 Args    : none.

=cut

sub calc_max_path_to_tips {
    my $node = $_[0];
    my ( $length, $maxlength ) = ( 0, 0 );
    foreach my $child ( @{ $node->get_terminals } ) {
        $length = 0;
        while ( $child != $node ) {
            $length += $child->get_branch_length if defined($child->get_branch_length);
            $child = $child->get_parent;
        }
        $maxlength = $length if $length > $maxlength;
    }
    return $maxlength;
}

=item calc_min_path_to_tips()

 Type    : Calculation
 Title   : calc_min_path_to_tips
 Usage   : $node->calc_min_path_to_tips;
 Function: Returns the path length from $node to the shortest tip.
 Returns : FLOAT
 Args    : none.

=cut

sub calc_min_path_to_tips {
    my $node = $_[0];
    my ( $length, $minlength );
    foreach my $child ( @{ $node->get_terminals } ) {
        $length = 0;
        while ( $child != $node ) {
            $length += $child->get_branch_length if defined($child->get_branch_length);
            $child = $child->get_parent;
        }
        $minlength = $length if !$minlength;
        $minlength = $length if $length < $minlength;
    }
    return $minlength;
}

=item calc_patristic_distance(Bio::Phylo::Trees::Node)

 Type    : Calculation
 Title   : calc_patristic_distance(Bio::Phylo::Trees::Node)
 Usage   : $node->calc_patristic_distance($other_node);
 Function: Returns the patristic distance
           between $node and $other_node.
 Returns : FLOAT
 Args    : A Bio::Phylo::Trees::Node object.

=cut

sub calc_patristic_distance {
    my ( $node, $other_node ) = @_;
    my $pd;
    my $mrca = $node->get_mrca($other_node);
    while ( $node != $mrca ) {
        if ( defined($node->get_branch_length) ) {
            $pd += $node->get_branch_length;
        }
        $node = $node->get_parent;
    }
    while ( $other_node != $mrca ) {
        if ( defined($other_node->get_branch_length) ) {
            $pd += $other_node->get_branch_length;
        }
        $other_node = $other_node->get_parent;
    }
    return $pd;
}

=back

=head2 CONTAINER

=over

=item container

 Type    : Internal method
 Title   : container
 Usage   : $node->container;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container {
    return 'TREE';
}

=item container_type

 Type    : Internal method
 Title   : container_type
 Usage   : $node->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'NODE';
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>
L<http://www.sfu.ca/~rvosa/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed
from BioPerl L<http://www.bioperl.org>, and CIPRES
L<http://www.phylo.org> and FAB* L<http://www.sfu.ca/~fabstar> for
comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
