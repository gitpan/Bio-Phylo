# $Id: Makefile.PL,v 1.6 2005/08/09 12:36:11 rvosa Exp $
# Subversion: $Rev: 163 $
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
        'Exception::Class' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Phylo-*' },
);
