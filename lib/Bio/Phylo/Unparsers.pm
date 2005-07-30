# $Id: Unparsers.pm,v 1.5 2005/07/26 21:05:38 rvosa Exp $
# Subversion: $Rev: 128 $

package Bio::Phylo::Unparsers;
use strict;
use warnings;
use base qw(Bio::Phylo);
my @unparsers = qw(Newick Pagel Svg);

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
        my $unparser = new $lib;
        if ( $unparser->can('to_string') ) {
            return $unparser->to_string(%opts);
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

=head1 BUGS

Please report any bugs or feature requests to
C<bug-phylo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Phylo>.
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
