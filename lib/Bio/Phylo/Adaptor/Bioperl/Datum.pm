package Bio::Phylo::Adaptor::Bioperl::Datum;
use Bio::Phylo::Adaptor;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Adaptor);

eval { require Bio::LocatableSeq };
if ( not $@ ) {
    push @ISA, 'Bio::LocatableSeq';
}

sub alphabet {
    my $adaptor = shift;
    my $self = $$adaptor;
    return $self->get_type_object->get_type;
}

sub get_nse {
    my $adaptor = shift;
    my $self = $$adaptor;
    my $name = $self->get_name;
    my $start = $self->get_position;
    my $length = $self->get_length;
    my $end = $start + $length;
    return "$name/$start-$end";
}

sub seq {
    my $adaptor = shift;
    my $self = $$adaptor;
    my $seq = $self->get_char;
    return $seq;
}

1;