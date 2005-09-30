# $Id: Makefile.PL,v 1.8 2005/09/19 19:34:35 rvosa Exp $
# Subversion: $Rev: 177 $
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
        'Test::More'       => 0,
        'Math::Random'     => 0,
        'SVG'              => 1.07,
        'Exception::Class' => 0,
        'Scalar::Util'     => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Phylo-*' },
);
