% script - run_lucasdigicamident.m
%
% Script to run lucasdigicamident.m To run the script the user must specify the following:
%
%   pmode:      'averagePRNU': the PRNU pattern is extracted from multiple noise
%                   residuals
%               'singlePRNU': a single PRNU pattern (in fact a noise residual)
%                   is saved for each image
%   inPath:      Folder name containing input images (flat-field or natural)
%   cameraID:    An identifier at the start of the PRNU filename relating to
%                   the camera make and model
%   imageType:   Set this to NI for natural images and FF for full frame
%   denoiseFilter: Select which denoising filter you wish to use.
%   iList:       Specify individual filenames or leave undefined to use all image
%                   files in folder.
%
% The format of the PRNU file is:
%       <cameraID>_<imageType>_<Image#>_denoiseFilter>_<alg>
%
% or for PRNU pattern averaged over multiple files
%
%       <cameraID>_<imageType>_AVE_denoiseFilter>_<alg>
%
% Requirements:
% - The Matlab Image Processing Toolbox is required.
% - The Matlab Wavelets Toolbox if the Mihcak denoising filter is used.
% - The BM2D package is needed if denoising using this method will be used.
%   The package can be downloaded from http://www.cs.tut.fi/~foi/GCF-BM3D/.
%
% H Muammar (hkmuammar@gmail.com)
% 25 January 2012
%
% THE SOFTWARE FURNISHED UNDER THIS AGREEMENT IS PROVIDED ON AN 'AS IS' BASIS, 
% WITHOUT ANY WARRANTIES OR REPRESENTATIONS EXPRESS OR IMPLIED, INCLUDING, 
% BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS
% FOR A PARTICULAR PURPOSE.
%
%
% This is an updated version including customization for the native PRNU extractor
% Green channel PRNU extractor is being implemented along with 
% Customization for different sizes and interpolation methods
% - REEPJYOTI DEKA
%   Eurecom,
%   deka@eurecom.fr
%
%

clear
%{
featureStr = {'MATLAB'; 'Image_Toolbox'; 'Wavelet_Toolbox'};


index = cellfun(@(f) license('test',f),featureStr);
availableFeatures = featureStr(logical(index));

% Check that the Image Processing Toolbox is installed
features = strcmp('Image_Toolbox', availableFeatures);

% Check that Wavelet Toolbox is installed
% features = strcmp('Wavelet_Toolbox', availableFeatures);
%}
% Checking availability of toolboxes
if ~license('test', 'image_toolbox')
    fprintf('Image Processing Toolbox is missing.\n');
    return
end
if license('test', 'wavelet_toolbox')
    wavInst = true;
else
    wavInst = false;
end

% Set Discrete Wavelet Transform extension mode to
% periodization.
if wavInst
    if ~strcmp(dwtmode('status', 'nodisp'), 'per')
        dwtmode('per', 'nodisp');
    end
end

opMode = 'reference';
%opMode = 'correlate';

fprintf('run_lucasdigicamident: Mode is %s\n', opMode);

switch opMode

% ++++++++++++++++++++++++++++++ Extract PRNU +++++++++++++++++++++++++++++

case 'reference'

% ------- User configurable parameters for 'reference' mode ----------

%pmode = 'singlePRNU';      % 'averagePRNU': compute the PRNU by averaging over all noise residuals
                            % 'singlePRNU' : compute an individual PRNU pattern (noise residual) for each image
pmode = 'averagePRNU';

inPath = '/cluster/deka/VISION/D07_Lenovo_P70A/12';      % folder containing input images

outPath = '/cluster/deka/VISION/References';      % This is where the prnu reference data are saved (.mat file)


% If G-PRNU required, update the following lines as well:
% line 62 in lucasdigicamident.m 
% line 49 in denoiseImages.m 
greenPrnu = 1;           % (0) if normal PRNU required. (1) if G-PRNU required. Currently done only for mihcak.
gprnu_size = 7201280;         %  size of the extracted G-PRNU (in px). default 0 to get un-resized GPRNU
                         %  Give interpolation method in the next line if gprnu_size > 0
                         %   ,num2str(gprnu_size),
interpolation_method = 'nearest';

cameraID = strcat('D07_',num2str(gprnu_size),'_',interpolation_method);  % Identifier for camera make/model

