# $Id: Node.pm 844 2009-03-05 00:07:26Z rvos $
package Bio::Phylo::Forest::Node;
use strict;
use Bio::Phylo::Taxa::TaxonLinker;
use Bio::Phylo::Util::CONSTANT qw(_NODE_ _TREE_ _TAXON_ looks_like_number looks_like_object looks_like_hash);
use Bio::Phylo::Listable;
use Bio::Phylo::Util::Exceptions 'throw';
use Scalar::Util 'weaken';

no warnings 'recursion';

# classic @ISA manipulation, not using 'base'
use vars qw(@ISA);
@ISA = qw(
  Bio::Phylo::Taxa::TaxonLinker
  Bio::Phylo::Listable
);

my $LOADED_WRAPPERS = 0;

{

	# logger singleton
	my $logger = __PACKAGE__->get_logger;

	# store type constant
	my ( $TYPE_CONSTANT, $CONTAINER_CONSTANT ) = ( _NODE_, _TREE_ );

	# @fields array necessary for object destruction
	my @fields = \( my ( %branch_length, %parent, %tree ) );

=head1 NAME

Bio::Phylo::Forest::Node - Node in a phylogenetic tree

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

Node constructor.

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
		$logger->info("constructor called for '$class'");
		
		# process bioperl args
		my %args = looks_like_hash @_;
		if ( exists $args{'-leaf'} ) {
			delete $args{'-leaf'};
		}
		if ( exists $args{'-id'} ) {
			my $name = $args{'-id'};
			delete $args{'-id'};
			$args{'-name'} = $name;
		}
		if ( exists $args{'-nhx'} ) {
			my $hash = $args{'-nhx'};
			delete $args{'-nhx'};
			$args{'-generic'} = $hash;
		}
		if ( not exists $args{'-tag'} ) {
			$args{'-tag'} = 'node';
		}

		# go up inheritance tree, eventually get an ID
		my $self = $class->SUPER::new(%args);
		
		if ( not $LOADED_WRAPPERS ) {
			eval do { local $/; <DATA> };
			$LOADED_WRAPPERS++;
		}	

		return $self;
	}

	my $set_raw_parent = sub {
		my ( $self, $parent ) = @_;
		$parent{ $$self } = $parent; # XXX here we modify parent
		weaken $parent{ $$self } if $parent;
	};

	my $get_parent = sub {
		my $self = shift;
		return $parent{ $$self };
	};
	
	my $get_children = sub { shift->get_entities };
	
	my $get_branch_length = sub {
		my $self = shift;
		return $branch_length{ $$self };
	};

	my $set_raw_child = sub {
		my ( $self, $child, $i ) = @_;
		$i = $self->last_index + 1 if not defined $i or $i == -1;
		$self->insert_at_index( $child, $i ); # XXX here we modify children
	};

=item new_from_bioperl()

Node constructor from bioperl L<Bio::Tree::NodeI> argument.

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
 Notes   : The following BioPerl properties are copied:
           BioPerl output:        Bio::Phylo output:
           ------------------------------------------------
           id                     get_name
           branch_length          get_branch_length
           description            get_desc
           bootstrap              get_generic('bootstrap')
           
           In addition all BioPerl tags and values are copied
           to set_generic( 'tag' => 'value' );

=cut

	sub new_from_bioperl {
		my ( $class, $bpnode ) = @_;
		my $node = $class->new;
		
		# copy name
		my $name = $bpnode->id;
		$node->set_name( $name ) if defined $name;
		
		# copy branch length
		my $branch_length = $bpnode->branch_length;
		$node->set_branch_length( $branch_length ) if defined $branch_length;
		
		# copy description
		my $desc = $bpnode->description;
		$node->set_desc( $desc ) if defined $desc;
		
		# copy bootstrap
		my $bootstrap = $bpnode->bootstrap;
		$node->set_score( $bootstrap ) if defined $bootstrap and looks_like_number $bootstrap;
		
		# copy other tags
		for my $tag ( $bpnode->get_all_tags ) {
		    my @values = $bpnode->get_tag_values( $tag );
			$node->set_generic( $tag => \@values );
		}
		return $node;
	}

=back

=head2 MUTATORS

=over

=item prune_child()

Sets argument as invocant's parent.

 Type    : Mutator
 Title   : prune_child
 Usage   : $parent->prune_child($child);
 Function: Removes $child (and its descendants) from $parent's children
 Returns : Modified object.
 Args    : A valid argument is Bio::Phylo::Forest::Node object.

=cut

	sub prune_child {
		my ( $self, $child ) = @_;	
		$self->delete( $child );
		return $self;
	}

=item collapse()

Collapse node.

 Type    : Mutator
 Title   : collapse
 Usage   : $node->collapse;
 Function: Attaches invocant's children to invocant's parent.
 Returns : Modified object.
 Args    : NONE
 Comments: If defined, adds invocant's branch 
           length to that of its children. If
           $node is in a tree, removes itself
           from that tree.

=cut

	sub collapse {
		my $self = shift;
		
		# can't collapse root
		if ( my $parent = $self->get_parent ) {
		
			# can't collapse terminal nodes
			if ( my @children = @{ $self->get_children } ) {
			
				# add node's branch length to that of children
				my $length = $self->get_branch_length;
				for my $child ( @children ) {
					if ( defined $length ) {
						my $child_length = $child->get_branch_length || 0;
						$child->set_branch_length( $length + $child_length );
					}
					
					# attach children to node's parent
					$child->set_parent( $parent );
				}
				
				# prune node from parent
				$parent->prune_child( $self );
				
				# delete node from tree
				if ( my $tree = $self->_get_container ) {
					$tree->delete( $self );
				}
			}
			else {
				return $self;
			}
		}
		else {
			return $self;
		}
	}

=item set_parent()

Sets argument as invocant's parent.

 Type    : Mutator
 Title   : set_parent
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
		if ( $parent and looks_like_object $parent, $TYPE_CONSTANT ) {		
			$parent->set_child( $self );
		}
		elsif ( not $parent ) {
			$set_raw_parent->( $self );
		}
		return $self;
	}

=item set_first_daughter()

