#!/usr/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use Bio::Phylo::Parsers 0.02;
use Bio::Phylo::Unparsers 0.02;

my ( $verbose, $man, $help, $nexus, $tree ) = ( 0, 0, 0, 0 );

sub check_args {
    Getopt::Long::GetOptions (
        "treefile=s" => \$tree,
        "nexus"      => \$nexus,
        "verbose"    => \$verbose,
        "help|?"     => \$help,
        "man"        => \$man );
    pod2usage(1) if $help;
    pod2usage( -verbose => 2 ) if $man;
    if (@ARGV) {
        Pod::Usage::pod2usage (
            -msg     => "Invalid argument(s): @ARGV",
            -exitval => 1,
            -verbose => 0 );
    }
    unless ( $tree ) {
        Pod::Usage::pod2usage (
            -msg     => "No input, no output!",
            -exitval => 2,
            -verbose => 0 );
    }
    print STDERR "Sane command line arguments supplied.\n" if $verbose;
    print STDERR "File name supplied: $tree\n" if $verbose;
}

sub parse_file ($) {
    my $infile = shift;
    print STDERR "Going to parse $infile\n" if $verbose;
    my $parser = new Bio::Phylo::Parsers;
    return $parser->parse( -format => 'newick', -file => $infile );
    print STDERR "Successfully parsed $infile\n" if $verbose;
}

sub main ($) {
    my $infile = shift;
    my $trees = parse_file $infile;
    if ( $nexus ) {
        print "#NEXUS\n";
        print "BEGIN TREES;\n";
    }
    my ( $i, $unparser ) = ( 1, new Bio::Phylo::Unparsers );
    foreach my $tree ( @{$trees->get_entities} ) {
        print "TREE TREE$i = " if $nexus;
        print $unparser->unparse( -format => 'newick', -phylo => $tree ), "\n";
        $i++;
    }
    if ( $nexus ) {
        print "END;\n";
    }
}

check_args;
main $tree;

__END__

=head1 NAME

dndtag.pl - applies unique node labels to newick trees.

=head1 SYNOPSIS

=over

=item B<perl dndtag.pl>

[B<-t|--treefile> F<<tree file>>]
[B<-n|--nexus>]
[B<-v|--verbose>]
[B<-h|--help>]
[B<-m|--man>]

=back

=head1 DESCRIPTION

The dndtag.pl program applies node labels to newick trees:

    ((A,B),C); --> ((A,B)n1,C)n2;

The node labels are unique per tree. Already existing node labels are
left in place. The output is written to standard out.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<-t|--treefile> F<<tree file>>

A text file containing newick formatted tree descriptions.

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

The program requires a valid newick-formatted tree file issued
after the I<--treefile> command line argument.

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
    Apparently, no input file name was specified.

=back

=cut
