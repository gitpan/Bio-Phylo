# $Id: IO.pm 4198 2007-07-12 16:45:08Z rvosa $
# Subversion: $Rev: 170 $
package Bio::Phylo::IO;
use strict;
use Bio::Phylo;
my @parsers = qw(Newick Nexus Table Taxlist);
my @unparsers = qw(Newick Pagel Svg);

my $cached_parsers = {};

BEGIN {
    use Exporter   ();
    our (@ISA, @EXPORT_OK);

    # set the version for version checking
    use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

    # classic subroutine exporting
    @ISA       = qw(Exporter Bio::Phylo);
    @EXPORT_OK = qw(&parse &unparse);
}

=head1 NAME

Bio::Phylo::IO - Input and output of phylogenetic data.

=head1 SYNOPSIS

 use Bio::Phylo::IO;

 # parsing a tree from a newick string
 my $tree_string = '(((A,B),C),D);';
 my $tree = Bio::Phylo::IO->parse(
    '-string' => $tree_string,

    # old parser, always adds node labels
    '-format' => 'newick',
 )->first;

 # OR:

 $tree = Bio::Phylo::IO->parse(
     '-string' => $tree_string,

     # faster, new parser, node labels optional
     '-format' => 'fastnewick', 

     # with node labels
     '-label'  => 1,            
  )->first; 

 # note: newick parsers return 
 # 'Bio::Phylo::Forest'! Call 
 # ->first to retrieve the first 
 # tree of the forest.

 # prints 'Bio::Phylo::Forest::Tree'
 print ref $tree, "\n";

 # parsing a table
 my $table_string = qq(A,1,2|B,1,2|C,2,2|D,2,1);
 my $matrix = Bio::Phylo::IO->parse(
    '-string'   => $table_string,
    '-format'   => 'table',

    # Data type, see Bio::Phylo::Parsers::Table
    '-type'     => 'STANDARD',

    # field separator  
    '-fieldsep' => ',',

    # line separator
    '-linesep'  => '|'          
 );

 # prints 'Bio::Phylo::Matrices::Matrix'
 print ref $matrix, "\n"; 

 # parsing a list of taxa
 my $taxa_string = 'A:B:C:D';
 my $taxa = Bio::Phylo::IO->parse(
    '-string'   => $taxa_string,
    '-format'   => 'taxlist',
    '-fieldsep' => ':'
 );

 # prints 'Bio::Phylo::Taxa'
 print ref $taxa, "\n";

 # matches taxon names in tree to $taxa object
 $tree->cross_reference($taxa);  

 # likewise for matrix  
 $matrix->cross_reference($taxa);

 print Bio::Phylo::IO->unparse(

    # pass the tree object, 
    # crossreferenced to taxa, which
    # are crossreferenced to the matrix
    '-phylo' => $tree,                         
    '-format' => 'pagel'
 );

 # prints a pagel data file:
 #4 2
 #A,n1,0.000000,1,2
 #B,n1,0.000000,1,2
 #n1,n2,0.000000
 #C,n2,0.000000,2,2
 #n2,n3,0.000000
 #D,n3,0.000000,2,1

=head1 DESCRIPTION

The IO module is the unified front end for parsing and unparsing phylogenetic
data objects. It is a non-OO module that optionally exports the 'parse' and
'unparse' subroutines into the caller's namespace, using the
C<< use Bio::Phylo::IO qw(parse unparse); >> directive. Alternatively, you can
call the subroutines as class methods, as in the synopsis. The C<< parse >> and
C<< unparse >> subroutines load and dispatch the appropriate sub-modules at
runtime, depending on the '-format' argument.

=head2 CLASS METHODS

=over

=item parse()

Parses a file or string.

 Type    : Class method
 Title   : parse
 Usage   : my $obj = Bio::Phylo::IO->parse(%options);
 Function: Creates (file) handle, 
           instantiates appropriate parser.
 Returns : A Bio::Phylo::* object
 Args    : -file    => (path),
            or
           -string  => (scalar),
           -format  => (description format),
           -(other) => (parser specific options)
 Comments: The parse method makes assumptions about 
		   the capabilities of Bio::Phylo::Parsers::* 
		   modules: i) their names match those of the
		   -format => (blah) arguments, insofar that 
		   ucfirst(blah) . '.pm' is an existing module; 
		   ii) the modules implement a _from_handle, 
		   or a _from_string method. Exceptions are 
		   thrown if either assumption is violated.           

