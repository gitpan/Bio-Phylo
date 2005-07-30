use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::Phylo',
    AUTHOR              => 'Rutger Vos <rvosa@sfu.ca>',
    VERSION_FROM        => 'lib/Bio/Phylo.pm',
    ABSTRACT_FROM       => 'lib/Bio/Phylo.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Math::Random'  => 0,
        'SVG'           => 1.07,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Phylo-*' },
);
