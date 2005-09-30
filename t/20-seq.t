# $Id: 20-seq.t,v 1.1 2005/09/19 22:25:14 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 15;
use Bio::Phylo::Matrices::Sequence;
use Bio::Phylo::Taxa::Taxon;
my $seq = Bio::Phylo::Matrices::Sequence->new;

my $nuc  = 'ACGTUMRWSYKVHDBXN.-?';
my $prot = 'ABCDEFGHIKLMNPQRSTUVWXYZ.-?';
my $std  = '1234567890?';
my $con  = '0.3242 0.23423';

ok($seq->set_taxon(Bio::Phylo::Taxa::Taxon->new), '1  taxon');
ok($seq->set_type('DNA'),                         '2  DNA');
ok($seq->set_seq($nuc),                           '3  seq');
eval { $seq->set_seq('E'); };
ok(UNIVERSAL::isa( $@, 'Bio::Phylo::Exceptions::BadString' ), '4  bad');
ok($seq->set_type('RNA'),                         '5  RNA');
ok($seq->set_type('STANDARD'),                    '6  STD');
ok($seq->set_seq($std),                           '7  seq');
ok($seq->set_type('PROTEIN'),                     '8  PROT');
ok($seq->set_seq($prot),                          '9  seq');
ok($seq->set_type('NUCLEOTIDE'),                  '10 NUC');
ok($seq->set_type('CONTINUOUS'),                  '11 CONT');
ok($seq->set_seq($con),                           '12 seq');
ok($seq->get_taxon,                               '13 taxon');
ok($seq->get_type,                                '14 type');
ok($seq->get_seq,                                 '15 seq');