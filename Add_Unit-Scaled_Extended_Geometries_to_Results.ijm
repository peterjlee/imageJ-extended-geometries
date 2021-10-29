/*	Add scaled columns ImageJ Analyze 	
	This macro adds additional geometrical calculations Peter J. Lee Applied Superconductivity Center NHMFL FSU 6/17/2016 - 9/28/2016.
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
	v190904-v190905 Now refers only to Tables and exclusively uses Table macro codes to calculate values.
	Tried to make column names more consistent. Random java exceptions appear to be timing related and do not alter values.
	v190906 Added intensity column removal option and fixed last row of Object#.
	v200515 Added square geometries relevant to diamond indent hardness measurements.
	v200518 Added square geometries and ROI names import option.
	v200526 Added information columns: scale, image names  v200604 Just removed superscript minus symbol for compatibility with Excel and macro import.
	v200611 This versions allows embedding and retrieval of image scale information in the table.
	v200730 Updated tableSetColumnFunction function and swapped multiple exits from restoreExits.
	v201130 Corrected TableGet row request for row zero. v201204 Various tweaks to try and debug issue with unit and file name not being output to table.
	v210825-7 Does not offer to delete "same value" columns if there is only 1 row. Replaces "-Infinity" entries (incompatible with macro table functions) with symbol and restores entries afterwards
	v211027 Uses selectResultsWindow function
	*/
