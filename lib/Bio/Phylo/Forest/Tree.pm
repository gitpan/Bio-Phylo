# $Id: Tree.pm,v 1.22 2006/04/12 22:38:22 rvosa Exp $
# Subversion: $Rev: 177 $
package Bio::Phylo::Forest::Tree;
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Forest::Node;
use Bio::Phylo::IO qw(unparse);
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Util::CONSTANT qw(_TREE_ _FOREST_ INT_SCORE_TYPE DOUBLE_SCORE_TYPE NO_SCORE_TYPE);
use Scalar::Util qw(looks_like_number blessed);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA $HAS_BIOPERL_INTERFACE);
@ISA = qw(Bio::Phylo::Listable);

# test for interface
my $interface = 'Bio::Tree::TreeI';
eval "require $interface";
$HAS_BIOPERL_INTERFACE = 1 unless $@;

# aliasing for Bio::Tree::TreeI
if ( $HAS_BIOPERL_INTERFACE ) {
    push @ISA, 'Bio::Tree::TreeI';
    *get_nodes           = sub { return @{ $_[0]->get_entities } };
    *get_root_node       = sub { return $_[0]->get_root };
    *number_nodes        = sub { return scalar @{ $_[0]->get_entities } };
    *total_branch_length = sub { return $_[0]->calc_tree_length };
    *height              = sub { return $_[0]->calc_tree_height };
    *id                  = sub { return $_[0]->get_name };
    *score               = sub { $_[1] ? $_[0]->set_score($_[1])->get_score : $_[0]->get_score };
    *get_leaf_nodes      = sub { return @{ $_[0]->get_terminals } };
}

{

=head1 NAME

Bio::Phylo::Forest::Tree - The tree object.

=head1 SYNOPSIS

 # some way to get a tree
 use Bio::Phylo::IO;
 my $string = '((A,B),C);';
 my $forest = Bio::Phylo::IO->parse(
    -format => 'newick',
    -string => $string
 );
 my $tree = $forest->first;

 # do something:
 print $tree->calc_imbalance;

 # prints "1"

=head1 DESCRIPTION

The object models a phylogenetic tree, a container of
L<Bio::Phylo::Forest::Node> objects. The tree object
inherits from L<Bio::Phylo::Listable>, so look there
for more methods.

=head1 METHODS

=head2 CONSTRUCTORS

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $tree = Bio::Phylo::Forest::Tree->new;
 Function: Instantiates a Bio::Phylo::Forest::Tree object.
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : No required arguments.

=cut

    sub new {
        my $class = shift;
        my $self  = Bio::Phylo::Forest::Tree->SUPER::new(@_);
        bless $self, __PACKAGE__;
        return $self;
    }
    
=item new_from_bioperl()

 Type    : Constructor
 Title   : new_from_bioperl
 Usage   : my $tree = 
           Bio::Phylo::Forest::Tree->new_from_bioperl(
               $bptree           
           );
 Function: Instantiates a 
           Bio::Phylo::Forest::Tree object.
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : A tree that implements Bio::Tree::TreeI

=cut

    sub new_from_bioperl {
        my ( $class, $bptree ) = @_;
        my $self;
        if ( blessed $bptree && $bptree->isa('Bio::Tree::TreeI') ) {
            $self = Bio::Phylo::Forest::Tree->SUPER::new(@_);
            bless $self, $class;
            $self = $self->_recurse( $bptree->get_root_node );        
        }
        else {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => 'Not a bioperl tree!',
            );
        }
        return $self;
    }    
    
=begin comment

 Type    : Internal method
 Title   : _recurse
 Usage   : $tree->_recurse( $bpnode );
 Function: Traverses a bioperl tree, instantiates a Bio::Phylo::Forest::Node
           object for every Bio::Tree::NodeI object it encounters, copying
           the parent, sibling and child relationships.
 Returns : None (modifies invocant).
 Args    : A Bio::Tree::NodeI object.

=end comment

=cut    
    
    sub _recurse {
        my ( $self, $bpnode, $parent ) = @_;
        my $node = Bio::Phylo::Forest::Node->new_from_bioperl( $bpnode );
        if ( $parent ) {
            $parent->set_child( $node );
        }
        $self->insert( $node );
        foreach my $bpchild ( $bpnode->each_Descendent ) {
            $self->_recurse( $bpchild, $node );
        }
        return $self;    
    }

=begin comment

 Type    : Internal method
 Title   : _analyze
 Usage   : $tree->_analyze;
 Function: Traverses the tree, creates references to first_daughter,
           last_daughter, next_sister and previous_sister.
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : none.
 Comments: This method only looks at the parent, so theoretically
           one could mess around with the
           Bio::Phylo::Forest::Node::parent(Bio::Phylo::Forest::Node) method and
           subsequently call Bio::Phylo::Forest::Tree::_analyze to overwrite old
           (and wrong) child and sister references with new (and correct) ones.

=end comment

=cut

    sub _analyze {
        my $tree  = $_[0];
        my $nodes = $tree->get_entities;
        foreach ( @{$nodes} ) {
            $_->set_next_sister();
            $_->set_previous_sister();
            $_->set_first_daughter();
            $_->set_last_daughter();
        }
        my ( $i, $j, $first, $next );
    
        # mmmm... O(N^2)
      NODE: for $i ( 0 .. $#{$nodes} ) {
            $first = $nodes->[$i];
            for $j ( ( $i + 1 ) .. $#{$nodes} ) {
                $next = $nodes->[$j];
                my ( $firstp, $nextp ) = ( $first->get_parent, $next->get_parent );
                if ( $firstp && $nextp && $firstp == $nextp ) {
                    if ( !$first->get_next_sister ) {
                        $first->set_next_sister($next);
                    }
                    if ( !$next->get_previous_sister ) {
                        $next->set_previous_sister($first);
                    }
                    next NODE;
                }
            }
        }
    
        # O(N)
        foreach ( @{$nodes} ) {
            my $p = $_->get_parent;
            if ($p) {
                if ( !$_->get_next_sister ) {
                    $p->set_last_daughter($_);
                    next;
                }
                if ( !$_->get_previous_sister ) {
                    $p->set_first_daughter($_);
                }
            }
        }
        return $tree;
    }

=back

=head2 QUERIES

=over

=item get_terminals()

 Type    : Query
 Title   : get_terminals
 Usage   : my @terminals = @{ $tree->get_terminals };
 Function: Retrieves all terminal nodes in
           the Bio::Phylo::Forest::Tree object.
 Returns : An array reference of 
           Bio::Phylo::Forest::Node objects.
 Args    : NONE
 Comments: If the tree is valid, this method 
           retrieves the same set of nodes as 
           $node->get_terminals($root). However, 
           because there is no recursion it may 
           be faster. Also, the node method by 
           the same name does not see orphans.

