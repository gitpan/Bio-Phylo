package Bio::Phylo::Adaptor::Bioperl::Matrix;
use Bio::Phylo::Adaptor;
use strict;
use vars '@ISA';
@ISA = qw(Bio::Phylo::Adaptor);

eval { require Bio::Align::AlignI };
if ( not $@ ) {
    push @ISA, 'Bio::Align::AlignI';
}

=head1 NAME

Bio::Phylo::Adaptor::Bioperl::Matrix - Adaptor class for bioperl compatibility

=head1 SYNOPSIS

 use Bio::Phylo::Matrices::Matrix;
 use Bio::Phylo::Adaptor;

 my $matrix = Bio::Phylo::Matrices::Matrix->new;

 $Bio::Phylo::COMPAT = 'Bioperl';

 my $alignment = Bio::Phylo::Adaptor->new($matrix);

 print "compatible!" if $matrix->isa('Bio::Align::AlignI');

=head1 DESCRIPTION

This class wraps Bio::Phylo matrix objects to give them an interface
compatible with bioperl.

=head1 METHODS

=over

=item add_seq()

Adds another sequence to the alignment. 

 Title     : add_seq
 Usage     : $myalign->add_seq($newseq);
 Function  : Adds another sequence to the alignment. *Does not* align
             it - just adds it to the hashes.
 Returns   : nothing
 Argument  : a Bio::LocatableSeq object
             order (optional)

See L<Bio::LocatableSeq> for more information.

=cut

sub add_seq {
    my ( $adaptor, $seq ) = @_;
    my $self = $$adaptor;
    $self->insert( $seq );
    return $self;
}

=item remove_seq()

Removes a single sequence from an alignment.

 Title     : remove_seq
 Usage     : $aln->remove_seq($seq);
 Function  : Removes a single sequence from an alignment
 Returns   :
 Argument  : a Bio::LocatableSeq object

=cut

sub remove_seq {
    my ( $adaptor, $seq ) = @_;
    my $self = $$adaptor;   
    $self->delete( $seq );
    return $self;
}

=item sort_alphabetically()

Changes the order of the alignemnt to alphabetical on name followed by numerical by number.

 Title     : sort_alphabetically
 Usage     : $ali->sort_alphabetically
 Function  : 

             Changes the order of the alignemnt to alphabetical on name 
             followed by numerical by number.

 Returns   : 
 Argument  : 

=cut

sub sort_alphabetically {
    my $adaptor = shift;
    my $self = $$adaptor;    
    my @seqs = sort { $a <=> $b } @{ $self->get_entities };
    $self->delete( $_ ) for @seqs;
    $self->insert( $_ ) for @seqs;
    return $self;
}

=item each_seq()

Gets an array of Seq objects from the alignment.

 Title     : each_seq
 Usage     : foreach $seq ( $align->each_seq() ) 
 Function  : Gets an array of Seq objects from the alignment
 Returns   : an array
 Argument  : 

=cut

sub each_seq {
    my $adaptor = shift;
    my $self = $$adaptor; 
    return @{ $self->get_entities };
}

=item each_alphabetically()

Returns an array of sequence object sorted alphabetically.

 Title     : each_alphabetically
 Usage     : foreach $seq ( $ali->each_alphabetically() )
 Function  :

             Returns an array of sequence object sorted alphabetically 
             by name and then by start point.
             Does not change the order of the alignment

 Returns   : 
 Argument  : 

=cut

sub each_alphabetically {
    my $adaptor = shift;
    my $self = $$adaptor; 
    return sort { $a <=> $b } @{ $self->get_entities };
}

=item each_seq_with_id()

Gets an array of Seq objects from the alignment.

 Title     : each_seq_with_id
 Usage     : foreach $seq ( $align->each_seq_with_id() ) 
 Function  : 

             Gets an array of Seq objects from the
             alignment, the contents being those sequences
             with the given name (there may be more than one)

 Returns   : an array
 Argument  : a seq name

=cut

sub each_seq_with_id {
    my ( $adaptor, $name ) = @_;
    my $self = $$adaptor;     
    return grep { $_->get_name =~ m/^\Q$name\E$/ } @{ $self->get_entities };
}

=item get_seq_by_pos()

