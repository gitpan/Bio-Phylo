# $Id: $
# Subversion: $Rev: 147 $
package Bio::Phylo::Exceptions;
use strict;
use warnings;

# One line so MakeMaker sees it.
use Bio::Phylo;  our $VERSION = $Bio::Phylo::VERSION;

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 147 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
$VERSION .= '_' . $rev;

# This doesn't actually *do* anything yet. But I promise you:
# One Day It Will.
use Exception::Class (
    'Bio::Phylo::Exceptions::BadArg',
    'Bio::Phylo::Exceptions::BadArg::ArgName' => {
        isa => 'Bio::Phylo::Exceptions::BadArg',
        description => 'Thrown in response to invalid argument name.'
    },
    'Bio::Phylo::Exceptions::BadArg::Number' => {
        isa => 'Bio::Phylo::Exceptions::BadArg',
        description => 'Thrown in response to invalid numerical argument.'
    },
    'Bio::Phylo::Exceptions::BadArg::String' => {
        isa => 'Bio::Phylo::Exceptions::BadArg',
        description => 'Thrown in response to invalid string argument.'
    },
    'Bio::Phylo::Exceptions::BadArg::Object' => {
        isa => 'Bio::Phylo::Exceptions::BadArg',
        description => 'Thrown in response to invalid object argument.'
    },
    'Bio::Phylo::Exceptions::BadArg::Method' => {
        isa => 'Bio::Phylo::Exceptions::BadArg',
        description => 'Thrown in response to invalid method invocation.'
    }
);

=head1 NAME

Bio::Phylo::Exceptions - Exception handling for Bio::Phylo::*

=head1 SYNOPSIS

 use Bio::Phylo::Exceptions;

=head1 DESCRIPTION

The Bio::Phylo::Exceptions class implements an exception hierarchy for
the Bio::Phylo::* modules.

=head1 SEE ALSO

L<Exception::Class>

=cut

1;
