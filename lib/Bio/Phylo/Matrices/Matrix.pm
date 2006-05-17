# $Id: Matrix.pm,v 1.31 2006/04/12 22:38:23 rvosa Exp $
package Bio::Phylo::Matrices::Matrix;
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::IO qw(unparse);
use Bio::Phylo::Util::CONSTANT qw(_MATRICES_ _MATRIX_ _TAXON_ _TAXA_ symbol_ok type_ok cipres_type infer_type);
use Scalar::Util qw(looks_like_number weaken);
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Taxa;
use Bio::Phylo::Taxa::Taxon;

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo::Listable);

{
    # inside out class arrays
    my @type;
    my @symbols;
    my @taxa;
    my @is_flat;
    my @ntax;
    my @nchar;
    my @missing;
    my @gap;
    
    # $fields hashref necessary for object destruction
    my $fields = {
        '-type'    => \@type,
        '-symbols' => \@symbols,
        '-taxa'    => \@taxa,
        '-is_flat' => \@is_flat,
        '-ntax'    => \@ntax,
        '-nchar'   => \@nchar,
        '-missing' => \@missing,
        '-gap'     => \@gap,
    };    

=head1 NAME

Bio::Phylo::Matrices::Matrix - The matrix object to aggregate datum objects.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Matrix;
 use Bio::Phylo::Matrices::Datum;
 use Bio::Phylo::Taxa::Taxon;
 
 # instantiate matrix object
 my $matrix = Bio::Phylo::Matrices::Matrix->new;
 
 # instantiate a taxon object
 my $taxon = Bio::Phylo::Taxa::Taxon->new;

 # instantiate 1000 datum objects and insert them in the matrix
 for my $i ( 0 .. 1000 ) {
    my $datum = Bio::Phylo::Matrices::Datum->new( 
        -pos   => $i,
        -type  => 'STANDARD',
        -taxon => $taxon,
        -char  => int(rand(2)),
    );
    $matrix->insert($datum);
 }
 
 # retrieve all datum objects whose position >= 500
 my @second_half_of_matrix = @{ $matrix->get_by_value(
    -value => 'get_position',
    -ge    => 500
 ) };
 

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
 Args    : NONE required, but look up the inheritance 
           tree to the SUPER class Bio::Phylo::Listable, 
           and its parent Bio::Phylo

=cut

    sub new {
        my ( $class, $self ) = shift;
        $self = __PACKAGE__->SUPER::new(@_);
        bless $self, __PACKAGE__;
        $missing[$$self] = '?';
        $gap[$$self]     = '-';
        $ntax[$$self]    = undef;
        $nchar[$$self]   = undef;
        if ( @_ ) {
            my %opt;
            eval { %opt = @_; };
            if ( $@ ) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
            }
            else {
                while ( my ( $key, $value ) = each %opt ) {
                    if ( $fields->{$key} ) {
                        $fields->{$key}->[$$self] = $value;
                        delete $opt{$key};
                    }
                }
                @_ = %opt;
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
                            if ( ! exists $taxa{$taxon} ) {
                                $datum->set_taxon( undef );
                                $replaced++;
                            }
                        }
                        elsif ( $datum->get_name and exists $name{$datum->get_name} ) {
                            $datum->set_taxon( $name{$datum->get_name} );
                        }                        
                    } 
                    if ( $replaced ) {
                        warn "Reset $replaced references from datum objects to taxa outside taxa block";
                    }
                    $taxa[$$self] = $taxa;
                    weaken( $taxa[$$self] );
                    $taxa->set_matrix( $self );
                }
                else {
                    Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                        error => "\"$taxa\" doesn't look like a taxa object"
                    );
                }
            }
            else {
                Bio::Phylo::Util::Exceptions::BadArgs->throw(
                    error => "\"$taxa\" is not a blessed object!"
                );  
            }
        }
        else {
            $taxa[$$self] = undef;
        }
        return $self;
    }
    
=item set_type()

 Type    : Mutator
 Title   : set_type
 Usage   : $matrix->set_type($type);
 Function: Assigns a matrix's type.
 Returns : Modified object.
 Args    : $type must be one of [DNA|RNA|STANDARD|
           PROTEIN|NUCLEOTIDE|CONTINUOUS]. If no 
           argument supplied, matrix type is set 
           to undefined.

