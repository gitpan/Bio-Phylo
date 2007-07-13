# $Id: Phylo.pm 4204 2007-07-13 05:40:14Z rvosa $
package Bio::Phylo;
use strict;
use warnings FATAL => 'all';
use vars qw($VERSION $VERBOSE $COMPAT);

# default value for verbosity: 0 only logs fatal messages,
# 1=error, 2=warn, 3=info, 4=debug
$VERBOSE = 0;

# Because we use a roll-your-own looks_like_number from
# Bio::Phylo::Util::CONSTANT, here we don't have to worry
# about older S::U versions...
use Scalar::Util qw(weaken blessed);

#... instead, Bio::Phylo::Util::CONSTANT can worry about it
# in one location
use Bio::Phylo::Util::CONSTANT qw(looks_like_number);
use Bio::Phylo::Util::IDPool;
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Mediators::TaxaMediator;

# Include the revision number from CIPRES subversion in $VERSION
my $rev = '$Id: Phylo.pm 4204 2007-07-13 05:40:14Z rvosa $';
$rev =~ s/^[^\d]+(\d+)\b.*$/$1/;
$VERSION = "0.17_RC4";
$VERSION .= "_$rev";

{

	# The following allows for semantics like:
	# 'use Bio::Phylo verbose => 1;' to increase verbosity,
	sub import {
		my $class = shift;
		if (@_) {
			my %opt;
			eval { %opt = @_ };
			if ($@) {
				Bio::Phylo::Util::Exceptions::OddHash->throw( 'error' => $@ );
			}
			else {
				while ( my ( $key, $value ) = each %opt ) {
					if ( $key =~ qr/^VERBOSE$/i ) {
						if ( $value > 4 || $value < 0 ) {
							Bio::Phylo::Util::Exceptions::OutOfBounds->throw(
								'error' =>
								  "verbosity must be >= 0 && <= 4 inclusive", );
						}
						else {
							$VERBOSE = $value;
						}
					}
					elsif ( $key =~ qr/^COMPAT$/i ) {
						$COMPAT = ucfirst( lc($value) );
					}
					else {
						Bio::Phylo::Util::Exceptions::BadArgs->throw( 'error' =>
							  "'$key' is not a valid argument for import", );
					}
				}
			}
		}
		return 1;
	}

	# inside out class arrays
	my %name;
	my %desc;
	my %score;
	my %generic;
	my %cache;
	my %container;

	# @fields array handy for object destruction
	my @fields = ( \%name, \%desc, \%score, \%generic, \%cache, \%container, );

=head1 NAME

Bio::Phylo - Phylogenetic analysis using perl.

=head1 SYNOPSIS

 # verbosity goes from 0, only fatal messages, to 4: everything from
 # fatal -> error -> warning -> info -> debug (which is a lot)
 use Bio::Phylo verbose => 1;

=head1 DESCRIPTION

This is the base class for the Bio::Phylo OO package. In this file, methods
are defined that are performed by other objects in the Bio::Phylo release,
i.e. objects that inherit from this class.

For general information on how to use Bio::Phylo, consult the manual
(L<Bio::Phylo::Manual>); for information on using Bio::Phylo in combination with
Bioperl (L<http://www.bioperl.org>) and Bio::Nexus
(L<http://search.cpan.org/~tjhladish/Bio-NEXUS>), consult the object
compatibility document (L<Bio::ObjectCompat>).

If you come here because you are trying to debug a problem you run into in
using Bio::Phylo, you may be interested in the "exceptions" system as discussed
in L<Bio::Phylo::Util::Exceptions>. In addition, you may find the logging system
that is discussed in this base class of use.

Documentation on the various scripts included in this release is embedded in
their respective source files, which, like all L<perldoc> can be viewed in
various ways using the nroff-like formatter C<perldoc> F<<filename>> or using
one of the many pod2* convertors such as pod2text, pod2html, pod2latex and so
on. In addition, the scripts generally have a B<-h> or B<--help> or B<-?>
option.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

The Bio::Phylo root object itself, and thus its constructor, is rarely, if ever,
used directly. Rather, all other objects in this package inherit its methods,
and call its constructor internally. The arguments shown here can thus also be
passed to any of the child classes' constructors, which will pass them on up the 
inheritance tree. Generally, constructors in Bio::Phylo subclasses can process
as arguments all methods that have set_* in their names. The arguments are named
for the methods, but "set_" has been replaced with a dash "-", e.g. the method
"set_name" becomes the argument "-name" in the constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $phylo = Bio::Phylo->new;
 Function: Instantiates Bio::Phylo object
 Returns : a Bio::Phylo object
 Args    : -name    => (object name)
           -desc    => (object description)
           -score   => (numerical score)
           -generic => (generic key/value pair, hash ref)

=cut

	sub new {

		# class could be a child class
		my $class = shift;

		# notify user
		$class->info("constructor called for '$class'");

		# happens only once because root class is visited from every constructor
		my $self = Bio::Phylo::Util::IDPool->_initialize();

		# bless in child class, not __PACKAGE__
		bless $self, $class;

		# processing arguments
		if (@_) {

			# notify user
			$self->debug("root constructor called with args");

			# something's wrong
			if ( ( scalar(@_) % 2 ) != 0 ) {
				Bio::Phylo::Util::Exceptions::OddHash->throw(
					'error' => "No even key/value pairs in constructor '@_'" );
			}

			# looks like an ok hash
			else {

				# notify user
				$self->debug("going to process constructor args");

				# process all arguments
				while (@_) {
					my $key   = shift @_;
					my $value = shift @_;

					# notify user
					$self->debug("processing arg '$key'");

					# don't access data structures directly, call mutators
					# in child classes or __PACKAGE__
					my $mutator = $key;
					$mutator =~ s/^-/set_/;

					# backward compat fixes:
					$mutator =~ s/^set_pos$/set_position/;
					$mutator =~ s/^set_matrix$/set_raw/;

					$self->$mutator($value);
				}
			}
		}

		# register with mediator
		Bio::Phylo::Mediators::TaxaMediator->register($self);

		return $self;
	}

=back

=head2 MUTATORS

=over

=item set_name()

Sets invocant name.

 Type    : Mutator
 Title   : set_name
 Usage   : $obj->set_name($name);
 Function: Assigns an object's name.
 Returns : Modified object.
 Args    : Argument must be a string, will be single 
           quoted if it contains [;|,|:\(|\)] 
           or spaces. Preceding and trailing spaces
           will be removed.

=cut

	sub set_name {
		my ( $self, $name ) = @_;

		# strip spaces
		$name =~ s/^\s*(.*?)\s*$/$1/;

		# check for bad characters
		if ( $name =~ m/(?:;|,|:|\(|\)|\s)/ ) {

			# had bad characters, but in quotes
			if ( $name =~ m/^(['"])/ && $name =~ m/$1$/ ) {
				$self->info("$name had bad characters, but was quoted");
			}

			# had unquoted bad characters
			else {
				Bio::Phylo::Util::Exceptions::BadString->throw(
					'error' => "$self '$name' has unquoted bad characters" );
			}
		}

		# notify user
		$self->info("setting name '$name'");

		$name{ $self->get_id } = $name;
		return $self;
	}

=item set_desc()

Sets invocant description.

 Type    : Mutator
 Title   : set_desc
 Usage   : $obj->set_desc($desc);
 Function: Assigns an object's description.
 Returns : Modified object.
 Args    : Argument must be a string.

=cut

	sub set_desc {
		my ( $self, $desc ) = @_;

		# notify user
		$self->info("setting description '$desc'");

		$desc{ $self->get_id } = $desc;
		return $self;
	}

=item set_score()

Sets invocant score.

 Type    : Mutator
 Title   : set_score
 Usage   : $obj->set_score($score);
 Function: Assigns an object's numerical score.
 Returns : Modified object.
 Args    : Argument must be any of
           perl's number formats, or undefined
           to reset score.

=cut

	sub set_score {
		my ( $self, $score ) = @_;

		# $score must be a number (or undefined)
		if ( defined $score
			&& !Bio::Phylo::Util::CONSTANT::looks_like_number($score) )
		{
			Bio::Phylo::Util::Exceptions::BadNumber->throw(
				'error' => "score \"$score\" is a bad number" );
		}

		# notify user
		$self->info("setting score '$score'");

		# this resets the score of $score was undefined
		$score{ $self->get_id } = $score;

		return $self;
	}

=item set_generic()

Sets generic key/value pair(s).

 Type    : Mutator
 Title   : set_generic
 Usage   : $obj->set_generic( %generic );
 Function: Assigns generic key/value pairs to the invocant.
 Returns : Modified object.
 Args    : Valid arguments constitute:

           * key/value pairs, for example:
             $obj->set_generic( '-lnl' => 0.87565 );

           * or a hash ref, for example:
             $obj->set_generic( { '-lnl' => 0.87565 } );

           * or nothing, to reset the stored hash, e.g.
                $obj->set_generic( );

=cut

	sub set_generic {
		my $self = shift;

		# retrieve id just once, don't call $self->get_id in loops, inefficient
		my $id = $self->get_id;

	 # this initializes the hash if it didn't exist yet, or resets it if no args
		if ( !defined $generic{$id} || !@_ ) {
			$generic{$id} = {};
		}

		# have args
		if (@_) {
			my %args;

			# have a single arg, a hash ref
			if ( scalar @_ == 1 && ref $_[0] eq 'HASH' ) {
				%args = %{ $_[0] };
			}

			# multiple args, hopefully even size key/value pairs
			else {
				eval { %args = @_ };
			}

			# something's wrong, not a hash
			if ($@) {
				Bio::Phylo::Util::Exceptions::OddHash->throw( error => $@ );
			}

			# everything okay.
			else {

				# notify user
				$self->info("setting generic key/value pairs '%args'");

				# fill up the hash
				foreach my $key ( keys %args ) {
					$generic{$id}->{$key} = $args{$key};
				}
			}
		}

		return $self;
	}

=back

=head2 ACCESSORS

=over

=item get_name()

Gets invocant's name.

 Type    : Accessor
 Title   : get_name
 Usage   : my $name = $obj->get_name;
 Function: Returns the object's name.
 Returns : A string
 Args    : None

=cut

	sub get_name {
		my $self = shift;
		return $name{ $self->get_id };
	}

=item get_internal_name()

Gets invocant's 'fallback' name (possibly autogenerated).

 Type    : Accessor
 Title   : get_internal_name
 Usage   : my $name = $obj->get_internal_name;
 Function: Returns the object's name (if none was set, the name
           is a combination of the $obj's class and its UID).
 Returns : A string
 Args    : None

=cut

	sub get_internal_name {
		my $self = shift;
		if ( my $name = $self->get_name ) {
			return $name;
		}
		else {
			my $internal_name = ref $self;
			$internal_name =~ s/.*:://;
			$internal_name .= $self->get_id;
			return $internal_name;
		}
	}

=item get_desc()

Gets invocant description.

 Type    : Accessor
 Title   : get_desc
 Usage   : my $desc = $obj->get_desc;
 Function: Returns the object's description (if any).
 Returns : A string
 Args    : None

=cut

	sub get_desc {
		my $self = shift;
		$self->debug("getting description");
		return $desc{ $self->get_id };
	}

=item get_score()

Gets invocant's score.

 Type    : Accessor
 Title   : get_score
 Usage   : my $score = $obj->get_score;
 Function: Returns the object's numerical score (if any).
 Returns : A number
 Args    : None

=cut

	sub get_score {
		my $self = shift;
		$self->debug("getting score");
		return $score{ $self->get_id };
	}

=item get_generic()

Gets generic hashref or hash value(s).

 Type    : Accessor
 Title   : get_generic
 Usage   : my $value = $obj->get_generic($key);
           or
           my %hash = %{ $obj->get_generic() };
 Function: Returns the object's generic data. If an
           argument is used, it is considered a key
           for which the associated value is returned.
           Without arguments, a reference to the whole
           hash is returned.
 Returns : A string or hash reference.
 Args    : None

=cut

	sub get_generic {
		my ( $self, $key ) = @_;

		# retrieve just once
		my $id = $self->get_id;

		# might not even have a generic hash yet, make one on-the-fly
		if ( not defined $generic{$id} ) {
			$generic{$id} = {};
		}

		# have an argument
		if ( defined $key ) {

			# notify user
			$self->debug("getting value for key '$key'");

			return $generic{$id}->{$key};
		}

		# no argument, wants whole hash
		else {

			# notify user
			$self->debug("retrieving generic hash");

			return $generic{$id};
		}
	}

=item get_id()

Gets invocant's UID.

 Type    : Accessor
 Title   : get_id
 Usage   : my $id = $obj->get_id;
 Function: Returns the object's unique ID
 Returns : INT
 Args    : None

=cut

	sub get_id {

		# self can be two things: either a blessed scalar, or an array tied
		# to that blessed scalar (in case we call ->get_id on a listable object)
		# in the latter case we first have to retrieve the tie'd object, and
		# then dereference that for the id
		my $self = shift;

		# $self was a 'normal' object, not tied
		if ( UNIVERSAL::isa( $self, 'SCALAR' ) ) {
			return $$self;
		}

		# for tied Bio::Phylo::Listable arrays
		elsif ( UNIVERSAL::isa( $self, 'ARRAY' ) ) {

			# get tied scalar from array
			my $tied = tied @{$self};
			if ( $tied and UNIVERSAL::isa( $tied, 'SCALAR' ) ) {
				return $$tied;
			}

			# this might happen if the tied object is destroyed before the array
			elsif ( not $tied ) {
				$self->warn("no tie'd object for '$self' - are we destroying?");
			}
		}

		# so far never seen this one...
		else {
			$self->error("object neither array nor scalar");
		}
	}

=back

=head2 PACKAGE METHODS

=over

=item get()

Attempts to execute argument string as method on invocant.

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

			# notify user
			$self->debug("retrieving return value for method '$var'");

			return $self->$var;
		}
		else {
			my $ref = ref $self;
			Bio::Phylo::Util::Exceptions::UnknownMethod->throw(
				'error' => "sorry, a '$ref' can't '$var'", );
		}
	}

=item debug()

Prints argument debugging message, depending on verbosity.

 Type    : logging method
 Title   : debug
 Usage   : $object->debug( "debugging message" );
 Function: prints debugging message, depending on verbosity
 Returns : invocant
 Args    : logging message

=cut

	sub debug {
		my ( $self, $msg ) = @_;
		if ( $VERBOSE >= 4 ) {
			my ( $package, $file1up,  $line1up, $subroutine ) = caller(1);
			my ( $pack0up, $filename, $line,    $sub0up )     = caller(0);
			printf( "%s %s [%s, %s] - %s\n",
				'DEBUG', $subroutine, $filename, $line, $msg );
		}
		return $self;
	}

=item info()

Prints argument informational message, depending on verbosity.

 Type    : logging method
 Title   : info
 Usage   : $object->info( "info message" );
 Function: prints info message, depending on verbosity
 Returns : invocant
 Args    : logging message

=cut

	sub info {
		my ( $self, $msg ) = @_;
		if ( $VERBOSE >= 3 ) {
			my ( $package, $file1up,  $line1up, $subroutine ) = caller(1);
			my ( $pack0up, $filename, $line,    $sub0up )     = caller(0);
			printf( "%s %s [%s, %s] - %s\n",
				'INFO', $subroutine, $filename, $line, $msg );
		}
		return $self;
	}

=item warn()

Prints argument warning message, depending on verbosity.

 Type    : logging method
 Title   : warn
 Usage   : $object->warn( "warning message" );
 Function: prints warning message, depending on verbosity
 Returns : invocant
 Args    : logging message

=cut

	sub warn {
		my ( $self, $msg ) = @_;
		if ( $VERBOSE >= 2 ) {
			my ( $package, $file1up,  $line1up, $subroutine ) = caller(1);
			my ( $pack0up, $filename, $line,    $sub0up )     = caller(0);
			printf( "%s %s [%s, %s] - %s\n",
				'WARN', $subroutine, $filename, $line, $msg );
		}
		return $self;
	}

=item error()

Prints argument error message, depending on verbosity.

 Type    : logging method
 Title   : error
 Usage   : $object->error( "error message" );
 Function: prints error message, depending on verbosity
 Returns : invocant
 Args    : logging message

=cut

	sub error {
		my ( $self, $msg ) = @_;
		if ( $VERBOSE >= 1 ) {
			my ( $package, $file1up,  $line1up, $subroutine ) = caller(1);
			my ( $pack0up, $filename, $line,    $sub0up )     = caller(0);
			printf( "%s %s [%s, %s] - %s\n",
				'ERROR', $subroutine, $filename, $line, $msg );
		}
		return $self;
	}

=item fatal()

Prints argument fatal message, depending on verbosity.

 Type    : logging method
 Title   : fatal
 Usage   : $object->fatal( "fatal message" );
 Function: prints fatal message, depending on verbosity
 Returns : invocant
 Args    : logging message

=cut

	sub fatal {
		my ( $self, $msg ) = @_;
		if ( $VERBOSE >= 0 ) {
			my ( $package, $file1up,  $line1up, $subroutine ) = caller(1);
			my ( $pack0up, $filename, $line,    $sub0up )     = caller(0);
			printf( "%s %s [%s, %s] - %s\n",
				'FATAL', $subroutine, $filename, $line, $msg );
		}
		return $self;
	}

=item clone()

Clones invocant.

 Type    : Utility method
 Title   : clone
 Usage   : my $clone = $object->clone;
 Function: Creates a copy of the invocant object.
 Returns : A copy of the invocant.
 Args    : none.
 Comments: Currently not implemented

=cut

	sub clone {
		my $self = shift;
		$self->error("cloning not (yet) implemented!");
		return $self;
	}

=item VERBOSE()

Getter and setter for the verbose level. This comes in five levels: 0 = only
fatal messages (though, when something fatal happens, you'll most likely get
an exception object), 1 = errors (hopefully recoverable), 2 = warnings 
(recoverable), 3 = info (useful diagnostics), 4 = debug (every method call)

 Type    : Accessor
 Title   : VERBOSE()
 Usage   : Bio::Phylo->VERBOSE( -level => $level )
 Function: Sets/gets verbose level
 Returns : Verbose level
 Args    : 0 <= $level && $level <= 4
 Comments:

=cut

	sub VERBOSE {
		my $class = shift;
		if (@_) {
			my %opt;
			eval { %opt = @_ };
			if ($@) {
				Bio::Phylo::Util::Exceptions::OddHash->throw( 'error' => $@ );
			}
			$VERBOSE = $opt{'-level'};

			# notify user
			$class->info("Changed verbosity level to '$VERBOSE'");
		}
		return $VERBOSE;
	}

=item CITATION()

Returns suggested citation.

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
		my $string  = qq{Rutger A. Vos, 2005-2007. $name: };
		$string .= qq{Phylogenetic analysis using Perl, version $version};
		return $string;
	}

=item VERSION()

Gets version number (including revision number).

 Type    : Accessor
 Title   : VERSION
 Usage   : $phylo->VERSION;
 Function: Returns version number
           (including SVN revision number).
 Alias   :
 Returns : SCALAR
 Args    : NONE
 Comments:

=cut

	sub VERSION { $VERSION; }

=back

=head2 DESTRUCTOR

=over

=item DESTROY()

Invocant destructor.

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

		# notify user
		$self->info("destructor called for '$self'");

		# build full @ISA from child to here
		my ( $class, $isa, $seen ) = ( ref($self), [], {} );
		_recurse_isa( $class, $isa, $seen );

		# call *all* _cleanup methods, wouldn't work if simply SUPER::_cleanup
		# given multiple inheritance
		$self->info("going to clean up '$self'");
		{
			no strict 'refs';
			for my $SUPER ( @{$isa} ) {
				my $cleanup = "${SUPER}::_cleanup";
				$self->$cleanup;
			}
			use strict;
		}
		$self->info("done cleaning up '$self'");

		# cleanup from mediator
		Bio::Phylo::Mediators::TaxaMediator->unregister($self);

		# done cleaning up, id can be reclaimed
		Bio::Phylo::Util::IDPool->_reclaim($self);

	}

	sub _recurse_isa {
		my ( $class, $isa, $seen ) = @_;
		if ( not $seen->{$class} ) {
			$seen->{$class} = 1;
			push @{$isa}, $class;
			my @isa;
			{
				no strict 'refs';
				@isa = @{"${class}::ISA"};
				use strict;
			}
			_recurse_isa( $_, $isa, $seen ) for @isa;
		}
	}

	sub _cleanup {
		my $self = shift;
		$self->info("cleaning up '$self'");
		my $id = $self->get_id;

		# cleanup local fields
		for my $field (@fields) {
			delete $field->{$id};
		}
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
		return $container{ $self->get_id };
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
		my $id = $self->get_id;
		if ( blessed $container ) {
			if ( defined $container->_type && defined $self->_container ) {
				if ( $container->_type == $self->_container ) {
					if ( $container->contains($self) ) {
						$container{$id} = $container;
						weaken( $container{$id} );
						return $self;
					}
					else {
						Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
							'error ' => "'$self' not in '$container'", );
					}
				}
				else {
					Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
						'error' => "'$container' cannot contain '$self'", );
				}
			}
			else {
				Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
					'error' => "Invalid objects", );
			}
		}
		else {
			Bio::Phylo::Util::Exceptions::BadArgs->throw(
				'error' => "Argument not an object", );
		}
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

$Id: Phylo.pm 4204 2007-07-13 05:40:14Z rvosa $

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
