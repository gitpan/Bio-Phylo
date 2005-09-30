# $Id: Tree.pm,v 1.13 2005/09/29 20:31:17 rvosa Exp $
# Subversion: $Rev: 177 $
package Bio::Phylo::Forest::Tree;
use strict;
use warnings;
use Bio::Phylo::Forest::Node;
use Bio::Phylo::IO qw(unparse);
use Bio::Phylo::CONSTANT qw(_TREE_ _FOREST_);
use Scalar::Util qw(looks_like_number);
use base 'Bio::Phylo::Listable';

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

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
L<Bio::Phylo::Forest::Node|Bio::Phylo::Forest::Node> objects. The tree object
inherits from L<Bio::Phylo::Listable|Bio::Phylo::Listable>, so look there
for more methods.

=head1 METHODS

=head2 CONSTRUCTOR

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
    my $self  = fields::new($class);
    $self->SUPER::new(@_);
    if (@_) {
        my %opts;
        eval { %opts = @_; };
        if ($@) {
            Bio::Phylo::Exceptions::OddHash->throw( error => $@ );
        }
        while ( my ( $key, $value ) = each %opts ) {
            my $localkey = uc substr $key, 1;
            eval { $self->{$localkey} = $value; };
            if ($@) {
                Bio::Phylo::Exceptions::BadArgs->throw(
                    error => "invalid field specified: $key ($localkey)" );
            }
        }
    }
    return $self;
}

=back

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

=head2 QUERIES

=over

=item get_terminals()

 Type    : Query
 Title   : get_terminals
 Usage   : my @terminals = @{ $tree->get_terminals };
 Function: Retrieves all terminal nodes in
           the Bio::Phylo::Forest::Tree object.
 Returns : An array reference of Bio::Phylo::Forest::Node objects.
 Args    : NONE
 Comments: If the tree is valid, this method retrieves the same set
           of nodes as $node->get_terminals($root). However, because
           there is no recursion it may be faster. Also, the node
           method by the same name does not see orphans.

=cut

sub get_terminals {
    my $tree = $_[0];
    my @terminals;
    foreach ( @{ $tree->get_entities } ) {
        if ( $_->is_terminal ) {
            push @terminals, $_;
        }
    }
    return \@terminals;
}

=item get_internals()

 Type    : Query
 Title   : get_internals
 Usage   : my @internals = @{ $tree->get_internals };
 Function: Retrieves all internal nodes in the Bio::Phylo::Forest::Tree object.
 Returns : An array reference of Bio::Phylo::Forest::Node objects.
 Args    : NONE
 Comments: If the tree is valid, this method retrieves the same set
           of nodes as $node->get_internals($root). However, because
           there is no recursion it may be faster. Also, the node
           method by the same name does not see orphans.

=cut

sub get_internals {
    my $tree = $_[0];
    my @internals;
    foreach ( @{ $tree->get_entities } ) {
        if ( $_->is_internal ) {
            push @internals, $_;
        }
    }
    return \@internals;
}

=item get_root()

 Type    : Query
 Title   : get_root
 Usage   : my $root = $tree->get_root;
 Function: Retrieves the first orphan in the current Bio::Phylo::Forest::Tree
           object - which should be the root.
 Returns : Bio::Phylo::Forest::Node
 Args    : NONE

=cut

sub get_root {
    my $tree = $_[0];
    foreach ( @{ $tree->get_entities } ) {
        if ( !$_->get_parent ) {
            return $_;
        }
    }
    return;
}

=item get_mrca()

 Type    : Query
 Title   : get_mrca
 Usage   : my $mrca = $tree->get_mrca(\@nodes);
 Function: Retrieves the most recent common ancestor of \@nodes
 Returns : Bio::Phylo::Forest::Node
 Args    : A reference to an array of Bio::Phylo::Forest::Node objects in
           $tree.

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
 Function: Tests whether the current Bio::Phylo::Forest::Tree object is
           bifurcating.
 Returns : BOOLEAN
 Args    : NONE

=cut

sub is_binary {
    my $tree = $_[0];
    foreach ( @{ $tree->get_internals } ) {
        if ( $_->get_first_daughter->get_next_sister != $_->get_last_daughter )
        {
            return;
        }
    }
    return 1;
}

