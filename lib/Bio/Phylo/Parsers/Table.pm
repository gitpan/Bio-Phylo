# $Id: Table.pm 4167 2007-07-11 01:36:38Z rvosa $
# Subversion: $Rev: 194 $
package Bio::Phylo::Parsers::Table;
use strict;
use Bio::Phylo;
use Bio::Phylo::IO;
use Bio::Phylo::Matrices::Matrix;
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Taxa;
use Bio::Phylo::Taxa::Taxon;

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo::IO);

=head1 NAME

Bio::Phylo::Parsers::Table - Parses tab- (or otherwise) delimited matrices. No
serviceable parts inside.

=head1 DESCRIPTION

This module is used to import data and taxa from plain text files or strings.
The following additional argument must be used in the call
to L<Bio::Phylo::IO|Bio::Phylo::IO>:

 -type => (one of [DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS])

In addition, these arguments may be used to indicate line separators (default
is "\n") and field separators (default is "\t"):

 -fieldsep => '\t',
 -linesep  => '\n'

=begin comment

 Type    : Constructor
 Title   : new
 Usage   : my $table = new Bio::Phylo::Parsers::Table;
 Function: Initializes a Bio::Phylo::Parsers::Table object.
 Returns : A Bio::Phylo::Parsers::Table object.
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

 Type    : parser
 Title   : from_handle(%options)
 Usage   : $table->_from_handle(%options);
 Function: Extracts data from file, populates matrix object
 Returns : A Bio::Phylo::Matrices::Matrix object.
 Args    : -handle   => (\*FH),
           -fieldsep => (record separator)
           -linesep  => (line separator)
           -type     => (data type)
 Comments:

=end comment

=cut

*_from_handle = \&_from_both;
*_from_string = \&_from_both;

sub _from_both {
    my $self   = shift;
    my %opts   = @_;
    my $matrix = Bio::Phylo::Matrices::Matrix->new(
        '-type' => $opts{'-type'},
    );
    my $taxa   = Bio::Phylo::Taxa->new;
    $taxa->set_matrix($matrix);
    $matrix->set_taxa($taxa);
    my ( $fieldre, $linere );

    if ( $opts{'-fieldsep'} ) {
        if ( $opts{'-fieldsep'} =~ /^\b$/ ) {
            $fieldre = qr/$opts{'-fieldsep'}/;
        }
        else {
            $fieldre = qr/\Q$opts{'-fieldsep'}/;
        }
    }
    else {
        $fieldre = qr/\t/;
    }
    if ( $opts{'-linesep'} ) {
        if ( $opts{'-linesep'} =~ /^\b$/ ) {
            $linere = qr/$opts{'-linesep'}/;
        }
        else {
            $linere = qr/\Q$opts{'-linesep'}/;
        }
    }
    else {
        $linere = qr/\n/;
    }
    if ( $opts{'-handle'} ) {
        while ( readline( $opts{'-handle'} ) ) {
            chomp;
            my @temp = split( $fieldre, $_ );
            my $taxon = Bio::Phylo::Taxa::Taxon->new( '-name' => $temp[0], );
            $taxa->insert($taxon);
            my $datum = Bio::Phylo::Matrices::Datum->new(
                '-name'  => $temp[0],
                '-type'  => uc $opts{'-type'},
                '-char'  => [ @temp[ 1, -1 ] ],
            );
            $datum->set_taxon($taxon);
            $taxon->set_data($datum);
            $matrix->insert($datum);
        }
    }
    elsif ( $opts{'-string'} ) {
        foreach my $line ( split( $linere, $opts{'-string'} ) ) {
            my @temp = split( $fieldre, $line );
            my $taxon = Bio::Phylo::Taxa::Taxon->new( '-name' => $temp[0], );
            $taxa->insert($taxon);
            my $datum = Bio::Phylo::Matrices::Datum->new(
                '-name' => $temp[0],
                '-type' => uc $opts{'-type'},
                '-char' => [ @temp[ 1 .. $#temp ] ],
            );
            $datum->set_taxon($taxon);
            $taxon->set_data($datum);
            $matrix->insert($datum);
        }
    }
    return $matrix;
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The table parser is called by the L<Bio::Phylo::IO|Bio::Phylo::IO> object.
Look there to learn how to parse tab- (or otherwise) delimited matrices.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual|Bio::Phylo::Manual>.

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

$Id: Table.pm 4167 2007-07-11 01:36:38Z rvosa $

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
