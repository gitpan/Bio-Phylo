# $Id: Phylo.pm,v 1.20 2005/09/29 20:31:16 rvosa Exp $
# Subversion: $Rev: 189 $
package Bio::Phylo;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use Bio::Phylo::Exceptions;
use Storable qw(dclone);
use fields qw(NAME                
              DESC 
              SCORE 
              GENERIC);

# The bit of voodoo is for including Subversion keywords in the main source
# file. $Rev is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Rev: 189 $';
$rev =~ s/^[^\d]+(\d+)[^\d]+$/$1/;
our $VERSION = '0.05';
$VERSION .= '_' . $rev;
my $VERBOSE = 1;
use vars qw($VERSION);

=head1 NAME

Bio::Phylo - Phylogenetic analysis using perl.

=head1 DESCRIPTION

This is the base class for the Bio::Phylo package. All other modules inherit
from it, the methods defined here are applicable to all. Consult the manual
for usage examples: L<Bio::Phylo::Manual>.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

The Bio::Phylo object itself, and thus its constructor, is rarely, if ever, used
directly. Rather, all other objects in this package inherit its methods, and call
its constructor internally.

 Type    : Constructor
 Title   : new
 Usage   : my $phylo = Bio::Phylo->new;
 Function: Instantiates Bio::Phylo object
 Returns : a Bio::Phylo object
 Args    : -name    => (object name)
           -desc    => (object description)
           -score   => (numerical score)
           -generic => (generic key/value pair)

=cut

sub new {
    my Bio::Phylo $self = shift;
    unless (ref $self) {
        $self = fields::new($self);
    }
    if (@_) {
        my %opts;
        eval { %opts = @_; };
        if ($@) {
            Bio::Phylo::Exceptions::OddHash->throw(
                error => $@
            );        
        }
        while ( my ( $key, $value ) = each %opts ) {
            my $localkey = uc substr $key, 1;
            eval { $self->{$localkey} = $value; };
            if ($@) {
                Bio::Phylo::Exceptions::BadArgs->throw(
                    error => "invalid field specified: $key ($localkey)"
                );
            }
        }
    }
    return $self;
}

=back

=head2 MUTATORS

=over

=item set_name()

 Type    : Mutator
 Title   : set_name
 Usage   : $obj->set_name($name);
 Function: Assigns an object's name.
 Returns : Modified object.
 Args    : Argument must be a string that doesn't contain [;|,|:\(|\)]

=cut

sub set_name {
    my ( $self, $name ) = @_;
    my $ref = ref $self;
    if ( $name =~ m/([;|,|:|\(|\)])/ ) {
        Bio::Phylo::Exceptions::BadString->throw(
            error => "\"$name\" is a bad name format for $ref names"
        );
    }
    else {
        $self->{'NAME'} = $name;
    }
    return $self;
}

=item set_desc()

 Type    : Mutator
 Title   : set_desc
 Usage   : $obj->set_desc($desc);
 Function: Assigns an object's description.
 Returns : Modified object.
 Args    : Argument must be a string.
 
=cut

sub set_desc {
    my ( $self, $desc ) = @_;
    $self->{'DESC'} = $desc;
    return $self;
}

=item set_score()

 Type    : Mutator
 Title   : set_score
 Usage   : $obj->set_score($score);
 Function: Assigns an object's numerical score.
 Returns : Modified object.
 Args    : Argument must be any of perl's number formats.

=cut

sub set_score {
    my $self = $_[0];
    if ( defined $_[1] ) {
        my $score = $_[1];
        if ( looks_like_number $score ) {
            $self->{'SCORE'} = $score;
        }
        else {
            Bio::Phylo::Exceptions::BadNumber->throw(
                error => "Score \"$score\" is a bad number"                
            );            
        }
    }
    else {
        $self->{'SCORE'} = undef;
    }
    return $self;
}

=item set_generic()

 Type    : Mutator
 Title   : set_generic
 Usage   : $obj->set_generic(%generic);
 Function: Assigns generic key/value pairs to the invocant.
 Returns : Modified object.
 Args    : Valid arguments constitute key/value pairs, for example:
           $node->set_generic(posterior => 0.87565);

=cut

sub set_generic {
    my $self = shift;
    if (@_) {
        my %args;
        eval { %args = @_ };
        if ($@) {
            Bio::Phylo::Exceptions::OddHash->throw(
                error => $@
            );
        }
        else {
            foreach my $key ( keys %args ) {
                $self->{'GENERIC'}->{$key} = $args{$key};
            }
        }
    }
    else {
        $self->{'GENERIC'} = undef;
    }
    return $self;
}

