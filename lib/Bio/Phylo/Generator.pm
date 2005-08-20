# $Id: Generator.pm,v 1.7 2005/08/11 19:41:12 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Generator;
use strict;
use warnings;
use Bio::Phylo::Trees;
use Bio::Phylo::Trees::Tree;
use Bio::Phylo::Trees::Node;
use Math::Random qw(random_exponential);
use base 'Bio::Phylo';

# One line so MakeMaker sees it.
use Bio::Phylo;  our $VERSION = $Bio::Phylo::VERSION;

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 148 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
$VERSION .= '_' . $rev;
use vars qw($VERSION);

my $VERBOSE = 1;

=head1 NAME

Bio::Phylo::Generator - An object-oriented module for generating random
objects (phylogenetic trees, nodes).

=head1 SYNOPSIS

 use Bio::Phylo::Generator;
 my $random = new Bio::Phylo::Generator;

=head1 DESCRIPTION

The generator module is used to simulate trees under the Yule, Hey, or
equiprobable model.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $gen = new Bio::Phylo::Generator;
 Function: Initializes a Bio::Phylo::Generator object.
 Returns : A Bio::Phylo::Generator object.
 Args    : none.

=cut

sub new {
    my $class = $_[0];
    my $self  = {};
    bless( $self, $class );
    return $self;
}

=back

=head2 GENERATOR

=over

=item gen_rand_pure_birth(%options)

This method generates a Bio::Phylo::Trees object populated with Yule/Hey trees.

 Type    : Generator
 Title   : gen_rand_pure_birth
 Usage   : $gen->gen_rand_pure_birth(-tips => 10, -model => 'yule');
 Function: Generates markov tree shapes, with branch lengths sampled from
           a user defined model of clade growth, for a user defined
           number of tips.
 Returns : A Bio::Phylo::Trees object.
 Args    : -tips = number of terminal nodes,
           -model = either 'yule' or 'hey',
           -trees = number of trees to generate

=cut

sub gen_rand_pure_birth {
    my $random  = shift;
    my %options = @_;
    my $trees   = new Bio::Phylo::Trees;
    for ( 0 .. $options{'-trees'} ) {
        my ( $tree, $node ) =
          ( new Bio::Phylo::Trees::Tree, new Bio::Phylo::Trees::Node );
        $node->set_name("root");
        $node->set_branch_length(0);
        $tree->insert($node);
        for my $i ( 1 .. ( $options{'-tips'} - 1 ) ) {
            my $bl;
            if ( $options{'-model'} =~ m/yule/i ) {
                $bl = random_exponential( 1, 1 / ( $i + 1 ) );
            }
            elsif ( $options{'-model'} =~ m/hey/i ) {
                $bl = random_exponential( 1, ( 1 / ( $i * ( $i + 1 ) ) ) );
            }
            else {
                $random->COMPLAIN(
                    "model \"$options{'-model'}\" not implemented: $@");
                return;
            }
            my ( $node1, $node2 ) =
              ( new Bio::Phylo::Trees::Node, new Bio::Phylo::Trees::Node );
            $node1->set_name("R$i");
            $node1->set_branch_length($bl);
            $node2->set_name("L$i");
            $node2->set_branch_length($bl);
            my $orphan = 1;
            while ($orphan) {
                my $nodes = $tree->get_terminals;
                my $j     = int( rand($i) );
                $node1->set_parent( $nodes->[$j] );
                $node2->set_parent( $nodes->[$j] );
                $tree->insert($node1);
                $tree->insert($node2);
                $tree->_analyze;
                $tree->ultrametricize;
                $orphan = 0;
            }
        }
        $trees->insert($tree);
    }
    return $trees;
}

=item gen_exp_pure_birth(%options)

This method generates a Bio::Phylo::Trees object populated with Yule/Hey trees
whose branch lengths are proportional to the expected waiting times (i.e. not
sampled from a distribution).

 Type    : Generator
 Title   : gen_exp_pure_birth
 Usage   : $gen->gen_exp_pure_birth(-tips => 10, -model => 'yule');
 Function: Generates markov tree shapes, with branch lengths following the
           expectation under a user defined model of clade growth, for a
           user defined number of tips.
 Returns : A Bio::Phylo::Trees object.
 Args    : -tips = number of terminal nodes,
           -model = either 'yule' or 'hey'
           -trees = number of trees to generate

=cut

sub gen_exp_pure_birth {
    my $random  = shift;
    my %options = @_;
    my $trees   = new Bio::Phylo::Trees;
    for ( 0 .. $options{'-trees'} ) {
        my ( $tree, $node ) =
          ( new Bio::Phylo::Trees::Tree, new Bio::Phylo::Trees::Node );
        $node->set_name("root");
        $node->set_branch_length(0);
        $tree->insert($node);
        for my $i ( 1 .. ( $options{'-tips'} - 1 ) ) {
            my $bl;
            if ( $options{'-model'} =~ m/yule/i ) {
                $bl = 1 / ( $i + 1 );
            }
            elsif ( $options{'-model'} =~ m/hey/i ) {
                $bl = 1 / ( $i * ( $i + 1 ) );
            }
            else {
                $random->COMPLAIN(
                    "model \"$options{'-model'}\" not implemented: $@");
                return;
            }
            my ( $node1, $node2 ) =
              ( new Bio::Phylo::Trees::Node, new Bio::Phylo::Trees::Node );
            $node1->set_name("R$i");
            $node1->set_branch_length($bl);
            $node2->set_name("L$i");
            $node2->set_branch_length($bl);
            my $orphan = 1;
            while ($orphan) {
                my $nodes = $tree->get_terminals;
                my $j     = int( rand($i) );
                $node1->set_parent( $nodes->[$j] );
                $node2->set_parent( $nodes->[$j] );
                $tree->insert($node1);
                $tree->insert($node2);
                $tree->_analyze;
                $tree->ultrametricize;
                $orphan = 0;
            }
        }
        $trees->insert($tree);
    }
    return $trees;
}

=item gen_equiprobable(%options)

This method draws tree shapes at random, such that all shapes are equally
probable.

 Type    : Generator
 Title   : gen_equiprobable
 Usage   : $gen->gen_equiprobable(-tips => 10, -trees => 5);
 Function: Generates an equiprobable tree shape, with branch lengths = 1;
 Returns : A Bio::Phylo::Trees object.
 Args    : -tips = number of terminal nodes,
           -trees = number of trees to generate

=cut

sub gen_equiprobable {
    my $random  = shift;
    my %options = @_;
    my $trees   = new Bio::Phylo::Trees;
    for ( 0 .. $options{'-trees'} ) {
        my $tree = new Bio::Phylo::Trees::Tree;
        for my $i ( 1 .. ( $options{'-tips'} + ( $options{'-tips'} - 1 ) ) ) {
            my $node = new Bio::Phylo::Trees::Node;
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
                  $nodes->[ int( rand( ( $options{'-tips'} - 1 ) ) ) ];
                unless ( $parent == $node ) {
                    if (   !$parent->get_parent
                        || !$node->is_ancestor_of($parent) )
                    {
                        my $children = 0;
                        for my $j ( 1 .. ( $i - 1 ) ) {
                            $children++ if $nodes->[$j]->get_parent == $parent;
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

=head2 CONTAINER

=over

=item container

 Type    : Internal method
 Title   : container
 Usage   : $generator->container;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container {
    return 'NONE';
}

=item container_type

 Type    : Internal method
 Title   : container_type
 Usage   : $generator->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'GENERATOR';
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>
L<http://www.sfu.ca/~rvosa/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

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
