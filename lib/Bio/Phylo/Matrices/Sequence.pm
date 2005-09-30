# $Id: Sequence.pm,v 1.9 2005/09/29 20:31:18 rvosa Exp $
# Subversion: $Rev: 177 $
package Bio::Phylo::Matrices::Sequence;
use strict;
use warnings;
use Bio::Phylo::Forest::Node;
use base 'Bio::Phylo';
use Bio::Phylo::CONSTANT qw(_ALIGNMENT_ _SEQUENCE_ _TAXON_);
use Scalar::Util qw(looks_like_number);
use fields qw(TAXON TYPE SEQ);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# List of allowed symbols. Move these to Bio::Phylo::CONSTANT, and turn
# into a hash, with translation table, nucleotide complements
my @IUPAC_NUC  = qw(A B C D G H K M N R S T U V W X Y . - ?);
my @IUPAC_PROT = qw(A B C D E F G H I K L M N P Q R S T U V W X Y Z . - ?);

=head1 NAME

Bio::Phylo::Matrices::Sequence - The molecular sequence object.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Sequence;
 use Bio::Phylo::Matrices::Alignment;
 use Bio::Phylo::Taxa::Taxon;

 #instantiating a sequence object...
 my $sequence = Bio::Phylo::Matrices::Sequence->new;
 $sequence->set_type('DNA');
 $sequence->set_seq('ACGCATCGACTCAGAC');
 
 #...and linking it to a taxon object
 $sequence->set_taxon(Bio::Phylo::Taxa::Taxon->new( -name => 'Homo_sapiens' ));
 
 #instantiate an alignment object...
 my $alignment = Bio::Phylo::Matrices::Alignment->new;
 
 #...and insert the sequence into the alignment
 $alignment->insert($sequence);

=head1 DESCRIPTION

The sequence object models a character sequence, which can be crossreferenced
with a taxon object, and inserted in an alignment object.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $sequence = Bio::Phylo::Matrices::Sequence->new;
 Function: Instantiates a Bio::Phylo::Matrices::Sequence object.
 Returns : A Bio::Phylo::Matrices::Sequence object.
 Args    : Optional arguments:
           -type  => 'DNA', (a string)
           -seq   => 'ACGCATCGACTACGCAG', (a string)
           -taxon => $taxon (a Bio::Phylo::Taxa::Taxon object)

=cut