=item is_ultrametric()

 Type    : Test
 Title   : is_ultrametric
 Usage   : if ( $tree->is_ultrametric(0.01) ) {
              # do something
           }
 Function: Tests whether the Bio::Phylo::Forest::Tree object is ultrametric.
 Returns : BOOLEAN
 Args    : Optional margin between pairwise comparisons (default = 0).
 Comments: The test is done by performing all pairwise comparisons for
           root-to-tip path lengths. Since many programs introduce
           rounding errors in branch lengths the optional argument is
           available to test TRUE for nearly ultrametric trees. For
           example, a value of 0.01 indicates that no pairwise
           comparison may differ by more than 1%. Note: behaviour is
           undefined for negative branch lengths.

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
           same as &Bio::Phylo::Forest::Node::is_outgroup_of.

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
 Function: Tests whether the set of \@tips forms a clade
 Returns : BOOLEAN
 Args    : A reference to an array of Bio::Phylo::Forest::Node objects.
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
 Usage   : my $tree_length = $tree->calc_tree_length;
 Function: Calculates the sum of all branch lengths (i.e. the tree length).
 Returns : FLOAT
 Args    : NONE

=cut

sub calc_tree_length {
    my $tree = $_[0];
    my $tl   = 0;
    foreach ( @{ $tree->get_entities } ) {
        if ( defined $_->get_branch_length ) {
            $tl += $_->get_branch_length;
        }
    }
    return $tl;
}

=item calc_tree_height()

 Type    : Calculation
 Title   : calc_tree_height
 Usage   : my $tree_height = $tree->calc_tree_height;
 Function: Calculates the height of the tree.
 Returns : FLOAT
 Args    : NONE
 Comments: For ultrametric trees this method returns the height, but this is
           done by averaging over all root-to-tip path lengths, so for
           additive trees the result should consequently be interpreted
           differently.

=cut

sub calc_tree_height {
    my $tree = $_[0];
    my $th   = $tree->calc_total_paths / $tree->calc_number_of_terminals;
    return $th;
}

=item calc_number_of_nodes()

 Type    : Calculation
 Title   : calc_number_of_nodes
 Usage   : my $number_of_nodes = $tree->calc_number_of_nodes;
 Function: Calculates the number of nodes (internals AND terminals).
 Returns : INT
 Args    : NONE

=cut

sub calc_number_of_nodes {
    my $tree = $_[0];
    return scalar @{ $tree->get_entities };
}

=item calc_number_of_terminals()

 Type    : Calculation
 Title   : calc_number_of_terminals
 Usage   : my $number_of_terminals = $tree->calc_number_of_terminals;
 Function: Calculates the number of terminal nodes.
 Returns : INT
 Args    : NONE

=cut

sub calc_number_of_terminals {
    my $tree = $_[0];
    return scalar @{ $tree->get_terminals };
}

=item calc_number_of_internals()

 Type    : Calculation
 Title   : calc_number_of_internals
 Usage   : my $number_of_internals = $tree->calc_number_of_internals;
 Function: Calculates the number of internal nodes.
 Returns : INT
 Args    : NONE

=cut

sub calc_number_of_internals {
    my $tree = $_[0];
    return scalar @{ $tree->get_internals };
}

=item calc_total_paths()

 Type    : Calculation
 Title   : calc_total_paths
 Usage   : my $total_paths = $tree->calc_total_paths;
 Function: Calculates the sum of all root-to-tip path lengths.
 Returns : FLOAT
 Args    : NONE

=cut

sub calc_total_paths {
    my $tree = $_[0];
    my $tp   = 0;
    foreach ( @{ $tree->get_terminals } ) {
        $tp += $_->calc_path_to_root;
    }
    return $tp;
}

=item calc_redundancy()

 Type    : Calculation
 Title   : calc_redundancy
 Usage   : my $redundancy = $tree->calc_redundancy;
 Function: Calculates the amount of shared (redundant) history on the total.
 Returns : FLOAT
 Args    : NONE
 Comments: Redundancy is calculated as
 1 / ( treelength - height / ( ntax * height - height ) )

=cut

sub calc_redundancy {
    my $tree = $_[0];
    my $tl   = $tree->calc_tree_length;
    my $th   = $tree->calc_tree_height;
    my $ntax = $tree->calc_number_of_terminals;
    my $red  = 1 - ( ( $tl - $th ) / ( ( $th * $ntax ) - $th ) );
    return $red;
}

=item calc_imbalance()

 Type    : Calculation
 Title   : calc_imbalance
 Usage   : my $imbalance = $tree->calc_imbalance;
 Function: Calculates Colless' coefficient of tree imbalance.
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Colless, D.H., 1982. The theory and practice of
           phylogenetic systematics. Systematic Zoology 31(1): 100-104

