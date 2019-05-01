/*	Add scaled columns ImageJ Analyze 	
	This macro adds additional geometrical calculations Peter J. Lee 6/17/2016 - 9/28/2016.
	For IntD all interfaces are shared between to objects either side so interface length is divided by 2
	v171009 Adds additional aspect ratio variants.
	v180223 Adds hexagonal geometry and a couple of volumetric examples from Russ.
	v180330 Renames GBD to IntD.
	v180503 1st version using new Table functions introduced in ImageJ 1.52
	v180503b Reverts to setResult for scaled data to give more flexibility on column labels
	v180809 All measurements selectable. Adds C_Tilt. Restored missing Feret AR column.
	v190319 Adds full max and min coordinates using Roi.getFeretPoints macro function added in ImageJ 1.52m.
	v190325 Saves and retrieves a preferences file.
	v190404 Removed redundant code. Prefs path moved from busy Macro directory to "info" sub-directory. Added HexShapeFactor and HexShapeFactorR.
	v190430-v190501 prefs moved to imageJ prefs. Please delete old copies of ..\macros\info\ExtGeoPrefs_LCF.txt
		Changed measurement naming philosophy (column titles stay abbreviated to keep column widths narrow but in the dialog selection box the geometry names expanded so that they are a little bit more descriptive. Some of the output names were changed too.
	*/
