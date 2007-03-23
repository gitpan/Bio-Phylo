package Bio::Phylo::Matrices::Matrix;
use vars '@ISA';
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Taxa::TaxaLinker;
use Bio::Phylo::Taxa::Taxon;
use Bio::Phylo::IO qw(unparse);
use Bio::Phylo::Util::CONSTANT qw(:objecttypes);
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Matrices::TypeSafeData;
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Util::XMLWritable;
use Scalar::Util qw(blessed);

@ISA = qw(
    Bio::Phylo::Listable 
    Bio::Phylo::Taxa::TaxaLinker 
    Bio::Phylo::Matrices::TypeSafeData
    Bio::Phylo::Util::XMLWritable
);

my @inside_out_arrays = \(
    my %type,
    my %charlabels,
    my %gapmode,
    my %matchchar,
    my %polymorphism,
    my %case_sensitivity,
);

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
                      continuous|standard|restriction|mixed => {}

           -taxa   => optional, link to taxa object
           -lookup => character state lookup hash ref
           -labels => array ref of character labels
           -matrix => two-dimensional array, first element of every
                      row is label, subsequent are characters

=cut

    sub new {
        # could be child class
        my $class = shift;
        
        # notify user
        $class->info("constructor called for '$class'");
        
        # go up inheritance tree, eventually get an ID
        my $self = $class->SUPER::new( '-type' => 'standard', @_ );
        
        # adapt (or not, if $Bio::Phylo::COMPAT is not set)
        return Bio::Phylo::Adaptor->new( $self );        
    }

=back

=head2 MUTATORS

=over

=item set_charlabels()

 Type    : Mutator
 Title   : set_charlabels
 Usage   : $matrix->set_charlabels( [ 'char1', 'char2', 'char3' ] );
 Function: Assigns character labels.
 Returns : $self
 Args    : ARRAY, or nothing (to reset);

=cut

sub set_charlabels {
    my ( $self, $charlabels ) = @_;
    
    # it's an array ref, but what about its contents?
    if ( UNIVERSAL::isa( $charlabels, 'ARRAY' ) ) {
    	for my $label ( @{ $charlabels } ) {
    	    if ( ref $label ) {
    		Bio::Phylo::Util::Exceptions::BadArgs->throw(
    		    'error' => "charlabels must be an array ref of scalars"
    		);
    	    }
    	}
    }
    
    # it's defined but not an array ref
    elsif ( defined $charlabels && ! UNIVERSAL::isa( $charlabels, 'ARRAY' ) ) {
	Bio::Phylo::Util::Exceptions::BadArgs->throw(
	    'error' => "charlabels must be an array ref of scalars"
	);
    }
    
    # it's either a valid array ref, or nothing, i.e. a reset
    $charlabels{ $self->get_id } = defined $charlabels ? $charlabels : [];
    return $self;
}

=item set_gapmode()

 Type    : Mutator
 Title   : set_gapmode
 Usage   : $matrix->set_gapmode( 1 );
 Function: Defines matrix gapmode ( false = missing, true = fifth state )
 Returns : $self
 Args    : boolean

=cut

sub set_gapmode {
    my ( $self, $gapmode ) = @_;
    $gapmode{ $self->get_id } = !!$gapmode;
    return $self;
}

=item set_matchchar()

 Type    : Mutator
 Title   : set_matchchar
 Usage   : $matrix->set_matchchar( $match );
 Function: Assigns match symbol (default is '.').
 Returns : $self
 Args    : ARRAY

=cut

sub set_matchchar {
    my ( $self, $char ) = @_;
    $matchchar{ $self->get_id } = $char;
    return $self;
}

=item set_polymorphism()

 Type    : Mutator
 Title   : set_polymorphism
 Usage   : $matrix->set_polymorphism( 1 );
 Function: Defines matrix 'polymorphism' interpretation
           ( false = uncertainty, true = polymorphism )
 Returns : $self
 Args    : boolean

=cut

sub set_polymorphism {
    my ( $self, $poly ) = @_;
    $polymorphism{ $self->get_id } = !!$poly;
    return $self;
}

=item set_raw()

 Type    : Mutator
 Title   : set_raw
 Usage   : $matrix->set_raw( [ [ 'taxon1' => 'acgt' ], [ 'taxon2' => 'acgt' ] ] );
 Function: Syntax sugar to define $matrix data contents.
 Returns : $self
 Args    : A two-dimensional array; first dimension contains matrix rows,
           second dimension contains taxon name / character string pair.

=cut

