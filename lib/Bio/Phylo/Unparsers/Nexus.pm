# $Id: Nexus.pm 3292 2007-03-17 16:52:08Z rvosa $
# Subversion: $Rev: 190 $
package Bio::Phylo::Unparsers::Nexus;
use strict;
use Bio::Phylo::IO;

use vars '@ISA';
@ISA=qw(Bio::Phylo::IO);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Unparsers::Nexus - Unparses nexus matrices. No serviceable parts
inside.

=head1 DESCRIPTION

This module turns a L<Bio::Phylo::Matrices::Matrix> object into a nexus
formatted matrix. It is called by the L<Bio::Phylo::IO> facade, don't call it
directly.

=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $nex = Bio::Phylo::Unparsers::Nexus->_new;
 Function: Initializes a Bio::Phylo::Unparsers::Nexus object.
 Returns : A Bio::Phylo::Unparsers::Nexus object.
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
 Title   : _to_string($matrix)
 Usage   : $nexus->_to_string($matrix);
 Function: Stringifies a matrix object into
           a nexus formatted table.
 Alias   :
 Returns : SCALAR
 Args    : Bio::Phylo::Matrices::Matrix;

=end comment

=cut

sub _to_string {
    my $self   = shift;
    my $matrix = $self->{'PHYLO'};
    my $string = "BEGIN DATA;\n[! Data block written by " . ref $self;
    $string .= " " . $self->VERSION . " on " . localtime() . " ]\n";
    $string .= "    DIMENSIONS NTAX=" . $matrix->get_ntax() . ' ';
    $string .= 'NCHAR=' . $matrix->get_nchar() . ";\n";
    $string .= "    FORMAT DATATYPE=" . $matrix->get_type();
    #$string .= $matrix->get_respectcase ? " RESPECTCASE" : "";
    $string .= " MATCHCHAR=" . $matrix->get_matchchar if $matrix->get_matchchar;
    $string .= " MISSING=" . $matrix->get_missing();
    $string .= " GAP=" . $matrix->get_gap() if $matrix->get_gap();
    $string .= ";\n";
    $string .= "    OPTIONS GAPMODE=";
    $string .= $matrix->get_gapmode ? "NEWSTATE " : "MISSING ";
    $string .= $matrix->get_polymorphism ? "MSTAXA=POLYMORPH;\n" : "MSTAXA=UNCERTAIN;\n";
    my $charlabels;
    if ( @{ $matrix->get_charlabels } ) {
    	for my $label ( @{ $matrix->get_charlabels } ) {
    		$charlabels .= $label =~ /\s/ ? " '$label'" : " $label";
    	}
	$string .= "    CHARLABELS$charlabels;\n";
    }
    $string .= "    MATRIX\n";
    my $length = 0;
    foreach my $datum ( @{ $matrix->get_entities } ) {
        $length = length( $datum->get_name )
          if length( $datum->get_name ) > $length;
    }
    $length += 4;
    my $sp = ' ';
    foreach my $datum ( @{ $matrix->get_entities } ) {
        $string .= "        "
          . $datum->get_name
          . ( $sp x ( $length - length( $datum->get_name ) ) );
		$string .= $datum->get_char;
        $string .= "\n";
    }
    $string .= "    ;\nEND;\n";
    return $string;
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The newick unparser is called by the L<Bio::Phylo::IO|Bio::Phylo::IO> object.
Look there to learn how to unparse newick strings.

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

$Id: Nexus.pm 3292 2007-03-17 16:52:08Z rvosa $

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