Gets a sequence based on its position in the alignment.

 Title     : get_seq_by_pos
 Usage     : $seq = $aln->get_seq_by_pos(3) # third sequence from the alignment
 Function  : 

             Gets a sequence based on its position in the alignment.
             Numbering starts from 1.  Sequence positions larger than
             no_sequences() will thow an error.

 Returns   : a Bio::LocatableSeq object
 Argument  : positive integer for the sequence osition

=cut

sub get_seq_by_pos {
    my ( $adaptor, $i ) = @_;
    my $self = $$adaptor;     
    return $self->get_by_index( --$i );
}

=item select()

Creates a new alignment from a continuous subset of sequences.

 Title     : select
 Usage     : $aln2 = $aln->select(1, 3) # three first sequences
 Function  : 

             Creates a new alignment from a continuous subset of
             sequences.  Numbering starts from 1.  Sequence positions
             larger than no_sequences() will thow an error.

 Returns   : a Bio::SimpleAlign object
 Argument  : positive integer for the first sequence
             positive integer for the last sequence to include (optional)

=cut

sub select {
    my ( $adaptor, $start, $end ) = @_;
    my $self = $$adaptor;     
    if ( ! $end ) {
        return $self->get_by_index( --$start );
    }
    else {
        my @seqs;
        for ( ( $start - 1 ) .. ( $end - 1 ) ) {
            push @seqs, $self->get_by_index( $_ );
        }
        return @seqs;
    }
}

=item select_noncont()

Creates a new alignment from a subset of sequences.

 Title     : select_noncont
 Usage     : $aln2 = $aln->select_noncont(1, 3) # first and 3rd sequences
 Function  : 

             Creates a new alignment from a subset of
             sequences.  Numbering starts from 1.  Sequence positions
             larger than no_sequences() will thow an error.

 Returns   : a Bio::SimpleAlign object
 Args      : array of integers for the sequences

=cut

sub select_noncont {
    my ( $adaptor, @indices ) = @_;
    my $self = $$adaptor;     
    my @seqs;
    push @seqs, $self->get_by_index( $_ ) for @indices;
    return @seqs;
}

=item id()

Gets/sets the id field of the alignment.

 Title     : id
 Usage     : $myalign->id("Ig")
 Function  : Gets/sets the id field of the alignment
 Returns   : An id string
 Argument  : An id string (optional)

=cut

sub id {
    my ( $adaptor, $name ) = @_;
    my $self = $$adaptor;     
    $self->set_name( $name ) if defined $name;
    return $self->get_name;
}

=item missing_char()

Gets/sets the missing_char attribute of the alignment.

 Title     : missing_char
 Usage     : $myalign->missing_char("?")
 Function  : Gets/sets the missing_char attribute of the alignment
             It is generally recommended to set it to 'n' or 'N' 
             for nucleotides and to 'X' for protein. 
 Returns   : An missing_char string,
 Argument  : An missing_char string (optional)

=cut

sub missing_char {
   my ( $adaptor, $char ) = @_;
    my $self = $$adaptor;    
   $self->set_missing( $char ) if defined $char;
   return $self->get_missing;
}

=item match_char()

Gets/sets the match_char attribute of the alignment.

 Title     : match_char
 Usage     : $myalign->match_char('.')
 Function  : Gets/sets the match_char attribute of the alignment
 Returns   : An match_char string,
 Argument  : An match_char string (optional)

=cut

sub match_char {
    my ( $adaptor, $match ) = @_;
    my $self = $$adaptor;     
    $self->set_matchchar( $match ) if defined $match;
    return $self->get_matchchar;
}

=item gap_char()

Gets/sets the gap_char attribute of the alignment.

 Title     : gap_char
 Usage     : $myalign->gap_char('-')
 Function  : Gets/sets the gap_char attribute of the alignment
 Returns   : An gap_char string, defaults to '-'
 Argument  : An gap_char string (optional)

=cut

sub gap_char {
    my ( $adaptor, $char ) = @_;
	my $self = $$adaptor;    
    $self->set_gap( $char ) if defined $char;
    return $self->get_gap;
}

=item symbol_chars()

