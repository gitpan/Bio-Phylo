package Bio::Phylo::Matrices::Datatype::Continuous;
use Bio::Phylo::Util::CONSTANT qw(looks_like_number);
use Bio::Phylo::Matrices::Datatype;
use strict;
use vars qw( @ISA $LOOKUP $MISSING $GAP);

@ISA = qw(Bio::Phylo::Matrices::Datatype);

=head1 NAME

Bio::Phylo::Matrices::Datatype::Continuous - Datatype subclass,
no serviceable parts inside

=head1 DESCRIPTION

The Bio::Phylo::Matrices::Datatype::* classes are used to validated data
contained by L<Bio::Phylo::Matrices::Matrix> and L<Bio::Phylo::Matrices::Datum>
objects.

=head1 METHODS

=head2 MUTATORS

=over

=item set_lookup()

Sets the lookup table (no-op for continuous data!).

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
	shift->warn("Can't set lookup table for continuous characters");
	return;
}

=back

=head2 ACCESSORS

=over

=item get_lookup()

Gets the lookup table (no-op for continuous data!).

 Type    : Accessor
 Title   : get_lookup
 Usage   : my $lookup = $obj->get_lookup;
 Function: Returns the object's lookup hash
 Returns : A hash reference
 Args    : None

=cut

sub get_lookup {
	shift->warn("Can't get lookup table for continuous characters");
	return;
}

=back

=head2 TESTS

=over

=item is_valid()

Validates arguments for data validity.

 Type    : Test
 Title   : is_valid
 Usage   : if ( $obj->is_valid($datum) ) {
              # do something
           }
 Function: Returns true if $datum only contains valid characters
 Returns : BOOLEAN
 Args    : A list of Bio::Phylo::Matrices::Datum object, and/or
           character array references, and/or character strings,
           and/or single characters

=cut

sub is_valid {
	my $self = shift;
	my @data;
	for my $arg (@_) {
		if ( UNIVERSAL::can( $arg, 'get_char' ) ) {
			push @data, $arg->get_char;
		}
		elsif ( UNIVERSAL::isa( $arg, 'ARRAY' ) ) {
			push @data, @{$arg};
		}
		else {
			push @data, @{ $self->split($arg) };
		}
	}
	my $missing = $self->get_missing;
  CHAR_CHECK: for my $char ( @data ) {
		if ( looks_like_number $char || $char eq $missing ) {
			next CHAR_CHECK;
		}
		else {
			return 0;
		}
	}
	return 1;
}

=back

=head2 UTILITY METHODS

=over

=item split()

Splits string of characters on whitespaces.

 Type    : Utility method
 Title   : split
 Usage   : $obj->split($string)
 Function: Splits $string into characters
 Returns : An array reference of characters
 Args    : A string

=cut

sub split {
	my ( $self, $string ) = @_;
	my @array = CORE::split /\s+/, $string;
	return \@array;
}

=item join()

Joins array ref of characters to a space-separated string.

 Type    : Utility method
 Title   : join
 Usage   : $obj->join($arrayref)
 Function: Joins $arrayref into a string
 Returns : A string
 Args    : An array reference

=cut

sub join {
	my ( $self, $array ) = @_;
	return CORE::join ' ', @{$array};
}

$MISSING = '?';

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Matrices::Datatype>

This object inherits from L<Bio::Phylo::Matrices::Datatype>, so the methods defined
therein are also applicable to L<Bio::Phylo::Matrices::Datatype::Continuous>
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

$Id: Continuous.pm 4159 2007-07-11 01:34:55Z rvosa $

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
