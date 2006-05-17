# $Id: Makefile.PL,v 1.9 2006/03/06 10:55:11 rvosa Exp $
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
        'Scalar::Util'     => 0,
        'Exception::Class' => 0,
        'Test::More'       => 0,
        'Math::Random'     => 0,
        'IO::String'       => 0,
        'XML::Simple'      => 0,
        'Hash::Util'       => 0,
        'SVG'              => 1.07,
        'Storable'         => 0,
        'fields'           => 0,
        'base'             => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-Phylo-*' },
);
