# $Id: Matrices.pm 4234 2007-07-17 13:41:02Z rvosa $
# Subversion: $Rev: 186 $
package Bio::Phylo::Matrices;
use strict;
use warnings FATAL => 'all';
use Bio::Phylo;
use Bio::Phylo::Listable;
use Bio::Phylo::Util::CONSTANT qw(_NONE_ _MATRICES_);
use Bio::Phylo::Util::Logger;
use vars qw($VERSION @ISA);

# set version based on svn rev
my $version = $Bio::Phylo::VERSION;
my $rev     = '$Id: Matrices.pm 4234 2007-07-17 13:41:02Z rvosa $';
$rev        =~ s/^[^\d]+(\d+)\b.*$/$1/;
$version    =~ s/_.+$/_$rev/;
$VERSION    = $version;

# classic @ISA manipulation, not using 'base'
@ISA = qw(Bio::Phylo::Listable);

{
	my $CONSTANT_TYPE = _MATRICES_;
	my $CONSTANT_CONTAINER = _NONE_;
	my $logger = Bio::Phylo::Util::Logger->new;

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

Matrices constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $matrices = Bio::Phylo::Matrices->new;
 Function: Initializes a Bio::Phylo::Matrices object.
 Returns : A Bio::Phylo::Matrices object.
 Args    : None required.

=cut

    sub new {
        # could be child class
        my $class = shift;
        
        # notify user
        $logger->info("constructor called for '$class'");
        
        # recurse up inheritance tree, get ID
        my $self = $class->SUPER::new( @_ );
        
        # local fields would be set here
        
        return $self;
    }

=begin comment

 Type    : Internal method
 Title   : _cleanup
 Usage   : $trees->_cleanup;
 Function: Called during object destruction, for cleanup of instance data
 Returns : 
 Args    :

=end comment

=cut

    sub _cleanup {
        my $self = shift;
        $logger->debug("cleaning up '$self'");
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

    sub _container { $CONSTANT_CONTAINER }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $matrices->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _type { $CONSTANT_TYPE }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Listable>

The L<Bio::Phylo::Matrices> object inherits from the L<Bio::Phylo::Listable>
object. Look there for more methods applicable to the matrices object.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>.

=back

=head1 REVISION

 $Id: Matrices.pm 4234 2007-07-17 13:41:02Z rvosa $

=cut

}

1;