sub set_raw {
    my ( $self, $raw ) = @_;
    if ( defined $raw ) {
    	if ( UNIVERSAL::isa( $raw, 'ARRAY' ) ) {
    	    my @rows;
    	    for my $row ( @{ $raw } ) {
    		if ( defined $row ) {
    		    if ( UNIVERSAL::isa( $row, 'ARRAY' ) ) {
			my $matrixrow = Bio::Phylo::Matrices::Datum->new(
			    '-name'        => $row->[0],
			    '-type_object' => $self->get_type_object,
			    '-char'        => join(' ', @$row[ 1 .. $#{$row} ]),
			);
			push @rows, $matrixrow;
    		    }
    		    else {
    			Bio::Phylo::Util::Exceptions::BadArgs->throw(
    			    'error' => "Raw matrix row must be an array reference"
    			);
    		    }
    		}
    	    }
    	    $self->clear;
    	    $self->insert( $_ ) for @rows;
    	}
    	else {
    	    Bio::Phylo::Util::Exceptions::BadArgs->throw(
    		'error' => "Raw matrix must be an array reference"
    	    );
    	}
    }
    return $self;
}

=item set_respectcase()

 Type    : Mutator
 Title   : set_respectcase
 Usage   : $matrix->set_respectcase( 1 );
 Function: Defines matrix case sensitivity interpretation
           ( false = disregarded, true = "respectcase" )
 Returns : $self
 Args    : boolean

=cut

sub set_respectcase {
    my ( $self, $case_sensitivity ) = @_;
    $case_sensitivity{ $self->get_id } = !!$case_sensitivity;
    return $self;
}

=back

=head2 ACCESSORS

=over

=item get_charlabels()

 Type    : Accessor
 Title   : get_charlabels
 Usage   : my @charlabels = @{ $matrix->get_charlabels };
 Function: Retrieves character labels.
 Returns : ARRAY
 Args    : None.

=cut

sub get_charlabels {
    my $self = shift;
    my $id = $self->get_id;
    return defined $charlabels{$id} ? $charlabels{$id} : [];
}

=item get_gapmode()

 Type    : Accessor
 Title   : get_gapmode
 Usage   : do_something() if $matrix->get_gapmode;
 Function: Returns matrix gapmode ( false = missing, true = fifth state )
 Returns : boolean
 Args    : none

=cut

sub get_gapmode {
    my $self = shift;
    return $gapmode{ $self->get_id };
}

=item get_matchchar()

 Type    : Accessor
 Title   : get_matchchar
 Usage   : my $char = $matrix->get_matchchar;
 Function: Returns matrix match character (default is '.')
 Returns : SCALAR
 Args    : none

=cut

sub get_matchchar {
    my $self = shift;
    return $matchchar{ $self->get_id };
}

=item get_nchar()

 Type    : Accessor
 Title   : get_nchar
 Usage   : my $nchar = $matrix->get_nchar;
 Function: Calculates number of characters (columns) in matrix (if the matrix
           is non-rectangular, returns the length of the longest row).
 Returns : INT
 Args    : none

=cut

sub get_nchar {
    my $self = shift;
    my $nchar = 0;
    my $i = 1;
    for my $row ( @{ $self->get_entities } ) {
	my $rowlength = $row->get_length;
	$self->debug( sprintf("counted %s chars in row %s", $rowlength, $i++) );
	$nchar = $rowlength if $rowlength > $nchar;
    }
    return $nchar;
}

=item get_ntax()

 Type    : Accessor
 Title   : get_ntax
 Usage   : my $ntax = $matrix->get_ntax;
 Function: Calculates number of taxa (rows) in matrix
 Returns : INT
 Args    : none

=cut

sub get_ntax {
    my $self = shift;
    return scalar @{ $self->get_entities };
}

=item get_polymorphism()

 Type    : Accessor
 Title   : get_polymorphism
 Usage   : do_something() if $matrix->get_polymorphism;
 Function: Returns matrix 'polymorphism' interpretation
           ( false = uncertainty, true = polymorphism )
 Returns : boolean
 Args    : none

=cut

sub get_polymorphism {
    my $self = shift;
    return $polymorphism{ $self->get_id };
}

=item get_raw()

 Type    : Accessor
 Title   : get_raw
 Usage   : my $rawmatrix = $matrix->get_raw;
 Function: Retrieves a 'raw' (two-dimensional array) representation
           of the matrix's contents.
 Returns : A two-dimensional array; first dimension contains matrix rows,
           second dimension contains taxon name and characters.
 Args    : NONE

=cut

sub get_raw {
    my $self = shift;
    my @raw;
    for my $row ( @{ $self->get_entities } ) {
        my @row;
        push @row, $row->get_name;
        my @char = $row->get_char;
        push @row, @char;
        push @raw, \@row;
    }
    return \@raw;
}

=item get_respectcase()

 Type    : Accessor
 Title   : get_respectcase
 Usage   : do_something() if $matrix->get_respectcase;
 Function: Returns matrix case sensitivity interpretation
           ( false = disregarded, true = "respectcase" )
 Returns : boolean
 Args    : none

=cut

sub get_respectcase {
    my $self = shift;
    return $case_sensitivity{ $self->get_id };
}

=back

=head2 METHODS

=over

=item to_nexus()

 Type    : Format convertor
 Title   : to_nexus
 Usage   : my $data_block = $matrix->to_nexus;
 Function: Converts matrix object into a nexus data block.
 Returns : Nexus data block (SCALAR).
 Args    : none
 Comments:

=cut

sub to_nexus {
    my $self = shift;
    my $nexus = unparse( '-format' => 'nexus', '-phylo' => $self );
    return $nexus;
}

=item insert()

 Type    : Listable method
 Title   : insert
 Usage   : $matrix->insert($datum);
 Function: Converts matrix object into a nexus data block.
 Returns : Modified object
 Args    : A datum object
 Comments: This method re-implements the method by the same
           name in Bio::Phylo::Listable

=cut

sub insert {
    my ( $self, $obj ) = @_;
    my $obj_container;
    eval { $obj_container = $obj->_container };
    if ( $@ || $obj_container != $self->_type ) {
        Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
	    'error' => 'object not a datum object!'
	);
    }
    $self->info("inserting '$obj' in '$self'");
    if ( ! $self->get_type_object->is_same( $obj->get_type_object ) ) {
	Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
	    'error' => 'object is of wrong data type'
	);	
    }
    my $taxon1 = $obj->get_taxon;
    for my $ents ( @{ $self->get_entities } ) {
	if ( $obj->get_id == $ents->get_id ) {
	    Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
		'error' => 'row already inserted'
	    );
	}
        if ( $taxon1 ) {
            my $taxon2 = $ents->get_taxon;
            if ( $taxon2 && $taxon1->get_id == $taxon2->get_id ) {
                $self->warn('datum linking to same taxon already existed, concatenating instead');
                $ents->concat( $obj );
                return $self;
            }
        }
    }
    $self->SUPER::insert( $obj );
}

