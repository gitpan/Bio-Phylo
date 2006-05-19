# $Id: CONSTANT.pm,v 1.7 2006/04/12 22:38:23 rvosa Exp $
package Bio::Phylo::Util::CONSTANT;
use strict;
use Scalar::Util qw(looks_like_number);

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT_OK, %EXPORT_TAGS );

    # set the version for version checking
    use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

    # classic subroutine exporting
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(&_NONE_ &_NODE_ &_TREE_ &_FOREST_ &_TAXON_
      &_TAXA_ &_DATUM_ &_MATRIX_ &_MATRICES_ &_SEQUENCE_ &_ALIGNMENT_
      &INT_SCORE_TYPE &DOUBLE_SCORE_TYPE &NO_SCORE_TYPE &symbol_ok &type_ok
      &cipres_type &infer_type
    );
    %EXPORT_TAGS = ( all => [@EXPORT_OK] );
}
my %IUPAC_NUC = (
    'A' => 1,
    'B' => 1,
    'C' => 1,
    'D' => 1,
    'G' => 1,
    'H' => 1,
    'K' => 1,
    'M' => 1,
    'N' => 1,
    'R' => 1,
    'S' => 1,
    'T' => 1,
    'U' => 1,
    'V' => 1,
    'W' => 1,
    'X' => 1,
    'Y' => 1,
    '.' => 1,
    '-' => 1,
    '?' => 1,
);

my %IUPAC_PROT = (
    'A' => 1,
    'B' => 1,
    'C' => 1,
    'D' => 1,
    'E' => 1,
    'F' => 1,
    'G' => 1,
    'H' => 1,
    'I' => 1,
    'K' => 1,
    'L' => 1,
    'M' => 1,
    'N' => 1,
    'P' => 1,
    'Q' => 1,
    'R' => 1,
    'S' => 1,
    'T' => 1,
    'U' => 1,
    'V' => 1,
    'W' => 1,
    'X' => 1,
    'Y' => 1,
    'Z' => 1,
    '.' => 1,
    '-' => 1,
    '?' => 1,
);

my %TYPES = (
    'DNA' => {
        'CHECK' => sub {
            foreach my $char ( split( //, $_[0] ) ) {
                if ( not exists $IUPAC_NUC{ uc($char) } ) {
                    return 0;
                }
            }
            return 1;
        },
        'CIPRES' => sub {
            eval { require CipresIDL };
            if ($@) {
                Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                    'error' =>
                      'This method requires CipresIDL, which you don\'t have',
                );
            }
            else {
                return &CipresIDL::DNA_DATATYPE;
            }
        },
    },
    'RNA' => {
        'CHECK' => sub {
            foreach my $char ( split( //, $_[0] ) ) {
                if ( not exists $IUPAC_NUC{ uc($char) } ) {
                    return 0;
                }
            }
            return 1;
        },
        'CIPRES' => sub {
            eval { require CipresIDL };
            if ($@) {
                Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                    'error' =>
                      'This method requires CipresIDL, which you don\'t have',
                );
            }
            else {
                return &CipresIDL::RNA_DATATYPE;
            }
        },
    },
    'NUCLEOTIDE' => {
        'CHECK' => sub {
            foreach my $char ( split( //, $_[0] ) ) {
                if ( not exists $IUPAC_NUC{ uc($char) } ) {
                    return 0;
                }
            }
            return 1;
        },
        'CIPRES' => sub {
            eval { require CipresIDL };
            if ($@) {
                Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                    'error' =>
                      'This method requires CipresIDL, which you don\'t have',
                );
            }
            else {
                return &CipresIDL::DNA_DATATYPE;
            }
        },
    },
    'PROTEIN' => {
        'CHECK' => sub {
            foreach my $char ( split( //, $_[0] ) ) {
                if ( not exists $IUPAC_PROT{ uc($char) } ) {
                    return 0;
                }
            }
            return 1;
        },
        'CIPRES' => sub {
            eval { require CipresIDL };
            if ($@) {
                Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                    'error' =>
                      'This method requires CipresIDL, which you don\'t have',
                );
            }
            else {
                return &CipresIDL::AA_DATATYPE;
            }
        },
    },
    'STANDARD' => {
        'CHECK' => sub {
            foreach my $char ( split( /\s+/, $_[0] ) ) {
                if ( $char !~ /^\d$/ ) {
                    return 0;
                }
            }
            return 1;
        },
        'CIPRES' => sub {
            eval { require CipresIDL };
            if ($@) {
                Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                    'error' =>
                      'This method requires CipresIDL, which you don\'t have',
                );
            }
            else {
                return &CipresIDL::GENERIC_DATATYPE;
            }
        },
    },
    'CONTINUOUS' => {
        'CHECK' => sub {
            foreach my $char ( split( /\s+/, $_[0] ) ) {
                if ( !looks_like_number $char ) {
                    return 0;
                }
            }
            return 1;
        },
        'CIPRES' => sub {
            Bio::Phylo::Util::Exceptions::NotImplemented->throw(
                'error' => 'Continuous characters not implemented in Cipres.',
            );
        },
    },
);