macro "Add Additional Geometrical Analyses to Results" {
	requires("1.52m"); /*Uses the new ROI.getFeretPoints released in 1.52m */
	if (nResults==0) exit("No Results Table to work with");
	userPath = getInfo("user.dir");
	selectWindow("Results");
	setBatchMode(true); /* batch mode on*/
	getPixelSize(unit, pixelWidth, pixelHeight);
	lcf = (pixelWidth + pixelHeight)/2;
	unitLabel = "\(" + unit + "\)";
	delimiter = "|";
	
	supminus = fromCharCode(0x207B);
	supone = fromCharCode(0x00B9); /* UTF-16 (hex) C/C++/Java source code 	"\u00B9" */
	suptwo = fromCharCode(0x00B2); /* UTF-16 (hex) C/C++/Java source code 	"\u00B2" */
	supthree = fromCharCode(0x00B2); /* UTF-16 (hex) C/C++/Java source code 	"\u00B3" */

	Xs = Table.getColumn("X");
	Ys = Table.getColumn("Y");
	XMs = Table.getColumn("XM");
	YMs = Table.getColumn("YM");
	BXs = Table.getColumn("BX");
	BYs = Table.getColumn("BY");
	BWs = Table.getColumn("Width");
	BHs = Table.getColumn("Height");
	Ps = Table.getColumn("Perim.");
	Areas =  Table.getColumn("Area");
	Majors = Table.getColumn("Major");
	Minors = Table.getColumn("Minor");
	Ferets = Table.getColumn("Feret");
	MinFerets = Table.getColumn("MinFeret");
	Angles = Table.getColumn("Angle");
	FeretAngles = Table.getColumn("FeretAngle");
	/* The measurements are split into groups for organization purposes and then recombined for simplicity of use with Dialog.addCheckboxGroup */
	analysesF = newArray("AR_Bounding_Rect","AR_Feret","Roundness_Feret","Compactness_Feret", "Feret_Coords");
	analysesA = newArray("Angle_0-90", "FeretAngle_0-90","CircToEllipse_Tilt");
	analysesPx = newArray("X\(px\)","Y\(px\)","YM\(px\)","YM\(px\)","BX\(px\)","BY\(px\)","Bounding_Rect_W\(px\)","Bounding_Rect_H\(px\)");
	analysesD = newArray("D_Area_CircEquiv","D_Perim_CircEquiv","Dsph_equiv");
	analysesB = newArray("FiberThk_Snake","Fiber_Thk_Russ1","Fiber_Thk_Russ2","Fiber_Lngth_Snake","Fiber_Lngth_Russ1","Fiber_Lngth_Russ2","Fiber_Snake_Curl","AR_Fiber_Snake","AR_Fiber_Russ1","AR_Fiber_Russ2");
	analysesH = newArray("Hxgn_Side","Hxgn_Perim","Hxgn_Shape_Factor", "Hxgn_Shape_Factor_R", "Hexagonality");
	analysesM = newArray("Object#","Convexity","Interfacial_Density","Thinnes_Ratio","Extent");
	analysesV = newArray("Vol_Pointed_Spheroid","Vol_Discus_Spheroid");
	analyses1 = Array.concat(analysesF,analysesA);
	analyses3 = Array.concat(analysesD,analysesB,analysesH,analysesM,analysesV);
	if (lcf!=1) {
		analyses = Array.concat(analyses1,analysesPx,analyses3);
		prefsNameKey = "ascExtGeoPrefs_LCF.";
	}
	else {
		analyses = Array.concat(analyses1,analyses3);
		prefsNameKey = "ascExtGeoPrefs.";
	}
	prefsAnalyses = call("ij.Prefs.get", prefsNameKey+"Analyses", "None");
	prefsAnalysesOn = call("ij.Prefs.get", prefsNameKey+"AnalysesOn", "None");
	if (prefsAnalyses!="None" && prefsAnalysesOn!="None") {
		lastUsedAnalyses = split(prefsAnalyses,delimiter);
		lastUsedAnalysesOn = split(prefsAnalysesOn,delimiter);
		if (analyses.length==lastUsedAnalysesOn.length) outputResult = lastUsedAnalysesOn; /* if new measurements are added the prefs are reset */
	}
	else {
		outputResult = newArray(analyses.length);
		outputResult = Array.fill(outputResult, true);
		/* Example of how to uncheck analyses that you do not think should be default inclusions. */ 
		outputResult[arrayRankMatch(analyses,"Fiber_Thk_Russ1")] = false;
		outputResult[arrayRankMatch(analyses,"Fiber_Lngth_Russ1")] = false;
		outputResult[arrayRankMatch(analyses,"AR_Fiber_Russ1")] = false;
		outputResult[arrayRankMatch(analyses,"Vol_Pointed_Spheroid")] = false;
		outputResult[arrayRankMatch(analyses,"Vol_Discus_Spheroid")] = false;
	}
	if (analyses.length!=outputResult.length) exit("analyses.length = " + analyses.length + " but outputResult.length = " + outputResult.length);
	checkboxGroupColumns = 5;
	checkboxGroupRows = round(analyses.length/checkboxGroupColumns)+1; /* Add +1 to make sure that there are enough cells */
	Dialog.create("Select Extended Geometrical Analyses");
	if (roiManager("count")!=nResults) {
		outputResult[arrayRankMatch(analyses,"Feret_Coords")] = false;
		Dialog.addMessage("Extended Feret Coords requires ROIs");
	}
	Dialog.addCheckboxGroup(checkboxGroupRows,checkboxGroupColumns,analyses,outputResult);
	Dialog.addCheckbox("Reset preferences for next run?", false);
	Dialog.show();
	for (i=0; i<outputResult.length; i++) outputResult[i] = Dialog.getCheckbox();
	analysesPrefsKey = prefsNameKey+"Analyses";
	analysesOnPrefsKey = prefsNameKey+"AnalysesOn";
	if (Dialog.getCheckbox()) {
		call("ij.Prefs.set", analysesPrefsKey, "None");
		call("ij.Prefs.set", analysesOnPrefsKey, "None");
	}
	else {
		analysesString = arrayToString(analyses,delimiter);
		analysesOnString = arrayToString(outputResult,delimiter);
		call("ij.Prefs.set", analysesPrefsKey, analysesString);
		call("ij.Prefs.set", analysesOnPrefsKey, analysesOnString);
	}
	/* Note that the AR reported by ImageJ is the ratio of the fitted ellipse major and minor axes. */
	if (outputResult[arrayRankMatch(analyses,"CircToEllipse_Tilt")]) {Table.applyMacro("Cir_to_El_Tilt=(180/PI) * acos(1/AR)");} /* The angle a circle (cylinder in 3D) would be tilted to appear as an ellipse with this AR */
	if (outputResult[arrayRankMatch(analyses,"AR_Bounding_Rect")]) {Table.applyMacro("AR_Box=maxOf(Height/Width, Width/Height)");} /* Bounding rectangle aspect ratio */
	if (outputResult[arrayRankMatch(analyses,"AR_Feret")]) {Table.applyMacro("AR_Feret=Feret/MinFeret");} /* adds fitted ellipse aspect ratio. */
	if (outputResult[arrayRankMatch(analyses,"Roundness_Feret")]) {Table.applyMacro("Round_Feret=4*Area/(PI * Feret * Feret)");} /* Adds Roundness, using Feret as maximum diameter (IJ Analyze uses ellipse major axis */
	if (outputResult[arrayRankMatch(analyses,"Compactness_Feret")]) {Table.applyMacro("Compact_Feret=(sqrt(Area*4/PI))/Feret");} /* Adds Compactness, using Feret as maximum diameter */
	for (i=0; i<nResults; i++) {
		if(!requires152m() && (roiManager("count")==nResults) && outputResult[arrayRankMatch(analyses,"Feret_Coords")]) {
			roiManager("select", i);
			Roi.getFeretPoints(x,y);
			setResult("FeretX", i, x[0]);
			setResult("FeretY", i, y[0]);
			setResult("FeretX2", i, x[1]);
			setResult("FeretY2", i, y[1]);
			setResult("FeretMinX", i, x[2]);
			setResult("FeretMinY", i, y[2]);
			setResult("FeretMinX2", i, d2s(round(x[3]),0));
			setResult("FeretMinY2", i, d2s(round(y[3]),0));
		}
		roiManager("deselect");
		if (lcf!=1) {
			if (outputResult[arrayRankMatch(analyses,"X\(px\)")]) setResult("X\(px\)", i, Xs[i]/lcf);
			if (outputResult[arrayRankMatch(analyses,"Y\(px\)")]) setResult("Y\(px\)", i, Ys[i]/lcf);
			if (outputResult[arrayRankMatch(analyses,"XM\(px\)")]) setResult("XM\(px\)", i, XMs[i]/lcf);
			if (outputResult[arrayRankMatch(analyses,"YM\(px\)")]) setResult("YM\(px\)", i, YMs[i]/lcf);
			if (outputResult[arrayRankMatch(analyses,"BX\(px\)")]) setResult("BX\(px\)", i, round(BXs[i]/lcf));
			if (outputResult[arrayRankMatch(analyses,"BY\(px\)")]) setResult("BY\(px\)", i, round(BYs[i]/lcf));
			if (outputResult[arrayRankMatch(analyses,"Bounding_Rect_W\(px\)")]) setResult("BoxW\(px\)", i, round(BWs[i]/lcf));
			if (outputResult[arrayRankMatch(analyses,"Bounding_Rect_H\(px\)")]) setResult("BoxH\(px\)", i, round(BHs[i]/lcf));
		}
		if (outputResult[arrayRankMatch(analyses,"Object#")]) setResult("Object#", i, i+1); /* Add Object#+1 column for labels */
		PE = PI * ((3*(Majors[i]/2 + Minors[i]/2)) - sqrt((3*Majors[i]/2 + Minors[i]/2)*(Majors[i]/2 + 3*Minors[i]/2))); /* Perimeter of fitted ellipse from Ramanujan's first approximation */;
		if (outputResult[arrayRankMatch(analyses,"Angle_0-90")]) setResult("Angle_0-90", i, abs(Angles[i]-90));
		if (outputResult[arrayRankMatch(analyses,"FeretAngle_0-90")]) setResult("FeretAngle_0-90", i, abs(FeretAngles[i]-90));
		if (outputResult[arrayRankMatch(analyses,"Convexity")]) setResult("Convexity", i, PE/Ps[i]); /* Convexity using the calculated elliptical fit to obtain a convex perimeter */
		DA = 2*(sqrt(Areas[i]/PI));  /* Adds Darea-equiv (AKA Heywood diameter) while we are at it. */
		if (outputResult[arrayRankMatch(analyses,"D_Area_CircEquiv")]) setResult("Da_equiv" +unitLabel, i, DA); /* adds new Da* column to end of results table - remember no spaces allowed in label. */
		DP = Ps[i]/PI;  /* Adds Dperimeter-equiv while we are at it. */
		if (outputResult[arrayRankMatch(analyses,"D_Perim_CircEquiv")]) setResult("Dp_equiv" +unitLabel, i, DP); /* Adds new Dp* column to end of results table - remember no spaces allowed in label. */
		if (outputResult[arrayRankMatch(analyses,"Dsph_equiv")]) setResult("Dsph_equiv" +unitLabel, i, exp((log(6*Areas[i]*(Ferets[i]+MinFerets[i])/(2*PI)))/3)); /* Adds diameter based on a sphere - Russ page 182 but using the mean Feret diameters to calculate the volume */
		W1 = 1/PI*(Ps[i]-(sqrt(Ps[i]*Ps[i]-4*PI*Areas[i]))); /* Round end ribbon thickness from repeating up/down half-annulus - think snake or perhaps Loch Ness Monster Lee & Jablonski LTSW'94 Devils Head Resort. */
		if (outputResult[arrayRankMatch(analyses,"FiberThk_Snake")]) setResult("FiberThSnk" +unitLabel, i, W1); /* Adds new Ribbon Thickness column to end of results table */
		W2 = Areas[i]/((0.5*Ps[i])-(2*(Areas[i]/Ps[i]))); /* Fiber width from fiber length from John C. Russ Computer Assisted Microscopy page 189. */
		if (outputResult[arrayRankMatch(analyses,"Fiber_Thk_Russ1")]) setResult("FiberThRuss1" +unitLabel, i, W2); /* Adds new fiber width column to end of results table. */
		W3 = Areas[i]/(0.3181*Ps[i]+sqrt(0.033102*Ps[i]*Ps[i]-0.41483*Areas[i])); /* Fiber width from Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		if (outputResult[arrayRankMatch(analyses,"Fiber_Thk_Russ2")]) setResult("FiberThRuss2" +unitLabel, i, W3); /* Adds new fiber width column to end of results table. */
		F1 = Areas[i]/W1; /* Fiber Length from fiber width Lee and Jablonski (John C. Russ  The Image Processing Handbook 7th Ed. Page 612 0.25*(sqrt(P+(P*P-(16*A)))) is incorrect).*/
		if (outputResult[arrayRankMatch(analyses,"Fiber_Lngth_Snake")]) setResult("FiberLSnk" +unitLabel, i, F1); /* Adds new fiber length column to end of results table. */
		F2 = (0.5*Ps[i])-(2*(Areas[i]/Ps[i])); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		if (outputResult[arrayRankMatch(analyses,"Fiber_Lngth_Russ1")]) setResult("FiberLRuss1" +unitLabel, i, F2); /* Adds new fiber length column to end of results table. */
		F3 = 0.3181*Ps[i]+sqrt(0.033102*Ps[i]*Ps[i]-0.41483*Areas[i]); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		if (outputResult[arrayRankMatch(analyses,"Fiber_Lngth_Russ2")]) setResult("FiberLRuss2" +unitLabel, i, F3); /* Adds new fiber length column to end of results table. */
		if (outputResult[arrayRankMatch(analyses,"Fiber_Snake_Curl")]) setResult("FiberSnkCrl", i, BHs[i]/F1); /* Adds Curl for Fiber 1 calculated and bounding length */
		G = Ps[i]/(2*Areas[i]);  /* Calculates Interface Density (e.g. grain boundary density based on the interfaces between objects being shared. */
		if (outputResult[arrayRankMatch(analyses,"Interfacial_Density")]) setResult("Intfc_D" + "\(" + unit + supminus + supone + "\)", i, G); /* Adds new IntD column to end of results table - remember no spaces allowed in label. */
		GL = d2s(G,4); /* Reduce Decimal places for labeling. */
		ARFL1 = F1/W1; /* Aspect ratio from fiber length approximation 1. */
		if (outputResult[arrayRankMatch(analyses,"AR_Fiber_Snake")]) setResult("AR_FiberSnk", i, ARFL1); /* adds fitted ellipse aspect ratio. */
		ARFL2 = F2/W2; /* Aspect ratio from fiber length approximation 2. */
		if (outputResult[arrayRankMatch(analyses,"AR_Fiber_Russ1")]) setResult("AR_FiberRuss1", i, ARFL2); /* adds fitted ellipse aspect ratio. */
		ARFL3 = F3/W3; /* Aspect ratio from fiber length approximation 3. */
		if (outputResult[arrayRankMatch(analyses,"AR_Fiber_Russ2")]) setResult("AR_FiberRuss2", i, ARFL3); /* adds fitted ellipse aspect ratio. */
		Thinnes = 4*PI*Areas[i]/(Ps[i]*Ps[i]); /* see http://imagej.net/Shape_Filter */
		if (outputResult[arrayRankMatch(analyses,"Thinnes_Ratio")]) setResult("Thinnes_Ratio", i, Thinnes); /* adds Thinnes ratio. */
		EXT = Areas[i]/(BWs[i] * BHs[i]); 
		if (outputResult[arrayRankMatch(analyses,"Extent")]) setResult("Extent", i, EXT); /* adds Extent ratio, which is the object area/bounding rectangle area */
		HexSide = sqrt((2*Areas[i])/(3*sqrt(3))); /* Some descriptions for 2D hexagonal close-packed structures */
		if (outputResult[arrayRankMatch(analyses,"Hxgn_Side")]) setResult("HexSide" +unitLabel, i, HexSide); /* adds the length of each hexagonal side */
		if (outputResult[arrayRankMatch(analyses,"Hxgn_Perim")]) setResult("HexPerim" +unitLabel, i, 6 * HexSide); /* adds total perimeter of hexagon */
		HSFideal = 8 * sqrt(3); /* Collin and Grabsch (1982) https://doi.org/10.1111/j.1755-3768.1982.tb05785.x */
		if (outputResult[arrayRankMatch(analyses,"Hxgn_Shape_Factor")]) setResult("HSF", i, abs(((Ps[i] * Ps[i])/Areas[i])-HSFideal)); /* Hexagonal Shape Factor from Behndig et al. https://iovs.arvojournals.org/article.aspx?articleid=2122939 */
		if (outputResult[arrayRankMatch(analyses,"Hxgn_Shape_Factor_R")]) setResult("HSFR", i, abs(HSFideal/((Ps[i] * Ps[i])/Areas[i]))); /* Hexagonal Shape Factor as ratio to the ideal HSF, the value for a perfect hexagon is 1 */
		if (outputResult[arrayRankMatch(analyses,"Hexagonality")]) setResult("Hexagonality", i, 6*HexSide/Ps[i]); /* adds a term to indicate accuracy of hexagon approximation */
		VolPr = (PI/6) * Ferets[i] * MinFerets[i] * MinFerets[i];
		if (outputResult[arrayRankMatch(analyses,"Vol_Pointed_Spheroid")]) setResult("Vol_PtdSphr" + "\(" + unit + supthree + "\)", i, VolPr); /* adds prolate ellipsoid (an American football) volume: Hilliard 1968, Russ p. 189 */
		VolOb = (PI/6) *MinFerets[i] * Ferets[i] * Ferets[i];
		if (outputResult[arrayRankMatch(analyses,"Vol_Discus_Spheroid")]) setResult("Vol_Discus" + "\(" + unit + supthree + "\)", i, VolOb); /* adds oblate ellipsoid (a discus) volume: Hilliard 1968, Russ p. 189 */
	}
	updateResults();
	setBatchMode("exit & display"); /* exit batch mode */
	showStatus("Additional Geometries Macro Finished for: " + nResults + "Objects");
	beep(); wait(300); beep(); wait(100); beep();
	run("Collect Garbage");
}
	/*
	( 8(|)  ( 8(|)  All ASC Functions    @@@@@:-)  @@@@@:-)
	*/

	function arrayRankMatch(array,string) {
		/* 1st version 8/9/2018 3:07 PM PJL */
		rank = NaN;
		for (i=0; i<array.length; i++)
			if (array[i] == string) rank = i;
		if (rank == NaN) exit("Error in analysis title match");
		return rank;
	}
	function arrayToString(array,delimiters){
		/* 1st version April 2019 PJL */
		for (i=0; i<array.length; i++){
			if (i==0) string = "" + array[0];
			else  string = string + delimiters + array[i];
		}
		return string;
	}
	/*
				Required ImageJ Functions
	*/
	function requires152m() {requires("1.52m"); return 0; }
