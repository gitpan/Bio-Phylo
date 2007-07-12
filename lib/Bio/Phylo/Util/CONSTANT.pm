# $Id: CONSTANT.pm 4169 2007-07-11 01:36:59Z rvosa $
package Bio::Phylo::Util::CONSTANT;
use strict;

sub IUPAC { 0 }
sub AMBIG { 1 }


BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT_OK, %EXPORT_TAGS );

    # set the version for version checking
    use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

    # classic subroutine exporting
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(&_NONE_ &_NODE_ &_TREE_ &_FOREST_ &_TAXON_
      &_TAXA_ &_CHAR_ &_DATUM_ &_MATRIX_ &_MATRICES_ &_SEQUENCE_ &_ALIGNMENT_
      &INT_SCORE_TYPE &DOUBLE_SCORE_TYPE &NO_SCORE_TYPE &symbol_ok &type_ok
      &cipres_type &infer_type &sym2ambig &ambig2sym
      &prot_symbols &nuc_symbols &looks_like_number
      &_CHARSTATE_ &_CHARSTATESEQ_ &_MATRIXROW_
      &DNA_DATATYPE &RNA_DATATYPE &AA_DATATYPE &CATEGORICAL_DATATYPE &CONTINUOUS_DATATYPE
    );
    %EXPORT_TAGS = ( 
        'all'       => [@EXPORT_OK],
        'datatypes' => [ 
            qw(
                &DNA_DATATYPE &RNA_DATATYPE &AA_DATATYPE 
                &CATEGORICAL_DATATYPE &CONTINUOUS_DATATYPE            
            )         
        ],
        'objecttypes' => [
            qw(
                &_NONE_ &_NODE_ &_TREE_ &_FOREST_ &_TAXON_
                &_TAXA_ &_CHAR_ &_DATUM_ &_MATRIX_ &_MATRICES_ 
                &_SEQUENCE_ &_ALIGNMENT_ &_CHARSTATE_ 
                &_CHARSTATESEQ_ &_MATRIXROW_
            )
        ],
    
    );
}
my $IUPAC_NUC = {
    'A' => 0,
    'B' => 1,
    'C' => 2,
    'D' => 3,
    'G' => 4,
    'H' => 5,
    'K' => 6,
    'M' => 7,
    'N' => 8,
    'R' => 9,
    'S' => 10,
    'T' => 11,
    'U' => 12,
    'V' => 13,
    'W' => 14,
    'X' => 15,
    'Y' => 16,
    '.' => 17,
    '-' => 18,
    '?' => 19,
};
my $NUC_LOOKUP = [
    [ 'A' => [  $IUPAC_NUC->{'A'}           ] ],
    [ 'B' => [ @$IUPAC_NUC{'C','G','T'}     ] ],
    [ 'C' => [  $IUPAC_NUC->{'C'}           ] ],
    [ 'D' => [ @$IUPAC_NUC{'A','G','T'}     ] ],
    [ 'G' => [  $IUPAC_NUC->{'G'}           ] ],
    [ 'H' => [ @$IUPAC_NUC{'A','C','T'}     ] ],
    [ 'K' => [ @$IUPAC_NUC{'G','T'}         ] ],
    [ 'M' => [ @$IUPAC_NUC{'A','C'}         ] ],
    [ 'N' => [ @$IUPAC_NUC{'A','C','G','T'} ] ],
    [ 'R' => [ @$IUPAC_NUC{'A','G'}         ] ],
    [ 'S' => [ @$IUPAC_NUC{'C','G'}         ] ],
    [ 'T' => [  $IUPAC_NUC->{'T'}           ] ],
    [ 'U' => [  $IUPAC_NUC->{'U'}           ] ],
    [ 'V' => [ @$IUPAC_NUC{'A','C','G'}     ] ],
    [ 'W' => [ @$IUPAC_NUC{'A','T'}         ] ],
    [ 'X' => [ @$IUPAC_NUC{'A','C','G','T'} ] ],
    [ 'Y' => [ @$IUPAC_NUC{'C','T'}         ] ],
    [ '.' => [ @$IUPAC_NUC{'A','C','G','T'} ] ],
    [ '-' => [                              ] ],
    [ '?' => [ @$IUPAC_NUC{'A','C','G','T'} ] ],
];

