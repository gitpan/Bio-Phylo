# $Id: Nexus.pm 4193 2007-07-11 20:26:06Z rvosa $
# Subversion: $Rev: 190 $
package Bio::Phylo::Unparsers::Nexus;
use strict;
use Bio::Phylo::IO;
use Bio::Phylo::Util::CONSTANT qw(:objecttypes);
use Bio::Phylo::Util::Exceptions;
use vars '@ISA';
@ISA=qw(Bio::Phylo::IO);

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;

=head1 NAME

Bio::Phylo::Unparsers::Nexus - Unparses nexus matrices. No serviceable parts
inside.

=head1 DESCRIPTION

This module turns a L<Bio::Phylo::Matrices::Matrix> object into a nexus
formatted matrix. It is called by the L<Bio::Phylo::IO> facade, don't call it
directly. You can pass the following additional arguments to the unparse call:
	
	# an array reference of matrix, forest and taxa objects:
	-phylo => [ $block1, $block2 ]
	
	# the arguments that can be passed for matrix objects, 
	# refer to Bio::Phylo::Matrices::Matrix::to_nexus:
	-matrix_args => {}

	# the arguments that can be passed for forest objects, 
	# refer to Bio::Phylo::Forest::to_nexus:
	-forest_args => {}

	# the arguments that can be passed for taxa objects, 
	# refer to Bio::Phylo::Taxa::to_nexus:
	-taxa_args => {}	
	
	OR:
	
	# for backward compatibility:
	-phylo => $matrix	

=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $nex = Bio::Phylo::Unparsers::Nexus->_new;
 Function: Initializes a Bio::Phylo::Unparsers::Nexus object.
 Returns : A Bio::Phylo::Unparsers::Nexus object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = shift;
    my $self  = {};
    if (@_) {
        my %opts = @_;
        foreach my $key ( keys %opts ) {
            my $localkey = uc $key;
            $localkey =~ s/-//;
            unless ( ref $opts{$key} ) {
                $self->{$localkey} = uc $opts{$key};
            }
            else {
                $self->{$localkey} = $opts{$key};
            }
        }
    }
    bless $self, $class;
    return $self;
}

=begin comment

 Type    : Wrapper
 Title   : _to_string($matrix)
 Usage   : $nexus->_to_string($matrix);
 Function: Stringifies a matrix object into
           a nexus formatted table.
 Alias   :
 Returns : SCALAR
 Args    : Bio::Phylo::Matrices::Matrix;

=end comment

=cut

sub _to_string {
    my $self   = shift;
    my $blocks = $self->{'PHYLO'};
    my $nexus  = "#NEXUS\n";
    my $type;
    eval { $type = $blocks->_type  };

    # array?
    if ( $@ ) {
    	for my $block ( @$blocks ) {
    		eval { $type = $block->_type };
    		my %args;
    		if ( $type == _FOREST_ ) {
    			if ( exists $self->{'FOREST_ARGS'} ) {
    				%args = %{ $self->{'FOREST_ARGS'} };
    			}
    		}
    		elsif ( $type == _TAXA_ ) {
    			if ( exists $self->{'TAXA_ARGS'} ) {
    				%args = %{ $self->{'TAXA_ARGS'} };
    			}    			
    		}
    		elsif ( $type == _MATRIX_ ) {
    			if ( exists $self->{'MATRIX_ARGS'} ) {
    				%args = %{ $self->{'MATRIX_ARGS'} };
    			}     			
    		}
    		elsif ( $@ ) {
		    	Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
    				'error' => "Can't unparse this object: $blocks"
    			);    			
    		}
    		$nexus .= $block->to_nexus(%args);
    	}
    }
    
    # matrix?
    elsif ( defined $type and $type == _MATRIX_ ) {
    	$nexus .= $blocks->to_nexus;
    }
    
    # wrong!
    else {
    	Bio::Phylo::Util::Exceptions::ObjectMismatch->throw(
    		'error' => "Can't unparse this object: $blocks"
    	);
    }
    
    return $nexus;

}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The newick unparser is called by the L<Bio::Phylo::IO> object.
Look there to learn how to unparse newick strings.

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>.

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

$Id: Nexus.pm 4193 2007-07-11 20:26:06Z rvosa $

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
