use Module::Build;

my $build = Module::Build->new(
    'module_name'   => 'Bio::Phylo',
    'license'       => 'perl',
    'dist_author'   => 'Rutger A. Vos <rvosa@sfu.ca>',
    'sign'          => 0,
    'create_readme' => 0,   
    'requires' => {
        'Exception::Class' => 1.23,
        'Math::Random'     => 0.67,
        'IO::String'       => 1.05,
        'SVG'              => 1.07,
        'List::Util'       => 0,
        'Scalar::Util'     => 0,   
        'Test::More'       => 0.62,             
    },
    'recommends' => {
        'Bio::Tree::TreeI' => 0,
        'Bio::Tree::NodeI' => 0,      
    },
    'auto_features' => {
        'HTML_support' => {
            'description' => 'Create HTML documentation',
            'requires'    => { 'Pod::Html' => 0 },
        },
    },
    'add_to_cleanup' => [ 'pm_to_blib', 'Build', 'Makefile', '_build', 'Build.bat' ],
    'meta_merge'     => {
        'resources'  => {
            'homepage'    => 'http://search.cpan.org/~rvosa/Bio-Phylo/',
            'bugtracker'  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Phylo',
            'MailingList' => 'mailto:rvos@interchange.ubc.ca',
            'repository'  => 'http://nladr-cvs.sdsc.edu/svn/CIPRES/cipresdev/trunk/cipres/framework/perl/phylo'
        },
    },
    'script_files' => [ 
    	'bin/age2bl.pl', 
    	'bin/bremer.pl', 
    	'bin/dnd2svg.pl', 
    	'bin/dndtag.pl', 
    	'bin/droptip.pl', 
    	'bin/LRmb.pl', 
    	'bin/postmb.pl', 
    ],
);

$build->create_build_script;