=cut

    sub get_terminals {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my @terminals;
        foreach ( @{ $self->get_entities } ) {
            if ( $_->is_terminal ) {
                push @terminals, $_;
            }
        }
        $self->_store_cache(\@terminals);
        return \@terminals;
    }

=item get_internals()

 Type    : Query
 Title   : get_internals
 Usage   : my @internals = @{ $tree->get_internals };
 Function: Retrieves all internal nodes 
           in the Bio::Phylo::Forest::Tree object.
 Returns : An array reference of 
           Bio::Phylo::Forest::Node objects.
 Args    : NONE
 Comments: If the tree is valid, this method 
           retrieves the same set of nodes as 
           $node->get_internals($root). However, 
           because there is no recursion it may 
           be faster. Also, the node method by 
           the same name does not see orphans.

=cut

    sub get_internals {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my @internals;
        foreach ( @{ $self->get_entities } ) {
            if ( $_->is_internal ) {
                push @internals, $_;
            }
        }
        $self->_store_cache(\@internals);
        return \@internals;
    }

=item get_root()

 Type    : Query
 Title   : get_root
 Usage   : my $root = $tree->get_root;
 Function: Retrieves the first orphan in 
           the current Bio::Phylo::Forest::Tree
           object - which should be the root.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

    sub get_root {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        foreach ( @{ $self->get_entities } ) {
            if ( !$_->get_parent ) {
                $self->_store_cache($_);
                return $_;
            }
        }
        $self->_store_cache(undef);
        return;
    }

=item get_tallest_tip()

 Type    : Query
 Title   : get_tallest_tip
 Usage   : my $tip = $tree->get_tallest_tip;
 Function: Retrieves the node furthest from the
           root in the current Bio::Phylo::Forest::Tree
           object.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE
 Comments: This method assumes the invocant
           tree has branch lengths.

=cut

    sub get_tallest_tip {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];        
        my $height = 0;
        my $tip;
        foreach my $node ( @{ $self->get_terminals } ) {
            if ( $node->calc_path_to_root > $height ) {
                $height = $node->calc_path_to_root;
                $tip = $node;
            }
        }   
        $self->_store_cache($tip);
        return $tip;         
    }

=item get_mrca()

 Type    : Query
 Title   : get_mrca
 Usage   : my $mrca = $tree->get_mrca(\@nodes);
 Function: Retrieves the most recent 
           common ancestor of \@nodes
 Returns : Bio::Phylo::Forest::Node
 Args    : A reference to an array of 
           Bio::Phylo::Forest::Node objects 
           in $tree.

=cut

    sub get_mrca {
        my ( $tree, $nodes ) = @_;
        my $mrca;
        for my $i ( 1 .. $#{$nodes} ) {
            $mrca ? $mrca = $mrca->get_mrca( $nodes->[$i] ) : $mrca =
              $nodes->[0]->get_mrca( $nodes->[$i] );
        }
        return $mrca;
    }

=back

=head2 TESTS

=over

=item is_binary()

 Type    : Test
 Title   : is_binary
 Usage   : if ( $tree->is_binary ) {
              # do something
           }
 Function: Tests whether the invocant 
           object is bifurcating.
 Returns : BOOLEAN
 Args    : NONE

=cut

    sub is_binary {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        foreach ( @{ $self->get_internals } ) {
            if ( $_->get_first_daughter->get_next_sister != $_->get_last_daughter )
            {
                $self->_store_cache(undef);
                return;
            }
        }
        $self->_store_cache(1);
        return 1;
    }

=item is_ultrametric()

 Type    : Test
 Title   : is_ultrametric
 Usage   : if ( $tree->is_ultrametric(0.01) ) {
              # do something
           }
 Function: Tests whether the invocant is 
           ultrametric.
 Returns : BOOLEAN
 Args    : Optional margin between pairwise 
           comparisons (default = 0).
 Comments: The test is done by performing 
           all pairwise comparisons for
           root-to-tip path lengths. Since many 
           programs introduce rounding errors 
           in branch lengths the optional argument is
           available to test TRUE for nearly 
           ultrametric trees. For example, a value 
           of 0.01 indicates that no pairwise
           comparison may differ by more than 1%. 
           Note: behaviour is undefined for 
           negative branch lengths.

=cut

    sub is_ultrametric {
        my ( $tree, $margin ) = @_;
        if ( !$margin ) {
            $margin = 0;
        }
        my @paths;
        foreach ( @{ $tree->get_terminals } ) {
            push @paths, $_->calc_path_to_root;
        }
        for my $i ( 0 .. $#paths ) {
            for my $j ( ( $i + 1 ) .. $#paths ) {
                my $diff;
                if ( $paths[$i] < $paths[$j] ) {
                    $diff = $paths[$i] / $paths[$j];
                }
                else {
                    if ( $paths[$i] ) {
                        $diff = $paths[$j] / $paths[$i];
                    }
                }
                if ( $diff && ( 1 - $diff ) > $margin ) {
                    return;
                }
            }
        }
        return 1;
    }

=item is_monophyletic()

 Type    : Test
 Title   : is_monophyletic
 Usage   : if ( $tree->is_monophyletic(\@tips, $node) ) {
              # do something
           }
 Function: Tests whether the set of \@tips is
           monophyletic w.r.t. $outgroup.
 Returns : BOOLEAN
 Args    : A reference to a list of nodes, and a node.
 Comments: This method is essentially the
           same as 
           &Bio::Phylo::Forest::Node::is_outgroup_of.

=cut

    sub is_monophyletic {
        my ( $tree, $nodes, $outgroup ) = @_;
        for my $i ( 0 .. $#{$nodes} ) {
            for my $j ( ( $i + 1 ) .. $#{$nodes} ) {
                my $mrca = $nodes->[$i]->get_mrca( $nodes->[$j] );
                return if $mrca->is_ancestor_of($outgroup);
            }
        }
        return 1;
    }

=item is_clade()

 Type    : Test
 Title   : is_clade
 Usage   : if ( $tree->is_clade(\@tips) ) {
              # do something
           }
 Function: Tests whether the set of 
           \@tips forms a clade
 Returns : BOOLEAN
 Args    : A reference to an array of 
           Bio::Phylo::Forest::Node objects.
 Comments:

=cut

    sub is_clade {
        my ( $tree, $tips ) = @_;
        my $mrca;
        for my $i ( 1 .. $#{$tips} ) {
            $mrca ? $mrca = $mrca->get_mrca( $tips->[$i] ) : $mrca =
              $tips->[0]->get_mrca( $tips->[$i] );
        }
        scalar @{ $mrca->get_terminals } == scalar @{$tips} ? return 1 : return;
    }

=back

=head2 CALCULATIONS

=over

=item calc_tree_length()

 Type    : Calculation
 Title   : calc_tree_length
 Usage   : my $tree_length = 
           $tree->calc_tree_length;
 Function: Calculates the sum of all branch 
           lengths (i.e. the tree length).
 Returns : FLOAT
 Args    : NONE

=cut

    sub calc_tree_length {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $tl = 0;
        foreach ( @{ $self->get_entities } ) {
            if ( my $bl = $_->get_branch_length ) {
                $tl += $bl if defined $bl;
            }
        }
        $self->_store_cache($tl);
        return $tl;
    }

=item calc_tree_height()

 Type    : Calculation
 Title   : calc_tree_height
 Usage   : my $tree_height = 
           $tree->calc_tree_height;
 Function: Calculates the height 
           of the tree.
 Returns : FLOAT
 Args    : NONE
 Comments: For ultrametric trees this 
           method returns the height, but 
           this is done by averaging over 
           all root-to-tip path lengths, so 
           for additive trees the result 
           should consequently be interpreted
           differently.

=cut

    sub calc_tree_height {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $th = $self->calc_total_paths / $self->calc_number_of_terminals;
        $self->_store_cache($th);
        return $th;
    }

=item calc_number_of_nodes()

 Type    : Calculation
 Title   : calc_number_of_nodes
 Usage   : my $number_of_nodes = 
           $tree->calc_number_of_nodes;
 Function: Calculates the number of 
           nodes (internals AND terminals).
 Returns : INT
 Args    : NONE

=cut

    sub calc_number_of_nodes {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $numnodes = scalar @{ $self->get_entities };
        $self->_store_cache($numnodes);
        return $numnodes;
    }

=item calc_number_of_terminals()

 Type    : Calculation
 Title   : calc_number_of_terminals
 Usage   : my $number_of_terminals = 
           $tree->calc_number_of_terminals;
 Function: Calculates the number 
           of terminal nodes.
 Returns : INT
 Args    : NONE

=cut

    sub calc_number_of_terminals {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $numterm = scalar @{ $self->get_terminals };
        $self->_store_cache($numterm);
        return $numterm;
    }

=item calc_number_of_internals()

 Type    : Calculation
 Title   : calc_number_of_internals
 Usage   : my $number_of_internals = 
           $tree->calc_number_of_internals;
 Function: Calculates the number 
           of internal nodes.
 Returns : INT
 Args    : NONE

=cut

    sub calc_number_of_internals {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $numint = scalar @{ $self->get_internals };
        $self->_store_cache($numint);
        return $numint;
    }

=item calc_total_paths()

 Type    : Calculation
 Title   : calc_total_paths
 Usage   : my $total_paths = 
           $tree->calc_total_paths;
 Function: Calculates the sum of all 
           root-to-tip path lengths.
 Returns : FLOAT
 Args    : NONE

=cut

    sub calc_total_paths {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $tp = 0;
        foreach ( @{ $self->get_terminals } ) {
            $tp += $_->calc_path_to_root;
        }
        $self->_store_cache($tp);
        return $tp;
    }

=item calc_redundancy()

 Type    : Calculation
 Title   : calc_redundancy
 Usage   : my $redundancy = 
           $tree->calc_redundancy;
 Function: Calculates the amount of shared 
           (redundant) history on the total.
 Returns : FLOAT
 Args    : NONE
 Comments: Redundancy is calculated as
 1 / ( treelength - height / ( ntax * height - height ) )

=cut

    sub calc_redundancy {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $tl   = $self->calc_tree_length;
        my $th   = $self->calc_tree_height;
        my $ntax = $self->calc_number_of_terminals;
        my $red  = 1 - ( ( $tl - $th ) / ( ( $th * $ntax ) - $th ) );
        $self->_store_cache($red);
        return $red;
    }

=item calc_imbalance()

 Type    : Calculation
 Title   : calc_imbalance
 Usage   : my $imbalance = $tree->calc_imbalance;
 Function: Calculates Colless' coefficient 
           of tree imbalance.
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Colless, D.H., 1982. 
           The theory and practice of phylogenetic 
           systematics. Systematic Zoology 31(1): 100-104

=cut

    sub calc_imbalance {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my ( $maxic, $sum, $Ic ) = ( 0, 0 );
        if ( !$self->is_binary ) {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => 'Colless\' imbalance only possible for binary trees'
            );
        }
        my $numtips = $self->calc_number_of_terminals;
        $numtips -= 2;
        while ($numtips) {
            $maxic += $numtips;
            $numtips--;
        }
        foreach my $node ( @{ $self->get_internals } ) {
            my ( $fd, $ld, $ftips, $ltips ) =
              ( $node->get_first_daughter, $node->get_last_daughter, 0, 0 );
            if ( $fd->is_internal ) {
                foreach ( @{ $fd->get_descendants } ) {
                    if ( $_->is_terminal ) { $ftips++; }
                    else { next; }
                }
            }
            else { $ftips = 1; }
            if ( $ld->is_internal ) {
                foreach ( @{ $ld->get_descendants } ) {
                    if ( $_->is_terminal ) { $ltips++; }
                    else { next; }
                }
            }
            else { $ltips = 1; }
            $sum += abs( $ftips - $ltips );
        }
        $Ic = $sum / $maxic;
        $self->_store_cache($Ic);
        return $Ic;
    }

=item calc_i2()

 Type    : Calculation
 Title   : calc_i2
 Usage   : my $ci2 = $tree->calc_i2;
 Function: Calculates I2 imbalance.
 Returns : FLOAT
 Args    : NONE
 Comments:

=cut

    sub calc_i2 {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my ( $maxic, $sum, $I2 ) = ( 0, 0 );
        if ( !$self->is_binary ) {
            Bio::Phylo::Exceptions::ObjectMismatch->throw(
                error => 'I2 imbalance only possible for binary trees'
            );
        }
        my $numtips = $self->calc_number_of_terminals;
        $numtips -= 2;
        while ( $numtips ) {
            $maxic += $numtips;
            $numtips--;
        }
        foreach my $node ( @{ $self->get_internals } ) {
            my ( $fd, $ld, $ftips, $ltips ) =
              ( $node->get_first_daughter, $node->get_last_daughter, 0, 0 );
            if ( $fd->is_internal ) {
                foreach ( @{ $fd->get_descendants } ) {
                    if ( $_->is_terminal ) {
                        $ftips++;
                    }
                    else {
                        next;
                    }
                }
            }
            else {
                $ftips = 1;
            }
            if ( $ld->is_internal ) {
                foreach ( @{ $ld->get_descendants } ) {
                    if ( $_->is_terminal ) {
                        $ltips++;
                    }
                    else {
                        next;
                    }
                }
            }
            else {
                $ltips = 1;
            }
            next unless ( $ftips + $ltips - 2 );
            $sum += abs( $ftips - $ltips ) / abs( $ftips + $ltips - 2 );
        }
        $I2 = $sum / $maxic;
        $self->_store_cache($I2);
        return $I2;
    }

=item calc_gamma()

 Type    : Calculation
 Title   : calc_gamma
 Usage   : my $gamma = $tree->calc_gamma();
 Function: Calculates the Pybus gamma statistic
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Pybus, O.G. and 
           Harvey, P.H., 2000. Testing
           macro-evolutionary models using 
           incomplete molecular phylogenies. 
           Proc. R. Soc. Lond. B 267, 2267-2272

=cut

    # code due to Aki Mimoto
    sub calc_gamma {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $tl        = $self->calc_tree_length;
        my $terminals = $self->get_terminals;
        my $n         = scalar @{ $terminals };
        my $height    = $self->calc_tree_height;
    
        # Calculate the distance of each node to the root
        my %soft_refs;
        my $root      = $self->get_root;
        $soft_refs{$root} = 0;
        my @nodes     = $root;
        while ( @nodes ) {
            my $node = shift @nodes;
            my $path_len  = $soft_refs{$node} += $node->get_branch_length;
            my $children  = $node->get_children or next;
            for my $child ( @$children ) {
                $soft_refs{$child} = $path_len;
            }
            push @nodes, @{ $children };
        }
    
        # Then, we know how far each node is from the root. At this point, we
        # can sort through and create the @g array
        my %node_spread  = map {($_=>1)} values %soft_refs; # remove duplicates
        my @sorted_nodes = sort {$a<=>$b} keys %node_spread;
        my $prev         = 0;
        my @g;
        for my $length ( @sorted_nodes ) {
            push @g, $length - $prev;
            $prev = $length;
        }
    
        my $sum = 0;
        eval "require Math::BigFloat";
        if ( $@ ) { # BigFloat is not available.
            for ( my $i = 2; $i < $n; $i++ ) {
                for ( my $k = 2; $k <= $i; $k++ ) {
                    $sum += $k * $g[$k-1];
                }
            }
            my $numerator   = ($sum/($n-2))- ($tl/2);
            my $denominator = $tl*sqrt(1/(12*($n-2)));

            $self->_store_cache($numerator/$denominator);
            return $numerator/$denominator;
        }
    
        # Big Float is available. We'll use it then
        $sum = Math::BigFloat->new(0);
        for ( my $i = 2; $i < $n; $i++ ) {
            for ( my $k = 2; $k <= $i; $k++ ) {
                $sum->badd($k * $g[$k-1]);
            }
        }
        $sum->bdiv( $n - 2 );
        $sum->bsub( $tl / 2 );
        my $denominator = Math::BigFloat->new( 1 );
        $denominator->bdiv( 12 * ( $n - 2 ) );
        $denominator->bsqrt();
        $sum->bdiv( $denominator * $tl );
        $self->_store_cache($sum);
        return $sum;
    }

=item calc_fiala_stemminess()

 Type    : Calculation
 Title   : calc_fiala_stemminess
 Usage   : my $fiala_stemminess = 
           $tree->calc_fiala_stemminess;
 Function: Calculates stemminess measure 
           Fiala and Sokal (1985).
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Fiala, K.L. and 
           R.R. Sokal, 1985. Factors 
           determining the accuracy of 
           cladogram estimation: evaluation 
           using computer simulation. 
           Evolution, 39: 609-622

=cut

    sub calc_fiala_stemminess {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my @internals = @{ $self->get_internals };
        my $total     = 0;
        my $nnodes    = ( scalar @internals - 1 );
        foreach my $node (@internals) {
            if ( $node->get_parent ) {
                my $desclengths = $node->get_branch_length;
                my @children    = @{ $node->get_descendants };
                foreach my $child (@children) {
                    $desclengths += $child->get_branch_length;
                }
                $total += ( $node->get_branch_length / $desclengths );
            }
        }
        $total /= $nnodes;
        $self->_store_cache($total);
        return $total;
    }

=item calc_rohlf_stemminess()

 Type    : Calculation
 Title   : calc_rohlf_stemminess
 Usage   : my $rohlf_stemminess = 
           $tree->calc_rohlf_stemminess;
 Function: Calculates stemminess measure 
           from Rohlf et al. (1990).
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Rohlf, F.J., 
           W.S. Chang, R.R. Sokal, J. Kim, 
           1990. Accuracy of estimated 
           phylogenies: effects of tree 
           topology and evolutionary model. 
           Evolution, 44(6): 1671-1684

=cut

    sub calc_rohlf_stemminess {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        if ( !$self->is_ultrametric(0.01) ) {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => 'Rohlf stemminess only possible for ultrametric trees' );
        }
        my @internals            = @{ $self->get_internals };
        my $total                = 0;
        my $one_over_t_minus_two = 1 / ( scalar @internals - 1 );
        foreach my $node (@internals) {
            if ( $node->get_parent ) {
                my $Wj_i   = $node->get_branch_length;
                my $parent = $node->get_parent;
                my $hj     = $parent->calc_min_path_to_tips;
                if ( !$hj ) {
                    next;
                }
                $total += ( $Wj_i / $hj );
            }
        }
        unless ($total) {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => 'it looks like all branches were of length zero' );
        }
        my $crs = $one_over_t_minus_two * $total;
        $self->_store_cache($crs);
        return $crs;
    }

=item calc_resolution()

 Type    : Calculation
 Title   : calc_resolution
 Usage   : my $resolution = 
           $tree->calc_resolution;
 Function: Calculates the total number 
           of internal nodes over the
           total number of internal nodes 
           on a fully bifurcating
           tree of the same size.
 Returns : FLOAT
 Args    : NONE

=cut

    sub calc_resolution {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $res = $self->calc_number_of_internals /
          ( $self->calc_number_of_terminals - 1 );
        $self->_store_cache($res);
        return $res;
    }