=cut

sub calc_imbalance {
    my $tree = $_[0];
    my ( $maxic, $sum, $Ic ) = ( 0, 0 );
    if ( !$tree->is_binary ) {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => 'Colless\' imbalance only possible for binary trees' );
    }
    my $numtips = $tree->calc_number_of_terminals;
    $numtips -= 2;
    while ($numtips) {
        $maxic += $numtips;
        $numtips--;
    }
    foreach my $node ( @{ $tree->get_internals } ) {
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
    return $Ic;
}

=item calc_fiala_stemminess()

 Type    : Calculation
 Title   : calc_fiala_stemminess
 Usage   : my $fiala_stemminess = $tree->calc_fiala_stemminess;
 Function: Calculates stemminess measure Fiala and Sokal (1985).
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Fiala, K.L. and R.R. Sokal, 1985. Factors determining
           the accuracy of cladogram estimation: evaluation using computer
           simulation. Evolution, 39: 609-622

=cut

sub calc_fiala_stemminess {
    my $tree      = $_[0];
    my @internals = @{ $tree->get_internals };
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
    return $total;
}

=item calc_rohlf_stemminess()

 Type    : Calculation
 Title   : calc_rohlf_stemminess
 Usage   : my $rohlf_stemminess = $tree->calc_rohlf_stemminess;
 Function: Calculates stemminess measure from Rohlf et al. (1990).
 Returns : FLOAT
 Args    : NONE
 Comments: As described in Rohlf, F.J., W.S. Chang, R.R. Sokal, J. Kim, 1990.
           Accuracy of estimated phylogenies: effects of tree topology and
           evolutionary model. Evolution, 44(6): 1671-1684

=cut

sub calc_rohlf_stemminess {
    my $tree = $_[0];
    if ( !$tree->is_ultrametric(0.01) ) {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => 'Rohlf stemminess only possible for ultrametric trees' );
    }
    my @internals            = @{ $tree->get_internals };
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
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => 'it looks like all branches were of length zero' );
    }
    my $crs = $one_over_t_minus_two * $total;
    return $crs;
}

=item calc_resolution()

 Type    : Calculation
 Title   : calc_resolution
 Usage   : my $resolution = $tree->calc_resolution;
 Function: Calculates the total number of internal nodes over the
           total number of internal nodes on a fully bifurcating
           tree of the same size.
 Returns : FLOAT
 Args    : NONE

=cut

sub calc_resolution {
    my $tree = $_[0];
    return $tree->calc_number_of_internals /
      ( $tree->calc_number_of_terminals - 1 );
}

=item calc_branching_times()

 Type    : Calculation
 Title   : calc_branching_times
 Usage   : my $branching_times = $tree->calc_branching_times;
 Function: Returns a two-dimensional array. The first dimension
           consists of the "records", so that in the second
           dimension $AoA[$first][0] contains the internal node
           references, and $AoA[$first][1] the branching time
           of the internal node. The records are orderered from
           root to tips by time from the origin.
 Returns : SCALAR[][] or FALSE
 Args    : NONE

=cut

sub calc_branching_times {
    my $tree = $_[0];
    my @branching_times;
    if ( !$tree->is_ultrametric(0.01) ) {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => 'tree isn\'t ultrametric, results would be meaningless' );
    }
    else {
        my ( $i, @temp ) = 0;
        foreach ( @{ $tree->get_internals } ) {
            $temp[$i] = [ $_, $_->calc_path_to_root ];
            $i++;
        }
        @branching_times = sort { $a->[1] <=> $b->[1] } @temp;
    }
    return \@branching_times;    # pass by ref
}

=item calc_ltt()

 Type    : Calculation
 Title   : calc_ltt
 Usage   : my $ltt = $tree->calc_ltt;
 Function: Returns a two-dimensional array. The first dimension
           consists of the "records", so that in the second dimension
           $AoA[$first][0] contains the internal node references, and
           $AoA[$first][1] the branching time of the internal node,
           and $AoA[$first][2] the cumulative number of lineages over
           time. The records are orderered from root to tips by
           time from the origin.
 Returns : SCALAR[][] or FALSE
 Args    : NONE

=cut

