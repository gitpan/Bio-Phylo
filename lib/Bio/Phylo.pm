# $Id: Phylo.pm,v 1.29 2006/04/12 22:38:22 rvosa Exp $
package Bio::Phylo;
use strict;
use Scalar::Util qw(looks_like_number weaken blessed);
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Util::Exceptions;
use XML::Simple;
use Storable qw(dclone);

# The bit of voodoo is for including CVS keywords in the main source file.
# $Id is the subversion revision number. The way I set it up here allows
# 'make dist' to build a *.tar.gz without the "_rev#" in the package name, while
# it still shows up otherwise (e.g. during 'make test') as a developer release,
# with the "_rev#".
my $rev = '$Id: Phylo.pm,v 1.29 2006/04/12 22:38:22 rvosa Exp $';
$rev =~ s/^[^\d]+(\d+\.\d+)\b.*$/$1/;
our $VERSION = '0.08';
$VERSION .= '_' . $rev;
my $VERBOSE = 0;
use vars qw($VERSION);

{
    # inside out class arrays
    my @name;
    my @desc;
    my @score;
    my @generic;
    my @cache;
    my @container;

    # $fields hashref necessary for object destruction
    my $fields = {
        '-name'      => \@name,
        '-desc'      => \@desc,
        '-score'     => \@score,
        '-generic'   => \@generic,
        '-cache'     => \@cache,
        '-container' => \@container,
    };
    
    # global container for Forest, Matrix and Taxa objects (a la Mesquite 
    # project)
    my $super = {};

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
        my $class = shift;
        my $self  = Bio::Phylo::Util::IDPool->_initialize();
        bless $self, __PACKAGE__;
        if ( @_ ) {
            my %opt;
            eval { %opt = @_; };
            if ( $@ ) {
                Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
            }
            else {
                while ( my ( $key, $value ) = each %opt ) {
                    if ( $fields->{$key} ) {
                        $fields->{$key}->[$$self] = $value;
                        delete $opt{$key};
                    }
                }
                @_ = %opt;
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
 Args    : Argument must be a string,
           single quoted if it
           contains [;|,|:\(|\)]

=cut

    sub set_name {
        my ( $self, $name ) = @_;
        my $ref = ref $self;
        if ( $name && $name !~ m/^'.*'$/ && $name =~ m/(?:;|,|:|\(|\))/ ) {
            Bio::Phylo::Util::Exceptions::BadString->throw(
                error => "\"$name\" is a bad name format for $ref names"
            );
        }
        else {
            $name[$$self] = $name;
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
        $desc[$$self] = $desc;
        return $self;
    }

=item set_score()

 Type    : Mutator
 Title   : set_score
 Usage   : $obj->set_score($score);
 Function: Assigns an object's numerical score.
 Returns : Modified object.
 Args    : Argument must be any of 
           perl's number formats.

=cut

    sub set_score {
        my $self = $_[0];
        if ( defined $_[1] ) {
            my $score = $_[1];
            if ( looks_like_number $score ) {
                $score[$$self] = $score;
            }
            else {
                Bio::Phylo::Util::Exceptions::BadNumber->throw(
                    error => "Score \"$score\" is a bad number"
                );
            }
        }
        else {
            $score[$$self] = undef;
        }
        return $self;
    }

=item set_generic()

 Type    : Mutator
 Title   : set_generic
 Usage   : $obj->set_generic(%generic);
 Function: Assigns generic key/value pairs to the invocant.
 Returns : Modified object.
 Args    : Valid arguments constitute 
           key/value pairs, for example:
           $node->set_generic(
               '-posterior' => 0.87565,
           );

=cut

    sub set_generic {
        my $self = shift;
        if ( @_ ) {
            my %args;
            eval { %args = @_ };
            if ( $@ ) {
                Bio::Phylo::Util::Exceptions::OddHash->throw(
                    error => $@
                );
            }
            else {
                foreach my $key ( keys %args ) {
                    $generic[$$self]->{$key} = $args{$key};
                }
            }
        }
        else {
            $generic[$$self] = {};
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
        my $self = shift;
        return $name[$$self];
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
        my $self = shift;
        return $desc[$$self];
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
        my $self = shift;
        return $score[$$self];
    }

=item get_generic()

 Type    : Accessor
 Title   : get_generic
 Usage   : my $value = $obj->get_generic($key);
           or
           my %hash = %{ $obj->get_generic() };
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
            return $generic[$$self]->{$key};
        }
        else {
            return $generic[$$self];
        }
    }
    
=item get_id()

 Type    : Accessor
 Title   : get_id
 Usage   : my $id = $obj->get_id;
 Function: Returns the object's unique ID
 Returns : INT
 Args    : None

=cut

    sub get_id {
        my $self = shift;
        return $$self;
    }    

=back

=head2 PACKAGE METHODS

=over

=item get()

All objects in the package subclass the Bio::Phylo object, and so, for example,
you can do C<$node-E<gt>get('get_branch_length');> instead of C<$node-E<gt>get_branch_length>.
This is a useful feature for listable objects especially, as they have the
get_by_value method, which allows you to retrieve, for instance, a list of nodes
whose branch length exceeds a certain value. That method (and
get_by_regular_expression) uses this C<$obj-E<gt>get method>.

 Type    : Accessor
 Title   : get
 Usage   : my $treename = $tree->get('get_name');
 Function: Alternative syntax for safely accessing 
           any of the object data; useful for 
           interpolating runtime $vars.
 Returns : (context dependent)
 Args    : a SCALAR variable, e.g. $var = 'get_name';

=cut

    sub get {
        my ( $self, $var ) = @_;
        if ( $self->can($var) ) {
            return $self->$var;
        }
        else {
            my $ref = ref $self;
            Bio::Phylo::Util::Exceptions::UnknownMethod->throw(
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
                Bio::Phylo::Util::Exceptions::OddHash->throw(
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
 Returns : Returns suggested citation.
 Args    : None
 Comments:

=cut

    sub CITATION {
        my $self    = shift;
        my $name    = __PACKAGE__;
        my $version = __PACKAGE__->VERSION;
        my $string  = qq{Rutger A. Vos, 2006. $name: };
           $string .= qq{Phylogenetic analysis using Perl, version $version};
        return $string;
    }

=item VERSION()

 Type    : Accessor
 Title   : VERSION
 Usage   : $phylo->VERSION;
 Function: Returns version number 
           (including CVS revision number).
 Alias   :
 Returns : SCALAR
 Args    : NONE
 Comments:

=cut

    sub VERSION { $VERSION; }
    
=item to_xml()

 Type    : Format converter
 Title   : to_cipres
 Usage   : my $xml = $obj->to_xml;
 Function: Turns the invocant object into an XML string.
 Returns : SCALAR
 Args    : NONE

=cut

sub to_xml {
    my $self = shift;
    my $class = ref $self;
    $class =~ s/^.*:([^:]+)$/$1/g;
    $class = lc($class);
    my $xml = '<' . $class . ' id="' . $class . $self->get_id . '">';
    my $generic = $self->get_generic;
    my ( $name, $score, $desc ) = ( $self->get_name, $self->get_score, $self->get_desc );
    $xml .= '<name>' . $name . '</name>' if $name;
    $xml .= '<score>' . $score . '</score>' if $score;
    $xml .= '<desc>' . $desc . '</desc>' if $desc;
    $xml .= XMLout( $generic ) if $generic && %{ $generic };
    if ( $self->isa('Bio::Phylo::Listable') ) {
        foreach my $ent ( @{ $self->get_entities } ) {
            $xml .= $ent->to_xml;
        }
    }
    $xml .= '</' . $class . '>';
    return $xml;
}    

=back

=head2 DESTRUCTOR

=over

=item DESTROY()

 Type    : Destructor
 Title   : DESTROY
 Usage   : $phylo->DESTROY
 Function: Destroys Phylo object
 Alias   :
 Returns : TRUE
 Args    : none
 Comments: You don't really need this, 
           it is called automatically when
           the object goes out of scope.

=cut

    sub DESTROY {
        my $self = shift;
        foreach( keys %{ $fields } ) {
            delete $fields->{$_}->[$$self];
        }
        Bio::Phylo::Util::IDPool->_reclaim($self);
        return 1;
    }

=begin comment

 Type    : Internal method
 Title   : _check_cache
 Usage   : $node->_check_cache;
 Function: Retrieves intermediate calculation results.
 Returns : SCALAR
 Args    :

=end comment

=cut

    sub _check_cache {
        my $self = shift;
        my @caller = caller(1);
        if ( exists $cache[$$self]->{$caller[3]} ) {
            return 1, $cache[$$self]->{$caller[3]};
        }
    }

=begin comment

 Type    : Internal method
 Title   : _store_cache
 Usage   : $node->_store_cache($value);
 Function: Stores intermediate calculation results.
 Returns : VOID
 Args    :

=end comment

=cut

    sub _store_cache {
        my ( $self, $result ) = @_;
        my @caller = caller(1);
        $cache[$$self]->{$caller[3]} = $result;
    }

=begin comment

 Type    : Internal method
 Title   : _flush_cache
 Usage   : $node->_flush_cache;
 Function: Stores intermediate calculation results.
 Returns : VOID
 Args    :

=end comment

=cut

    sub _flush_cache {
        my $self = shift;
        $cache[$$self] = {};
    }

=begin comment

 Type    : Internal method
 Title   : _get_container
 Usage   : $phylo->_get_container;
 Function: Retrieves the object that contains the invocant (e.g. for a node,
           returns the tree it is in).
 Returns : Bio::Phylo::* object
 Args    : None

=end comment

=cut

    sub _get_container {
        my $self = shift;
        return $container[$$self];
    }
    
=begin comment

 Type    : Internal method
 Title   : _set_container
 Usage   : $phylo->_set_container($obj);
 Function: Creates a reference from the invocant to the object that contains 
           it (e.g. for a node, creates a reference to the tree it is in).
 Returns : Bio::Phylo::* object
 Args    : A Bio::Phylo::Listable object

=end comment

=cut

    sub _set_container {
        my ( $self, $container ) = @_;
        if ( blessed $container ) {
            if ( $container->can('_type') && $self->can('_container') ) {
                if ( $container->_type == $self->_container ) {
                    if ( $container->contains($self) ) {
                        $container[$$self] = $container;
                        weaken( $container[$$self] );
                        return $self;
                    }
                    else {
                        Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                            error => "\"$self\" not in \"$container\"",
                        );
                    }
                }
                else {
                    Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                        error => "\"$container\" cannot contain \"$self\"",
                    );
                }
            }
            else {
                Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
                    error => "Invalid objects",
                );            
            }
        }
        else {
            Bio::Phylo::Util::Exceptions::BadArgs->throw(
                error => "Argument not an object",
            );
        }
    }
    
=begin comment

 Type    : Internal method
 Title   : _set_super
 Usage   : $phylo->_set_super;
 Function: Creates a reference to the invocant in the static $super hashref
 Returns : Bio::Phylo::* object
 Args    : None;

=end comment

=cut

    sub _set_super {
        my $self = shift;
        $super->{$self} = $self;
        weaken( $super->{$self} );
        return $self;
    }

=begin comment

 Type    : Internal method
 Title   : _get_super
 Usage   : Bio::Phylo->_get_super;
 Function: Returns all references in the static $super hashref
 Returns : Bio::Phylo::* objects in an array ref
 Args    : None;

=end comment

=cut

    sub _get_super {
        my @tmp = values %{ $super };
        return \@tmp;
    }

=begin comment

 Type    : Internal method
 Title   : _del_from_super;
 Usage   : $phylo->_del_from_super;
 Function: Deletes invocant from $super hashref
 Returns : VOID
 Args    : None;

=end comment

=cut

    sub _del_from_super {
        my $self = shift;
        delete $super->{$self};
        return;
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

$Id: Phylo.pm,v 1.29 2006/04/12 22:38:22 rvosa Exp $

=head1 AUTHOR

Rutger Vos,

=over

=item email: L<mailto://rvosa@sfu.ca>

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

}

1;
