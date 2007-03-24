# $Id: Node.pm 3386 2007-03-24 16:22:25Z rvosa $
package Bio::Phylo::Forest::Node;
use strict;
use Bio::Phylo::Taxa::TaxonLinker;
use Bio::Phylo::Util::CONSTANT qw(_NODE_ _TREE_ _TAXON_ looks_like_number);
use Bio::Phylo::Adaptor;
use Scalar::Util qw(weaken);

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo Bio::Phylo::Taxa::TaxonLinker);

# set version based on svn rev
my $version = $Bio::Phylo::VERSION;
my $rev     = '$Id: Node.pm 3386 2007-03-24 16:22:25Z rvosa $';
$rev        =~ s/^[^\d]+(\d+)\b.*$/$1/;
$version    =~ s/_.+$/_$rev/;
$VERSION    = $version;

{

    # inside out class arrays
    my %parent;
    my %first_daughter;
    my %last_daughter;
    my %next_sister;
    my %previous_sister;
    my %branch_length;

    # $fields hashref necessary for object destruction
    my @fields = (
        \%parent,
        \%first_daughter,
        \%last_daughter,
        \%next_sister,
        \%previous_sister,
        \%branch_length,
    );

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

 # prints 'Bio::Phylo::Forest'
 print ref $forest;

 foreach my $tree ( @{ $forest->get_entities } ) {

    # prints 'Bio::Phylo::Forest::Tree'
    print ref $tree;

    foreach my $node ( @{ $tree->get_entities } ) {

       # prints 'Bio::Phylo::Forest::Node'
       print ref $node;

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
           -parent          => $parent,
           -taxon           => $taxon,
           -branch_length   => 0.423e+2,
           -first_daughter  => $f_daughter,
           -last_daughter   => $l_daughter,
           -next_sister     => $n_sister,
           -previous_sister => $p_sister,
           -name            => 'node_name',
           -desc            => 'this is a node',
           -score           => 0.98,
           -generic         => {
                -posterior => 0.98,
                -bootstrap => 0.80
           }

=cut

    sub new {
        # could be child class
        my $class = shift;
        
        # notify user
        $class->info("constructor called for '$class'");
        
        # go up inheritance tree, eventually get an ID
        my $self = $class->SUPER::new( @_ );
        
        # adapt (or not, if $Bio::Phylo::COMPAT is not set)
        return Bio::Phylo::Adaptor->new( $self );
    }

=item new_from_bioperl()

 Type    : Constructor
 Title   : new_from_bioperl
 Usage   : my $node =
           Bio::Phylo::Forest::Node->new_from_bioperl(
               $bpnode
           );
 Function: Instantiates a Bio::Phylo::Forest::Node object
           from a bioperl node object.
 Returns : Bio::Phylo::Forest::Node
 Args    : An objects that implements Bio::Tree::NodeI

=cut

    sub new_from_bioperl {
        my ( $class, $bpnode ) = @_;
        my $node = __PACKAGE__->new;
        $node->set_name( $bpnode->id );
        $node->set_branch_length( $bpnode->branch_length );
        $node->set_desc( $bpnode->description );
        $node->set_generic( 'bootstrap' => $bpnode->bootstrap );
        my @k = $bpnode->get_all_tags;
        my @v = $bpnode->get_tag_values;
        for my $i ( 0 .. $#k ) {
            $node->set_generic( $k[$i] => $v[$i] );
        }
        return $node;
    }

=back

=head2 MUTATORS

=over

=item set_parent()

 Type    : Mutator
 Title   : parent
 Usage   : $node->set_parent($parent);
 Function: Assigns a node's parent.
 Returns : Modified object.
 Args    : If no argument is given, the current
           parent is set to undefined. A valid
           argument is Bio::Phylo::Forest::Node
           object.

=cut

    sub set_parent {
        my ( $self, $parent ) = @_;
        my $id = $self->get_id;
        if ( $parent ) {
            my $type;
            eval { $type = $parent->_type };
            if ( $@ || $type != _NODE_ ) {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    error => "\"$parent\" is not a valid node object" 
                );
            }
            else {
                $parent{$id} = $parent;
                weaken $parent{$id};
            }
        }
        else {
            $parent{$id} = undef;
        }
        return $self;
    }

=item set_first_daughter()

 Type    : Mutator
 Title   : set_first_daughter
 Usage   : $node->set_first_daughter($f_daughter);
 Function: Assigns a node's leftmost daughter.
 Returns : Modified object.
 Args    : Undefines the first daughter if no
           argument given. A valid argument is
           a Bio::Phylo::Forest::Node object.

=cut

    sub set_first_daughter {
        my ( $self, $first_daughter ) = @_;
        my $id = $self->get_id;
        if ( $first_daughter ) {
            my $type;
            eval { $type = $first_daughter->_type };
            if ( $@ || $type != _NODE_ ) {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    error => "\"$first_daughter\" is not a valid node object" 
                );
            }
            else {
                $first_daughter{$id} = $first_daughter;
                weaken $first_daughter{$id};
            }
        }
        else {
            $first_daughter{$id} = undef;
        }
        return $self;
    }

=item set_last_daughter()

 Type    : Mutator
 Title   : set_last_daughter
 Usage   : $node->set_last_daughter($l_daughter);
 Function: Assigns a node's rightmost daughter.
 Returns : Modified object.
 Args    : A valid argument consists of a
           Bio::Phylo::Forest::Node object. If
           no argument is given, the value is
           set to undefined.

=cut

    sub set_last_daughter {
        my ( $self, $last_daughter ) = @_;
        my $id = $self->get_id;
        if ( $last_daughter ) {
            my $type;
            eval { $type = $last_daughter->_type };
            if ( $@ || $type != _NODE_ ) {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    error => "\"$last_daughter\" is not a valid node object" 
                );
            }
            else {
                $last_daughter{$id} = $last_daughter;
                weaken $last_daughter{$id};
            }
        }
        else {
            $last_daughter{$id} = undef;
        }
        return $self;
    }