Sets argument as invocant's first daughter.

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
		my ( $self, $fd ) = @_;
		$self->set_child( $fd, 0 );
		return $self;
	}

=item set_last_daughter()

Sets argument as invocant's last daughter.

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
		my ( $self, $ld ) = @_;
		$self->set_child( $ld, scalar @{ $self->get_children } );
		return $self;
	}

=item set_previous_sister()

Sets argument as invocant's previous sister.

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
		my ( $self, $ps ) = @_;
		if ( $ps and looks_like_object $ps, $TYPE_CONSTANT ) {
			if ( my $parent  = $self->get_parent ) {
				my $children = $parent->get_children;
				my $j = 0;
				FINDSELF: for ( my $i = $#{ $children }; $i >= 0; $i-- ) {
					if ( $children->[$i] == $self ) {
						$j = $i - 1;
						last FINDSELF;
					}
				}
				$j = 0 if $j == -1;
				$parent->set_child( $ps, $j );
			}
		}
		return $self;
	}

=item set_next_sister()

Sets argument as invocant's next sister.

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
		my ( $self, $ns ) = @_;
		if ( $ns and looks_like_object $ns, $TYPE_CONSTANT ) {
			if ( my $parent  = $self->get_parent ) {
				my $children = $parent->get_children;
				my $last = scalar @{ $children };		
				my $j = $last;
				FINDSELF: for my $i ( 0 .. $#{ $children } ) {
					if ( $children->[$i] == $self ) {
						$j = $i + 1;
						last FINDSELF;
					}
				}
				$parent->set_child( $ns, $j );
			}
		}
		return $self;
	}

=item set_child()

Sets argument as invocant's child.

 Type    : Mutator
 Title   : set_child
 Usage   : $node->set_child($child);
 Function: Assigns a new child to $node
 Returns : Modified object.
 Args    : A valid argument consists of a
           Bio::Phylo::Forest::Node object.

=cut

	sub set_child {
		my ( $self, $child, $i ) = @_;
		
		# bad args?
		if ( not $child or not looks_like_object $child, $TYPE_CONSTANT ) {
			return;
		}
		
		# maybe nothing to do?
		if ( not $child or $child->get_id == $self->get_id or $child->is_child_of($self) ) {
			return $self;
		}
		
		# $child_parent is NEVER $self, see above
		my $child_parent = $child->get_parent;
		
		# child is ancestor: this is obviously problematic, because
		# now we're trying to set a node nearer to the root on the
		# same lineage as the CHILD of a descendant. Because they're
		# on the same lineage it's hard to see how this can be done
		# sensibly. The decision here is to do:
		# 	1. we prune what is to become the parent (now the descendant)
		#	   from its current parent
		#	2. we set this pruned node (and its descendants) as a sibling
		#	   of what is to become the child
		#	3. we prune what is to become the child from its parent
		#	4. we set that pruned child as the child of $self
		if ( $child->is_ancestor_of( $self ) ) {
			
			# step 1.
			my $parent_parent = $self->get_parent;
			$parent_parent->prune_child( $self );
			
			# step 2.
			$set_raw_parent->( $self, $child_parent ); # XXX could be undef	
			if ( $child_parent ) {
				$set_raw_child->( $child_parent, $self );
			}
		
		}
		
		# step 3.
		if ( $child_parent ) {
			$child_parent->prune_child( $child );
		}
		$set_raw_parent->( $child, $self );
		
		# now do the insert, first make room by shifting later siblings right
		my $children = $self->get_children;
		if ( defined $i ) {
			for ( my $j = $#{ $children }; $j >= 0; $j-- ) {
				my $sibling = $children->[$j];
				$set_raw_child->( $self, $sibling, $j + 1 );
			}
		}
		
		# no index was supplied, child becomes last daughter
		else {
			$i = scalar @{ $children };
		}
		
		# step 4.
		$set_raw_child->( $self, $child, $i );
	
		return $self;
	}

=item set_branch_length()

Sets argument as invocant's branch length.

 Type    : Mutator
 Title   : set_branch_length
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
		my $id = $$self;
		if ( defined $bl && looks_like_number $bl && !ref $bl ) {
			$branch_length{$id} = $bl;
		}
		elsif ( defined $bl && ( !looks_like_number $bl || ref $bl ) ) {
			throw 'BadNumber' => "Branch length \"$bl\" is a bad number";
		}
		elsif ( !defined $bl ) {
			$branch_length{$id} = undef;
		}
		return $self;
	}

=item set_node_below()

Sets new (unbranched) node below invocant.

 Type    : Mutator
 Title   : set_node_below
 Usage   : my $new_node = $node->set_node_below;
 Function: Creates a new node below $node
 Returns : New node if tree was modified, undef otherwise
 Args    : NONE

=cut 

	sub set_node_below {
		my $self = shift;
		
		# can't set node below root
		if ( $self->is_root ) {
			return;
		}
		
		# instantiate new node from $self's class
		my $new_node = ( ref $self )->new( @_ );
		
		# attach new node to $child's parent
		my $parent = $self->get_parent;
		$parent->set_child( $new_node );
		
		# insert new node in tree
# 		if ( my $tree = $self->_get_container ) {
# 			$tree->insert( $new_node );
# 		}
		
		# attach $self to new node
		$new_node->set_child( $self );	
		
		# done
		return $new_node;
	}

=item set_root_below()

Reroots below invocant.

 Type    : Mutator
 Title   : set_root_below
 Usage   : $node->set_root_below;
 Function: Creates a new tree root below $node
 Returns : New root if tree was modified, undef otherwise
 Args    : NONE
 Comments: Implementation incomplete: returns spurious 
           results when $node is grandchild of current root.

=cut    

# Example tree to illustrate rerooting algorithm:
#
#  A     B     C     D     E     F
#   \   /     /     /     /     /
#    \_/     /     /     /     /
#     1     /     /     /     /
# new->\   /     /     /     /
#       \_/     /     /     /
#        2     /     /     /
#         \   /     /     /
#          \_/     /     /
#           3     /     /
#            \   /     /
#             \_/     /
#              4     / 
#               \   /
#                \_/
#                 5
#                 |
           