imageType = 'NI';         % Specify argument as FF for flat-field and NI for natural image

denoiseFilter = 'mihcak'; % Specify the denoising filter: 'mihcak', 'sigma', 'gaussian','bm3d'

saveWaveletCoeffs = 0;      % (0) Don't save wavelet coefficients (1) Save the wavelet coefficients. NOTE - only applies when using the Mihcak wavelet based denoising algorithm. Coefficient is ignored otherwise

overwrite = 1;          % (0) use existing denoised images; (1) Overwrite existing denoised images



% Specify image names. Two options are available:
%    1) If iList variable is commented out or not defined, then all the
%    images in the folder inPath are used.
%    2) If iList is defined then only the images listed in iList are used.
%
%iList = {'IMG_0001.JPG' 'IMG_0002.JPG' 'IMG_0003.JPG'};  % Specify image names. If iList is commented out then all images in folder inPath are used

% --------- end of user configurable parameters ------

% Search for jpeg and png files
if (~exist('iList') == 1)
    fileData = rdir([inPath, '/*.*'], 'regexp(name, [''.bmp'' ''|'' ''.jpg''], ''ignorecase'')', true);
    iList = {fileData.name};
end

% Create PRNU name

switch pmode
    case 'averagePRNU'
        imageID = 'AVE';
        prnuName = {[cameraID '_' imageType '_' imageID]};
    case 'singlePRNU'
        nL = length(iList);
        for i=1:nL
            [b1 imageID b2] = fileparts(iList{i}); clear b1 b2;
            prnuName{i} = {[cameraID '_' imageType '_' imageID]};
        end
end

denoiseFolderRoot = [inPath '/denoise'];

addargs.filterName = denoiseFilter;
switch denoiseFilter
    
    case 'gaussian'    % Use Gaussian LPF 
    
        addargs.denoiseFolder = [denoiseFolderRoot '\gaussian'];     % Folder to save denoised images
        addargs.filterSize = [3 3];     % Filter size
        addargs.filterSD = 0.5;         % Gaussian filter standard deviation
        addargs.overwrite = overwrite;          % 0: use denoised file if exists, 1: overwrite file
        
        switch pmode
            case 'averagePRNU'
                prnuName{1} = [prnuName{1} '_G'];
            case 'singlePRNU'
                for i=1:nL
                    prnuName{i} = {[prnuName{i}{:} '_G']};
                end
        end
        
    case 'mihcak'       % Use Mihcak wavelet based denoising algorithm
        
        if ~wavInst
            fprintf('Warning: Mihcak filter selected but Wavelet Toolbox is not available.\n');
        end
        addargs.denoiseFolder = [denoiseFolderRoot '/mihcak'];     % Folder to save denoised images
        addargs.sigma0 = 5;     % value of sigma0
        addargs.overwrite = overwrite;
        addargs.saveWaveletCoeffs = saveWaveletCoeffs;      % Save wavelet coefficients as a .mat file
        
        switch pmode
            case 'averagePRNU'
                prnuName{1} = [prnuName{1} '_M'];
            case 'singlePRNU'
                for i=1:nL
                    prnuName{i} = {[prnuName{i}{:} '_M']};
                end
        end

    case 'sigma'        % Use Sigma filter
        
        addargs.denoiseFolder = [denoiseFolderRoot '\sigma'];     % Folder to save denoised images
        addargs.windowSize = 7;         % window size to use in sigma filter
        %addargs.stdval = [2.35 1.6 2.0];           % value for standard deviation of flat field images for Kodak V550
        addargs.stdval = [2.0 2.0 2.0];           % value for standard deviation of flat field images for Kodak V550
        addargs.overwrite = overwrite;          % 0: use denoised file if exists, 1: overwrite file
        
        switch pmode
            case 'averagePRNU'
                prnuName{1} = [prnuName{1} '_S'];
            case 'singlePRNU'
                for i=1:nL
                    prnuName{i} = {[prnuName{i}{:} '_S']};
                end
        end
        
    case 'bm3d'     % Use the method of denoising by sparse 3D transform-domain collaborative filtering
        
        addargs.denoiseFolder = [denoiseFolderRoot '\bm3dFolder'];
        addargs.sigma = 0.4;        % Use a standard deviation of 1.0 (for intensities in range [0 255]
        addargs.overwrite = overwrite;      % use denoised file if it exists
        
        switch pmode
            case 'averagePRNU'
                prnuName{1} = [prnuName{1} '_B'];
            case 'singlePRNU'
                for i=1:nL
                    prnuName{i} = {[prnuName{i}{:} '_B']};
                end
        end
        
    otherwise
        
        fprintf('Unknown filter\n');

end

switch pmode
    case 'averagePRNU'
        prnuNameID = {[prnuName{1} '_L']};
        status = lucasdigicamident(opMode, gprnu_size, interpolation_method, inPath, outPath, prnuNameID, iList, addargs);
    case 'singlePRNU'
        for i=1:nL
            prnuNameID = {[prnuName{i}{:} '_L']};
            iListID = iList(i);
            status = lucasdigicamident(opMode, gprnu_size, interpolation_method, inPath, outPath, prnuNameID, iListID, addargs);
        end
end


% ++++++++++++++++++++++++++++++ Cross Correlation +++++++++++++++++++++++++++++

case 'correlate'

% ------- User configurable parameters for 'correlate' mode ----------
gprnu_size = 0;           % (0) initialising variable. 

    
inPath = 'E:\Reep\PRNU\VISION\D03_Huawei_P9\flat';

outPath = 'E:\Reep\PRNU\VISION\References';      % This is where the correlation results file is written

% If correlating a reference frame with a SINGLE noise residual:
%    1) Comment out rListFile
%    2) Set refFileNames to {<name of reference PRNU file>, <name of noise residual>}
% After running the script, the correlation results for the red, green and
% blue channels are written to Matlab Command Window. No files are saved.
%
% If correlating a reference PRNU frame with MULTIPLE noise residuals:
%   1) Create a text file containing two columns. The first column should contain the
%      name of the reference file, and the second the name of the noise residual
%      file. (See accompanying readme.txt).
%   2) Set rListFile to the path and name of the correlation list text file
%      created in step 1. The variable refFilenames is ignored, if it is
%      defined.
% After running the script, the cross-correlation results are written to a
% file in the folder specified by outPath.
% 

