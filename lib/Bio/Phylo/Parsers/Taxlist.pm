# $Id: Taxlist.pm 4167 2007-07-11 01:36:38Z rvosa $
# Subversion: $Rev: 193 $
package Bio::Phylo::Parsers::Taxlist;
use strict;
use Bio::Phylo;
use Bio::Phylo::Taxa;
use Bio::Phylo::Taxa::Taxon;
use Bio::Phylo::IO;

use vars '@ISA';
@ISA=qw(Bio::Phylo::IO);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Parsers::Taxlist - Parses lists of taxon names. No serviceable parts
inside.

=head1 DESCRIPTION

This module is used for importing sets of taxa from plain text files, one taxon
on each line. It is called by the L<Bio::Phylo::IO|Bio::Phylo::IO> object, so
look there for usage examples. If you want to parse from a string, you
may need to indicate the field separator (default is '\n') to the
Bio::Phylo::IO->parse call:

 -fieldsep => '\n',

=begin comment

 Type    : Constructor
 Title   : new
 Usage   : my $taxlist = Bio::Phylo::Parsers::Taxlist->new;
 Function: Initializes a Bio::Phylo::Parsers::Taxlist object.
 Returns : A Bio::Phylo::Parsers::Taxlist object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = $_[0];
    my $self  = {};
    bless $self, $class;
    return $self;
}

=begin comment

 Type    : parser
 Title   : from_handle(%options)
 Usage   : $taxlist->from_handle(%options);
 Function: Reads taxon names from file, populates taxa object
 Returns : A Bio::Phylo::Taxa object.
 Args    : -handle => (\*FH), -file => (filename)
 Comments:

=end comment

=cut

*_from_handle = \&_from_both;
*_from_string = \&_from_both;

sub _from_both {
    my $self = shift;
    my %opts = @_;
    if ( !$opts{'-fieldsep'} ) {
        $opts{'-fieldsep'} = "\n";
    }
    my $taxa = Bio::Phylo::Taxa->new;
    if ( $opts{'-handle'} ) {
        while ( readline $opts{'-handle'} ) {
            chomp;
            if ($_) {
                $taxa->insert( Bio::Phylo::Taxa::Taxon->new( -name => $_ ) );
            }
        }
    }
    elsif ( $opts{'-string'} ) {
        foreach ( split /$opts{'-fieldsep'}/, $opts{'-string'} ) {
            chomp;
            if ($_) {
                $taxa->insert( Bio::Phylo::Taxa::Taxon->new( -name => $_ ) );
            }
        }
    }
    return $taxa;
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The taxon list parser is called by the L<Bio::Phylo::IO|Bio::Phylo::IO> object.
Look there for examples.

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

$Id: Taxlist.pm 4167 2007-07-11 01:36:38Z rvosa $

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

1;
