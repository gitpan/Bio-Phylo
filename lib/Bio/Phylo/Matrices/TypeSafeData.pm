package Bio::Phylo::Matrices::TypeSafeData;
use Bio::Phylo::Listable;
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Matrices::Datatype;
use strict;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Listable);


{
    my %type;
    
=head1 NAME

Bio::Phylo::Matrices::TypeSafeData - Superclass for objects that hold
character data.

=head1 SYNOPSIS

 # No direct usage

=head1 DESCRIPTION

This is a superclass for objects holding character data. Objects that inherit
from this class (typically matrices and datum objects) yield functionality to
handle datatype objects and use them to validate data such as DNA sequences,
continuous data etc.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

TypeSafeData constructor.

 Type    : Constructor
 Title   : new
 Usage   : No direct usage, is called by child class;
 Function: Instantiates a Bio::Phylo::Matrices::TypeSafeData
 Returns : a Bio::Phylo::Matrices::TypeSafeData child class
 Args    : -type    => (data type - required)
           Optional:
           -missing => (the symbol for missing data)
           -gap     => (the symbol for gaps)
           -lookup  => (a character state lookup hash)
           -type_object => (a datatype object)
=cut    

    sub new {
        # is child class
        my $class = shift;

        # notify user
        __PACKAGE__->info("constructor called for '$class'");

        # go up inheritance tree, eventually get an ID
        return $class->SUPER::new( @_ );
    }

=back

=head2 MUTATORS

=over

=item set_type()

Set data type.

 Type    : Mutator
 Title   : set_type
 Usage   : $obj->set_type($type);
 Function: Sets the object's datatype.
 Returns : Modified object.
 Args    : Argument must be a string, one of
           continuous, custom, dna, mixed,
           protein, restriction, rna, standard

=cut

    sub set_type {
        my ( $self, $type ) = @_;
        $self->info("setting type '$type'");
        $self->set_type_object( Bio::Phylo::Matrices::Datatype->new( $type ) );
        return $self;
    }

=item set_missing()

Set missing data symbol.

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
        $self->info("setting missing '$missing'");
        $self->get_type_object->set_missing( $missing );
        $self->validate;
        return $self;
    }

=item set_gap()

Set gap data symbol.

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
        $self->info("setting gap '$gap'");
        $self->get_type_object->set_gap( $gap );
        $self->validate;
        return $self;
    }

=item set_lookup()

Set ambiguity lookup table.

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
        my ( $self, $lookup ) = @_;
        $self->info("setting character state lookup hash");
        $self->get_type_object->set_lookup( $lookup );
        $self->validate;
        return $self;
    }

=item set_type_object()

Set data type object.

 Type    : Mutator
 Title   : set_type_object
 Usage   : $obj->set_gap($obj);
 Function: Sets the datatype object
 Returns : Modified object.
 Args    : Argument must be a subclass
           of Bio::Phylo::Matrices::Datatype

=cut

    sub set_type_object {
        my ( $self, $obj ) = @_;
        $self->info("setting character type object");
        $type{ $self->get_id } = $obj;
        eval {
            $self->validate
        };
        if ( $@ ) {
            $self->clear;
            undef($@);
            $self->warn("new type invalidates data (which has been removed)");
        }
        return $self;
    }

=back

=head2 ACCESSORS

=over

=item get_type()

Get data type.

 Type    : Accessor
 Title   : get_type
 Usage   : my $type = $obj->get_type;
 Function: Returns the object's datatype
 Returns : A string
 Args    : None

=cut

    sub get_type {    shift->get_type_object->get_type    }

=item get_missing()

Get missing data symbol.

 Type    : Accessor
 Title   : get_missing
 Usage   : my $missing = $obj->get_missing;
 Function: Returns the object's missing data symbol
 Returns : A string
 Args    : None

=cut

    sub get_missing { shift->get_type_object->get_missing }

=item get_gap()

Get gap symbol.

 Type    : Accessor
 Title   : get_gap
 Usage   : my $gap = $obj->get_gap;
 Function: Returns the object's gap symbol
 Returns : A string
 Args    : None

=cut

    sub get_gap {     shift->get_type_object->get_gap     }

=item get_lookup()

Get ambiguity lookup table.

 Type    : Accessor
 Title   : get_lookup
 Usage   : my $lookup = $obj->get_lookup;
 Function: Returns the object's lookup hash
 Returns : A hash reference
 Args    : None

=cut

    sub get_lookup {  shift->get_type_object->get_lookup  }

=item get_type_object()

Get data type object.

 Type    : Accessor
 Title   : get_type_object
 Usage   : my $obj = $obj->get_type_object;
 Function: Returns the object's linked datatype object
 Returns : A subclass of Bio::Phylo::Matrices::Datatype
 Args    : None

=cut

    sub get_type_object { $type{ shift->get_id } }

=back

=head2 INTERFACE METHODS

=over

=item validate()

Validates the object's contents

 Type    : Interface method
 Title   : validate
 Usage   : $obj->validate
 Function: Validates the object's contents
 Returns : True or throws Bio::Phylo::Util::Exceptions::InvalidData
 Args    : None
 Comments: This is an interface method, i.e. this class doesn't
           implement the method, child classes have to

=cut

    sub validate {
        Bio::Phylo::Util::Exceptions::NotImplemented->throw(
            'error' => 'Not implemented!',
        );
    }
    
    sub _cleanup {
        my $self = shift;
        $self->info("cleaning up '$self'");
        delete $type{ $self->get_id };
    }

}

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo>

This object inherits from L<Bio::Phylo>, so the methods defined therein are
also applicable to L<Bio::Phylo::Matrices::TypeSafeData> objects.

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

$Id: TypeSafeData.pm 4158 2007-07-11 01:34:44Z rvosa $

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