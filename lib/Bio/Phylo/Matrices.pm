# $Id: Matrices.pm,v 1.25 2006/03/14 12:01:56 rvosa Exp $
# Subversion: $Rev: 186 $
package Bio::Phylo::Matrices;
use strict;
use Bio::Phylo::Listable;
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Util::CONSTANT qw(_NONE_ _MATRICES_);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

# classic @ISA manipulation, not using 'base'
use vars qw($VERSION @ISA);
@ISA = qw(Bio::Phylo::Listable);
{

=head1 NAME

Bio::Phylo::Matrices - Holds a set of matrix objects.

=head1 SYNOPSIS

 use Bio::Phylo::Matrices;
 use Bio::Phylo::Matrices::Matrix;
 
 my $matrices = Bio::Phylo::Matrices->new;
 my $matrix   = Bio::Phylo::Matrices::Matrix->new;
 
 $matrices->insert($matrix);

=head1 DESCRIPTION

The L<Bio::Phylo::Matrices> object models a set of matrices. It inherits from
the L<Bio::Phylo::Listable> object, and so the filtering methods of that object
are available to apply to a set of matrices.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $matrices = Bio::Phylo::Matrices->new;
 Function: Initializes a Bio::Phylo::Matrices object.
 Returns : A Bio::Phylo::Matrices object.
 Args    : None required.

=cut

    sub new {
        my ( $class, $self ) = shift;
        $self = __PACKAGE__->SUPER::new(@_);
        bless $self, __PACKAGE__;
        return $self;
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
        $self->SUPER::DESTROY;
        return 1;
    }

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $matrices->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _container { _NONE_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $matrices->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _type { _MATRICES_ }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Listable>

The L<Bio::Phylo::Matrices> object inherits from the L<Bio::Phylo::Listable>
object. Look there for more methods applicable to the matrices object.

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

$Id: Matrices.pm,v 1.25 2006/03/14 12:01:56 rvosa Exp $

=head1 AUTHOR

Rutger Vos,

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

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

}
1;
