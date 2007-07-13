# $Id: Newick.pm 4198 2007-07-12 16:45:08Z rvosa $
# Subversion: $Rev: 190 $
package Bio::Phylo::Unparsers::Newick;
use strict;
use Bio::Phylo::Forest::Tree;
use Bio::Phylo::IO;

use vars '@ISA';
@ISA=qw(Bio::Phylo::IO);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Unparsers::Newick - Unparses newick trees. No serviceable parts
inside.

=head1 DESCRIPTION

This module turns a tree object into a newick formatted (parenthetical) tree
description. It is called by the L<Bio::Phylo::IO> facade, don't call it
directly. You can pass the following additional arguments to the unparse
call:
	
	# by default, names for tips are derived from $node->get_name, if 
	# 'internal' is specified, uses $node->get_internal_name, if 'taxon'
	# uses $node->get_taxon->get_name, if 'taxon_internal' uses 
	# $node->get_taxon->get_internal_name, if $key, uses $node->get_generic($key)
	-tipnames => one of (internal|taxon|taxon_internal|$key)
	
	# for things like a translate table in nexus, or to specify truncated
	# 10-character names, you can pass a translate mapping as a hashref.
	# to generate the translated names, the strings obtained following the
	# -tipnames rules are used.
	-translate => { Homo_sapiens => 1, Pan_paniscus => 2 }	
	
	# array ref used to specify keys, which are embedded as key/value pairs (where
	# the value is obtained from $node->get_generic($key)) in comments, 
	# formatted depending on '-nhxstyle', which could be 'nhx' (default), i.e.
	# [&&NHX:$key1=$value1:$key2=$value2] or 'mesquite', i.e. 
	# [% $key1 = $value1, $key2 = $value2 ]
	-nhxkeys => [ $key1, $key2 ]	
	
	# if set, appends labels to internal nodes (names obtained from the same
	# source as specified by '-tipnames')
	-nodelabels => 1
	
	# specifies a formatting style / dialect
	-nhxstyle => one of (mesquite|nhx)
	
	# specifies a branch length sprintf number formatting template, default is %f
	-blformat => '%e'

=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $newick = Bio::Phylo::Unparsers::Newick->_new;
 Function: Initializes a Bio::Phylo::Unparsers::Newick object.
 Returns : A Bio::Phylo::Unparsers::Newick object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = shift;
    my $self  = {};
    if (@_) {
        my %opts = @_;
        foreach my $key ( keys %opts ) {
            my $localkey = uc $key;
            $localkey =~ s/-//;
            unless ( ref $opts{$key} ) {
                $self->{$localkey} = uc $opts{$key};
            }
            else {
                $self->{$localkey} = $opts{$key};
            }
        }
    }
    bless $self, $class;
    return $self;
}

=begin comment

 Type    : Wrapper
 Title   : _to_string($tree)
 Usage   : $newick->_to_string($tree);
 Function: Prepares for the recursion to unparse the tree object into a
           newick string.
 Alias   :
 Returns : SCALAR
 Args    : Bio::Phylo::Forest::Tree

=end comment

=cut

sub _to_string {
    my $self = shift;
    my $tree = $self->{'PHYLO'};
    my $root = $tree->get_root;
    my %args;
    if ( $self->{'TRANSLATE'} ) {
    	$args{'-translate'} = $self->{'TRANSLATE'};
    }
    if ( $self->{'TIPNAMES'} ) {
    	$args{'-tipnames'} = $self->{'NAMES'};
    }
    if ( $self->{'NHXKEYS'} ) {
    	$args{'-nhxkeys'} = $self->{'NHXKEYS'};
    }
    if ( $self->{'NODELABELS'} ) {
    	$args{'-nodelabels'} = $self->{'NODELABELS'}; 
    }
    if ( $self->{'BLFORMAT'} ) {
    	$args{'-blformat'} = $self->{'BLFORMAT'}; 
    }   
    if ( $self->{'NHXSTYLE'} ) {
    	$args{'-nhxstyle'} = $self->{'NHXSTYLE'};
    } 
    return $root->to_newick( %args );
}

=begin comment

 Type    : Unparser
 Title   : __to_string
 Usage   : $newick->__to_string($tree, $node);
 Function: Unparses the tree object into a newick string.
 Alias   :
 Returns : SCALAR
 Args    : A Bio::Phylo::Forest::Tree object. Optional: A Bio::Phylo::Forest::Node
           object, the starting point for recursion.

=end comment

=cut

{
    my $string = q{};
    no warnings 'uninitialized';

    sub __to_string {
        my ( $self, $tree, $n ) = @_;
        if ( !$n->get_parent ) {
            if ( defined $n->get_branch_length ) {
                $string = $n->get_name . ':' . $n->get_branch_length . ';';
            }
            else {
                $string = $n->get_name ? $n->get_name . ';' : ';';
            }
        }
        elsif ( !$n->get_previous_sister ) {
            if ( defined $n->get_branch_length ) {
                $string = $n->get_name . ':' . $n->get_branch_length . $string;
            }
            else { $string = $n->get_name . $string; }
        }
        else {
            if ( defined $n->get_branch_length ) {
                $string =
                  $n->get_name . ':' . $n->get_branch_length . ',' . $string;
            }
            else { $string = $n->get_name . ',' . $string; }
        }
        if ( $n->get_first_daughter ) {
            $n      = $n->get_first_daughter;
            $string = ')' . $string;
            $self->__to_string( $tree, $n );
            while ( $n->get_next_sister ) {
                $n = $n->get_next_sister;
                $self->__to_string( $tree, $n );
            }
            $string = '(' . $string;
        }
    }
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The newick unparser is called by the L<Bio::Phylo::IO> object.
Look there to learn how to unparse newick strings.

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

$Id: Newick.pm 4198 2007-07-12 16:45:08Z rvosa $

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
