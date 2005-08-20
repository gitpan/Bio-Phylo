# $Id: Phylo.pm,v 1.7 2005/08/11 19:41:12 rvosa Exp $
# Subversion: $Rev: 148 $
package Bio::Phylo;
use constant TREES    => 0;
use constant TAXA     => 1;
use constant MATRICES => 2;
use constant COMMENTS => 3;
use strict;
use warnings;
use Storable qw(dclone);

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 148 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.04';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);

=head1 NAME

Bio::Phylo - A base module for analyzing and manipulating phylogenetic trees.

=head1 SYNOPSIS

 use Bio::Phylo;

 #instantiate a new object
 my $phylo = new Bio::Phylo;

 #and destroy it
 $phylo->DESTROY;

=head1 DESCRIPTION

=head2 INTRODUCTION

The Bio::Phylo package consists of a collection of Perl
libraries (OO-style) for parsing, generating and
analyzing phylogenetic trees. The intended audience are
biologists who are well versed in phylogenetic theory
and comfortable with text editors. The simplest usage
of Bio::Phylo would be for file conversion, in which case
only a few lines of code would suffice. However, the
libraries offer more, and in order to make these features
more easily accessible I should start with a description
of how Bio::Phylo sees trees, taxa, and matrices.

=head3 THE Bio::Phylo OBJECT MODEL

=head4 TREES

According to Bio::Phylo, there are Trees (which are
modelled by the Bio::Phylo::Trees object), which contain
Bio::Phylo::Trees::Tree objects, which contain
Bio::Phylo::Trees::Node objects.

=over

=item The Bio::Phylo::Trees::Node object

A node 'knows' a couple
of things: its name, its branch length (i.e. the length
of the branch connecting it and its parent), who its
parent is, its next sister (on its right), its previous
sister (on the left), its first daughter and its last
daughter. These properties can be retrieved and
modified by methods classified as ACCESSORS and MUTATORS.

From this set of properties follows a number of
things which must be either true or false. For example,
if a node has no children it is a terminal node. By asking
a node whether it "is_terminal", it replies either with
true (i.e. 1) or false (undef). Methods such as this
are classified as TESTS.

Likewise, based on the properties of an individual
node we can perform a query to retrieve nodes related
to it. For example, by asking the node to
"get_ancestors" it returns a list of its ancestors,
being all the nodes and the path from its parent to,
and including, the root. These methods are QUERIES.

Lastly, some CALCULATIONS can be performed by the
node. By asking the node to "calc_path_to_root" it
calculates the sum of the lengths of the branches
connecting it and the root. Of course, in order to make
all this possible, a node has to exist, so it needs to
be constructed. The CONSTRUCTOR is the Bio::Phylo::Node->new()
method.

Once a node has served its purpose it
can be destroyed. For this purpose there is a
DESTRUCTOR, which cleans up once we're done with the
node. However, in most cases you don't have to worry
about constructing and destroying nodes as this is done
for you by a parser or a generator as needs arise.

For a detailed description of all the node methods,
their arguments and return values, consult the node
documentation, which, after install, can be viewed by
issuing the "perldoc Bio::Phylo::Trees::Node" command.

=item The Bio::Phylo::Trees::Tree object

A tree knows very
little. All it really holds is a set of nodes, which
are there because of TREE POPULATION, i.e. the process
of inserting nodes in the tree. The tree can be queried
in a number of ways, for example, we can ask the tree
to "get_entities", to which the tree replies with a list
of all the nodes it holds. Be advised that this doesn't
mean that the nodes are connected in a meaningful way,
if at all. The tree doesn't care, the nodes are
supposed to know who their parents, sisters, and
daughters are. But, we can still get, for example, all
the terminal nodes (i.e. the tips) in the tree by
retrieving all the nodes in the tree and asking each
one of them whether it "is_terminal", discarding the
ones that aren't.

Based on the set of nodes the tree holds it can
perform calculations, such as "calc_tree_length", which
simply means that the tree iterates over all its nodes,
summing their branch lengths, and returning the total.

