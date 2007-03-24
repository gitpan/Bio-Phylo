package Bio::Phylo::Matrices::Datatype;
use Bio::Phylo;
use strict;
use vars '@ISA';
@ISA = qw(Bio::Phylo);

{

    my %lookup;
    my %missing;
    my %gap;
    
    my @fields = ( \%lookup, \%missing, \%gap );

=head1 NAME

Bio::Phylo::Matrices::Datatype - Superclass for objects that validate
character data.

=head1 SYNOPSIS

 # No direct usage

=head1 DESCRIPTION

This is a superclass for objects that validate character data. Objects that
inherit from this class (typically those in the
Bio::Phylo::Matrices::Datatype::* namespace) can check strings and arrays of
character data for invalid symbols, and split and join strings and arrays
in a way appropriate for the type (i.e. on whitespace for continuous data,
on single characters for categorical data).

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : No direct usage, is called by TypeSafaData classes;
 Function: Instantiates a Datatype object
 Returns : a Bio::Phylo::Matrices::Datatype child class
 Args    : $type (optional, one of continuous, custom, dna,
           mixed, protein, restriction, rna, standard)

=cut

    sub new {
        my $package = shift;
        my $type = ucfirst( lc( shift ) );
        if ( not $type ) {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                'error' => "No subtype specified!"
            );
        }
        if ( $type eq 'Nucleotide' ) {
            $package->warn("'nucleotide' datatype requested, using 'dna'");
            $type = 'Dna';
        }
        my $typeclass = __PACKAGE__ . '::' . $type;
        my $self      = __PACKAGE__->SUPER::new; 
        eval "require $typeclass";
        if ( $@ ) {
            Bio::Phylo::Util::Exceptions::BadFormat->throw(
                'error' => sprintf( "'%s' is not a valid datatype", $type )
            );
        }
        else {
            return $typeclass->_new( $self, @_ );
        }
    }
    
    sub _new { 
        my $class = shift;
        my $self  = shift;
        my ( $lookup, $missing, $gap );
        {
            no strict 'refs';
            $lookup  = ${ $class . '::LOOKUP'  };
            $missing = ${ $class . '::MISSING' }; 
            $gap     = ${ $class . '::GAP'     };
            use strict;
        }
        bless $self, $class;
        $self->set_lookup(  $lookup  ) if defined $lookup;
        $self->set_missing( $missing ) if defined $missing;
        $self->set_gap(     $gap     ) if defined $gap;
        return $self;
    }

=back

=head2 MUTATORS

=over

=item set_lookup()

 Type    : Mutator
 Title   : set_lookup
 Usage   : $obj->set_gap($hashref);
 Function: Sets the symbol for gaps
 Returns : Modified object.
 Args    : Argument must be a hash
           reference that maps allowed
           single character symbols
           (including ambiguity symbols)
           onto the equivalent set of
           non-ambiguous symbols

=cut

    sub set_lookup {
        my ( $self, $lookup ) = @_;
        
        # we have a value
        if ( defined $lookup ) {
            if ( UNIVERSAL::isa( $lookup, 'HASH' ) ) {
                $lookup{ $self->get_id } = $lookup;
            }
            else {
                Bio::Phylo::Util::Exceptions::BadArgs->throw(
                    'error' => "lookup must be a hash reference"
                );
            }
        }
        
        # no value, so must be a reset
        else {
            $lookup{ $self->get_id } = $self->get_lookup;
        }
        return $self;
    }

=item set_missing()

 Type    : Mutator
 Title   : set_missing
 Usage   : $obj->set_missing('?');
 Function: Sets the symbol for missing data
 Returns : Modified object.
 Args    : Argument must be a single
           character, default is '?'

=cut

    sub set_missing {
        my $self = shift;
        $missing{ $self->get_id } = shift;
        return $self;
    }

=item set_gap()

 Type    : Mutator
 Title   : set_gap
 Usage   : $obj->set_gap('-');
 Function: Sets the symbol for gaps
 Returns : Modified object.
 Args    : Argument must be a single
           character, default is '-'