=item calc_branching_times()

 Type    : Calculation
 Title   : calc_branching_times
 Usage   : my $branching_times = 
           $tree->calc_branching_times;
 Function: Returns a two-dimensional array. 
           The first dimension consists of 
           the "records", so that in the 
           second dimension $AoA[$first][0] 
           contains the internal node references, 
           and $AoA[$first][1] the branching 
           time of the internal node. The 
           records are orderered from root to 
           tips by time from the origin.
 Returns : SCALAR[][] or FALSE
 Args    : NONE

=cut

    sub calc_branching_times {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my @branching_times;
        if ( !$self->is_ultrametric(0.01) ) {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => 'tree isn\'t ultrametric, results would be meaningless' );
        }
        else {
            my ( $i, @temp ) = 0;
            foreach ( @{ $self->get_internals } ) {
                $temp[$i] = [ $_, $_->calc_path_to_root ];
                $i++;
            }
            @branching_times = sort { $a->[1] <=> $b->[1] } @temp;
        }
        $self->_store_cache(\@branching_times);
        return \@branching_times;
    }

=item calc_ltt()

 Type    : Calculation
 Title   : calc_ltt
 Usage   : my $ltt = $tree->calc_ltt;
 Function: Returns a two-dimensional array. 
           The first dimension consists of the 
           "records", so that in the second 
           dimension $AoA[$first][0] contains 
           the internal node references, and
           $AoA[$first][1] the branching time 
           of the internal node, and $AoA[$first][2] 
           the cumulative number of lineages over
           time. The records are orderered from 
           root to tips by time from the origin.
 Returns : SCALAR[][] or FALSE
 Args    : NONE

=cut

    sub calc_ltt {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        if ( !$self->is_ultrametric(0.01) ) {
            Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                error => 'tree isn\'t ultrametric, results are meaningless' );
        }
        my $ltt      = ( $self->calc_branching_times );
        my $lineages = 1;
        for my $i ( 0 .. $#{$ltt} ) {
            $lineages += ( scalar @{ $ltt->[$i][0]->get_children } - 1 );
            $ltt->[$i][2] = $lineages;
        }
        $self->_store_cache($ltt);
        return $ltt;
    }

=item calc_symdiff()

 Type    : Calculation
 Title   : calc_symdiff
 Usage   : my $symdiff = 
           $tree->calc_symdiff($other_tree);
 Function: Returns the symmetric difference 
           metric between $tree and $other_tree, 
           sensu Penny and Hendy, 1985.
 Returns : SCALAR
 Args    : A Bio::Phylo::Forest::Tree object
 Comments: Trees in comparison must span 
           the same set of terminal taxa
           or results are meaningless.

=cut

    sub calc_symdiff {
        my ( $tree, $other_tree ) = @_;
        my ( $symdiff, @clades1, @clades2 ) = (0);
        foreach my $node ( @{ $tree->get_internals } ) {
            my $tips = join ' ',
              sort { $a cmp $b } map { $_->get_name } @{ $node->get_terminals };
            push @clades1, $tips;
        }
        foreach my $node ( @{ $other_tree->get_internals } ) {
            my $tips = join ' ',
              sort { $a cmp $b } map { $_->get_name } @{ $node->get_terminals };
            push @clades2, $tips;
        }
      OUTER: foreach my $outer (@clades1) {
            foreach my $inner (@clades2) {
                next OUTER if $outer eq $inner;
            }
            $symdiff++;
        }
      OUTER: foreach my $outer (@clades2) {
            foreach my $inner (@clades1) {
                next OUTER if $outer eq $inner;
            }
            $symdiff++;
        }
        return $symdiff;
    }

=item calc_fp() 

 Type    : Calculation
 Title   : calc_fp
 Usage   : my $fp = $tree->calc_fp();
 Function: Returns the Fair Proportion 
           value for each terminal
 Returns : HASHREF
 Args    : NONE

=cut

    # code due to Aki Mimoto
    sub calc_fp {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        
        # First establish how many children sit on each of the nodes
        my %weak_ref; 
        my $terminals = $self->get_terminals;
        for my $terminal ( @$terminals ) {
            my $index = $terminal;
            do { $weak_ref{$index}++ }
            while ( $index = $index->get_parent );
        }
    
        # Then, assign each terminal a value
        my $fp = {};
    
        for my $terminal ( @$terminals ) {
            my $name  = $terminal->get_name;
            my $fpi   = 0;
            do {
                $fpi += ( $terminal->get_branch_length || 0 ) / $weak_ref{$terminal};
            } while ( $terminal = $terminal->get_parent );
            $fp->{$name} = $fpi;
        }
        $self->_store_cache($fp);
        return $fp;
    }

=item calc_es() 

 Type    : Calculation
 Title   : calc_es
 Usage   : my $es = $tree->calc_es();
 Function: Returns the Equal Splits value for each terminal
 Returns : HASHREF
 Args    : NONE

=cut

    # code due to Aki Mimoto
    sub calc_es {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
    
        # First establish how many children sit on each of the nodes
        my $terminals = $self->get_terminals;
    
        my $es = {};
        for my $terminal ( @{ $terminals } ) {
            my $name    = $terminal->get_name;
            my $esi     = 0;
            my $divisor = 1;
            do {
                my $length   = $terminal->get_branch_length || 0;
                my $children = $terminal->get_children || [];
                $divisor     *= @$children || 1;
                $esi         += $length / $divisor;
            } while ( $terminal = $terminal->get_parent );
            $es->{$name} = $esi;
        }

        $self->_store_cache($es);
        return $es;
    }

=item calc_pe()

 Type    : Calculation
 Title   : calc_pe
 Usage   : my $es = $tree->calc_pe();
 Function: Returns the Pendant Edge value for each terminal
 Returns : HASHREF
 Args    : NONE

=cut

    # code due to Aki Mimoto
    sub calc_pe {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $terminals = $self->get_terminals or return {};
        my $pe = { map { $_->get_name => $_->get_branch_length } @{ $terminals } };
        $self->_store_cache($pe);
        return $pe;
    }

=item calc_shapley()

 Type    : Calculation
 Title   : calc_shapley
 Usage   : my $es = $tree->calc_shapley();
 Function: Returns the Shapley value for each terminal
 Returns : HASHREF
 Args    : NONE

