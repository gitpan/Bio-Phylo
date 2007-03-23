package Bio::Phylo::Adaptor::Bioperl::Matrix;
use Bio::Phylo::Adaptor;
use strict;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Adaptor);

eval { require Bio::Align::AlignI };
if ( not $@ ) {
    push @ISA, 'Bio::Align::AlignI';
}

sub add_seq {
    my ( $adaptor, $seq ) = @_;
    my $self = $$adaptor;
    $self->insert( $seq );
    return $self;
}

sub remove_seq {
    my ( $adaptor, $seq ) = @_;
    my $self = $$adaptor;   
    $self->delete( $seq );
    return $self;
}

sub sort_alphabetically {
    my $adaptor = shift;
    my $self = $$adaptor;    
    my @seqs = sort { $a <=> $b } @{ $self->get_entities };
    $self->delete( $_ ) for @seqs;
    $self->insert( $_ ) for @seqs;
    return $self;
}

sub each_seq {
    my $adaptor = shift;
    my $self = $$adaptor; 
    return @{ $self->get_entities };
}

sub each_alphabetically {
    my $adaptor = shift;
    my $self = $$adaptor; 
    return sort { $a <=> $b } @{ $self->get_entities };
}

sub each_seq_with_id {
    my ( $adaptor, $name ) = @_;
    my $self = $$adaptor;     
    return grep { $_->get_name =~ m/^\Q$name\E$/ } @{ $self->get_entities };
}

sub get_seq_by_pos {
    my ( $adaptor, $i ) = @_;
    my $self = $$adaptor;     
    return $self->get_by_index( --$i );
}

sub select {
    my ( $adaptor, $start, $end ) = @_;
    my $self = $$adaptor;     
    if ( ! $end ) {
        return $self->get_by_index( --$start );
    }
    else {
        my @seqs;
        for ( ( $start - 1 ) .. ( $end - 1 ) ) {
            push @seqs, $self->get_by_index( $_ );
        }
        return @seqs;
    }
}

sub select_noncont {
    my ( $adaptor, @indices ) = @_;
    my $self = $$adaptor;     
    my @seqs;
    push @seqs, $self->get_by_index( $_ ) for @indices;
    return @seqs;
}

sub id {
    my ( $adaptor, $name ) = @_;
    my $self = $$adaptor;     
    $self->set_name( $name ) if defined $name;
    return $self->get_name;
}

sub missing_char {
   my ( $adaptor, $char ) = @_;
    my $self = $$adaptor;    
   $self->set_missing( $char ) if defined $char;
   return $self->get_missing;
}

sub match_char {
    my ( $adaptor, $match ) = @_;
    my $self = $$adaptor;     
    $self->set_matchchar( $match ) if defined $match;
    return $self->get_matchchar;
}

sub gap_char {
    my ( $adaptor, $char ) = @_;
	my $self = $$adaptor;    
    $self->set_gap( $char ) if defined $char;
    return $self->get_gap;
}

sub symbol_chars {
    my ( $adaptor, $include_special_chars ) = @_;
    my $self = $$adaptor;     
    my @chars;
    for my $row ( @{ $self->get_entities } ) {
    	my @temp = $row->get_char;
        push @chars, @temp;
    }
    my @uniq = keys %{ { map { $_ => 1 } @chars } };
    push @uniq, $self->get_missing, $self->get_gap, $self->get_matchchar if $include_special_chars;
    return @uniq;
}

sub is_flush { 1 } # Bio::Phylo::Matrices::Matrix is always rectangular

sub length {
    my $adaptor = shift;
    my $self = $$adaptor;     
    return $self->get_nchar;
}

sub maxdisplayname_length {
    my $adaptor = shift;
    my $self = $$adaptor;     
    my $length = 0;
    for my $row ( @{ $self->get_entities } ) {
    	my $rowlength = CORE::length( $row->get_name );
    	$length = $rowlength if $rowlength > $length;
    }
    return $length;
}

sub no_sequences {
    my $adaptor = shift;
    my $self = $$adaptor;     
    return $self->get_ntax;
}

sub displayname {
    my ( $adaptor, $name, $displayname ) = @_;
    my $self = $$adaptor;     
    if ( not defined $displayname ) {
	$self->debug( "Getting displayname for '$name'" );
    }
    else {
        $self->debug( "Setting displayname '$displayname' for '$name'" );
    }
    $name =~ s/\/.*$//;
    my $seq;
    for ( @{ $self->get_entities } ) {
        if ( $_->get_name eq $name ) {
            $seq = $_;
            last;
        }
    }
    if ( defined $displayname ) {
        $seq->set_generic( 'displayname' => $displayname );
    }
    return $seq->get_generic( 'displayname' ) || $name;
}

sub set_displayname_flat {
    return 1;
}

1;