sub set_root_below {
	my $self = shift;
	my %constructor_args = @_;
	$constructor_args{'-name'} = 'root' if not $constructor_args{'-name'};
	
	# $self is node 5, nothing to do,
	# can't place root below root
	if ( $self->is_root ) {
		return;
	}
	
	my @ancestors = @{ $self->get_ancestors };
	
	# if @ancestors = ( 5 ); i.e. $self is node 4
	# root is already below $self
	if ( scalar @ancestors == 1 ) {
		return;
	}
	
	# let's say $self is node 1, ancestors is:	
	# ( 2, 3, 4, 5 ) -> ( 2, 3, 4 )
	my $root = pop @ancestors;
	
	# ( 2, 3, 4 ) -> ( 2, 3 )
	my $node_above_root = pop @ancestors; 
	
	# collapse node 4
	$node_above_root->collapse; 
	
	 # ( 2, 3 ) -> ( 2, 3, 5 ); 4 doesn't exist anymore (collapsed)
	push @ancestors, $root;   
	
	# ( 2, 3, 5 ) -> ( new, 2, 3, 5 )
	unshift @ancestors, $self->set_node_below(%constructor_args); 
	
	# i.e. $self wasn't 3
	if ( scalar @ancestors > 2 ) {
		for ( my $i = $#ancestors; $i >= 0; $i-- ) {
		
			# flip parent & child
			$ancestors[$i]->set_child( $ancestors[$i+1] ); 
		}
	}
	else {
		# XXX
		$logger->warn;
		$ancestors[0]->set_child( $ancestors[1] );
	}

	if ( my $tree = $self->get_tree ) {
	    $tree->insert($ancestors[0]);
	}
	return $ancestors[0];
	
}

# 	sub set_root_below {
# 		my $node = shift;
# 		if ( $node->get_ancestors ) {
# 			my @ancestors = @{ $node->get_ancestors };
# 
# 			# first collapse root
# 			my $root = $ancestors[-1];
# 			my $lineage_containing_node;
# 			my @children = @{ $root->get_children };
# 		  FIND_LINEAGE: for my $child (@children) {
# 				if ( $child->get_id == $node->get_id ) {
# 					$lineage_containing_node = $child;
# 					last FIND_LINEAGE;
# 				}
# 				for my $descendant ( @{ $child->get_descendants } ) {
# 					if ( $descendant->get_id == $node->get_id ) {
# 						$lineage_containing_node = $child;
# 						last FIND_LINEAGE;
# 					}
# 				}
# 			}
# 			for my $child (@children) {
# 				next if $child->get_id == $lineage_containing_node->get_id;
# 				$child->set_parent($lineage_containing_node);
# 			}
# 
# 			# now create new root as parent of $node
# 			my $newroot = __PACKAGE__->new( '-name' => 'root' );
# 			$node->set_parent($newroot);
# 
# 			# update list of ancestors, want to get rid of old root
# 			# at $ancestors[-1] and have new root as $ancestors[0]
# 			unshift @ancestors, $newroot;
# 			pop @ancestors;
# 
# 			# update connections
# 			for ( my $i = $#ancestors ; $i >= 1 ; $i-- ) {
# 				$ancestors[$i]->set_parent( $ancestors[ $i - 1 ] );
# 			}
# 
# 			# delete root if part of tree, insert new
# 			if ( my $tree = $node->_get_container ) {
# 				$tree->delete($root);
# 				$tree->insert($newroot);
# 			}
# 		}
# 	}

=item set_tree()

Sets what tree invocant belongs to

 Type    : Mutator
 Title   : set_tree
 Usage   : $node->set_tree($tree);
 Function: Sets what tree invocant belongs to
 Returns : Invocant
 Args    : Bio::Phylo::Forest::Tree
 Comments: This method is called automatically 
           when inserting or deleting nodes in
           trees.

