package Bio::Phylo::Matrices::Datatype::Mixed;
use strict;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Matrices::Datatype);

{

=head1 NAME

Bio::Phylo::Matrices::Datatype::Mixed - Datatype subclass,
no serviceable parts inside

=head1 DESCRIPTION

The Bio::Phylo::Matrices::Datatype::* classes are used to validated data
contained by L<Bio::Phylo::Matrices::Matrix> and L<Bio::Phylo::Matrices::Datum>
objects.

=cut   

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

=head1 METHODS

=head2 MUTATORS

=over

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
        my ( $self, $missing ) = @_;
        $missing{ $self->get_id } = $missing;
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
        my ( $self, $gap ) = @_;
        $gap{ $self->get_id } = $gap;
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_missing()

 Type    : Accessor
 Title   : get_missing
 Usage   : my $missing = $obj->get_missing;
 Function: Returns the object's missing data symbol
 Returns : A string
 Args    : None

=cut

    sub get_missing { return $missing{ shift->get_id } }

=item get_gap()

 Type    : Accessor
 Title   : get_gap
 Usage   : my $gap = $obj->get_gap;
 Function: Returns the object's gap symbol
 Returns : A string
 Args    : None

=cut

    sub get_gap { return $gap{ shift->get_id } }
    
    my $get_ranges = sub { $range{ shift->get_id } };

=item get_type()

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $obj->get_type;
 Function: Returns the object's datatype
 Returns : A string
 Args    : None

=cut

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

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Matrices::Datatype>

This object inherits from L<Bio::Phylo::Matrices::Datatype>, so the methods defined
therein are also applicable to L<Bio::Phylo::Matrices::Datatype::Mixed>
objects.

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

$Id: Mixed.pm 3386 2007-03-24 16:22:25Z rvosa $

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