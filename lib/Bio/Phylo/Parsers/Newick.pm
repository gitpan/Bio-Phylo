# $Id: Newick.pm 3291 2007-03-17 11:34:46Z rvosa $
package Bio::Phylo::Parsers::Newick;
use strict;
use Bio::Phylo::IO;
use Bio::Phylo;
use vars '@ISA';
@ISA=qw(Bio::Phylo::IO);

my $logger = 'Bio::Phylo';

# One line so MakeMaker sees it.
use Bio::Phylo; our $VERSION = $Bio::Phylo::VERSION;
*_from_handle = \&_from_both;
*_from_string = \&_from_both;

=head1 NAME

Bio::Phylo::Parsers::Newick - Parses newick trees. No serviceable parts inside.

=head1 DESCRIPTION

This module parses tree descriptions in parenthetical
format. It is called by the L<Bio::Phylo::IO> facade,
don't call it directly.

=begin comment

 Type    : Constructor
 Title   : _new
 Usage   : my $newick = Bio::Phylo::Parsers::Newick->_new;
 Function: Initializes a Bio::Phylo::Parsers::Newick object.
 Returns : A Bio::Phylo::Parsers::Newick object.
 Args    : none.

=end comment

=cut

sub _new {
    my $class = $_[0];
    $logger->info("instantiating newick parser");
    my $self  = {};
    bless( $self, $class );
    return $self;
}

=begin comment

 Type    : Wrapper
 Title   : _from_both(%options)
 Usage   : $newick->_from_both(%options);
 Function: Extracts trees from file, sends strings to _parse_string()
 Returns : Bio::Phylo::Forest
 Args    : -handle => (\*FH) or -string => (scalar).
 Comments:

=end comment

=cut

sub _from_both {
    my $self  = shift;
    my %args  = @_;
    
    # turn string into pseudo-handle
    if ( $args{'-string'} ) {
        require IO::String;
        $args{'-handle'} = IO::String->new( $args{'-string'} );
        $logger->debug("creating handle from string");
    }
    
    # just concatenate
    my $string;
    while ( my $line = $args{-handle}->getline ) {
        chomp( $line );
        $string .= $line;
    }
    $logger->debug("concatenated lines");                   
    
    # remove comments, split on trees
    my @trees = $self->_split( $string );
    
    # lazy loading, we only want the forest *now*
    require Bio::Phylo::Forest;
    my $forest = Bio::Phylo::Forest->new;    
    
    # parse trees
    for my $tree ( @trees ) {
        $forest->insert( $self->_parse_string( $tree ) );
    }
    
    # adding labels to untagged nodes
    if ( $args{'-label'} ) {
        for my $tree ( @{ $forest->get_entities } ) {
            my $i = 1;
            for my $node ( @{ $tree->get_entities } ) {
                if ( not $node->get_name ) {
                    $node->set_name( 'n' . $i++ );
                }
            }
        }
    }

    # done
    return $forest;
}

=begin comment

 Type    : Parser
 Title   : _split($string)
 Usage   : my @strings = $newick->_split($string);
 Function: Creates an array of (decommented) tree descriptions
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : $string = concatenated tree descriptions

=end comment

=cut

sub _split {
    my ( $self, $string ) = @_;
    my ( $QUOTED, $COMMENTED ) = ( 0, 0 );
    my $decommented = '';
    my @trees;
    TOKEN: for my $i ( 0 .. length( $string ) ) {
        if ( ! $QUOTED && ! $COMMENTED && substr($string,$i,1) eq "'" ) {
            $QUOTED++;
        }
        elsif ( ! $QUOTED && ! $COMMENTED && substr($string,$i,1) eq "[" ) {
            $COMMENTED++;
            next TOKEN;
        }
        elsif ( ! $QUOTED && $COMMENTED && substr($string,$i,1) eq "]" ) {
            $COMMENTED--;
            next TOKEN;
        }
        elsif ( $QUOTED && ! $COMMENTED && substr($string,$i,1) eq "'" && substr($string,$i,2) ne "''" ) {
            $QUOTED--;
        }
        $decommented .= substr($string,$i,1) unless $COMMENTED;
        if ( ! $QUOTED && ! $COMMENTED && substr($string,$i,1) eq ';' ) {
            push @trees, $decommented;
            $decommented = '';
        }
    }
    $logger->debug("removed comments, split on tree descriptions");
    return @trees;
}

