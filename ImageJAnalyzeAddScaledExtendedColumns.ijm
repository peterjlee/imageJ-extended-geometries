/*	Add scaled columns ImageJ Analyze
	http://stackoverflow.com/questions/22429638/renaming-rois-in-imagej-based-on-their-x-coordinate-value-in-order-to-create-a-s/22760127#22760127
	This macro calculates the grain boundary density assuming the grain boundary is shared by two grains.
	It also adds additional geometrical calculations Peter J. Lee 6/17/2016 - 9/28/2016.
	v171009 Adds additional aspect ratio variants.
	v180223 Adds hexagonal geometry and a couple of volumetric examples from Russ
*/
macro "Add Additional Geometrical Analyses to Results" {
	/* v171023 */
	requires("1.49u6");
	saveSettings;
	/* Some cleanup */
	run("Select None");
	setBatchMode(true); /* batch mode on*/
	
	t=getTitle();
	getPixelSize(unit, pixelWidth, pixelHeight);
	lcf = (pixelWidth + pixelHeight)/2;
	
	supminus = fromCharCode(0x207B);
	supone = fromCharCode(0x00B9); /* UTF-16 (hex) C/C++/Java source code 	"\u00B9" */
	suptwo = fromCharCode(0x00B2); /* UTF-16 (hex) C/C++/Java source code 	"\u00B2" */
	supthree = fromCharCode(0x00B2); /* UTF-16 (hex) C/C++/Java source code 	"\u00B3" */

	checkForRoiManager();
	checkForResults();

	if (nResults!=roiManager("count")) {
		roiManager("deselect");
		roiManager("delete");
		setAnalysisDefaults();
		run("Analyze Particles...", "display clear add");
	}
	
	for (i=0 ; i<roiManager("count"); i++) {
		setResult("ROI#", i, i+1); /* Add ROI#+1 column for labels */
		if (pixelWidth!=1) {
			setResult("X\(px\)", i, (getResult("X", i))/lcf);
			setResult("Y\(px\)", i, (getResult("Y", i))/lcf);
			setResult("XM\(px\)", i, (getResult("XM", i))/lcf);
			setResult("YM\(px\)", i, (getResult("YM", i))/lcf);
			setResult("BX\(px\)", i, round((getResult("BX", i))/lcf));
			setResult("BY\(px\)", i, round((getResult("BY", i))/lcf));
			setResult("Width\(px\)", i, round((getResult("Width", i))/lcf));
			setResult("Height\(px\)", i, round((getResult("Height", i))/lcf));
		}
		P = getResult("Perim.",i);
		A = getResult("Area",i);
		BW = getResult("Width", i); /* Bounding rectangle width */
		BH = getResult("Height", i); /* Bounding rectangle height */
		MajorR = getResult("Major", i)/2; MinorR = getResult("Minor", i)/2;  /* Obtain major and minor axis radii for Ramanujan's formula */
		PE = PI * ((3*(MajorR + MinorR)) - sqrt((3*MajorR + MinorR)*(MajorR + 3*MinorR))); /* Perimeter of fitted ellipse from Ramanujan's first approximation */;
		Feret = getResult("Feret", i);
		MinFeret = getResult("MinFeret", i);
		ARF = Feret/MinFeret;
		setResult("AR_Feret", i, ARF); /* adds fitted ellipse aspect ratio. */
		ARB = BH/BW; /* Bounding rectangle aspect ratio */
		if (ARB <= 1) ARB = 1/ARB;
		setResult("AR_Box", i, ARB); /* adds rectangular bounding box aspect ratio. */
		/* Note that the AR reported by ImageJ is the ratio of the fitted ellipse major and minor axes. */
		setResult("Round_Feret", i, 4*A/(PI * Feret * Feret)); /* Adds Roundness, using Feret as maximum diameter (IJ Analyze uses ellipse major axis */
		setResult("Compact_Feret", i, (sqrt(A*4/PI))/Feret); /* Adds Compactness, using Feret as maximum diameter */
		setResult("Angle_0-90", i, abs((getResult("Angle", i))-90));
		setResult("FeretAngle_0-90", i, abs((getResult("FeretAngle", i))-90));
		setResult("Convexity", i, PE/P); /* Convexity using the calculated elliptical fit to obtain a convex perimeter */
		DA = 2*(sqrt(A/PI));  /* Adds Darea-equiv (AKA Heywood diameter) while we are at it. */
		setResult("Da_equiv" + "\(" + unit + "\)", i, DA); /* adds new Da* column to end of results table - remember no spaces allowed in label. */
		DP = P/PI;  /* Adds Dperimeter-equiv while we are at it. */
		setResult("Dp_equiv" + "\(" + unit + "\)", i, DP); /* Adds new Dp* column to end of results table - remember no spaces allowed in label. */
		setResult("Dsph_equiv" + "\(" + unit + "\)", i, exp((log(6*A*(Feret+MinFeret)/(2*PI)))/3)); /* Adds diameter based on a sphere - Russ page 182 but using the mean Feret diameters to calculate the volume */
		W1 = 1/PI*(P-(sqrt(P*P-4*PI*A))); /* Round end ribbon thickness from repeating half-annulus - Lee & Jablonski LTSW'94 Devils Head Resort. */
		setResult("FiberThAnn" + "\(" + unit + "\)", i, W1); /* Adds new Ribbon Thickness column to end of results table */
		W2 = A/((0.5*P)-(2*(A/P))); /* Fiber width from fiber length from John C. Russ Computer Assisted Microscopy page 189. */
		setResult("FiberThRuss1" + "\(" + unit + "\)", i, W2); /* Adds new fiber width column to end of results table. */
		W3 = A/(0.3181*P+sqrt(0.033102*P*P-0.41483*A)); /* Fiber width from Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		setResult("FiberThRuss2" + "\(" + unit + "\)", i, W3); /* Adds new fiber width column to end of results table. */
		F1 = A/W1; /* Fiber Length from fiber width Lee and Jablonski (John C. Russ  The Image Processing Handbook 7th Ed. Page 612 0.25*(sqrt(P+(P*P-(16*A)))) is incorrect).*/
		setResult("FiberLAnn" + "\(" + unit + "\)", i, F1); /* Adds new fiber length column to end of results table. */
		F2 = (0.5*P)-(2*(A/P)); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		setResult("FiberLRuss1" + "\(" + unit + "\)", i, F2); /* Adds new fiber length column to end of results table. */
		F3 = 0.3181*P+sqrt(0.033102*P*P-0.41483*A); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		setResult("FiberLRuss2" + "\(" + unit + "\)", i, F3); /* Adds new fiber length column to end of results table. */
		setResult("CurlF1", i, BH/F1); /* Adds Curl for Fiber 1 calculated and bounding length */
		G = P/(2*A);  /* Calculates Grain Boundary Density based on the GB shared between 2 grains. */
		setResult("GBD" + "\(" + unit + supminus + supone + "\)", i, G); /* Adds new GB column to end of results table - remember no spaces allowed in label. */
		GL = d2s(G,4); /* Reduce Decimal places for labeling. */
		ARFL1 = F1/W1; /* Aspect ratio from fiber length approximation 1. */
		setResult("AR_Fiber1", i, ARFL1); /* adds fitted ellipse aspect ratio. */
		ARFL2 = F2/W2; /* Aspect ratio from fiber length approximation 2. */
		setResult("AR_Fiber2", i, ARFL2); /* adds fitted ellipse aspect ratio. */
		ARFL3 = F3/W3; /* Aspect ratio from fiber length approximation 3. */
		setResult("AR_Fiber3", i, ARFL3); /* adds fitted ellipse aspect ratio. */
		Thinnes = 4*PI*A/(P*P); /* see http://imagej.net/Shape_Filter */
		setResult("T_Ratio", i, Thinnes); /* adds Thinnes ratio. */
		EXT = getResult("Area", i)/(BW * BH); 
		setResult("Extent", i, EXT); /* adds Extent ratio, which is the object area/bounding rectangle area */
		HexSide = sqrt((2*A)/(3*sqrt(3))); /* Some descriptions for 2D hexagonal close-packed structures */
		setResult("HexSide" + "\(" + unit + "\)", i, HexSide); /* adds the length of each hexagonal side */
		setResult("HexPerim" + "\(" + unit + "\)", i, 6 * HexSide); /* adds total perimeter of hexagon */
		setResult("Hexagonality", i, 6*HexSide/P); /* adds a term to indicate accuracy of hexagon approximation */
		VolPr = (PI/6) * Feret * MinFeret * MinFeret;
		setResult("VolPr" + "\(" + unit + supthree + "\)", i, VolPr); /* adds prolate ellipsoid (an American football) volume: Hilliard 1968, Russ p. 189 */
		VolOb = (PI/6) *MinFeret * Feret * Feret;
		setResult("VolOb" + "\(" + unit + supthree + "\)", i, VolOb); /* adds oblate ellipsoid (a discus) volume: Hilliard 1968, Russ p. 189 */
	}
	updateResults();
	// reset();
	restoreSettings();
	setBatchMode("exit & display"); /* exit batch mode */
	showStatus("Additional Geometries Macro Finished: " + roiManager("count"));
	beep(); wait(300); beep(); wait(100); beep();
	run("Collect Garbage");
}