=cut

    # code due to Aki Mimoto
    sub calc_shapley {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
    
        # First find out how many tips are at the ends of each edge.
        my $terminals   = $self->get_terminals or return;  # nothing to see!
        my $edge_lookup = {};
        my $index       = $terminals->[0];
    
        # Iterate through the edges and find out which side each terminal reside
        _calc_shapley_traverse( $index, undef, $edge_lookup, 'root' );
    
        # At this point, it's possible to create the calculation matrix
        my $n = @$terminals;
        my @m;
        my $edges = [keys %$edge_lookup];
        for my $e ( 0..$#$edges ) {
            my $edge = $edges->[$e];
            my $el = $edge_lookup->{$edge}; # Lookup for terminals on one edge side
            my $v  = keys %{$el->{terminals}}; # Number of elements on one side of the edge
            for my $l ( 0..$#$terminals ) {
                my $terminal = $terminals->[$l];
                my $name     = $terminal->get_name;
                if ( $el->{terminals}{$name} ) {
                    $m[$l][$e] = ( $n - $v ) / ( $n * $v );
                }
                else {
                    $m[$l][$e] = $v / ( $n * ( $n - $v ) );
                }
            }
        }
    
        # Now we can calculate through the matrix
        my $shapley = {};
        for my $l ( 0..$#$terminals) {
            my $terminal = $terminals->[$l];
            my $name = $terminal->get_name;
            for my $e ( 0..$#$edges ) {
                my $edge = $edge_lookup->{$edges->[$e]};
                $shapley->{$name} += $edge->{branch_length} * $m[$l][$e];
            }
        }
        
        $self->_store_cache($shapley);
        return $shapley;
    }

    sub _calc_shapley_traverse {
        # This does a depth first traversal to assign the terminals
        # to the outgoing side of each branch. 
        my ( $index, $previous, $edge_lookup, $direction ) = @_;
        return unless $index;
        $previous ||= '';
    
        # Is this element a root?  
        my $is_root = !$index->get_parent;
    
        # Now assemble all the terminal datapoints and use the soft reference
        # to keep track of which end the terminals are attached
        my @core_terminals;
        if ( $previous and $index->is_terminal ) {
            push @core_terminals, $index->get_name;
        }
        my $parent = $index->get_parent || '';
        my @child_terminals;
        my $child_nodes = $index->get_children || [];
        for my $child ( @$child_nodes ) {
            next unless $child ne $previous;
            push @child_terminals, _calc_shapley_traverse( $child, $index, $edge_lookup, 'tip' );
        }
        my @parent_terminals;
        if ( $parent ne $previous ) {
            push @parent_terminals, _calc_shapley_traverse( $parent, $index, $edge_lookup, 'root' );
        }
    
        # We're going to toss the root node and we need to merge the root's child branches
        unless ( $is_root ) {
            $edge_lookup->{$index} = {
                branch_length => $index->get_branch_length,
                terminals     => {
                    map {$_=>1} 
                        @core_terminals,
                        $direction eq 'root' ? @parent_terminals : @child_terminals
                }
            };
        }
    
        return ( @core_terminals, @child_terminals, @parent_terminals );
    }

=back

=head2 TREE MANIPULATION

=over

=item ultrametricize()

 Type    : Tree manipulator
 Title   : ultrametricize
 Usage   : $tree->ultrametricize;
 Function: Sets all root-to-tip path 
           lengths equal by stretching
           all terminal branches to the 
           height of the tallest node.
 Returns : The modified invocant.
 Args    : NONE
 Comments: This method is analogous to 
           the 'ultrametricize' command
           in Mesquite, i.e. no rate smoothing 
           or anything like that happens, just 
           a lengthening of terminal branches.

=cut

    sub ultrametricize {
        my $tree    = shift;
        my $tallest = 0;
        $tree->_flush_cache;
        foreach ( @{ $tree->get_terminals } ) {
            my $path_to_root = $_->calc_path_to_root;
            if ( $path_to_root > $tallest ) {
                $tallest = $path_to_root;
            }
        }
        foreach ( @{ $tree->get_terminals } ) {
            my $newbl =
              $_->get_branch_length + ( $tallest - $_->calc_path_to_root );
            $_->set_branch_length($newbl);
        }
        return $tree;
    }

=item scale()

 Type    : Tree manipulator
 Title   : scale
 Usage   : $tree->scale($height);
 Function: Scales the tree to the 
           specified height.
 Returns : The modified invocant.
 Args    : $height = a numerical value 
           indicating root-to-tip path length.
 Comments: This method uses the 
           $tree->calc_tree_height method, and 
           so for additive trees the *average* 
           root-to-tip path length is scaled to
           $height (i.e. some nodes might be 
           taller than $height, others shorter).

=cut

    sub scale {
        my ( $tree, $target_height ) = @_;
        $tree->_flush_cache;
        my $current_height = $tree->calc_tree_height;
        my $scaling_factor = $target_height / $current_height;
        foreach ( @{ $tree->get_entities } ) {
            my $bl = $_->get_branch_length;
            if ($bl) {
                my $new_branch_length = $bl * $scaling_factor;
                $_->set_branch_length($new_branch_length);
            }
        }
        return $tree;
    }

=item resolve()

 Type    : Tree manipulator
 Title   : resolve
 Usage   : $tree->resolve;
 Function: Breaks polytomies by inserting 
           additional internal nodes 
           orderered from left to right.
 Returns : The modified invocant.
 Args    :
 Comments:

=cut

    sub resolve {
        my $tree = $_[0];
        $tree->_flush_cache;        
        foreach my $node ( @{ $tree->get_entities } ) {
            if (   $node->is_internal
                && $node->get_first_daughter->get_next_sister !=
                $node->get_last_daughter )
            {
                my $i = 1;
                while ( $node->get_first_daughter->get_next_sister !=
                    $node->get_last_daughter )
                {
                    my $newnode = new Bio::Phylo::Forest::Node;
                    $newnode->set_branch_length(0.00);
                    $newnode->set_name( $node->get_name . 'r' . $i++ );
    
                    # parent relationships
                    $newnode->set_parent($node);
                    $node->get_first_daughter->set_parent($newnode);
                    $node->get_first_daughter->get_next_sister->set_parent(
                        $newnode);
    
                    # daughter relationships
                    $newnode->set_first_daughter( $node->get_first_daughter );
                    $newnode->set_last_daughter(
                        $node->get_first_daughter->get_next_sister );
                    $node->set_first_daughter($newnode);
    
                    # sister relationships
                    $newnode->set_next_sister(
                        $newnode->get_first_daughter->get_next_sister
                          ->get_next_sister );
                    $newnode->get_first_daughter->get_next_sister->get_next_sister
                      ->set_previous_sister($newnode);
                    $newnode->get_first_daughter->get_next_sister->set_next_sister(
                    );
                    $tree->insert($newnode);
                }
            }
        }
        return $tree;
    }

