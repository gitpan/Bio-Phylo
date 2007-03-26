#!/usr/bin/perl
# $Id: age2bl.pl 3388 2007-03-25 23:46:40Z rvosa $
# Subversion: $Rev: 145 $
use strict;
use warnings;
use Bio::Phylo::IO 'parse';
use Pod::Usage;
use Getopt::Long;
use IO::File;

my ( $agefile, $treefile, %ages );

# get options and do quick sanity check
GetOptions(
    'treefile=s' => \$treefile,
    'agefile=s'  => \$agefile,
    'help|?'     => sub { pod2usage(1) },
    'man'        => sub { pod2usage( -verbose => 2 ) },
);
if ( not $treefile or not $agefile ) {
    pod2usage (
        '-msg'     => 'Need --treefile <file> and --agefile <file>',
        '-exitval' => 2,
        '-verbose' => 0
    );
}

# get tree from tree file
my $tree = parse( '-format' => 'newick', '-file' => $treefile )->first;

# populate ages hash: keys are node names, values are ages
{
    my $fh = IO::File->new;
    $fh->open("< $agefile") or die $!;
    my @lines = $fh->getlines;
    for my $line ( @lines ) {
        chomp( $line );
        my @kv = split /\t/, $line;
        $ages{$kv[0]} = $kv[1];
    }
    $fh->close;
}

# we start from the tips and drill deeper
for my $tip ( @{ $tree->get_terminals } ) {
    
    # parent now is from $tip's perspective only one node from present...
    if ( my $parent = $tip->get_parent ) {
        my $parent_name = $parent->get_name;
        my $parent_age = exists $ages{$parent_name}
                         ? $ages{$parent_name}
                         : die "No age for $parent_name!";
        
        # ...hence the age of $parent must be $tip's branch length
        $tip->set_branch_length( $parent_age );
        
        # drill deeper
        while ( $parent ) {
            
            # branch length may have already been calculated from different $tip
            if ( not defined $parent->get_branch_length ) {
                
                # find the longest node-to-tip path for all children...
                my $longest_child_path = 0;
                for my $child ( @{ $parent->get_children } ) {
                    my $maxpath = $child->calc_max_path_to_tips;
                    $longest_child_path = $maxpath if $longest_child_path < $maxpath;
                }
                
                # ...subtract that from $parent's age: it's $parent's branch length
                my $branch_length = $parent_age - $longest_child_path;
                $parent->set_branch_length( $branch_length );
            }
            
            # and deeper
            $parent = $parent->get_parent;
        }
    }
}

print $tree->to_newick;

__END__

=head1 NAME

age2bl.pl - converts node ages to branch lengths.

=head1 SYNOPSIS

=over 4

=item B<perl age2bl.pl>

=over 8

=item B<-treefile> F<<tree file>>

=item B<-agefile>  F<<age file>>

=item [B<-help|-h|-?>]

=item [B<-man>]

=back

=back

=head1 DESCRIPTION

The age2bl program takes a newick tree with labelled nodes, such as
C<((A,B)n1,C)n2;>, and a tab-delimited 'age file', a text file that lists for
all labelled nodes their ages, i.e. distance from present. The first token on
each line should be the node name, the next token the node's age:

 n1      1
 n2      2

The program then traverses the tree and calculates what the branch lengths on
the tree should be. With the input shown here, the output would be as follows:
C<(C:2,(B:1,A:1)n1:1)n2:0;>, i.e. an ultrametric tree where the path lengths
work out to the ages provided in the input.

I (RVOSA) initially wrote this script because I was using I<ape>
(L<http://cran.r-project.org/src/contrib/Descriptions/ape.html>) in which some
analyses produce a list of node ages, and I wanted branch lengths. It is now
provided as part of L<Bio::Phylo> to showcase how to traverse and manipulate
trees using the L<Bio::Phylo> API.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<-treefile> F<<tree file>>

A text file containing at least one newick formatted tree description (first
tree is used).

=item B<-agefile> F<<age file>>

A file containing a table with node ages.

=item B<-h|-help|-?>

Print help message and quit.

=item B<-man>

Print manual page and quit.

=back

=head1 FILES

The program requires a valid newick-formatted tree file and a file containing
node ages, formatted as described above.

=head1 SEE ALSO

Rutger Vos: L<http://search.cpan.org/~rvosa>, L<Bio::Phylo>

=cut
