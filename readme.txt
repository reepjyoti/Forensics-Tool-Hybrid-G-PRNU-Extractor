Matlab Implementation of the Lucas etc al. (2006) algorithm for source camera identification using the PRNU signature of a digital image sensor

Reference:

Lukas, J., Fridrich, J. & Goljan, M. "Digital camera identification from sensor pattern noise." IEEE Transactions on Information Forensics and Security, 2006, 1, 205 - 214 

Prerequisites:

- The Image Processing Toolbox is required.
- If the Mihcak algorithm for image denoising will be used then the Matlab Wavelets Toolbox is required.
- If the BM3D denoising algorithm will be used, then the BM3D package is needed. This can be downloaded from: http://www.cs.tut.fi/~foi/GCF-BM3D/

The camera identification script may be used in two modes. In 'Reference' mode, a PRNU signature pattern is extracted either from a set of flat-field images or from individual image files. In 'correlate' mode, signature patterns from individual images are correlated with a reference PRNU pattern to determine whether the query image was taken with the same camera that generated the reference PRNU pattern.

USAGE:

1. To use the code, first create a set of flat-field images for your camera. This can be done by first creating a white diffuse light source. This can be done by placing a frosted (matt) Perspex panel in front of an LCD monitor and setting the monitor to display an all white background with maximum or near maximum brightness. Position the camera very close to the perspex panel capture and, if possible, set focus to infinity, and lens focal length to the equivalent to 50mm in 35mm terms. If it is possible, set custom white balance based on the captured white perspex panel. Capture between 50 and 100 images.

Edit run_lucasdigicamident.m and set the following parameters:

	a) Set opMode = 'reference':
	b) Set pmode = 'averagePRNU'
	c) Set inPath to the folder containing the input image files (e.g. 'c:\prnu\flatfields')
	d) Set outPath to the folder where the PRNU reference file (in .mat format) will be used. Make sure it exists before running the script.
	e) Set cameraID to a sequence of characters that uniquely identifies the camera being tested.
	f) Set imageType = 'FF' (i.e. flat-field images)
	g) Set denoiseFilter to specify the denoising filter. Choose from 'mihcak', 'sigma', 'gaussian' and 'bm3d'
	h) Set savewaveletCoeffs to: (0) Don't save wavelet coefficients during Mihcak denoising, or (1) Save the wavelet coefficients. Note this variable only applies when denoising using the Mihcak filter has been selected.
	i) Set overwrite to: (0) use existing denoised images in .\denoise\<filtername>, or (1) to always apply denoising and save, overwriting existing denoised images in .\denoise\<filtername>.
	j) Set iList to specify the names of image files which should be used to generate the reference frame. They should be entered as a set of strings in a cell array. Note, if the iList variable is undefined, then all files ending in .jpg and .png in inPath are processed.
	
Run the script by typing:
>> run_lucasdigicamident

This will save the denoised images in the folder .\denoise\<filtername> under inPath. It will also save the extracted PRNU reference data in outPath. A scaled 8-bit version of the PRNU reference frame is saved as an image file in .\denoise\<filtername>.

2. Create noise residual for each source image. To do this, edit run_lucasdigicamident.m and:
	a) Set opMode = 'reference'
	a) set inPath to point to the source images.
	b) Set pmode = 'singlePRNU'
	c) Set imageType = 'NI' to signify that the file is a noise residual from a naturally captured image, if that is the case.
	
Run the script. This will save the noise residuals as .mat files to the folder defined in the variable outPath. Scaled 8-bit versions of the PRNU reference frame are saved as image files in .\denoise\<filtername>.

3. Correlate the reference pattern against the noise residuals of the individual source images. First, edit the script run_lucasdigicamident.m:

	Set opMode = "correlate"
	
In the section of the code labelled 'Cross Correlation' towards the bottom of run_lucasdigicamident.m:

	a) Set inPath to the folder containing the reference frame .mat file and the noise residual .mat files.
	b) Set outPath to the folder where the correlation results are written.

There are two ways in which correlation can be performed.

3.1. If it is desired to cross-correlate a reference frame with a single noise residual, then:

	a) comment out or delete the variable, rListFile.
	b) set the variable refFileNames to <name of reference PRNU file> and <name of the noise residual>. These are entered as strings in a cell variable.

Run the script; the cross-correlation results between the reference PRNU frame and the noise residual for the red green and blue channels are written to the Matlab Command Window. Nothing is written to the hard disk in this case.

3.2. To cross-correlate a reference PRNU frame with several noise residuals corresponding to sources images, first create a text file containing two columns. The first column should contain the name of the reference file, and the second, the name of the file containing the noise residual for which correlation is to be performed. For example:

<reference PRNU file name> <noise residual 1 file name>
<reference PRNU file name> <noise residual 2 file name>
<reference PRNU file name> <noise residual 3 file name>
<reference PRNU file name> <noise residual 4 file name>

Set the variable rListFile to the path and name of the correlation file. Note that in this case the variable refFileNames is ignored if it is defined. Run the script; the cross-correlation results are written in a file to the folder specified in outPath.

Appendix:

To create a text file containing two columns for correlating the PRNU reference frame with the noise residuals, to options are available:

1. Edit and run the accompanying script 'script_create_correlation_lists.m'. This will create a correlation list file.

2. Create the correlation list file using a text editor such as Notepad++

First create a listing of the noise residual files, using Cygwin and save the listing to disk. e.g. navigate to the folder containing the noise residuals and reference PRNU frame and type ls -1 >listing.txt. Open the file in Notepad++.

Create a new file in Notepad++ and copy the name of the reference PRNU frame file into the new file. Duplicate the file name as many times as there are noise residual files such that a column containing the duplicated file name is formed.

Now copy the list of noise residual file names from the file listing, but this time do it in block edit mode. Delete the name of the reference PRNU file and any other files from the file listing. Then copy in block mode the noise residual file names. This is done by pressing ALT+SHFT+Cursor keys (or ALT+SHFT+ Mouse select) when selecting the noise residual file names. Copy the file names to the clipboard by pressing CTRL+C. Move to the panel containing the new file and position the cursor to the right of the first entry and press CTRL+V. This will copy the noise residual names in block edit mode.

Finally, save the newly created file to disk. Call it something like correlation-listing.txt.


Hani Muammar
December 2014
hkmuammar@gmail.com