=cut

    sub set_type {
        my ( $self, $type ) = @_;
        if ( $type && type_ok( $type ) ) {
            $type[$$self] = uc $type;        
        }
        elsif ( $type && ! type_ok( $type ) ) {
            Bio::Phylo::Util::Exceptions::BadFormat->throw(
                error => "\"$type\" is a bad data type"
            );
        }
        elsif ( ! $type ) {
            $type[$$self] = undef;
        }
        return $self;
    }   
    
=item set_symbols()

 Type    : Mutator
 Title   : set_symbol
 Usage   : $matrix->set_symbols($symbols);
 Function: Assigns/adds an array ref 
           of allowed symbols
 Returns : Modified object.
 Args    : A reference to an array of symbols. 
           When no argument is given,
           the symbol table is reset.

=cut

    sub set_symbols {
        my ( $self, $symbols ) = @_;
        if ( my $type = $self->get_type ) {
            if ( defined $symbols && ref $symbols eq 'ARRAY' ) {
                my %tmp;
                %tmp = map { $_ => 1 } @{ $self->get_symbols } if defined $self->get_symbols;
                foreach ( keys %{ { map { uc( $_ ) => 1 } @{ $symbols } } } ) {
                    if ( symbol_ok( '-type' => $type, '-char' => $_ ) ) {
                        $tmp{$_} = 1;
                    }
                    else {
                        Bio::Phylo::Util::Exceptions::BadString->throw(
                            error => "\"$_\" is not a valid \"$type\" symbol"
                        );                        
                    }
                }
                my @sym = keys %tmp;
                $symbols[$$self] = \@sym;
            }
            elsif ( defined $symbols && ref $symbols ne 'ARRAY' ) {
                Bio::Phylo::Util::Exceptions::BadArgs->throw(
                    'error' => "\"$symbols\" is not an array reference",
                );
            }
            elsif ( ! defined $symbols ) {
                $symbols[$$self] = undef;
            }
            return $self;
        }
        else {
            Bio::Phylo::Util::Exceptions::BadFormat->throw(
                error => 'please define the data type first'
            );
        }
    }
    
=item set_missing()

 Type    : Mutator
 Title   : set_missing
 Usage   : $matrix->set_missing('?');
 Function: Assigns the missing character symbol.
 Returns : Modified object.
 Args    : A symbol used to indicate missing
           data. Default is '?'.

=cut

sub set_missing {
    my ( $self, $missing ) = @_;
    if ( defined $missing and $missing !~ m/^.$/ ) {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => 'not a valid missing data symbol',
        );        
    }
    elsif ( defined $missing ) {
        $missing[$$self] = $missing;
    }    
    else {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => 'please define a missing data symbol',
        );    
    }
    return $self;
}

=item set_gap()

 Type    : Mutator
 Title   : set_gap
 Usage   : $matrix->set_gap('-');
 Function: Assigns the gap (indel?) character symbol.
 Returns : Modified object.
 Args    : A symbol used to indicate gaps. 
           Default is '-'.

=cut

sub set_gap {
    my ( $self, $gap ) = @_;
    if ( defined $gap and $gap !~ m/^.$/ ) {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => 'not a valid gap symbol',
        );        
    }
    elsif ( defined $gap ) {
        $gap[$$self] = $gap;
    }    
    else {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => 'please define a gap symbol',
        );    
    }
    return $self;
}

=item set_ntax()

 Type    : Mutator
 Title   : set_ntax
 Usage   : $matrix->set_ntax(10);
 Function: Assigns the intended number of 
           taxa for the matrix.
 Returns : Modified object.
 Args    : Optional: An integer. If no
           value is given, ntax is reset
           to the undefined default.
 Comments: This value is only necessary 
           for the $matrix->validate 
           method. If you don't need to
           call that, this value is 
           better left unset.

=cut

sub set_ntax {
    my ( $self, $ntax ) = @_;
    if ( defined $ntax and $ntax !~ m/^\d+$/ ) {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => "not a valid ntax value ($ntax)",
        );        
    }
    elsif ( defined $ntax ) {
        $ntax[$$self] = $ntax;
    }    
    else {
        $ntax[$$self] = undef;   
    }
    return $self;
}

