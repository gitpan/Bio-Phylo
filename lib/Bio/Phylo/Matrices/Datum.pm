# $Id: Datum.pm,v 1.20 2005/09/29 20:31:18 rvosa Exp $
# Subversion: $Rev: 177 $
package Bio::Phylo::Matrices::Datum;
use strict;
use warnings;
use Bio::Phylo::Forest::Node;
use Scalar::Util qw(looks_like_number);
use Bio::Phylo::CONSTANT qw(_DATUM_ _MATRIX_ _TAXON_);
use base 'Bio::Phylo';
use fields qw(TAXON
              WEIGHT
              TYPE
              CHAR
              POS);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# List of allowed symbols. Move these to Bio::Phylo::CONSTANT, and turn
# into a hash, with translation table, nucleotide complements
my @IUPAC_NUC  = qw(A B C D G H K M N R S T U V W X Y . - ?);
my @IUPAC_PROT = qw(A B C D E F G H I K L M N P Q R S T U V W X Y Z . - ?);

=head1 NAME

Bio::Phylo::Matrices::Datum - The single observations object.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Matrix;
 use Bio::Phylo::Matrices::Datum;
 use Bio::Phylo::Taxa::Taxon;

 # instantiating a datum object...
 my $datum = Bio::Phylo::Matrices::Datum->new(
    -name   => 'Tooth comb size,
    -type   => 'STANDARD',
    -desc   => 'Records the number of teeth in lower jaw tooth comb',
    -pos    => 1,
    -weight => 2,
    -char   => 6
 );

 # ...and linking it to a taxon object
 $datum->set_taxon( Bio::Phylo::Taxa::Taxon->new( -name => 'Lemur_catta' ) );
 
 # instantiating a matrix...
 my $matrix = Bio::Phylo::Matrices::Matrix->new;
 
 # ...and insert datum in matrix
 $matrix->insert($datum);

=head1 DESCRIPTION

The datum object models a single observation, which can be crossreferenced
with a taxon object.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $datum = new Bio::Phylo::Matrices::Datum;
 Function: Instantiates a Bio::Phylo::Matrices::Datum object.
 Returns : A Bio::Phylo::Matrices::Datum object.
 Args    : None required. Optional:
           -taxon  => $taxon (A Bio::Phylo::Taxa::Taxon object)
           -weight => 0.234 (a perl number)
           -type   => (one of DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS)
           -char   => 3 (a single character state)
           -pos    => 2 (position in the matrix object)
 

=cut

sub new {
    my $class = shift;
    my $self = fields::new($class);
    $self->SUPER::new(@_);
    if (@_) {
        my %opts;
        eval { %opts = @_; };
        if ($@) {
            Bio::Phylo::Exceptions::OddHash->throw(
                error => $@
            );
        }
        while ( my ( $key, $value ) = each %opts ) {
            my $localkey = uc substr $key, 1;
            eval { $self->{$localkey} = $value; };
            if ($@) {
                Bio::Phylo::Exceptions::BadArgs->throw(
                    error => "invalid field specified: $key ($localkey)"
                );
            }
        }
    }
    return $self;
}

=back

=head2 MUTATORS

=over

=item set_taxon()

 Type    : Mutator
 Title   : set_taxon
 Usage   : $datum->set_taxon($taxon);
 Function: Assigns the taxon a datum refers to.
 Returns : Modified object.
 Args    : $taxon must be a Bio::Phylo::Taxa::Taxon object.

=cut

sub set_taxon {
    my $self  = $_[0];
    my $taxon = $_[1];
    my $ref   = ref $taxon;
    if ( !$taxon->can('_type') || $taxon->_type != _TAXON_ ) {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => "$ref doesn't look like a taxon"
        );
    }
    else {
        $self->{'TAXON'} = $taxon;
    }
    return $self;
}

=item set_weight()

 Type    : Mutator
 Title   : set_weight
 Usage   : $datum->set_weight($weight);
 Function: Assigns a datum's weight.
 Returns : Modified object.
 Args    : The $weight argument must be a number in any of Perl's number
           formats.

=cut

sub set_weight {
    my $self   = $_[0];
    my $weight = $_[1];
    if ( ! looks_like_number $weight ) {
        Bio::Phylo::Exceptions::BadNumber->throw(
            error => "\"$weight\" is a bad number format"
        );
    }
    else {
        $self->{'WEIGHT'} = $weight;
    }
    return $self;
}

=item set_type()

 Type    : Mutator
 Title   : set_type
 Usage   : $datum->set_type($type);
 Function: Assigns a datum's type.
 Returns : Modified object.
 Args    : $type must be one of [DNA|RNA|STANDARD|PROTEIN|
           NUCLEOTIDE|CONTINUOUS]. If DNA, RNA or NUCLEOTIDE is defined, the
           subsequently set char is validated against the IUPAC nucleotide one
           letter codes. If PROTEIN is defined, the char is validated against
           IUPAC one letter amino acid codes. Likewise, a STANDARD char has to
           be a single integer [0-9], while for CONTINUOUS all of Perl's number
           formats are allowed.

