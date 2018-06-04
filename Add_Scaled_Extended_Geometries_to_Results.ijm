/*	Add scaled columns ImageJ Analyze 	
	This macro adds additional geometrical calculations Peter J. Lee 6/17/2016 - 9/28/2016.
	For IntD all interfaces are shared between to objects either side so interface length is divided by 2
	v171009 Adds additional aspect ratio variants.
	v180223 Adds hexagonal geometry and a couple of volumetric examples from Russ.
	v180330 Renames GBD to IntD.
	v180503 1st version using new Table functions introduced in ImageJ 1.52
	v180503b Reverts to setResult for scaled data to give more flexibility on column labels	
	*/
macro "Add Additional Geometrical Analyses to Results" {
	requires("1.52a"); /*Uses the new Table Macro Functions released in 1.52a */
	if (nResults==0) exit("No Results Table to work with");
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
	
	/* Note that the AR reported by ImageJ is the ratio of the fitted ellipse major and minor axes. */
	Table.applyMacro("AR_Box=maxOf(Height/Width, Width/Height)"); /* Bounding rectangle aspect ratio */
	Table.applyMacro("AR_Feret=Feret/MinFeret"); /* adds fitted ellipse aspect ratio. */
	Table.applyMacro("Round_Feret=4*Area/(PI * Feret * Feret)"); /* Adds Roundness, using Feret as maximum diameter (IJ Analyze uses ellipse major axis */
	Table.applyMacro("Compact_Feret=(sqrt(Area*4/PI))/Feret"); /* Adds Compactness, using Feret as maximum diameter */
	for (i=0; i<nResults; i++) {
		if (lcf!=1) {
			setResult("X\(px\)", i, Xs[i]/lcf);
			setResult("Y\(px\)", i, Ys[i]/lcf);
			setResult("XM\(px\)", i, XMs[i]/lcf);
			setResult("YM\(px\)", i, YMs[i]/lcf);
			setResult("BX\(px\)", i, round(BXs[i]/lcf));
			setResult("BY\(px\)", i, round(BYs[i]/lcf));
			setResult("BoxW\(px\)", i, round(BWs[i]/lcf));
			setResult("BoxH\(px\)", i, round(BHs[i]/lcf));
		}
		setResult("Object#", i, i+1); /* Add Object#+1 column for labels */
		PE = PI * ((3*(Majors[i]/2 + Minors[i]/2)) - sqrt((3*Majors[i]/2 + Minors[i]/2)*(Majors[i]/2 + 3*Minors[i]/2))); /* Perimeter of fitted ellipse from Ramanujan's first approximation */;
		setResult("Angle_0-90", i, abs(Angles[i]-90));
		setResult("FeretAngle_0-90", i, abs(FeretAngles[i]-90));
		setResult("Convexity", i, PE/Ps[i]); /* Convexity using the calculated elliptical fit to obtain a convex perimeter */
		DA = 2*(sqrt(Areas[i]/PI));  /* Adds Darea-equiv (AKA Heywood diameter) while we are at it. */
		setResult("Da_equiv" +unitLabel, i, DA); /* adds new Da* column to end of results table - remember no spaces allowed in label. */
		DP = Ps[i]/PI;  /* Adds Dperimeter-equiv while we are at it. */
		setResult("Dp_equiv" +unitLabel, i, DP); /* Adds new Dp* column to end of results table - remember no spaces allowed in label. */
		setResult("Dsph_equiv" +unitLabel, i, exp((log(6*Areas[i]*(Ferets[i]+MinFerets[i])/(2*PI)))/3)); /* Adds diameter based on a sphere - Russ page 182 but using the mean Feret diameters to calculate the volume */
		W1 = 1/PI*(Ps[i]-(sqrt(Ps[i]*Ps[i]-4*PI*Areas[i]))); /* Round end ribbon thickness from repeating half-annulus - Lee & Jablonski LTSW'94 Devils Head Resort. */
		setResult("FiberThAnn" +unitLabel, i, W1); /* Adds new Ribbon Thickness column to end of results table */
		W2 = Areas[1]/((0.5*Ps[i])-(2*(Areas[i]/Ps[i]))); /* Fiber width from fiber length from John C. Russ Computer Assisted Microscopy page 189. */
		setResult("FiberThRuss1" +unitLabel, i, W2); /* Adds new fiber width column to end of results table. */
		W3 = Areas[i]/(0.3181*Ps[i]+sqrt(0.033102*Ps[i]*Ps[i]-0.41483*Areas[i])); /* Fiber width from Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		setResult("FiberThRuss2" +unitLabel, i, W3); /* Adds new fiber width column to end of results table. */
		F1 = Areas[i]/W1; /* Fiber Length from fiber width Lee and Jablonski (John C. Russ  The Image Processing Handbook 7th Ed. Page 612 0.25*(sqrt(P+(P*P-(16*A)))) is incorrect).*/
		setResult("FiberLAnn" +unitLabel, i, F1); /* Adds new fiber length column to end of results table. */
		F2 = (0.5*Ps[i])-(2*(Areas[i]/Ps[i])); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		setResult("FiberLRuss1" +unitLabel, i, F2); /* Adds new fiber length column to end of results table. */
		F3 = 0.3181*Ps[i]+sqrt(0.033102*Ps[i]*Ps[i]-0.41483*Areas[i]); /* Fiber Length from John C. Russ Computer Assisted Microscopy page 189. */
		setResult("FiberLRuss2" +unitLabel, i, F3); /* Adds new fiber length column to end of results table. */
		setResult("CurlF1", i, BHs[i]/F1); /* Adds Curl for Fiber 1 calculated and bounding length */
		G = Ps[i]/(2*Areas[i]);  /* Calculates Interface Density (e.g. grain boundary density based on the interfaces between objects being shared. */
		setResult("IntD" + "\(" + unit + supminus + supone + "\)", i, G); /* Adds new IntD column to end of results table - remember no spaces allowed in label. */
		GL = d2s(G,4); /* Reduce Decimal places for labeling. */
		ARFL1 = F1/W1; /* Aspect ratio from fiber length approximation 1. */
		setResult("AR_Fiber1", i, ARFL1); /* adds fitted ellipse aspect ratio. */
		ARFL2 = F2/W2; /* Aspect ratio from fiber length approximation 2. */
		setResult("AR_Fiber2", i, ARFL2); /* adds fitted ellipse aspect ratio. */
		ARFL3 = F3/W3; /* Aspect ratio from fiber length approximation 3. */
		setResult("AR_Fiber3", i, ARFL3); /* adds fitted ellipse aspect ratio. */
		Thinnes = 4*PI*Areas[i]/(Ps[i]*Ps[i]); /* see http://imagej.net/Shape_Filter */
		setResult("T_Ratio", i, Thinnes); /* adds Thinnes ratio. */
		EXT = Areas[i]/(BWs[i] * BHs[i]); 
		setResult("Extent", i, EXT); /* adds Extent ratio, which is the object area/bounding rectangle area */
		HexSide = sqrt((2*Areas[i])/(3*sqrt(3))); /* Some descriptions for 2D hexagonal close-packed structures */
		setResult("HexSide" +unitLabel, i, HexSide); /* adds the length of each hexagonal side */
		setResult("HexPerim" +unitLabel, i, 6 * HexSide); /* adds total perimeter of hexagon */
		setResult("Hexagonality", i, 6*HexSide/Ps[i]); /* adds a term to indicate accuracy of hexagon approximation */
		VolPr = (PI/6) * Ferets[i] * MinFerets[i] * MinFerets[i];
		setResult("VolPr" + "\(" + unit + supthree + "\)", i, VolPr); /* adds prolate ellipsoid (an American football) volume: Hilliard 1968, Russ p. 189 */
		VolOb = (PI/6) *MinFerets[i] * Ferets[i] * Ferets[i];
		setResult("VolOb" + "\(" + unit + supthree + "\)", i, VolOb); /* adds oblate ellipsoid (a discus) volume: Hilliard 1968, Russ p. 189 */
	}
	updateResults();
	setBatchMode("exit & display"); /* exit batch mode */
	showStatus("Additional Geometries Macro Finished for: " + nResults + "Objects");
	beep(); wait(300); beep(); wait(100); beep();
	run("Collect Garbage");
}