=item set_nchar()

 Type    : Mutator
 Title   : set_nchar
 Usage   : $matrix->set_nchar(10);
 Function: Assigns the intended number of 
           characters for the matrix.
 Returns : Modified object.
 Args    : Optional: An integer. If no
           value is given, nchar is reset
           to the undefined default.
 Comments: This value is only necessary 
           for the $matrix->validate 
           method. If you don't need to
           call that, this value is 
           better left unset.

=cut

sub set_nchar {
    my ( $self, $nchar ) = @_;
    if ( defined $nchar and $nchar !~ m/^\d+$/ ) {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => "not a valid nchar value ($nchar)",
        );        
    }
    elsif ( defined $nchar ) {
        $nchar[$$self] = $nchar;
    }    
    else {
        $nchar[$$self] = undef;   
    }
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

    sub get_type {
        my $self = shift;
        return $type[$$self];
    }

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
        return $symbols[$$self];
    }

=item get_num_characters()

 Type    : Accessor
 Title   : get_num_characters
 Usage   : my $nchar = $matrix->get_num_characters;
 Function: Retrieves number of characters
 Returns : ARRAY
 Args    : NONE

=cut    

    sub get_num_characters {
        my $self  = shift;
        my $obs   = {};
        foreach my $row ( @{ $self->get_entities } ) {
            my $taxon = $row->get_taxon;
            foreach ( $row->get_char ) {
                $obs->{$taxon}++;
            }
        }
        my ( $nchar, $ntax ) = ( 0, 0 );
        foreach my $k ( keys %{ $obs } ) {
            $nchar += $obs->{$k};
            $ntax++;
        }
        return $nchar / $ntax;
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
        return scalar @{ $symbols[$$self] };
    }  

=item get_num_taxa()

 Type    : Accessor
 Title   : get_num_taxa
 Usage   : my $ntax = $matrix->get_num_taxa;
 Function: Retrieves the number of 
           distinct taxa in the matrix
 Returns : SCALAR
 Args    : NONE
     
