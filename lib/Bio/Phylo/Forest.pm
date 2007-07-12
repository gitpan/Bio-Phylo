# $Id: Forest.pm 4193 2007-07-11 20:26:06Z rvosa $
package Bio::Phylo::Forest;
use strict;
use warnings FATAL => 'all';
use Bio::Phylo;
use Bio::Phylo::Listable;
use Bio::Phylo::Taxa::TaxaLinker;
use Bio::Phylo::Taxa::Taxon;
use Bio::Phylo::Util::CONSTANT qw(_NONE_ _FOREST_);
use vars qw($VERSION @ISA);

# set version based on svn rev
my $version = $Bio::Phylo::VERSION;
my $rev = '$Id: Forest.pm 4193 2007-07-11 20:26:06Z rvosa $';
$rev =~ s/^[^\d]+(\d+)\b.*$/$1/;
$version =~ s/_.+$/_$rev/;
$VERSION = $version;

# classic @ISA manipulation, not using 'base'
@ISA = qw(Bio::Phylo::Listable Bio::Phylo::Taxa::TaxaLinker);

{

=head1 NAME

Bio::Phylo::Forest - The forest object, a set of phylogenetic trees.

=head1 SYNOPSIS

 use Bio::Phylo::Forest;
 use Bio::Phylo::Forest::Tree;
 
 my $forest = Bio::Phylo::Forest->new;
 my $tree = Bio::Phylo::Forest::Tree->new;
 $forest->insert($tree);

=head1 DESCRIPTION

The Bio::Phylo::Forest object models a set of trees. The object subclasses the
L<Bio::Phylo::Listable> object, so look there for more methods available to
forest objects.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

Forest constructor.

 Type    : Constructor
 Title   : new
 Usage   : my $trees = Bio::Phylo::Forest->new;
 Function: Instantiates a Bio::Phylo::Forest object.
 Returns : A Bio::Phylo::Forest object.
 Args    : None required, though see the superclass
           Bio::Phylo::Listable from which this
           object inherits.

=cut

    sub new {
        # could be child class
        my $class = shift;
        
        # notify user
        $class->info("constructor called for '$class'");
        
        # recurse up inheritance tree, get ID
        my $self = $class->SUPER::new( @_ );
        
        # local fields would be set here
        
        return $self;
    }

=back

=head1 METHODS

=over

=item check_taxa()

Validates taxon links of nodes in invocant's trees.

 Type    : Method
 Title   : check_taxa
 Usage   : $trees->check_taxa;
 Function: Validates the taxon links of the
           nodes of the trees in $trees
 Returns : A validated Bio::Phylo::Forest object.
 Args    : None

=cut

    sub check_taxa {
        my $self = shift;
        
        # is linked
        if ( my $taxa = $self->get_taxa ) {
            my %tips = map { $_->get_internal_name => $_ } map { @{ $_->get_terminals } } @{ $self->get_entities };
            my %taxa = map { $_->get_internal_name => $_ } @{ $taxa->get_entities };
			for my $tip ( keys %tips ) {
				$self->debug( "linking tip $tip" );
				if ( not exists $taxa{$tip} ) {
					$self->debug( "no taxon object for $tip yet, instantiating" );
					$taxa->insert( $taxa{$tip} = Bio::Phylo::Taxa::Taxon->new( '-name' => $tip ) );					
				}
				$tips{$tip}->set_taxon( $taxa{$tip} );
			}
        }
        
        # not linked
        else {
            for my $tree ( @{ $self->get_entities } ) {
                for my $node ( @{ $tree->get_entities } ) {
                    $node->set_taxon();
                }
            }
        }
        return $self;
    }

=item to_nexus()

Serializer to nexus format.

 Type    : Format convertor
 Title   : to_nexus
 Usage   : my $data_block = $matrix->to_nexus;
 Function: Converts matrix object into a nexus data block.
 Returns : Nexus data block (SCALAR).
 Args    : Trees can be formatted using the same arguments as those
 		   passed to Bio::Phylo::Unparsers::Newick. In addition, you
 		   can provide: 
 		   
 		   # as per mesquite's inter-block linking system (default is false):
 		   -links => 1 (to create a TITLE token, and a LINK token, if applicable)
 		   
 		   # rooting is determined based on basal trichotomy. "token" means 'TREE' or 'UTREE'
 		   # is used, "comment" means [&R] or [&U] is used, "nhx" means [%unrooted=on] or
 		   # [%unrooted=off] if used, default is "comment"
 		   -rooting => one of (token|comment|nhx)
 		   
 		   # to map taxon names to indices (default is false)
 		   -make_translate => 1 (autogenerate translation table, overrides -translate => {})
 Comments:

=cut

	sub to_nexus {
		my $self = shift;
		my %args = ( '-rooting' => 'comment', @_ );
		my %translate;
		my $nexus;
		
		# make translation table
		if ( $args{'-make_translate'} ) {			
			my $i = 0;
			for my $tree ( @{ $self->get_entities } ) {
				for my $node ( @{ $tree->get_terminals } ) {
					my $name;
					if ( not $args{'-tipnames'} ) {		
						$name = $node->get_name;
					}
					elsif ( $args{'-tipnames'} =~ /^internal$/i ) {
						$name = $node->get_internal_name;
					}
					elsif ( $args{'-tipnames'} =~ /^taxon/i and $node->get_taxon ) {
						if ( $args{'-tipnames'} =~ /^taxon_internal$/i ) {
							$name = $node->get_taxon->get_internal_name;
						}
						elsif ( $args{'-tipnames'} =~ /^taxon$/i ) {
							$name = $node->get_taxon->get_name;
						}
					}
					else {
						$name = $node->get_generic( $args{'-tipnames'} );
					}
					$translate{$name} = ( 1 + $i++ ) if not exists $translate{$name};
				}
			}			
			$args{'-translate'} = \%translate;
		}	
		
		# create header
		$nexus  = "BEGIN TREES;\n";
		$nexus .= "[! Trees block written by " . ref($self) . " " . $self->VERSION . " on " . localtime() . " ]\n";
		if ( $args{'-links'} ) {
			delete $args{'-links'};
			$nexus .= "\tTITLE " . $self->get_internal_name . ";\n";
			if ( my $taxa = $self->get_taxa ) {
				$nexus .= "\tLINK TAXA=" . $taxa->get_internal_name . ";\n"
			}
		}
				
		# stringify translate table
		if ( $args{'-make_translate'} ) {
			delete $args{'-make_translate'};
			$nexus .= "\tTRANSLATE\n";
			my @translate;
			for ( keys %translate ) { $translate[$translate{$_}-1] = $_ }
			for my $i ( 0 .. $#translate ) {
				$nexus .= "\t\t" . ( $i + 1 ) . " " . $translate[$i];
				if ( $i == $#translate ) {
					$nexus .= ";\n";
				}
				else {
					$nexus .= ",\n";
				}
			}	
		}
		
		# stringify trees
		for my $tree ( @{ $self->get_entities } ) {
			if ( $tree->is_rooted ) {
				if ( $args{'-rooting'} =~ /^token$/i ) {
					$nexus .= "\tTREE " . $tree->get_internal_name . ' = ' . $tree->to_newick(%args) . "\n"; 
				}
				elsif ( $args{'-rooting'} =~ /^comment$/i ) {
					$nexus .= "\tTREE " . $tree->get_internal_name . ' = [&R] ' . $tree->to_newick(%args) . "\n"; 
				}
				elsif ( $args{'-rooting'} =~ /^nhx/i ) {
					$tree->get_root->set_generic( 'unrooted' => 'off' );
					if ( $args{'-nhxkeys'} ) {
						push @{ $args{'-nhxkeys'} }, 'unrooted';
					}
					else {
						$args{'-nhxkeys'} = [ 'unrooted' ];
					}
					$nexus .= "\tTREE " . $tree->get_internal_name . ' = ' . $tree->to_newick(%args) . "\n"; 
				}				
			}
			else {
				if ( $args{'-rooting'} =~ /^token$/i ) {
					$nexus .= "\tUTREE " . $tree->get_internal_name . ' = ' . $tree->to_newick(%args) . "\n"; 
				}
				elsif ( $args{'-rooting'} =~ /^comment$/i ) {
					$nexus .= "\tTREE " . $tree->get_internal_name . ' = [&U] ' . $tree->to_newick(%args) . "\n"; 
				}
				elsif ( $args{'-rooting'} =~ /^nhx/i ) {
					$tree->get_root->set_generic( 'unrooted' => 'on' );
					if ( $args{'-nhxkeys'} ) {
						push @{ $args{'-nhxkeys'} }, 'unrooted';
					}
					else {
						$args{'-nhxkeys'} = [ 'unrooted' ];
					}
					$nexus .= "\tTREE " . $tree->get_internal_name . ' = ' . $tree->to_newick(%args) . "\n"; 
				}				
			}			
		}
		
		# done!
		$nexus .= "END;\n";
		return $nexus;
	}

=begin comment

 Type    : Internal method
 Title   : _cleanup
 Usage   : $trees->_cleanup;
 Function: Called during object destruction, for cleanup of instance data
 Returns : 
 Args    :

=end comment

=cut

    sub _cleanup {
        my $self = shift;
        $self->info("cleaning up '$self'");
    }

=begin comment

 Type    : Internal method
 Title   : _container
 Usage   : $trees->_container;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _container { _NONE_ }

=begin comment

 Type    : Internal method
 Title   : _type
 Usage   : $trees->_type;
 Function:
 Returns : CONSTANT
 Args    :

=end comment

=cut

    sub _type { _FOREST_ }

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Listable>

The forest object inherits from the L<Bio::Phylo::Listable>
object. The methods defined therein are applicable to forest objects.

=item L<Bio::Phylo::Taxa::TaxaLinker>

The forest object inherits from the L<Bio::Phylo::Taxa::TaxaLinker>
object. The methods defined therein are applicable to forest objects.

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

$Id: Forest.pm 4193 2007-07-11 20:26:06Z rvosa $

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

}
1;
