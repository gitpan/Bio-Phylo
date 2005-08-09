# $Id: Datum.pm,v 1.6 2005/08/09 12:36:12 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo::Matrices::Datum;
use strict;
use warnings;
use Bio::Phylo::Trees::Node;
use base 'Bio::Phylo';

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 148 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.03';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);
my @IUPAC_NUC  = qw(A C G T U M R W S Y K V H D B X N . - ?);
my @IUPAC_PROT = qw(A B C D E F G H I K L M N P Q R S T U V W X Y Z . - ?);

=head1 NAME

Bio::Phylo::Matrices::Datum - An object-oriented module for storing single
observations.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Matrix;

 #instantiating a datum object...
 my $datum = Bio::Phylo::Matrices::Datum->new(
    -name=>'Homo_sapiens,
    -type=>DNA,
    -desc=>'Cytochrome B, mtDNA',
    -pos=>1,
    -weight=>2,
    -char=>'C'
 );

 #...and linking it to a taxon object
 $datum->set_taxon(Bio::Phylo::Taxa::Taxon->new(-name=>'Homo_sapiens'));

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
 Args    : none.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    $self->{'NAME'}   = undef;
    $self->{'TAXON'}  = undef;
    $self->{'DESC'}   = undef;
    $self->{'WEIGHT'} = undef;
    $self->{'TYPE'}   = undef;
    $self->{'CHAR'}   = undef;
    $self->{'POS'}    = undef;
    if (@_) {
        my %opts = @_;
        foreach my $key ( keys %opts ) {
            my $localkey = uc($key);
            $localkey =~ s/-//;
            $self->{$localkey} = $opts{$key};
        }
    }
    bless( $self, $class );
    return $self;
}

=back

=head2 MUTATORS

=over

=item set_name()

 Type    : Mutator
 Title   : set_name
 Usage   : $datum->set_name($name);
 Function: Assigns a datums's name (i.e. the name of the taxon it refers to).
 Returns :
 Args    : $name must not contain [;|,|:|(|)]

=cut

sub set_name {
    my $self = $_[0];
    my $name = $_[1];
    my $ref  = ref $self;
    if ( $name =~ m/([;|,|:|\(|\)])/ ) {
        $self->COMPLAIN("\"$name\" is a bad name format for $ref names: $@");
        return;
    }
    else {
        $self->{'NAME'} = $name;
    }
}

=item set_taxon()

 Type    : Mutator
 Title   : set_taxon
 Usage   : $datum->set_taxon($taxon);
 Function: Assigns the taxon a datum refers to.
 Returns :
 Args    : $taxon must be a Bio::Phylo::Taxa::Taxon object.

=cut

sub set_taxon {
    my $self  = $_[0];
    my $taxon = $_[1];
    my $ref   = ref $taxon;
    if ( !$taxon->can('container_type') || $taxon->container_type ne 'TAXON' ) {
        $self->COMPLAIN("$ref doesn't look like a taxon: $@");
        return;
    }
    else {
        $self->{'TAXON'} = $taxon;
    }
    return $self->{'TAXON'};
}

=item set_desc()

 Type    : Mutator
 Title   : set_desc
 Usage   : $datum->set_desc($desc);
 Function: Assigns a description of the current datum.
 Returns :
 Args    : The $desc argument is a string of arbitrary length.

=cut

sub set_desc {
    my $self = $_[0];
    $self->{'DESC'} = $_[1];
}

=item set_weight()

 Type    : Mutator
 Title   : set_weight
 Usage   : $datum->set_weight($weight);
 Function: Assigns a datums's weight.
 Returns :
 Args    : The $weight argument may be a number in any of Perl's number
           formats.

=cut

sub set_weight {
    my $self   = $_[0];
    my $weight = $_[1];
    if ( $weight !~ m/(^[-|+]?\d+\.?\d*e?[-|+]?\d*$)/i ) {
        $self->COMPLAIN("\"$weight\" is a bad number format: $@");
        return;
    }
    else {
        $self->{'WEIGHT'} = $weight;
    }
}

=item set_type()

 Type    : Mutator
 Title   : set_type
 Usage   : $datum->set_type($type);
 Function: Assigns a datums's type.
 Returns :
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
        $self->COMPLAIN("\"$type\" is a bad data type: $@");
        return;
    }
    else {
        $self->{'TYPE'} = uc($type);
    }
}

=item set_char()

 Type    : Mutator
 Title   : set_char
 Usage   : $datum->set_char($char);
 Function: Assigns a datums's character value.
 Returns :
 Args    : The $char argument is checked against the allowed ranges for the
           various character types: IUPAC nucleotide (for types of DNA|RNA|NUCLEOTIDE),
           IUPAC single letter amino acid codes (for type PROTEIN), integers
           (STANDARD) or any of perl's decimal formats (CONTINUOUS).

