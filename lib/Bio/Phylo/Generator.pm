# $Id: Generator.pm,v 1.18 2005/09/29 20:31:17 rvosa Exp $
# Subversion: $Rev: 184 $
package Bio::Phylo::Generator;
use strict;
use warnings;
use Bio::Phylo::Forest;
use Bio::Phylo::Forest::Tree;
use Bio::Phylo::Forest::Node;
use Math::Random qw(random_exponential);
use base 'Bio::Phylo';

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Generator - Generates random trees.

=head1 SYNOPSIS

 use Bio::Phylo::Generator;
 my $gen = Bio::Phylo::Generator->new;
 my $trees = $gen->gen_rand_pure_birth( -tips => 10, -model => 'yule' );
 print ref $trees; # prints 'Bio::Phylo::Forest'

=head1 DESCRIPTION

The generator module is used to simulate trees under the Yule, Hey, or
equiprobable model.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $gen = Bio::Phylo::Generator->new;
 Function: Initializes a Bio::Phylo::Generator object.
 Returns : A Bio::Phylo::Generator object.
 Args    : NONE

=cut

sub new {
    my $class = $_[0];
    my $self  = {};
    bless $self, $class;
    return $self;
}

=back

=head2 GENERATOR

=over

=item gen_rand_pure_birth()

This method generates a Bio::Phylo::Forest object populated with Yule/Hey trees.

 Type    : Generator
 Title   : gen_rand_pure_birth
 Usage   : my $trees = $gen->gen_rand_pure_birth(-tips => 10, -model => 'yule');
 Function: Generates markov tree shapes, with branch lengths sampled from
           a user defined model of clade growth, for a user defined
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
        Bio::Phylo::Exceptions::BadFormat->throw(
            error => "model \"$options{'-model'}\" not implemented"
        );
    }
    my $forest  = Bio::Phylo::Forest->new;
    for ( 0 .. $options{'-trees'} ) {

        # instantiate new tree object
        my $tree = Bio::Phylo::Forest::Tree->new;

        # $i = a counter, $bl = branch length
        my ( $i, $bl ) = 1;

        # generate branch length
        if ( $yule ) {
            $bl = random_exponential( 1, 1 / ( $i + 1 ) );
        }
        elsif ( $hey ) {
            $bl = random_exponential( 1, ( 1 / ( $i * ( $i + 1 ) ) ) );
        }

        # instantiate root node
        my $root = Bio::Phylo::Forest::Node->new(
            -name => 'r',
            -branch_length => 0
        );

        # instantiate left daughter
        my $node1 = Bio::Phylo::Forest::Node->new(
            -name => 'L' . $i,
            -branch_length => $bl,
            -parent => $root
        );

        # instantiate right daughter
        my $node2 = Bio::Phylo::Forest::Node->new(
            -name => 'R' . $i,
            -branch_length => $bl,
            -parent => $root,
            -previous_sister => $node1
        );

        # make connections
        $node1->set_next_sister($node2);
        $root->set_first_daughter($node1);
        $root->set_last_daughter($node2);

        # we now have a basal split, which we insert in
        # the tree object
        $tree->insert($root);
        $tree->insert($node1);
        $tree->insert($node2);

        # there are now two tips from which the tree
        # can grow, we store these in the tip array,
        # from which we well randomly draw a tip
        # for the next split.
        my @tips;
        push @tips, $node1, $node2;

        # start growing the tree
        for my $i ( 2 .. ( $options{'-tips'} - 1 ) ) {

            # generate branch length
            if ( $yule ) {
                $bl = random_exponential( 1, 1 / ( $i + 1 ) );
            }
            elsif ( $hey ) {
                $bl = random_exponential( 1, ( 1 / ( $i * ( $i + 1 ) ) ) );
            }

            # draw a random integer between 0 and
            # the tip array length
            my $j = int rand scalar @tips;

            # dereference to obtain parent of current split
            my $parent = $tips[$j];

            # instantiate left daughter
            $node1 = Bio::Phylo::Forest::Node->new(
                -name => 'L' . $i,
                -branch_length => $bl,
                -parent => $parent
            );

            # instantiate right daughter
            $node2 = Bio::Phylo::Forest::Node->new(
                -name  => 'R' . $i,
                -branch_length => $bl,
                -parent => $parent,
                -previous_sister => $node1
            );

            # make required connections
            $node1->set_next_sister($node2);
            $parent->set_first_daughter($node1);
            $parent->set_last_daughter($node2);

            # insert new nodes in the tree
            $tree->insert($node1);
            $tree->insert($node2);

            # remove parent from tips array
            splice @tips, $j, 1;

            # stretch all tips to the present
            foreach (@tips){
                my $oldbl = $_->get_branch_length;
                $_->set_branch_length($oldbl + $bl);
            }

            # add new nodes to tips array
            push @tips, $node1, $node2;
        }
        $forest->insert($tree);
    }
    return $forest;
}

=item gen_exp_pure_birth()