macro "Add Additional Geometries to Table" {
	lMacro = "Add_Unit-Scaled_Extended_Geometries_to_Results_v211027"; /* Better to use manual label in case macro is called from startup */
	requires("1.52m"); /*Uses the new ROI.getFeretPoints released in 1.52m */
	saveSettings();
	fullFName = getInfo("image.filename");
	selectResultsWindow();
	tableTitle = Table.title;
	nTable = Table.size;
	if (nTable==0) exit("No Table to work with");
	tableHeadings = Table.headings;
	tableColumns = split(tableHeadings);
	columnsL = lengthOf(tableColumns);
	infinitySym = fromCharCode(0x221E);
	infinityCount = 0;
	for (i=0; i<columnsL; i++){
		for (j=0; j<nTable; j++){
			if(Table.get(tableColumns[i],j)=="-Infinity"){
				Table.set(tableColumns[i],j,infinitySym);
				infinityCount++;
			}
		}
	}
	defaultAllHeadings = Table.allHeadings;
	defaultAllColumns = split(defaultAllHeadings);
	nDResults = defaultAllColumns.length;
	nHResults = tableColumns.length;
	nMissingResults = nDResults - nHResults;
	missingResults = "";
	if (nMissingResults>0){
		for (i=0; i<nDResults; i++) {
			dAC = defaultAllColumns[i];
			if (dAC!="Ch" && dAC!="Frame" && dAC!="MinThr" && dAC!="MaxThr"){
				if (indexOfArray(tableColumns,defaultAllColumns[i],-1)<0) missingResults += defaultAllColumns[i] + ", ";
			}
		}
		if (missingResults!="") showMessageWithCancel("The table does not have " + missingResults + ": Continue?");
	}
	userPath = getInfo("user.dir");
	prefsDelimiter = "|";
	if (isOpen(tableTitle)) selectWindow(tableTitle);
	else {
		selectResultsWindow();
		tableTitle = Table.title;
	}
	/* Check table for embedded scale */
	tableScale = false;
	if (Table.size>0){
		tablePW = Table.get("PixelWidth",0); /* This value embedded in the table by some ASC macros */
		tablePAR = Table.get("PixelAR",0); /* This value embedded in the table by some ASC macros */
		tableUnit = Table.getString("Unit",0); /* This value embedded in the table by some ASC macros */
		if (tablePW!=NaN && tablePAR!=NaN && tableUnit!="null" && tableUnit!=NaN){
			tableScale = true;
			pixelWidth = parseFloat(tablePW); /* Makes sure this is not a string in the imported table  */
			pixelAR = parseFloat(tablePAR); /* Makes sure this is not a string in the imported table */
			pixelHeight = pixelWidth/pixelAR;
			unit = tableUnit;
		}
	}
	if (!tableScale){
		if (nImages>0) getPixelSize(unit, pixelWidth, pixelHeight);
		else {
			Dialog.create("No images open, please enter unit values");
				Dialog.addRadioButtonGroup("Perhaps there should be an open image?", newArray("continue","exit"),2,1,"continue");
				print("No images were open, expanded Feret coordinates will not be added to table.");
				Dialog.addNumber("pixel width",1,10,10,"units");
				Dialog.addNumber("pixel height",1,10,10,"units");
				unitChoices = newArray("m","cm","mm","µm","microns","nm","Å","pm","inches");
				Dialog.addChoice("units",unitChoices,"pixels");
				Dialog.show;
				if (Dialog.getRadioButton=="exit") restoreExit;
				pixelWidth = Dialog.getNumber;
				pixelHeight = Dialog.getNumber;
				unit = Dialog.getChoice;
		}
	}
	pixelAR = pixelWidth/pixelHeight;
	lcf = (pixelWidth + pixelHeight)/2;
	unitLabel = "\(" + unit + "\)";
	 
	supminus = "^-"; /* the character code fromCharCode(0x207B) does not seem to work as exported to Excel and when called into other macros */
	supone = fromCharCode(0x00B9); /* UTF-16 (hex) C/C++/Java source code 	"\u00B9" */
	suptwo = fromCharCode(0x00B2); /* UTF-16 (hex) C/C++/Java source code 	"\u00B2" */
	supthree = fromCharCode(0x00B2); /* UTF-16 (hex) C/C++/Java source code 	"\u00B3" */
	sqroot = fromCharCode(0x221A); /* UTF-16 (hex) */
	degreeSym = fromCharCode(0x00B0); /* UTF-16 (hex) degree symbol */
	
	 html = "<html>"
	 +"<font color=blue size=+1>Additional Aspect Ratios:</font><br />"
	 +"<font color=green> \"AR Bounding Rect\"</font>: Aspect ratio from bounding rectangle.<br />"
	 +"<font color=green> \"AR Feret\"</font>: Aspect ratio Feret diameters\( max\/min\).<br />"
	 +"<font color=blue size=+1>Additional Feret Diameter derived geometries:</font><br />"
		+"<font color=green> \"Feret Coordinates\"</font>: Coordinates for both min and max Feret diameters.<br />"
		+"<font color=green>\"Compactness_Feret\"</font> (using Feret diameter as maximum diameter),<br />"
		+"<font color=green>0-90"+sqroot+" resolved angles:</font> for \"Angle\" and \"Feret Angle\"<br />"
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
	 +"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; https://doi.org/10.1186/s40645-015-0078-x<br />"
	 +"<font color=green> \"Thinnes ratio\"</font> inverse of circularity see https://imagej.net/Shape_Filter<br />"
	 +"<font color=green> \"Extent ratio\"</font> object area/bounding rectangle area */,<br />"
	 +"<font color=green> \"Curl\"</font> Fiber length/length of bounding box<br />"
	 +"<font color=blue size=+1>Square geometries</font> relevant to diamond indent hardness measurement:<br />"
	 +"<font color=green>Sqr_Diag_A</font> = "+sqroot+"\(2*Area\) </font> for a square with vertical diagonal this length should match the bounding box height<br />"
	 +"<font color=green>Squarity:</font> for a perfect square these values should approach 1:<br />"
	 +"<font color=green>&nbsp;Squarity_AP</font> =  1-|1-\(16*Area\)/Perimeter"+suptwo+"| </font> \(perhaps too sensitive to perimeter roughness\)<br />"
	 +"<font color=green>&nbsp;Squarity_AF</font> =  1-|1-Feret/\(A*"+sqroot+"2\)| </font> <br />"
	 +"<font color=green>&nbsp;Squarity_Ff</font> =  1-|1-"+sqroot+"2/Feret_AR| </font><br />"
	 +"<font color=blue size=+1>Hexagonal geometries</font> more appropriate to close-packed structures than ellipses:<br />"
	 +"<font color=green>HexPerimeter</font> = 6 * HxgnSide<br />"
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
	for (i=0; i<resultsNeeded.length; i++) {
		if (indexOfArray(tableColumns,resultsNeeded[i],-1)<0) {
			resultsMissing += resultsNeeded[i] + ", ";
			missing += 1;
		}
	}
	if (missing > 0) restoreExit("" + missing + " required columns " + resultsMissing + " are missing");
	/* The measurements are split into groups for organization purposes and then recombined for simplicity of use with Dialog.addCheckboxGroup */
	analysesI = newArray("Image_Scale","Unit","ObjectN","ROI_name", "Image_Name"); /* Information */
	analysesF = newArray("AR_Bounding_Rect","AR_Feret","Roundness_Feret","Compactness_Feret", "Feret_Coords");
	analysesA = newArray("Angle_0-90", "FeretAngle_0-90","CircToEllipse_Tilt");
	analysesPx = newArray("X\(px\)","Y\(px\)","XM\(px\)","YM\(px\)","BX\(px\)","BY\(px\)","Bounding_Rect_W\(px\)","Bounding_Rect_H\(px\)");
	analysesD = newArray("D_Area_CircEquiv","D_Perim_CircEquiv","Dsph_equiv");
	analysesB = newArray("FiberThk_Snake","Fiber_Thk_Russ1","Fiber_Thk_Russ2","Fiber_Lngth_Snake","Fiber_Lngth_Russ1","Fiber_Lngth_Russ2","Fiber_Snake_Curl","Fiber_Russ1_Curl","Fiber_Russ2_Curl","AR_Fiber_Snake","AR_Fiber_Russ1","AR_Fiber_Russ2");
	analysesS = newArray("Sqr_Diag_A","Squarity_AP", "Squarity_AF", "Squarity_Ff");
	analysesH = newArray("Hxgn_Side","Hxgn_Perim","Hxgn_Shape_Factor", "Hxgn_Shape_Factor_R", "Hexagonality");
	analysesM = newArray("Convexity","Elongation","Roundness_cAR","Interfacial_Density","Thinnes_Ratio","Extent");
	analysesV = newArray("Vol_Pointed_Spheroid","Vol_Discus_Spheroid");
	analyses1 = Array.concat(analysesI,analysesF,analysesA);
	analyses3 = Array.concat(analysesD,analysesB,analysesS,analysesH,analysesM,analysesV);
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
		for (i=0; i<defaultOffs.length; i++)	outputResult[indexOfArray(analyses,defaultOffs[i],false)] = false;
	}
	if (analyses.length!=outputResult.length) restoreExit("analyses.length = " + analyses.length + " but outputResult.length = " + outputResult.length);
	checkboxGroupColumns = 5;
	checkboxGroupRows = round(analyses.length/checkboxGroupColumns)+1; /* Add +1 to make sure that there are enough cells */
	Dialog.create("Select Extended Geometrical Analyses");
		Dialog.addMessage("Macro filename: " + lMacro);
		Dialog.setInsets(-5, 20, 0);
		Dialog.addMessage("Image file name: " + fullFName);
		if (tableScale){
			Dialog.setInsets(-5, 20, 0);
			Dialog.addMessage("Pixel Width = " + parseFloat(tablePW) + ", Pixel AR = " + parseFloat(tablePAR) + ", Unit = " + tableUnit + " - - - Scale imported from embedded table data");
			getPixelSize(iUnit, iPixelWidth, iPixelHeight);
			Dialog.setInsets(-5, 20, 0);
			Dialog.addMessage("Pixel Width = " + iPixelWidth + ", Pixel AR = " + iPixelWidth/iPixelHeight + ", Unit = " + iUnit + " - - - Active image scale");
		}
		else {
			Dialog.setInsets(-5, 20, 0);
			Dialog.addMessage("Pixel Width = " + pixelWidth + ", Pixel AR = " + pixelWidth/pixelHeight + ", Unit = " + unit + " - - - Image scale used");
		}
		if (pixelAR!=1) Dialog.addMessage("IMPORTANT: The pixels are not reported as square, these extended geometries have not been tested for this condition.");
		if (roiManager("count")!=nTable || nImages==0) {
			outputResult[indexOfArray(analyses,"Feret_Coords",false)] = false;
			Dialog.addMessage("Extended Feret Coordinates series requires ROIs and an open image");
		}
		Dialog.addCheckboxGroup(checkboxGroupRows,checkboxGroupColumns,analyses,outputResult);
		Dialog.addCheckbox("Select all \(override selections above\)",false);
		Dialog.addRadioButtonGroup("Set preferences for next run:", newArray("Use these settings", "select all","select none","reset"),4,1,"Use these settings");
		if (nTable>1) Dialog.addCheckbox("Table cleanup: Remove Mean,StdDev,Mode,Min,Max,IntDen,Median,Skew,Kurt,%Area,RawIntDen, columns if all the same", true);
		Dialog.addHelp(html);
		Dialog.show();
		for (i=0; i<outputResult.length; i++) outputResult[i] = Dialog.getCheckbox();
		if (Dialog.getCheckbox) for (i=0; i<outputResult.length; i++) outputResult[i] = true;
		analysesPrefsKey = prefsNameKey+"Analyses";
		analysesOnPrefsKey = prefsNameKey+"AnalysesOn";
		nextRunSettings = Dialog.getRadioButton();
		if (nTable>1) columnCleanup = Dialog.getCheckbox();
		else columnCleanup = false;
	selectWindow(tableTitle);
	setBatchMode(true); /* batch mode on*/
	if (columnCleanup){
		intCols = newArray("Mean","StdDev","Mode","Min","Max","IntDen","Median","Skew","Kurt","%Area","RawIntDen");
		for(i=0;i<intCols.length;i++) {
			if (indexOf("\t"+tableHeadings,"\t"+intCols[i]+"\t")>-1) {
				vals = Table.getColumn(intCols[i]);
				Array.getStatistics(vals, min, max, nul, nul); 
				if(min==max){
					Table.deleteColumn(intCols[i]);
					Table.update;
					print("Column " + intCols[i] + " contained a single value \(" + min + "\) and was deleted");
				}
			}
		}
	}
	if (nextRunSettings=="reset") {
		call("ij.Prefs.set", analysesPrefsKey, "None");
		call("ij.Prefs.set", analysesOnPrefsKey, "None");
		print("prefs reset");
	}
	else {
		if (nextRunSettings=="select all") for (i=0;i<analyses.length; i++) outputResult[i] = true;
		if (nextRunSettings=="select none") for (i=0;i<analyses.length; i++) outputResult[i] = false;
		analysesString = arrayToString(analyses,prefsDelimiter);
		analysesOnString = arrayToString(outputResult,prefsDelimiter);
		call("ij.Prefs.set", analysesPrefsKey, analysesString);
		call("ij.Prefs.set", analysesOnPrefsKey, analysesOnString);
	}
	if (nImages>0 && outputResult[indexOfArray(analyses,"Image_Name",false)]) {
		tableSetColumnValue("Image_Name", fullFName);
	}
	if (lcf!=1) {
		tableSetColumnValue("lcf",lcf);
		if (outputResult[indexOfArray(analyses,"Image_Scale",false)]){
			tableSetColumnValue("Unit",unit);
			tableSetColumnValue("PixelWidth",pixelWidth);
			tableSetColumnValue("PixelAR",pixelAR);
		}
		if (outputResult[indexOfArray(analyses,"X\(px\)",false)]) {Table.applyMacro("X_px = X/lcf");}
		if (outputResult[indexOfArray(analyses,"Y\(px\)",false)]) {Table.applyMacro("Y_px = Y/lcf");}
		if (outputResult[indexOfArray(analyses,"XM\(px\)",false)]) {Table.applyMacro("XM_px = XM/lcf");}
		if (outputResult[indexOfArray(analyses,"YM\(px\)",false)]) {Table.applyMacro("YM_px = YM/lcf");}
		if (outputResult[indexOfArray(analyses,"BX\(px\)",false)]) {Table.applyMacro("BX_px = round(BX/lcf)");}
		if (outputResult[indexOfArray(analyses,"BY\(px\)",false)]) {Table.applyMacro("BY_px = round(BY/lcf)");}
		if (outputResult[indexOfArray(analyses,"Bounding_Rect_W\(px\)",false)]) {Table.applyMacro("BoxW_px = round(Width/lcf)");}
		if (outputResult[indexOfArray(analyses,"Bounding_Rect_H\(px\)",false)]) {Table.applyMacro("BoxH_px = round(Height/lcf)");}
		Table.deleteColumn("lcf");
	}
	Table.update;
	if((roiManager("count")==nTable) && outputResult[indexOfArray(analyses,"ROI_name",false)]) {
		for (i=0; i<nTable; i++) {
			roiName = call("ij.plugin.frame.RoiManager.getName", i);
			Table.set("ROI_name", i, roiName);
		}
		roiManager("deselect");
	}
	if((roiManager("count")==nTable) && nImages>0 && outputResult[indexOfArray(analyses,"Feret_Coords",false)]) {
		for (i=0; i<nTable; i++) {
			roiManager("select", i);
			Roi.getFeretPoints(x,y);
			Table.set("FeretX", i, x[0]);
			Table.set("FeretY", i, y[0]);
			Table.set("FeretX2", i, x[1]);
			Table.set("FeretY2", i, y[1]);
			Table.set("MinFeretX", i, x[2]);
			Table.set("MinFeretY", i, y[2]);
			Table.set("MinFeretX2", i, d2s(round(x[3]),0));
			Table.set("MinFeretY2", i, d2s(round(y[3]),0));
		}
		roiManager("deselect");
	}
	selectWindow(tableTitle);
	Table.update;
	if (outputResult[indexOfArray(analyses,"ObjectN",false)]){
		Table.setColumn("ObjectN",Array.slice(Array.getSequence(nTable+1),1,nTable+1));}  /* Add ObjectN+1 column for labels */
		bSCode = "BS = minOf(Width,Height); BL = maxOf(Width,Height)";
		Table.applyMacro(bSCode);
		Table.update;
		/* Note that the AR reported by ImageJ is the ratio of the fitted ellipse major and minor axes. */
		if (outputResult[indexOfArray(analyses,"CircToEllipse_Tilt",false)]) {Table.applyMacro("Cir_to_El_Tilt = (180/PI) * acos(1/AR)");} /* The angle a circle (cylinder in 3D) would be tilted to appear as an ellipse with this AR */
		if (outputResult[indexOfArray(analyses,"AR_Bounding_Rect",false)]) {Table.applyMacro("AR_Box = BL/BS");} /* Bounding rectangle aspect ratio */
		if (outputResult[indexOfArray(analyses,"AR_Feret",false)]) {Table.applyMacro("AR_Feret = Feret/MinFeret");} /* adds fitted ellipse aspect ratio. */
		if (outputResult[indexOfArray(analyses,"Roundness_Feret",false)]) {Table.applyMacro("Rnd_Feret = 4*Area/(PI * pow(Feret,2))");} /* Adds Roundness, using Feret as maximum diameter (IJ Analyze uses ellipse major axis */
		if (outputResult[indexOfArray(analyses,"Compactness_Feret",false)]) {Table.applyMacro("Compact_Feret = (sqrt(Area*4/PI))/Feret");} /* Adds Compactness, using Feret as maximum diameter */
		if (outputResult[indexOfArray(analyses,"Elongation",false)]) {Table.applyMacro("Elongation = 1-(minOf(Height/Width, Width/Height))");} /* Elongation see https://imagej.net/Shape_Filter */
		if (outputResult[indexOfArray(analyses,"Thinnes_Ratio",false)]) {Table.applyMacro("Thinnes_Ratio = 1/Circ_");} /* adds Thinnes ratio. */
		if (outputResult[indexOfArray(analyses,"Sqr_Diag_A",false)]) {Table.applyMacro("Sqr_Diag_A = (sqrt(Area*2))");} /* Adds diagonal of square based on area */
		if (outputResult[indexOfArray(analyses,"Squarity_AP",false)]) {Table.applyMacro("Squarity_AP = 1-abs(1-(16*Area/(pow(Perim_,2))))");} /* Adds Squarity_AP value, should be 1 for perfect square */
		if (outputResult[indexOfArray(analyses,"Squarity_AF",false)]) {Table.applyMacro("Squarity_AF = 1-abs(1-(Feret/(sqrt(2*Area))))");} /* Adds Squarity_AF value, should be 1 for perfect square */
		if (outputResult[indexOfArray(analyses,"Squarity_Ff",false)]) {Table.applyMacro("Squarity_Ff = 1-abs(1-(AR_Feret/sqrt(2)))");} /* Adds Squarity_Ff value, should be 1 for perfect square */
		// wait(delay);
		Table.update;
		if (outputResult[indexOfArray(analyses,"Fiber",false)]) {
			fiberCode = "P2 = pow(Perim_,2); Fbr_Th_Snk_Units = 1/PI*(Perim_-(sqrt(P2-4*PI*Area))); Fbr_Th_Rss1_Units = Area/((0.5*Perim_)-(2*(Area/Perim_)));"
			+ "Fbr_Th_Rss2_Units = Area/(0.3181*Perim_+sqrt(0.033102*P2-0.41483*Area)); Fbr_L_Snk_Units = Area/Fbr_Th_Snk_Units; Fbr_L_Rss1_Units = (0.5*Perim_)-(2*(Area/Perim_));"
			+ "Fbr_L_Rss2_Units = 0.3181*Perim_+sqrt(0.033102*P2-0.41483*Area)";
			Table.applyMacro(fiberCode);
			/* Fbr_Th_Snk_Units: Round end ribbon thickness from repeating up/down half-annulus - think snake or perhaps Loch Ness Monster Lee & Jablonski LTSW'94 Devils Head Resort. */
			/* Fbr_Th_Rss1_Units: Fiber width from fiber length from John C. Russ Computer Assisted Microscopy page 189. */
			/* Fbr_Th_Rss2_Units: Fiber width from Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */		
		}
		Table.update;
		if (outputResult[indexOfArray(analyses,"Angle_0-90",false)]) {Table.applyMacro("Angle_0to90 = abs(Angle-90)");}
		if (outputResult[indexOfArray(analyses,"FeretAngle_0-90",false)]) {Table.applyMacro("FeretAngle0to90 = abs(FeretAngle-90)");}
		if (outputResult[indexOfArray(analyses,"Convexity",false)]){ /* Perimeter of fitted ellipse from Ramanujan's first approximation */
			Table.applyMacro("Convexity = (PI * ((3*(Major/2 + Minor/2)) - sqrt((3*Major/2 + Minor/2)*(Major/2 + 3*Minor/2))))/Perim_");} /* Convexity using the calculated elliptical fit to obtain a convex perimeter */
		if (outputResult[indexOfArray(analyses,"Roundness_cAR",false)]){
			Table.applyMacro("Rndnss_cAR = Circ_ + 0.913 - (0.826261 + 0.337479 * AR-0.335455 * pow(AR,2) + 0.103642 * pow(AR,3) - 0.0155562 * pow(AR,4) + 0.00114582 * pow(AR,5) - 0.0000330834 * pow(AR,6))"); /* Circularity corrected by aspect ratio roundness: https://doi.org/10.1186/s40645-015-0078-x */
		}
		Table.update;
		if (outputResult[indexOfArray(analyses,"D_Area_CircEquiv",false)]){
			Table.applyMacro("Da_Equiv_Units = 2*(sqrt(Area/PI))");} /* Darea-equiv (AKA Heywood diameter) - remember no spaces allowed in label. */
		if (outputResult[indexOfArray(analyses,"D_Perim_CircEquiv",false)]){
			Table.applyMacro("Dp_Equiv_Units = Perim_/PI");} /* Adds new perimeter-equivalent Diameter column to end of results table - remember no spaces allowed in label. */
		if (outputResult[indexOfArray(analyses,"Dsph_equiv",false)]){
			Table.applyMacro("Dsph_Equiv_Units = exp((log(6*Area*(Feret+MinFeret)/(2*PI)))/3)");} /* Adds diameter based on a sphere - Russ page 182 but using the mean Feret diameters to calculate the volume */
		if (outputResult[indexOfArray(analyses,"Fiber",false)]) {
			if (outputResult[indexOfArray(analyses,"Fiber_Snake_Curl",false)])
				{Table.applyMacro("Fbr_Snk_Crl = BL/Fbr_L_Snk_Units");} /* Adds Curl for Fiber 1 calculated and bounding length */
			if (outputResult[indexOfArray(analyses,"Fiber_Russ1_Curl",false)])
				{Table.applyMacro("Fbr_Rss1_Crl = BL/Fbr_L_Rss1_Units");} /* Adds Curl for Fiber Russ 1 calculated and bounding length */
			if (outputResult[indexOfArray(analyses,"Fiber_Russ2_Curl",false)])
				{Table.applyMacro("Fbr_Rss2_Crl = BL/Fbr_L_Rss2_Units");} /* Adds Curl for Fiber Russ 2 calculated and bounding length */
			if (outputResult[indexOfArray(analyses,"AR_Fiber_Snake",false)])
				{Table.applyMacro("AR_Fbr_Snk = Fbr_L_Snk_Units/Fbr_Th_Snk_Units");} /* Aspect ratio from fiber length approximation 1. */
			if (outputResult[indexOfArray(analyses,"AR_Fiber_Russ1",false)])
				{Table.applyMacro("AR_Fbr_Russ1 = Fbr_L_Rss1_Units/Fbr_Th_Rss1_Units");} /* Aspect ratio from fiber length approximation 2. */
			if (outputResult[indexOfArray(analyses,"AR_Fiber_Russ2",false)]) 
				{Table.applyMacro("AR_Fbr_Russ2 = Fbr_L_Rss2_Units/Fbr_Th_Rss2_Units");} /* aspect ratio from fiber length approximation*/
		}
		Table.update;
		/* Calculates Interface Density (e.g. grain boundary density based on the interfaces between objects being shared. */
		if (outputResult[indexOfArray(analyses,"Interfacial_Density",false)]){
			Table.applyMacro("IntfcD = Perim_/(2*Area)"); /* Adds new IntD column to end of results table - remember no spaces allowed in label. */
			tableColumnRenameOrReplace("IntfcD","Intfc_D" + "\(" + unit + supminus + supone + "\)");
			// GL = d2s(G,4); /* Reduce Decimal places for labeling. */
		}
		Table.update;
		if (outputResult[indexOfArray(analyses,"Extent",false)]){
			Table.applyMacro("Extent = Area/(BL * BS)");} /* adds Extent ratio, which is the object area/bounding rectangle area */
		if (outputResult[indexOfArray(analyses,"Hex",false)] || outputResult[indexOfArray(analyses,"Hxg",false)]){
			Table.applyMacro("Ps2A = P2/Area");
			Table.applyMacro("HSFideal = 8 * sqrt(3)");} /* Collin and Grabsch (1982) https://doi.org/10.1111/j.1755-3768.1982.tb05785.x */
		if (outputResult[indexOfArray(analyses,"Hxgn_Side",false)]){
			Table.applyMacro("Hxgn_Side_Units = sqrt((2*Area)/(3*sqrt(3)))"); /* adds the length of each hexagonal side */
		if (outputResult[indexOfArray(analyses,"Hxgn_Perim",false)]){
			Table.applyMacro("Hxgn_Perim_Units = 6 * Hxgn_Side_Units");} /* adds total perimeter of hexagon */
		if (outputResult[indexOfArray(analyses,"Hxgn_Shape_Factor",false)])
			{Table.applyMacro("HSF = abs(Ps2A-HSFideal)");} /* Hexagonal Shape Factor from Behndig et al. https://iovs.arvojournals.org/article.aspx?articleid=2122939 */
		if (outputResult[indexOfArray(analyses,"Hxgn_Shape_Factor_R",false)])
			{Table.applyMacro("HSFR = abs(HSFideal/Ps2A)");} /* Hexagonal Shape Factor as ratio to the ideal HSF, the value for a perfect hexagon is 1 */
		if (outputResult[indexOfArray(analyses,"Hexagonality",false)])
			{Table.applyMacro("Hexagonality = 6*Hxgn_Side_Units/Perim_");} /* adds a term to indicate accuracy of hexagon approximation */
		Table.update;
		Table.deleteColumn("Ps2A");
		Table.update;
		Table.deleteColumn("HSFideal");
		Table.update;
		if (outputResult[indexOfArray(analyses,"Vol_Pointed_Spheroid",false)]){
			Table.applyMacro("VolPtdSphr = (PI/6) * Feret * pow(MinFeret,2)"); /* adds prolate ellipsoid (an American football) volume: Hilliard 1968, Russ p. 189 */
			tableColumnRenameOrReplace("VolPtdSphr","Vol_PtdSphr" + "\(" + unit + supthree + "\)");
		}
		if (outputResult[indexOfArray(analyses,"Vol_Discus_Spheroid",false)]){
			Table.applyMacro("VolDiscus = (PI/6) * MinFeret * pow(Feret,2)"); /* adds oblate ellipsoid (a discus) volume: Hilliard 1968, Russ p. 189 */
			tableColumnRenameOrReplace("VolDiscus","Vol_Discus" + "\(" + unit + supthree + "\)");
		}
		tableDeleteColumn("P2");
		tableDeleteColumn("BS");
		tableDeleteColumn("BL");
		finalColumns = split(Table.headings);
		for (i=0; i<finalColumns.length; i++){
			cN = finalColumns[i];
			if (indexOf(cN,"_px")>0) tableColumnRenameOrReplace(cN,replace(cN,"_px","\(px\)"));
			if (indexOf(cN,"_Units")>0) tableColumnRenameOrReplace(cN,replace(cN,"_Units",unitLabel));
			if (indexOf(cN,"_0to90")>0) tableColumnRenameOrReplace(cN,replace(cN,"0to90","0-90" + degreeSym));
		}
		if (infinityCount>0){
			for (i=0; i<columnsL; i++){
				for (j=0; j<nTable; j++){
					if(Table.get(tableColumns[i],j)==infinitySym){
						Table.set(tableColumns[i],j,"-Infinity");
						infinityCount -=1;
						if (infinityCount==0){
							j=nTable; i=columnsL;
						}
					}
				}
			}
		}
		Table.update;
	}
	setBatchMode("exit & display"); /* exit batch mode */
	showStatus("Additional Geometries Macro Finished for: " + nTable + " Objects");
	Table.rename(tableTitle,"Results"); /* column headers export not supported for tables otherwise  :-( */
	beep(); wait(300); beep(); wait(300); beep();
	restoreSettings;
	call("java.lang.System.gc");
	/* End of Add_Unit-Scaled_Extended_Geometries_to_Results */
}
	/*
	( 8(|)  ( 8(|)  All ASC Functions    @@@@@:-)  @@@@@:-)
	*/
	function arrayToString(array,delimiters){
		/* 1st version April 2019 PJL
			v190722 Modified to handle zero length array */
		string = "";
		for (i=0; i<array.length; i++){
			if (i==0) string += array[0];
			else  string = string + delimiters + array[i];
		}
		return string;
	}
	function getResultsTableList() {
		/* simply returns array of open results tables
		v200723: 1st version
		v201207: Removed warning message */
		nonImageWindows = getList("window.titles");
		// if (nonImageWindows.length==0) exit("No potential results windows are open");
		if (nonImageWindows.length>0){
			resultsWindows = newArray();
			for (i=0; i<nonImageWindows.length; i++){
				selectWindow(nonImageWindows[i]);
				if(getInfo("window.type")=="ResultsTable")
				resultsWindows = Array.concat(resultsWindows,nonImageWindows[i]);    
			}
			return resultsWindows;
		}
		else return "";
	}
	function indexOfArray(array,string,default) {
		/* v190423 Adds "default" parameter (use -1 for backwards compatibility). Returns only first found value */
		index = default;
		for (i=0; i<lengthOf(array); i++){
			if (array[i]==string) {
				index = i;
				i = lengthOf(array);
			}
		}
		return index;
	}
	function memFlush(waitTime) {
		run("Reset...", "reset=[Undo Buffer]"); 
		wait(waitTime);
		run("Reset...", "reset=[Locked Image]"); 
		wait(waitTime);
		call("java.lang.System.gc"); /* force a garbage collection */
		wait(waitTime);
	}
	function restoreExit(message){ /* Make a clean exit from a macro, restoring previous settings */
		/* v200305 1st version using memFlush function */
		restoreSettings(); /* Restore previous settings before exiting */
		setBatchMode("exit & display"); /* Probably not necessary if exiting gracefully but otherwise harmless */
		memFlush(200);
		exit(message);
	}
	function selectResultsWindow(){
		/* selects the Results window
			v200722: 1st version
			v200723: Uses separate getResultsTableList function
			v211027: if only one Results window found it selects it. Requires restoreExit function
			*/
		resultsWindows = getResultsTableList();
		if (resultsWindows.length>1){
			resultsWindows = Array.sort(resultsWindows); /* R for Results comes before S for Summary */
			Dialog.create("Select table for analysis: v200722");
			Dialog.addChoice("Choose Results Table: ",resultsWindows,resultsWindows[0]);
			Dialog.show();
			selectWindow(Dialog.getChoice());
		}
		else if (resultsWindows.length==1) selectWindow(resultsWindows[0]);
		else restoreExit("Sorry, no results windows found");
  	}
	function tableColumnRenameOrReplace(oldName,newName){
		/* 1st version 9/5/2019 11:29 AM PJL 
			v190906 Add table update  */
		headingsString = "\t" + Table.headings + "\t"; /* 1st tab not currently needed */
		oldNameTab = "\t" + oldName + "\t";
		newNameTab = "\t" + newName + "\t";
		if (indexOf(headingsString,newNameTab)>= 0) {Table.deleteColumn(newName);Table.update;}
		if (indexOf(headingsString,oldNameTab)>= 0) {Table.renameColumn(oldName, newName);Table.update;}
	}
	function tableDeleteColumn(columnName){
		/* 1st version 9/5/2019 11:29 AM PJL
			Allows no-error running if when column may or may not exist.
			v190906 Add table update  */
		headingsString = "\t" + Table.headings + "\t"; /* 1st tab not currently needed. */
		if (indexOf(headingsString,columnName)> = 0) {
			Table.deleteColumn(columnName);
			Table.update;
		}
	}
	function tableSetColumnValue(columnName,value){
		/* Original version v190905 to overcome Table macro limitation - PJL 
			v190906 Add table update
			v200730 If value cannot be converted to number it is entered as a string
		*/
		if (Table.size>0){
			tempArray = newArray(Table.size);
			number = parseFloat(value);
			if (isNaN(number)) for (i=0; i<Table.size; i++) Table.set(columnName, i, value);
			else {	
				Array.fill(tempArray, number);
				Table.setColumn(columnName, tempArray);
			}
		Table.update;
		}
		else restoreExit("No Table for array fill");
	}