The tree object also has a constructor and a
destructor, but normally you don't have to worry about
that. All the tree methods can be viewed by issuing the
"perldoc Bio::Phylo::Trees::Tree" command.

=item The Bio::Phylo::Trees object

The object containing all others is the Trees object. It
serves merely as a container to hold multiple trees, which
are inserted in the Trees object using the "insert()" method,
and retrieved using the "get_entities" method. More information
can be found in the Bio::Phylo::Trees perldoc page.

=back

=head3 CREATING NODES AND TREES

=over

=item The Bio::Phylo::Parsers::* objects

Trees are probably most easily imported from files. To
this end Bio::Phylo::Parsers objects are available. The
constructor and destructor aside, these have only one method
intended for outside access: "parse", with arguments
indicating the tree format, and the location of the
tree file.

=item The Bio::Phylo::Generator object

For simulations you can also generate trees. The currently
available models are Yule, Hey and equiprobable. Consult the
perldoc pages for Bio::Phylo::Generator to learn more about
how to address this object.

=back

=head2 USEFUL FEATURES

The following features are of particular interest:

=over

=item Stemminess and Balance measures

A number of analysis methods heretofore unavailable are included
in this package, such as calculation of two stemminess indices
(Fiala et al, 1985; Rohlf et al., 1990).

=item Filters

Sets of objects can be filtered based on the results of any
calculation available in this package. For example: Trees can
be filtered on tree length, or imbalance, and so on. Nodes can
be filtered based on their distance to the root, or to the tips,
and so on. In addition, sets of objects can be filtered based on
the string results of any method. For example, on a tree that
contains species from the genera Lemur, Hapalemur, Eulemur and
Otolemur these can all be filtered out by searching on the
/^.*lemur$/i pattern.

=item Converters

The Phylo packages includes a number of parsers and unparsers,
and additional ones can be included simply by writing the
appropriate package and dropping the file in the Parsers or
Unparsers folder. No modification of any of the other source is
required, as long as a very limited set of methods is supported.
With the currently packaged parsers, one can for example import
taxa from one file, a tree from another, and a data matrix from
a third file, then crossreference the three, and output them in
a format suitable for Discrete, Continuous or Multistate. (The
tree is resolved on the fly.)

=back

=head2 REQUIREMENTS

Phylo has the following requirements:

=over

=item A recent version of perl (5.6.* or 5.8.*);

The module should then build on all platforms. A quick test
yielded success on all platforms that I tried:

    - perl, v5.8.4 built for MSWin32-x86-multi-thread
    - perl, v5.8.6 built for cygwin-thread-multi-64int
    - perl, v5.8.0 built for darwin
    - perl, v5.8.0 built for sun4-solaris
    - perl, v5.6.1 built for i386-linux
    - perl, v5.8.1-RC3 built for darwin-thread-multi-2level

Older versions of perl5 may or may not work. Perl4 definitely won't work.

=item Any version of the Math::Random module for generating Yule and Hey trees.

Math::Random can be installed from the comprehensive perl archive network by
issuing:

    perl -MCPAN -e 'install Math::Random'

or, on Windows:

    ppm
    install Math::Random

from the command line.

=item Any version of the SVG module for drawing trees.

SVG.pm can be installed from the comprehensive perl archive network by
issuing:

    perl -MCPAN -e 'install SVG'

or, on Windows:

    ppm
    install SVG

from the command line.

=back

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

The Bio::Phylo object itself, and thus its constructor, is rarely, if ever, used
directly. Rather, all other objects in this package inherit its methods.

 Type    : Constructor
 Title   : new
 Usage   : my $phylo = new Bio::Phylo;
 Function: Instantiates Bio::Phylo object
 Returns : a Bio::Phylo object
 Args    : none

=cut

sub new {
    my $class = shift;
    my $self  = [];
    $self->[TREES]    = [];
    $self->[TAXA]     = [];
    $self->[MATRICES] = [];
    $self->[COMMENTS] = [];
    bless( $self, $class );
    return $self;
}