=cut 

    sub set_tree {
        my ( $self, $tree ) = @_;
        my $id = $self->get_id;
        if ( $tree ) {
            if ( looks_like_object $tree, $CONTAINER_CONSTANT ) {
                $tree{$id} = $tree;
                weaken $tree{$id};
            }
            else {
                throw 'ObjectMismatch' => "$tree is not a tree";
            }
        }
        else {
            $tree{$id} = undef;
        }
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_parent()

Gets invocant's parent.

 Type    : Accessor
 Title   : get_parent
 Usage   : my $parent = $node->get_parent;
 Function: Retrieves a node's parent.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

	sub get_parent { return $get_parent->( shift ) }

=item get_first_daughter()

Gets invocant's first daughter.

 Type    : Accessor
 Title   : get_first_daughter
 Usage   : my $f_daughter = $node->get_first_daughter;
 Function: Retrieves a node's leftmost daughter.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

	sub get_first_daughter {
		return $_[0]->get_child(0);
	}

=item get_last_daughter()

Gets invocant's last daughter.

 Type    : Accessor
 Title   : get_last_daughter
 Usage   : my $l_daughter = $node->get_last_daughter;
 Function: Retrieves a node's rightmost daughter.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

	sub get_last_daughter {
		return $_[0]->get_child(-1);
	}

=item get_previous_sister()

Gets invocant's previous sister.

 Type    : Accessor
 Title   : get_previous_sister
 Usage   : my $p_sister = $node->get_previous_sister;
 Function: Retrieves a node's previous sister (to the left).
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

	sub get_previous_sister {
		my ( $self ) = @_;
		my $ps;
		if ( my $parent = $self->get_parent ) {
			my $children = $parent->get_children;
			FINDSELF: for ( my $i = $#{ $children }; $i >= 1; $i-- ) {
				if ( $children->[$i] == $self ) {
					$ps = $children->[$i - 1];
					last FINDSELF;				
				}
			}
		}
		return $ps;
	}

=item get_next_sister()

Gets invocant's next sister.

 Type    : Accessor
 Title   : get_next_sister
 Usage   : my $n_sister = $node->get_next_sister;
 Function: Retrieves a node's next sister (to the right).
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

	sub get_next_sister {
		my ( $self ) = @_;
		my $ns;
		if ( my $parent = $self->get_parent ) {
			my $children = $parent->get_children;
			FINDSELF: for my $i ( 0 .. $#{ $children } ) {
				if ( $children->[$i] == $self ) {
					$ns = $children->[$i + 1];
					last FINDSELF;
				}
			}
		}
		return $ns;
	}

=item get_branch_length()

Gets invocant's branch length.

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

	sub get_branch_length { return $get_branch_length->( shift ) }

=item get_ancestors()

Gets invocant's ancestors.

 Type    : Query
 Title   : get_ancestors
 Usage   : my @ancestors = @{ $node->get_ancestors };
 Function: Returns an array reference of ancestral nodes,
           ordered from young to old (i.e. $ancestors[-1] is root).
 Returns : Array reference of Bio::Phylo::Forest::Node
           objects.
 Args    : NONE

=cut

	sub get_ancestors {
		my $self = shift;
		my @ancestors;
		my $node = $self;
		if ( $node = $node->get_parent ) {
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

Gets invocant's sisters.

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
		my $self    = shift;
		my $sisters = $self->get_parent->get_children;
		return $sisters;
	}

=item get_children()

Gets invocant's immediate children.

 Type    : Query
 Title   : get_children
 Usage   : my @children = @{ $node->get_children };
 Function: Returns an array reference of immediate
           descendants, ordered from left to right.
 Returns : Array reference of
           Bio::Phylo::Forest::Node objects.
 Args    : NONE

=cut

	sub get_children { return $get_children->( shift ) }

=item get_child()

Gets invocant's i'th child.

 Type    : Query
 Title   : get_child
 Usage   : my $child = $node->get_child($i);
 Function: Returns the child at index $i
 Returns : A Bio::Phylo::Forest::Node object.
 Args    : An index (integer) $i
 Comments: if no index is specified, first
           child is returned

=cut

	sub get_child {
		my ( $self, $i ) = @_;
		$i = 0 if not defined $i;
		my $children = $self->get_children;
		return $children->[$i];
	}

=item get_descendants()

Gets invocant's descendants.

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
		my $self    = shift;
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
		foreach (@current) {
			my $children = $_->get_children;
			if ($children) {
				push @return, @{$children};
			}
		}
		return @return;
	}

=item get_terminals()

Gets invocant's terminal descendants.

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
		if ( @{$desc} ) {
			foreach ( @{$desc} ) {
				if ( $_->is_terminal ) {
					push @terminals, $_;
				}
			}
		}
		return \@terminals;
	}

=item get_internals()

Gets invocant's internal descendants.

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
		if ( @{$desc} ) {
			foreach ( @{$desc} ) {
				if ( $_->is_internal ) {
					push @internals, $_;
				}
			}
		}
		return \@internals;
	}

=item get_mrca()

Gets invocant's most recent common ancestor shared with argument.

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
		$logger->warn( "using " . $self_anc->[-1]->get_internal_name );
		return $self_anc->[-1];
	}

=item get_leftmost_terminal()

Gets invocant's leftmost terminal descendant.

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
		my $self     = shift;
		my $daughter = $self;
	  FIRST_DAUGHTER: while ($daughter) {
			if ( my $grand_daughter = $daughter->get_first_daughter ) {
				$daughter = $grand_daughter;
				next FIRST_DAUGHTER;
			}
			else {
				last FIRST_DAUGHTER;
			}
		}
		return $daughter;
	}

=item get_rightmost_terminal()

Gets invocant's rightmost terminal descendant

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
		my $self     = shift;
		my $daughter = $self;
	  LAST_DAUGHTER: while ($daughter) {
			if ( my $grand_daughter = $daughter->get_last_daughter ) {
				$daughter = $grand_daughter;
				next LAST_DAUGHTER;
			}
			else {
				last LAST_DAUGHTER;
			}
		}
		return $daughter;
	}

=item get_tree()

Returns the tree invocant belongs to

 Type    : Query
 Title   : get_tree
 Usage   : my $tree = $node->get_tree;
 Function: Returns the tree $node belongs to
 Returns : Bio::Phylo::Forest::Tree
 Args    : NONE

=cut

    sub get_tree {
        my $self = shift;
        my $id = $self->get_id;
        return $tree{$id};
    }

=back

=head2 TESTS

=over

=item is_terminal()

Tests if invocant is a terminal node.

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
		return !shift->get_first_daughter;
	}

=item is_internal()

Tests if invocant is an internal node.

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
		return !!shift->get_first_daughter;
	}
	
=item is_first()

Tests if invocant is first sibling in left-to-right order.

 Type    : Test
 Title   : is_first
 Usage   : if ( $node->is_first ) {
              # do something
           }
 Function: Returns true if first sibling 
           in left-to-right order.
 Returns : BOOLEAN
 Args    : NONE

=cut

	sub is_first {
		return !shift->get_previous_sister;
	}

=item is_last()

Tests if invocant is last sibling in left-to-right order.

 Type    : Test
 Title   : is_last
 Usage   : if ( $node->is_last ) {
              # do something
           }
 Function: Returns true if last sibling 
           in left-to-right order.
 Returns : BOOLEAN
 Args    : NONE

=cut

	sub is_last {
		return !shift->get_next_sister;
	}	

=item is_root()

Tests if invocant is a root.

 Type    : Test
 Title   : is_root
 Usage   : if ( $node->is_root ) {
              # do something
           }
 Function: Returns true if node is a root       
 Returns : BOOLEAN
 Args    : NONE

=cut

	sub is_root {
		return !shift->get_parent;
	}

=item is_descendant_of()

Tests if invocant is descendant of argument.

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
		my ( $self, $ancestor ) = @_;
		my $ancestor_id = $$ancestor;
		while ($self) {
			if ( my $parent = $self->get_parent ) {
				$self = $parent;
			}
			else {
				return;
			}
			if ( $$self == $ancestor_id ) {
				return 1;
			}
		}
	}

=item is_ancestor_of()

Tests if invocant is ancestor of argument.

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

Tests if invocant is sister of argument.

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
		my ( $self, $sister ) = @_;
		my ( $self_parent, $sister_parent ) =
		  ( $self->get_parent, $sister->get_parent );
		if (   $self_parent
			&& $sister_parent
			&& $self_parent->get_id == $sister_parent->get_id )
		{
			return 1;
		}
		else {
			return;
		}
	}

