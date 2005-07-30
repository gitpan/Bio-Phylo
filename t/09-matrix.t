# $Id: 09-matrix.t,v 1.3 2005/07/22 00:46:31 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 26;
use Bio::Phylo::Matrices::Datum;
use Bio::Phylo::Matrices::Matrix;
use Bio::Phylo;

ok( my $matrix = new Bio::Phylo::Matrices::Matrix, '1 initialize' );

$matrix->VERBOSE( -level => 0 );

ok( !$matrix->insert('BAD!'), '2 insert bad data' );
my $datum = new Bio::Phylo::Matrices::Datum;
$datum->set_name('datum');
$datum->set_type('STANDARD');
$datum->set_char('5');
ok( $matrix->insert($datum), '3 insert good data' );

# the get method
ok( !$matrix->get('frobnicate'), '4 get bad method' );
ok( $matrix->get('get_entities'), '5 get good method' );

# the get_data method
ok( $matrix->get_entities, '6 get data' );

# the get_by_value method
ok( $matrix->get_by_value( -value => 'get_char', -lt => 6 ),
    '9 get by value lt' );
ok( $matrix->get_by_value( -value => 'get_char', -le => 5 ),
    '10 get by value le' );
ok( $matrix->get_by_value( -value => 'get_char', -gt => 4 ),
    '11 get by value gt' );
ok( $matrix->get_by_value( -value => 'get_char', -ge => 5 ),
    '12 get by value ge' );
ok( $matrix->get_by_value( -value => 'get_char', -eq => 5 ),
    '13 get by value eq' );
ok( ! scalar @{$matrix->get_by_value( -value => 'get_char', -lt => 4 )},
    '14 get by value lt' );
ok( ! scalar @{$matrix->get_by_value( -value => 'get_char', -le => 4 )},
    '15 get by value le' );
ok( ! scalar @{$matrix->get_by_value( -value => 'get_char', -gt => 6 )},
    '16 get by value gt' );
ok( ! scalar @{$matrix->get_by_value( -value => 'get_char', -ge => 6 )},
    '17 get by value ge' );
ok( ! scalar @{$matrix->get_by_value( -value => 'get_char', -eq => 6 )},
    '18 get by value eq' );
ok( ! scalar @{$matrix->get_by_value( -value => 'frobnicate', -lt => 4 )},
    '19 get by value lt' );
ok( ! scalar @{$matrix->get_by_value( -value => 'frobnicate', -le => 4 )},
    '20 get by value le' );
ok( ! scalar @{$matrix->get_by_value( -value => 'frobnicate', -gt => 6 )},
    '21 get by value gt' );
ok( ! scalar @{$matrix->get_by_value( -value => 'frobnicate', -ge => 6 )},
    '22 get by value ge' );
ok( ! scalar @{$matrix->get_by_value( -value => 'frobnicate', -eq => 6 )},
    '23 get by value eq' );
ok(
    $matrix->get_by_regular_expression(
        -value => 'get_type',
        -match => '^STANDARD$'
    ),
    '24 get by re'
);
ok(
    ! scalar @{$matrix->get_by_regular_expression(
        -value => 'frobnicate',
        -match => '^STANDARD$'
    )},
    '25 get by re'
);
ok(
    ! scalar @{$matrix->get_by_regular_expression(
        -value => 'get_type',
        -match => '^DNA$'
    )},
    '26 get by re'
);
ok(
    !$matrix->get_by_regular_expression(
        -value      => 'get_type',
        -frobnicate => '^DNA$'
    ),
    '27 get by re'
);
ok( $matrix->DESTROY, '28 destroy' );
