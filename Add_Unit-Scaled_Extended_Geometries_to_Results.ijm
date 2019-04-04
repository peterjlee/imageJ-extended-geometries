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
	v190404 Removed redundant code. Prefs path moved from busy Macro directory to "info" sub-directory. Added HSF and HSFR.
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
	
	analyses1 = newArray("C_Tilt","AR_Box","AR_Feret","Round_Feret","Compact_Feret", "Feret_Coords");
	analyses2 = newArray("X\(px\)","Y\(px\)","YM\(px\)","YM\(px\)","BX\(px\)","BY\(px\)","BoxW\(px\)","BoxH\(px\)");
	analyses3 = newArray("Object#","Angle_0-90","FeretAngle_0-90","Convexity","Da_equiv","Dp_equiv","Dsph_equiv","FiberThAnn","FiberThRuss1","FiberThRuss2","FiberLAnn","FiberLRuss1","FiberLRuss2","CurlF1","IntD","AR_Fiber","AR_FiberRuss1","AR_FiberRuss2","T_Ratio","Extent","HexSide","HexPerim","HSF", "HSFR", "Hexagonality","VolPr","VolOb");
	if (lcf!=1) {
		analyses = Array.concat(analyses1,analyses2,analyses3);
		prefsPath = userPath + "\\macros\\info\\ExtGeoPrefs_LCF.txt";
	}
	else {
		analyses = Array.concat(analyses1,analyses3);
		prefsPath = userPath + "\\macros\\info\\ExtGeoPrefs.txt";
	}
	if (File.exists(prefsPath)) lastUsedPrefs = import1ColPrefsToArray(prefsPath);
	if (analyses.length==lastUsedPrefs.length) outputResult = lastUsedPrefs; /* if new measurements are added the prefs are reset */
	else {
		outputResult = newArray(analyses.length);
		for (i=0; i<analyses.length; i++) outputResult[i]=true;
		/* Example of how to uncheck analyses that you do not think should be default inclusions. */ 
		outputResult[arrayRankMatch(analyses,"FiberThRuss1")] = false;
		outputResult[arrayRankMatch(analyses,"FiberLRuss1")] = false;
		outputResult[arrayRankMatch(analyses,"AR_FiberRuss1")] = false;
		outputResult[arrayRankMatch(analyses,"VolPr")] = false;
		outputResult[arrayRankMatch(analyses,"VolOb")] = false;
	}
	if (analyses.length!=outputResult.length) exit("analyses.length = " + analyses.length + " but outputResult.length = " + outputResult.length);
	checkboxGroupColumns = 5;
	checkboxGroupRows = round(analyses.length/checkboxGroupColumns)+1; /* Add +1 to make sure that there are enough cells */
	Dialog.create("Select Extended Geometrical Analyses");
	if (File.exists(prefsPath)) Dialog.addMessage("Previous selections were loaded from:\n" + prefsPath);
	if (roiManager("count")!=nResults) {
		outputResult[arrayRankMatch(analyses,"Feret_Coords")] = false;
		Dialog.addMessage("Extended Feret Coords requires ROIs");
	}
	Dialog.addCheckboxGroup(checkboxGroupRows,checkboxGroupColumns,analyses,outputResult);
	Dialog.addMessage("Preferences will be saved at:\n" + prefsPath);
	Dialog.show();
	for (i=0; i<outputResult.length; i++) outputResult[i] = Dialog.getCheckbox();
	Array.show(outputResult);
	if (lcf!=1) {
		saveAs("Results", userPath + "\\macros\\ExtGeoPrefs_LCF.txt");
		close("ExtGeoPrefs_LCF.txt");
	}
	else {
		saveAs("Results", userPath + "\\macros\\ExtGeoPrefs.txt");
		close("ExtGeoPrefs.txt");		
	}
	/* Note that the AR reported by ImageJ is the ratio of the fitted ellipse major and minor axes. */
	if (outputResult[arrayRankMatch(analyses,"C_Tilt")]) {Table.applyMacro("C_Tilt=(180/PI) * acos(1/AR)");} /* The angle a circle (cylinder in 3D) would be tilted to appear as an ellipse with this AR */
	if (outputResult[arrayRankMatch(analyses,"AR_Box")]) {Table.applyMacro("AR_Box=maxOf(Height/Width, Width/Height)");} /* Bounding rectangle aspect ratio */
	if (outputResult[arrayRankMatch(analyses,"AR_Feret")]) {Table.applyMacro("AR_Feret=Feret/MinFeret");} /* adds fitted ellipse aspect ratio. */
	if (outputResult[arrayRankMatch(analyses,"Round_Feret")]) {Table.applyMacro("Round_Feret=4*Area/(PI * Feret * Feret)");} /* Adds Roundness, using Feret as maximum diameter (IJ Analyze uses ellipse major axis */
	if (outputResult[arrayRankMatch(analyses,"Compact_Feret")]) {Table.applyMacro("Compact_Feret=(sqrt(Area*4/PI))/Feret");} /* Adds Compactness, using Feret as maximum diameter */
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
			if (outputResult[arrayRankMatch(analyses,"BoxW\(px\)")]) setResult("BoxW\(px\)", i, round(BWs[i]/lcf));
			if (outputResult[arrayRankMatch(analyses,"BoxH\(px\)")]) setResult("BoxH\(px\)", i, round(BHs[i]/lcf));
		}
		if (outputResult[arrayRankMatch(analyses,"Object#")]) setResult("Object#", i, i+1); /* Add Object#+1 column for labels */
		PE = PI * ((3*(Majors[i]/2 + Minors[i]/2)) - sqrt((3*Majors[i]/2 + Minors[i]/2)*(Majors[i]/2 + 3*Minors[i]/2))); /* Perimeter of fitted ellipse from Ramanujan's first approximation */;
		if (outputResult[arrayRankMatch(analyses,"Angle_0-90")]) setResult("Angle_0-90", i, abs(Angles[i]-90));
		if (outputResult[arrayRankMatch(analyses,"FeretAngle_0-90")]) setResult("FeretAngle_0-90", i, abs(FeretAngles[i]-90));
		if (outputResult[arrayRankMatch(analyses,"Convexity")]) setResult("Convexity", i, PE/Ps[i]); /* Convexity using the calculated elliptical fit to obtain a convex perimeter */
		DA = 2*(sqrt(Areas[i]/PI));  /* Adds Darea-equiv (AKA Heywood diameter) while we are at it. */
		if (outputResult[arrayRankMatch(analyses,"Da_equiv")]) setResult("Da_equiv" +unitLabel, i, DA); /* adds new Da* column to end of results table - remember no spaces allowed in label. */
		DP = Ps[i]/PI;  /* Adds Dperimeter-equiv while we are at it. */
		if (outputResult[arrayRankMatch(analyses,"Dp_equiv")]) setResult("Dp_equiv" +unitLabel, i, DP); /* Adds new Dp* column to end of results table - remember no spaces allowed in label. */
		if (outputResult[arrayRankMatch(analyses,"Dsph_equiv")]) setResult("Dsph_equiv" +unitLabel, i, exp((log(6*Areas[i]*(Ferets[i]+MinFerets[i])/(2*PI)))/3)); /* Adds diameter based on a sphere - Russ page 182 but using the mean Feret diameters to calculate the volume */
		W1 = 1/PI*(Ps[i]-(sqrt(Ps[i]*Ps[i]-4*PI*Areas[i]))); /* Round end ribbon thickness from repeating half-annulus - Lee & Jablonski LTSW'94 Devils Head Resort. */
		if (outputResult[arrayRankMatch(analyses,"FiberThAnn")]) setResult("FiberThAnn" +unitLabel, i, W1); /* Adds new Ribbon Thickness column to end of results table */
		W2 = Areas[i]/((0.5*Ps[i])-(2*(Areas[i]/Ps[i]))); /* Fiber width from fiber length from John C. Russ Computer Assisted Microscopy page 189. */
		if (outputResult[arrayRankMatch(analyses,"FiberThRuss1")]) setResult("FiberThRuss1" +unitLabel, i, W2); /* Adds new fiber width column to end of results table. */
		W3 = Areas[i]/(0.3181*Ps[i]+sqrt(0.033102*Ps[i]*Ps[i]-0.41483*Areas[i])); /* Fiber width from Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		if (outputResult[arrayRankMatch(analyses,"FiberThRuss2")]) setResult("FiberThRuss2" +unitLabel, i, W3); /* Adds new fiber width column to end of results table. */
		F1 = Areas[i]/W1; /* Fiber Length from fiber width Lee and Jablonski (John C. Russ  The Image Processing Handbook 7th Ed. Page 612 0.25*(sqrt(P+(P*P-(16*A)))) is incorrect).*/
		if (outputResult[arrayRankMatch(analyses,"FiberLAnn")]) setResult("FiberLAnn" +unitLabel, i, F1); /* Adds new fiber length column to end of results table. */
		F2 = (0.5*Ps[i])-(2*(Areas[i]/Ps[i])); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		if (outputResult[arrayRankMatch(analyses,"FiberLRuss1")]) setResult("FiberLRuss1" +unitLabel, i, F2); /* Adds new fiber length column to end of results table. */
		F3 = 0.3181*Ps[i]+sqrt(0.033102*Ps[i]*Ps[i]-0.41483*Areas[i]); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		if (outputResult[arrayRankMatch(analyses,"FiberLRuss2")]) setResult("FiberLRuss2" +unitLabel, i, F3); /* Adds new fiber length column to end of results table. */
		if (outputResult[arrayRankMatch(analyses,"CurlF1")]) setResult("CurlF1", i, BHs[i]/F1); /* Adds Curl for Fiber 1 calculated and bounding length */
		G = Ps[i]/(2*Areas[i]);  /* Calculates Interface Density (e.g. grain boundary density based on the interfaces between objects being shared. */
		if (outputResult[arrayRankMatch(analyses,"IntD")]) setResult("IntD" + "\(" + unit + supminus + supone + "\)", i, G); /* Adds new IntD column to end of results table - remember no spaces allowed in label. */
		GL = d2s(G,4); /* Reduce Decimal places for labeling. */
		ARFL1 = F1/W1; /* Aspect ratio from fiber length approximation 1. */
		if (outputResult[arrayRankMatch(analyses,"AR_Fiber")]) setResult("AR_Fiber", i, ARFL1); /* adds fitted ellipse aspect ratio. */
		ARFL2 = F2/W2; /* Aspect ratio from fiber length approximation 2. */
		if (outputResult[arrayRankMatch(analyses,"AR_FiberRuss1")]) setResult("AR_FiberRuss1", i, ARFL2); /* adds fitted ellipse aspect ratio. */
		ARFL3 = F3/W3; /* Aspect ratio from fiber length approximation 3. */
		if (outputResult[arrayRankMatch(analyses,"AR_FiberRuss2")]) setResult("AR_FiberRuss2", i, ARFL3); /* adds fitted ellipse aspect ratio. */
		Thinnes = 4*PI*Areas[i]/(Ps[i]*Ps[i]); /* see http://imagej.net/Shape_Filter */
		if (outputResult[arrayRankMatch(analyses,"T_Ratio")]) setResult("T_Ratio", i, Thinnes); /* adds Thinnes ratio. */
		EXT = Areas[i]/(BWs[i] * BHs[i]); 
		if (outputResult[arrayRankMatch(analyses,"Extent")]) setResult("Extent", i, EXT); /* adds Extent ratio, which is the object area/bounding rectangle area */
		HexSide = sqrt((2*Areas[i])/(3*sqrt(3))); /* Some descriptions for 2D hexagonal close-packed structures */
		if (outputResult[arrayRankMatch(analyses,"HexSide")]) setResult("HexSide" +unitLabel, i, HexSide); /* adds the length of each hexagonal side */
		if (outputResult[arrayRankMatch(analyses,"HexPerim")]) setResult("HexPerim" +unitLabel, i, 6 * HexSide); /* adds total perimeter of hexagon */
		HSFideal = 8 * sqrt(3); /* Collin and Grabsch (1982) https://doi.org/10.1111/j.1755-3768.1982.tb05785.x */
		if (outputResult[arrayRankMatch(analyses,"HSF")]) setResult("HSF", i, abs(((Ps[i] * Ps[i])/Areas[i])-HSFideal)); /* Hexagonal Shape Factor from Behndig et al. https://iovs.arvojournals.org/article.aspx?articleid=2122939 */
		if (outputResult[arrayRankMatch(analyses,"HSFR")]) setResult("HSFR", i, abs(HSFideal/((Ps[i] * Ps[i])/Areas[i]))); /* Hexagonal Shape Factor as ratio to the ideal HSF, the value for a perfect hexagon is 1 */
		if (outputResult[arrayRankMatch(analyses,"Hexagonality")]) setResult("Hexagonality", i, 6*HexSide/Ps[i]); /* adds a term to indicate accuracy of hexagon approximation */
		VolPr = (PI/6) * Ferets[i] * MinFerets[i] * MinFerets[i];
		if (outputResult[arrayRankMatch(analyses,"VolPr")]) setResult("VolPr" + "\(" + unit + supthree + "\)", i, VolPr); /* adds prolate ellipsoid (an American football) volume: Hilliard 1968, Russ p. 189 */
		VolOb = (PI/6) *MinFerets[i] * Ferets[i] * Ferets[i];
		if (outputResult[arrayRankMatch(analyses,"VolOb")]) setResult("VolOb" + "\(" + unit + supthree + "\)", i, VolOb); /* adds oblate ellipsoid (a discus) volume: Hilliard 1968, Russ p. 189 */
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
	function import1ColPrefsToArray(savePath) {
		/* 1st version 3/19/2019 11:16 AM PJL
			v190403
		*/
		if (File.exists(savePath)) {
			prefsString=File.openAsString(savePath); 
			prefsList=split(prefsString, "\n");
			if (prefsList[0]=="Value") prefsList = Array.slice(prefsList,1,prefsList.length);
		}
		else print("Could not find " + savePath);
		return prefsList;
	}
	/*
				Required ImageJ Functions
	*/
	function requires152m() {requires("1.52m"); return 0; }