=item is_child_of()

Tests if invocant is child of argument.

 Type    : Test
 Title   : is_child_of
 Usage   : if ( $node->is_child_of($parent) ) {
              # do something
           }
 Function: Returns true if the node is
           a child of the argument.
 Returns : BOOLEAN
 Args    : putative parent - a
           Bio::Phylo::Forest::Node object.

=cut

	sub is_child_of {
		my ( $self, $node ) = @_;
		if ( my $parent = $self->get_parent ) {
			return $parent->get_id == $node->get_id;
		}
		return 0;
	}

=item is_outgroup_of()

Test if invocant is outgroup of argument nodes.

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

=item can_contain()

Test if argument(s) can be a child/children of invocant.

 Type    : Test
 Title   : can_contain
 Usage   : if ( $parent->can_contain(@children) ) {
              # do something
           }
 Function: Test if arguments can be children of invocant.
 Returns : BOOLEAN
 Args    : An array of Bio::Phylo::Forest::Node objects;
 Comments: This method is an override of 
           Bio::Phylo::Listable::can_contain. Since node
           objects hold a list of their children, they
           inherit from the listable class and so they
           need to be able to validate the contents
           of that list before they are inserted.

=cut

	sub can_contain {
		my $self = shift;
		my $type = $self->_type;
		for ( @_ ) {
			return 0 if $type != $_->_type;
		}
		return 1;
	}

=back

=head2 CALCULATIONS

=over

=item calc_path_to_root()

Calculates path to root.

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
		while ($node) {
			my $branch_length = $node->get_branch_length;
			if ( defined $branch_length ) {
				$path += $branch_length;
			}
			if ( my $parent = $node->get_parent ) {
				$node = $parent;
			}
			else {
				last;
			}
		}
		return $path;
	}

=item calc_nodes_to_root()

Calculates number of nodes to root.

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
		while ($parent) {
			$nodes++;
			$parent = $parent->get_parent;
			if ($parent) {
				if ( my $cntr = $parent->calc_nodes_to_root ) {
					$nodes += $cntr;
					last;
				}
			}
		}
		return $nodes;
	}

=item calc_max_nodes_to_tips()