=cut

    sub get_num_taxa {
        my $self  = shift;
        my $obs   = {};
        foreach my $row ( @{ $self->get_entities } ) {
            my $taxon = $row->get_taxon;
            $obs->{$taxon}++;
        }
        my $ntax = scalar keys %{ $obs };
        return $ntax;
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
        return $taxa[$$self];
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
        if ( $taxon ) {
            if ( $taxon->can('_type') && $taxon->_type == _TAXON_ ) {
                foreach my $datum ( @{ $self->get_entities } ) {
                    if ( my $tax = $datum->get_taxon ) {
                        push @chars, $datum if $tax == $taxon;
                    }
                }
            }
            else {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    'error' => "\"$taxon\" is not a valid taxon",
                );
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                'error' => 'Need a taxon to match against',
            );
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
        my $copy = $self->copy_atts;
        my @range = @_;
        while ( my $taxon = $self->get_taxa->next ) {
            my $datum   = shift @{ $self->get_chars_for_taxon($taxon) };
            my $charstr = $datum->get_char;
            my $chars   = ref $charstr ? $charstr 
                                       : $datum->get_type =~ m/CONT/ 
                                       ? [ split(/\s+/, $charstr) ] 
                                       : [ split(//,    $charstr) ];
            my $newchars = [];
            for my $i ( @range ) {
                if ( exists $chars->[$i] ) {
                    push @{ $newchars }, $chars->[$i];
                }
                else {
                    Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                        'error' => "Character position index $i out of bounds",
                    );
                }
            }
            my $newdat = $datum->copy_atts;
            $newdat->set_char( $newchars );
            $copy->insert( $newdat );
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
        for my $i ( @range ) {
            if ( my $taxon  = $taxa->[$i] ) {
                foreach my $datum ( @{ $self->get_chars_for_taxon( $taxon ) } ) {
                    my $datcopy = $datum->copy_atts;
                    $datcopy->set_char( $datum->get_char );
                    $copy->insert( $datcopy );
                }
            }        
            else {
                Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
                    'error' => "Taxon position index $i out of bounds",
                );
            }
        }
        return $copy;
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
        return $missing[$$self];
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
        my $self = shift;
        return $gap[$$self];
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
        return $ntax[$$self];
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
        return $nchar[$$self];
    }

# TODO: get_rows, splice, concat

=back

=head2 METHODS

=over

=item validate()

 Type    : Method
 Title   : validate
 Usage   : $matrix->validate;
 Function: Compares computed ntax and nchar with
           asserted. Reacts violently if something
           doesn't match.
 Returns : Void.
 Args    : None
 Comments: 'set_ntax' and 'set_nchar' need to be 
           assigned for this to work.

=cut

    sub validate {
        my $self  = shift;
        if ( not $self->get_nchar or not $self->get_ntax ) {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                error => "'set_ntax' and 'set_nchar' need to be assigned for this to work",
            );
        }
        my $nchar = $self->get_nchar;
        my $ntax  = $self->get_ntax;
        my $obs   = {};
        foreach my $row ( @{ $self->get_entities } ) {
            my $taxon = $row->get_taxon;
            foreach ( $row->get_char ) {
                $obs->{$taxon} = 0 if not defined $obs->{$taxon};
                $obs->{$taxon}++;
            }
        }
        foreach my $k ( keys %{ $obs } ) {
            if ( $obs->{$k} != $nchar ) {
                Bio::Phylo::Util::Exceptions::BadFormat->throw(
                    error => "Bad nchar (" . $obs->{$k} . ") for taxon " . $k->get_name,
                );            
            }
        }
        if ( scalar keys %{ $obs } != $ntax ) {
            Bio::Phylo::Util::Exceptions::BadFormat->throw(
                error => "Bad ntax - observed: ". scalar keys ( %{ $obs } ) . ", expected: $ntax"
            );
        }        
    }

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
        my @tmp = $self->_check_cache;
        return $tmp[1] if $tmp[0];        
        eval { require 'CipresIDL'; };
        if ( $@ ) {
            Bio::Phylo::Util::Exceptions::Extension::Error->throw(
                'error' => 'This method requires CipresIDL, which you don\'t have',
            );
        }
        my ( $chars_lol, $i, @charStateLookup ) = ( [], 0 );
        my %lookup = map { $_ => $i++ } @{ $self->get_symbols };
        $i = 0;
        foreach my $taxon ( @{ $self->get_taxa } ) {
            $chars_lol->[$i] = [];
            foreach ( @{ $self->get_chars_for_taxon($taxon) } ) {
                push @{ $chars_lol->[$i] }, $lookup{$_};
            }
            $i++;
        }
        @charStateLookup = ( 0 .. $#{ $self->get_symbols } );
        my $cipres_matrix = CipresIDL::DataMatrix->new(
            'm_symbols'         => join( '', @{ $self->get_symbols } ),
            'm_numStates'       => $self->get_num_states,
            'm_numCharacters'   => $self->get_num_characters,
            'm_charStateLookup' => [ \@charStateLookup ],
            'm_matrix'          => $chars_lol,
            'm_datatype'        => cipres_type( $self->get_type ),
        );        
        $self->_store_cache( $cipres_matrix );
        return $cipres_matrix;
    }

=item make_taxa()

 Type    : Utility method
 Title   : make_taxa
 Usage   : my $taxa = $matrix->make_taxa;
 Function: Creates a Bio::Phylo::Taxa object 
           from the data in invocant.
 Returns : Bio::Phylo::Taxa
 Args    : NONE
 Comments: N.B.!: the newly created taxa 
           object will replace all earlier 
           references to other taxa and 
           taxon objects.