sub _NONE_      { 1 }
sub _NODE_      { 2 }
sub _TREE_      { 3 }
sub _FOREST_    { 4 }
sub _TAXON_     { 5 }
sub _TAXA_      { 6 }
sub _DATUM_     { 7 }
sub _MATRIX_    { 8 }
sub _MATRICES_  { 9 }
sub _SEQUENCE_  { 10 }
sub _ALIGNMENT_ { 11 }

sub INT_SCORE_TYPE {
    eval { require CipresIDL };
    if ($@) {
        Bio::Phylo::Util::Exceptions::Extension::Error->throw(
            'error' => 'This method requires CipresIDL, which you don\'t have',
        );
    }
    else {
        return $CipresIDL::INT_SCORE_TYPE;
    }
}

sub DOUBLE_SCORE_TYPE {
    eval { require CipresIDL };
    if ($@) {
        Bio::Phylo::Util::Exceptions::Extension::Error->throw(
            'error' => 'This method requires CipresIDL, which you don\'t have',
        );
    }
    else {
        return $CipresIDL::DOUBLE_SCORE_TYPE;
    }
}

sub NO_SCORE_TYPE {
    eval { require CipresIDL };
    if ($@) {
        Bio::Phylo::Util::Exceptions::Extension::Error->throw(
            'error' => 'This method requires CipresIDL, which you don\'t have',
        );
    }
    else {
        return $CipresIDL::NO_SCORE_TYPE;
    }
}

