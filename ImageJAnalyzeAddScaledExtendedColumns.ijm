/*	Add scaled columns ImageJ Analyze
	http://stackoverflow.com/questions/22429638/renaming-rois-in-imagej-based-on-their-x-coordinate-value-in-order-to-create-a-s/22760127#22760127
	This macro calculates the grain boundary density assuming the grain boundary is shared by two grains.
	It also adds additional geometrical calculations Peter J. Lee 6/17/2016 - 9/28/2016
	v161013
*/
macro "Add Additional Geometrical Analyses to Results" {
	// assess required conditions before proceeding
	requires("1.49u6");
	saveSettings;
	// Some cleanup
	run("Select None");
	setBatchMode(true); //batch mode on
	start = getTime();
	
	/* Set options for black objects on white background as this works better for publications */
	run("Options...", "iterations=1 white count=1"); /* set white background */
	run("Colors...", "foreground=black background=white selection=yellow"); //set colors
	setOption("BlackBackground", false);
	run("Appearance...", " "); /* do not use Inverting LUT */
	// The above should be the defaults but this makes sure (black particles on a white background)
	// http://imagejdocu.tudor.lu/doku.php?id=faq:technical:how_do_i_set_up_imagej_to_deal_with_white_particles_on_a_black_background_by_default

	t=getTitle();
	getPixelSize(unit, pixelWidth, pixelHeight);
	lcf = (pixelWidth + pixelHeight)/2;
	// snapshot();

	//Macro settings:
	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack nan redirect=None decimal=9");
	
	supminus = fromCharCode(0x207B);
	supone = fromCharCode(0x00B9); //UTF-16 (hex) C/C++/Java source code 	"\u00B9"
	suptwo = fromCharCode(0x00B2); //UTF-16 (hex) C/C++/Java source code 	"\u00B2"

	binaryCheck(t);
	checkForRoiManager();
	checkForResults();

	if (nResults!=roiManager("count")) {
		roiManager("deselect")
		roiManager("delete");
		setOption("BlackBackground", false);
		run("Analyze Particles...", "display clear add");
	}
	
	for (i=0 ; i<roiManager("count"); i++) {
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
		setResult("Angle_0-90", i, abs((getResult("Angle", i))-90));
		setResult("FeretAngle_0-90", i, abs((getResult("FeretAngle", i))-90));
		P = getResult("Perim.",i);
		A = getResult("Area",i);
		DA = 2*(sqrt(A/PI));  // might as well add Darea-equiv (AKA Heywood diameter) while we are at it
		setResult("Da_equiv" + "\(" + unit + "\)", i, DA); // adds new D* column to end of results table - remember no spaces allowed in label
		DP = P/PI;  // might as well add Dperimeter-equiv while we are at it
		setResult("Dp_equiv" + "\(" + unit + "\)", i, DP); // adds new D* column to end of results table - remember no spaces allowed in label
		W1 = 1/PI*(P-(sqrt(P*P-4*PI*A))); // Round end ribbon thickness from repeating half-annulus - Lee & Jablonski LTSW'94 Devils Head Resort
		setResult("FiberThAnn" + "\(" + unit + "\)", i, W1); // adds new Ribbon Thickness column to end of results table
		W2 = A/((0.5*P)-(2*(A/P))); //Fiber width from fiber length from John C. Russ Computer Assisted Microscopy page 189
		setResult("FiberThRuss1" + "\(" + unit + "\)", i, W2); // adds new column to end of results table
		W3 = A/(0.3181*P+sqrt(0.033102*P*P-0.41483*A)); //Fiber width from Fiber Length from John C. Russ Computer Assisted Microscopy page 189
		setResult("FiberThRuss2" + "\(" + unit + "\)", i, W3); // adds new column to end of results table
		F1 = A/W1; //Fiber Length from fiber width Lee and Jablonski (John C. Russ  The Image Processing Handbook 7th Ed. Page 612 0.25*(sqrt(P+(P*P-(16*A)))) is incorrect)
		setResult("FiberLAnn" + "\(" + unit + "\)", i, F1); // adds new column to end of results table
		F2 = (0.5*P)-(2*(A/P)); //Fiber Length from John C. Russ Computer Assisted Microscopy page 189
		setResult("FiberLRuss1" + "\(" + unit + "\)", i, F2); // adds new column to end of results table
		F3 = 0.3181*P+sqrt(0.033102*P*P-0.41483*A); //Fiber Length from John C. Russ Computer Assisted Microscopy page 189
		setResult("FiberLRuss2" + "\(" + unit + "\)", i, F3); // adds new column to end of results table
		G = P/(2*A);  // calculates Grain Boundary Density based on the GB shared between 2 grains
		setResult("GBD" + "\(" + unit + supminus + supone + "\)", i, G); // adds new GB column to end of results table - remember no spaces allowed in label
		GL = d2s(G,4); // Reduce Decimal places for labeling
	}
	updateResults();
	// reset();
	restoreSettings();
	setBatchMode("exit & display"); /* exit batch mode */
	showStatus("Additional Geometries Macro Finished: " + roiManager("count") + " objects analyzed in " + (getTime()-start)/1000 + "s.");
	beep(); wait(300); beep(); wait(300); beep();
}

