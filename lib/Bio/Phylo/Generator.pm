# $Id: Generator.pm 4198 2007-07-12 16:45:08Z rvosa $
package Bio::Phylo::Generator;
use strict;
use Bio::Phylo;
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Forest;
use Bio::Phylo::Forest::Tree;
use Bio::Phylo::Forest::Node;
use Math::Random qw(random_exponential);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo);
{

=head1 NAME

Bio::Phylo::Generator - Generates random trees.

=head1 SYNOPSIS

 use Bio::Phylo::Generator;
 my $gen = Bio::Phylo::Generator->new;
 my $trees = $gen->gen_rand_pure_birth( 
     '-tips'  => 10, 
     '-model' => 'yule',
     '-trees' => 10,
 );

 # prints 'Bio::Phylo::Forest'
 print ref $trees;

=head1 DESCRIPTION

The generator module is used to simulate trees under the Yule, Hey, or
equiprobable model.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

Generator constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $gen = Bio::Phylo::Generator->new;
 Function: Initializes a Bio::Phylo::Generator object.
 Returns : A Bio::Phylo::Generator object.
 Args    : NONE

=cut

	sub new {

		# could be child class
		my $class = shift;

		# notify user
		$class->info("constructor called for '$class'");

		# recurse up inheritance tree, get ID
		my $self = $class->SUPER::new(@_);

		# local fields would be set here

		return $self;
	}

=back

=head2 GENERATOR

=over

=item gen_rand_pure_birth()

This method generates a Bio::Phylo::Forest 
object populated with Yule/Hey trees.

 Type    : Generator
 Title   : gen_rand_pure_birth
 Usage   : my $trees = $gen->gen_rand_pure_birth(
               '-tips'  => 10, 
               '-model' => 'yule',
               '-trees' => 10,
           );
 Function: Generates markov tree shapes, 
           with branch lengths sampled 
           from a user defined model of 
           clade growth, for a user defined
           number of tips.
 Returns : A Bio::Phylo::Forest object.
 Args    : -tips  => number of terminal nodes,
           -model => either 'yule' or 'hey',
           -trees => number of trees to generate

=cut

	sub gen_rand_pure_birth {
		my $random  = shift;
		my %options = @_;
		my ( $yule, $hey );
		if ( $options{'-model'} =~ m/yule/i ) {
			$yule = 1;
		}
		elsif ( $options{'-model'} =~ m/hey/i ) {
			$hey = 1;
		}
		else {
			Bio::Phylo::Util::Exceptions::BadFormat->throw(
				error => "model \"$options{'-model'}\" not implemented" );
		}
		my $forest = Bio::Phylo::Forest->new;
		for ( 0 .. $options{'-trees'} ) {

			# instantiate new tree object
			my $tree = Bio::Phylo::Forest::Tree->new;

			# $i = a counter, $bl = branch length
			my ( $i, $bl ) = 1;

			# generate branch length
			if ($yule) {
				$bl = random_exponential( 1, 1 / ( $i + 1 ) );
			}
			elsif ($hey) {
				$bl = random_exponential( 1, ( 1 / ( $i * ( $i + 1 ) ) ) );
			}

			# instantiate root node
			my $root = Bio::Phylo::Forest::Node->new( '-name' => 'root' );
			$root->set_branch_length(0);
			$tree->insert($root);

			for ( 1 .. 2 ) {
				my $node =
				  Bio::Phylo::Forest::Node->new( '-name' => "node.$i.$_" );
				$node->set_branch_length($bl);
				$tree->insert($node);
				$node->set_parent($root);
			}

			# there are now two tips from which the tree
			# can grow, we store these in the tip array,
			# from which we well randomly draw a tip
			# for the next split.
			my @tips;
			push @tips, @{ $root->get_children };

			# start growing the tree
			for my $i ( 2 .. ( $options{'-tips'} - 1 ) ) {

				# generate branch length
				if ($yule) {
					$bl = random_exponential( 1, 1 / ( $i + 1 ) );
				}
				elsif ($hey) {
					$bl = random_exponential( 1, ( 1 / ( $i * ( $i + 1 ) ) ) );
				}

				# draw a random integer between 0 and
				# the tip array length
				my $j = int rand scalar @tips;

				# dereference to obtain parent of current split
				my $parent = $tips[$j];

				for ( 1 .. 2 ) {
					my $node =
					  Bio::Phylo::Forest::Node->new( '-name' => "node.$i.$_" );
					$node->set_branch_length($bl);
					$tree->insert($node);
					$node->set_parent($parent);
				}

				# remove parent from tips array
				splice @tips, $j, 1;

				# stretch all tips to the present
				foreach (@tips) {
					my $oldbl = $_->get_branch_length;
					$_->set_branch_length( $oldbl + $bl );
				}

				# add new nodes to tips array
				push @tips, @{ $parent->get_children };
			}
			$forest->insert($tree);
		}
		return $forest;
	}

=item gen_exp_pure_birth()

This method generates a Bio::Phylo::Forest object 
populated with Yule/Hey trees whose branch lengths 
are proportional to the expected waiting times (i.e. 
not sampled from a distribution).

 Type    : Generator
 Title   : gen_exp_pure_birth
 Usage   : my $trees = $gen->gen_exp_pure_birth(
               '-tips'  => 10, 
               '-model' => 'yule',
               '-trees' => 10,
           );
 Function: Generates markov tree shapes, 
           with branch lengths following 
           the expectation under a user 
           defined model of clade growth, 
           for a user defined number of tips.
 Returns : A Bio::Phylo::Forest object.
 Args    : -tips  => number of terminal nodes,
           -model => either 'yule' or 'hey'
           -trees => number of trees to generate

=cut

	sub gen_exp_pure_birth {
		my $random  = shift;
		my %options = @_;
		my ( $yule, $hey );
		if ( $options{'-model'} =~ m/yule/i ) {
			$yule = 1;
		}
		elsif ( $options{'-model'} =~ m/hey/i ) {
			$hey = 1;
		}
		else {
			Bio::Phylo::Util::Exceptions::BadFormat->throw(
				error => "model \"$options{'-model'}\" not implemented" );
		}
		my $forest = Bio::Phylo::Forest->new;
		for ( 0 .. $options{'-trees'} ) {

			# instantiate new tree object
			my $tree = Bio::Phylo::Forest::Tree->new;

			# $i = a counter, $bl = branch length
			my ( $i, $bl ) = 1;

			# generate branch length
			if ($yule) {
				$bl = 1 / ( $i + 1 );
			}
			elsif ($hey) {
				$bl = 1 / ( $i * ( $i + 1 ) );
			}

			# instantiate root node
			my $root = Bio::Phylo::Forest::Node->new( '-name' => 'root' );
			$root->set_branch_length(0);
			$tree->insert($root);

			# instantiate children
			for ( 1 .. 2 ) {
				my $node =
				  Bio::Phylo::Forest::Node->new( '-name' => "node.$i.$_" );
				$node->set_branch_length($bl);
				$tree->insert($node);
				$node->set_parent($root);
			}

			# there are now two tips from which the tree
			# can grow, we store these in the tip array,
			# from which we well randomly draw a tip
			# for the next split.
			my @tips;
			push @tips, @{ $root->get_children };

			# start growing the tree
			for my $i ( 2 .. ( $options{'-tips'} - 1 ) ) {

				# generate branch length
				if ($yule) {
					$bl = 1 / ( $i + 1 );
				}
				elsif ($hey) {
					$bl = 1 / ( $i * ( $i + 1 ) );
				}

				# draw a random integer between 0 and
				# the tip array length
				my $j = int rand scalar @tips;

				# dereference to obtain parent of current split
				my $parent = $tips[$j];

				# instantiate children
				for ( 1 .. 2 ) {
					my $node =
					  Bio::Phylo::Forest::Node->new( '-name' => "node.$i.$_" );
					$node->set_branch_length($bl);
					$tree->insert($node);
					$node->set_parent($parent);
				}

				# remove parent from tips array
				splice @tips, $j, 1;

				# stretch all tips to the present
				foreach (@tips) {
					my $oldbl = $_->get_branch_length;
					$_->set_branch_length( $oldbl + $bl );
				}

				# add new nodes to tips array
				push @tips, @{ $parent->get_children };
			}
			$forest->insert($tree);
		}
		return $forest;
	}

=item gen_equiprobable()

This method draws tree shapes at random, 
such that all shapes are equally probable.

 Type    : Generator
 Title   : gen_equiprobable
 Usage   : my $trees = $gen->gen_equiprobable( 
               '-tips'  => 10, 
               '-trees' => 5,
           );
 Function: Generates an equiprobable tree 
           shape, with branch lengths = 1;
 Returns : A Bio::Phylo::Forest object.
 Args    : -tips  => number of terminal nodes,
           -trees => number of trees to generate

=cut

	sub gen_equiprobable {
		my $random  = shift;
		my %options = @_;
		my $forest  = Bio::Phylo::Forest->new( '-name' => 'Equiprobable' );
		for ( 0 .. $options{'-trees'} ) {
			my $tree = Bio::Phylo::Forest::Tree->new( '-name' => 'Tree' . $_ );
			for my $i ( 1 .. ( $options{'-tips'} + ( $options{'-tips'} - 1 ) ) )
			{
				my $node = Bio::Phylo::Forest::Node->new(
					'-name'          => 'Node' . $i,
					'-branch_length' => 1,
				);
				$tree->insert($node);
			}
			my $nodes   = $tree->get_entities;
			my $parents = $nodes;
			for my $node ( @{$nodes} ) {
			  CHOOSEPARENT: while ( @{$parents} ) {
					my $j      = int rand scalar @{$parents};
					my $parent = $parents->[$j];
					if ( $parent != $node && !$node->is_ancestor_of($parent) ) {
						if ( $parent->is_terminal ) {
							$node->set_parent($parent);
							last CHOOSEPARENT;
						}
						elsif ( scalar @{ $parent->get_children } == 1 ) {
							$node->set_parent($parent);
							splice( @{$parents}, $j, 1 );
							last CHOOSEPARENT;
						}
					}
				}
			}
			$forest->insert($tree);
		}
		return $forest;
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
	}

=back

=head1 SEE ALSO

=over

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

$Id: Generator.pm 4198 2007-07-12 16:45:08Z rvosa $

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
