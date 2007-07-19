package Bio::Phylo::Adaptor;
use strict;
use Bio::Phylo::Util::Exceptions;
use Bio::Phylo::Util::Logger;
use Bio::Phylo;
use vars '$AUTOLOAD';

my $logger = Bio::Phylo::Util::Logger->new;

=head1 NAME

Bio::Phylo::Adaptor - Object adaptor for compatibility

=head1 SYNOPSIS

 # load adaptor class
 use Bio::Phylo::Adaptor;

 # going to build Bio::Phylo tree
 use Bio::Phylo::Forest::Tree;
 my $tree = Bio::Phylo::Forest::Tree->new;

 $Bio::Phylo::COMPAT = 'Bioperl';

 my $bptree = Bio::Phylo::Adaptor->new($tree);

 # $tree is now bioperl compatible
 print "bioperl compatible!" if $bptree->isa('Bio::Tree::TreeI'); 

=head1 DESCRIPTION

The adaptor architecture is used to make Bio::Phylo objects compatible with
other software (currently only bioperl). The compatibility mode can be
defined globally at compile time by specifying:

 use Bio::Phylo compat => 'Bioperl';

In which case all objects are instantiated as adapted objects automatically
from within their respective constructors. Alternatively, adapted objects can
be created by setting the C<$Bio::Phylo::COMPAT> variable and passing 'raw'
Bio::Phylo objects to the Bio::Phylo::Adaptor constructor.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new

 Type    : Constructor
 Title   : new
 Usage   : my $adapted = Bio::Phylo::Adaptor->new($obj);
 Function: Instantiates an adapted Bio::Phylo object.
 Returns : An object compatible with whatever $Bio::Phylo::COMPAT
           is set to.
 Args    : An object to adapt
 Comments: This method depends on a correct setting of the global
           $Bio::Phylo::COMPAT setting.

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual>.

=back

=head1 REVISION

 $Id: Adaptor.pm 4234 2007-07-17 13:41:02Z rvosa $

=cut

sub _adaptor_build_isa {
    my ( $class, $isa ) = @_;
    $logger->debug( "recursing through class '$class'" );
    my @isa;
    {
        no strict 'refs';
        @isa = @{"${class}::ISA"};
        use strict;
    }
    my %seen = map { $_ => 1 } @$isa;
    $seen{__PACKAGE__} = 1;
    ! $seen{$_} and push @$isa, $_ for @isa;
    _adaptor_build_isa->( $_, $isa ) for @isa;
}

sub _adaptor_find_methods {
    my $isa = shift;
    my %methods;
    {
        no strict 'refs';
        for my $class ( @{ $isa } ) {
            my %symtable = %{"${class}::"};
            for my $key ( keys %symtable ) {
                next if $key =~ qr/^[A-Z]+$/;
                next if $key =~ qr/^_/;
                next if $key =~ qr/^:/;
                $methods{$key} = $symtable{$key};
                $logger->debug( "found method to implement: $key" );
            }
        }
        use strict;
    }
    return keys %methods;
}

sub new {
    my ( $class, $self ) = @_;
    
    # if there's no explicit compatibility mode, we just return
    # the non-wrapped object
    if ( not $Bio::Phylo::COMPAT ) {
        return $self;
    }
    
    # construct the class name for the wrapper class. This has the
    # following conventions:
    # first part is current __PACKAGE__, i.e. Bio::Phylo::Adaptor
    # second part is whatever $Bio::Phylo::COMPAT is set to, e.g. Bioperl
    # last part is the last item in the wrapped objects namespace, so that
    # we get names like Bio::Phylo::Adaptor::Bioperl::Node
    my $sub = ref $self;
    $sub =~ s/.*:://;
    my $adaptor_class = __PACKAGE__ .'::'. $Bio::Phylo::COMPAT .'::'. $sub;
    eval "require $adaptor_class";
    if ( $@ ) {
        Bio::Phylo::Util::Exceptions::ExtensionError->throw( 
            'error' => "Can't load adaptor class '$adaptor_class': $@"
        );
    }

    # because the interface of the class whose identity we're faking is
    # push'ed into the adaptor's @ISA at runtime, it'll be the last item
    # in the @ISA, which we'll retrieve here
    my $class_to_adapt_to;
    {
        no strict 'refs';
        my @isa = @{"${adaptor_class}::ISA"};
        $class_to_adapt_to = $isa[-1];
        use strict;
    }    
    if ( ! $class_to_adapt_to ) {
        Bio::Phylo::Util::Exceptions::ExtensionError->throw( 
            'error' => "Need class to adapt to!" 
        );
    }
    eval "require $class_to_adapt_to";
    if ( $@ ) {
        Bio::Phylo::Util::Exceptions::ExtensionError->throw( 
            'error' => "Can't load class to adapt to '$class_to_adapt_to': $@"
        );
    }

    # the following build up the full isa of the class we're adapting to,
    # we then check the combined symbol tables of those classes, and emit
    # warnings if our adaptor class doesn't re-implement methods defined
    # therein
    my $class_to_adapt_to_isa = [ $class_to_adapt_to ];
    my $adaptor_isa           = [ $adaptor_class     ];
    _adaptor_build_isa( $class_to_adapt_to, $class_to_adapt_to_isa );
    my %obj_methods = map { $_ => 1 } _adaptor_find_methods( 
        $class_to_adapt_to_isa,   
    );
    my %adapt_methods = map { $_ => 1 } _adaptor_find_methods( 
        $adaptor_isa, 
    );
    for my $obj_method ( sort { $a cmp $b } keys %obj_methods ) {
        if ( not exists $adapt_methods{$obj_method} ) {
            $logger->warn( "method '$obj_method' not implemented in $adaptor_class" );
        }
    }
    
    # done
    $logger->info( "setting up adaptor class '$adaptor_class' to wrap '$class_to_adapt_to'" );
    return bless \$self, $adaptor_class;
}

sub AUTOLOAD {
    my $self = shift;
    my $object = $$self;
    my $method = $AUTOLOAD;
    $method =~ s/.*://;
    if ( UNIVERSAL::can( $object, $method ) ) {
        return $object->$method( @_ );
    }
    else {
        Bio::Phylo::Util::Exceptions::NotImplemented->throw(
            'error' => "Method '$method' not implemented!"
        );
    }
}

1;