=back

=head2 PACKAGE METHODS

=over

=item get()

All objects in the package subclass the Bio::Phylo object, and so,
for example, you can do $node->get('get_branch_length'); instead
of $node->get_branch_length. This is a useful feature for listable
objects especially, as the have the get_by_value method, which
allows you to retrieve, for instance, a list of nodes whose branch
length exceeds a certain value. That method (and get_by_regular_expression)
uses this $obj->get method.

 Type    : Accessor
 Title   : get
 Usage   : my $treelength = $tree->get('calc_tree_length');
 Function: Alternative syntax for safely accessing any of the object data;
           useful for interpolating runtime $vars.
 Returns : A SCALAR numerical value.
 Args    : a SCALAR variable, e.g. $var = 'calc_matrix_size';

=cut

sub get {
    my ( $self, $var ) = @_;
    if ( $self->can($var) ) {
        return $self->$var;
    }
    else {
        my $ref = ref $self;
        $self->COMPLAIN("sorry, a \"$ref\" can't \"$var\": $@");
        return;
    }
}

=item clone()

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : none.

=cut

sub clone {
    my $self = shift;
    my $clone = dclone($self);
    return $clone;
}

=item VERBOSE()

Getter and setter for the verbose level. Currently it's just 0=no messages,
1=messages, but perhaps there could be more levels? For caller diagnostics
and so on?

 Type    : Accessor
 Title   : VERBOSE(0|1)
 Usage   : Phylo->VERBOSE(0|1)
 Function: Sets/gets verbose level
 Alias   :
 Returns : Verbose level
 Args    : 0=no messages; 1=error messages
 Comments:

=cut

sub VERBOSE {
    my $class = shift;
    if (@_) {
        my %opt = @_;
        $VERBOSE = $opt{-level};
    }
    return $VERBOSE;
}

=item CITATION()

 Type    : Accessor
 Title   : CITATION
 Usage   : $phylo->CITATION;
 Function: Returns suggested citation.
 Alias   :
 Returns : Returns suggested citation.
 Args    : None
 Comments:

=cut

sub CITATION {
    my $self    = shift;
    my $name    = __PACKAGE__;
    my $version = __PACKAGE__->VERSION;
    my $string  = qq{Rutger A. Vos, 2005. $name: };
       $string .= qq{Phylogenetic analysis using Perl, version $version};
    return $string;
}

=item COMPLAIN()

 Type    : Internal method
 Title   : COMPLAIN
 Usage   : $phylo->COMPLAIN("error");
 Function: Prints error message to STDERR if verbose level > 0
 Alias   :
 Returns : TRUE
 Args    : String, error message
 Comments:

=cut

sub COMPLAIN {
    my ( $phylo, $complaint ) = @_;
    my $length = length($complaint) * $phylo->VERBOSE;
    $complaint = substr( $complaint, 0, $length );
    my ( $package, $file, $line ) = caller;
    my $level2 = qq{package: $package, file: $file, line: $line};
    print STDERR qq{$complaint};
    return 1;
}

=item VERSION()

 Type    : Accessor
 Title   : VERSION
 Usage   : $phylo->VERSION;
 Function: Returns version number (including revision number).
 Alias   :
 Returns : SCALAR
 Args    : NONE
 Comments:

=cut

sub VERSION {
    shift;
    return $VERSION;
}

=back

=head2 DESTRUCTOR

=over

=item DESTROY()

The destructor doesn't actually do anything yet, but it may be used, in the
future, for additional debugging messages.

 Type    : Destructor
 Title   : DESTROY
 Usage   : $phylo->DESTROY
 Function: Destroys Phylo object
 Alias   :
 Returns : TRUE
 Args    : none
 Comments: You don't really need this, perl takes care of memory
           management and garbage collection.

=cut

sub DESTROY {
    my $self = $_[0];
    return 1;
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