Calculates maximum number of nodes to tips.

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
		my $self    = shift;
		my $self_id = $self->get_id;
		my ( $nodes, $maxnodes ) = ( 0, 0 );
		foreach my $child ( @{ $self->get_terminals } ) {
			$nodes = 0;
			while ( $child && $child->get_id != $self_id ) {
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

Calculates minimum number of nodes to tips.

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
		my $self    = shift;
		my $self_id = $self->get_id;
		my ( $nodes, $minnodes );
		foreach my $child ( @{ $self->get_terminals } ) {
			$nodes = 0;
			while ( $child && $child->get_id != $self_id ) {
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

Calculates longest path to tips.

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
		my $id   = $self->get_id;
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

Calculates shortest path to tips.

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
		my $id   = $self->get_id;
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

Calculates patristic distance between invocant and argument.

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
		my $mrca    = $self->get_mrca($other_node);
		my $mrca_id = $mrca->get_id;
		while ( $self->get_id != $mrca_id ) {
			my $branch_length = $self->get_branch_length;
			if ( defined $branch_length ) {
				$patristic_distance += $branch_length;
			}
			$self = $self->get_parent;
		}
		while ( $other_node and $other_node->get_id != $mrca_id ) {
			my $branch_length = $other_node->get_branch_length;
			if ( defined $branch_length ) {
				$patristic_distance += $branch_length;
			}
			$other_node = $other_node->get_parent;
		}
		return $patristic_distance;
	}
	
=item calc_nodal_distance()

Calculates node distance between invocant and argument.

 Type    : Calculation
 Title   : calc_nodal_distance
 Usage   : my $nodal_distance =
           $node->calc_nodal_distance($other_node);
 Function: Returns the number of nodes
           between $node and $other_node.
 Returns : INT
 Args    : Bio::Phylo::Forest::Node

=cut	
	
	sub calc_nodal_distance {
	    my ( $self, $other_node ) = @_;
	    my $nodal_distance;
	    my $mrca = $self->get_mrca( $other_node );
	    my $mrca_id = $mrca->get_id;
		while ( $self and $self->get_id != $mrca_id ) {
			$nodal_distance++;
			$self = $self->get_parent;
		}
		while ( $other_node and $other_node->get_id != $mrca_id ) {
			$nodal_distance++;
			$other_node = $other_node->get_parent;
		}
		return $nodal_distance;	    
	}

=back

=head2 VISITOR METHODS

The methods below are similar in spirit to those by the same name in L<Bio::Phylo::Forest::Tree>,
except those in the tree class operate from the tree root, and those in this node class operate
on an invocant node, and so these process a subtree.

=over

=item visit_depth_first()

Visits nodes depth first

 Type    : Visitor method
 Title   : visit_depth_first
 Usage   : $tree->visit_depth_first( -pre => sub{ ... }, -post => sub { ... } );
 Function: Visits nodes in a depth first traversal, executes subs
 Returns : $tree
 Args    : Optional:
            # first event handler, is executed when node is reached in recursion
            -pre            => sub { print "pre: ",            shift->get_name, "\n" },
                        
            # is executed if node has a daughter, but before that daughter is processed
            -pre_daughter   => sub { print "pre_daughter: ",   shift->get_name, "\n" },
            
            # is executed if node has a daughter, after daughter has been processed 
            -post_daughter  => sub { print "post_daughter: ",  shift->get_name, "\n" },
            
            # is executed if node has no daughter
            -no_daughter    => sub { print "no_daughter: ",    shift->get_name, "\n" },                         

            # is executed whether or not node has sisters, if it does have sisters
            # they're processed first   
            -in             => sub { print "in: ",             shift->get_name, "\n" },

            # is executed if node has a sister, before sister is processed
            -pre_sister     => sub { print "pre_sister: ",     shift->get_name, "\n" }, 
            
            # is executed if node has a sister, after sister is processed
            -post_sister    => sub { print "post_sister: ",    shift->get_name, "\n" },         
            
            # is executed if node has no sister
            -no_sister      => sub { print "no_sister: ",      shift->get_name, "\n" }, 
            
            # is executed last          
            -post           => sub { print "post: ",           shift->get_name, "\n" },
            
            # specifies traversal order, default 'ltr' means first_daugher -> next_sister
            # traversal, alternate value 'rtl' means last_daughter -> previous_sister traversal
            -order          => 'ltr', # ltr = left-to-right, 'rtl' = right-to-left
 Comments: 

=cut

 #$tree->visit_depth_first(
 #	'-pre'            => sub { print "pre: ",            shift->get_name, "\n" },
 #	'-pre_daughter'   => sub { print "pre_daughter: ",   shift->get_name, "\n" },
 #	'-post_daughter'  => sub { print "post_daughter: ",  shift->get_name, "\n" },
 #	'-in'             => sub { print "in: ",             shift->get_name, "\n" },
 #	'-pre_sister'     => sub { print "pre_sister: ",     shift->get_name, "\n" },
 #	'-post_sister'    => sub { print "post_sister: ",    shift->get_name, "\n" },
 #	'-post'           => sub { print "post: ",           shift->get_name, "\n" },
 #	'-order'          => 'ltr',
 #);

	sub visit_depth_first {
		my $self = shift;
		my %args = looks_like_hash @_;

		if ( $args{'-order'} and $args{'-order'} =~ /^rtl$/i ) {
			$args{'-sister_method'}   = 'get_previous_sister';
			$args{'-daughter_method'} = 'get_last_daughter';
		}
		else {
			$args{'-sister_method'}   = 'get_next_sister';
			$args{'-daughter_method'} = 'get_first_daughter';
		}

		$self->_visit_depth_first(%args);
		return $self;
	}

	sub _visit_depth_first {
		my ( $node, %args ) = @_;
		my ( $daughter_method, $sister_method ) =
		  @args{qw(-daughter_method -sister_method)};

		$args{'-pre'}->($node) if $args{'-pre'};

		if ( my $daughter = $node->$daughter_method ) {
			$args{'-pre_daughter'}->($node) if $args{'-pre_daughter'};
			$daughter->_visit_depth_first(%args);
			$args{'-post_daughter'}->($node) if $args{'-post_daughter'};
		}
		else {
			$args{'-no_daughter'}->($node) if $args{'-no_daughter'};
		}

		$args{'-in'}->($node) if $args{'-in'};

		if ( my $sister = $node->$sister_method ) {
			$args{'-pre_sister'}->($node) if $args{'-pre_sister'};
			$sister->_visit_depth_first(%args);
			$args{'-post_sister'}->($node) if $args{'-post_sister'};
		}
		else {
			$args{'-no_sister'}->($node) if $args{'-no_sister'};
		}

		$args{'-post'}->($node) if $args{'-post'};
	}

=item visit_breadth_first()

Visits nodes breadth first

 Type    : Visitor method
 Title   : visit_breadth_first
 Usage   : $tree->visit_breadth_first( -pre => sub{ ... }, -post => sub { ... } );
 Function: Visits nodes in a breadth first traversal, executes handlers
 Returns : $tree
 Args    : Optional handlers in the order in which they would be executed on an internal node:
			
            # first event handler, is executed when node is reached in recursion
            -pre            => sub { print "pre: ",            shift->get_name, "\n" },
            
            # is executed if node has a sister, before sister is processed
            -pre_sister     => sub { print "pre_sister: ",     shift->get_name, "\n" }, 
            
            # is executed if node has a sister, after sister is processed
            -post_sister    => sub { print "post_sister: ",    shift->get_name, "\n" },         
            
            # is executed if node has no sister
            -no_sister      => sub { print "no_sister: ",      shift->get_name, "\n" },             
            
            # is executed whether or not node has sisters, if it does have sisters
            # they're processed first   
            -in             => sub { print "in: ",             shift->get_name, "\n" },         
            
            # is executed if node has a daughter, but before that daughter is processed
            -pre_daughter   => sub { print "pre_daughter: ",   shift->get_name, "\n" },
            
            # is executed if node has a daughter, after daughter has been processed 
            -post_daughter  => sub { print "post_daughter: ",  shift->get_name, "\n" },
            
            # is executed if node has no daughter
            -no_daughter    => sub { print "no_daughter: ",    shift->get_name, "\n" },                         
            
            # is executed last          
            -post           => sub { print "post: ",           shift->get_name, "\n" },
            
            # specifies traversal order, default 'ltr' means first_daugher -> next_sister
            # traversal, alternate value 'rtl' means last_daughter -> previous_sister traversal
            -order          => 'ltr', # ltr = left-to-right, 'rtl' = right-to-left
 Comments: 

=cut

	sub visit_breadth_first {
		my $self = shift;
		my %args = looks_like_hash @_;

		if ( $args{'-order'} and $args{'-order'} =~ /rtl/i ) {
			$args{'-sister_method'}   = 'get_previous_sister';
			$args{'-daughter_method'} = 'get_last_daughter';
		}
		else {
			$args{'-sister_method'}   = 'get_next_sister';
			$args{'-daughter_method'} = 'get_first_daughter';
		}

		$self->_visit_breadth_first(%args);
		return $self;
	}

	sub _visit_breadth_first {
		my ( $node, %args ) = @_;
		my ( $daughter_method, $sister_method ) =
		  @args{qw(-daughter_method -sister_method)};

		$args{'-pre'}->($node) if $args{'-pre'};

		if ( my $sister = $node->$sister_method ) {
			$args{'-pre_sister'}->($node) if $args{'-pre_sister'};
			$sister->_visit_breadth_first(%args);
			$args{'-post_sister'}->($node) if $args{'-post_sister'};
		}
		else {
			$args{'-no_sister'}->($node) if $args{'-no_sister'};
		}		

		$args{'-in'}->($node) if $args{'-in'};

		if ( my $daughter = $node->$daughter_method ) {
			$args{'-pre_daughter'}->($node) if $args{'-pre_daughter'};
			$daughter->_visit_breadth_first(%args);
			$args{'-post_daughter'}->($node) if $args{'-post_daughter'};
		}
		else {
			$args{'-no_daughter'}->($node) if $args{'-no_daughter'};
		}		

		$args{'-post'}->($node) if $args{'-post'};
	}

=item visit_level_order()

Visits nodes in a level order traversal.

 Type    : Visitor method
 Title   : visit_level_order
 Usage   : $tree->visit_level_order( sub{...} );
 Function: Visits nodes in a level order traversal, executes sub
 Returns : $tree
 Args    : A subroutine reference that operates on visited nodes.
 Comments:

=cut	

	sub visit_level_order {
		my ( $self, $sub ) = @_;
		if ( UNIVERSAL::isa( $sub, 'CODE' ) ) {
			my @queue = ($self);
			while (@queue) {
				my $node = shift @queue;
				$sub->($node);
				if ( my $children = $node->get_children ) {
					push @queue, @{$children};
				}
			}
		}
		else {
			throw 'BadArgs' => "'$sub' not a CODE reference";
		}
		return $self;
	}

=back

=head2 UTILITY METHODS

=over

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : Optional: a hash of code references to 
           override reflection-based getter/setter copying

           my $clone = $object->clone(  
               'set_forest' => sub {
                   my ( $self, $clone ) = @_;
                   for my $forest ( @{ $self->get_forests } ) {
                       $clone->set_forest( $forest );
                   }
               },
               'set_matrix' => sub {
                   my ( $self, $clone ) = @_;
                   for my $matrix ( @{ $self->get_matrices } ) {
                       $clone->set_matrix( $matrix );
                   }
           );

 Comments: Cloning is currently experimental, use with caution.
           It works on the assumption that the output of get_foo
           called on the invocant is to be provided as argument
           to set_foo on the clone - such as 
           $clone->set_name( $self->get_name ). Sometimes this 
           doesn't work, for example where this symmetry doesn't
           exist, or where the return value of get_foo isn't valid
           input for set_foo. If such a copy fails, a warning is 
           emitted. To make sure all relevant attributes are copied
           into the clone, additional code references can be 
           provided, as in the example above. Typically, this is
           done by overrides of this method in child classes.

=cut

	sub clone {
		my $self = shift;
		$logger->info("cloning $self");
		my %subs = @_;
			
		# we'll clone relatives in the tree, so no raw copying
		$subs{'set_parent'}          = sub {};
		$subs{'set_first_daughter'}  = sub {};
		$subs{'set_last_daughter'}   = sub {};
		$subs{'set_next_sister'}     = sub {};
		$subs{'set_previous_sister'} = sub {};
		$subs{'set_child'}           = sub {};
		$subs{'insert'}              = sub {};
		
		return $self->SUPER::clone(%subs);
	}

=back

=head2 SERIALIZERS

=over

=item to_json()

Serializes object to JSON string

 Type    : Serializer
 Title   : to_json()
 Usage   : print $obj->to_json();
 Function: Serializes object to JSON string
 Returns : String 
 Args    : None
 Comments:

=cut

    sub to_json {
        my $node = shift;
        my %args = @_;
        my $extra_attr = \%args;
        $extra_attr->{'get_branch_length'} = 'length';
        if ( my @children = @{ $node->get_children } ) {
            return '{' 
                . $node->_to_json( $extra_attr )
                . ',"children":['
                . ( join ',', map { $_->to_json } @children )
                . ']}';
        }
        else {
            return '{' . $node->_to_json($extra_attr) . '}';
        }
    }

=item to_xml()

Serializes invocant to xml.

 Type    : Serializer
 Title   : to_xml
 Usage   : my $xml = $obj->to_xml;
 Function: Turns the invocant object (and its descendants )into an XML string.
 Returns : SCALAR
 Args    : NONE

=cut

	sub to_xml {
		my $self = shift;
		my @nodes = ( $self, @{ $self->get_descendants } );
		my $xml = '';
		
		# first write out the node elements
		for my $node ( @nodes ) {
			if ( my $taxon = $node->get_taxon ) {
				$node->set_attributes( 'otu' => $taxon->get_xml_id );
			}
			if ( $node->is_root ) {
				$node->set_attributes( 'root' => 'true' );
			}
			$xml .= "\n" . $node->get_xml_tag(1);
			
		}
		
		# then the rootedge?
		if ( my $length = shift(@nodes)->get_branch_length ) {
			my $target = $self->get_xml_id;
			my $id = "edge" . $self->get_id;
			$xml .= "\n" . sprintf('<rootedge target="%s" id="%s" length="%s"/>', $target, $id, $length);
		}
		
		# then the subtended edges
		for my $node ( @nodes ) {
			my $source = $node->get_parent->get_xml_id;
			my $target = $node->get_xml_id;
			my $id     = "edge" . $node->get_id;
			my $length = $node->get_branch_length;
			if ( defined $length ) {
				$xml .= "\n" . sprintf('<edge source="%s" target="%s" id="%s" length="%s"/>', $source, $target, $id, $length);
			}
			else {
				$xml .= "\n" . sprintf('<edge source="%s" target="%s" id="%s"/>', $source, $target, $id);
			}
		}
		
		return $xml;		
	}

=item to_newick()

Serializes subtree subtended by invocant to newick string.

 Type    : Serializer
 Title   : to_newick
 Usage   : my $newick = $obj->to_newick;
 Function: Turns the invocant object into a newick string.
 Returns : SCALAR
 Args    : takes same arguments as Bio::Phylo::Unparsers::Newick
 Comments: takes same arguments as Bio::Phylo::Unparsers::Newick

=cut    

	{
		my ( $root_id, $string );
		#no warnings 'uninitialized';

		sub to_newick {
			my $node = shift;
			my %args = @_;
			$root_id = $node->get_id if not $root_id;
			my $blformat = '%f';

			# first create the name
			my $name;
			if ( $node->is_terminal or $args{'-nodelabels'} ) {
				if ( not $args{'-tipnames'} ) {
					$name = $node->get_name;
				}
				elsif ( $args{'-tipnames'} =~ /^internal$/i ) {
					$name = $node->get_internal_name;
				}
				elsif ( $args{'-tipnames'} =~ /^taxon/i and $node->get_taxon ) {
					if ( $args{'-tipnames'} =~ /^taxon_internal$/i ) {
						$name = $node->get_taxon->get_internal_name;
					}
					elsif ( $args{'-tipnames'} =~ /^taxon$/i ) {
						$name = $node->get_taxon->get_name;
					}
				}
				else {
					$name = $node->get_generic( $args{'-tipnames'} );
				}
				if ( $args{'-translate'}
					and exists $args{'-translate'}->{$name} )
				{
					$name = $args{'-translate'}->{$name};
				}
			}

			# now format branch length
			my $branch_length;
			if ( defined( $branch_length = $node->get_branch_length ) ) {
				if ( $args{'-blformat'} ) {
					$blformat = $args{'-blformat'};
				}
				$branch_length = sprintf $blformat, $branch_length;
			}

			# now format nhx
			my $nhx;
			if ( $args{'-nhxkeys'} ) {
				my $sep;
				if ( $args{'-nhxstyle'} =~ /^mesquite$/i ) {
					$sep = ',';
					$nhx = '[%';
				}
				else {
					$sep = ':';
					$nhx = '[&&NHX:';
				}
				my @nhx;
				for my $i ( 0 .. $#{ $args{'-nhxkeys'} } ) {
					my $key   = $args{'-nhxkeys'}->[$i];
					my $value = $node->get_generic($key);
					push @nhx, " $key = $value " if $value;
				}
				if (@nhx) {
					$nhx .= join $sep, @nhx;
					$nhx .= ']';
				}
				else {
					$nhx = '';
				}
			}

			# recurse further
			if ( my $first_daughter = $node->get_first_daughter ) {
				$string .= '(';
				$first_daughter->to_newick(%args);
			}

			# append to growing newick string
			$string .= ')'                  if $node->get_first_daughter;
			$string .= $name                if defined $name;
			$string .= ':' . $branch_length if defined $branch_length;
			$string .= $nhx                 if $nhx;
			if ( $root_id == $node->get_id ) {
				undef $root_id;
				my $result = $string . ';';
				undef $string;
				return $result;
			}

			# recurse further
			elsif ( my $next_sister = $node->get_next_sister ) {
				$string .= ',';
				$next_sister->to_newick(%args);
			}
		}
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
		my $id = $self->get_id;
		for my $field (@fields) {
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

	sub _type { $TYPE_CONSTANT }

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $node->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

	sub _container { $CONTAINER_CONSTANT }

=back

=cut

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:38 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Forest::Node inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Forest::Node also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::Taxa::TaxonLinker

Bio::Phylo::Forest::Node inherits from superclass L<Bio::Phylo::Taxa::TaxonLinker>. 
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

=head2 SUPERCLASS Bio::Phylo::Listable

Bio::Phylo::Forest::Node inherits from superclass L<Bio::Phylo::Listable>. 
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

Bio::Phylo::Forest::Node inherits from superclass L<Bio::Phylo::Util::XMLWritable>. 
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

Bio::Phylo::Forest::Node inherits from superclass L<Bio::Phylo>. 
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

=item L<Bio::Phylo::Taxa::TaxonLinker>

This object inherits from L<Bio::Phylo::Taxa::TaxonLinker>, so methods
defined there are also applicable here.

=item L<Bio::Phylo::Listable>

This object inherits from L<Bio::Phylo::Listable>, so methods
defined there are also applicable here.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: Node.pm 844 2009-03-05 00:07:26Z rvos $

=cut

}

1;

__DATA__

sub add_Descendent{
   my ( $self,$child ) = @_;
   $self->set_child( $child );
   return scalar @{ $self->get_children };
}

sub each_Descendent{
	my $self = shift;
	if ( my $children = $self->get_children ) {
		return @{ $children };
   	}
   	return;
}

sub get_all_Descendents{
	my $self = shift;
	if ( my $desc = $self->get_descendants ) {
		return @{ $desc };
	}
	return;
}

*get_Descendents = \&get_all_Descendents;

*is_Leaf = \&is_terminal;
*is_otu = \&is_terminal;

sub descendent_count{
	my $self = shift;
	my $count = 0;
	if ( my $desc = get_descendants ) {
		$count = scalar @{ $desc };
	}
	return $count;
}

sub height{ shift->calc_max_path_to_tips }

sub depth{ shift->calc_path_to_root }

sub branch_length{
	my $self = shift;
	if ( @_ ) {
		$self->set_branch_length(shift);
	}
	return $self->get_branch_length;
}

sub id {
    my $self = shift;
    if ( @_ ) {
    	$self->set_name(shift);
    }
    return $self->get_name;
}

sub internal_id { shift->get_id }

sub description {
	my $self = shift;
	if ( @_ ) {
		$self->set_desc(shift);
	}
	return $self->get_desc;
}

sub bootstrap {
	my ( $self, $bs ) = @_;
	if ( defined $bs && looks_like_number $bs ) {
		$self->set_score($bs);
	}
	return $self->get_score;
}

sub ancestor {
	my $self = shift;
	if ( @_ ) {
		$self->set_parent(shift);
	}
	return $self->get_parent;
}

sub invalidate_height { }

sub add_tag_value{
	my $self = shift;
	if ( @_ ) {
		my ( $key, $value ) = @_;
		$self->set_generic( $key, $value );
	}
	return 1;
}

sub remove_tag {
	my ( $self, $tag ) = @_;
	my %hash = %{ $self->get_generic };
	my $exists = exists $hash{$tag};
	delete $hash{$tag};
	$self->set_generic();
	$self->set_generic(%hash);
	return !!$exists;
}

sub remove_all_tags{ shift->set_generic() }

sub get_all_tags {
	my $self = shift;
	my %hash = %{ $self->get_generic };
	return keys %hash;
}

sub get_tag_values{
	my ( $self, $tag ) = @_;
	my $values = $self->get_generic($tag);
	return ref $values ? @{ $values } : $values;
}

sub has_tag{
	my ( $self, $tag ) = @_;
	my %hash = %{ $self->get_generic };
	return exists $hash{$tag};
}

sub id_output { shift->get_internal_name }