=begin comment

 Type    : Parser
 Title   : _parse_string($string)
 Usage   : my $tree = $newick->_parse_string($string);
 Function: Creates a populated Bio::Phylo::Forest::Tree object from a newick
           string.
 Returns : A Bio::Phylo::Forest::Tree object.
 Args    : $string = a newick tree description

=end comment

=cut

sub _parse_string {
    my ( $self, $string ) = @_;
    $logger->info("going to parse tree string '$string'");
    require Bio::Phylo::Forest::Tree;
    require Bio::Phylo::Forest::Node;
    my $tree = Bio::Phylo::Forest::Tree->new;
    my $remainder = $string;
    my $token;
    my @tokens;
    while ( ( $token, $remainder ) = $self->_next_token( $remainder ) ) {
        last if ( ! defined $token || ! defined $remainder );
        $logger->info("fetched token '$token'");
        push @tokens, $token;
    }
    my $i;
    for ( $i = $#tokens; $i >= 0; $i-- ) {
        last if $tokens[$i] eq ';';
    }
    my $root = Bio::Phylo::Forest::Node->new;
    $tree->insert( $root );
    $self->_parse_node_data( $root, @tokens[ 0 .. ( $i - 1 ) ] );
    $self->_parse_clade( $tree, $root, @tokens[ 0 .. ( $i - 1 ) ] );
    return $tree;
}
sub _parse_clade {
    my ( $self, $tree, $root, @tokens ) = @_;
    $logger->info("recursively parsing clade '@tokens'");
    my ( @clade, $depth, @remainder );
    TOKEN: for my $i ( 0 .. $#tokens ) {
        if ( $tokens[$i] eq '(' ) {
            if ( not defined $depth ) {
                $depth = 1;
                next TOKEN;
            }
            else {
                $depth++;
            }
        }
        elsif ( $tokens[$i] eq ',' && $depth == 1 ) {
            my $node = Bio::Phylo::Forest::Node->new;
            $root->set_child( $node );
            $tree->insert( $node );
            $self->_parse_node_data( $node, @clade );
            $self->_parse_clade( $tree, $node, @clade );
            @clade = ();
            next TOKEN;
        }
        elsif ( $tokens[$i] eq ')' ) {
            $depth--;
            if ( $depth == 0 ) {
                @remainder = @tokens[ ( $i + 1 ) .. $#tokens ];
                my $node = Bio::Phylo::Forest::Node->new;
                $root->set_child( $node );
                $tree->insert( $node );
                $self->_parse_node_data( $node, @clade );
                $self->_parse_clade( $tree, $node, @clade );
                last TOKEN;
            }
        }
        push @clade, $tokens[$i];
    }
}
sub _parse_node_data {
    my ( $self, $node, @clade ) = @_;
    $logger->info("parsing name and branch length for node");
    my @tail;
    PARSE_TAIL: for ( my $i = $#clade; $i >= 0; $i-- ) {
        if ( $clade[$i] eq ')' ) {
            @tail = @clade[ ( $i + 1 ) .. $#clade ];
            last PARSE_TAIL;
        }
        elsif ( $i == 0 ) {
            @tail = @clade;
        }
    }
    # name only
    if ( scalar @tail == 1 ) {
        $node->set_name( $tail[0] );
    }
    elsif ( scalar @tail == 2 ) {
        $node->set_branch_length( $tail[-1] );
    }
    elsif ( scalar @tail == 3 ) {
        $node->set_name( $tail[0] );
        $node->set_branch_length( $tail[-1] );
    }
}
sub _next_token {
    my ( $self, $string ) = @_;
    $logger->info("tokenizing string '$string'");
    my $QUOTED = 0;
    my $token = '';
    my $TOKEN_DELIMITER = qr/[():,;]/;
    TOKEN: for my $i ( 0 .. length( $string ) ) {
        $token .= substr($string,$i,1);
        $logger->info("growing token: '$token'");
        if ( ! $QUOTED && $token =~ $TOKEN_DELIMITER ) {
            my $length = length( $token );
            if ( $length == 1 ) {
                $logger->info("single char token: '$token'");
                return $token, substr($string,($i+1));
            }
            else {
                $logger->info(sprintf("range token: %s", substr($token,0,$length-1)));
                return substr($token,0,$length-1),substr($token,$length-1,1).substr($string,($i+1));
            }
        }
        if ( ! $QUOTED && substr($string,$i,1) eq "'" ) {
            $QUOTED++;
        }
        elsif ( $QUOTED && substr($string,$i,1) eq "'" && substr($string,$i,2) ne "''" ) {
            $QUOTED--;
        }        
    }
}

=begin comment

 Type    : Internal method.
 Title   : _nodelabels($string)
 Usage   : my $labelled = $newick->_nodelabels($string);
 Function: Returns a newick string with labelled nodes
 Returns : SCALAR = a labelled newick tree description
 Args    : $string = a newick tree description
 Notes   : Node labels are now optional, determined by the -labels => 1 switch.

=end comment

=cut

sub _nodelabels {
    my ( $self, $string ) = @_;
    my ( $x, @x );
    while ( $string =~ /\)[:|,|;|\)]/o ) {
        foreach ( split( /[:|,|;|\)]/o, $string ) ) {
            if (/n([0-9]+)/) {
                push( @x, $1 );
            }
        }
        @x = sort { $a <=> $b } @x;
        $x = $x[-1];
        $string =~ s/(\))([:|,|;|\)])/$1.'n'.++$x.$2/ose;
    }
    return $string;
}

