macro "Draw Bounding Rectangles on Objects in Results Table" {
/*	This macro draws the Bounding Rectangle, he smallest rectangle enclosing the selection. 
	PJL NHMFL
	v200514 First version
	v200515 Simplified options to ensure highest quality output.
*/
	saveSettings();
	if (nResults==0) exit("No Results Table to work with");
	iD = getImageID();
	fullFName = getInfo("image.filename");
	if (fullFName=="") {	fName = getTitle();extension = "";}
	else { path = getInfo("image.directory");	fName = File.getNameWithoutExtension(path+fullFName); extension = substring(fullFName, lengthOf(fName));}
	newName = fName + "+Bndng_Rects" + extension;
	originalImageDepth = bitDepth(); /*8 (gray or color), 16, 24 (RGB) or 32 (float). */
	if (is("grayscale")) grayScale = true; else grayScale = false;
	defaultLineWidth = maxOf(1,(round(getWidth()/1024)));
	getPixelSize(unit, pixelWidth, pixelHeight);
	unitLabel = "\(" + unit + "\)";
	lcf = (pixelWidth + pixelHeight)/2;
	Dialog.create("Rectangle Line Options");
		colorChoice = newArray("Use_gray_choice", "random", "red", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "jazzberry_jam", "red_N_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern", "Radical Red", "Wild Watermelon", "Outrageous Orange", "Atomic Tangerine", "Neon Carrot", "Sunglow", "Laser Lemon", "Electric Lime", "Screamin' Green", "Magic Mint", "Blizzard Blue", "Shocking Pink", "Razzle Dazzle Rose", "Hot Magenta");
		grayChoice = newArray("gray", "white", "black", "off-white", "off-black", "light_gray", "dark_gray");
		if (grayScale) colorIndex = 0;
		else colorIndex = 9;
		Dialog.addChoice("Grayscale Line color:", grayChoice, grayChoice[0]);
		Dialog.addChoice("Color Line color \(color overrides gray choice\):", colorChoice,  colorChoice[colorIndex]);
		Dialog.addNumber("Line width \(pixels\) = ", defaultLineWidth);	
		Dialog.addCheckbox("Keep drawings as overlays?", true);
	Dialog.show();
		lineGray = Dialog.getChoice();
		lineColor = Dialog.getChoice();
		keepOverlays =  Dialog.getCheckbox();
		lineWidth = Dialog.getNumber;
	if (lineColor=="Use_gray_choice") lineColor = lineGray;
	setBatchMode(true); /* Does not appear to improve speed much here */
	setLineWidth(lineWidth);
	run("Select None");
	run("Duplicate...", "title=DBR_temp");
	selectWindow("Results");
	TableHeadings = Table.headings;
	if (indexOf(TableHeadings, "BX")<0 || indexOf(TableHeadings, "BY")<0 || indexOf(TableHeadings, "Width")<0 || indexOf(TableHeadings, "Height")<0) exit("Analysis with Bounding Rectangle required, please add to measurement options");
	fX = Table.getColumn("BX");
	fY = Table.getColumn("BY");
	fW = Table.getColumn("Width"); /* This angle is in degrees */
	fH = Table.getColumn("Height");
	if (lineColor!="random") setColorFromColorName(lineColor);
	for (i=0; i<nResults; i++) {
		if (i%5==0) showProgress(i/nResults);
		run("Select None");
		if (lineColor=="random"){
			rCA = getRandomColorArray(75,200);
			setColor(rCA[0],rCA[1],rCA[2]);
		}
		Overlay.drawRect(fX[i],fY[i],fW[i],fH[i]);
		Overlay.show;
	}
	Overlay.show;
	selectWindow("DBR_temp");
	if(!keepOverlays){
		run("Flatten");
		if (lineColor==lineGray && grayScale==true) {
			run("" + originalImageDepth + "-bit");
		}
		rename(newName);
		close("DBR_temp");
	}
	else rename(newName);
	setBatchMode("exit and display");
	showStatus("Bounding Rectangle Drawing Finished: " + nResults + " line\"s\" drawn");
	beep(); wait(300); beep(); wait(300); beep();
	selectWindow(newName);
	run("Select None");
	restoreSettings();
	call("java.lang.System.gc"); 
}

	function getColorArrayFromColorName(colorName) {
		/* v180828 added Fluorescent Colors
		   v181017-8 added off-white and off-black for use in gif transparency and also added safe exit if no color match found
		*/
		if (colorName == "white") cA = newArray(255,255,255);
		else if (colorName == "black") cA = newArray(0,0,0);
		else if (colorName == "off-white") cA = newArray(245,245,245);
		else if (colorName == "off-black") cA = newArray(10,10,10);
		else if (colorName == "light_gray") cA = newArray(200,200,200);
		else if (colorName == "gray") cA = newArray(127,127,127);
		else if (colorName == "dark_gray") cA = newArray(51,51,51);
		else if (colorName == "off-black") cA = newArray(10,10,10);
		else if (colorName == "light_gray") cA = newArray(200,200,200);
		else if (colorName == "gray") cA = newArray(127,127,127);
		else if (colorName == "dark_gray") cA = newArray(51,51,51);
		else if (colorName == "red") cA = newArray(255,0,0);
		else if (colorName == "pink") cA = newArray(255, 192, 203);
		else if (colorName == "green") cA = newArray(0,255,0); /* #00FF00 AKA Lime green */
		else if (colorName == "blue") cA = newArray(0,0,255);
		else if (colorName == "yellow") cA = newArray(255,255,0);
		else if (colorName == "orange") cA = newArray(255, 165, 0);
		else if (colorName == "garnet") cA = newArray(120,47,64);
		else if (colorName == "gold") cA = newArray(206,184,136);
		else if (colorName == "aqua_modern") cA = newArray(75,172,198); /* #4bacc6 AKA "Viking" aqua */
		else if (colorName == "blue_accent_modern") cA = newArray(79,129,189); /* #4f81bd */
		else if (colorName == "blue_dark_modern") cA = newArray(31,73,125);
		else if (colorName == "blue_modern") cA = newArray(58,93,174); /* #3a5dae */
		else if (colorName == "gray_modern") cA = newArray(83,86,90);
		else if (colorName == "green_dark_modern") cA = newArray(121,133,65);
		else if (colorName == "green_modern") cA = newArray(155,187,89); /* #9bbb59 AKA "Chelsea Cucumber" */
		else if (colorName == "green_modern_accent") cA = newArray(214,228,187); /* #D6E4BB AKA "Gin" */
		else if (colorName == "green_spring_accent") cA = newArray(0,255,102); /* #00FF66 AKA "Spring Green" */
		else if (colorName == "orange_modern") cA = newArray(247,150,70);
		else if (colorName == "pink_modern") cA = newArray(255,105,180);
		else if (colorName == "purple_modern") cA = newArray(128,100,162);
		else if (colorName == "jazzberry_jam") cA = newArray(165,11,94);
		else if (colorName == "red_N_modern") cA = newArray(227,24,55);
		else if (colorName == "red_modern") cA = newArray(192,80,77);
		else if (colorName == "tan_modern") cA = newArray(238,236,225);
		else if (colorName == "violet_modern") cA = newArray(76,65,132);
		else if (colorName == "yellow_modern") cA = newArray(247,238,69);
		/* Fluorescent Colors https://www.w3schools.com/colors/colors_crayola.asp */
		else if (colorName == "Radical Red") cA = newArray(255,53,94);			/* #FF355E */
		else if (colorName == "Wild Watermelon") cA = newArray(253,91,120);		/* #FD5B78 */
		else if (colorName == "Outrageous Orange") cA = newArray(255,96,55);	/* #FF6037 */
		else if (colorName == "Supernova Orange") cA = newArray(255,191,63);	/* FFBF3F Supernova Neon Orange*/
		else if (colorName == "Atomic Tangerine") cA = newArray(255,153,102);	/* #FF9966 */
		else if (colorName == "Neon Carrot") cA = newArray(255,153,51);			/* #FF9933 */
		else if (colorName == "Sunglow") cA = newArray(255,204,51); 			/* #FFCC33 */
		else if (colorName == "Laser Lemon") cA = newArray(255,255,102); 		/* #FFFF66 "Unmellow Yellow" */
		else if (colorName == "Electric Lime") cA = newArray(204,255,0); 		/* #CCFF00 */
		else if (colorName == "Screamin' Green") cA = newArray(102,255,102); 	/* #66FF66 */
		else if (colorName == "Magic Mint") cA = newArray(170,240,209); 		/* #AAF0D1 */
		else if (colorName == "Blizzard Blue") cA = newArray(80,191,230); 		/* #50BFE6 Malibu */
		else if (colorName == "Dodger Blue") cA = newArray(9,159,255);			/* #099FFF Dodger Neon Blue */
		else if (colorName == "Shocking Pink") cA = newArray(255,110,255);		/* #FF6EFF Ultra Pink */
		else if (colorName == "Razzle Dazzle Rose") cA = newArray(238,52,210); 	/* #EE34D2 */
		else if (colorName == "Hot Magenta") cA = newArray(255,0,204);			/* #FF00CC AKA Purple Pizzazz */
		else restoreExit("No color match to " + colorName);
		return cA;
	}
	function getRandomColorArray(lowestIntensity,highestIntensity) {
		/* v200515 1st version PJL */
		r =-255; g = -255; b = -255;
		lIRGB = lowestIntensity*3;
		hIRGB = highestIntensity*3;
		while ((r+g+b) < lIRGB || (r+g+b) > (hIRGB)){
			r = 255*random;
			g = 255*random;
			b = 255*random;
		}
		rCA = newArray(round(r),round(g),round(b));
		return rCA;
	}
	function setColorFromColorName(colorName) {
		colorArray = getColorArrayFromColorName(colorName);
		setColor(colorArray[0], colorArray[1], colorArray[2]);
	}
	function restoreExit(message){ /* Make a clean exit from a macro, restoring previous settings */
		/* 9/9/2017 added Garbage clean up suggested by Luc LaLonde - LBNL */
		restoreSettings(); /* Restore previous settings before exiting */
		setBatchMode("exit & display"); /* Probably not necessary if exiting gracefully but otherwise harmless */
		call("java.lang.System.gc");
		exit(message);
	}
