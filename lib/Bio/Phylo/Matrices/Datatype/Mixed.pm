package Bio::Phylo::Matrices::Datatype::Mixed;
use strict;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Matrices::Datatype);

{

    my ( %range, %missing, %gap );
    my @fields = ( \%range, \%missing, \%gap );
    
    sub _new { 
        my ( $package, $self, $ranges ) = @_;
        if ( not UNIVERSAL::isa( $ranges, 'ARRAY' ) ) {
            die "No ranges specified!";
        }
        my $id = $self->get_id;
        $range{$id}   = [];
        $missing{$id} = '?';
        $gap{$id}     = '-';
        my $start = 0;
        for ( my $i = 0; $i <= ( $#{ $ranges } - 1 ); $i += 2 ) {
            my $type = $ranges->[ $i     ];
            my $arg  = $ranges->[ $i + 1 ];
            my ( @args, $length );
            if ( UNIVERSAL::isa( $arg, 'HASH' ) ) {
                $length = $arg->{'-length'};
                @args   = @{ $arg->{'-args'} };
            }
            else {
                $length = $arg;
            }
            my $end = $length + $start - 1;
            my $obj = Bio::Phylo::Matrices::Datatype->new( $type, @args );
            $range{$id}->[$_] = $obj for ( $start .. $end );
            $start = ++$end;
        }
        return bless $self, $package;
    }
    
    sub set_missing {
        my ( $self, $missing ) = @_;
        $missing{ $self->get_id } = $missing;
        return $self;
    }
    
    sub set_gap {
        my ( $self, $gap ) = @_;
        $gap{ $self->get_id } = $gap;
        return $self;
    }
    
    sub get_missing { return $missing{ shift->get_id } }
    
    sub get_gap { return $gap{ shift->get_id } }
    
    my $get_ranges = sub { $range{ shift->get_id } };
    
    sub get_type {
        my $self = shift;
        my $string = 'mixed(';
        my $last;
        my $range = $self->$get_ranges;
        MODEL_RANGE_CHECK: for my $i ( 0 .. $#{ $range } ) {
            if ( $i == 0 ) {
                $string .= $range->[$i]->get_type . ":1-";
                $last = $range->[$i];
            }
            elsif ( $range->[$i] != $last ) {
                $last = $range->[$i];
                $string .= "$i, " . $last->get_type . ":" . ( $i + 1 ) . "-";
            }
            else {
                next MODEL_RANGE_CHECK;
            }		
        }
        $string .= scalar( @{ $range } ) . ")";
        return $string;
    }
    
    sub is_valid { 
        my ( $self, $datum ) = @_;
        my ( $start, $end ) = ( $datum->get_position - 1, $datum->get_length - 1 );
        my $ranges = $self->$get_ranges;
        my $type;
        MODEL_RANGE_CHECK: for my $i ( $start .. $end ) {
            if ( not $type ) {
                $type = $ranges->[$i];
            }
            elsif ( $type != $ranges->[$i] ) {
                die; # needs to slice
            }
            else {
                next MODEL_RANGE_CHECK;
            }
        }
        return $type->is_valid( $datum );
    }
    
    sub DESTROY {
        my $self = shift;
        my $id = $self->get_id;
        for my $field ( @fields ) {
            delete $field->{$id};
        }
    }

}

1;