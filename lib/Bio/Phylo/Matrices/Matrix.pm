# $Id: Matrix.pm 2187 2006-09-07 07:13:33Z rvosa $
package Bio::Phylo::Matrices::Matrix;
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::IO qw(unparse);
use Bio::Phylo::Util::CONSTANT
qw(_MATRICES_ _MATRIX_ _TAXON_ _TAXA_ _DATUM_ symbol_ok type_ok cipres_type infer_type looks_like_number);
use Scalar::Util qw(weaken);
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Taxa;
use Bio::Phylo::Taxa::Taxon;

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo::Listable);

# Inherited Bio::Matrix::MatrixI methods
*matrix_id    = sub { return $_[0]->get_id };
*matrix_name  = sub { return $_[0]->get_name };
*num_rows     = sub { return $_[0]->get_ntax };
*num_columns  = sub { return $_[0]->get_nchar };
*column_names = sub { return $_[0]->get_char_labels };
*row_names    = sub { return map { $_->get_name } @{ $_[0]->get_entities } };
# get_entry($row,$col)
# get_column($col)
# get_row($row)
# get_diagonal()
*column_num_for_name = sub { 
    my $labels = $_[0]->get_char_labels;
    for my $i ( 0 .. $#{ $labels } ) {
        return $i if $labels->[$i] eq $_[1];
    }
    return;
};
# row_num_for_name($name)

# Bio::Matrix::GenericMatrix methods
# add_row($row)
# remove_row($row)
# add_column($col)
# remove_column($col)
{

    # inside out class arrays
    my @taxa;
    my @char_labels;

    # $fields hashref necessary for object destruction
    my $fields = {
        '-taxa'   => \@taxa,
        '-labels' => \@char_labels,
    };

=head1 NAME

Bio::Phylo::Matrices::Matrix - Character state matrix.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Matrix;
 use Bio::Phylo::Taxa;
 use Bio::Phylo::Taxa::Taxon;

 # instantiate taxa object
 my $taxa = Bio::Phylo::Taxa->new();
 for ( 'Homo sapiens', 'Pan paniscus', 'Pan troglodytes' ) {
     $taxa->insert( Bio::Phylo::Taxa::Taxon->new( '-name' => $_ ) );
 }

 # instantiate matrix object
 my $matrix = Bio::Phylo::Matrices::Matrix->new(
     '-taxa'   => $taxa,
     '-type'   => 'STANDARD',
     '-lookup' => { 
         '-' => [],
         '0' => [ '0' ],
         '1' => [ '1' ],
         '?' => [ '0', '1' ],
     },
     '-labels' => [ 'Opposable big toes', 'Opposable thumbs', 'Not a pygmy' ],
     '-matrix' => [
         [ 'Homo sapiens'    => '0', '1', '1' ],
         [ 'Pan paniscus'    => '1', '1', '0' ],
         [ 'Pan troglodytes' => '1', '1', '1' ],
     ],
 );

=head1 DESCRIPTION

This module defines a container object that holds
L<Bio::Phylo::Matrices::Datum> objects. The matrix
object inherits from L<Bio::Phylo::Listable>, so the
methods defined there apply here.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $matrix = Bio::Phylo::Matrices::Matrix->new;
 Function: Instantiates a Bio::Phylo::Matrices::Matrix
           object.
 Returns : A Bio::Phylo::Matrices::Matrix object.
 Args    : -type   => required, datatype, one of dna|rna|protein|
                      continuous|standard|restriction|mixed
           -taxa   => optional, link to taxa object
           -lookup => character state lookup hash ref
           -labels => array ref of character labels
           -matrix => two-dimensional array, first element of every
                      row is label, subsequent are characters

=cut

    sub new {
        my ( $class, $self ) = shift;
        $self = __PACKAGE__->SUPER::new(@_);
        bless $self, __PACKAGE__;
        if (@_) {
            my %opt;
            eval { %opt = @_; };
            if ( $@ ) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( 'error' => $@ );
            }
            else {
                if ( not $opt{'-type'} ) {
                    Bio::Phylo::Util::Exceptions::BadArgs->throw(
                        'error' => '"-type" must be defined in constructor'
                    );
                }
                else {
                    my $class = __PACKAGE__ . '::' . lc( $opt{'-type'} );
                    eval { $self = $class->new( $self, $opt{'-lookup'} ); };
                    if ( $@ ) {
                        Bio::Phylo::Util::Exceptions::BadFormat->throw(
                            'error' => "Type \"$opt{'-type'}\" not supported"
                        );
                    }                
                }
                if ( exists $opt{'-labels'} ) {
                    eval { $char_labels[ $self->get_id ] = [ @{ $opt{'-labels'} } ] };
                    if ( $@ ) {
                        Bio::Phylo::Util::Exceptions::BadArgs->throw(
                            'error' => $@
                        );                    
                    }
                }
                else {
                    $char_labels[ $self->get_id ] = [];
                }
                if ( exists $opt{'-matrix'} ) {
                    foreach my $row ( @{ $opt{'-matrix'} } ) {
                        $self->insert(
                            Bio::Phylo::Matrices::CharSeq->new(
                                shift( @{ $row } ),
                                $row,
                            )
                        );
                    }
                }
            }
        }
        $self->_set_super;
        return $self;
    }

