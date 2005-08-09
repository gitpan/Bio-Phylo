# $Id: Unparsers.pm,v 1.6 2005/08/09 12:36:12 rvosa Exp $
# Subversion: $Rev: 148 $

package Bio::Phylo::Unparsers;
use strict;
use warnings;
use base 'Bio::Phylo';
my @unparsers = qw(Newick Pagel Svg);

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 148 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.03';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);

=head1 NAME

Bio::Phylo::Unparsers - A library for stringifying phylogenetic data files and
strings

=head1 SYNOPSIS

 my $unparser = new Bio::Phylo::Unparsers;
 print $unparser->unparse(-phylo => $tree, -format => 'newick');

=head1 DESCRIPTION

The Unparsers module is the unified front end for unparsing tree objects. The
module imports the appropriate sub-module at runtime, depending on the '-format'
argument.

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $unparser = new Bio::Phylo::Unparsers;
 Function: Initializes a Bio::Phylo::Unparsers object.
 Returns : A Bio::Phylo::Unparsers object.
 Args    : none.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless ( $self, $class );
    return $self;
}

=item unparse(%options)

The unparse method is the front door for the various unparser modules. All
argument checking should be done here, not by the individual unparsers. At this
point, the assumption is that all (valid) unparsers can do a to_string method,
but conceivably this should be extended to include to_file methods, and
possibly to_database.

 Type    : Parsers
 Title   : unparse(%options)
 Usage   : $unparser->unparse(%options);
 Function: Turns Bio::Phylo object into a string according to specified format.
 Returns : SCALAR
 Args    : -phylo => (Bio::Phylo object),
           -format => (description format),
           -other => (parser specific options)

=cut

sub unparse {
    my $self = shift;
    my @opts = @_;
    my %opts;
    if ( ! @opts || scalar @opts % 2 ) {
        $self->COMPLAIN("bad number of arguments.");
        return;
    }
    else {
        %opts = @opts;
        if ( ! $opts{-format} ) {
            $self->COMPLAIN("no format specified.");
            return;
        }
        if ( ! $opts{-phylo} ) {
            $self->COMPLAIN("no object to unparse specified.");
            return;
        }
        my $lib = ref $self;
        $lib .= '::' . ucfirst($opts{-format});
        eval "require $lib";
        if ( $@ ) {
            $self->COMPLAIN("no valid parser found");
            return;
        }
        my $unparser = $lib->new(%opts);
        if ( $unparser->can('to_string') ) {
            return $unparser->to_string;
        }
        else {
            $self->COMPLAIN("the unparser can't convert to strings");
            return;
        }
    }
}

=back

=head1 AUTHOR

Rutger Vos, C<< <rvosa@sfu.ca> >>
L<http://www.sfu.ca/~rvosa/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed
from BioPerl L<http://www.bioperl.org>, and CIPRES
L<http://www.phylo.org> and FAB* L<http://www.sfu.ca/~fabstar> for
comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
