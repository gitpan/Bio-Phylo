# $Id: Makefile.PL 2904 2007-01-30 23:29:05Z rvosa $
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::Phylo',
    AUTHOR              => 'Rutger Vos <rvosa@sfu.ca>',
    VERSION_FROM        => 'lib/Bio/Phylo.pm',
    ABSTRACT_FROM       => 'lib/Bio/Phylo.pm',
    EXE_FILES           => [
                            'bin/age2bl.pl',
                            'bin/bremer.pl',
                            'bin/dnd2svg.pl',
                            'bin/droptip.pl',
                            'bin/LRmb.pl',
                            'bin/postmb.pl'
                            ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Scalar::Util'     => 0,
        'Exception::Class' => 1.23,
        'Test::More'       => 0.47,
        'Math::Random'     => 0.67,
        'IO::String'       => 1.05,
        'SVG'              => 1.07,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-Phylo-*' },
);