=item prune_tips()

 Type    : Tree manipulator
 Title   : prune_tips
 Usage   : $tree->prune_tips(\@taxa);
 Function: Prunes specified taxa from invocant.
 Returns : A pruned Bio::Phylo::Forest::Tree object.
 Args    : A reference to an array of taxon names.
 Comments:

=cut

    sub prune_tips {
        my ( $self, $tips ) = @_;
        $self->_flush_cache;        
        my $tree = $self->get_entities;
      OUTER: for ( my $i = 0 ; $i <= $#{$tree} ; $i++ ) {
            if ( !defined $tree->[$i] ) {
                next OUTER;
            }
          INNER: foreach my $tip ( @{$tips} ) {
                if ( !defined $tree->[$i] ) {
                    last INNER;
                }
                if ( $tree->[$i]->get_name eq $tip && $tree->[$i]->is_terminal ) {
    
                    # scope out nodes that reference current
                    my $ps = $tree->[$i]->get_previous_sister;
                    my $ns = $tree->[$i]->get_next_sister;
                    my $p  = $tree->[$i]->get_parent;
    
                    # parent is polytomy
                    if ( $p && scalar @{ $p->get_children } > 2 ) {
                        if ( $p->get_first_daughter == $tree->[$i] ) {
                            $p->set_first_daughter($ns);
                            $ns->set_previous_sister();
                        }
                        elsif ( $p->get_last_daughter == $tree->[$i] ) {
                            $p->set_last_daughter($ps);
                            $ps->set_next_sister();
                        }
                        else {
                            $ps->set_next_sister($ns);
                            $ns->set_previous_sister($ps);
                        }
                        $tree->[$i] = undef;
                        next OUTER;
                    }
    
                    # parent bifurcates, has parent
                    my $gp = $p->get_parent;
                    if ( $p && scalar @{ $p->get_children } <= 2 && $gp ) {
                        my $sib;
                        if ( $p->get_first_daughter == $tree->[$i] ) {
                            $sib = $ns;
                            $sib->set_previous_sister();
                        }
                        elsif ( $p->get_last_daughter == $tree->[$i] ) {
                            $sib = $ps;
                            $sib->set_next_sister();
                        }
                        my $sibbl = $sib->get_branch_length;
                        my $pbl   = $p->get_branch_length;
                        my $sibnbl;
                        if ($sibbl) {
                            $sibnbl = $sibbl;
                        }
                        if ($pbl) {
                            $sibnbl += $pbl;
                        }
                        if ( defined $sibnbl ) {
                            $sib->set_branch_length($sibnbl);
                        }
                        $sib->set_parent($gp);
                        my $pps = $p->get_previous_sister;
                        my $pns = $p->get_next_sister;
                        if ($pps) {
                            $sib->set_previous_sister($pps);
                            $pps->set_next_sister($sib);
                        }
                        if ($pns) {
                            $sib->set_next_sister($pns);
                            $pns->set_previous_sister($sib);
                        }
                        if ( $gp->get_first_daughter == $p ) {
                            $gp->set_first_daughter($sib);
                        }
                        elsif ( $gp->get_last_daughter == $p ) {
                            $gp->set_last_daughter($sib);
                        }
                      PARENT: for ( my $j = 0 ; $j <= $#{$tree} ; $j++ ) {
                            if ( !defined $tree->[$j] ) {
                                next PARENT;
                            }
                            if ( $tree->[$j] == $p ) {
                                $tree->[$j] = undef;
                                last PARENT;
                            }
                        }
                        $tree->[$i] = undef;
                        next OUTER;
                    }
    
                    # parent bifurcates, is root
                    elsif ( $p && !$gp && scalar @{ $p->get_children } <= 2 ) {
                        if ( $p->get_first_daughter == $tree->[$i] ) {
                            my $pld = $p->get_last_daughter;
                            $pld->set_parent();
                            $pld->set_next_sister();
                            $pld->set_previous_sister();
                        }
                        elsif ( $p->get_last_daughter == $tree->[$i] ) {
                            my $pfd = $p->get_first_daughter;
                            $pfd->set_parent();
                            $pfd->set_next_sister();
                            $pfd->set_previous_sister();
                        }
                        $tree->[$i] = undef;
                      PARENT: for ( my $j = 0 ; $j <= $#{$tree} ; $j++ ) {
                            if ( !defined $tree->[$j] ) {
                                next PARENT;
                            }
                            if ( $tree->[$j] == $p ) {
                                $tree->[$j] = undef;
                                last PARENT;
                            }
                        }
                        next OUTER;
                    }
                }
                elsif ( $tree->[$i]->get_name eq $tip && $tree->[$i]->is_internal )
                {
                    Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                        error => "$tip is an internal node. Tips only please!" );
                }
            }
        }
    
        # splice undef nodes here
        for ( my $j = $#{$tree} ; $j >= 0 ; $j-- ) {
            if ( !defined $tree->[$j] ) {
                splice @{$tree}, $j, 1;
            }
        }
        return $self;
    }

=item keep_tips()

 Type    : Tree manipulator
 Title   : keep_tips
 Usage   : $tree->keep_tips(\@taxa);
 Function: Keeps specified taxa from invocant.
 Returns : The pruned Bio::Phylo::Forest::Tree object.
 Args    : A list of taxon names.
 Comments:

=cut

    sub keep_tips {
        my ( $tree, $tips ) = @_;
        $tree->_flush_cache;        
        my ( @allnames, @taxatoprune );
        foreach my $tip ( @{ $tree->get_terminals } ) {
            push @allnames, $tip->get_name;
        }
        foreach my $name (@allnames) {
            if ( $name && ! grep /^$name$/, @{$tips} ) {
                push @taxatoprune, $name;
            }
        }
        $tree->prune_tips( \@taxatoprune );
        return $tree;
    }

=item negative_to_zero()

 Type    : Tree manipulator
 Title   : negative_to_zero
 Usage   : $tree->negative_to_zero;
 Function: Converts negative branch 
           lengths to zero.
 Returns : The modified invocant.
 Args    : NONE
 Comments:

=cut

    sub negative_to_zero {
        my $tree = shift;
        $tree->_flush_cache;        
        foreach my $node ( @{ $tree->get_entities } ) {
            my $bl = $node->get_branch_length;
            if ( $bl && $bl < 0 ) {
                $node->set_branch_length('0.00');
            }
        }
        return $tree;
    }