This method generates a Bio::Phylo::Forest object populated with Yule/Hey trees
whose branch lengths are proportional to the expected waiting times (i.e. not
sampled from a distribution).

 Type    : Generator
 Title   : gen_exp_pure_birth
 Usage   : my $trees = $gen->gen_exp_pure_birth(-tips => 10, -model => 'yule');
 Function: Generates markov tree shapes, with branch lengths following the
           expectation under a user defined model of clade growth, for a
           user defined number of tips.
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
        Bio::Phylo::Exceptions::BadFormat->throw(
            error => "model \"$options{'-model'}\" not implemented"
        );
    }
    my $forest  = Bio::Phylo::Forest->new;
    for ( 0 .. $options{'-trees'} ) {

        # instantiate new tree object
        my $tree = Bio::Phylo::Forest::Tree->new;

        # $i = a counter, $bl = branch length
        my ( $i, $bl ) = 1;

        # generate branch length
        if ( $yule ) {
            $bl = 1 / ( $i + 1 );
        }
        elsif ( $hey ) {
            $bl = 1 / ( $i * ( $i + 1 ) );
        }

        # instantiate root node
        my $root = Bio::Phylo::Forest::Node->new(
            -name => 'r',
            -branch_length => 0
        );

        # instantiate left daughter
        my $node1 = Bio::Phylo::Forest::Node->new(
            -name => 'L' . $i,
            -branch_length => $bl,
            -parent => $root
        );

        # instantiate right daughter
        my $node2 = Bio::Phylo::Forest::Node->new(
            -name => 'R' . $i,
            -branch_length => $bl,
            -parent => $root,
            -previous_sister => $node1
        );

        # make connections
        $node1->set_next_sister($node2);
        $root->set_first_daughter($node1);
        $root->set_last_daughter($node2);

        # we now have a basal split, which we insert in
        # the tree object
        $tree->insert($root);
        $tree->insert($node1);
        $tree->insert($node2);

        # there are now two tips from which the tree
        # can grow, we store these in the tip array,
        # from which we well randomly draw a tip
        # for the next split.
        my @tips;
        push @tips, $node1, $node2;

        # start growing the tree
        for my $i ( 2 .. ( $options{'-tips'} - 1 ) ) {

            # generate branch length
            if ( $yule ) {
                $bl = 1 / ( $i + 1 );
            }
            elsif ( $hey ) {
                $bl = 1 / ( $i * ( $i + 1 ) );
            }

            # draw a random integer between 0 and
            # the tip array length
            my $j = int rand scalar @tips;

            # dereference to obtain parent of current split
            my $parent = $tips[$j];

            # instantiate left daughter
            $node1 = Bio::Phylo::Forest::Node->new(
                -name => 'L' . $i,
                -branch_length => $bl,
                -parent => $parent
            );

            # instantiate right daughter
            $node2 = Bio::Phylo::Forest::Node->new(
                -name  => 'R' . $i,
                -branch_length => $bl,
                -parent => $parent,
                -previous_sister => $node1
            );

            # make required connections
            $node1->set_next_sister($node2);
            $parent->set_first_daughter($node1);
            $parent->set_last_daughter($node2);

            # insert new nodes in the tree
            $tree->insert($node1);
            $tree->insert($node2);

            # remove parent from tips array
            splice @tips, $j, 1;

            # stretch all tips to the present
            foreach (@tips){
                my $oldbl = $_->get_branch_length;
                $_->set_branch_length($oldbl + $bl);
            }

            # add new nodes to tips array
            push @tips, $node1, $node2;
        }
        $forest->insert($tree);
    }
    return $forest;
}

=item gen_equiprobable()

This method draws tree shapes at random, such that all shapes are equally
probable.

 Type    : Generator
 Title   : gen_equiprobable
 Usage   : my $trees = $gen->gen_equiprobable( -tips => 10, -trees => 5 );
 Function: Generates an equiprobable tree shape, with branch lengths = 1;
 Returns : A Bio::Phylo::Forest object.
 Args    : -tips  => number of terminal nodes,
           -trees => number of trees to generate

=cut

sub gen_equiprobable {
    my $random  = shift;
    my %options = @_;
    my $trees   = new Bio::Phylo::Forest;
    for ( 0 .. $options{'-trees'} ) {
        my $tree = new Bio::Phylo::Forest::Tree;
        for my $i ( 1 .. ( $options{'-tips'} + ( $options{'-tips'} - 1 ) ) ) {
            my $node = new Bio::Phylo::Forest::Node;
            $node->set_name("Node$i");
            $node->set_branch_length(1);
            $tree->insert($node);
        }
        my $nodes = $tree->get_entities;
        for my $i ( 1 .. $#{$nodes} ) {
            my $node   = $nodes->[$i];
            my $orphan = 1;
            while ($orphan) {
                my $parent =
                  $nodes->[ int rand ( $options{'-tips'} - 1 ) ];
                unless ( $parent == $node ) {
                    if (   !$parent->get_parent
                        || !$node->is_ancestor_of($parent) )
                    {
                        my $children = 0;
                        for my $j ( 1 .. ( $i - 1 ) ) {
                            if ( $nodes->[$j]->get_parent == $parent ) {
                                $children++;
                            }
                        }
                        if ( $children < 2 ) {
                            $node->set_parent($parent);
                            $orphan = 0;
                        }
                    }
                    else {
                        next;
                    }
                }
            }
        }
        $tree->_analyze;
        $trees->insert($tree);
    }
    return $trees;
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

$Id: Generator.pm,v 1.18 2005/09/29 20:31:17 rvosa Exp $

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
