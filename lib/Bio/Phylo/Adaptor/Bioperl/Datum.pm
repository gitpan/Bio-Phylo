# $Id: Datum.pm 4265 2007-07-20 14:14:44Z rvosa $
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

This class wraps L<Bio::Phylo::Matrices::Datum> objects to give 
them an interface compatible with bioperl.

=head1 METHODS

=over

=item alphabet()

Returns the alphabet of sequence.

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
    return lc( $self->get_type_object->get_type );
}

=item get_nse()

read-only name of form id/start-end

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

Returns the sequence as a string of letters. 

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

=item L<Bio::Phylo::Adaptor>

The base class for the adaptor architecture, instantiates the appropriate
wrapper depending on $Bio::Phylo::COMPAT

=item L<Bio::LocatableSeq>

Bio::Phylo::Adaptor::Bioperl::Datum is an adaptor that makes Bio::Phylo
character data sequences compatible with L<Bio::LocatableSeq> objects.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual|Bio::Phylo::Manual>.

=back

=head1 REVISION

 $Id: Datum.pm 4265 2007-07-20 14:14:44Z rvosa $

=cut

1;