=back

=head2 MUTATORS

=over

=item set_taxa()

 Type    : Mutator
 Title   : set_taxa
 Usage   : $matrix->set_taxa( $taxa );
 Function: Links the invocant matrix object
           to a taxa object. Individual datum
           objects are linked to individual taxon
           objects by name, i.e. by what is
           returned by $datum->get_name
 Returns : $matrix
 Args    : A Bio::Phylo::Taxa object.
 Comments: This method checks whether any
           of the datum objects in the
           invocant link to Bio::Phylo::Taxa::Taxon
           objects not contained by $matrix. If
           found, these are set to undef and the
           following message is displayed:

           "Reset X references from datum objects
           to taxa outside taxa block"

=cut

    sub set_taxa {
        my ( $self, $taxa ) = @_;
        if ( defined $taxa ) {
            if ( blessed $taxa ) {
                if ( $taxa->can('_type') && $taxa->_type == _TAXA_ ) {
                    my %taxa = map { $_ => $_ } @{ $taxa->get_entities };
                    my %name;
                    while ( my ( $k, $v ) = each %taxa ) {
                        $name{$v} = $k;
                    }
                    my $replaced = 0;
                    while ( my $datum = $self->next ) {
                        if ( my $taxon = $datum->get_taxon ) {
                            if ( !exists $taxa{$taxon} ) {
                                $datum->set_taxon(undef);
                                $replaced++;
                            }
                        }
                        elsif ( $datum->get_name
                            and exists $name{ $datum->get_name } )
                        {
                            $datum->set_taxon( $name{ $datum->get_name } );
                        }
                    }
                    if ($replaced) {
                        warn
"Reset $replaced references from datum objects to taxa outside taxa block";
                    }
                    $taxa[ $self->get_id ] = $taxa;
                    weaken( $taxa[ $self->get_id ] );
                    $taxa->set_matrix($self);
                }
                else {
                    Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                        error => "\"$taxa\" doesn't look like a taxa object" );
                }
            }
            else {
                Bio::Phylo::Util::Exceptions::BadArgs->throw(
                    error => "\"$taxa\" is not a blessed object!" );
            }
        }
        else {
            $taxa[ $self->get_id ] = undef;
        }
        return $self;
    }

=item set_charlabels()

 Type    : Mutator
 Title   : set_charlabels
 Usage   : $matrix->set_charlabels( [ 'char1', 'char2', 'char3' ] );
 Function: Assigns character labels.
 Returns : $self
 Args    : ARRAY
 
