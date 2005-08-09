# $Id: Table.pm,v 1.6 2005/08/09 12:36:13 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Parsers::Table;
use strict;
use warnings;
use Bio::Phylo;
use Bio::Phylo::Matrices::Matrix;
use Bio::Phylo::Matrices::Datum;
use base 'Bio::Phylo::Parsers';

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 148 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.03';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);

=head1 NAME

Bio::Phylo::Parsers::Table - A library for parsing plain text tables.

=head1 SYNOPSIS

 my $table = new Bio::Phylo::Parsers::Table;
 my $matrix = $table->parse(
        -file => 'data.dat',
        -type => 'STANDARD',
        -separator => '\t'
        );

=head1 DESCRIPTION

This module is used to import data and taxa, from a plain text file, such as
a tab-delimited file.

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $table = new Bio::Phylo::Parsers::Table;
 Function: Initializes a Bio::Phylo::Parsers::Table object.
 Returns : A Bio::Phylo::Parsers::Table object.
 Args    : none.

=cut

sub new {
    my $class = $_[0];
    my $self  = {};
    bless( $self, $class );
    return $self;
}

=back

=head2 PARSER

=over

=item from_handle(%options)

 Type    : parser
 Title   : from_handle(%options)
 Usage   : $table->from_handle(%options);
 Function: Extracts data from file, populates matrix object
 Returns : A Bio::Phylo::Matrices::Matrix object.
 Args    : -handle => (\*FH), -separator => (record separator)
 Comments:

=cut

sub from_handle {
    my $self    = shift;
    my %opts    = @_;
    my $matrix  = new Bio::Phylo::Matrices::Matrix;
    my $date    = localtime;
    my $version = $self->VERSION;
    while ( readline( $opts{-handle} ) ) {
        chomp;
        my @temp = split( /$opts{-separator}/, $_ );
        for my $i ( 1 .. $#temp ) {
            my $datum = new Bio::Phylo::Matrices::Datum;
            $datum->set_name( $temp[0] );
            $datum->set_type( uc( $opts{'-type'} ) );
            my $description =
qq{$opts{'-type'} character number $i read from $opts{-file} on $date by Phylo $version};
            $datum->set_desc($description);
            $datum->set_weight(1);
            $datum->set_char( $temp[$i] );
            $datum->set_position($i);
            $matrix->insert($datum);
        }
    }
    return $matrix;
}

=back

=head2 CONTAINER

=over

=item container

 Type    : Internal method
 Title   : container
 Usage   : $table->container;
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
 Usage   : $table->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'TABLE';
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>
L<http://www.sfu.ca/~rvosa/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed
from BioPerl L<http://www.bioperl.org>, and CIPRES
L<http://www.phylo.org> and FAB* L<http://www.sfu.ca/~fabstar>
for comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
