# $Id: CONSTANT.pm,v 1.8 2005/09/29 20:31:17 rvosa Exp $
# Subversion: $Rev: 177 $
package Bio::Phylo::CONSTANT;
use strict;
use warnings;

BEGIN {
    use Exporter   ();
    our (@ISA, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

    # classic subroutine exporting
    @ISA         = qw(Exporter);
    @EXPORT_OK   = qw(&_NONE_ &_NODE_ &_TREE_ &_FOREST_ &_TAXON_
        &_TAXA_ &_DATUM_ &_MATRIX_ &_MATRICES_ &_SEQUENCE_ &_ALIGNMENT_ );

    %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

}

sub _NONE_      { 0  }
sub _NODE_      { 1  }
sub _TREE_      { 2  }
sub _FOREST_    { 3  }
sub _TAXON_     { 4  }
sub _TAXA_      { 5  }
sub _DATUM_     { 6  }
sub _MATRIX_    { 7  }
sub _MATRICES_  { 8  }
sub _SEQUENCE_  { 9  }
sub _ALIGNMENT_ { 10 }

1;

__END__

=head1 NAME

Bio::Phylo::CONSTANT - Global constants for Bio::Phylo. No serviceable parts
inside.

=head1 DESCRIPTION

This package defines globals used in the Bio::Phylo libraries. The constants
are called internally by the other packages. There is no direct usage.

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

$Id: CONSTANT.pm,v 1.8 2005/09/29 20:31:17 rvosa Exp $

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

