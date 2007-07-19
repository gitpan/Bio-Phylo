# $Id: Custom.pm 4213 2007-07-15 03:11:27Z rvosa $
package Bio::Phylo::Matrices::Datatype::Custom;
use strict;
use vars qw(@ISA);
@ISA = qw(Bio::Phylo::Matrices::Datatype);

=head1 NAME

Bio::Phylo::Matrices::Datatype::Custom - Datatype subclass,
no serviceable parts inside

=head1 DESCRIPTION

The Bio::Phylo::Matrices::Datatype::* classes are used to validated data
contained by L<Bio::Phylo::Matrices::Matrix> and L<Bio::Phylo::Matrices::Datum>
objects.

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Matrices::Datatype>

This class subclasses L<Bio::Phylo::Matrices::Datatype>.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>.

=back

=head1 REVISION

 $Id: Custom.pm 4213 2007-07-15 03:11:27Z rvosa $

=cut

sub _new { 
        my $class = shift;
        my $self  = shift;
        my %args  = @_;
        die if not $args{'-lookup'};
        bless $self, $class; 
        $self->set_lookup( $args{'-lookup'} );
        return $self;
}

1;