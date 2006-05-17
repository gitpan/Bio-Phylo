# $Id: 14-nexus.t,v 1.11 2006/04/06 02:14:24 rvosa Exp $
use strict;
use warnings;
use Test::More tests => 5;
use Bio::Phylo::IO qw(parse);

$Bio::Phylo::VERBOSE = 1;

# Up until the next big block of comment tokens, a number of nexus strings is
# defined.
################################################################################
################################################################################
################################################################################
################################################################################

# This string holds a valid (mesquite) nexus file
my $testparse = <<TESTPARSE
#NEXUS
[written Wed Jun 08 00:30:00 CEST 2005 by Mesquite  version 1.02+ (build g8)]

BEGIN TAXA;
	DIMENSIONS NTAX=5;
	TAXLABELS
		taxon_1 taxon_2 taxon_3 taxon_4 taxon_5
	;

END;


BEGIN CHARACTERS;
[! Simulated Matrices on Current Tree:  Matrix #1; Simulator: Evolve DNA Characters; most recent tree: Default ladder [seed for matrix sim. 1118183366345]
     Evolve DNA Characters:  Simulated evolution using model Jukes-Cantor with the following parameters:
        Root states model (Equal Frequencies): Equal Frequencies
        Equilibrium states model (Equal Frequencies): Equal Frequencies
        Character rates model (Equal Rates): Equal Rates
        Rate matrix model (Single Rate): single rate

         Stored Probability Model for Simulation:  Current model "Jukes-Cantor":         Root states model (Equal Frequencies): Equal Frequencies
        Equilibrium states model (Equal Frequencies): Equal Frequencies
        Character rates model (Equal Rates): Equal Rates
        Rate matrix model (Single Rate): single rate

         Stored Matrices:  Character Matrices from file: Project with home file "testparse.nex"
     Tree of context:  Tree(s) used from Tree Window 2 showing Stored Trees. Last tree used: Default ladder  [tree: (1,(2,(3,(4,5))));]
]
	DIMENSIONS NCHAR=10;
	FORMAT DATATYPE = DNA GAP = - MISSING = ?;
	MATRIX
	taxon_1  TACCACTTGT

	taxon_2  GTTCTCTTCT

	taxon_3  AGCGTCTTTC

	taxon_4  ACTTTGTTTC

	taxon_5  GCCCCTCGAG


;


END;

BEGIN ASSUMPTIONS;
	TYPESET * UNTITLED   =  unord:  1 -  10;

END;

BEGIN MESQUITECHARMODELS;
	ProbModelSet * UNTITLED   =  'Jukes-Cantor':  1 -  10;
END;

BEGIN TREES;
[!Parameters: ]
	TRANSLATE
		1 taxon_1,
		2 taxon_2,
		3 taxon_3,
		4 taxon_4,
		5 taxon_5;
	TREE Default_ladder = (1,(2,(3,(4,5))));
	TREE Default_bush = (1,2,3,4,5);
	TREE Default_symmetrical = ((1,2),(3,(4,5)));

END;


