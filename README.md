# Fiji-Counting-Macro

This ImageJ Macro counts and quantifies the intensity of DAPI/CXCL8/YAP costained cells by counting DAPI stained cells (segmented with [interactive watershed](https://github.com/mpicbg-scicomp/Interactive-H-Watershed.git)) and assigning a positive brightness value threshold of the CXCL8 and YAP channels. Then cells in which CXCL8 and YAP respectively are expressed are quantified.

The "Manual Watershed" allows for the user to manually input the settings for the interactive watershed for each image, while the "Set Watershed" uniform pre-established settings for all of the images within the file which can be changed in the script itself