Returns all the seen symbols (other than gaps).

 Title   : symbol_chars
 Usage   : my @symbolchars = $aln->symbol_chars;
 Function: Returns all the seen symbols (other than gaps)
 Returns : array of characters that are the seen symbols
 Argument: boolean to include the gap/missing/match characters

=cut

sub symbol_chars {
    my ( $adaptor, $include_special_chars ) = @_;
    my $self = $$adaptor;     
    my @chars;
    for my $row ( @{ $self->get_entities } ) {
    	my @temp = $row->get_char;
        push @chars, @temp;
    }
    my @uniq = keys %{ { map { $_ => 1 } @chars } };
    push @uniq, $self->get_missing, $self->get_gap, $self->get_matchchar if $include_special_chars;
    return @uniq;
}

=item is_flush()

Tells you whether the alignment is flush, ie all of the same length

 Title     : is_flush
 Usage     : if( $ali->is_flush() )
           : 
           :
 Function  : Tells you whether the alignment 
           : is flush, ie all of the same length
           : 
           :
 Returns   : 1 or 0
 Argument  : 

=cut

sub is_flush { 1 } # Bio::Phylo::Matrices::Matrix is always rectangular

=item length()

Returns the maximum length of the alignment.

 Title     : length()
 Usage     : $len = $ali->length() 
 Function  : Returns the maximum length of the alignment.
             To be sure the alignment is a block, use is_flush
 Returns   : 
 Argument  : 

=cut

sub length {
    my $adaptor = shift;
    my $self = $$adaptor;     
    return $self->get_nchar;
}

=item maxdisplayname_length()

Gets the maximum length of the displayname in the alignment. 

 Title     : maxdisplayname_length
 Usage     : $ali->maxdisplayname_length()
 Function  : 

             Gets the maximum length of the displayname in the
             alignment. Used in writing out various MSE formats.

 Returns   : integer
 Argument  : 

=cut

sub maxdisplayname_length {
    my $adaptor = shift;
    my $self = $$adaptor;     
    my $length = 0;
    for my $row ( @{ $self->get_entities } ) {
    	my $rowlength = CORE::length( $row->get_name );
    	$length = $rowlength if $rowlength > $length;
    }
    return $length;
}

=item no_sequences()

Number of sequence in the sequence alignment.

 Title     : no_sequences
 Usage     : $depth = $ali->no_sequences
 Function  : number of sequence in the sequence alignment
 Returns   : integer
 Argument  : None

=cut

sub no_sequences {
    my $adaptor = shift;
    my $self = $$adaptor;     
    return $self->get_ntax;
}

=item displayname()

Gets/sets the display name of a sequence in the alignment.

 Title     : displayname
 Usage     : $myalign->displayname("Ig", "IgA")
 Function  : Gets/sets the display name of a sequence in the alignment
           :
 Returns   : A display name string
 Argument  : name of the sequence
             displayname of the sequence (optional)

=cut

sub displayname {
    my ( $adaptor, $name, $displayname ) = @_;
    my $self = $$adaptor;     
    if ( not defined $displayname ) {
	$self->debug( "Getting displayname for '$name'" );
    }
    else {
        $self->debug( "Setting displayname '$displayname' for '$name'" );
    }
    $name =~ s/\/.*$//;
    my $seq;
    for ( @{ $self->get_entities } ) {
        if ( $_->get_name eq $name ) {
            $seq = $_;
            last;
        }
    }
    if ( defined $displayname ) {
        $seq->set_generic( 'displayname' => $displayname );
    }
    return $seq->get_generic( 'displayname' ) || $name;
}

=item set_displayname_flat()

Makes all the sequences be displayed as just their name, not name/start-end

 Title     : set_displayname_flat
 Usage     : $ali->set_displayname_flat()
 Function  : Makes all the sequences be displayed as just their name,
             not name/start-end
 Returns   : 1
 Argument  : None

=cut

sub set_displayname_flat {
    return 1;
}

=back

=head1 SEE ALSO

=over

=item L<Bio::Align::AlignI>

Bio::Phylo::Adaptor::Bioperl::Matrix is an adaptor that makes Bio::Phylo
character matrices compatible with L<Bio::Align::AlignI> objects.

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

$Id: Matrix.pm 4198 2007-07-12 16:45:08Z rvosa $

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