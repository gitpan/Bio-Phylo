#!/usr/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use Bio::Phylo::IO 'parse';

my ( $verbose, $nexus, $treefile, $string );

sub check_args {
    Getopt::Long::GetOptions (
        "treefile=s" => \$treefile,
        "string=s"   => \$string,
        "nexus"      => \$nexus,
        "verbose"    => \$verbose,
        "help|?"     => sub { pod2usage(1) },
        "man"        => sub { pod2usage( -verbose => 2 ) },
    );
    if (@ARGV) {
        pod2usage (
            -msg     => "Invalid argument(s): @ARGV",
            -exitval => 1,
            -verbose => 0
        );
    }
    if ( not $treefile and not $string ) {
        pod2usage (
            -msg     => "No input, no output!",
            -exitval => 2,
            -verbose => 0
        );
    }
    print STDERR "Sane command line arguments supplied.\n" if $verbose;
    print STDERR "File name supplied: $treefile\n" if $verbose and $treefile;
    print STDERR "String supplied: $string\n" if $verbose and $string;
}

sub parse_file_or_string {
    my %args = @_;
    print STDERR "Going to parse %args\n" if $verbose;
    return parse( -format => 'newick', %args );
}

sub main ($$$) {
    my ( $infile, $string, $nexus ) = @_;
    my $trees = defined $infile
                    ? parse_file_or_string( -file   => $infile )
                    : parse_file_or_string( -string => $string );
    for my $tree ( @{ $trees->get_entities } ) {
        for my $node ( @{ $tree->get_entities } ) {
            $node->set_name( $node->get_internal_name );
        }
    }
    if ( $nexus ) {
        print "#NEXUS\n";
        print "BEGIN TREES;\n";
    }
    my $i = 0;
    for my $tree ( @{ $trees->get_entities } ) {
        print 'TREE TREE', ++$i, ' = ' if $nexus;
        print $tree->to_newick, "\n";
    }
    if ( $nexus ) {
        print "END;\n";
    }
}

check_args;
main( $treefile, $string, $nexus );

__END__

=head1 NAME

dndtag.pl - applies unique node labels to newick trees.

=head1 SYNOPSIS

=over

=item B<perl dndtag.pl>

[B<-t|--treefile> F<<tree file>>]
[B<-s|--string> C<'newick string'>]
[B<-n|--nexus>]
[B<-v|--verbose>]
[B<-h|--help>]
[B<-m|--man>]

=back

=head1 DESCRIPTION

The dndtag.pl program applies node labels to newick trees:

    ((A,B),C); --> ((A,B)Node1,C)Node2;

The node labels are unique per tree. Already existing node labels are
left in place. The output is written to standard out.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<-t|--treefile> F<<tree file>>

A text file containing newick formatted tree descriptions.

=item B<-s|--string> C<'newick string'>

A tree string, i.e. a parenthetical statement, possibly shell-escaped (e.g. on
/bin/bash, this statement needs to be single quoted, on windows cmd double
quoted).

=item B<-n|--nexus>

Output printed in nexus format.

=item B<-h|--help|-?>

Returns this help message.

=item B<-v|--verbose>

Verbose mode yields (a few) more messages.

=item B<-m|--man>

Opens the full documentation in perldoc format.

=back

=head1 SUBROUTINES

=head2 check_args

Parameters:
    none

Checks command line arguments for sanity.

=head2 parse_file

Parameters:
    infile

Parses the provided input file.

=head2 main

Parameters:
    infile

Calls the other subroutines.

=head1 EXIT STATUS

The following exit values are returned:

0   All input files were processed successfully.

1   Invalid command line arguments.

2   No input file specified.

=head1 FILES

The program requires either a newick string or a valid newick-formatted tree
file issued after the I<--treefile> command line argument.

=head1 SEE ALSO

Rutger Vos: L<http://search.cpan.org/~rvosa>

=head1 WARNINGS

=over

=item I<Unknown option: ...>

Meaning:
    Command line arguments where supplied that aren't recognized
    by the program.

=item I<No input, no output!>

Meaning:
    Apparently, no input file name or string was specified.

=back

=cut