=cut

    sub set_charlabels {
        my ( $self, $labels ) = @_;
        $char_labels[ $self->get_id ] = $labels;
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_type()

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $matrix->get_type;
 Function: Retrieves a matrix's type.
 Returns : SCALAR =~ (DNA|RNA|STANDARD|
           PROTEIN|NUCLEOTIDE|CONTINUOUS);
 Args    : NONE

=cut

# implemented by subclasses, see below

=item get_symbols()

 Type    : Accessor
 Title   : get_symbols
 Usage   : my $symbols = $matrix->get_symbols;
 Function: Retrieves a matrix's symbol table.
 Returns : ARRAY
 Args    : NONE

=cut

    sub get_symbols {
        my $self = shift;
        return [ keys %{ $self->get_charstate_lookup } ];
    }


=item get_num_states()

 Type    : Accessor
 Title   : get_num_states
 Usage   : my $nstates = $matrix->get_num_states;
 Function: Retrieves the number of distinct
           states in the matrix
 Returns : SCALAR
 Args    : NONE

=cut

    sub get_num_states {
        my $self = shift;
        return scalar @{ $self->get_symbols };
    }

=item get_taxa()

 Type    : Accessor
 Title   : get_taxa
 Usage   : my $taxa = $matrix->get_taxa;
 Function: Retrieves the Bio::Phylo::Taxa
           object linked to the invocant.
 Returns : Bio::Phylo::Taxa
 Args    : NONE
 Comments: This method returns the Bio::Phylo::Taxa
           object to which the invocant is linked.
           The returned object can therefore contain
           *more* taxa than are actually in the matrix.

=cut

    sub get_taxa {
        my $self = shift;
        return $taxa[ $self->get_id ];
    }

=item get_chars_for_taxon()

 Type    : Accessor
 Title   : get_chars_for_taxon
 Usage   : my @chars = @{
               $matrix->get_chars_for_taxon($taxon)
           };
 Function: Retrieves the datum
           objects for $taxon
 Returns : ARRAY
 Args    : A Bio::Phylo::Taxa::Taxon object

=cut

    sub get_chars_for_taxon {
        my ( $self, $taxon ) = @_;
        my @chars;
        if ($taxon) {
            if ( $taxon->can('_type') && $taxon->_type == _TAXON_ ) {
                foreach my $datum ( @{ $self->get_entities } ) {
                    if ( my $tax = $datum->get_taxon ) {
                        push @chars, $datum if $tax == $taxon;
                    }
                }
            }
            else {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    'error' => "\"$taxon\" is not a valid taxon", );
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                'error' => 'Need a taxon to match against', );
        }
        return \@chars;
    }

=item get_cols()

 Type    : Accessor
 Title   : get_cols
 Usage   : my $cols = $matrix->get_cols( 0 .. 100 );
 Function: Retrieves columns in $matrix
 Returns : Bio::Phylo::Matrices::Matrix (shallow copy)
 Args    : Column numbers, zero-based,
           throws exception if out of bounds.
 Notes   : This method can be used as a makeshift
           bootstrapper/jackknifer. The trick is to
           create the appropriate argument list, i.e.
           for bootstrapping one with the same number
           of elements as there are columns in the
           matrix - but resampled with replacement;
           for jackknifing a list where the number
           of elements is that of the number of columns
           to keep. You can generate such a list by
           iteratively calling shift(shuffle(@list))
           where shuffle comes from the List::Util
           package.

