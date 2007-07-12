package Bio::Phylo::Adaptor::Bioperl::Datum;
use Bio::Phylo::Adaptor;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Adaptor);

eval { require Bio::LocatableSeq };
if ( not $@ ) {
    push @ISA, 'Bio::LocatableSeq';
}
=head1 NAME

Bio::Phylo::Adaptor::Bioperl::Datum - Adaptor class for bioperl compatibility

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Datum;
 use Bio::Phylo::Adaptor;

 my $datum = Bio::Phylo::Matrices::Datum->new;

 $Bio::Phylo::COMPAT = 'Bioperl';

 my $seq = Bio::Phylo::Adaptor->new($datum);

 print "compatible!" if $seq->isa('Bio::LocatableSeq');

=head1 DESCRIPTION

This class wraps Bio::Phylo datum objects to give them an interface
compatible with bioperl.

=head1 METHODS

=over

=item alphabet()

 Title   : alphabet
 Usage   : if( $obj->alphabet eq 'dna' ) { /Do Something/ }
 Function: Returns the alphabet of sequence, one of
           'dna', 'rna' or 'protein'. This is case sensitive.

           This is not called <type> because this would cause
           upgrade problems from the 0.5 and earlier Seq objects.

 Returns : a string either 'dna','rna','protein'. NB - the object must
           make a call of the type - if there is no alphabet specified it
           has to guess.
 Args    : none


=cut

sub alphabet {
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->get_type_object->get_type;
}

=item get_nse()

 Title   : get_nse
 Usage   :
 Function: read-only name of form id/start-end
 Example :
 Returns :
 Args    :

=cut

sub get_nse {
    my $adaptor = shift;
    my $self = $$adaptor;
    my $name = $self->get_name;
    my $start = $self->get_position;
    my $length = $self->get_length;
    my $end = $start + $length;
    return "$name/$start-$end";
}

=item seq()

 Title   : seq()
 Usage   : $string    = $obj->seq()
 Function: Returns the sequence as a string of letters. The
           case of the letters is left up to the implementer.
           Suggested cases are upper case for proteins and lower case for
           DNA sequence (IUPAC standard), but you should not rely on this.
 Returns : A scalar
 Args    : Optionally on set the new value (a string). An optional second
           argument presets the alphabet (otherwise it will be guessed).
           Both parameters may also be given in named paramater style
           with -seq and -alphabet being the names.

=cut

sub seq {
    my $adaptor = shift;
    my $self = $$adaptor;
    my $seq = $self->get_char;
    return $seq;
}

=back

=head1 SEE ALSO

=over

=item L<Bio::LocatableSeq>

Bio::Phylo::Adaptor::Bioperl::Datum is an adaptor that makes Bio::Phylo
character data sequences compatible with L<Bio::LocatableSeq> objects.

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

$Id: Datum.pm 4162 2007-07-11 01:35:39Z rvosa $

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