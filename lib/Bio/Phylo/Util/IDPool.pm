package Bio::Phylo::Util::IDPool;
use strict;
{
    my @reclaim;
    my $obj_counter = 0;

    sub _initialize {
        my $obj_ID = 0;
        if ( @reclaim ) {
            $obj_ID = shift( @reclaim );
        }
        else {
            $obj_ID = $obj_counter;
            $obj_counter++;
        }
        return \$obj_ID;
    }

    sub _reclaim {
        my ( $class, $obj ) = @_;
        #push @reclaim, $obj->get_id;
    }
}
1;
__END__

=head1 NAME

Bio::Phylo::Util::IDPool - Utility class for generating object IDs. No serviceable parts inside.

=head1 DESCRIPTION

This package defines utility functions for generating and reclaiming object
IDs. These functions are called by object constructors and destructors,
respectively. There is no direct usage.

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

$Id: IDPool.pm 4169 2007-07-11 01:36:59Z rvosa $

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