=cut

    sub get_cols {
        my $self  = shift->_flatten;
        my $copy  = $self->copy_atts;
        my @range = @_;
        while ( my $taxon = $self->get_taxa->next ) {
            my $datum   = shift @{ $self->get_chars_for_taxon($taxon) };
            my $charstr = $datum->get_char;
            my $chars   =
                ref $charstr ? $charstr
              : $datum->get_type =~ m/CONT/ ? [ split( /\s+/, $charstr ) ]
              : [ split( //, $charstr ) ];
            my $newchars = [];
            for my $i (@range) {
                if ( exists $chars->[$i] ) {
                    push @{$newchars}, $chars->[$i];
                }
                else {
                    Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                        'error' => "Character position index $i out of bounds",
                    );
                }
            }
            my $newdat = $datum->copy_atts;
            $newdat->set_char($newchars);
            $copy->insert($newdat);
        }
        return $copy;
    }

=item get_rows()

 Type    : Accessor
 Title   : get_rows
 Usage   : my $rows = $matrix->get_rows( 0 .. 100 );
 Function: Retrieves rows in $matrix
 Returns : Bio::Phylo::Matrices::Matrix (shallow copy)
 Args    : Row numbers, zero-based, throws
           exception if out of bounds.
 Notes   :

=cut

    sub get_rows {
        my $self  = shift->_flatten;
        my $copy  = $self->copy_atts;
        my @range = @_;
        my $taxa  = $self->get_taxa->get_entities;
        for my $i (@range) {
            if ( my $taxon = $taxa->[$i] ) {
                foreach my $datum ( @{ $self->get_chars_for_taxon($taxon) } ) {
                    my $datcopy = $datum->copy_atts;
                    $datcopy->set_char( $datum->get_char );
                    $copy->insert($datcopy);
                }
            }
            else {
                Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                    'error' => "Taxon position index $i out of bounds", );
            }
        }
        return $copy;
    }

=item get_charlabels()

 Type    : Accessor
 Title   : get_charlabels
 Usage   : $matrix->get_charlabels;
 Function: Retrieves character labels.
 Returns : ARRAY
 Args    : None.
 
=cut

    sub get_charlabels {
        my $self = shift;
        return $char_labels[ $self->get_id ];
    }

=item get_missing()

 Type    : Accessor
 Title   : get_missing
 Usage   : $matrix->get_missing;
 Function: Retrieves the missing data symbol.
 Returns : A single character.
 Args    : None.

=cut

    sub get_missing {
        my $self = shift;
        my $lookup  = $self->get_charstate_lookup;
        my @missing = map   { $_->[0] }
                      sort  { $b->[1] <=> $a->[1] } 
                      map   { [ $_, scalar @{ $lookup->{$_} } ] }
                      keys %{ $lookup };
        return $missing[0];
    }

=item get_gap()

 Type    : Accessor
 Title   : get_gap
 Usage   : $matrix->get_gap;
 Function: Retrieves the gap (indel?) character symbol.
 Returns : A single character.
 Args    : None.

=cut

    sub get_gap {
        my $self   = shift;
        my $lookup = $self->get_charstate_lookup;
        my @gap    = map   { $_->[0] }
                     sort  { $a->[1] <=> $b->[1] } 
                     map   { [ $_, scalar @{ $lookup->{$_} } ] }
                     keys %{ $lookup };
        return $gap[0];
    }

=item get_ntax()

 Type    : Accessor
 Title   : get_ntax
 Usage   : my $ntax = $matrix->get_ntax;
 Function: Retrieves the intended number of
           taxa for the matrix.
 Returns : An integer, or undefined.
 Args    : None.
 Comments: The return value is whatever was
           set by the 'set_ntax' method call.
           'get_ntax' is used by the 'validate'
           method to check if the computed
           number of taxa matches with
           what is asserted here. In other words,
           this method does not return the
           *actual* number of taxa in the matrix
           (use 'get_num_taxa' for that), but the
           number it is supposed to have.

=cut

    sub get_ntax {
        my $self = shift;
        return scalar @{ $self->get_entities };
    }

=item get_nchar()

 Type    : Accessor
 Title   : get_nchar
 Usage   : $matrix->get_nchar;
 Function: Retrieves the intended number of
           characters for the matrix.
 Returns : An integer, or undefined.
 Args    : None.
 Comments: The return value is whatever was
           set by the 'set_nchar' method call.
           'get_nchar' is used by the 'validate'
           method to check if the computed
           number of characters matches with
           what is asserted here.

=cut

    sub get_nchar {
        my $self = shift;
        my $nchar;
        foreach my $datum ( @{ $self->get_entities } ) {
            my @chars = $datum->get_char;
            if ( not $nchar ) {
                if ( ref $chars[0] eq 'ARRAY' ) {
                    $nchar = scalar @{ $chars[0] };
                }
                else {
                    $nchar = scalar @chars;
                }
            }
            else {
                if ( ref $chars[0] eq 'ARRAY' ) {
                    if ( $nchar != scalar @{ $chars[0] } ) {
                        Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                            'error' => 'Observed and expected nchar mismatch'
                        );
                    }
                }
                else {
                    if ( $nchar != scalar @chars ) {
                        Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                            'error' => 'Observed and expected nchar mismatch'
                        );                    
                    }
                }            
            }
        }
        return $nchar;
    }