=cut

sub set_char {
    my $self = $_[0];
    my $char = $_[1];
    if ( my $type = $self->{'TYPE'} ) {
        if ( $type =~ /(DNA|RNA|NUCLEOTIDE)/ ) {
            if ( !grep /$char/i, @IUPAC_NUC ) {
                $self->COMPLAIN("$char is not a valid $type symbol: $@");
                return;
            }
        }
        if ( $type eq 'PROTEIN' ) {
            if ( !grep /$char/i, @IUPAC_PROT ) {
                $self->COMPLAIN("$char is not a valid $type symbol: $@");
                return;
            }
        }
        if ( $type eq 'STANDARD' ) {
            if ( $char !~ m/^(\d|\?)$/ ) {
                $self->COMPLAIN("$char is not a valid $type symbol: $@");
                return;
            }
        }
        if ( $type eq 'CONTINUOUS' ) {
            if ( $char !~ m/(^[-|+]?\d+\.?\d*e?[-|+]?\d*$)/i ) {
                $self->COMPLAIN("$char is not a valid $type symbol: $@");
                return;
            }
        }
        $self->{'CHAR'} = $char;
    }
    else {
        $self->COMPLAIN("Please define the data type first: $@");
        return;
    }
}

=item set_position()

 Type    : Mutator
 Title   : set_position
 Usage   : $datum->set_position($pos);
 Function: Assigns a datums's position.
 Returns :
 Args    : $pos must be an integer.

=cut

sub set_position {
    my $self = $_[0];
    my $pos  = $_[1];
    if ( $pos !~ m/^\d+$/ ) {
        $self->COMPLAIN("\"$pos\" is bad. Positions must be integers: $@");
        return;
    }
    else {
        $self->{'POS'} = $pos;
    }
}

=back

=head2 ACCESSORS

=over

=item get_name()

 Type    : Accessor
 Title   : get_name
 Usage   : $name = $datum->get_name();
 Function: Retrieves a datums's name (i.e. the name of the taxon it refers to).
 Returns : SCALAR
 Args    :

=cut

sub get_name {
    return $_[0]->{'NAME'};
}

=item get_taxon()

 Type    : Accessor
 Title   : get_taxon
 Usage   : $taxon = $datum->get_taxon();
 Function: Retrieves the taxon a datum refers to.
 Returns : Phylo::Taxa::Taxon object
 Args    :

=cut

sub get_taxon {
    return $_[0]->{'TAXON'};
}

=item get_desc()

 Type    : Accessor
 Title   : get_desc
 Usage   : $desc = $datum->get_desc();
 Function: Retrieves a description of the current datum.
 Returns : SCALAR
 Args    :

=cut

sub get_desc {
    return $_[0]->{'DESC'};
}

=item get_weight()

 Type    : Accessor
 Title   : get_weight
 Usage   : $weight = $datum->get_weight();
 Function: Retrieves a datums's weight.
 Returns : SCALAR
 Args    :

=cut

sub get_weight {
    return $_[0]->{'WEIGHT'};
}

=item get_type()

 Type    : Accessor
 Title   : get_type
 Usage   : $type = $datum->get_type();
 Function: Retrieves a datums's type.
 Returns : One of [DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS]
 Args    :

=cut

sub get_type {
    return $_[0]->{'TYPE'};
}

=item get_char()

 Type    : Accessor
 Title   : get_char
 Usage   : $char = $datum->get_char();
 Function: Retrieves a datums's character value.
 Returns : A single character.
 Args    :

=cut

sub get_char {
    return $_[0]->{'CHAR'};
}

=item get_position()

 Type    : Accessor
 Title   : get_position
 Usage   : $pos = $datum->get_position();
 Function: Retrieves a datums's position.
 Returns : a SCALAR integer.
 Args    :

=cut

sub get_position {
    return $_[0]->{'POS'};
}

=back

=head2 CONTAINER

=over

=item container()

 Type    : Internal method
 Title   : container
 Usage   : $datum->container;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container {
    return 'MATRIX';
}

=item container_type()

 Type    : Internal method
 Title   : container_type
 Usage   : $datum->container_type;
 Function:
 Returns : SCALAR
 Args    :

=cut

sub container_type {
    return 'DATUM';
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>
L<http://www.sfu.ca/~rvosa/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed
from BioPerl L<http://www.bioperl.org>, and CIPRES
L<http://www.phylo.org> and FAB* L<http://www.sfu.ca/~fabstar>
for comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
