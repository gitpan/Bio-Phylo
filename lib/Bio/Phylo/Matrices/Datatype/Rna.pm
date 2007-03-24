package Bio::Phylo::Matrices::Datatype::Rna;
use strict;
use vars qw($LOOKUP @ISA $MISSING $GAP);
@ISA=qw(Bio::Phylo::Matrices::Datatype);

=head1 NAME

Bio::Phylo::Matrices::Datatype::Rna - Datatype subclass,
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

$Id: Rna.pm 3386 2007-03-24 16:22:25Z rvosa $

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

$LOOKUP = {
    'A' => [ 'A'                ],
    'C' => [ 'C'                ],
    'G' => [ 'G'                ],
    'U' => [ 'U'                ],
    'M' => [ 'A', 'C'           ],
    'R' => [ 'A', 'G'           ],
    'W' => [ 'A', 'U'           ],
    'S' => [ 'C', 'G'           ],
    'Y' => [ 'C', 'U'           ],
    'K' => [ 'G', 'U'           ],
    'V' => [ 'A', 'C', 'G'      ],
    'H' => [ 'A', 'C', 'U'      ],
    'D' => [ 'A', 'G', 'U'      ],
    'B' => [ 'C', 'G', 'U'      ],
    'X' => [ 'G', 'A', 'U', 'C' ],
    'N' => [ 'G', 'A', 'U', 'C' ],
};

$MISSING = '?';

$GAP = '-';

1;