Begin MESQUITE;
		MESQUITESCRIPTVERSION 2;
		TITLE AUTO;
		tell ProjectCoordinator;
		getEmployee  #mesquite.minimal.ManageTaxa.ManageTaxa;
		tell It;
			setID 0 7362620364969598977;
			showTaxa #7362620364969598977 #mesquite.lists.TaxonList.TaxonList;
			tell It;
				setTaxa #7362620364969598977;
				getWindow;
				tell It;
					newAssistant  #mesquite.lists.TaxonListCurrPartition.TaxonListCurrPartition;
					setSize 360 382;
					setLocation 60 10;
					setFont SanSerif;
					setFontSize 10;
					onInfoBar;
					setExplanationSize 30;
					setAnnotationSize 20;
					getToolPalette;
					tell It;
					endTell;
				endTell;
				showWindow;
			endTell;
		endTell;
		getEmployee  #mesquite.charMatrices.ManageCharacters.ManageCharacters;
		tell It;
			setID 0 7381659581231466636;
			checksum 0 623236349;
		endTell;
		getEmployee  #mesquite.charMatrices.BasicDataWindowCoord.BasicDataWindowCoord;
		tell It;
			showDataWindow #7381659581231466636 #mesquite.charMatrices.BasicDataWindowMaker.BasicDataWindowMaker;
			tell It;
				getWindow;
				tell It;
					setSize 420 280;
					setLocation 259 168;
					setFont SanSerif;
					setFontSize 10;
					onInfoBar;
					setExplanationSize 30;
					setAnnotationSize 20;
					getToolPalette;
					tell It;
					endTell;
					setActive;
					setTool mesquite.charMatrices.BasicDataWindowMaker.BasicDataWindow.arrow;
					colorCells  #mesquite.charMatrices.ColorByState.ColorByState;
					setBackground White;
					toggleShowNames on;
					toggleTight off;
					toggleShowChanges on;
					toggleShowStates on;
					toggleAutoWithCharNames on;
					toggleConstrainCW on;
				endTell;
				showWindow;
				getWindow;
				tell It;
					forceAutosize;
				endTell;
				getEmployee #mesquite.charMatrices.ColorCells.ColorCells;
				tell It;
					setColor Red;
					removeColor off;
				endTell;
				getEmployee #mesquite.charMatrices.QuickKeySelector.QuickKeySelector;
				tell It;
					autotabOff;
				endTell;
				getEmployee #mesquite.ornamental.CellPictures.CellPictures;
				tell It;
					toggleSeparate off;
					toggleAA off;
				endTell;
			endTell;
		endTell;
		getEmployee  #mesquite.trees.BasicTreeWindowCoord.BasicTreeWindowCoord;
		tell It;
			makeTreeWindow #7362620364969598977  #mesquite.trees.BasicTreeWindowMaker.BasicTreeWindowMaker;
			tell It;
				setTreeSource  #mesquite.trees.StoredTrees.StoredTrees;
				tell It;
					setTreeBlock 1;
					toggleUseWeights off;
				endTell;
				setAssignedID 597.1118183342852.1985362903674620622;
				getTreeDrawCoordinator #mesquite.trees.BasicTreeDrawCoordinator.BasicTreeDrawCoordinator;
				tell It;
					suppress;
					setTreeDrawer  #mesquite.trees.DiagonalDrawTree.DiagonalDrawTree;
					tell It;
						setEdgeWidth 12;
						orientUp;
						getEmployee #mesquite.trees.NodeLocsStandard.NodeLocsStandard;
						tell It;
							stretchToggle off;
							branchLengthsToggle off;
							toggleScale on;
							toggleCenter off;
							toggleEven off;
							namesAngle ?;
						endTell;
					endTell;
					setBackground White;
					setBranchColor Black;
					showNodeNumbers off;
					labelBranchLengths off;
					desuppress;
					getEmployee #mesquite.trees.BasicDrawTaxonNames.BasicDrawTaxonNames;
					tell It;
						setColor Black;
						toggleColorPartition on;
						toggleShadePartition off;
						toggleNodeLabels on;
						toggleShowNames on;
					endTell;
				endTell;
				getTreeWindow;
				tell It;
					setSize 520 400;
					setLocation 352 149;
					setFont SanSerif;
					setFontSize 10;
					onInfoBar;
					setExplanationSize 30;
					setAnnotationSize 20;
					getToolPalette;
					tell It;
					endTell;
					setTreeNumber 1;
					useSuggestedSize;
					toggleTextOnTree off;
				endTell;
				showWindow;
				getEmployee #mesquite.ornamental.BranchNotes.BranchNotes;
				tell It;
					setAlwaysOn off;
				endTell;
				getEmployee #mesquite.trees.ColorBranches.ColorBranches;
				tell It;
					setColor Red;
					removeColor off;
				endTell;
			endTell;
		endTell;
		endTell;
end;
TESTPARSE
;

# this string holds a valid nexus tree block
my $testparse_trees = <<TESTPARSE_TREES
#NEXUS
BEGIN TREES;
[!Parameters: ]
	TRANSLATE
		1 taxon_1,
		2 taxon_2,
		3 taxon_3,
		4 taxon_4,
		5 taxon_5;
	TREE Default_ladder = (1,(2,(3,(4,5))));
	TREE Default_bush = (1,2,3,4,5);
	TREE Default_symmetrical = ((1,2),(3,(4,5)));

END;
TESTPARSE_TREES
;

# this string holds a nexus file with a bad nchar specification.
my $testparse_bad = <<TESTPARSE_BAD
#NEXUS
[written Wed Jun 08 00:30:00 CEST 2005 by Mesquite  version 1.02+ (build g8)]

BEGIN TAXA;
	DIMENSIONS NTAX=5;
	TAXLABELS
		taxon_1 taxon_2 taxon_3 taxon_4 taxon_5
	;

