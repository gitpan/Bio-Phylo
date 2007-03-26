#!/usr/bin/perl
# $Id: droptip.pl 3388 2007-03-25 23:46:40Z rvosa $
# Subversion: $Rev: 145 $
# This script is used to create a subtree from a larger tree. The first
# command line argument is the path to a text file containing a single
# newick tree. The second command line argument is the path to a text
# file containing a list of taxa to keep.
#
# usage:
# perl droptip.pl <tree file> <taxa file>
use strict;
use warnings;
use Bio::Phylo::IO 'parse';
use IO::File;
use Pod::Usage;

my ( $treefile, $taxafile ) = @ARGV;
pod2usage(2) if not $treefile or not $taxafile;
pod2usage(1) if $treefile =~ /(?:-h|-\?)/ or $taxafile =~ /(?:-h|-\?)/ or @ARGV;

my $tree = parse( '-format' => 'newick',  '-file' => $treefile )->first;
my $taxa = parse( '-format' => 'taxlist', '-file' => $taxafile );

$tree->prune_tips( $taxa );
print $tree->to_newick;

__END__

=head1 NAME

droptip.pl - prunes a list of tips from input tree.

=head1 SYNOPSIS

=over

=item B<perl droptip.pl>

F<<tree file>>
F<<taxa file>>

=back

=head1 DESCRIPTION

The droptip.pl program prunes the taxa listed in F<<taxa file>> from the tree
specified (as a newick tree) in F<<tree file>>. I (RVOSA) needed just such an
operation to be performed somewhere in a work flow I was setting up. Using the
L<Bio::Phylo> libraries this was trivial, and so now this script is mostly meant
to illustrate some of the functionality of the libraries.

=head1 OPTIONS AND ARGUMENTS

=over

=item F<<tree file>>

A text file containing at least one newick formatted tree description (first
tree is used).

=item F<<taxa file>>

A list of taxa to prune from the tree, one taxon name per line.

=item C<-h|-help|-?>

Print help message and quit.

=back

=head1 FILES

The program requires a valid newick-formatted tree file and a file containing
taxon names, one name per line.

=head1 SEE ALSO

Rutger Vos: L<http://search.cpan.org/~rvosa>

=cut
