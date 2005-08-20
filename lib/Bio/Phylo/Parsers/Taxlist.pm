# $Id: Taxlist.pm,v 1.7 2005/08/11 19:41:13 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Parsers::Taxlist;
use strict;
use warnings;
use Bio::Phylo;
use Bio::Phylo::Taxa;
use Bio::Phylo::Taxa::Taxon;
use base 'Bio::Phylo::Parsers';

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

Bio::Phylo::Parsers::Taxlist - A library for parsing plain text tables.

=head1 SYNOPSIS

 my $taxlist = new Bio::Phylo::Parsers::Taxlist;
 my $taxa = $taxlist->parse(
        -file => 'data.dat',
        );

=head1 DESCRIPTION

This module is used for importing sets of taxa, from a plain text file, one
taxon on each line.

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $taxlist = new Bio::Phylo::Parsers::Taxlist;
 Function: Initializes a Bio::Phylo::Parsers::Taxlist object.
 Returns : A Bio::Phylo::Parsers::Taxlist object.
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
 Usage   : $taxlist->from_handle(%options);
 Function: Reads taxon names from file, populates taxa object
 Returns : A Bio::Phylo::Taxa object.
 Args    : -handle => (\*FH), -file => (filename)
 Comments:

=cut

sub from_handle {
    my $self    = shift;
    my %opts    = @_;
    my $taxa    = new Bio::Phylo::Taxa;
    my $version = $self->VERSION;
    while ( readline( $opts{-handle} ) ) {
        chomp;
        if ($_) {
            my $taxon       = new Bio::Phylo::Taxa::Taxon;
            my $date        = localtime;
            my $description =
              qq{Read from $opts{-file} using Phylo version $version on $date};
            $taxon->set_name($_);
            $taxon->set_desc($description);
            $taxa->insert($taxon);
        }
    }
    return $taxa;
}

=back

=head2 CONTAINER

=over

=item container

 Type    : Internal method
 Title   : container
 Usage   : $taxlist->container;
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
 Usage   : $taxlist->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'TAXLIST';
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