=item set_previous_sister()

 Type    : Mutator
 Title   : set_previous_sister
 Usage   : $node->set_previous_sister($p_sister);
 Function: Assigns a node's previous sister (to the left).
 Returns : Modified object.
 Args    : A valid argument consists of
           a Bio::Phylo::Forest::Node object.
           If no argument is given, the value
           is set to undefined.

=cut

    sub set_previous_sister {
        my ( $self, $previous_sister ) = @_;
        my $id = $self->get_id;
        if ( $previous_sister ) {
            my $type;
            eval { $type = $previous_sister->_type };
            if ( $@ || $type != _NODE_ ) {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw( 
                	error => "\"$previous_sister\" is not a valid node object" 
                );
            }
            else {
                $previous_sister{$id} = $previous_sister;
                weaken $previous_sister{$id};
            }
        }
        else {
            $previous_sister{$id} = undef;
        }
        return $self;
    }

=item set_next_sister()

 Type    : Mutator
 Title   : set_next_sister
 Usage   : $node->set_next_sister($n_sister);
 Function: Assigns or retrieves a node's
           next sister (to the right).
 Returns : Modified object.
 Args    : A valid argument consists of a
           Bio::Phylo::Forest::Node object.
           If no argument is given, the
           value is set to undefined.

=cut

    sub set_next_sister {
        my ( $self, $next_sister ) = @_;
        my $id = $self->get_id;
        if ( $next_sister ) {
            my $type;
            eval { $type = $next_sister->_type };
            if ( $@ || $type != _NODE_ ) {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    error => "\"$next_sister\" is not a valid node object" 
                );
            }
            else {
                $next_sister{$id} = $next_sister;
                weaken $next_sister{$id};
            }
        }
        else {
            $next_sister{$id} = undef;
        }
        return $self;
    }

=item set_child()

 Type    : Mutator
 Title   : set_child
 Usage   : $node->set_child($child);
 Function: Assigns a new child to $node
 Returns : Modified object.
 Args    : A valid argument consists of a
           Bio::Phylo::Forest::Node object.