=back

=head2 UTILITY METHODS

=over

=item copy_atts()

 Type    : Method
 Title   : copy_atts
 Usage   : my $copy = $matrix->copy_atts;
 Function: Creates an empty copy of invocant
           (i.e. no data, but all the attributes).
 Returns : Bio::Phylo::Matrices::Matrix (shallow copy)
 Args    : None

=cut

    sub copy_atts {
        my $self = shift;
        my $copy = __PACKAGE__->new;

        # attributes from Bio::Phylo::Matrices::Matrix
        $copy->set_taxa( $self->get_taxa );
        $copy->set_type( $self->get_type );
        $copy->set_symbols( $self->get_symbols );
        $copy->set_nchar( $self->get_nchar ) if $self->get_nchar;
        $copy->set_ntax( $self->get_ntax )   if $self->get_ntax;
        $copy->set_gap( $self->get_gap );
        $copy->set_missing( $self->get_missing );

        # attributes from Bio::Phylo
        $copy->set_name( $self->get_name );
        $copy->set_desc( $self->get_desc );
        $copy->set_score( $self->get_score );
        $copy->set_generic( %{ $self->get_generic } ) if $self->get_generic;
        return $copy;
    }

=item to_nexus()

 Type    : Format convertor
 Title   : to_nexus
 Usage   : my $data_block = $matrix->to_nexus;
 Function: Converts matrix object into a nexus data block.
 Alias   :
 Returns : Nexus data block (SCALAR).
 Args    : none
 Comments:

=cut

    sub to_nexus {
        my $self = shift;
        my $nexus = unparse( '-format' => 'nexus', '-phylo' => $self );
        return $nexus;
    }

=item to_cipres()

 Type    : Format convertor
 Title   : to_cipres
 Usage   : my $cipres_matrix = $matrix->to_cipres;
 Function: Converts matrix object to CipresIDL
 Alias   :
 Returns : CIPRES compliant data structure
 Args    : none
 Comments:

=cut

    sub to_cipres {
        my $self = shift;
        my $class = 'Cipres::Util::TypeConverter';
        eval "require $class"; 
        if ( $@ ) {
        Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                'error' => 'This method requires Cipres::Util::TypeConverter, which you don\'t have',
            );
        };
        return Cipres::Util::TypeConverter::matrix2cipres( $self );
    }

=item make_taxa()

 Type    : Utility method
 Title   : make_taxa
 Usage   : my $taxa = $matrix->make_taxa;
 Function: Creates a Bio::Phylo::Taxa object
           from the data in invocant.
 Returns : Bio::Phylo::Taxa
 Args    : NONE
 Comments: NOTE: the newly created taxa
           object will replace all earlier
           references to other taxa and
           taxon objects.

=cut

    sub make_taxa {
        my $self = shift;
        $self->_flush_cache;
        my $taxa = Bio::Phylo::Taxa->new;
        $taxa->set_name('Untitled_taxa_block');
        $taxa->set_desc( 'Generated from ' . $self . ' on ' . localtime() );
        my %data;
        foreach my $datum ( @{ $self->get_entities } ) {
            my $name = $datum->get_name;
            if ( !exists $data{$name} ) {
                my $taxon = Bio::Phylo::Taxa::Taxon->new;
                $taxon->set_name($name);
                $data{$name} = {
                    'datum' => [$datum],
                    'taxon' => $taxon,
                };
            }
            else {
                push @{ $data{$name}->{'datum'} }, $datum;
            }
        }
        foreach my $name ( keys %data ) {
            my $taxon = $data{$name}->{'taxon'};
            foreach my $datum ( @{ $data{$name}->{'datum'} } ) {
                $datum->set_taxon($taxon);
                $taxon->set_data($datum);
            }
            $taxa->insert($taxon);
        }
        $self->set_taxa($taxa);
        return $taxa;
    }

