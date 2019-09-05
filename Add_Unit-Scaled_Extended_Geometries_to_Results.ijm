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
	v190404 Removed redundant code. Prefs path moved from busy Macro directory to "info" sub-directory. Added HxgnShapeFactor and HxgnShapeFactorR.
	v190430-v190501 prefs moved to imageJ prefs. Please delete old copies of ..\macros\info\ExtGeoPrefs_LCF.txt
		Changed measurement naming philosophy (column titles stay abbreviated to keep column widths narrow but in the dialog selection box the geometry names expanded so that they are a little bit more descriptive. Some of the output names were changed too.
	v190815 Help button provides more information on each measurement.
	v190830 Corrected Thinnes ratio (which was inverted :-$ ). Redefined Elongation to 1 - (short box side/long box side). Added Circularity corrected by aspect ratio (Takashimizu and Iiyoshi). Abbreviated some names and made code more efficient.
	v190904-v190905 Now works uses table values exclusively rather than Results.
	*/
macro "Add Additional Geometrical Analyses to Results" {
	requires("1.52m"); /*Uses the new ROI.getFeretPoints released in 1.52m */
	if (getValue("results.count")==0) exit("No Table to work with");
	tableTitle = Table.title;
	tableHeadings = Table.headings;
	tableColumns = split(tableHeadings);
	// Array.print(tableColumns);
	defaultAllHeadings = Table.allHeadings;
	defaultAllColumns = split(defaultAllHeadings);
	// Array.print(defaultAllColumns);
	nDResults = lengthOf(defaultAllColumns);
	nHResults = lengthOf(tableColumns);
	nMissingResults = nDResults - nHResults;
	missingResults = "";
	if (nMissingResults>0){
		for (i=0; i<nDResults; i++) {
			dAC = defaultAllColumns[i];
			if (dAC!="Ch" && dAC!="Frame" && dAC!="MinThr" && dAC!="MaxThr"){
				if (arrayRankMatch3(tableColumns,defaultAllColumns[i],-1)<0) missingResults += defaultAllColumns[i] + ", ";
			}
		}
		if (missingResults!="") showMessageWithCancel("The table does not have " + missingResults + ": Continue?");
	}
	// else if (nMissingResults<0) showMessageWithCancel("The table has more columns than the default all-measurements; continue?");
	nTable = Table.size;
	userPath = getInfo("user.dir");
	prefsDelimiter = "|";
	selectWindow(tableTitle);
	// setBatchMode(true); /* batch mode on*/
	if (nImages!=0) getPixelSize(unit, pixelWidth, pixelHeight);
	else {
		Dialog.create("No images open, please enter unit values");
			Dialog.addRadioButtonGroup("Perhaps there should be an open image?", newArray("continue","exit"),2,1,"continue");
			Dialog.addNumber("pixel width",1,10,10,"units");
			Dialog.addNumber("pixel height",1,10,10,"units");
			unitChoices = newArray("m","cm","mm","µm","microns","nm","Å","pm","inches");
			Dialog.addChoice("units",unitChoices,"pixels");
			Dialog.show;
			if (Dialog.getRadioButton=="exit") exit;
			pixelWidth = Dialog.getNumber;
			pixelHeight = Dialog.getNumber;
			unit = Dialog.getChoice;
	}
	lcf = (pixelWidth + pixelHeight)/2;
	unitLabel = "\(" + unit + "\)";
	
	supminus = fromCharCode(0xFE63); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
	supone = fromCharCode(0x00B9); /* UTF-16 (hex) C/C++/Java source code 	"\u00B9" */
	suptwo = fromCharCode(0x00B2); /* UTF-16 (hex) C/C++/Java source code 	"\u00B2" */
	supthree = fromCharCode(0x00B2); /* UTF-16 (hex) C/C++/Java source code 	"\u00B3" */
	sqroot = fromCharCode(0x221A); /* UTF-16 (hex) */
	
	 html = "<html>"
	 +"<font color=blue size=+1>Additional Aspect Ratios:</font><br />"
	 +"<font color=green> \"AR Bounding Rect\"</font>: Aspect ratio from bounding rectangle.<br />"
	 +"<font color=green> \"AR Feret\"</font>: Aspect ratio Feret diameters\( max\/min\).<br />"
	 +"<font color=blue size=+1>Additional Feret Diameter derived geometries:</font><br />"
		+"<font color=green> \"Feret Coordinates\"</font>: Coordinates for both min and max Feret diameters.<br />"
		+"<font color=green>\"Compactness_Feret\"</font> (using Feret diameter as maximum diameter),<br />"
		+"<font color=green>0-90 degree resolved angles:</font> for \"Angle\" and \"Feret Angle\"<br />"
     +"<font color=blue size=+1>Interfacial density</font> (assuming each interface is shared by two objects - e.g. grain boundary density).<br />"
	 +"<font color=blue size=+1>CircToEllipse Tilt:</font> Angle that a circle would have to be tilted to match measured ellipse.<br />"
	 +"<font color=blue size=+1>Pixel coordinates:</font> Coordinates and bounding box values converted to pixels.<br />"
     +"<font color=blue size=+1>Area equivalent diameter</font>\(AKA Heywood diameter\):<br />"
	 +"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; The \"diameter\" of an object obtained from the area assuming a circular geometry.<br />"
	 +"<font color=blue size=+1>Perimeter equivalent diameter</font>: Calculated from the perimeter  assuming a circular geometry.<br />"
	 +"<font color=blue size=+1>Spherical equivalent diameter</font>: Calculated from the volume of a sphere (Russ page 182)<br />"
	 +"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; but using the mean projected Feret diameters to calculate the volume.<br />"
	 +"<font color=blue size=+1>Fiber geometries</font>:<br />"
	 +"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color=green>Snake ribbon thickness estimates</font> from repeating half-annulus (Lee & Jablonski LTSW'94).<br />"
	 +"<font color=blue size=+1>Fiber widths</font> estimated obtained from the fiber length from [1] page 189.<br />"
	 +"<font color=blue size=+1>Fiber length</font> from fiber width (Lee and Jablonski LTSW'94; modified from the formula in [2] Page 612.<br />"
	 +"<font color=blue size=+1>Fiber lengths</font> from Russ formulae.<br />"
	 +"<font color=blue size=+1>Volumetric estimates from projections</font> obtained from the formulae in [1] 189.<br />"
	 +"<font color=blue size=+1>Additional shape factors</font>:<br />"
	 +"<font color=green>\"Convexity\"</font>: using the calculated elliptical fit to obtain a convex perimeter, https://imagej.net/Shape_Filter<br />"
	 +"<font color=green>\"Elongation\"</font> = 1 - 1/Bounding Rectangle Aspect Ratio see https://imagej.net/Shape_Filter<br />"
	 +"<font color=green>\"Roundnesss_cAR\"</font> Circularity corrected by aspect ratio,<br />"
	 +"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Takashimizu and Iiyoshi Progress in Earth and Planetary Science (2016) 3:2<br />"
	 +"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; https://doi.org/DOI 10.1186/s40645-015-0078-x<br />"
	 +"<font color=green> \"Thinnes ratio\"</font> inverse of circularity see https://imagej.net/Shape_Filter<br />"
	 +"<font color=green> \"Extent ratio\"</font> object area/bounding rectangle area */,<br />"
	 +"<font color=green> \"Curl\"</font> Fiber length/length of bounding box<br />"
	 +"<font color=blue size=+1>Hexagonal geometries</font> more appropriate to close-packed structures than ellipses:<br />"
	 +"<font color=green>HxgnSide</font> ="+sqroot+"\(\(2*Area\)/\(3*"+sqroot+"3\)\)<br />"
	 +"<font color=green>HexPerimeter</font> = 6 * HxgnSide<br />"
	 +"<font color=green>Hexagonal Shape Factor</font> \"HSF\" = |\(P"+suptwo+"\/Area-13.856\)| <br />"
	 +"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Hexagonal Shape Factor from Behndig et al. https://iovs.arvojournals.org/article.aspx?articleid=2122939 <br />"
	 +"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; and Collin and Grabsch (1982) https://doi.org/10.1111/j.1755-3768.1982.tb05785.x <br />"
	 +"<font color=green>Hexagonal Shape Factor Ratio</font> \"HSFR\" = |\(13.856/\(P"+suptwo+"\/Area\)\)|    <br /> as above but expressed as a ratio like circularity, with 1 being an ideal hexagon.<br />"
	 +"<font color=green>HexPerimeter</font> = 6 * HxgnSide</font><br />"
	 +"<font color=green>Hexagonality</font> = 6 * HxgnSide/Perimeter</font><br />"
	 +"<font color=blue>Full Feret coordinate listing</font> using new Roi.getFeretPoints macro function added in ImageJ 1.52m.<br />"
	 +"Preferences are automatically saved and retrieved from the IJ_prefs file so that favorite geometries can be retained.<br />"
	 +"[1] John C. Russ, Computer Assisted Microscopy.<br />"
	 +"[2] John C. Russ, Image Processing Handbook 7th Ed.<br />";

	resultsNeeded = newArray("AR","Area","Width","Height","Feret","minFeret","Circ.","X","Y","XM","YM","BX","BY","Perim.","Major","Minor","Angle","FeretAngle");
	missing = 0;
	resultsMissing = "";
	for (i=0; i<lengthOf(resultsNeeded); i++) {
		if (arrayRankMatch3(tableColumns,resultsNeeded[i],-1)<0) {
			resultsMissing += resultsNeeded[i] + ", ";
			missing += 1;
		}
	}
	if (missing > 0) exit("" + missing + " required columns " + resultsMissing + " are missing");
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
	ARs = Table.getColumn("AR");
	Angles = Table.getColumn("Angle");
	Cs = Table.getColumn("Circ.");
	FeretAngles = Table.getColumn("FeretAngle");
	/* The measurements are split into groups for organization purposes and then recombined for simplicity of use with Dialog.addCheckboxGroup */
	analysesF = newArray("AR_Bounding_Rect","AR_Feret","Roundness_Feret","Compactness_Feret", "Feret_Coords");
	analysesA = newArray("Angle_0-90", "FeretAngle_0-90","CircToEllipse_Tilt");
	analysesPx = newArray("X\(px\)","Y\(px\)","YM\(px\)","YM\(px\)","BX\(px\)","BY\(px\)","Bounding_Rect_W\(px\)","Bounding_Rect_H\(px\)");
	analysesD = newArray("D_Area_CircEquiv","D_Perim_CircEquiv","Dsph_equiv");
	analysesB = newArray("FiberThk_Snake","Fiber_Thk_Russ1","Fiber_Thk_Russ2","Fiber_Lngth_Snake","Fiber_Lngth_Russ1","Fiber_Lngth_Russ2","Fiber_Snake_Curl","Fiber_Russ1_Curl","Fiber_Russ2_Curl","AR_Fiber_Snake","AR_Fiber_Russ1","AR_Fiber_Russ2");
	analysesH = newArray("Hxgn_Side","Hxgn_Perim","Hxgn_Shape_Factor", "Hxgn_Shape_Factor_R", "Hexagonality");
	analysesM = newArray("Object#","Convexity","Elongation","Roundness_cAR","Interfacial_Density","Thinnes_Ratio","Extent");
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
		lastUsedAnalyses = split(prefsAnalyses,prefsDelimiter);
		lastUsedAnalysesOn = split(prefsAnalysesOn,prefsDelimiter);
		if (analyses.length==lastUsedAnalysesOn.length) outputResult = lastUsedAnalysesOn; /* if new measurements are added the prefs are reset */
		else {
			outputResult = newArray(analyses.length);
			Dialog.create("Reset analysis selections");
			Dialog.addRadioButtonGroup("Choose reset mode \(all analyses or none\):",newArray("all","none"),1,2,"all");
			Dialog.show;
			if (Dialog.getRadioButton=="none")	outputResult = Array.fill(outputResult, false);
			else outputResult = Array.fill(outputResult, true);
		}
	}
	else {
		outputResult = newArray(analyses.length);
		outputResult = Array.fill(outputResult, true);
		/* Example of how to uncheck analyses that you do not think should be default inclusions. */ 
		defaultOffs = newArray("Fiber_Thk_Russ1","Fiber_Lngth_Russ1","AR_Fiber_Russ1","Fiber_Russ1_Curl","Vol_Pointed_Spheroid","Vol_Discus_Spheroid");
		for (i=0; i<lengthOf(defaultOffs); i++)	outputResult[arrayRankMatch3(analyses,defaultOffs[i],NaN)] = false;
	}
	if (analyses.length!=outputResult.length) exit("analyses.length = " + analyses.length + " but outputResult.length = " + outputResult.length);
	checkboxGroupColumns = 5;
	checkboxGroupRows = round(analyses.length/checkboxGroupColumns)+1; /* Add +1 to make sure that there are enough cells */
	Dialog.create("Select Extended Geometrical Analyses");
		if (roiManager("count")!=nTable) {
			outputResult[arrayRankMatch3(analyses,"Feret_Coords",NaN)] = false;
			Dialog.addMessage("Extended Feret Coords requires ROIs");
		}
		Dialog.addCheckboxGroup(checkboxGroupRows,checkboxGroupColumns,analyses,outputResult);
		Dialog.addRadioButtonGroup("Set preferences for next run:", newArray("Use these settings", "select all", "reset"),3,1,"Use these settings");
		Dialog.addHelp(html);
		Dialog.show();
		for (i=0; i<outputResult.length; i++) outputResult[i] = Dialog.getCheckbox();
		analysesPrefsKey = prefsNameKey+"Analyses";
		analysesOnPrefsKey = prefsNameKey+"AnalysesOn";
		nextRunSettings = Dialog.getRadioButton();
		if (nextRunSettings=="reset") {
			call("ij.Prefs.set", analysesPrefsKey, "None");
			call("ij.Prefs.set", analysesOnPrefsKey, "None");
			print("prefs reset");
		}
		else {
			if (nextRunSettings=="select all") for (i=0;i<lengthOf(analyses); i++) outputResult[i] = true;
			analysesString = arrayToString(analyses,prefsDelimiter);
			analysesOnString = arrayToString(outputResult,prefsDelimiter);
			call("ij.Prefs.set", analysesPrefsKey, analysesString);
			call("ij.Prefs.set", analysesOnPrefsKey, analysesOnString);
		}
	/* Note that the AR reported by ImageJ is the ratio of the fitted ellipse major and minor axes. */
	if (outputResult[arrayRankMatch3(analyses,"CircToEllipse_Tilt",NaN)]) {Table.applyMacro("Cir_to_El_Tilt=(180/PI) * acos(1/AR)");} /* The angle a circle (cylinder in 3D) would be tilted to appear as an ellipse with this AR */
	if (outputResult[arrayRankMatch3(analyses,"AR_Bounding_Rect",NaN)]) {Table.applyMacro("AR_Box=maxOf(Height/Width, Width/Height)");} /* Bounding rectangle aspect ratio */
	if (outputResult[arrayRankMatch3(analyses,"AR_Feret",NaN)]) {Table.applyMacro("AR_Feret=Feret/MinFeret");} /* adds fitted ellipse aspect ratio. */
	if (outputResult[arrayRankMatch3(analyses,"Roundness_Feret",NaN)]) {Table.applyMacro("Rnd_Feret=4*Area/(PI * pow(Feret,2))");} /* Adds Roundness, using Feret as maximum diameter (IJ Analyze uses ellipse major axis */
	if (outputResult[arrayRankMatch3(analyses,"Compactness_Feret",NaN)]) {Table.applyMacro("Compact_Feret=(sqrt(Area*4/PI))/Feret");} /* Adds Compactness, using Feret as maximum diameter */
	if (outputResult[arrayRankMatch3(analyses,"Elongation",NaN)]) {Table.applyMacro("Elong = 1-(minOf(Height/Width, Width/Height))");} /* Elongation see https://imagej.net/Shape_Filter */
	if (outputResult[arrayRankMatch3(analyses,"Thinnes_Ratio",NaN)]) {
		Table.renameColumn("Circ.", "Circ"); /* New table functions do not accept periods in names */
		Table.applyMacro("Thinnes_Ratio = 1/Circ"); /* adds Thinnes ratio. */ 
		Table.renameColumn("Circ", "Circ.");
	}
	setBatchMode(true);
	for (i=0; i<nTable; i++) {
		BS = minOf(BWs[i],BHs[i]);
		BL = maxOf(BWs[i],BHs[i]);
		BAR = BL/BS;
		if((roiManager("count")==nTable) && outputResult[arrayRankMatch3(analyses,"Feret_Coords",NaN)]) {
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
			if (outputResult[arrayRankMatch3(analyses,"X\(px\)",NaN)]) setResult("X\(px\)", i, Xs[i]/lcf);
			if (outputResult[arrayRankMatch3(analyses,"Y\(px\)",NaN)]) setResult("Y\(px\)", i, Ys[i]/lcf);
			if (outputResult[arrayRankMatch3(analyses,"XM\(px\)",NaN)]) setResult("XM\(px\)", i, XMs[i]/lcf);
			if (outputResult[arrayRankMatch3(analyses,"YM\(px\)",NaN)]) setResult("YM\(px\)", i, YMs[i]/lcf);
			if (outputResult[arrayRankMatch3(analyses,"BX\(px\)",NaN)]) setResult("BX\(px\)", i, round(BXs[i]/lcf));
			if (outputResult[arrayRankMatch3(analyses,"BY\(px\)",NaN)]) setResult("BY\(px\)", i, round(BYs[i]/lcf));
			if (outputResult[arrayRankMatch3(analyses,"Bounding_Rect_W\(px\)",NaN)]) setResult("BoxW\(px\)", i, round(BWs[i]/lcf));
			if (outputResult[arrayRankMatch3(analyses,"Bounding_Rect_H\(px\)",NaN)]) setResult("BoxH\(px\)", i, round(BHs[i]/lcf));
		}
		if (outputResult[arrayRankMatch3(analyses,"Object#",NaN)]) setResult("Object#", i, i+1); /* Add Object#+1 column for labels */
		if (outputResult[arrayRankMatch3(analyses,"Angle_0-90",NaN)]) setResult("Angle_0-90", i, abs(Angles[i]-90));
		if (outputResult[arrayRankMatch3(analyses,"FeretAngle_0-90",NaN)]) setResult("Ft_Ang_0-90", i, abs(FeretAngles[i]-90));
		if (outputResult[arrayRankMatch3(analyses,"Convexity",NaN)]){
			PE = PI * ((3*(Majors[i]/2 + Minors[i]/2)) - sqrt((3*Majors[i]/2 + Minors[i]/2)*(Majors[i]/2 + 3*Minors[i]/2))); /* Perimeter of fitted ellipse from Ramanujan's first approximation */;
			setResult("Conv.", i, PE/Ps[i]); /* Convexity using the calculated elliptical fit to obtain a convex perimeter */			
		}
		if (outputResult[arrayRankMatch3(analyses,"Roundness_cAR",NaN)]){
			cAR = 0.826261 + 0.337479 * ARs[i]-0.335455 * pow(ARs[i],2) + 0.103642 * pow(ARs[i],3) - 0.0155562 * pow(ARs[i],4) + 0.00114582 * pow(ARs[i],5) - 0.0000330834 * pow(ARs[i],6);
			setResult("Roundness_cAR", i, Cs[i] + 0.913 - cAR); /* Circularity corrected by aspect ratio roundness: https://doi.org/10.1186/s40645-015-0078-x */
		}
		if (outputResult[arrayRankMatch3(analyses,"D_Area_CircEquiv",NaN)])
			setResult("Da_equiv" +unitLabel, i, 2*(sqrt(Areas[i]/PI))); /* Darea-equiv (AKA Heywood diameter) - remember no spaces allowed in label. */
		if (outputResult[arrayRankMatch3(analyses,"D_Perim_CircEquiv",NaN)])
			setResult("Dp_equiv" +unitLabel, i, Ps[i]/PI); /* Adds new perimeter-equivalent Diameter column to end of results table - remember no spaces allowed in label. */
		if (outputResult[arrayRankMatch3(analyses,"Dsph_equiv",NaN)])
			setResult("Dsph_equiv" +unitLabel, i, exp((log(6*Areas[i]*(Ferets[i]+MinFerets[i])/(2*PI)))/3)); /* Adds diameter based on a sphere - Russ page 182 but using the mean Feret diameters to calculate the volume */
		if (outputResult[arrayRankMatch3(analyses,"Fiber",NaN)]) {
			W1 = 1/PI*(Ps[i]-(sqrt(Ps[i]*Ps[i]-4*PI*Areas[i]))); /* Round end ribbon thickness from repeating up/down half-annulus - think snake or perhaps Loch Ness Monster Lee & Jablonski LTSW'94 Devils Head Resort. */
			W2 = Areas[i]/((0.5*Ps[i])-(2*(Areas[i]/Ps[i]))); /* Fiber width from fiber length from John C. Russ Computer Assisted Microscopy page 189. */
			W3 = Areas[i]/(0.3181*Ps[i]+sqrt(0.033102*Ps[i]*Ps[i]-0.41483*Areas[i])); /* Fiber width from Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */		
			F1 = Areas[i]/W1; /* Fiber Length from fiber width Lee and Jablonski (John C. Russ  The Image Processing Handbook 7th Ed. Page 612 0.25*(sqrt(P+(P*P-(16*A)))) is incorrect).*/
			F2 = (0.5*Ps[i])-(2*(Areas[i]/Ps[i])); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
			F3 = 0.3181*Ps[i]+sqrt(0.033102*Ps[i]*Ps[i]-0.41483*Areas[i]); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		}
		if (outputResult[arrayRankMatch3(analyses,"Hex",NaN)] || outputResult[arrayRankMatch3(analyses,"Hxg",NaN)]){
			HxgnSide = sqrt((2*Areas[i])/(3*sqrt(3))); /*the length of each hexagonal side */
			Ps2A = pow(Ps[i],2)/Areas[i];
			HSFideal = 8 * sqrt(3); /* Collin and Grabsch (1982) https://doi.org/10.1111/j.1755-3768.1982.tb05785.x */
		}
		if (outputResult[arrayRankMatch3(analyses,"FiberThk_Snake",NaN)])
			setResult("FbrThSnk" +unitLabel, i, W1); /* Adds new Ribbon Thickness column to end of results table */
		if (outputResult[arrayRankMatch3(analyses,"Fiber_Thk_Russ1",NaN)])
			setResult("FbrThRss1" +unitLabel, i, W2); /* Adds new fiber width column to end of results table. */
		if (outputResult[arrayRankMatch3(analyses,"Fiber_Thk_Russ2",NaN)])
			setResult("FbrThRss2" +unitLabel, i, W3); /* Adds new fiber width column to end of results table. */
		if (outputResult[arrayRankMatch3(analyses,"Fiber_Lngth_Snake",NaN)])
			setResult("FbrLSnk" +unitLabel, i, F1); /* Adds new fiber length column to end of results table. */
		if (outputResult[arrayRankMatch3(analyses,"Fiber_Lngth_Russ1",NaN)])
			setResult("FbrLRss1" +unitLabel, i, F2); /* Adds new fiber length column to end of results table. */
		if (outputResult[arrayRankMatch3(analyses,"Fiber_Lngth_Russ2",NaN)])
			setResult("FbrLRss2" +unitLabel, i, F3); /* Adds new fiber length column to end of results table. */
		if (outputResult[arrayRankMatch3(analyses,"Fiber_Snake_Curl",NaN)])
			setResult("FbrSnkCrl", i, BL/F1); /* Adds Curl for Fiber 1 calculated and bounding length */
		if (outputResult[arrayRankMatch3(analyses,"Fiber_Russ1_Curl",NaN)])
			setResult("FbrRss1Crl", i, BL/F2); /* Adds Curl for Fiber Russ 1 calculated and bounding length */
		if (outputResult[arrayRankMatch3(analyses,"Fiber_Russ2_Curl",NaN)])
			setResult("FbrRss2Crl", i, BL/F3); /* Adds Curl for Fiber Russ 2 calculated and bounding length */
		G = Ps[i]/(2*Areas[i]);  /* Calculates Interface Density (e.g. grain boundary density based on the interfaces between objects being shared. */
		if (outputResult[arrayRankMatch3(analyses,"Interfacial_Density",NaN)])
			setResult("Intfc_D" + "\(" + unit + supminus + supone + "\)", i, G); /* Adds new IntD column to end of results table - remember no spaces allowed in label. */
		// GL = d2s(G,4); /* Reduce Decimal places for labeling. */
		if (outputResult[arrayRankMatch3(analyses,"AR_Fiber_Snake",NaN)])
			setResult("AR_FbrSnk", i, F1/W1); /* Aspect ratio from fiber length approximation 1. */
		if (outputResult[arrayRankMatch3(analyses,"AR_Fiber_Russ1",NaN)])
			setResult("AR_FbrRuss1", i, F2/W2); /* Aspect ratio from fiber length approximation 2. */
		if (outputResult[arrayRankMatch3(analyses,"AR_Fiber_Russ2",NaN)]) 
			setResult("AR_FbrRuss2", i, F3/W3); /* aspect ratio from fiber length approximation*/
		if (outputResult[arrayRankMatch3(analyses,"Extent",NaN)])
			setResult("Extent", i, Areas[i]/(BL * BS)); /* adds Extent ratio, which is the object area/bounding rectangle area */
		if (outputResult[arrayRankMatch3(analyses,"Hxgn_Side",NaN)])
			setResult("HxgnSide" +unitLabel, i, HxgnSide); /* adds the length of each hexagonal side */
		if (outputResult[arrayRankMatch3(analyses,"Hxgn_Perim",NaN)])
			setResult("HxgnPerim" +unitLabel, i, 6 * HxgnSide); /* adds total perimeter of hexagon */
		if (outputResult[arrayRankMatch3(analyses,"Hxgn_Shape_Factor",NaN)])
			setResult("HSF", i, abs(Ps2A-HSFideal)); /* Hexagonal Shape Factor from Behndig et al. https://iovs.arvojournals.org/article.aspx?articleid=2122939 */
		if (outputResult[arrayRankMatch3(analyses,"Hxgn_Shape_Factor_R",NaN)])
			setResult("HSFR", i, abs(HSFideal/Ps2A)); /* Hexagonal Shape Factor as ratio to the ideal HSF, the value for a perfect hexagon is 1 */
		if (outputResult[arrayRankMatch3(analyses,"Hexagonality",NaN)])
			setResult("Hxgnlty", i, 6*HxgnSide/Ps[i]); /* adds a term to indicate accuracy of hexagon approximation */
		if (outputResult[arrayRankMatch3(analyses,"Vol_Pointed_Spheroid",NaN)])
			setResult("Vol_PtdSphr" + "\(" + unit + supthree + "\)", i, (PI/6) * Ferets[i] * pow(MinFerets[i],2)); /* adds prolate ellipsoid (an American football) volume: Hilliard 1968, Russ p. 189 */
		if (outputResult[arrayRankMatch3(analyses,"Vol_Discus_Spheroid",NaN)])
			setResult("Vol_Discus" + "\(" + unit + supthree + "\)", i, (PI/6) * MinFerets[i] * pow(Ferets[i],2)); /* adds oblate ellipsoid (a discus) volume: Hilliard 1968, Russ p. 189 */
	}
	updateResults();
	setBatchMode("exit & display"); /* exit batch mode */
	showStatus("Additional Geometries Macro Finished for: " + nTable + "Objects");
	beep(); wait(300); beep(); wait(100); beep();
	run("Collect Garbage");
}
	/*
	( 8(|)  ( 8(|)  All ASC Functions    @@@@@:-)  @@@@@:-)
	*/

	function arrayRankMatch3(array,string,default) {
		/* Original version 8/9/2018 3:07 PM PJL
			v190904 default option added */
		rank = default;
		for (i=0; i<array.length; i++) {
			if (array[i] == string){
				rank = i;
				i = array.length;
			}
		}
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
