# $Id: Mrp.pm 4198 2007-07-12 16:45:08Z rvosa $
# Subversion: $Rev: 190 $
package Bio::Phylo::Unparsers::Mrp;
use strict;
use Bio::Phylo::IO;

use vars '@ISA';
@ISA=qw(Bio::Phylo::IO);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Unparsers::Mrp - Unparses a forest object into an MRP matrix. No
serviceable parts inside.

=head1 DESCRIPTION

This module turns a L<Bio::Phylo::Forest> object into an MRP nexus
formatted matrix. It is called by the L<Bio::Phylo::IO> facade, don't call it
directly.

=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $mrp = Bio::Phylo::Unparsers::Mrp->_new;
 Function: Initializes a Bio::Phylo::Unparsers::Mrp object.
 Returns : A Bio::Phylo::Unparsers::Mrp object.
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
 Title   : _to_string
 Usage   : my $mrp_string = $mrp->_to_string;
 Function: Stringifies a matrix object into
           an MRP nexus formatted table.
 Alias   :
 Returns : SCALAR
 Args    : Bio::Phylo::Matrices::Matrix;

=end comment

=cut

sub _to_string {
    my $self   = shift;
    my $forest = $self->{'PHYLO'};
    my $string = "BEGIN DATA;\n[! Data block written by " . ref $self;
    $string .= " " . $self->VERSION . " on " . localtime() . " ]\n";
    my $taxa = $forest->make_taxa;
    my $ntax = scalar @{ $taxa->get_entities } + 1;    # + 1 for mrp_outgroup
    $string .= "    DIMENSIONS NTAX=$ntax ";
    my $nchar = 0;

    foreach my $tree ( @{ $forest->get_entities } ) {
        foreach my $node ( @{ $tree->get_internals } ) {
            $nchar++;
        }
    }
    $string .= "NCHAR=$nchar;\n";
    $string .= "    FORMAT DATATYPE=STANDARD MISSING=?;\n    MATRIX\n";
    my $length = length('mrp_outgroup');
    foreach my $taxon ( @{ $taxa->get_entities } ) {
        $length = length( $taxon->get_name )
          if length( $taxon->get_name ) > $length;
    }
    $length += 4;
    my $sp = ' ';
    my %mrp;
    foreach my $tree ( @{ $forest->get_entities } ) {
        my %in_tree = map { $_->get_taxon => 1 } @{ $tree->get_terminals };
        my $n = scalar @{ $tree->get_internals };
        foreach my $t ( @{ $taxa->get_entities } ) {
            $mrp{$t} = ( $sp x ( $length - length( $t->get_name ) ) )
              if !defined $mrp{$t};
            if ( exists $in_tree{$t} ) {
                foreach my $node ( @{ $tree->get_internals } ) {
                    my %in_clade =
                      map { $_->get_taxon => 1 } @{ $node->get_terminals };
                    if ( exists $in_clade{$t} ) {
                        $mrp{$t} .= '1';
                    }
                    else {
                        $mrp{$t} .= '0';
                    }
                }
            }
            else {
                $mrp{$t} .= '?' x $n;
            }
        }
    }
    $string .=
      '        mrp_outgroup' . ( $sp x ( $length - length('mrp_outgroup') ) );
    $string .= ( '0' x $nchar ) . "\n";
    foreach my $taxon ( @{ $taxa->get_entities } ) {
        $string .= '        ' . $taxon->get_name;
        $string .= $mrp{$taxon} . "\n";
    }
    $string .= "    ;\nEND;\n";
    return $string;
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The newick unparser is called by the L<Bio::Phylo::IO> object.
Look there to learn how to create mrp matrices.

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

$Id: Mrp.pm 4198 2007-07-12 16:45:08Z rvosa $

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
