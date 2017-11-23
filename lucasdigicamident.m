function [status varargout] = lucasdigicamident(opMode, gprnu_size, interpolation_method, inpath, outpath, prnuName, iList, addargs)
%
% Function: [status varargout] = lucasdigicamident(opMode, gprnu_size, inpath, outpath, iList, addargs)
%
% Function to apply the algorithm for creating reference image sensor PRNU
% patterns and for cross-correlating camera reference patterns based on the
% paper by Lukas et al.
%
% Input:
% opMode <string>: 'reference': create reference pattern
%       'correlate': cross correlate reference patterns
% inpath <string>: Input folder name containing relevant image files (reference) or
%       prnu data files (correlate).
% outpath <string>:  Output folder name specifying where the prnu data is
%       saved (reference) or where correlation results are written (correlation).
% prnuName <cell>: single cell containing prnu file name to be saved
%       (reference) or two cell elements containing the prnu pattern names to be
%       correlated.
% iList <cell>:    Cell array containing list of image file names for be
%       denoise (reference mode only).
% addargs <cell>:  any additional arguments needed (reference mode only):
%               'reference' additional arguments
%                   - denoise filter name
%                   - folder name for writing denoised images
%                   - other filter specific arguments...
%
% Output:
% status:   When creating reference frames status parameter confirms that
%           operation is complete. When cross correlating reference frames, status
%           contains the results of cross correlating the red, green and blue
%           components.
%
% (optional):   Used only when in correlate mode
% ref1, ref2: the names of the prnu reference files that were correlated
%             colrNames: a cell containing 'Grey' for single channel or 'Red' 'Green'
% 'Blue'     for three channel reference data
% corr:      The results of correlating the reference files
%
% Reference:
% -		Lukas, J., Fridrich, J. & Goljan, M. "Digital camera identification from sensor pattern noise." IEEE Transactions on %		 Information Forensics and Security, 2006, 1, 205-214
%
% Author: H Muammar (hkmuammar@gmail.com)
% Date:   19 December 2011
% updated: 1 December 2014
%
% THE SOFTWARE FURNISHED UNDER THIS AGREEMENT IS PROVIDED ON AN 'AS IS' BASIS, 
% WITHOUT ANY WARRANTIES OR REPRESENTATIONS EXPRESS OR IMPLIED, INCLUDING, 
% BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS
% FOR A PARTICULAR PURPOSE.
%
% This is an updated version including customization for the native PRNU extractor
% Green channel PRNU extractor is being implemented along with 
% Customization for different sizes and interpolation methods
% - REEPJYOTI DEKA
%   Eurecom,
%   deka@eurecom.fr
%
%

% number of output arguments specified by the calling routine
nout =  max(nargout,1);
greenPrnu = 1;           % (0) if normal PRNU required. (1) if G-PRNU required. Currently done only for mihcak.

                
switch opMode
    
% ++++++++++++++++++++++++++++++ Reference Frames +++++++++++++++++++++++++++++
    
case 'reference'        % Generate reference images

    if (nout ~= 1)
    fprintf('error: one output argument should be specified.\n')
            status = -1; return;
    end

    [status1, denoiseFolder] = denoiseImages(inpath, gprnu_size, interpolation_method, iList, addargs);

    if ~status1 == -1
        fprintf('Error with denoising images\n');
        status = -1;
        return;
    end
        
    % Check that prnuName contains one cell element
    if length(prnuName) ~= 1
        fprintf('multiple prnu file names have been specified - only one required\n');
        status = -1;
        return;
    end
    % Extract PRNU pattern and create reference frame
    % Configure buffer used to store difference images
    
    
    if(greenPrnu)
        firstFileName = fullfile(inpath, iList{1});
        [pathF, nameF extF] = fileparts(firstFileName);

        imInfo = imfinfo(fullfile(denoiseFolder, strcat(nameF,'_d.png')));
    else
        imInfo = imfinfo(fullfile(inpath, iList{1}));   % Get image dimensions from first source image
    end
    
    diffImSum = repmat(0, [imInfo.Height imInfo.Width floor(imInfo.BitDepth./8)]);
    
    
    Np = length(iList);
    fprintf('Extracting PRNU pattern\n');
    for iFile = 1:Np
        srcImName = fullfile(inpath, iList{iFile});
        [pathF, nameF extF] = fileparts(srcImName);
        denImName = fullfile(denoiseFolder, [nameF '_d' '.png']);

        srcIm = double(imread(srcImName));
        if(greenPrnu)
            srcImBeforeResize = srcIm;
                if(gprnu_size == 0)
                    srcIm = srcImBeforeResize(:,:,2);
                else
                    srcIm = imresize(srcImBeforeResize(:,:,2), [gprnu_size gprnu_size], interpolation_method);

                end
        end
        denIm = double(imread(denImName));

        diffIm = srcIm - denIm;
        
            %% Enhancement
            %% for better Sensor Pattern Noise converting to ESPN using Li's
            %% model 5
        
        %{
            alpha = 7;
            ESPN = zeros(size(diffIm));
            LTO = find(diffIm<0);
            MTO = find(diffIm>0);
            ESPN(LTO) = -exp(((-0.5).*diffIm(LTO).^2) /alpha^2);
            ESPN(MTO) = exp(((-0.5).*diffIm(MTO).^2) /alpha^2);
            diffIm = ESPN;
        %}
        diffImSum = diffImSum + diffIm;
    end
    diffImSum = diffImSum./Np;

    % Zero mean the PRNU pattern such that the row and column averages are
    % zero. This is done by subtracting the column averages from each pixel
    % and then subtracting the row averages from each pixel. This is done
    % to remove colour interpolation and other artefacts and is implemented
    % in Chen2007a.
    
    % Clear uneeded variables to free up memory
    clear denIm diffIm srcIm;
    
    % Do all channels at once
    colAve = mean(diffImSum, 1);
    
    colAveTemp = repmat(colAve, [size(diffImSum, 1) 1]);
    
    buf = diffImSum - colAveTemp;
    
    rowAve = mean(buf, 2);
    rowAveTemp = repmat(rowAve, [1 size(diffImSum, 2)]);
    
    diffImSum = buf - rowAveTemp;
        
    % At this point we need to save the reference image. Probably a good
    % idea is to write it out as a .mat file. It can also be scaled to 255
    % and saved as an 8-bit image.
    fprintf('Saving pattern\n');
    diffName = fullfile(outpath, [prnuName{1} '.mat']);
    save(diffName, 'diffImSum');
    
    maxDiff = max(max(max(diffImSum)));
    minDiff = min(min(min(diffImSum)));
    
    diffImage = diffImSum - minDiff;
    diffImage = diffImage./(maxDiff - minDiff);
    diffImage = diffImage.*255;
    diffImage = uint8(round(diffImage));
    diffImageName = fullfile(outpath, [prnuName{1} '.png']);
    imwrite(diffImage, diffImageName, 'png');
    
   % greenImageName = fullfile(outpath, [prnuName{1},'_g' '.png']);
   % imwrite(diffImage(:,:,2), greenImageName, 'png');
    
    