sub new {
    my $class = shift;
    my $self  = fields::new($class);
    $self->SUPER::new(@_);
    if (@_) {
        my %opts;
        eval { %opts = @_; };
        if ($@) {
            Bio::Phylo::Exceptions::OddHash->throw( error => $@ );
        }
        while ( my ( $key, $value ) = each %opts ) {
            my $localkey = uc substr $key, 1;
            eval { $self->{$localkey} = $value; };
            if ($@) {
                Bio::Phylo::Exceptions::BadArgs->throw(
                    error => "invalid field specified: $key ($localkey)" );
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
 Usage   : $sequence->set_taxon($taxon);
 Function: Assigns the taxon a sequence refers to.
 Returns : Modified Bio::Phylo::Matrices::Sequence object.
 Args    : $taxon must be a Bio::Phylo::Taxa::Taxon object.

=cut

sub set_taxon {
    my ( $self, $taxon ) = ( $_[0], $_[1] );
    my $ref = ref $taxon;
    if ( !$taxon->can('_type') || $taxon->_type != _TAXON_ ) {
        Bio::Phylo::Exceptions::ObjectMismatch->throw(
            error => "\"$ref\" doesn't look like a taxon" );
    }
    else {
        $self->{'TAXON'} = $taxon;
    }
    return $self;
}

=item set_type()

 Type    : Mutator
 Title   : set_type
 Usage   : $sequence->set_type($type);
 Function: Assigns a sequence's type.
 Returns : Modified object.
 Args    : $type must be one of [DNA|RNA|STANDARD|PROTEIN|
           NUCLEOTIDE|CONTINUOUS]. If DNA, RNA or NUCLEOTIDE is defined, the
           subsequently set seq is validated against the IUPAC nucleotide one
           letter codes. If PROTEIN is defined, the seq is validated against
           IUPAC one letter amino acid codes. Likewise, a STANDARD seq has to
           be a single integer [0-9], while for CONTINUOUS all of Perl's number
           formats are allowed.

=cut

sub set_type {
    my ( $self, $type ) = ( $_[0], $_[1] );
    if ( $type !~ m/^(DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS)$/i ) {
        Bio::Phylo::Exceptions::BadFormat->throw(
            error => "\"$type\" is not a recognized data type" );
    }
    else {
        $self->{'TYPE'} = uc $type;
    }
    return $self;
}

=item set_seq()

 Type    : Mutator
 Title   : set_seq
 Usage   : $sequence->set_seq('ACGTCGGATCGATCGACACA');
 Function: Assigns a character string to the sequence object.
 Returns : The modified Bio::Phylo::Matrices::Sequence object.
 Args    : A character string.
 Comments: The string argument is checked against the allowed ranges for the
           various character types: IUPAC nucleotide (for types of DNA|RNA|
           NUCLEOTIDE), IUPAC single letter amino acid codes (for type PROTEIN),
           integers (STANDARD) or any of perl's decimal formats (CONTINUOUS).
           The character type must be specified first using the
           $sequence->set_type method.

=cut

sub set_seq {
    my ( $self, $seq ) = ( $_[0], $_[1] );
    my @seq = split //, $seq;
    my @sites = keys %{ { map { $_ => undef } @seq } };
    if ( my $type = $self->{'TYPE'} ) {
        if ( $type =~ /(DNA|RNA|NUCLEOTIDE)/ ) {
            my %IUPAC_NUC;
            undef @IUPAC_NUC{@IUPAC_NUC};
            foreach (@sites) {
                if ( !exists $IUPAC_NUC{$_} ) {
                    Bio::Phylo::Exceptions::BadString->throw(
                        error => "\"$_\" is not a valid $type symbol" );
                }
            }
        }
        elsif ( $type eq 'PROTEIN' ) {
            my %IUPAC_PROT;
            undef @IUPAC_PROT{@IUPAC_PROT};
            foreach (@sites) {
                if ( !exists $IUPAC_PROT{$_} ) {
                    Bio::Phylo::Exceptions::BadString->throw(
                        error => "\"$_\" is not a valid $type symbol" );
                }
            }
        }
        elsif ( $type eq 'STANDARD' ) {
            foreach (@sites) {
                if ( $_ !~ m/^(\d|\?)$/ ) {
                    Bio::Phylo::Exceptions::BadString->throw(
                        error => "\"$_\" is not a valid $type symbol" );
                }
            }
        }
        elsif ( $type eq 'CONTINUOUS' ) {
            foreach ( split /\s+/, $seq ) {
                if ( /^[^?]$/ || !looks_like_number $_ ) {
                    Bio::Phylo::Exceptions::BadString->throw(
                        error => "\"$_\" is not a valid $type symbol" );
                }
            }
        }
        $self->{'SEQ'} = $seq;
    }
    else {
        Bio::Phylo::Exceptions::BadFormat->throw(
            error => 'please define the data type first' );
    }
    return $self;
}

=back

=head2 ACCESSORS

=over

=item get_taxon()

 Type    : Accessor
 Title   : get_taxon
 Usage   : my $taxon = $sequence->get_taxon;
 Function: Retrieves the taxon a sequence refers to.
 Returns : Bio::Phylo::Taxa::Taxon
 Args    : NONE

=cut

sub get_taxon {
    return $_[0]->{'TAXON'};
}

=item get_type()

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $sequence->get_type;
 Function: Retrieves a sequence's type.
 Returns : One of [DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS]
 Args    : NONE

=cut

sub get_type {
    return $_[0]->{'TYPE'};
}

=item get_seq()

 Type    : Accessor
 Title   : get_seq
 Usage   : my $string = $sequence->get_char;
 Function: Retrieves a sequence object's raw character string;
 Returns : A character string.
 Args    : NONE

=cut

sub get_seq {
    return $_[0]->{'SEQ'};
}

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $sequence->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

sub _container { _ALIGNMENT_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $sequence->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

sub _type { _SEQUENCE_ }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

This object inherits from L<Bio::Phylo>, so the methods defined therein are also
applicable to L<Bio::Phylo::Matrices::Sequence> objects.

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

$Id: Sequence.pm,v 1.9 2005/09/29 20:31:18 rvosa Exp $

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
