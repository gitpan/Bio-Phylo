# $Id: Parsers.pm,v 1.5 2005/07/26 21:05:38 rvosa Exp $
# Subversion: $Rev: 128 $

package Bio::Phylo::Parsers;
use strict;
use warnings;
use base qw(Bio::Phylo);
my @parsers = qw(Newick Nexus Table Taxlist);

=head1 NAME

Bio::Phylo::Parsers - A library for parsing phylogenetic data files and strings

=head1 SYNOPSIS

 my $parser = new Bio::Phylo::Parsers;
 $parser->parse(-file => 'data.nex', -format => 'Nexus');

=head1 DESCRIPTION

The Bio::Phylo::Parsers object is the unified 'front door' for parsing trees,
lists of taxa and data matrices. It imports the appropriate subclass at runtime
based on the '-format' argument.

=head2 CONSTRUCTOR

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : my $parser = new Bio::Phylo::Parsers;
 Function: Initializes a Bio::Phylo::Parsers object.
 Returns : A Bio::Phylo::Parsers object.
 Args    : none.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless ( $self, $class );
    return $self;
}

=item parse(%options)

The parse method makes assumptions about the capabilities of
Bio::Phylo::Parsers::* modules: i) their names match those of the
-format => (blah) arguments, insofar that ucfirst(blah) . '.pm' is
an existing module; ii) the modules can either parse from_handle,
i.e. from a file handle that gets passed to them, or from_string
(i.e. from a scalar). I can see this expand to include the
capability to parse from a database handle, and perhaps from a URL.

 Type    : Parsers
 Title   : parse(%options)
 Usage   : $parser->parse(%options);
 Function: Creates (file) handle, instantiates appropriate parser.
 Returns : L<Phylo> object
 Args    : -file => (path), -string => (scalar),
           -format => (description format), -other => (parser specific options)

=cut

sub parse {
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
        if ( ! grep(ucfirst($opts{-format}), @parsers) ) {
            $self->COMPLAIN("no parser available for specified format.");
            return;
        }
        my $lib = ref $self;
        $lib .= '::' . ucfirst($opts{-format});
        eval "require $lib";
        if ( $@ ) {
            $self->COMPLAIN("failure loading parser library");
            return;
        }
        my $parser = new $lib;
        if ( $opts{-file} && $parser->can('from_handle') ) {
            if ( ! -r $opts{-file} ) {
                $self->COMPLAIN("file not found or unreadable");
                return;
            }
            eval { open(FH, $opts{-file}); };
            if ( $@ ) {
                $self->COMPLAIN("failure creating file handle");
                return;
            }
            $opts{-handle} = *FH;
            return $parser->from_handle(%opts);
        }
        elsif ( $opts{-string} && $parser->can('from_string') ) {
            return $parser->from_string(%opts);
        }
        else {
            $self->COMPLAIN("no parseable data source specified.");
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