%rListFile = 'c:\images\prnu\correlation-list.txt';   % Comment out if individual prnu reference filenames in refFileNames, below, are to be used instead.

size= 640 ;% size of GPRNU
interpolation_method= 'nn' ; % interpolation_method (bc,bl,nn)

imageRef = strcat('D03',num2str(size),'_',interpolation_method,'_NI_AVE_M_L.mat')
vidRef = strcat('D03',num2str(size),'_',interpolation_method,'_NI_AVE_M_L.mat')

refFileNames = {imageRef, vidRef}; % This is ignored if rListFile above is defined

% --------- end of user configurable parameters ------

if exist('rListFile') == 1
    
    fid = fopen(rListFile, 'r');

    % Read pairs of prnu reference filenames from list.
    rList = textscan(fid, '%s %s');

    rList1 = rList{1};
    rList2 = rList{2};

    nList = size(rList1, 1);    % Number of entries

    % Create a file for wrinting correlation results
    dateNow = datestr(now, 30);
    
    cResultsFileName = fullfile(outPath, ['corlnResults-' datestr(now, 30) '.txt']);
    fidw = fopen(cResultsFileName, 'wt');
    
    fprintf(fidw, 'Correlation results on: %s\n', datestr(datenum(dateNow, 'yyyymmddTHHMMSS'), 0));
    fprintf(fidw, 'Reference folder: %s\n', inPath);
    
    for i = 1:nList
        prnuName = {rList1{i}, rList2{i}};
        [status, ref1, ref2, colrNames, corr] = lucasdigicamident(opMode, gprnu_size, interpolation_method, inPath, outPath, prnuName);
        fprintf(fidw, '%s %s ', strtok(rList1{i}, '.'), strtok(rList2{i}, '.'));
        
        for j=1:length(colrNames)
            fprintf(fidw, '%s: %6.4f  ', colrNames{j}, corr(j));
        end
            
        fprintf(fidw, ' Sum: %6.4f\n', sum(corr));
    end

    fclose(fidw);
    
else
    prnuName = refFileNames;
    status = lucasdigicamident(opMode, gprnu_size,'', inPath, outPath, prnuName);

end

end