END;


BEGIN CHARACTERS;
[! Simulated Matrices on Current Tree:  Matrix #1; Simulator: Evolve DNA Characters; most recent tree: Default ladder [seed for matrix sim. 1118183366345]
     Evolve DNA Characters:  Simulated evolution using model Jukes-Cantor with the following parameters:
        Root states model (Equal Frequencies): Equal Frequencies
        Equilibrium states model (Equal Frequencies): Equal Frequencies
        Character rates model (Equal Rates): Equal Rates
        Rate matrix model (Single Rate): single rate

         Stored Probability Model for Simulation:  Current model "Jukes-Cantor":         Root states model (Equal Frequencies): Equal Frequencies
        Equilibrium states model (Equal Frequencies): Equal Frequencies
        Character rates model (Equal Rates): Equal Rates
        Rate matrix model (Single Rate): single rate

         Stored Matrices:  Character Matrices from file: Project with home file "testparse.nex"
     Tree of context:  Tree(s) used from Tree Window 2 showing Stored Trees. Last tree used: Default ladder  [tree: (1,(2,(3,(4,5))));]
]
	DIMENSIONS NCHAR=11;
	FORMAT DATATYPE = DNA GAP = - MISSING = ?;
	MATRIX
	taxon_1  TACCACTTGT

	taxon_2  GTTCTCTTCT

	taxon_3  AGCGTCTTTC

	taxon_4  ACTTTGTTTC

	taxon_5  GCCCCTCGAG


;


END;

BEGIN ASSUMPTIONS;
	TYPESET * UNTITLED   =  unord:  1 -  10;

END;

BEGIN MESQUITECHARMODELS;
	ProbModelSet * UNTITLED   =  'Jukes-Cantor':  1 -  10;
END;

BEGIN TREES;
[!Parameters: ]
	TRANSLATE
		1 taxon_1,
		2 taxon_2,
		3 taxon_3,
		4 taxon_4,
		5 taxon_5;
	TREE Default_ladder = (1,(2,(3,(4,5))));
	TREE Default_bush = (1,2,3,4,5);
	TREE Default_symmetrical = ((1,2),(3,(4,5)));

END;