=item exponentiate()

 Type    : Tree manipulator
 Title   : exponentiate
 Usage   : $tree->exponentiate($power);
 Function: Raises branch lengths to $power.
 Returns : The modified invocant.
 Args    : A $power in any of perl's number formats.

=cut

    sub exponentiate {
        my ( $tree, $power ) = @_;
        $tree->_flush_cache;        
        if ( ! looks_like_number $power ) {
            Bio::Phylo::Util::Exceptions::BadNumber->throw(
                error => "Power \"$power\" is a bad number" );
        }
        else {
            foreach my $node ( @{ $tree->get_entities } ) {
                my $bl = $node->get_branch_length;
                $node->set_branch_length( $bl**$power );
            }
        }
        return $tree;
    }

=item log_transform()

 Type    : Tree manipulator
 Title   : log_transform
 Usage   : $tree->log_transform($base);
 Function: Log $base transforms branch lengths.
 Returns : The modified invocant.
 Args    : A $base in any of perl's number formats.

=cut

    sub log_transform {
        my ( $tree, $base ) = @_;
        $tree->_flush_cache;        
        if ( ! looks_like_number $base ) {
            Bio::Phylo::Util::Exceptions::BadNumber->throw(
                error => "Base \"$base\" is a bad number" );
        }
        else {
            foreach my $node ( @{ $tree->get_entities } ) {
                my $bl = $node->get_branch_length;
                my $newbl;
                eval { $newbl = ( log $bl ) / ( log $base ); };
                if ($@) {
                    Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                        error => "Invalid input for log transform: $@" );
                }
                else {
                    $node->set_branch_length($newbl);
                }
            }
        }
        return $tree;
    }

=item remove_unbranched_internals()

 Type    : Tree manipulator
 Title   : remove_unbranched_internals
 Usage   : $tree->remove_unbranched_internals;
 Function: Collapses internal nodes 
           with fewer than 2 children.
 Returns : The modified invocant.
 Args    : NONE
 Comments:

=cut

    sub remove_unbranched_internals {
        my $self = shift;
        $self->_flush_cache;
        my $tree = $self->get_entities;
        for my $i ( 0 .. $#{$tree} ) {
            if ( $tree->[$i] ) {
                if (   $tree->[$i]->get_parent
                    && $tree->[$i]->is_internal
                    && scalar $tree->[$i]->get_children == 1 )
                {
                    $tree->[$i]
                      ->get_first_daughter->set_parent( $tree->[$i]->get_parent );
                    my $childbl =
                      $tree->[$i]->get_first_daughter->get_branch_length;
                    $childbl += $tree->[$i]->get_branch_length;
                    $tree->[$i]->get_first_daughter->set_branch_length($childbl);
                    splice @{$tree}, $i, 1;
                    $tree->_analyze;
                }
                elsif (!$tree->[$i]->get_parent
                    && $tree->[$i]->is_internal
                    && scalar $tree->[$i]->get_children == 1 )
                {
                    $tree->[$i]->get_first_daughter->set_parent();
                    splice @{$tree}, $i, 1;
                }
            }
            else {
                splice @{$tree}, $i, 1;
            }
        }
        return $self;
    }

=item to_newick()

 Type    : Stringifier
 Title   : to_newick
 Usage   : my $string = $tree->to_newick;
 Function: Turns the invocant tree object 
           into a newick string
 Returns : SCALAR
 Args    : NONE

=cut

    sub to_newick {
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];
        my $newick = unparse( -format => 'newick', -phylo => $self );
        $self->_store_cache($newick);
        return $newick;
    }

=item to_cipres()

 Type    : Format converter
 Title   : to_cipres
 Usage   : my $ciprestree = $tree->to_cipres;
 Function: Turns the invocant tree object 
           into a CIPRES CORBA compliant 
           data structure
 Returns : HASHREF
 Args    : NONE

=cut

    sub to_cipres {
        eval { require CipresIDL; };
        if ( $@ ) {
            Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                'error' => 'This method requires CipresIDL, which you don\'t have',
            );
        }
        
        my $self = shift;
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];

        my $m_newick  = $self->to_newick;
        my $m_name    = $self->get_name;
        my $_score    = $self->get_score;
        my $scoretype = $self->get_generic('score_type');
        my $m_score   = CipresIDL::TreeScore->new;        
        my $m_leafSet = [];
                
        for my $i ( 0 .. $#{ $self->get_entities } ) {
            push @{ $m_leafSet }, $i if $self->get_by_index($i)->is_terminal;
        }
        
        if ( defined $scoretype && $scoretype == INT_SCORE_TYPE ) {
            $m_score->intScore( 'CipresIDL::INT_SCORE_TYPE', $_score );
        }
        elsif ( defined $scoretype && $scoretype == DOUBLE_SCORE_TYPE ) {
            $m_score->doubleScore( 'CipresIDL::DOUBLE_SCORE_TYPE', $_score );
        }
        else {
            $m_score->noScore( 'CipresIDL::NO_SCORE_TYPE', $_score );
        }
                 
        my $cipres_tree = CipresIDL::Tree->new(
            'm_newick'  => $m_newick,
            'm_score'   => $m_score,
            'm_leafSet' => $m_leafSet,
            'm_name'    => $m_name,
        );        
        
        $self->_store_cache($cipres_tree);
        return $cipres_tree;
    }
    
=begin comment

 Type    : Internal method
 Title   : DESTROY
 Usage   : $node->DESTROY;
 Function: Sends object ID back to pool
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub DESTROY {
        my $self = shift;
        $self->SUPER::DESTROY;        
        return 1;
    }

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $tree->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _container { _FOREST_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $tree->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _type { _TREE_ }

=back

=head1 Bio::Tree::TreeI methods

If Bio::Tree::TreeI is found in @INC, the Bio::Phylo::Forest::Tree object
will implement the Bio::Tree::TreeI methods. Consult the L<Bio::Tree::TreeI>
documentation for details about the following methods.

=over

=item get_leaf_nodes()

=item get_nodes()

=item get_root_node()

=item height()

=item id()

=item number_nodes()

=item score()

=item total_branch_length()

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Listable>

The L<Bio::Phylo::Forest::Tree|Bio::Phylo::Forest::Tree> object inherits from
the L<Bio::Phylo::Listable|Bio::Phylo::Listable> object, so the methods defined
therein also apply to trees.

=item L<Bio::Tree::TreeI>

If you have BioPerl installed, the L<Bio::Phylo::Forest::Tree> will
implement the TreeI interface.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual|Bio::Phylo::Manual>.

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

$Id: Tree.pm,v 1.22 2006/04/12 22:38:22 rvosa Exp $

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