=back

=head2 DESTRUCTOR

=over

=item DESTROY()

 Type    : Destructor
 Title   : DESTROY
 Usage   : $phylo->DESTROY
 Function: Destroys Phylo object
 Alias   :
 Returns : TRUE
 Args    : none
 Comments: You don't really need this,
           it is called automatically when
           the object goes out of scope.

=cut

    sub DESTROY {
        my $self = shift;
        if ( my $i = $self->get_id ) {
            foreach ( keys %{$fields} ) {
                delete $fields->{$_}->[$i];
            }
        }
        $self->_del_from_super;
        $self->SUPER::DESTROY;
        return 1;
    }

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $matrix->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _container { _MATRICES_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $matrix->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _type { _MATRIX_ }

=back

=head1 Re-Implemented Bio::Matrix::MatrixI methods

Consult the L<Bio::Matrix::MatrixI> documentation for details about 
the following methods:

=over

=item matrix_id()

=item matrix_name()

=item num_rows()

=item num_columns()

=item row_names()

=item column_names()

=item column_num_for_name()

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Listable>

This object inherits from L<Bio::Phylo::Listable>, so the
methods defined therein are also applicable to L<Bio::Phylo::Matrices::Matrix>
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

$Id: Matrix.pm 2187 2006-09-07 07:13:33Z rvosa $

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

################################################################################
package Bio::Phylo::Matrices::Matrix::categorical;
sub is_valid {
    my ( $self, @chars ) = @_;
    my $lookup = $self->get_charstate_lookup;
    foreach(@chars){
        return if not exists $lookup->{$_};
    }
    return 1;
}
################################################################################
package Bio::Phylo::Matrices::Matrix::dna;
use vars '@ISA';
@ISA=qw(Bio::Phylo::Matrices::Matrix Bio::Phylo::Matrices::Matrix::categorical);
{
    my @lookup;
    my $IUPAC = {
        'A' => [ 'A'             ], # 1000
        'B' => [ 'C','G','T'     ], # 0111
        'C' => [ 'C'             ], # 0100
        'D' => [ 'A','G','T'     ], # 1011
        'G' => [ 'G'             ], # 0010
        'H' => [ 'A','C','T'     ], # 1101
        'K' => [ 'G','T'         ], # 0011
        'M' => [ 'A','C'         ], # 1100
        'N' => [ 'A','C','G','T' ], # 1111
        'R' => [ 'A','G'         ], # 1010
        'S' => [ 'C','G'         ], # 0110
        'T' => [ 'T'             ], # 0001
        'U' => [ 'U'             ], # 0001
        'V' => [ 'A','C','G'     ], # 1110
        'W' => [ 'A','T'         ], # 1001
        'X' => [ 'A','C','G','T' ], # 1111
        'Y' => [ 'C','T'         ], # 0101
        '-' => [                 ], # 0000
        '?' => [ 'A','C','G','T' ], # 1111
    };
    sub new {
        my ( $class, $self, $lookup ) = @_;
        if ( $lookup ) {
            $lookup[ $self->get_id ] = $lookup;
        }
        else {
            $lookup[ $self->get_id ] = $IUPAC;
        }
        return bless $self, $class;
    }
    sub set_charstate_lookup {
        my ( $self, $lookup ) = @_;
        $lookup[ $self->get_id ] = $lookup;
        return $self;
    }
    sub get_charstate_lookup {
        my ( $self ) = @_;
        return $lookup[ $self->get_id ];
    } 
    sub get_type { 'DNA' }
    sub default_charstate_looup { $IUPAC }           
    sub DESTROY {
        my ( $self ) = @_;
        if ( my $i = $self->get_id ) {
            delete $lookup[$i];
        }        
        $self->SUPER::DESTROY;
    }
       
    
}
################################################################################
package Bio::Phylo::Matrices::Matrix::rna;
use vars '@ISA';
@ISA=qw(Bio::Phylo::Matrices::Matrix Bio::Phylo::Matrices::Matrix::dna);
{
    sub new {
        my ( $class, $self, $lookup ) = @_;
        return bless Bio::Phylo::Matrices::Matrix::dna->new($self,$lookup), $class;
    }
    sub get_type { 'RNA' }
}
################################################################################
package Bio::Phylo::Matrices::Matrix::protein;
use vars '@ISA';
@ISA=qw(Bio::Phylo::Matrices::Matrix Bio::Phylo::Matrices::Matrix::categorical);
{
    my @lookup;
    my $PROT_LOOKUP = {
        '-' => [],
        'A' => [ 'A' ],
        'C' => [ 'C' ],
        'D' => [ 'D' ],
        'E' => [ 'E' ],
        'F' => [ 'F' ],
        'G' => [ 'G' ],
        'H' => [ 'H' ],
        'I' => [ 'I' ],
        'K' => [ 'K' ],
        'L' => [ 'L' ],
        'M' => [ 'M' ],
        'N' => [ 'N' ],
        'P' => [ 'P' ],
        'Q' => [ 'Q' ],
        'R' => [ 'R' ],
        'S' => [ 'S' ],
        'T' => [ 'T' ],
        'U' => [ 'U' ],
        'V' => [ 'V' ],
        'W' => [ 'W' ],
        'X' => [ 'X' ],
        'Y' => [ 'Y' ],
        '*' => [ '*' ],
        'B' => [ 'D','N' ],
        'Z' => [ 'E','Q' ],
        '?' => [ qw(A C D E F G H I K L M N P Q R S T U V W X Y Z) ],
    };    
    sub new {
        my ( $class, $self, $lookup ) = @_;
        if ( $lookup ) {
            $lookup[ $self->get_id ] = $lookup;
        }
        else {
            $lookup[ $self->get_id ] = $PROT_LOOKUP;
        }
        return bless $self, $class;
    }    
    sub set_charstate_lookup {
        my ( $self, $lookup ) = @_;
        $lookup[ $self->get_id ] = $lookup;
        return $self;
    }
    sub get_charstate_lookup {
        my ( $self ) = @_;
        return $lookup[ $self->get_id ];
    }
    sub default_charstate_looup { $PROT_LOOKUP }    
    sub get_type { 'PROTEIN' } 
    sub DESTROY {
        my ( $self ) = @_;
        delete $lookup[ $self->get_id ];
        $self->SUPER::DESTROY;
    }    
}
################################################################################
package Bio::Phylo::Matrices::Matrix::restriction;
use vars '@ISA';
@ISA=qw(Bio::Phylo::Matrices::Matrix Bio::Phylo::Matrices::Matrix::categorical);
{
    my @lookup;
    my $REST_LOOKUP = {
        '-' => [],
        '0' => [ '0' ],
        '1' => [ '1' ],
        '?' => [ '0', '1' ],
    };
    sub new {
        my ( $class, $self, $lookup ) = @_;
        if ( $lookup ) {
            $lookup[ $self->get_id ] = $lookup;
        }
        else {
            $lookup[ $self->get_id ] = $REST_LOOKUP;
        }
        return bless $self, $class;
    }    
    sub set_charstate_lookup {
        my ( $self, $lookup ) = @_;
        $lookup[ $self->get_id ] = $lookup;
        return $self;
    }
    sub get_charstate_lookup {
        my ( $self ) = @_;
        return $lookup[ $self->get_id ];
    }
    sub default_charstate_looup { $REST_LOOKUP }
    sub get_type { 'RESTRICTION' }
    sub DESTROY {
        my ( $self ) = @_;
        delete $lookup[ $self->get_id ];
        $self->SUPER::DESTROY;
    }    
}
################################################################################
package Bio::Phylo::Matrices::Matrix::standard;
use vars '@ISA';
@ISA=qw(Bio::Phylo::Matrices::Matrix Bio::Phylo::Matrices::Matrix::categorical);
{
    my @lookup;
    my $STANDARD = {
        '-' => [],
        '0' => [ '0' ],
        '1' => [ '1' ],
        '2' => [ '2' ],
        '3' => [ '3' ],
        '4' => [ '4' ],
        '5' => [ '5' ],
        '6' => [ '6' ],
        '7' => [ '7' ],
        '8' => [ '8' ],
        '9' => [ '9' ],
        '?' => [ ( 0 .. 9 ) ],
    };
    sub new {
        my ( $class, $self, $lookup ) = @_;
        if ( $lookup ) {
            $lookup[ $self->get_id ] = $lookup;
        }
        else {
            $lookup[ $self->get_id ] = $STANDARD;
        }
        return bless $self, $class;
    }
    sub set_charstate_lookup {
        my ( $self, $lookup ) = @_;
        $lookup[ $self->get_id ] = $lookup;
        return $self;
    }
    sub get_charstate_lookup {
        my ( $self ) = @_;
        return $lookup[ $self->get_id ];
    }
    sub default_charstate_lookup { $STANDARD }
    sub get_type { 'STANDARD' }
    sub DESTROY {
        my ( $self ) = @_;
        delete $lookup[ $self->get_id ];
        $self->SUPER::DESTROY;
    }    
}
################################################################################
package Bio::Phylo::Matrices::Matrix::continuous;
use vars '@ISA';
use Scalar::Util qw(looks_like_number);
@ISA=qw(Bio::Phylo::Matrices::Matrix);
{
    my @lookup;
    sub new {
        my ( $class, $self ) = @_;
        return bless $self, $class;
    }
    sub set_charstate_lookup {
        my ( $self, $lookup ) = @_;
        $lookup[ $self->get_id ] = $lookup;
        return $self;
    }
    sub get_charstate_lookup {
        my ( $self ) = @_;
        return $lookup[ $self->get_id ];
    }
    sub get_type { 'CONTINUOUS' };
    sub is_valid {
        my ( $self, @chars ) = @_;
        foreach(@chars){
            return if not looks_like_number $_;
        }
        return 1;
    }
    sub DESTROY {
        my ( $self ) = @_;
        delete $lookup[ $self->get_id ];
        $self->SUPER::DESTROY;
    }    
}
################################################################################
package Bio::Phylo::Matrices::CharSeq;
use Bio::Phylo::Util::CONSTANT qw(_MATRIX_ _DATUM_);

use vars '@ISA';
@ISA=qw(Bio::Phylo);
my $class = 'Bio::RangeI';
eval "require $class";
if ( not $@ ) {
    push @ISA, $class;
}

my ( @start, @container, @tuple );

use overload '@{}' => sub { $tuple[$$_[0]] }, 'fallback' => 1;

sub new {
    my ( $class, $name, $chars ) = @_;
    my $self = $class->SUPER::new( '-name' => $name );
    $tuple[ $self->get_id ] = [ $name, $chars ];
    return bless $self, $class;
}
sub get_char {
    my $self = shift;
    return wantarray ? @{ $tuple[ $self->get_id ]->[1] } : join ' ', @{ $tuple[ $self->get_id ]->[1] };
}
sub get_taxon {
    my $self = shift;
    return ref $tuple[ $self->get_id ]->[0] ? $tuple[ $self->get_id ]->[0] : undef;
}
sub start {
    my ( $self, $start ) = @_;
    $start[ $self->get_id ] = $start if $start;
    return $start[ $self->get_id ];
}
sub end {
    return $#{ $_[0]->get_char } + $_[0]->start;
}
sub strand {

}
sub length {
    return $_[0]->end - $_[0]->start;
}
sub toString {

}
sub overlaps {
    return ( $_[0]->start <= $_[1]->end  && $_[0]->end >= $_[1]->start ) ? 1 : 0;
}
sub contains {
    return ( $_[0]->start <= $_[1]->start && $_[0]->end >= $_[1]->end ) ? 1 : 0;
}
sub equals {
    return ( $_[0]->start == $_[1]->start && $_[0]->end == $_[1]->end ) ? 1 : 0;
}
sub intersection {

}
sub union {

}
sub _container { _MATRIX_ }
sub _type { _DATUM_ }

1;