=cut

    sub make_taxa {
        my $self = shift;
        $self->_flush_cache;
        my $taxa = Bio::Phylo::Taxa->new;
        $taxa->set_name('Untitled_taxa_block');
        $taxa->set_desc('Generated from ' . $self . ' on ' . localtime());
        my %data;   
        foreach my $datum ( @{ $self->get_entities } ) {
            my $name = $datum->get_name;
            if ( ! exists $data{$name} ) {
                my $taxon = Bio::Phylo::Taxa::Taxon->new;
                $taxon->set_name( $name );
                $data{$name} = {
                    'datum' => [ $datum ],
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

=begin comment

 Type    : Boolean test
 Title   : _is_flat
 Usage   : if ( $matrix->_is_flat ) {
               # do something
           }
 Function: This is a switch to indicate whether the _flatten method needs
           to be called.
 Returns : Boolean
 Args    : with arg: setter; without: getter

=end comment

=cut

    sub _is_flat {
        my $self = shift;
        $is_flat[$$self] = shift if @_;
        return $is_flat[$$self];
    }

=begin comment

 Type    : Format convertor
 Title   : _flatten
 Usage   : my $flattened = $matrix->_flatten;
 Function: Matrix objects can consist of 
           non-contiguous or overlapping
           datum objects for the same taxon. 
           This method assigns each taxon one 
           contiguous datum object, filling 
           the intervals with '?' missing data. 
           It resolves overlaps (i.e. multiple 
           datum objects that occupy the same 
           position) by favouring the most
           recently inserted datum.
 Returns : Bio::Phylo::Matrices::Matrix
 Args    : none
 Comments: Bio::Phylo::Matrices::Matrix objects 
           are *NOT* rectangular by default. If a 
           matrix is linked to a taxa object, but 
           not all taxa in that taxa object have 
           data in the matrix, their rows in the 
           matrix will be *empty*. Use the '_flatten' 
           method to pad their rows with '?' missing 
           data in order to obtain a rectangular 
           matrix (e.g. to write to a nexus file).

=end comment

=cut

    sub _flatten {
        my $self = shift;
        $self->_flush_cache;
        my $flattened = $self->copy_atts;
        my $taxa = {};
        while ( my $datum = $self->next ) {
            my $taxon;
            if ( not $taxon = $datum->get_taxon ) {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    error => "Unlinked datum encountered!",
                );
            }        
            if ( not exists $taxa->{ $taxon } ) {
                $taxa->{ $taxon } = [];
            }
            push @{ $taxa->{ $taxon } }, $datum;
        }
        my ( $newdata, $length ) = ( [], 0 );
        foreach my $taxon ( keys %{ $taxa } ) {
            my $newdat = Bio::Phylo::Matrices::Datum->new( 
                '-taxon' => $taxon,
                '-pos'   => 0,
            );
            my ( $char, $note ) = ( [], [] );
            foreach my $datum ( @{ $taxa->{ $taxon } } ) {
                my $begin = $datum->get_position ? $datum->get_position : 0;
                my @char = $datum->get_char;
                my $end = @char ? $begin + $#char : $begin;
                if ( @char ) {
                    my $j = 0;
                    for my $i ( $begin .. $end ) {
                        $char->[$i] = $char[$j];
                        $j++;
                    }
                }
                $note->[ $begin .. $end ] = @{ $datum->get_annotation } if @{ $datum->get_annotation };
                # copy atts
                $newdat->set_weight(  $datum->get_weight  );
                $newdat->set_name(    $datum->get_name    );
                $newdat->set_desc(    $datum->get_desc    );
                $newdat->set_score(   $datum->get_score   );
                $newdat->set_type(    $datum->get_type    );
                $newdat->set_generic( %{ $datum->get_generic } ) if $datum->get_generic; 
            }
            $length = $#{ $char } if $#{ $char } > $length;
            $newdat->set_char( $char );
            $newdat->set_annotations( @{ $note } );
            push @{ $newdata }, $newdat;
        }
        $flattened->_is_flat(1);    
        foreach my $datum ( @{ $newdata } ) {
            my @char = $datum->get_char;
            my $note = $datum->get_annotation;
            if ( @char ) {
                for my $i ( 0 .. $length ) {
                    if ( not defined $char[$i] ) {
                        $char[$i] = '?';
                    }
                }
            }
            $datum->set_char( \@char );
            $datum->set_annotations( @{ $note } );
            $flattened->insert( $datum );
        }    
        return $flattened;
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
        foreach( keys %{ $fields } ) {
            delete $fields->{$_}->[$$self];
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

$Id: Matrix.pm,v 1.31 2006/04/12 22:38:23 rvosa Exp $

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