my $IUPAC_PROT = {
    'A' => 0,
    'B' => 1,
    'C' => 2,
    'D' => 3,
    'E' => 4,
    'F' => 5,
    'G' => 6,
    'H' => 7,
    'I' => 8,
    'K' => 9,
    'L' => 10,
    'M' => 11,
    'N' => 12,
    'P' => 13,
    'Q' => 14,
    'R' => 15,
    'S' => 16,
    'T' => 17,
    'U' => 18,
    'V' => 19,
    'W' => 20,
    'X' => 21,
    'Y' => 22,
    'Z' => 23,
    '.' => 24,
    '-' => 25,
    '?' => 26,
    '*' => 27,
};
my $PROT_LOOKUP = [
    [ 'A' => [ $IUPAC_PROT->{'A'}     ] ],
    [ 'B' => [ @$IUPAC_PROT{'D','N'}  ] ],
    [ 'C' => [ $IUPAC_PROT->{'C'}     ] ],
    [ 'D' => [ $IUPAC_PROT->{'D'}     ] ],
    [ 'E' => [ $IUPAC_PROT->{'E'}     ] ],
    [ 'F' => [ $IUPAC_PROT->{'F'}     ] ],
    [ 'G' => [ $IUPAC_PROT->{'G'}     ] ],
    [ 'H' => [ $IUPAC_PROT->{'H'}     ] ],
    [ 'I' => [ $IUPAC_PROT->{'I'}     ] ],
    [ 'K' => [ $IUPAC_PROT->{'K'}     ] ],
    [ 'L' => [ $IUPAC_PROT->{'L'}     ] ],
    [ 'M' => [ $IUPAC_PROT->{'M'}     ] ],
    [ 'N' => [ $IUPAC_PROT->{'N'}     ] ],
    [ 'P' => [ $IUPAC_PROT->{'P'}     ] ],
    [ 'Q' => [ $IUPAC_PROT->{'Q'}     ] ],
    [ 'R' => [ $IUPAC_PROT->{'R'}     ] ],
    [ 'S' => [ $IUPAC_PROT->{'S'}     ] ],
    [ 'T' => [ $IUPAC_PROT->{'T'}     ] ],
    [ 'U' => [ $IUPAC_PROT->{'U'}     ] ],
    [ 'V' => [ $IUPAC_PROT->{'V'}     ] ],
    [ 'W' => [ $IUPAC_PROT->{'W'}     ] ],
    [ 'X' => [ $IUPAC_PROT->{'X'}     ] ],
    [ 'Y' => [ $IUPAC_PROT->{'Y'}     ] ],
    [ 'Z' => [ @$IUPAC_PROT{'E','Q'}  ] ],
    [ '.' => [ $IUPAC_PROT->{ @{ &prot_symbols } } ] ],
    [ '-' => [                        ] ],
    [ '?' => [ $IUPAC_PROT->{ @{ &prot_symbols } } ] ],
    [ '*' => [ $IUPAC_PROT->{'*'}     ] ],
];

my $TYPES = [];

$TYPES->[ &DNA_DATATYPE ] = {
    'CHECK' => sub {
        foreach my $char ( split( //, $_[0] ) ) {
            if ( not exists $IUPAC_NUC->{ uc($char) } ) {
                return 0;
            }
        }
        return 1;
    },
    'CIPRES' => sub {
        eval { require CipresIDL_api1 };
        if ($@) {
            Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                'error' =>
                  'This method requires CipresIDL_api1, which you don\'t have',
            );
        }
        else {
            return &CipresIDL_api1::DNA_DATATYPE;
        }
    },
};

$TYPES->[ &RNA_DATATYPE ] = {
    'CHECK' => sub {
        foreach my $char ( split( //, $_[0] ) ) {
            if ( not exists $IUPAC_NUC->{ uc($char) } ) {
                return 0;
            }
        }
        return 1;
    },
    'CIPRES' => sub {
        eval { require CipresIDL_api1 };
        if ($@) {
            Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                'error' =>
                  'This method requires CipresIDL_api1, which you don\'t have',
            );
        }
        else {
            return &CipresIDL_api1::RNA_DATATYPE;
        }
    },
};