sub calc_ltt {
    my $tree = $_[0];
    if ( !$tree->is_ultrametric(0.01) ) {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => 'tree isn\'t ultrametric, results would be meaningless' );
    }
    my $ltt      = ( $tree->calc_branching_times );
    my $lineages = 1;
    for my $i ( 0 .. $#{$ltt} ) {
        $lineages += ( scalar @{ $ltt->[$i][0]->get_children } - 1 );
        $ltt->[$i][2] = $lineages;
    }
    return $ltt;
}

=item calc_symdiff()

 Type    : Calculation
 Title   : calc_symdiff
 Usage   : my $symdiff = $tree->calc_symdiff($other_tree);
 Function: Returns the symmetric difference metric between $tree and
           $other_tree, sensu Penny and Hendy, 1985.
 Returns : SCALAR
 Args    : A Bio::Phylo::Forest::Tree object
 Comments: Trees in comparison must span the same set of terminal taxa
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

=back

=head2 TREE MANIPULATION

=over

=item ultrametricize()

 Type    : Tree manipulator
 Title   : ultrametricize
 Usage   : $tree->ultrametricize;
 Function: Sets all root-to-tip path lengths equal by stretching
           all terminal branches to the height of the tallest node.
 Returns : The modified Bio::Phylo::Forest::Tree object.
 Args    : NONE
 Comments: This method is analogous to the 'ultrametricize' command
           in Mesquite, i.e. no rate smoothing or anything like that
           happens, just a lengthening of terminal branches.

=cut

sub ultrametricize {
    my $tree    = $_[0];
    my $tallest = 0;
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
 Function: Scales the tree to the specified height.
 Returns : The modified Bio::Phylo::Forest::Tree object.
 Args    : $height = a numerical value indicating root-to-tip path length.
 Comments: This method uses the $tree->calc_tree_height method, and so for
           additive trees the *average* root-to-tip path length is scaled to
           $height (i.e. some nodes might be taller than $height, others
           shorter).

=cut

sub scale {
    my ( $tree, $target_height ) = @_;
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
 Function: Breaks polytomies by inserting additional internal nodes orderered
           from left to right.
 Returns : The modified Bio::Phylo::Forest::Tree object.
 Args    :
 Comments:

=cut

sub resolve {
    my $tree = $_[0];
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
                Bio::Phylo::Exceptions::ObjectMismatch->throw(
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
    my ( @allnames, @taxatoprune );
    foreach my $tip ( @{ $tree->get_terminals } ) {
        push @allnames, $tip->get_name;
    }
    foreach my $name (@allnames) {
        if ( grep /$name/, @{$tips} ) {
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
 Function: Converts negative branch lengths to zero.
 Returns : The modified Bio::Phylo::Forest::Tree object.
 Args    : NONE
 Comments:

=cut

sub negative_to_zero {
    my $tree = shift;
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
 Returns : The modified Bio::Phylo::Forest::Tree object.
 Args    : A $power in any of perl's number formats.

=cut

sub exponentiate {
    my ( $tree, $power ) = @_;
    if ( ! looks_like_number $power ) {
        Bio::Phylo::Exceptions::BadNumber->throw(
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
 Returns : The modified Bio::Phylo::Forest::Tree object.
 Args    : A $base in any of perl's number formats.

=cut

sub log_transform {
    my ( $tree, $base ) = @_;
    if ( ! looks_like_number $base ) {
        Bio::Phylo::Exceptions::BadNumber->throw(
            error => "Base \"$base\" is a bad number" );
    }
    else {
        foreach my $node ( @{ $tree->get_entities } ) {
            my $bl = $node->get_branch_length;
            my $newbl;
            eval { $newbl = ( log $bl ) / ( log $base ); };
            if ($@) {
                Bio::Phylo::Exceptions::OutOfBounds->throw(
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
 Function: Collapses internal nodes with fewer than 2 children.
 Returns : The modified Bio::Phylo::Forest::Tree object.
 Args    : NONE
 Comments:

=cut

sub remove_unbranched_internals {
    my $self = shift;
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
 Function: Turns the invocant tree object into a newick string
 Returns : SCALAR
 Args    : NONE

=cut

sub to_newick {
    return unparse( -format => 'newick', -phylo => $_[0] );
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

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Listable>

The L<Bio::Phylo::Forest::Tree|Bio::Phylo::Forest::Tree> object inherits from
the L<Bio::Phylo::Listable|Bio::Phylo::Listable> object, so the methods defined
therein also apply to trees.

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

$Id: Tree.pm,v 1.13 2005/09/29 20:31:17 rvosa Exp $

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
