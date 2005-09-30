# $Id: Exceptions.pm,v 1.11 2005/09/30 19:12:28 rvosa Exp $
# Subversion: $Rev: 170 $
package Bio::Phylo::Exceptions;
use strict;
use warnings;

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

use Exception::Class (
    'Bio::Phylo::Exceptions',

    'Bio::Phylo::Exceptions::BadNumber' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::BadString' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::BadFormat' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::OddHash' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::ObjectMismatch' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::UnknownMethod' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::BadArgs' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::FileError' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::ExtensionError' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::OutOfBounds' =>
    { isa => 'Bio::Phylo::Exceptions' },

    'Bio::Phylo::Exceptions::NotImplemented' =>
    { isa => 'Bio::Phylo::Exceptions' },
);

1;

__END__

=head1 NAME

Bio::Phylo::Exceptions - Exception classes for Bio::Phylo. No serviceable parts
inside.

=head1 DESCRIPTION

This package defines exceptions that can be thrown by other modules. There are
no serviceable parts inside. Refer to the L<Exception::Class>
perldoc for examples on how to catch exceptions and show traces.

=head1 EXCEPTION TYPES

=over

=item Bio::Phylo::Exceptions::BadNumber

Thrown when anything other than a number that passes L<Scalar::Util>'s 
looks_like_number test is given as an argument to a method that expects a number.

=item Bio::Phylo::Exceptions::BadString

Thrown when a string that contains any of the characters C<< ():;, >>  is given
as an argument to a method that expects a name.

=item Bio::Phylo::Exceptions::BadFormat

Thrown when a non-existing parser or unparser format is requested, in calls
such as C<< parse( -format => 'newik', -string => $string ) >>, where 'newik'
doesn't exist.

=item Bio::Phylo::Exceptions::OddHash

Thrown when an odd number of arguments has been specified. This might happen if 
you call a method that requires named arguments and the key/value pairs don't 
seem to match up.

=item Bio::Phylo::Exceptions::ObjectMismatch

Thrown when a method is called that requires an object as an argument, and the
wrong type of object is specified.

=item Bio::Phylo::Exceptions::UnknownMethod

Trown when an indirect method call is attempted through the 
C<< $obj->get('unknown_method') >> interface, and the object doesn't seem to 
implement the requested method.

=item Bio::Phylo::Exceptions::BadArgs

Thrown when something undefined is wrong with the supplied arguments.

=item Bio::Phylo::Exceptions::FileError

Thrown when a file specified as an argument does not exist or is not readable.

=item Bio::Phylo::Exceptions::ExtensionError

Thrown when there is an error loading a requested extension.

=item Bio::Phylo::Exceptions::OutOfBounds

Thrown when an entity is requested that falls outside of the range of
objects contained by a L<Bio::Phylo::Listable> subclass, probably through 
the C<< $obj->get_by_index($i) >> method call.

=item Bio::Phylo::Exceptions::NotImplemented

Thrown when an interface method is called instead of the implementation
by the child class.

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual|Bio::Phylo::Manual>.

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

$Id: Exceptions.pm,v 1.11 2005/09/30 19:12:28 rvosa Exp $

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