/*---( 8(|)------( 8(|)---Functions---( 8(|)------( 8(|)---*/

	function checkForResults() {
		nROIs = roiManager("count");
		nRES = nResults;
		if (nRES==0)	{
			Dialog.create("No Results to Work With");
			Dialog.addCheckbox("Run Analyze-particles to generate table?", true);
			Dialog.addMessage("This macro requires a Results table to analyze.\n \nThere are   " + nRES +"   results.\nThere are    " + nROIs +"   ROIs.");
			Dialog.show();
			analyzeNow = Dialog.getCheckbox(); /* if (analyzeNow==true) ImageJ analyze particles will be performed, otherwise exit; */
			if (analyzeNow==true) {
				if (roiManager("count")!=0) {
					roiManager("deselect")
					roiManager("delete"); 
				}
				setOption("BlackBackground", false);
				run("Analyze Particles..."); /* let user select settings */
			}
			else restoreExit("Goodbye, your previous setting will be restored.");
		}
	}
	function checkForRoiManager() {
		/* v161109 adds the return of the updated ROI count and also adds dialog if there are already entries just in case . . */
		nROIs = roiManager("count");
		nRES = nResults; /* not really needed except to provide useful information below */
		if (nROIs==0) runAnalyze = true;
		else runAnalyze = getBoolean("There are already " + nROIs + " in the ROI manager; do you want to clear the ROI manager and reanalyze?");
		if (runAnalyze) {
			roiManager("reset");
			Dialog.create("Analysis check");
			Dialog.addCheckbox("Run Analyze-particles to generate new roiManager values?", true);
			Dialog.addMessage("This macro requires that all objects have been loaded into the roi manager.\n \nThere are   " + nRES +"   results.\nThere are   " + nROIs +"   ROIs.");
			Dialog.show();
			analyzeNow = Dialog.getCheckbox();
			if (analyzeNow) {
				setOption("BlackBackground", false);
				if (nResults==0)
					run("Analyze Particles...", "display add");
				else run("Analyze Particles..."); /* let user select settings */
				if (nResults!=roiManager("count"))
					restoreExit("Results and ROI Manager counts do not match!");
			}
			else restoreExit("Goodbye, your previous setting will be restored.");
		}
		return roiManager("count"); /* returns the new count of entries */
	}
	function restoreExit(message){ /* clean up before aborting macro then exit */
		/* 9/9/2017 added Garbage clean up suggested by Luc LaLonde - LBNL */
		restoreSettings(); /* clean up before exiting */
		setBatchMode("exit & display"); /* not sure if this does anything useful if exiting gracefully but otherwise harmless */
		run("Collect Garbage"); 
		exit(message);
	}
	function setAnalysisDefaults() {
		/* Set options for black objects on white background as this works better for publications */
		run("Options...", "iterations=1 white count=1"); /* set white background */
		run("Colors...", "foreground=black background=white selection=yellow"); /* set colors */
		setOption("BlackBackground", false);
		run("Appearance...", " "); /* do not use Inverting LUT */
		/* The above should be the defaults but this makes sure (black particles on a white background)
		   http://imagejdocu.tudor.lu/doku.php?id=faq:technical:how_do_i_set_up_imagej_to_deal_with_white_particles_on_a_black_background_by_default}
		*/
		run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack nan redirect=None decimal=9");
	}