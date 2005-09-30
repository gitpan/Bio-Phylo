# $Id: Matrix.pm,v 1.20 2005/09/29 20:31:18 rvosa Exp $
# Subversion: $Rev: 177 $
package Bio::Phylo::Matrices::Matrix;
use strict;
use warnings;
use base 'Bio::Phylo::Listable';
use Bio::Phylo::CONSTANT qw(_MATRICES_ _MATRIX_);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Matrices::Matrix - The matrix object to aggregate datum objects.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Matrix;
 use Bio::Phylo::Matrices::Datum;
 
 # instantiate matrix object
 my $matrix = Bio::Phylo::Matrices::Matrix->new;

 # instantiate 1000 datum objects and insert them in the matrix
 for my $i ( 0 .. 1000 ) {
    my $datum = Bio::Phylo::Matrices::Datum->new( -pos => $i );
    $matrix->insert($datum);
 }
 
 # retrieve all datum objects whose position >= 500
 my @second_half_of_matrix = @{ $matrix->get_by_value(
    -value => 'get_position',
    -ge    => 500
 ) };
 

=head1 DESCRIPTION

This module defines a container object that holds
L<Bio::Phylo::Matrices::Datum|Bio::Phylo::Matrices::Datum> objects. The matrix
object inherits from L<Bio::Phylo::Listable|Bio::Phylo::Listable>, so the
methods defined there apply here.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $matrix = Bio::Phylo::Matrices::Matrix->new;
 Function: Instantiates a Bio::Phylo::Matrices::Matrix object.
 Returns : A Bio::Phylo::Matrices::Matrix object.
 Args    : NONE required, but look up the inheritance tree to the SUPER class
           Bio::Phylo::Listable, and its parent Bio::Phylo

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

$Id: Matrix.pm,v 1.20 2005/09/29 20:31:18 rvosa Exp $

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
