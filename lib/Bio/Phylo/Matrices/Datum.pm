package Bio::Phylo::Matrices::Datum;
use vars '@ISA';
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Taxa::TaxonLinker;
use Bio::Phylo::Util::XMLWritable;
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Matrices::TypeSafeData;
use Bio::Phylo::Adaptor;
use Bio::Phylo::Util::CONSTANT qw(:objecttypes looks_like_number);
@ISA = qw(
    Bio::Phylo::Listable 
    Bio::Phylo::Taxa::TaxonLinker 
    Bio::Phylo::Util::XMLWritable
    Bio::Phylo::Matrices::TypeSafeData 
);

{

    my ( %weight, %char, %position, %annotations );
    my @fields = ( \%weight, \%char, \%position, \%annotations );

    sub new {
        # could be child class
        my $class = shift;
        
        # notify user
        $class->info("constructor called for '$class'");
        
        # go up inheritance tree, eventually get an ID
        my $self = $class->SUPER::new( '-type' => 'standard', @_ );
        
        # adapt (or not, if $Bio::Phylo::COMPAT is not set)
        return Bio::Phylo::Adaptor->new( $self );
    }

    sub set_weight {
        my ( $self, $weight ) = @_;
        my $id = $self->get_id;
        if ( defined $weight && looks_like_number $weight ) {
            $weight{$id} = $weight;
        }
        elsif ( defined $weight && ! looks_like_number $weight ) {
            Bio::Phylo::Util::Exceptions::BadNumber->throw(
                'error' => 'Not a number!',
            );
        }
        else {
            $weight{$id} = 1;
        }
    }
        
    sub set_char { 
        my ( $self, $char ) = @_;
        if ( not UNIVERSAL::isa( $char, 'ARRAY' ) ) {
            my $array = $self->get_type_object->split( $char );
            $char{ $self->get_id } = $array;
        }
        else {
            $char{ $self->get_id } = $char;
        }
        $self->validate;
        return $self;
    }
        
    sub set_position {
        my ( $self, $pos ) = @_;
        if ( looks_like_number $pos && $pos >= 1 && $pos / int($pos) == 1 ) {
            $position{ $self->get_id } = $pos;
        }
        else {
            Bio::Phylo::Util::Exceptions::BadNumber->throw(
                'error' => "'$pos' not a positive integer!",
            );
        }
    }
        
    sub set_annotation {}
        
    sub set_annotations {}
        
    sub get_weight {
        my $self = shift;
        my $weight = $weight{ $self->get_id };
        return defined $weight ? $weight : 1;
    }
        
    sub get_char {
        my $self = shift;
        my $id = $self->get_id;
        if ( $char{$id} ) {
            return wantarray ? @{ $char{$id} } : $self->get_type_object->join( $char{$id} );
        }
        else {
            return wantarray ? () : '';
        }
    }
        
    sub get_position {
        my $self = shift;
        my $pos = $position{ $self->get_id };
        return defined $pos ? $pos : 1;
    }
        
    sub get_annotation {}
        
    sub get_length {
        my $self = shift;
        my @chars = $self->get_char;
        return scalar @chars;
    }
        
    sub copy_atts {}
        
    sub reverse {
        my $self = shift;
        my @char = $self->get_char;
        my @reversed = reverse( @char );
        $self->set_char( \@reversed );
    }
        
    sub complement {}
        
    sub slice {}
        
    sub concat {
        my ( $self, @data ) = @_;
        $self->info("concatenating objects");
        my @newchars;
        my @self_chars = $self->get_char;
        my $self_i = $self->get_position - 1;
        my $self_j = $self->get_length - 1 + $self_i;
        @newchars[ $self_i .. $self_j ] = @self_chars;
        for my $datum ( @data ) {
            my @chars = $datum->get_char;
            my $i = $datum->get_position - 1;
            my $j = $datum->get_length - 1 + $i;
            @newchars[ $i .. $j ] = @chars;
        }
        my $missing = $self->get_missing;
        for my $i ( 0 .. $#newchars ) {
            $newchars[$i] = $missing if ! defined $newchars[$i];
        }
        $self->set_char( \@newchars );
    }
        
    sub validate {
        my $self = shift;
        if ( ! $self->get_type_object->is_valid( $self ) ) {
            Bio::Phylo::Util::Exceptions::InvalidData->throw(
                'error' => 'Invalid data!',
            );
        }
    }
        
    sub _type { _DATUM_ }
        
    sub _container { _MATRIX_ }
        
    sub _cleanup {
        my $self = shift;
        $self->info("cleaning up '$self'");
        my $id = $self->get_id;
        for my $field ( @fields ) {
            delete $field->{$id};
        }
    }
        
}

1;