/*---( 8(|)------( 8(|)---Functions---( 8(|)------( 8(|)---*/

	function binaryCheck(windowTitle) { // for white objects on black background
		selectWindow(windowTitle);
		if (is("binary")==0) run("8-bit");
		// Quick-n-dirty threshold if not previously thresholded
		getThreshold(t1,t2); 
		if (t1==-1)  {
			run("8-bit");
			setThreshold(0, 128);
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Invert");
		}
		// Make sure black objects on white background for consistency	
		if (((getPixel(0, 0))==0 || (getPixel(0, 1))==0 || (getPixel(1, 0))==0 || (getPixel(1, 1))==0))
			run("Invert"); 
		// Sometimes the outline procedure will leave a pixel border around the outside - this next step checks for this.
		// i.e. the corner 4 pixels should now be all black, if not, we have a "border issue".
		if (((getPixel(0, 0))+(getPixel(0, 1))+(getPixel(1, 0))+(getPixel(1, 1))) != 4*(getPixel(0, 0)) ) 
				restoreExit("Border Issue"); 	
	}
	function checkForResults() {
		if (nResults==0)	{
			Dialog.create("No Results to Work With");
			Dialog.addCheckbox("Run Analyze-particles to generate table?", true);
			Dialog.addMessage("This macro requires a Results table to analyze.");
			Dialog.show();
			analyzeNow = Dialog.getCheckbox(); //if (analyzeNow==true) ImageJ analyze particles will be performed, otherwise exit;
			if (analyzeNow==true) {
				if (roiManager("count")!=0) {
					roiManager("deselect")
					roiManager("delete"); 
				}
				setOption("BlackBackground", false);
				run("Analyze Particles...", "display clear add");
			}
			else restoreExit();
		}
	}
	function checkForRoiManager() {
		if (roiManager("count")==0)  {
			Dialog.create("No ROI");
			Dialog.addCheckbox("Run Analyze-particles to generate roiManager values?", true);
			Dialog.addMessage("This macro requires that all objects have been loaded into the roi manager.");
			Dialog.show();
			analyzeNow = Dialog.getCheckbox(); //if (analyzeNow==true) ImageJ analyze particles will be performed, otherwise exit;
			if (analyzeNow==true) {
				setOption("BlackBackground", false);
				if (nResults==0) run("Analyze Particles...", "display add");
				else run("Analyze Particles...", "display clear add");
				if (nResults!=roiManager("count")) restoreExit("Results and ROI Manager counts do not match!");
			}
			else restoreExit();
		}
	}
	function cleanLabel(string) {
		string= replace(string, "\\^2", fromCharCode(178)); // superscript 2 
		string= replace(string, "\\^3", fromCharCode(179)); // superscript 3 UTF-16 (decimal)
		string= replace(string, "\\^-1", fromCharCode(0x207B) + fromCharCode(185)); // superscript -1
		string= replace(string, "\\^-2", fromCharCode(0x207B) + fromCharCode(178)); // superscript -2
		string= replace(string, "\\^-^1", fromCharCode(0x207B) + fromCharCode(185)); // superscript -1
		string= replace(string, "\\^-^2", fromCharCode(0x207B) + fromCharCode(178)); // superscript -2
		string= replace(string, "(?<![A-Za-z0-9])u(?=m)", fromCharCode(181)); // micrometer units
		string= replace(string, "\\b[aA]ngstrom\\b", fromCharCode(197)); // angstrom symbol
		string= replace(string, "  ", " "); // double spaces
		string= replace(string, "_", fromCharCode(0x2009)); // replace underlines with thin spaces
		string= replace(string, "px", "pixels"); // expand pixel abbreviation
		return string;
	}
	function closeImageByTitle(windowTitle) {  /* cannot be used with tables */
        if (isOpen(windowTitle)) {
		selectWindow(windowTitle);
        close();
		}
	}
	function closeNonImageByTitle(windowTitle) { // obviously
	if (isOpen(windowTitle)) {
		selectWindow(windowTitle);
        run("Close");
		}
	}
	function restoreExit(message){ // clean up before aborting macro then exit
		restoreSettings(); //clean up before exiting
		setBatchMode("exit & display"); // not sure if this does anything useful if exiting gracefully but otherwise harmless
		exit(message);
	}