$TYPES->[ &AA_DATATYPE ] = {
    'CHECK' => sub {
        foreach my $char ( split( //, $_[0] ) ) {
            if ( not exists $IUPAC_PROT->{ uc($char) } ) {
                return 0;
            }
        }
        return 1;
    },
    'CIPRES' => sub {
        eval { require CipresIDL_api1 };
        if ($@) {
            Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                'error' =>
                  'This method requires CipresIDL_api1, which you don\'t have',
            );
        }
        else {
            return &CipresIDL_api1::AA_DATATYPE;
        }
    },
};

$TYPES->[ &CATEGORICAL_DATATYPE ] = {
    'CHECK' => sub {
        foreach my $char ( split( /\s+/, $_[0] ) ) {
            if ( $char !~ /^\d$/ ) {
                return 0;
            }
        }
        return 1;
    },
    'CIPRES' => sub {
        eval { require CipresIDL_api1 };
        if ($@) {
            Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                'error' =>
                  'This method requires CipresIDL_api1, which you don\'t have',
            );
        }
        else {
            return &CipresIDL_api1::GENERIC_DATATYPE;
        }
    },
};
$TYPES->[ &CONTINUOUS_DATATYPE ] = {
    'CHECK' => sub {
        foreach my $char ( split( /\s+/, $_[0] ) ) {
            if ( ! &looks_like_number( $char ) ) {
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
};

sub _NONE_      { 1  }
sub _NODE_      { 2  }
sub _TREE_      { 3  }
sub _FOREST_    { 4  }
sub _TAXON_     { 5  }
sub _TAXA_      { 6  }
sub _DATUM_     { 7  }
sub _MATRIX_    { 8  }
sub _MATRICES_  { 9  }
sub _SEQUENCE_  { 10 }
sub _ALIGNMENT_ { 11 }
sub _CHAR_      { 12 }

sub _CHARSTATE_    { 13 }
sub _CHARSTATESEQ_ { 14 }
sub _MATRIXROW_    { 15 }

sub DNA_DATATYPE         { 0 }
sub RNA_DATATYPE         { 1 }
sub AA_DATATYPE          { 2 }
sub CATEGORICAL_DATATYPE { 3 }
sub CONTINUOUS_DATATYPE  { 4 }
sub CUSTOM_DATATYPE      { 5 }

sub INT_SCORE_TYPE {
    eval { require CipresIDL_api1 };
    if ($@) {
        Bio::Phylo::Util::Exceptions::Extension::Error->throw(
            'error' => 'This method requires CipresIDL, which you don\'t have',
        );
    }
    else {
        return $CipresIDL_api1::INT_SCORE_TYPE;
    }
}

sub DOUBLE_SCORE_TYPE {
    eval { require CipresIDL_api1 };
    if ($@) {
        Bio::Phylo::Util::Exceptions::Extension::Error->throw(
            'error' => 'This method requires CipresIDL, which you don\'t have',
        );
    }
    else {
        return $CipresIDL_api1::DOUBLE_SCORE_TYPE;
    }
}

sub NO_SCORE_TYPE {
    eval { require CipresIDL_api1 };
    if ($@) {
        Bio::Phylo::Util::Exceptions::Extension::Error->throw(
            'error' => 'This method requires CipresIDL, which you don\'t have',
        );
    }
    else {
        return $CipresIDL_api1::NO_SCORE_TYPE;
    }
}

sub symbol_ok {
    my %opt;
    eval { %opt = @_; };
    if ($@) {
        Bio::Phylo::Util::Exceptions::OddHash->throw( 'error' => $@, );
    }
    elsif ( defined $opt{'-type'} && defined $opt{'-char'} ) {
        if ( $opt{'-type'} =~ qr/^\d+$/ && exists $TYPES->[ $opt{'-type'} ] ) {
            if ( ref $opt{'-char'} eq 'ARRAY' ) {
                foreach my $char ( @{ $opt{'-char'} } ) {
                    return if not $TYPES->[ $opt{'-type'} ]->{'CHECK'}->($char);
                }
                return 1;
            }
            elsif ( $opt{'-type'} != CONTINUOUS_DATATYPE ) {
                foreach my $char ( split( //, $opt{'-char'} ) ) {
                    return if not $TYPES->[ $opt{'-type'} ]->{'CHECK'}->($char);
                }
                return 1;
            }
            elsif ( $opt{'-type'} == CONTINUOUS_DATATYPE ) {
                foreach my $char ( split( /\s+/, $opt{'-char'} ) ) {
                    return if not $TYPES->[ $opt{'-type'} ]->{'CHECK'}->($char);
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
    if ( $type =~ m/^\d+$/ and exists $TYPES->[ $type ] ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub cipres_type {
    my $type = shift;
    if ($type) {
        if ( exists $TYPES->{ uc($type) } ) {
            return $TYPES->{ uc($type) }->{'CIPRES'}->();
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
    for ( 'DNA', 'STANDARD', 'PROTEIN', 'CONTINUOUS' ) {
        eval { symbol_ok( '-type' => $_, '-char' => $chars ) };
        if ( not $@ ) {
            return $_;
        }
    }
    Bio::Phylo::Util::Exceptions::BadArgs->throw(
        'error' => 'No valid type found', 
    );
}

sub sym2ambig {
    my %opt;
    eval { %opt = @_ };
    if ( $@ ) {
        Bio::Phylo::Util::Exceptions::OddHash->throw(
            'error' => $@,
        );
    }
    else {
        if ( not symbol_ok(%opt) ) {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                'error' => "Bad symbol \"$opt{-char}\" for type $opt{-type}"
            );
        }
        my $const = $opt{'-type'} =~ m/^PROTEIN$/i ? $IUPAC_PROT->{$opt{'-char'}} : $IUPAC_NUC->{$opt{'-char'}};
        if ( $opt{'-type'} =~ m/^(?:DNA|RNA)$/i ) {
            my @symbols;
            foreach ( @{ $NUC_LOOKUP->[ $const ]->[ AMBIG ] } ) {
                push @symbols, $NUC_LOOKUP->[ $_ ]->[ IUPAC ];
            }
            return \@symbols;
        }
        elsif ( $opt{'-type'} =~ m/^PROTEIN$/i ) {
            my @symbols;
            foreach ( @{ $PROT_LOOKUP->[ $const ]->[ AMBIG ] } ) {
                push @symbols, $PROT_LOOKUP->[ $_ ]->[ IUPAC ];
            }
            return \@symbols;
        }
        else {
            return $const;
        }
    }
}

sub ambig2sym {
    my %opt;
    eval { %opt = @_ };
    if ( $@ ) {
        Bio::Phylo::Util::Exceptions::OddHash->throw(
            'error' => $@,
        );
    }
    else {
        my $charstr = uc( join( '', sort { $a cmp $b } @{ $opt{'-ambig'} } ) );
        if ( not symbol_ok( '-type' => $opt{'-type'}, '-char' => $charstr ) ) {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                'error' => "Bad symbols \"$charstr\" for type $opt{-type}"
            );
        }
        if ( $opt{'-type'} =~ m/^(?:DNA|RNA)$/i ) {
            my @indices = sort { $a <=> $b } map { $IUPAC_NUC->{$_} } @{ $opt{'-ambig'} };
            NUC_LOOKUP: foreach ( @{ $NUC_LOOKUP } ) {
                next NUC_LOOKUP if scalar(@indices) != scalar( @{ $_->[ AMBIG ] } );
                my @ambig = sort { $a <=> $b } @{ $_->[ AMBIG ] };
                for my $i ( 0 .. $#ambig ) {
                    next NUC_LOOKUP if $ambig[$i] != $indices[$i];
                }
                return $_->[ IUPAC ];
            }
        }
        elsif ( $opt{'-type'} =~ m/^PROTEIN$/i ) {
            PROT_LOOKUP: my @indices = sort { $a <=> $b } map { $IUPAC_PROT->{$_} } @{ $opt{'-ambig'} };
            foreach ( @{ $PROT_LOOKUP } ) {
                next PROT_LOOKUP if scalar(@indices) != scalar( @{ $_->[ AMBIG ] } );
                my @ambig = sort { $a <=> $b } @{ $_->[ AMBIG ] };
                for my $i ( 0 .. $#ambig ) {
                    next PROT_LOOKUP if $ambig[$i] != $indices[$i];
                }
                return $_->[ IUPAC ];
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                'error' => "No ambiguity codes for $opt{-type}"
            );
        }
        Bio::Phylo::Util::Exceptions::BadArgs->throw(
            'error' => 'Ambiguity code not found',
        );
    }
}

sub nuc_symbols {
    my @symbols;
    foreach ( @{ $NUC_LOOKUP } ) {
        push @symbols, $_->[ IUPAC ];
    }
    return \@symbols;
}

sub prot_symbols {
    my @symbols;
    foreach ( @{ $PROT_LOOKUP } ) {
        push @symbols, $_->[ IUPAC ];
    }
    return \@symbols;
}

# this is a drop in replacement for Scalar::Util's function
my $LOOKS_LIKE_NUMBER = qr/^([-+]?\d+(\.\d+)?([eE][-+]\d+)?|Inf|NaN)$/;
sub looks_like_number($) {
    my $num = shift;
    if ( defined $num and $num =~ $LOOKS_LIKE_NUMBER ) {
        return 1;
    }
    else {
        return;
    }
}

1;
__END__

=head1 NAME

Bio::Phylo::Util::CONSTANT - This package defines global constants and utility
functions that operate on them.

=head1 DESCRIPTION

This package defines globals used in the Bio::Phylo libraries. The constants
are called internally by the other packages. There is no direct usage.

=head1 PUBLIC CONSTANTS

=over

=item AA_DATATYPE()

Constant for amino acid data type.

 Type    : Constant
 Title   : AA_DATATYPE
 Usage   : my $datatype = AA_DATATYPE;
 Function: A constant subroutine to indicate matrix datatype is amino acid.
 Returns : INT
 Args    : NONE

=item CATEGORICAL_DATATYPE()

Constant for categorical data type.

 Type    : Constant
 Title   : CATEGORICAL_DATATYPE
 Usage   : my $datatype = CATEGORICAL_DATATYPE;
 Function: A constant subroutine to indicate matrix datatype is 'standard'.
 Returns : INT
 Args    : NONE

=item CONTINUOUS_DATATYPE()

Constant for continuous data type.

 Type    : Constant
 Title   : CONTINUOUS_DATATYPE
 Usage   : my $datatype = CONTINUOUS_DATATYPE;
 Function: A constant subroutine to indicate matrix datatype is 'continuous'.
 Returns : INT
 Args    : NONE

=item DNA_DATATYPE()

Constant for dna data type.

 Type    : Constant
 Title   : DNA_DATATYPE
 Usage   : my $datatype = DNA_DATATYPE;
 Function: A constant subroutine to indicate matrix datatype is dna/nucleotides.
 Returns : INT
 Args    : NONE

=item RNA_DATATYPE()

Constant for rna data type.

 Type    : Constant
 Title   : RNA_DATATYPE
 Usage   : my $datatype = RNA_DATATYPE;
 Function: A constant subroutine to indicate matrix datatype is rna.
 Returns : INT
 Args    : NONE

=item CUSTOM_DATATYPE()

Constant for custom data type.

 Type    : Constant
 Title   : CUSTOM_DATATYPE
 Usage   : my $datatype = CUSTOM_DATATYPE;
 Function: A constant subroutine to indicate matrix datatype is defined by
           a custom ambiguity lookup table, e.g. for "mixed" molecular
           and standard categorical data.
 Returns : INT
 Args    : NONE

=item INT_SCORE_TYPE()

Constant for integer tree score.

 Type    : CIPRES constant
 Title   : INT_SCORE_TYPE
 Usage   : my $scoretype = INT_SCORE_TYPE;
 Function: A constant subroutine to indicate tree score is an integer value.
 Returns : INT
 Args    : NONE

=item DOUBLE_SCORE_TYPE()

Constant for double tree score.

 Type    : CIPRES constant
 Title   : DOUBLE_SCORE_TYPE
 Usage   : my $scoretype = DOUBLE_SCORE_TYPE;
 Function: A constant subroutine to indicate tree score is a double value.
 Returns : INT
 Args    : NONE

=item NO_SCORE_TYPE()

Constant for no tree score.

 Type    : CIPRES constant
 Title   : NO_SCORE_TYPE
 Usage   : my $scoretype = NO_SCORE_TYPE;
 Function: A constant subroutine to indicate tree has no score.
 Returns : INT
 Args    : NONE

=item IUPAC ()

IUPAC constants.

 Type    : constant
 Title   : IUPAC
 Usage   : no direct usage
 Function: no direct usage
 Returns : INT
 Args    : NONE

=item AMBIG ()

IUPAC ambiguity codes.

 Type    : constant
 Title   : AMBIG
 Usage   : no direct usage
 Function: no direct usage
 Returns : INT
 Args    : NONE

=back

=head1 SUBROUTINES

=over

=item symbol_ok()

Checks symbol (deprecated).

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

Checks data type (deprecated)

 Type    : Type checker
 Title   : type_ok
 Usage   : if ( type_ok( $type ) ) {
               # do something
           }
 Function: Checks whether $type is a recognized data type
 Returns : BOOLEAN
 Args    : one of [DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS]

=item infer_type()

Infers data type (deprecated)

 Type    : Type checker
 Title   : infer_type
 Usage   : my $type = infer_type( $chars );
 Function: Attempts to identify what type $chars holds.
 Returns : one of DNA|STANDARD|PROTEIN|CONTINUOUS, or error if not found
 Args    : A string of characters.

=item cipres_type()

Converts to CIPRES data type constant.

 Type    : Type convertor
 Title   : cipres_type
 Usage   : my $cipres_type = cipres_type($type)
 Function: Returns the cipres constant for $type
 Returns : CONSTANT
 Args    : one of [DNA|RNA|STANDARD|PROTEIN|NUCLEOTIDE|CONTINUOUS]


=item sym2ambig()

Returns the set of symbols defined by the ambiguity symbol (deprecated)

 Type    : Type convertor
 Title   : sym2ambig
 Usage   : my @ambig = @{ sym2ambig( -type => 'DNA', -char => 'N' ) };
 Function: Returns the set of symbols defined by the ambiguity symbol
 Returns : ARRAY
 Args    : -type => one of [DNA|RNA|PROTEIN|NUCLEOTIDE]
           -char => an IUPAC ambiguity symbol

=item ambig2sym()

Returns the iupac ambiguity symbol for a set of symbols (deprecated)

 Type    : Type convertor
 Title   : ambig2sym
 Usage   : my $sym = ambig2sym( -type => 'DNA', -char => [ 'A', 'C' ] );
 Function: Returns the iupac ambiguity symbol for a set of symbols
 Returns : SCALAR
 Args    : -type => one of [DNA|RNA|PROTEIN|NUCLEOTIDE]
           -char => an array of symbols

=item nuc_symbols()

Returns the iupac ambiguity symbols for nucleotide data (deprecated)

 Type    : Constant
 Title   : nuc_symbols
 Usage   : my @symbols = @{ nuc_symbols };
 Function: Returns the iupac ambiguity symbols for nucleotide data
 Returns : ARRAY
 Args    : NONE

=item prot_symbols()

Returns the iupac ambiguity symbols for protein data (deprecated)

 Type    : Constant
 Title   : prot_symbols
 Usage   : my @symbols = @{ prot_symbols };
 Function: Returns the iupac ambiguity symbols for protein data
 Returns : ARRAY
 Args    : NONE

=item looks_like_number()

Tests if argument looks like a number.

 Type    : Constant
 Title   : looks_like_number
 Usage   : do 'something' if looks_like_number $var;
 Function: Tests whether $var looks like a number.
 Returns : TRUE or undef
 Args    : $var = a variable to test

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

$Id: CONSTANT.pm 4169 2007-07-11 01:36:59Z rvosa $

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