=cut

    sub set_gap {
        my $self = shift;
        $gap{ $self->get_id } = shift;
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_type()

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $obj->get_type;
 Function: Returns the object's datatype
 Returns : A string
 Args    : None

=cut

    sub get_type {
        my $type = ref shift;
        $type =~ s/.*:://;
        return $type;
    }

=item get_lookup()

 Type    : Accessor
 Title   : get_lookup
 Usage   : my $lookup = $obj->get_lookup;
 Function: Returns the object's lookup hash
 Returns : A hash reference
 Args    : None

=cut

    sub get_lookup {
        my $self = shift;
        my $id = $self->get_id;
        if ( exists $lookup{$id} ) {
            return $lookup{$id};
        }
        else {
           my $class = ref $self;
           my $lookup;
           {
                no strict 'refs';
                $lookup = ${ $class . '::LOOKUP'  };
                use strict;
           }
           $self->set_lookup( $lookup );
           return $lookup;
        }
    }

=item get_missing()

 Type    : Accessor
 Title   : get_missing
 Usage   : my $missing = $obj->get_missing;
 Function: Returns the object's missing data symbol
 Returns : A string
 Args    : None

=cut

    sub get_missing {
        return $missing{ shift->get_id };
    }

=item get_gap()

 Type    : Accessor
 Title   : get_gap
 Usage   : my $gap = $obj->get_gap;
 Function: Returns the object's gap symbol
 Returns : A string
 Args    : None

=cut

    sub get_gap {
        return $gap{ shift->get_id };
    }

=back

=head2 TESTS

=over

=item is_valid()

 Type    : Test
 Title   : is_valid
 Usage   : if ( $obj->is_valid($datum) ) {
              # do something
           }
 Function: Returns true if $datum only contains valid characters
 Returns : BOOLEAN
 Args    : A Bio::Phylo::Matrices::Datum object

=cut

    sub is_valid {
        my ( $self, $datum ) = @_;
        my $type = $self->get_type;
        my $lookup = $self->get_lookup;
        my ( $missing, $gap ) = ( $self->get_missing, $self->get_gap );
        CHAR_CHECK: for my $char ( $datum->get_char ) {
            my $uc = uc $char;
            next CHAR_CHECK if not defined $char;
            if ( exists $lookup->{$uc} || ( defined $missing && $uc eq $missing ) || ( defined $gap && $uc eq $gap ) ) {
                next CHAR_CHECK;
            }
            else {
                return 0;
            }
        }
        return 1;
    }

=item is_same()

 Type    : Test
 Title   : is_same
 Usage   : if ( $obj->is_same($obj1) ) {
              # do something
           }
 Function: Returns true if $obj1 contains the same validation rules
 Returns : BOOLEAN
 Args    : A Bio::Phylo::Matrices::Datatype::* object

=cut

    sub is_same {
        my ( $self, $model ) = @_;
        
        # check strings
        for my $prop ( qw(get_type get_missing get_gap) ) {
            my ( $self_prop, $model_prop ) = ( $self->$prop, $model->$prop );
            return 0 if defined $self_prop && defined $model_prop && $self_prop ne $model_prop;
        }
        my ( $s_lookup, $m_lookup ) = ( $self->get_lookup, $model->get_lookup );
    
        # one has lookup, other hasn't
        if ( $s_lookup && ! $m_lookup ) {
            return 0;
        }
    
        # both don't have lookup -> are continuous
        if ( ! $s_lookup && ! $m_lookup ) {
            return 1;
        }
    
        # get keys
        my @s_keys = keys %{ $s_lookup };
        my @m_keys = keys %{ $m_lookup };
    
        # different number of keys
        if ( scalar( @s_keys ) != scalar( @m_keys ) ) {
            return 0;
        }
        
        # compare keys
        for my $key ( @s_keys ) {
            if ( not exists $m_lookup->{$key} ) {
                return 0;
            }
            else {
                # compare values
                my ( %s_vals, %m_vals );
                my ( @s_vals, @m_vals );
                @s_vals = @{ $s_lookup->{$key} };
                @m_vals = @{ $m_lookup->{$key} };
                
                # different number of vals
                if ( scalar( @m_vals ) != scalar( @s_vals ) ) {
                    return 0;
                }
                
                # make hashes to compare on vals
                %s_vals = map { $_ => 1 } @s_vals;
                %m_vals = map { $_ => 1 } @m_vals;                      
                for my $val ( keys %s_vals ) {
                    return 0 if not exists $m_vals{$val};
                }
            }
        }
        return 1;
    }

=back

=head2 UTILITY METHODS

=over

=item split()

 Type    : Utility method
 Title   : split
 Usage   : $obj->split($string)
 Function: Splits $string into characters
 Returns : An array reference of characters
 Args    : A string

=cut

    sub split {
        my ( $self, $string ) = @_;
        my @array = CORE::split /\s*/, $string;
        return \@array;
    }

=item join()

 Type    : Utility method
 Title   : join
 Usage   : $obj->join($arrayref)
 Function: Joins $arrayref into a string
 Returns : A string
 Args    : An array reference

=cut

    sub join {
        my ( $self, $array ) = @_;
        return CORE::join '', @{ $array };
    }
    
    sub _cleanup {
        my $self = shift;
        $self->info("cleaning up '$self'");
        my $id = $self->get_id;
        for my $field ( @fields ) {
            delete $field->{$id};
        }
    }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

This object inherits from L<Bio::Phylo>, so the methods defined
therein are also applicable to L<Bio::Phylo::Matrices::Datatype> objects.

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

$Id: Datatype.pm 3386 2007-03-24 16:22:25Z rvosa $

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

}

1;