=back

=head2 ACCESSORS

=over

=item get_name()

 Type    : Accessor
 Title   : get_name
 Usage   : my $name = $obj->get_name;
 Function: Returns the object's name (if any).
 Returns : A string
 Args    : None

=cut

sub get_name {
    return $_[0]->{'NAME'};
}

=item get_desc()

 Type    : Accessor
 Title   : get_desc
 Usage   : my $desc = $obj->get_desc;
 Function: Returns the object's description (if any).
 Returns : A string
 Args    : None

=cut

sub get_desc {
    return $_[0]->{'DESC'};
}

=item get_score()

 Type    : Accessor
 Title   : get_score
 Usage   : my $score = $obj->get_score;
 Function: Returns the object's numerical score (if any).
 Returns : A number
 Args    : None

=cut

sub get_score {
    return $_[0]->{'SCORE'};
}

=item get_generic()

 Type    : Accessor
 Title   : get_generic
 Usage   : my $value = $obj->get_generic($key);
           or
           my %hash = %{ $obj->get_generic($key) };
 Function: Returns the object's generic data. If an
           argument is used, it is considered a key
           for which the associated value is return.
           Without arguments, a reference to the whole
           hash is returned.
 Returns : A string or hash reference.
 Args    : None
 
=cut 

sub get_generic {
    my ( $self, $key ) = @_;
    if ( defined $key ) {
        return $self->{'GENERIC'}->{$key};
    }
    else {
        return $self->{'GENERIC'};
    }
}

=back

=head2 PACKAGE METHODS

=over

=item get()

All objects in the package subclass the Bio::Phylo object, and so, for example,
you can do $node->get('get_branch_length'); instead of $node->get_branch_length.
This is a useful feature for listable objects especially, as they have the
get_by_value method, which allows you to retrieve, for instance, a list of nodes
whose branch length exceeds a certain value. That method (and
get_by_regular_expression) uses this $obj->get method.

 Type    : Accessor
 Title   : get
 Usage   : my $treelength = $tree->get('calc_tree_length');
 Function: Alternative syntax for safely accessing any of the object data;
           useful for interpolating runtime $vars.
 Returns : (context dependent)
 Args    : a SCALAR variable, e.g. $var = 'calc_tree_length';

=cut

sub get {
    my ( $self, $var ) = @_;
    if ( $self->can($var) ) {
        return $self->$var;
    }
    else {
        my $ref = ref $self;
        Bio::Phylo::Exceptions::UnknownMethod->throw(
            error => "sorry, a \"$ref\" can't \"$var\""
        );
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
        my %opt;
        eval { %opt = @_; };
        if ($@) {
            Bio::Phylo::Exceptions::OddHash->throw(
                error => $@
            );
        }
        $VERBOSE = $opt{'-level'};
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
    return 1;
}

=begin comment

 Type    : Interface
 Title   : container
 Usage   : $phylo->_container;
 Function:
 Returns : CONSTANT
 Args    :
 
=end comment

=cut

sub _container {
    Bio::Phylo::Exceptions::NotImplemented->throw(
        error => 'Attempt to call interface method'
    );
}

=begin comment

 Type    : Interface
 Title   : _type
 Usage   : $phylo->_type;
 Function:
 Returns : CONSTANT
 Args    :
 
=end comment

=cut

sub _type {
    Bio::Phylo::Exceptions::NotImplemented->throw(
        error => 'Attempt to call interface method'
    );
}

=back

=head1 SEE ALSO

Also see the manual: L<Bio::Phylo::Manual>.

=head1 FORUM

CPAN hosts a discussion forum for Bio::Phylo. If you have trouble using this
module the discussion forum is a good place to start posting questions (NOT bug
reports, see below): L<http://www.cpanforum.com/dist/Bio-Phylo>

=head1 BUGS

Please report any bugs or feature requests to C<< bug-bio-phylo@rt.cpan.org >>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo>. I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes. Be sure to include the following in your request or comment, so that
I know what version you're using:

$Id: Phylo.pm,v 1.20 2005/09/29 20:31:16 rvosa Exp $

=head1 AUTHOR

Rutger Vos,

=over

=item email: C<< rvosa@sfu.ca >>

=item web page: L<http://www.sfu.ca/~rvosa/>

=back

=head1 ACKNOWLEDGEMENTS

The author would like to thank Jason Stajich for many ideas borrowed from
BioPerl L<http://www.bioperl.org>, and CIPRES L<http://www.phylo.org> and
FAB* L<http://www.sfu.ca/~fabstar> for comments and requests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rutger Vos, All Rights Reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