=item validate()

 Type    : Method
 Title   : validate
 Usage   : $obj->validate
 Function: Validates the object's contents
 Returns : True or throws Bio::Phylo::Util::Exceptions::InvalidData
 Args    : None
 Comments: This method implements the interface method by the same
           name in Bio::Phylo::Matrices::TypeSafeData

=cut

sub validate {
    my $self = shift;
    for my $row ( @{ $self->get_entities } ) {
        $row->validate;
    }
}

=item check_taxa()

 Type    : Method
 Title   : check_taxa
 Usage   : $obj->check_taxa
 Function: Validates relation between matrix and taxa block 
 Returns : Modified object
 Args    : None
 Comments: This method implements the interface method by the same
           name in Bio::Phylo::Taxa::TaxaLinker

=cut

sub check_taxa {
    my $self = shift;
    # is linked to taxa
    if ( my $taxa = $self->get_taxa ) {
        my %taxa = map { $_->get_name => $_ } @{ $taxa->get_entities };
        ROW_CHECK: for my $row ( @{ $self->get_entities } ) {
            if ( my $taxon = $row->get_taxon ) {
                next ROW_CHECK if exists $taxa{$taxon->get_name}; 
            }
            my $name = $row->get_name;
            if ( exists $taxa{$name} ) {
                $row->set_taxon( $taxa{$name} );
            }
            else {
                my $taxon = Bio::Phylo::Taxa::Taxon->new( -name => $name );
                $taxa{$name} = $taxon;
                $taxa->insert( $taxon );
                $row->set_taxon( $taxon );
            }
        }
        
    }
    # not linked
    else {
        my $row = $self->first;
        $row->set_taxon();
        for ( $row = $self->next ) {
            $row->set_taxon();
        }
    }
    return $self;
}

sub _type { _MATRIX_ }

sub _container { _MATRICES_ }

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

sub _cleanup {
    my $self = shift;
    $self->info("cleaning up '$self'");
    my $id = $self->get_id;
    for ( @inside_out_arrays ) {
        delete $_->{$id} if defined $id and exists $_->{$id};
    }
}

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

$Id: Matrix.pm 3319 2007-03-20 01:39:35Z rvosa $

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