=begin comment

 Type    : Internal method.
 Title   : _parse
 Usage   : my $labelled = $newick->_nodelabels($string);
 Function: Recursive newick parser function
 Returns : (Modifies caller's tree object)
 Args    : $substr (a newick subtree), $tree (a tree object),
           $parent (root of subtree)
 Notes   :

=end comment

=cut

sub _parse {
    my ( $substr, $tree, $parent ) = @_;
    my @clades;
    my ( $level, $token ) = ( 0, '' );
    for my $i ( 0 .. length($substr) ) {
        my $c = substr( $substr, $i, 1 );
        $level++ if $c eq '(';
        $level-- if $c eq ')';
        if ( !$level && $c eq ',' || $i == length($substr) ) {
            my ( $node, $clade ) = &_token_handler($token);
            if ($clade) {
                push( @clades, [ $node, $clade ] );
            }
            else {
                push( @clades, [$node] );
            }
            $token = '';
        }
        else {
            $token .= $c;
        }
    }
    $parent->set_first_daughter( $clades[0][0] )
      ->set_last_daughter( $clades[-1][0] );
    $clades[0][0]->set_parent($parent);
    $tree->insert( $clades[0][0] );
    &_parse( $clades[0][1], $tree, $clades[0][0] ) if $clades[0][1];
    for my $i ( 1 .. $#clades ) {
        $clades[$i][0]->set_parent($parent)
          ->set_previous_sister(
            $clades[ $i - 1 ][0]->set_next_sister( $clades[$i][0] ) );
        $tree->insert( $clades[$i][0] );
        &_parse( $clades[$i][1], $tree, $clades[$i][0] ) if $clades[$i][1];
    }
}

=begin comment

 Type    : Internal subroutine.
 Title   : _token_handler
 Usage   : my ( $node, $substring ) = &_token_handler($string);
 Function: Tokenizes current substring, instantiates node objects.
 Returns : L<Bio::Phylo::Forest::Node>, SCALAR substring
 Args    : $token (a newick subtree)
 Notes   :

=end comment

=cut

sub _token_handler {
    my $token = shift;
    my ( $node, $name, $clade );
    if ( $token =~ m/^\((.*)\)([^()]*)$/o ) {
        ( $clade, $name ) = ( $1, $2 );
    }
    else {
        $name = $token;
    }
    if ( $name =~ m/^([^:()]*?)\s*:\s*(.*)$/o ) {
        $node = Bio::Phylo::Forest::Node->new(
            '-name'          => $1,
            '-branch_length' => $2,
        );
    }
    else {
        $node = Bio::Phylo::Forest::Node->new( '-name' => $name, );
    }
    return $node, $clade;
}

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The newick parser is called by the L<Bio::Phylo::IO> object.
Look there to learn how to parse newick strings.

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

$Id: Newick.pm 3291 2007-03-17 11:34:46Z rvosa $

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