% ++++++++++++++++++++++++++++++ Cross Correlation +++++++++++++++++++++++++++++

    case 'correlate'
        
        % Calculate the correlation between a camera reference pattern and:
        %   a) a noise residual from a single image
        %   b) a noise residual from a set of images
        % Correlation must be applied to two diff_data,mat files which are
        % specified by their respective folder names.
        
        % Input arguments:
        %   inpath - the folder containing the  reference frames
        %   outpath - the folder for saving the correlation data
        %   prnuName - a cell array containing:
        %               1) the name of the 1st prnu frame
        %               2) the name of the 2nd prnu frame
        
        if (nout ~= 1) && (nout ~= 5)
            fprintf('error: only one or five output argument may be specified.\n')
            status = -1; return;
        end
    
        if length(prnuName) ~= 2
            fprintf('The names of 2 prnu pattern files are required.\n');
            status = -1;
            return;
        end
        
        ref1 = fullfile(inpath, prnuName{1});
        ref2 = fullfile(inpath, prnuName{2});
        
        if exist(ref1, 'file')
            diff1 = load(ref1);
        else
            fprintf('error: reference file 1 does not exist\n');
            status = -1; return;
        end
        
        if exist(ref2, 'file')
            diff2 = load(ref2);
        else
            fprintf('error: reference file 2 does not exist\n');
            status = -1; return;
        end
        
        d1S = size(diff1.diffImSum);
        d2S = size(diff2.diffImSum);
        
        % Number of planes in diff1
        if ndims(diff1.diffImSum) > 2
            nD1 = d1S(3);
        else
            nD1 = 1;
        end
        
        % Number of planes in diff1
        if ndims(diff2.diffImSum) > 2
            nD2 = d1S(3);
        else
            nD2 = 1;
        end

        % Error if number of planes differ
        if nD1~=nD2
            fprintf('Number of planes differ.\n');
            status = -1; return;
        end
        
        % Error if the dimensions of each plane differ
        for i=1:nD1-1
            if d1S(i) ~= d2S(i)
                fprintf('error: dimensions of difference arrays differ.\n')
                status = -1; return;
            end
        end
        
        % Set up temporary array for holding mean subtracted difference
        % image
        d1 = repmat(0, d1S);
        d2 = repmat(0, d2S);
        
        % Calculate mean subtracted difference images
        %%%% -- HKM note - remove mean subtraction???
        for i=1:nD1
            mDiff1(i) = mean(mean(diff1.diffImSum(:,:,i)));
            d1(:,:,i) = diff1.diffImSum(:,:,i) - mDiff1(i);
 
            mDiff2(i) = mean(mean(diff2.diffImSum(:,:,i)));
            d2(:,:,i) = diff2.diffImSum(:,:,i) - mDiff2(i);
        end

        % Free up memory
        clear diff1 diff2
        
        for i=1:nD1
            num(i) = sum(sum(d1(:,:,i).*d2(:,:,i)));
            den(i) = sqrt(sum(sum(d1(:,:,i).^2))).*...
                sqrt(sum(sum(d2(:,:,i).^2)));
        end
        
        corr = num./den;

        if nD1 == 1
            colrNames = {'Grey'};
        elseif nD1 == 3
            colrNames = {'Red', 'Green', 'Blue'};
        end

        if nout == 1        % Print the results to screen
            
            fprintf('Correlation results:\n');
            fprintf('Reference file 1: %s\n', ref1);
            fprintf('Reference file 2: %s\n', ref2);

            for i=1:nD1
                fprintf('%s: %6.4f  ', colrNames{i}, corr(i));
            end

            fprintf(' Sum: %6.4f\n', sum(corr));
            
        elseif nout == 5
            
            varargout(1) = {ref1};
            varargout(2) = {ref2};
            varargout(3) = {colrNames};
            varargout(4) = {corr};

        end
        
    otherwise
        
end

status = 1;

return