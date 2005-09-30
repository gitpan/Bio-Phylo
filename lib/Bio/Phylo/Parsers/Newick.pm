# $Id: Newick.pm,v 1.22 2005/09/29 20:31:18 rvosa Exp $
# Subversion: $Rev: 196 $
package Bio::Phylo::Parsers::Newick;
use strict;
use warnings;
use Bio::Phylo::Forest;
use Bio::Phylo::Forest::Tree;
use Bio::Phylo::Forest::Node;
use base 'Bio::Phylo::IO';

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

*_from_handle = \&_from_both;
*_from_string = \&_from_both;

=head1 NAME

Bio::Phylo::Parsers::Newick - Parses newick trees. No serviceable parts
inside.

=head1 DESCRIPTION

This module parses tree descriptions in parenthetical format. It is called by
the L<Bio::Phylo::IO> facade, don't call it directly.

=begin comment

 Type    : Constructor
 Title   : new
 Usage   : my $newick = new Bio::Phylo::Parsers::Newick;
 Function: Initializes a Bio::Phylo::Parsers::Newick object.
 Returns : A Bio::Phylo::Parsers::Newick object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = $_[0];
    my $self  = {};
    bless( $self, $class );
    return $self;
}

=begin comment

 Type    : Wrapper
 Title   : from_both(%options)
 Usage   : $newick->from_both(%options);
 Function: Extracts trees from file, sends strings to _parse_string()
 Returns : Bio::Phylo::Forest
 Args    : -handle => (\*FH) or -string => (scalar).
 Comments:

=end comment

=cut

sub _from_both {
    my $self  = shift;
    my %args  = @_;
    my $trees = Bio::Phylo::Forest->new;
    if ( $args{'-handle'} ) {
        my $string;
        while ( readline( $args{-handle} ) ) {
            chomp;
            s/\s//g;
            $string .= $_;
            if ( $string =~ m/^(.+;)(.*)$/ ) {
                $trees->insert( $self->_parse_string($1) );
                $string = $2;
            }
        }
    }
    if ( $args{'-string'} ) {
        foreach ( split( /;/, $args{'-string'} ) ) {
            chomp;
            s/\s//g;
            my $tree = $_ . ';';
            $trees->insert( $self->_parse_string($tree) );
        }
    }
    return $trees;
}

=begin comment

 Type    : Parser
 Title   : _parse_string($string)
 Usage   : my $tree = $newick->_parse_string($string);
 Function: Creates a populated Bio::Phylo::Forest::Tree object from a newick
           string.
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : $string = a newick tree description

=end comment

=cut

sub _parse_string {
    my ( $self, $string ) = @_;
    my $tree = Bio::Phylo::Forest::Tree->new;
    $string = $self->_nodelabels($string);
    foreach ( grep ( /\w/, split( /[\(|,|\)|;]+/o, $string ) ) ) {
        my $node;
        if (/^(.+):\s*(-?\d+\.?\d*e?[-|+]?\d*)$/oi) {
            $node = Bio::Phylo::Forest::Node->new(
                -name          => $1,
                -branch_length => $2
            );
        }
        else {
            $node = Bio::Phylo::Forest::Node->new(
                -name => $_,
            );
        }
        $tree->insert($node);
    }
    for my $i ( 0 .. $tree->last_index ) {
        my $node = $tree->get_by_index($i);
        my ( $st, $depth, $name ) = ( $string, 0, $node->get_name );
        $st =~ s/^.*[,|\)|\(]$name([,|:|\)|;].*)$/$1/;
        for my $x ( 0 .. length($st) ) {
            if ( substr( $st, $x, 1 ) eq ')' || substr( $st, $x, 1 ) eq ';' ) {
                $depth--;
            }
            if ( substr( $st, $x, 1 ) eq '(' ) {
                $depth++;
            }
            if ( $depth == -1 ) {
                $st = substr( $st, $x++ );
                last;
            }
        }
        $st =~ s/^\)(.+?)[:|,|;|\)].*$/$1/;
        for my $j ( ( $i + 1 ) .. $tree->last_index ) {
            my $p = $tree->get_by_index($j);
            if ( $p->get_name eq $st ) {
                $node->set_parent($p);
                last;
            }
        }
    }
    $tree->_analyze;
    return $tree;
}

=begin comment

 Type    : Internal method.
 Title   : _nodelabels($string)
 Usage   : my $labelled = $newick->_nodelabels($string);
 Function: Returns a newick string with labelled nodes
 Returns : SCALAR
 Args    : $string = a newick tree description

=end comment

=cut

sub _nodelabels {
    my ( $self, $string ) = @_;
    my ( $x, @x );
    while ( $string =~ /\)[:|,|;|\)]/o ) {
        foreach ( split( /[:|,|;|\)]/o, $string ) ) {
            if ( /n([0-9]+)/ ) {
                push( @x, $1 );
            }
        }
        @x = sort { $a <=> $b } @x;
        $x = $x[-1];
        $string =~ s/(\))([:|,|;|\)])/$1.'n'.++$x.$2/ose;
    }
    return $string;
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The newick parser is called by the L<Bio::Phylo::IO> object.
Look there to learn how to parse newick strings.

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

$Id: Newick.pm,v 1.22 2005/09/29 20:31:18 rvosa Exp $

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