sub symbol_ok {
    my %opt;
    eval { %opt = @_; };
    if ($@) {
        Bio::Phylo::Util::Exceptions::OddHash->throw( 'error' => $@, );
    }
    elsif ( defined $opt{'-type'} && defined $opt{'-char'} ) {
        if ( exists $TYPES{ uc( $opt{'-type'} ) } ) {
            if ( ref $opt{'-char'} eq 'ARRAY' ) {
                foreach my $char ( @{ $opt{'-char'} } ) {
                    return if not $TYPES{ $opt{'-type'} }->{'CHECK'}->($char);
                }
                return 1;
            }
            elsif ( $opt{'-type'} !~ m/^CONTINUOUS$/i ) {
                foreach my $char ( split( //, $opt{'-char'} ) ) {
                    return if not $TYPES{ $opt{'-type'} }->{'CHECK'}->($char);
                }
                return 1;
            }
            elsif ( $opt{'-type'} =~ m/^CONTINUOUS$/i ) {
                foreach my $char ( split( /\s+/, $opt{'-char'} ) ) {
                    return if not $TYPES{ $opt{'-type'} }->{'CHECK'}->($char);
                }
                return 1;
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::BadFormat->throw(
                error => "\"$opt{'-type'}\" is a bad data type" );
        }
    }
    elsif ( !defined $opt{'-type'} || !defined $opt{'-char'} ) {
        Bio::Phylo::Util::Exceptions::BadArgs->throw(
            'error' => 'Need \'-type\' and \'-char\' arguments', );
    }
}

sub type_ok {
    my $type = shift;
    if ( exists $TYPES{ uc($type) } ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub cipres_type {
    my $type = shift;
    if ($type) {
        if ( exists $TYPES{ uc($type) } ) {
            return $TYPES{ uc($type) }->{'CIPRES'}->();
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                'error' => "\"$type\" is not a valid data type", );
        }
    }
    else {
        Bio::Phylo::Util::Exceptions::BadArgs->throw(
            'error' => 'Need a data type to convert', );
    }
}

sub infer_type {
    my $chars = shift;
    foreach ( 'DNA', 'STANDARD', 'PROTEIN', 'CONTINUOUS' ) {
        eval { symbol_ok( '-type' => $_, '-char' => $chars ) };
        if ( not $@ ) {
            return $_;
        }
    }
    Bio::Phylo::Util::Exceptions::BadArgs->throw(
        'error' => 'No valid type found', );
}
1;
__END__

=head1 NAME

Bio::Phylo::Util::CONSTANT - Global constants for Bio::Phylo. No serviceable parts
inside.

=head1 DESCRIPTION

This package defines globals used in the Bio::Phylo libraries. The constants
are called internally by the other packages. There is no direct usage.

=head1 PUBLIC CONSTANTS

=over

=item INT_SCORE_TYPE()

 Type    : CIPRES constant
 Title   : INT_SCORE_TYPE
 Usage   : my $scoretype = INT_SCORE_TYPE;
 Function: A constant subroutine to indicate tree score is an integer value.
 Returns : INT
 Args    : NONE

=item DOUBLE_SCORE_TYPE()

 Type    : CIPRES constant
 Title   : DOUBLE_SCORE_TYPE
 Usage   : my $scoretype = DOUBLE_SCORE_TYPE;
 Function: A constant subroutine to indicate tree score is a double value.
 Returns : INT
 Args    : NONE

=item NO_SCORE_TYPE()

 Type    : CIPRES constant
 Title   : NO_SCORE_TYPE
 Usage   : my $scoretype = NO_SCORE_TYPE;
 Function: A constant subroutine to indicate tree has no score.
 Returns : INT
 Args    : NONE

=back

=head1 SUBROUTINES

=over

=item symbol_ok()

 Type    : Type checker
 Title   : symbol_ok
 Usage   : if ( symbol_ok( -type => $type, -char => $sym ) ) {
               # do something
           }
 Function: Checks whether $sym is a valid symbol for $type data
 Returns : BOOLEAN
 Args    : -type => one of [DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS]
           -char => a symbol, e.g. 'ACGT', '0.242 0.4353 0.324', etc.

=item type_ok()

 Type    : Type checker
 Title   : type_ok
 Usage   : if ( type_ok( $type ) ) {
               # do something
           }
 Function: Checks whether $type is a recognized data type
 Returns : BOOLEAN
 Args    : one of [DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS]

=item infer_type()

 Type    : Type checker
 Title   : infer_type
 Usage   : my $type = infer_type( $chars );
 Function: Attempts to identify what type $chars holds.
 Returns : one of DNA|STANDARD|PROTEIN|CONTINUOUS, or error if not found
 Args    : A string of characters.

=item cipres_type()

 Type    : Type convertor
 Title   : cipres_type
 Usage   : my $cipres_type = cipres_type($type)
 Function: Returns the cipres constant for $type
 Returns : CONSTANT
 Args    : one of [DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS]


=back

=head1 SEE ALSO

=over

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

$Id: CONSTANT.pm,v 1.7 2006/04/12 22:38:23 rvosa Exp $

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

