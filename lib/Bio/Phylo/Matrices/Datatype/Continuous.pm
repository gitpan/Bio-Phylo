package Bio::Phylo::Matrices::Datatype::Continuous;
use Bio::Phylo::Util::CONSTANT qw(looks_like_number);
use strict;
use vars qw($LOOKUP @ISA $MISSING $GAP);
@ISA = qw(Bio::Phylo::Matrices::Datatype);

sub set_lookup { 
    shift->warn( "Can't set lookup table for continuous characters" );
    return;
}

sub get_lookup { 
    shift->warn( "Can't get lookup table for continuous characters" );
    return;
}

sub is_valid {
    my ( $self, $datum ) = @_;
    my $missing = $self->get_missing;
    CHAR_CHECK: for my $char ( $datum->get_char ) {
        if ( looks_like_number $char || $char eq $missing ) {
            next CHAR_CHECK;
        }
        else {
            return 0;
        }
    }
    return 1;
}

sub split {
    my ( $self, $string ) = @_;
    my @array = CORE::split /\s+/, $string;
    return \@array;
}

sub join {
    my ( $self, $array ) = @_;
    return CORE::join ' ', @{ $array };
}

$MISSING = '?';

1;