=cut

    sub set_child {
        my ( $self, $child ) = @_;
        if ( $child ) {
            my $type;
            eval { $type = $child->_type };
            if ( $@ || $type != _NODE_ ) {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    error => "\"$child\" is not a valid node object" 
                );
            }
            else {
                if ( my $ld = $self->get_last_daughter ) {
                    $ld->set_next_sister($child);
                    $child->set_previous_sister($ld);
                    $self->set_last_daughter($child);
                }
                elsif ( my $fd = $self->get_first_daughter ) {
                    $fd->set_next_sister($child);
                    $child->set_previous_sister($fd);
                    $self->set_last_daughter($child);
                }
                else {
                    $self->set_first_daughter($child);
                }
                $child->set_parent($self);
            }
        }
        return $self;
    }

=item set_branch_length()

 Type    : Mutator
 Title   : branch_length
 Usage   : $node->set_branch_length(0.423e+2);
 Function: Assigns a node's branch length.
 Returns : Modified object.
 Args    : If no argument is given, the
           current branch length is set
           to undefined. A valid argument
           is a number in any of Perl's formats.

=cut

    sub set_branch_length {
        my ( $self, $bl ) = @_;
        my $id = $self->get_id;
        if ( defined $bl && looks_like_number $bl && !ref $bl ) {
            $branch_length{$id} = $bl;
        }
        elsif ( defined $bl && ( !looks_like_number $bl || ref $bl ) ) {
            Bio::Phylo::Util::Exceptions::BadNumber->throw(
                error => "Branch length \"$bl\" is a bad number" 
            );
        }
        elsif ( !defined $bl ) {
            $branch_length{$id} = undef;
        }
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_parent()

 Type    : Accessor
 Title   : get_parent
 Usage   : my $parent = $node->get_parent;
 Function: Retrieves a node's parent.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

    sub get_parent { $parent{ shift->get_id } }

=item get_first_daughter()

 Type    : Accessor
 Title   : get_first_daughter
 Usage   : my $f_daughter = $node->get_first_daughter;
 Function: Retrieves a node's leftmost daughter.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

    sub get_first_daughter { $first_daughter{ shift->get_id } }

=item get_last_daughter()

 Type    : Accessor
 Title   : get_last_daughter
 Usage   : my $l_daughter = $node->get_last_daughter;
 Function: Retrieves a node's rightmost daughter.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

    sub get_last_daughter { $last_daughter{ shift->get_id } }

=item get_previous_sister()

 Type    : Accessor
 Title   : get_previous_sister
 Usage   : my $p_sister = $node->get_previous_sister;
 Function: Retrieves a node's previous sister (to the left).
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

    sub get_previous_sister { $previous_sister{ shift->get_id } }

=item get_next_sister()

 Type    : Accessor
 Title   : get_next_sister
 Usage   : my $n_sister = $node->get_next_sister;
 Function: Retrieves a node's next sister (to the right).
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

    sub get_next_sister { $next_sister{ shift->get_id } }

=item get_branch_length()

 Type    : Accessor
 Title   : get_branch_length
 Usage   : my $branch_length = $node->get_branch_length;
 Function: Retrieves a node's branch length.
 Returns : FLOAT
 Args    : NONE
 Comments: Test for "defined($node->get_branch_length)"
           for zero-length (but defined) branches. Testing
           "if ( $node->get_branch_length ) { ... }"
           yields false for zero-but-defined branches!

=cut

    sub get_branch_length { $branch_length{ shift->get_id } }

=item get_ancestors()

 Type    : Query
 Title   : get_ancestors
 Usage   : my @ancestors = @{ $node->get_ancestors };
 Function: Returns an array reference of ancestral nodes,
           ordered from young to old.
 Returns : Array reference of Bio::Phylo::Forest::Node
           objects.
 Args    : NONE

=cut

    sub get_ancestors {
        my $self = shift;
        my @ancestors;
        my $node = $self;
        if ( $node = $node->get_parent ) {
            while ( $node ) {
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
 Function: Returns an array reference of sisters,
           ordered from left to right.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

    sub get_sisters {
        my $self = shift;
        my $sisters = $self->get_parent->get_children;
        return $sisters;
    }

=item get_children()

 Type    : Query
 Title   : get_children
 Usage   : my @children = @{ $node->get_children };
 Function: Returns an array reference of immediate
           descendants, ordered from left to right.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

    sub get_children {
        my $self = shift;
        my @children;
        my $fd = $self->get_first_daughter;
        if ( $fd ) {
            while ( $fd ) {
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
 Function: Returns an array reference of
           descendants, recursively ordered
           breadth first.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : none.

=cut

    sub get_descendants {
        my $self = shift;
        my @current = ($self);
        my @desc;
        while ( $self->_desc(@current) ) {
            @current = $self->_desc(@current);
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
        my $self    = shift;
        my @current = @_;
        my @return;
        foreach ( @current ) {
            my $children = $_->get_children;
            if ( $children ) {
                push @return, @{ $children };
            }
        }
        return @return;
    }

=item get_terminals()

 Type    : Query
 Title   : get_terminals
 Usage   : my @terminals = @{ $node->get_terminals };
 Function: Returns an array reference
           of terminal descendants.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

    sub get_terminals {
        my $self = shift;
        my @terminals;
        my $desc = $self->get_descendants;
        if ( @{ $desc } ) {
            foreach ( @{ $desc } ) {
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
 Function: Returns an array reference
           of internal descendants.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

    sub get_internals {
        my $self = shift;
        my @internals;
        my $desc = $self->get_descendants;
        if ( @{ $desc } ) {
            foreach ( @{ $desc } ) {
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
 Args    : A Bio::Phylo::Forest::Node
           object in the same tree.

=cut

    sub get_mrca {
        my ( $self, $other_node ) = @_;
        my $self_anc  = $self->get_ancestors;
        my $other_anc = $other_node->get_ancestors;
        for my $i ( 0 .. $#{$self_anc} ) {
            for my $j ( 0 .. $#{$other_anc} ) {
                if ( ${ $self_anc->[$i] } == ${ $other_anc->[$j] } ) {
                    return $self_anc->[$i];
                }
            }
        }
        return;
    }

=item get_leftmost_terminal()

 Type    : Query
 Title   : get_leftmost_terminal
 Usage   : my $leftmost_terminal =
           $node->get_leftmost_terminal;
 Function: Returns the leftmost
           terminal descendant of $node.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

    sub get_leftmost_terminal {
        my $self = shift;
        my $daughter = $self;
        while ( $daughter ) {
            if ( $daughter->get_first_daughter ) {
                $daughter = $daughter->get_first_daughter;
            }
            else {
                last;
            }
        }
        return $daughter;
    }

=item get_rightmost_terminal()

 Type    : Query
 Title   : get_rightmost_terminal
 Usage   : my $rightmost_terminal =
           $node->get_rightmost_terminal;
 Function: Returns the rightmost
           terminal descendant of $node.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

    sub get_rightmost_terminal {
        my $self = shift;
        my $daughter = $self;
        while ( $daughter ) {
            if ( $daughter->get_last_daughter ) {
                $daughter = $daughter->get_last_daughter;
            }
            else {
                last;
            }
        }
        return $daughter;
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
 Function: Returns true if node has
           no children (i.e. is terminal).
 Returns : BOOLEAN
 Args    : NONE

=cut

    sub is_terminal {
        return ! shift->is_internal;
    }

=item is_internal()

 Type    : Test
 Title   : is_internal
 Usage   : if ( $node->is_internal ) {
              # do something
           }
 Function: Returns true if node
           has children (i.e. is internal).
 Returns : BOOLEAN
 Args    : NONE

=cut

    sub is_internal {
	return !! shift->get_first_daughter;
    }

=item is_descendant_of()

 Type    : Test
 Title   : is_descendant_of
 Usage   : if ( $node->is_descendant_of($grandparent) ) {
              # do something
           }
 Function: Returns true if the node is
           a descendant of the argument.
 Returns : BOOLEAN
 Args    : putative ancestor - a
           Bio::Phylo::Forest::Node object.

=cut

    sub is_descendant_of {
        my ( $self, $parent ) = @_;
        while ($self) {
            if ( $self->get_parent ) {
                $self = $self->get_parent;
            }
            else {
                return;
            }
            if ( $self->get_id == $parent->get_id ) {
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
 Function: Returns true if the node
           is an ancestor of the argument.
 Returns : BOOLEAN
 Args    : putative descendant - a
           Bio::Phylo::Forest::Node object.

=cut

    sub is_ancestor_of {
        my ( $self, $child ) = @_;
        if ( $child->is_descendant_of($self) ) {
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
 Function: Returns true if the node is
           a sister of the argument.
 Returns : BOOLEAN
 Args    : putative sister - a
           Bio::Phylo::Forest::Node object.

=cut

    sub is_sister_of {
        my ( $self, $sis ) = @_;
        if (   $self->get_parent
            && $sis->get_parent
            && $self->get_parent == $sis->get_parent )
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
 Function: Tests whether the set of
           \@ingroup is monophyletic
           with respect to the $node.
 Returns : BOOLEAN
 Args    : A reference to an array of
           Bio::Phylo::Forest::Node objects;
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
 Usage   : my $path_to_root =
           $node->calc_path_to_root;
 Function: Returns the sum of branch
           lengths from $node to the root.
 Returns : FLOAT
 Args    : NONE

=cut

    sub calc_path_to_root {
        my $self = shift;
        my $node = $self;
        my $path = 0;
        while ( $node ) {
            if ( defined $node->get_branch_length ) {
                $path += $node->get_branch_length;
            }
            if ( $node->get_parent ) {
                $node = $node->get_parent;
            }
            else {
                last;
            }
        }
        return $path;
    }

=item calc_nodes_to_root()

 Type    : Calculation
 Title   : calc_nodes_to_root
 Usage   : my $nodes_to_root =
           $node->calc_nodes_to_root;
 Function: Returns the number of nodes
           from $node to the root.
 Returns : INT
 Args    : NONE

=cut

    sub calc_nodes_to_root {
        my $self = shift;
        my ( $nodes, $parent ) = ( 0, $self );
        while ( $parent ) {
            $nodes++;
            $parent = $parent->get_parent;
            if ( $parent ) {
                if ( my $cntr = $parent->calc_nodes_to_root ) {
                    $nodes += $cntr;
                    last;
                }
            }
        }
        return $nodes;
    }

=item calc_max_nodes_to_tips()

 Type    : Calculation
 Title   : calc_max_nodes_to_tips
 Usage   : my $max_nodes_to_tips =
           $node->calc_max_nodes_to_tips;
 Function: Returns the maximum number
           of nodes from $node to tips.
 Returns : INT
 Args    : NONE

=cut

    sub calc_max_nodes_to_tips {
        my $self = shift;
        my ( $nodes, $maxnodes ) = ( 0, 0 );
        foreach my $child ( @{ $self->get_terminals } ) {
            $nodes = 0;
            while ( $child && $child->get_id != $self->get_id ) {
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
 Usage   : my $min_nodes_to_tips =
           $node->calc_min_nodes_to_tips;
 Function: Returns the minimum number of
           nodes from $node to tips.
 Returns : INT
 Args    : NONE

=cut

    sub calc_min_nodes_to_tips {
        my $self = shift;
        my ( $nodes, $minnodes );
        foreach my $child ( @{ $self->get_terminals } ) {
            $nodes = 0;
            while ( $child && $child->get_id != $self->get_id ) {
                $nodes++;
                $child = $child->get_parent;
            }
            if ( !$minnodes || $nodes < $minnodes ) {
                $minnodes = $nodes;
            }
        }
        return $minnodes;
    }

=item calc_max_path_to_tips()

 Type    : Calculation
 Title   : calc_max_path_to_tips
 Usage   : my $max_path_to_tips =
           $node->calc_max_path_to_tips;
 Function: Returns the path length from
           $node to the tallest tip.
 Returns : FLOAT
 Args    : NONE

=cut

    sub calc_max_path_to_tips {
        my $self = shift;
        my $id = $self->get_id;
        my ( $length, $maxlength ) = ( 0, 0 );
        foreach my $child ( @{ $self->get_terminals } ) {
            $length = 0;
            while ( $child && $child->get_id != $id ) {
                my $branch_length = $child->get_branch_length;
                if ( defined $branch_length ) {
                    $length += $branch_length;
                }
                $child = $child->get_parent;
            }
            if ( $length > $maxlength ) {
                $maxlength = $length;
            }
        }
        return $maxlength;
    }

=item calc_min_path_to_tips()

 Type    : Calculation
 Title   : calc_min_path_to_tips
 Usage   : my $min_path_to_tips =
           $node->calc_min_path_to_tips;
 Function: Returns the path length from
           $node to the shortest tip.
 Returns : FLOAT
 Args    : NONE

=cut

    sub calc_min_path_to_tips {
        my $self = shift;
        my $id = $self->get_id;
        my ( $length, $minlength );
        foreach my $child ( @{ $self->get_terminals } ) {
            $length = 0;
            while ( $child && $child->get_id != $id ) {
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
                $minlength = $length;
            }
        }
        return $minlength;
    }

=item calc_patristic_distance()

 Type    : Calculation
 Title   : calc_patristic_distance
 Usage   : my $patristic_distance =
           $node->calc_patristic_distance($other_node);
 Function: Returns the patristic distance
           between $node and $other_node.
 Returns : FLOAT
 Args    : Bio::Phylo::Forest::Node

=cut

    sub calc_patristic_distance {
        my ( $self, $other_node ) = @_;
        my $patristic_distance;
        my $mrca    = $self->get_mrca( $other_node );
        my $mrca_id = $mrca->get_id;
        while ( $self->get_id != $mrca_id ) {
            my $branch_length = $self->get_branch_length;
            if ( defined $branch_length ) {
                $patristic_distance += $branch_length;
            }
            $self = $self->get_parent;
        }
        while ( $other_node->get_id != $mrca_id ) {
            my $branch_length = $other_node->get_branch_length;
            if ( defined $branch_length ) {
                $patristic_distance += $branch_length;
            }
            $other_node = $other_node->get_parent;
        }
        return $patristic_distance;
    }

=item to_xml()

 Type    : Format converter
 Title   : to_xml
 Usage   : my $xml = $obj->to_xml;
 Function: Turns the invocant object into an XML string.
 Returns : SCALAR
 Args    : NONE

=cut

    sub to_xml {
        my $self  = shift;
        my $class = ref $self;
        $class =~ s/^.*:([^:]+)$/$1/g;
        $class = lc($class);
        my $xml     = '<' . $class . ' id="' . $class . $self->get_id . '">';
        my $generic = $self->get_generic;
        my ( $name, $score, $desc ) =
          ( $self->get_name, $self->get_score, $self->get_desc );
        $xml .= '<name>' . $name . '</name>'    if $name;
        $xml .= '<score>' . $score . '</score>' if $score;
        $xml .= '<desc>' . $desc . '</desc>'    if $desc;
        if ( $generic and ref $generic eq 'HASH' ) {
            $xml .= '<generic>';
            $xml .= "<prop><key>$_</key><val>$generic->{$_}</val></prop>\n" for keys %$generic;
            $xml .= '</generic>';
        }
        $xml .= '<branchlength>' . $self->get_branch_length . '</branchlength>'
          if defined $self->get_branch_length;
        $xml .= '<parent idref="' . $class . $self->get_parent->get_id . '" />'
          if $self->get_parent;
        $xml .= '</' . $class . '>';
        return $xml;
    }

=begin comment

 Type    : Internal method
 Title   : _cleanup
 Usage   : $trees->_cleanup;
 Function: Called during object destruction, for cleanup of instance data
 Returns : 
 Args    :

=end comment

=cut

    sub _cleanup {
        my $self = shift;
        $self->info("cleaning up '$self'");
        my $id = $self->get_id;
        for my $field ( @fields ) {
            delete $field->{$id};
        }
    }

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

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

This object inherits from L<Bio::Phylo>, so the methods defined
therein are also applicable to L<Bio::Phylo::Forest::Node> objects.

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

$Id: Node.pm 3386 2007-03-24 16:22:25Z rvosa $

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

}

1;
