/*
Before you begin, make sure to download Interactive Watershed by going to Help -> Update -> Manage Update Sites ->
Then scroll until you find "SCF MPI CBG" and apply it, then restart FIJI then when it reopens it should be downloaded
and add another tab named "SCF" after the Help tab.
*/

//Closing any open tabs
close("*");
close("Summary");
close("Results");
close("ROI Manager");
close("Threshold");

//selecting the file
Dialog.create("Choose your file");
	Dialog.addDirectory("Choose your file", "");
	Dialog.show();
folder = Dialog.getString();
result_csv_file = "Summary.csv"
YAP_result_csv_file = " YAP.csv"
CXCL8_result_csv_file = " CXCL8.csv"

//retrieve all files in the folder in an array
filelist = getFileList(folder);
run("Colors...", "background=black");
run("Set Measurements...", "area mean modal min shape redirect=None decimal=3");

for (i = 0; i < lengthOf(filelist); i++) {
	image_file = filelist [i];
	if ( endsWith(image_file, ".jpg")) {

		open(folder + image_file);

/*
		//set scale
		if (i < 1) {
			setTool("line");
			waitForUser("Set Scale", "Draw a line over the scale bar");
			Dialog.create("Enter the Length of the Scale Bar");
			Dialog.addNumber("Length in um", "");
			Dialog.show();
			scale = Dialog.getNumber();
			run("Set Scale...", "known=scale unit=um global");
		}
*/

/*
		//select epithelium
		run("Colors...", "background=black");
		setTool("freehand");
		waitForUser("Select the areas you want to count (hold down shift to select multiple). Click OK when you have selected the areas");
		run("Clear Outside");
*/		
		
		//pre-processing
		run("Split Channels");
		selectImage(image_file + " (blue)");
		run("Duplicate...", "title=blue");
		selectImage(image_file + " (blue)");
		run("Gaussian Blur...", "sigma=1");

		//Interactive Watershed (pre-set)
		hMin = 20;
		thresh = 50;
		peakFlooding = 95;
		run("H_Watershed", "impin=["+getTitle()+"] hmin="+hMin+" thresh="+thresh+" peakflooding="+peakFlooding + " outputmask=true allowsplitting=false");
		
		//Analyze nuclei and create mask
		run("Analyze Particles...", "size=100-Infinity summarize add clear");
		newImage(image_file + " nuclei", "RGB black", getWidth(), getHeight(), 1);
		roiManager("show all without labels");
		run("From ROI Manager");
		setForegroundColor(0, 0, 255);
		roiManager("Fill");
		saveAs(folder + image_file + " nuclei");
		setForegroundColor(255, 255, 255);
		roiManager("Fill");
		
		//Analyze Intensity of YAP
		selectImage(image_file + " (red)");
		run("Duplicate...", "title=Intensity");
		selectImage("Intensity");
		roiManager("Show All without labels");
		roiManager("Measure");
		run("Summarize");
		YAPMean = getResult("Mean", nResults-4);
		YAPMin = getResult("Min", nResults-4);
		YAPMax = getResult("Max", nResults-4);
		saveAs("Results", folder + image_file + YAP_result_csv_file);
		run("Clear Results");

		//CXCL8 within cell detection
		imageCalculator("Subtract create", image_file + " (green)", "blue");
		rename("GreenChannel");
		run("Duplicate...", "title=subtraction");
		run("Gaussian Blur...", "sigma=50");
		imageCalculator("Subtract create", "GreenChannel", "subtraction");
		rename("CXCL8mask");
		roiManager("show all without labels");
		roiManager("Measure");
		run("Summarize");
		CXCL8Mean = getResult("Mean", nResults-4);
		CXCL8Min = getResult("Min", nResults-4);
		CXCL8Max = getResult("Max", nResults-4);
		saveAs("Results", folder + image_file + CXCL8_result_csv_file);
		setAutoThreshold("MaxEntropy dark no-reset");
		run("Convert to Mask");
		roiManager("show all without labels");
		run("Clear Results");
		roiManager("Measure");
		green = 0;
		for (r = 0; r < nResults; r++) {
		if (getResult("Max", r) == 255) {
			green++;
			}
		}
		selectImage("CXCL8mask");
		run("Green");
		selectImage(image_file + " nuclei");
		roiManager("Show None");
		run("Add Image...", "image=CXCL8mask x=0 y=0 opacity=80 zero");
		saveAs(folder + image_file + " CXCL8 overlay");
		roiManager("Delete");
		
		//Process YAP and create mask
		selectImage(image_file + " (red)");
		setOption("BlackBackground", true);
		run("Enhance Contrast...", "saturated=0.02");
		run("Gaussian Blur...", "sigma=1.5");
		setThreshold(100, 250, "raw");
		run("Convert to Mask");
		run("Analyze Particles...", "size=0-Infinity add clear");
		newImage(image_file + " YAP", "RGB black", getWidth(), getHeight(), 1);
		if (RoiManager.size > 0) {
		roiManager("show all without labels");
		run("From ROI Manager");
		setForegroundColor(255, 0, 0);
		roiManager("Fill");
		saveAs(folder + image_file + " YAP");
		setForegroundColor(255, 255, 255);
		roiManager("Fill");
		}
		else {
		saveAs(folder + image_file + " YAP");
		}

		//Overlay nuclei & YAP
		imageCalculator("AND create", image_file + " YAP" , image_file + " nuclei");
		run("8-bit");
		rename(image_file + " YAP+");
		
		//YAP+ nuclei
		run("Remove Outliers...", "radius=2 threshold=50 which=Bright");
		run("Analyze Particles...", "size=15-Infinity summarize add clear");
		newImage("YAP+ nuclei", "RGB black", getWidth(), getHeight(), 1);
		roiManager("show all without labels");
		if (RoiManager.size > 0) {
		run("From ROI Manager");
		setForegroundColor(255, 0, 255);
		roiManager("Fill");
		}
		saveAs(folder + image_file + " YAP+ nuclei");
		run("Close All");
		close("ROI Manager");
	
		//add intensity and CXCL8 to results table
		IJ.renameResults("Summary", "Results");
		setResult("Slice", nResults, image_file + " CXCL8");
		setResult("Mean", (i*3) + 1, YAPMean);
		setResult("Min", (i*3) + 1, YAPMin);
		setResult("Max", (i*3) + 1, YAPMax);
		setResult("Count", (i*3) + 2, green);
		setResult("Mean", (i*3) + 2, CXCL8Mean);
		setResult("Min", (i*3) + 2, CXCL8Min);
		setResult("Max", (i*3) + 2, CXCL8Max);
		IJ.renameResults("Results", "Summary");
		
			}
		}

//save result table
	IJ.renameResults("Summary", "Results");
	saveAs("Results", folder + result_csv_file);