Begin MESQUITE;
		MESQUITESCRIPTVERSION 2;
		TITLE AUTO;
		tell ProjectCoordinator;
		getEmployee  #mesquite.minimal.ManageTaxa.ManageTaxa;
		tell It;
			setID 0 7362620364969598977;
			showTaxa #7362620364969598977 #mesquite.lists.TaxonList.TaxonList;
			tell It;
				setTaxa #7362620364969598977;
				getWindow;
				tell It;
					newAssistant  #mesquite.lists.TaxonListCurrPartition.TaxonListCurrPartition;
					setSize 360 382;
					setLocation 60 10;
					setFont SanSerif;
					setFontSize 10;
					onInfoBar;
					setExplanationSize 30;
					setAnnotationSize 20;
					getToolPalette;
					tell It;
					endTell;
				endTell;
				showWindow;
			endTell;
		endTell;
		getEmployee  #mesquite.charMatrices.ManageCharacters.ManageCharacters;
		tell It;
			setID 0 7381659581231466636;
			checksum 0 623236349;
		endTell;
		getEmployee  #mesquite.charMatrices.BasicDataWindowCoord.BasicDataWindowCoord;
		tell It;
			showDataWindow #7381659581231466636 #mesquite.charMatrices.BasicDataWindowMaker.BasicDataWindowMaker;
			tell It;
				getWindow;
				tell It;
					setSize 420 280;
					setLocation 259 168;
					setFont SanSerif;
					setFontSize 10;
					onInfoBar;
					setExplanationSize 30;
					setAnnotationSize 20;
					getToolPalette;
					tell It;
					endTell;
					setActive;
					setTool mesquite.charMatrices.BasicDataWindowMaker.BasicDataWindow.arrow;
					colorCells  #mesquite.charMatrices.ColorByState.ColorByState;
					setBackground White;
					toggleShowNames on;
					toggleTight off;
					toggleShowChanges on;
					toggleShowStates on;
					toggleAutoWithCharNames on;
					toggleConstrainCW on;
				endTell;
				showWindow;
				getWindow;
				tell It;
					forceAutosize;
				endTell;
				getEmployee #mesquite.charMatrices.ColorCells.ColorCells;
				tell It;
					setColor Red;
					removeColor off;
				endTell;
				getEmployee #mesquite.charMatrices.QuickKeySelector.QuickKeySelector;
				tell It;
					autotabOff;
				endTell;
				getEmployee #mesquite.ornamental.CellPictures.CellPictures;
				tell It;
					toggleSeparate off;
					toggleAA off;
				endTell;
			endTell;
		endTell;
		getEmployee  #mesquite.trees.BasicTreeWindowCoord.BasicTreeWindowCoord;
		tell It;
			makeTreeWindow #7362620364969598977  #mesquite.trees.BasicTreeWindowMaker.BasicTreeWindowMaker;
			tell It;
				setTreeSource  #mesquite.trees.StoredTrees.StoredTrees;
				tell It;
					setTreeBlock 1;
					toggleUseWeights off;
				endTell;
				setAssignedID 597.1118183342852.1985362903674620622;
				getTreeDrawCoordinator #mesquite.trees.BasicTreeDrawCoordinator.BasicTreeDrawCoordinator;
				tell It;
					suppress;
					setTreeDrawer  #mesquite.trees.DiagonalDrawTree.DiagonalDrawTree;
					tell It;
						setEdgeWidth 12;
						orientUp;
						getEmployee #mesquite.trees.NodeLocsStandard.NodeLocsStandard;
						tell It;
							stretchToggle off;
							branchLengthsToggle off;
							toggleScale on;
							toggleCenter off;
							toggleEven off;
							namesAngle ?;
						endTell;
					endTell;
					setBackground White;
					setBranchColor Black;
					showNodeNumbers off;
					labelBranchLengths off;
					desuppress;
					getEmployee #mesquite.trees.BasicDrawTaxonNames.BasicDrawTaxonNames;
					tell It;
						setColor Black;
						toggleColorPartition on;
						toggleShadePartition off;
						toggleNodeLabels on;
						toggleShowNames on;
					endTell;
				endTell;
				getTreeWindow;
				tell It;
					setSize 520 400;
					setLocation 352 149;
					setFont SanSerif;
					setFontSize 10;
					onInfoBar;
					setExplanationSize 30;
					setAnnotationSize 20;
					getToolPalette;
					tell It;
					endTell;
					setTreeNumber 1;
					useSuggestedSize;
					toggleTextOnTree off;
				endTell;
				showWindow;
				getEmployee #mesquite.ornamental.BranchNotes.BranchNotes;
				tell It;
					setAlwaysOn off;
				endTell;
				getEmployee #mesquite.trees.ColorBranches.ColorBranches;
				tell It;
					setColor Red;
					removeColor off;
				endTell;
			endTell;
		endTell;
		endTell;
end;
TESTPARSE_BAD
;

# this string holds a taxa block with a bad ntax specification
my $testparse_taxa_bad = <<TESTPARSE_TAXA_BAD
#NEXUS
[written Wed Jun 08 00:30:00 CEST 2005 by Mesquite  version 1.02+ (build g8)]

BEGIN TAXA;
	DIMENSIONS NTAX=6;
	TAXLABELS
		taxon_1 taxon_2 taxon_3 taxon_4 taxon_5
	;

END;
TESTPARSE_TAXA_BAD
;

################################################################################
################################################################################
################################################################################
################################################################################
# Done defining nexus tokens, let's try to parse them.

print "--------------------------------------------------------------------\n";
ok( parse( '-format' => 'fastnexus', '-string' => $testparse ), '1 good parse' );
print "--------------------------------------------------------------------\n";
ok( parse( '-format' => 'fastnexus', '-string' => $testparse_trees ), '2 tree block' );
print "--------------------------------------------------------------------\n";
eval { parse( '-format' => 'fastnexus', '-string' => $testparse_bad ) };
ok( $@->isa('Bio::Phylo::Util::Exceptions::BadFormat' ), '3 bad nchar' );
print "--------------------------------------------------------------------\n";
eval { parse( '-format' => 'fastnexus', '-string' => $testparse_taxa_bad ) };
ok( $@->isa('Bio::Phylo::Util::Exceptions::BadFormat'), '4 bad ntax' );
print "--------------------------------------------------------------------\n";
eval { parse( '-format' => 'fastnexus', '-file' => 'DOES_NOT_EXIST' ) };
ok( $@->isa('Bio::Phylo::Util::Exceptions::FileError'), '5 file error' );
