# $Id: Forest.pm 844 2009-03-05 00:07:26Z rvos $
package Bio::Phylo::Forest;
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Taxa::TaxaLinker;
use Bio::Phylo::Util::CONSTANT qw(_NONE_ _FOREST_ _PROJECT_);
use Bio::Phylo::Util::Exceptions 'throw';
use Bio::Phylo::Factory;
use vars qw(@ISA);

=begin comment

This class has no internal state, no cleanup is necessary.

=end comment

=cut

# classic @ISA manipulation, not using 'base'
@ISA = qw(Bio::Phylo::Listable Bio::Phylo::Taxa::TaxaLinker);

{

	my $logger             = __PACKAGE__->get_logger;
	my $factory            = Bio::Phylo::Factory->new;
	my $CONSTANT_TYPE      = _FOREST_;
	my $CONTAINER_CONSTANT = _PROJECT_;

=head1 NAME

Bio::Phylo::Forest - Container for tree objects

=head1 SYNOPSIS

 use Bio::Phylo::Factory;
 my $fac = Bio::Phylo::Factory->new;
 my $forest = $fac->create_forest;
 my $tree = $fac->create_tree;
 $forest->insert($tree);
 print $forest->to_nexus;

=head1 DESCRIPTION

The Bio::Phylo::Forest object models a set of trees. The object subclasses the
L<Bio::Phylo::Listable> object, so look there for more methods available to
forest objects.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

Forest constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $trees = Bio::Phylo::Forest->new;
 Function: Instantiates a Bio::Phylo::Forest object.
 Returns : A Bio::Phylo::Forest object.
 Args    : None required, though see the superclass
           Bio::Phylo::Listable from which this
           object inherits.

=cut

	sub new {

		# could be child class
		my $class = shift;

		# notify user
		$logger->info("constructor called for '$class'");

		# recurse up inheritance tree, get ID
		my $self = $class->SUPER::new( '-tag' => 'trees', @_ );

		# local fields would be set here

		return $self;
	}

=back

=head1 METHODS

=over

=item insert()

Inserts trees in forest.

 Type    : Method
 Title   : insert
 Usage   : $trees->insert( $tree1, $tree2, ... );
 Function: Inserts trees in forest.
 Returns : A Bio::Phylo::Forest object.
 Args    : Trees
 Comment : The last seen tree that is set as default
           becomes the default for the entire forest

=cut

	sub insert {
		my $self = shift;
		if ( $self->can_contain(@_) ) {
			my $seen_default = 0;
			for my $tree ( reverse @_ ) {
				if ( $tree->is_default ) {
					if ( not $seen_default ) {
						$seen_default++;
					}
					else {
						$tree->set_not_default;
					}
				}
			}
			if ( $seen_default ) {
				if ( my $tree = $self->get_default_tree ) {
					$tree->set_not_default;
				}
			}
			$self->SUPER::insert(@_);
		}
		else {
			throw 'ObjectMismatch' => "Failed insertion: @_ [in $self]";
		}
	}

=item get_default_tree()

Gets the default tree in the forest.

 Type    : Method
 Title   : get_default_tree
 Usage   : my $tree = $trees->get_default_tree;
 Function: Gets the default tree in the forest.
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : None
 Comment : If no default tree has been set, 
           returns first tree. 

=cut

	sub get_default_tree {
		my $self = shift;
		my $first = $self->first;
		for my $tree ( @{ $self->get_entities } ) {
			return $tree if $tree->is_default;
		}
		return $first;
	}

=item check_taxa()

Validates taxon links of nodes in invocant's trees.

 Type    : Method
 Title   : check_taxa
 Usage   : $trees->check_taxa;
 Function: Validates the taxon links of the
           nodes of the trees in $trees
 Returns : A validated Bio::Phylo::Forest object.
 Args    : None

=cut

	sub check_taxa {
		my $self = shift;

		# is linked
		if ( my $taxa = $self->get_taxa ) {
			my %tips;
			for my $tip ( map { @{ $_->get_terminals } } @{ $self->get_entities } ) {
				my $name = $tip->get_internal_name;
				if ( not $tips{$name} ) {
					$tips{$name} = [];
				}
				push @{ $tips{$name} }, $tip;
			}
			my %taxa =
			  map { $_->get_internal_name => $_ } @{ $taxa->get_entities };
			for my $name ( keys %tips ) {
				$logger->debug("linking tip $name");
				if ( not exists $taxa{$name} ) {
					$logger->debug("no taxon object for $name yet, instantiating");
					$taxa->insert( $taxa{$name} = $factory->create_taxon( '-name' => $name ) );
				}
				for my $tip ( @{ $tips{$name} } ) {
					$tip->set_taxon( $taxa{$name} );
				}
			}
		}

		# not linked
		else {
			for my $tree ( @{ $self->get_entities } ) {
				for my $node ( @{ $tree->get_entities } ) {
					$node->set_taxon();
				}
			}
		}
		return $self;
	}

=item make_matrix()

Creates an MRP matrix object.

 Type    : Method
 Title   : make_matrix
 Usage   : my $matrix = $obj->make_matrix
 Function: Creates an MRP matrix object
 Returns : $matrix
 Args    : NONE

=cut

    sub make_matrix {
        my $self = shift;
        my $taxa = $self->make_taxa;
        my $matrix = $factory->create_matrix;
        $matrix->set_taxa( $taxa );
        my ( %data, @charlabels, @statelabels );
        for my $taxon ( @{ $taxa->get_entities } ) {
            my $datum = $factory->create_datum;
            $datum->set_taxon( $taxon );
            $datum->set_name( $taxon->get_name );
            $matrix->insert( $datum );
            $data{ $taxon->get_name } = [];
        }
        my $recursion = sub {
            my ( $node, $tree, $taxa, $method ) = @_;
            push @charlabels, $tree->get_internal_name;
            push @statelabels, [ 'outgroup', $node->get_internal_name ];
            my %tip_values = map { $_->get_name => 1 } @{ $node->get_terminals };
            for my $tipname ( map { $_->get_name } @{ $tree->get_terminals } ) {
                $tip_values{$tipname} = 0 if not exists $tip_values{$tipname};
            }
            for my $datumname ( keys %data ) {
                if ( exists $tip_values{$datumname} ) {
                    push @{ $data{$datumname} }, $tip_values{$datumname};
                }
                else {
                    push @{ $data{$datumname} }, '?';
                }
            }
            $method->( $_, $tree, $taxa, $method ) for grep { $_->is_internal } @{ $node->get_children };            
        };
        for my $tree ( @{ $self->get_entities } ) {
            $recursion->( $tree->get_root, $tree, $taxa, $recursion );
        }
        for my $datum ( @{ $matrix->get_entities } ) {
            $datum->set_char( $data{ $datum->get_name } );
        }
        $matrix->set_charlabels( \@charlabels );
        $matrix->set_statelabels( \@statelabels );
        return $matrix;
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
			for my $tree ( @{ $self->get_entities } ) {
				for my $tip ( @{ $tree->get_terminals } ) {
					my $name = $tip->get_internal_name;
					if ( not $taxa{$name} ) {
						$taxa{$name} = $factory->create_taxon( '-name' => $name );
					}
				}
			}
			$taxa->insert( map { $taxa{$_} } sort { $a cmp $b } keys %taxa );
			$self->set_taxa( $taxa );
			return $taxa;
		}
	}

