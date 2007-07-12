package Bio::Phylo::Util::XMLWritable;
use strict;
use Bio::Phylo;
use vars '@ISA';
@ISA=qw(Bio::Phylo);

=head1 NAME

Bio::Phylo::Util::XMLWritable - Superclass for objects that stringify to xml

=head1 SYNOPSIS

 # no direct usage

=head1 DESCRIPTION

This class implements a single method, 'to_xml', that writes the invocant to
an xml string. Objects that subclass this class (all biological data objects
in Bio::Phylo) therefore can be written to xml. The 'to_xml' method sometimes
yields ugly (but valid) results, so subclasses may choose to provide their own
override.

=head1 METHODS

=over

=item to_xml()

Serializes invocant to XML.

 Type    : XML serializer
 Title   : to_xml
 Usage   : my $xml = $obj->to_xml;
 Function: Serializes $obj to xml
 Returns : An xml string
 Args    : None

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

$Id: XMLWritable.pm 4169 2007-07-11 01:36:59Z rvosa $

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

sub to_xml {
    my $self = shift;
    my @methods;
    my ( $class, $isa, $seen ) = ( ref $self, [], {} );
    _recurse_isa( $class, $isa, $seen );
    {
        no strict 'refs';
        for my $package ( @{ $isa } ) {
            my %symtable = %{"${package}::"};            
            for my $method ( keys %symtable ) {
                if ( $method =~ m/^get_(.+)$/ && exists $symtable{"set_$1"} ) {
                    push @methods, $method;
                }
            }
        }
        use strict;
    }
    $class =~ s/.*:://;
    $class = lc $class;
    my $xml = sprintf("<%s id=\"n%s\">\n", $class, $self->get_id);
    push @methods, 'get_entities' if $self->isa('Bio::Phylo::Listable');
    @methods = keys %{ { map { $_ => 1 } @methods } };
    for my $method ( sort { $a cmp $b } @methods ) {
        my $result = $self->$method;
        if ( defined $result ) {
            $method =~ s/get_//;
            if ( not ref $result ) {
                $xml .= sprintf("<%s>%s</%s>\n", $method, $result, $method);
            }
            else {
                if ( UNIVERSAL::can( $result, 'to_xml' ) ) {
                    $xml .= $result->to_xml;
                }
                elsif ( UNIVERSAL::isa( $result, 'HASH' ) && %{ $result } ) {
                    $xml .= "<$method>" . _hash_to_xml( $result ) . "</$method>\n";
                }
                elsif ( UNIVERSAL::isa( $result, 'ARRAY' ) && @{ $result } ) {
                    $xml .= "<$method>" . _array_to_xml( $result ) . "</$method>\n";
                }
            }
        }
    }
    $xml .= sprintf("</%s>\n", $class);
}

sub _array_to_xml {
    my $list = shift;
    my $xml = "<list>\n";
    for my $elt ( @{ $list } ) {
        $xml .= "<item>\n";
            if ( not ref $elt ) {
                $xml .= $elt;
            }
            else {
                if ( UNIVERSAL::can( $elt, 'to_xml' ) ) {
                    $xml .= $elt->to_xml;
                }
                elsif ( UNIVERSAL::isa( $elt, 'HASH' ) ) {
                    $xml .= _hash_to_xml( $elt );
                }
                elsif ( UNIVERSAL::isa( $elt, 'ARRAY' ) ) {
                    $xml .= _array_to_xml( $elt );
                }
            }
        $xml .= "</item>\n";
    }
    $xml .= "</list>\n";
    return $xml;
}

sub _hash_to_xml {
    my $hash = shift;
    my $xml = "<dict>\n";
    for my $key ( sort { $a cmp $b } keys %{ $hash } ) {
        $xml .= "<entry>\n<key>$key</key>\n";
        my $val = $hash->{$key};
        if ( not ref $val ) {
            $xml .= "<val>$val</val>\n";
        }
        else {
            if ( UNIVERSAL::can( $val, 'to_xml' ) ) {
                $xml .= "<val>" . $val->to_xml . "</val>\n";
            }
            elsif ( UNIVERSAL::isa( $val, 'HASH' ) ) {
                $xml .= "<val>" . _hash_to_xml( $val ) . "</val>\n";
            }
            elsif ( UNIVERSAL::isa( $val, 'ARRAY' ) ) {
                $xml .= "<val>" . _array_to_xml( $val ) . "</val>\n";
            }
        }
        $xml .= "</entry>\n";
    }
    $xml .= "</dict>\n";
    return $xml;
}

sub _recurse_isa {
    my ( $class, $isa, $seen ) = @_;
    if ( not $seen->{$class} ) {
        $seen->{$class} = 1;
        push @{ $isa }, $class;
        my @isa;
        {
            no strict 'refs';
            @isa   = @{"${class}::ISA"};
            use strict;
        }
        _recurse_isa( $_, $isa, $seen ) for @isa;
    }
}

sub _cleanup { 
    my $self = shift;
    $self->info("cleaning up '$self'"); 
}

1;