=cut

sub set_type {
    my $self = $_[0];
    my $type = $_[1];
    if ( $type !~ m/^(DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS)$/i ) {
        Bio::Phylo::Exceptions::BadFormat->throw(
            error => "\"$type\" is a bad data type"
        );
    }
    else {
        $self->{'TYPE'} = uc $type;
    }
    return $self;
}

=item set_char()

 Type    : Mutator
 Title   : set_char
 Usage   : $datum->set_char($char);
 Function: Assigns a datum's character value.
 Returns : Modified object.
 Args    : The $char argument is checked against the allowed ranges for the
           various character types: IUPAC nucleotide (for types of
           DNA|RNA|NUCLEOTIDE), IUPAC single letter amino acid codes
           (for type PROTEIN), integers (STANDARD) or any of perl's
           decimal formats (CONTINUOUS).

=cut

sub set_char {
    my $self = $_[0];
    my $char = $_[1];
    if ( my $type = $self->{'TYPE'} ) {
        if ( $type =~ /(DNA|RNA|NUCLEOTIDE)/ ) {
            if ( !grep /$char/i, @IUPAC_NUC ) {
                Bio::Phylo::Exceptions::BadString->throw(
                    error => "\"$char\" is not a valid \"$type\" symbol"
                );
            }
        }
        if ( $type eq 'PROTEIN' ) {
            if ( !grep /$char/i, @IUPAC_PROT ) {
                Bio::Phylo::Exceptions::BadString->throw(
                    error => "\"$char\" is not a valid \"$type\" symbol"
                );
            }
        }
        if ( $type eq 'STANDARD' ) {
            if ( $char !~ m/^(\d|\?)$/ ) {
                Bio::Phylo::Exceptions::BadString->throw(
                    error => "\"$char\" is not a valid \"$type\" symbol"
                );
            }
        }
        if ( $type eq 'CONTINUOUS' ) {
            if ( $char !~ m/(^[-|+]?\d+\.?\d*e?[-|+]?\d*$)/i ) {
                Bio::Phylo::Exceptions::BadString->throw(
                    error => "\"$char\" is not a valid \"$type\" symbol"
                );
            }
        }
        $self->{'CHAR'} = $char;
    }
    else {
        Bio::Phylo::Exceptions::BadFormat->throw(
            error => 'please define the data type first'
        );
    }
    return $self;
}

=item set_position()

 Type    : Mutator
 Title   : set_position
 Usage   : $datum->set_position($pos);
 Function: Assigns a datum's position.
 Returns : Modified object.
 Args    : $pos must be an integer.

=cut

sub set_position {
    my $self = $_[0];
    my $pos  = $_[1];
    if ( $pos !~ m/^\d+$/ ) {
        Bio::Phylo::Exceptions::BadNumber->throw(
            error => "\"$pos\" is bad. Positions must be integers"
        );
    }
    else {
        $self->{'POS'} = $pos;
    }
    return $self;
}

=back

=head2 ACCESSORS

=over

=item get_taxon()

 Type    : Accessor
 Title   : get_taxon
 Usage   : my $taxon = $datum->get_taxon;
 Function: Retrieves the taxon a datum refers to.
 Returns : Bio::Phylo::Taxa::Taxon
 Args    : NONE

=cut

sub get_taxon {
    return $_[0]->{'TAXON'};
}

=item get_weight()

 Type    : Accessor
 Title   : get_weight
 Usage   : my $weight = $datum->get_weight;
 Function: Retrieves a datum's weight.
 Returns : FLOAT
 Args    : NONE

=cut

sub get_weight {
    return $_[0]->{'WEIGHT'};
}

=item get_type()

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $datum->get_type;
 Function: Retrieves a datum's type.
 Returns : One of [DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS]
 Args    : NONE

=cut

sub get_type {
    return $_[0]->{'TYPE'};
}

=item get_char()

 Type    : Accessor
 Title   : get_char
 Usage   : my $char = $datum->get_char;
 Function: Retrieves a datum's character value.
 Returns : A single character.
 Args    : NONE

=cut

sub get_char {
    return $_[0]->{'CHAR'};
}

=item get_position()

 Type    : Accessor
 Title   : get_position
 Usage   : my $pos = $datum->get_position;
 Function: Retrieves a datum's position.
 Returns : a SCALAR integer.
 Args    : NONE

=cut

sub get_position {
    return $_[0]->{'POS'};
}

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $datum->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

sub _container { _MATRIX_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $datum->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

sub _type { _DATUM_ }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

This object inherits from L<Bio::Phylo>, so the methods defined
therein are also applicable to L<Bio::Phylo::Matrices::Datum> objects.

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

$Id: Datum.pm,v 1.20 2005/09/29 20:31:18 rvosa Exp $

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