=item to_newick()

Serializes invocant to newick string.

 Type    : Stringifier
 Title   : to_newick
 Usage   : my $string = $forest->to_newick;
 Function: Turns the invocant forest object 
           into a newick string, one line per tree
 Returns : SCALAR
 Args    : The same arguments as 
           Bio::Phylo::Forest::Tree::to_newick

=cut

    sub to_newick {
        my $self = shift;
        my $newick;
        for my $tree ( @{ $self->get_entities } ) {
            $newick .= $tree->to_newick(@_) . "\n";
        }
        return $newick;
    }

=item to_nexus()

Serializer to nexus format.

 Type    : Format convertor
 Title   : to_nexus
 Usage   : my $data_block = $matrix->to_nexus;
 Function: Converts matrix object into a nexus data block.
 Returns : Nexus data block (SCALAR).
 Args    : Trees can be formatted using the same arguments as those
           passed to Bio::Phylo::Unparsers::Newick. In addition, you
           can provide: 
           
           # as per mesquite's inter-block linking system (default is false):
           -links => 1 (to create a TITLE token, and a LINK token, if applicable)
           
           # rooting is determined based on basal trichotomy. "token" means 'TREE' or 'UTREE'
           # is used, "comment" means [&R] or [&U] is used, "nhx" means [%unrooted=on] or
           # [%unrooted=off] if used, default is "comment"
           -rooting => one of (token|comment|nhx)
           
           # to map taxon names to indices (default is false)
           -make_translate => 1 (autogenerate translation table, overrides -translate => {})
 Comments:

=cut

	sub to_nexus {
		my $self = shift;
		my %args = ( '-rooting' => 'comment', @_ );
		my %translate;
		my $nexus;

		# make translation table
		if ( $args{'-make_translate'} ) {
			my $i = 0;
			for my $tree ( @{ $self->get_entities } ) {
				for my $node ( @{ $tree->get_terminals } ) {
					my $name;
					if ( not $args{'-tipnames'} ) {
						$name = $node->get_name;
					}
					elsif ( $args{'-tipnames'} =~ /^internal$/i ) {
						$name = $node->get_internal_name;
					}
					elsif ( $args{'-tipnames'} =~ /^taxon/i
						and $node->get_taxon )
					{
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
					$translate{$name} = ( 1 + $i++ )
					  if not exists $translate{$name};
				}
			}
			$args{'-translate'} = \%translate;
		}

		# create header
		$nexus = "BEGIN TREES;\n";
		$nexus .=
		    "[! Trees block written by "
		  . ref($self) . " "
		  . $self->VERSION . " on "
		  . localtime() . " ]\n";
		if ( $args{'-links'} ) {
			delete $args{'-links'};
			$nexus .= "\tTITLE " . $self->get_internal_name . ";\n";
			if ( my $taxa = $self->get_taxa ) {
				$nexus .= "\tLINK TAXA=" . $taxa->get_internal_name . ";\n";
			}
		}

		# stringify translate table
		if ( $args{'-make_translate'} ) {
			delete $args{'-make_translate'};
			$nexus .= "\tTRANSLATE\n";
			my @translate;
			for ( keys %translate ) { $translate[ $translate{$_} - 1 ] = $_ }
			for my $i ( 0 .. $#translate ) {
				$nexus .= "\t\t" . ( $i + 1 ) . " " . $translate[$i];
				if ( $i == $#translate ) {
					$nexus .= ";\n";
				}
				else {
					$nexus .= ",\n";
				}
			}
		}

		# stringify trees
		for my $tree ( @{ $self->get_entities } ) {
			if ( $tree->is_rooted ) {
				if ( $args{'-rooting'} =~ /^token$/i ) {
					$nexus .= "\tTREE "
					  . $tree->get_internal_name . ' = '
					  . $tree->to_newick(%args) . "\n";
				}
				elsif ( $args{'-rooting'} =~ /^comment$/i ) {
					$nexus .= "\tTREE "
					  . $tree->get_internal_name
					  . ' = [&R] '
					  . $tree->to_newick(%args) . "\n";
				}
				elsif ( $args{'-rooting'} =~ /^nhx/i ) {
					$tree->get_root->set_generic( 'unrooted' => 'off' );
					if ( $args{'-nhxkeys'} ) {
						push @{ $args{'-nhxkeys'} }, 'unrooted';
					}
					else {
						$args{'-nhxkeys'} = ['unrooted'];
					}
					$nexus .= "\tTREE "
					  . $tree->get_internal_name . ' = '
					  . $tree->to_newick(%args) . "\n";
				}
			}
			else {
				if ( $args{'-rooting'} =~ /^token$/i ) {
					$nexus .= "\tUTREE "
					  . $tree->get_internal_name . ' = '
					  . $tree->to_newick(%args) . "\n";
				}
				elsif ( $args{'-rooting'} =~ /^comment$/i ) {
					$nexus .= "\tTREE "
					  . $tree->get_internal_name
					  . ' = [&U] '
					  . $tree->to_newick(%args) . "\n";
				}
				elsif ( $args{'-rooting'} =~ /^nhx/i ) {
					$tree->get_root->set_generic( 'unrooted' => 'on' );
					if ( $args{'-nhxkeys'} ) {
						push @{ $args{'-nhxkeys'} }, 'unrooted';
					}
					else {
						$args{'-nhxkeys'} = ['unrooted'];
					}
					$nexus .= "\tTREE "
					  . $tree->get_internal_name . ' = '
					  . $tree->to_newick(%args) . "\n";
				}
			}
		}

		# done!
		$nexus .= "END;\n";
		return $nexus;
	}

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $trees->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

	sub _container { $CONTAINER_CONSTANT }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $trees->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

	sub _type { $CONSTANT_TYPE }

=back

=cut

# podinherit_insert_token
# podinherit_start_token_do_not_remove
# AUTOGENERATED pod created by /Users/rvosa/Applications/podinherit on Wed Mar  4 17:13:21 2009
# DO NOT EDIT the code below, rerun /Users/rvosa/Applications/podinherit instead.

=pod

=head1 INHERITED METHODS

Bio::Phylo::Forest inherits from one or more superclasses. This means that objects of 
class Bio::Phylo::Forest also "do" the methods from the superclasses in addition to the 
ones implemented in this class. Below is the documentation for those additional 
methods, organized by superclass.

=head2 SUPERCLASS Bio::Phylo::Listable

Bio::Phylo::Forest inherits from superclass L<Bio::Phylo::Listable>. 
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
 Args    : NONE.
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

Bio::Phylo::Forest inherits from superclass L<Bio::Phylo::Util::XMLWritable>. 
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

Bio::Phylo::Forest inherits from superclass L<Bio::Phylo>. 
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

Bio::Phylo::Forest inherits from superclass L<Bio::Phylo::Taxa::TaxaLinker>. 
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

=item L<Bio::Phylo::Listable>

The forest object inherits from the L<Bio::Phylo::Listable>
object. The methods defined therein are applicable to forest objects.

=item L<Bio::Phylo::Taxa::TaxaLinker>

The forest object inherits from the L<Bio::Phylo::Taxa::TaxaLinker>
object. The methods defined therein are applicable to forest objects.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=back

=head1 REVISION

 $Id: Forest.pm 844 2009-03-05 00:07:26Z rvos $

=cut

}
1;