=cut

sub parse {
    if ( $_[0] and $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__ ) {
        shift;
    }
    my %opts;
    if ( ! @_ || scalar @_ % 2 ) {
        Bio::Phylo::Util::Exceptions::OddHash->throw(
            error => 'Odd number of elements in hash assignment'
        );
    }
    eval { %opts = @_; };
    if ( $@ ) {
        Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
    }
    if ( ! $opts{'-format'} ) {
        Bio::Phylo::Util::Exceptions::BadArgs->throw(
            error => 'no format specified.'
        );
    }
    if ( ! grep ucfirst( $opts{'-format'} ), @parsers ) {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => 'no parser available for specified format.'
        );
    }
    if ( ! $opts{'-file'} && ! $opts{'-string'} ) {
        Bio::Phylo::Util::Exceptions::BadArgs->throw(
            error => 'no parseable data source specified.'
        );
    }
    my $lib = 'Bio::Phylo::Parsers::' . ucfirst( $opts{-format} );
    my $parser;
    if ( exists $cached_parsers->{$lib} ) {
        $parser = $cached_parsers->{$lib};
    }
    else {
        eval "require $lib";
        if ( $@ ) {
            Bio::Phylo::Util::Exceptions::ExtensionError->throw( error => $@ );
        }
        $parser = $lib->_new;
        $cached_parsers->{$lib} = $parser;
    }
    if ( $opts{-file} && $parser->can('_from_handle') ) {
        require IO::File;
        my $fh = IO::File->new;
        $fh->open("< $opts{-file}");
        if ( $! ) {
            Bio::Phylo::Util::Exceptions::FileError->throw( error => $! );
        }
        $opts{-handle} = $fh;
        return $parser->_from_handle(%opts);
    }
    elsif ( $opts{-string} && $parser->can('_from_string') ) {
        return $parser->_from_string(%opts);
    }
    elsif ( $opts{-string} && ! $parser->can('_from_string') ) {
        Bio::Phylo::Util::Exceptions::BadArgs->throw(
            error => "$opts{-format} parser can't handle strings"
        );
    }
}

=item unparse()

Unparses object(s) to a string.

 Type    : Class method
 Title   : unparse
 Usage   : my $string = Bio::Phylo::IO->unparse(
               %options
           );
 Function: Turns Bio::Phylo object into a 
           string according to specified format.
 Returns : SCALAR
 Args    : -phylo   => (Bio::Phylo object),
           -format  => (description format),
           -(other) => (parser specific options)

=cut

sub unparse {
    if ( $_[0] and $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__ ) {
        shift;
    }
    my %opts;
    if ( ! @_ || scalar @_ % 2 ) {
        Bio::Phylo::Util::Exceptions::OddHash->throw(
            error => 'Odd number of elements in hash assignment'
        );
    }
    eval { %opts = @_; };
    if ( $@ ) {
        Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
    }
    if ( ! $opts{-format} ) {
        Bio::Phylo::Util::Exceptions::BadFormat->throw(
            error => 'no format specified.'
        );
    }
    if ( ! $opts{-phylo} ) {
        Bio::Phylo::Util::Exceptions::BadArgs->throw(
            error => 'no object to unparse specified.'
        );
    }
    my $lib = 'Bio::Phylo::Unparsers::' . ucfirst $opts{-format};
    eval "require $lib";
    if ( $@ ) {
        Bio::Phylo::Util::Exceptions::ExtensionError->throw( error => $@ );
    }
    my $unparser = $lib->_new(%opts);
    if ( $unparser->can('_to_string') ) {
        return $unparser->_to_string;
    }
    else {
        Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
            error => 'the unparser can\'t convert to strings.'
        );
    }
}

# this just to prevent from calling __PACKAGE__->SUPER::DESTROY
sub DESTROY {
    return 1;
}

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Parsers::Newick>

=item L<Bio::Phylo::Parsers::Nexus>

=item L<Bio::Phylo::Parsers::Table>

=item L<Bio::Phylo::Parsers::Taxlist>

=item L<Bio::Phylo::Unparsers::Mrp>

=item L<Bio::Phylo::Unparsers::Newick>

=item L<Bio::Phylo::Unparsers::Nexus>

=item L<Bio::Phylo::Unparsers::Pagel>

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>

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

$Id: IO.pm 4198 2007-07-12 16:45:08Z rvosa $

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
