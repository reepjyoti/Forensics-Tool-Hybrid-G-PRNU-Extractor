function [status, denoiseFolder] = denoiseImages(inpath, gprnu_size, interpolation_method, iList, addargs)
%
% function: status = denoiseImages(inpath, outpath, iList, addargs)
%
% Function to denoise images using Gaussian, Mihcak and Sigma filter
% methods.
%
% Input:
% inpath <string>:  folder path to images to be denoised
% iList <cell>:     cell array containing one or more images to denoise
% addargs <cell>:   additional arguments specific to denoising algorithm.
%
%   Gaussian low pass filtering:
%       arg 1 <string>: 'gaussian'
%       arg 2 <string>: folder name where denoised images are to be saved
%       arg 3 <double>:  window size of Gaussian mask
%       arg 4 <double>: standard deviation of Gaussian
%       arg 5 <double>: 0: use denoised file if exists, 1: overwrite file
%
%   Mihcak denoising:
%       arg 1 <string>: 'mihcak'
%       arg 2 <string>: folder name where denoised images are to be saved
%       arg 3 <double>: Value of sigma0 used
%       arg 4 <double>: 0: use denoised file if exists, 1: overwrite file
%
%   Sigma filtering:
%       arg 1 <string>: 'sigma'
%       arg 2 <string>: folder name where denoised images are to be saved
%       arg 3 <double>: window size of sigma filter
%       arg 4 <double>: value for standard deviation
%       arg 5 <double>: 0: use denoised file if exists, 1: overwrite file
%
% Author: H Muammar
% Date:   9 January 2012%
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
    
% Check that denoise filter specified is recognised name
denoiseFilterName = addargs.filterName;
denoiseFolder = addargs.denoiseFolder;
greenPrnu = 1;           % (0) if normal PRNU required. (1) if G-PRNU required. Currently done only for mihcak.

    
% Check that denoise folder exists and create it if it doesn't.
if ~exist(denoiseFolder, 'dir')
     folderCreated = mkdir(denoiseFolder);
     if ~folderCreated
         fprintf('Error creating denoise folder\n');
         status = -1;
         return
     end
 end

 fprintf('Denoising images ');
 switch denoiseFilterName
        
        case 'gaussian'
            fprintf('using Gaussian\n');
            % Initialise parameters and create denoise folder
            
            filterSize = addargs.filterSize;      % Window size of Gaussian
            filterSD = addargs.filterSD; % Standard deviation of Gaussian
            overwrite = addargs.overwrite;       % 0: use denoised file if exists, 1: overwrite file
            
            % Apply denoising and save denoised image
            farray = fspecial('gaussian', filterSize, filterSD);
            for iFile = 1:length(iList)
                
                fileName = fullfile(inpath, iList{iFile});
                [pathF, nameF extF] = fileparts(fileName);
                extF = '.png';
                
                if (~exist(fullfile(denoiseFolder, [nameF '_d' extF]), 'file') | overwrite)
                    imIn = imread(fileName);
                    imOut = imfilter(imIn, farray, 'replicate');
                    fileName = fullfile(denoiseFolder, [nameF '_d' extF]);
                    imwrite(imOut, fileName, 'png');
                end
            end
            clear imIn imOut

        case 'mihcak'
            fprintf('using Mihcak Wavelets\n');

            sigma0 = addargs.sigma0;         % Value of sigma0 used by Mihcak alg
            overwrite = addargs.overwrite;   % 0: use denoised file if exists, 1: overwrite file
            saveWaveletCoeffs = addargs.saveWaveletCoeffs;

            if saveWaveletCoeffs
                saveWaveletFolder = fullfile(inpath, 'wavelet');

                if ~exist(saveWaveletFolder, 'dir')
                    folderCreated = mkdir(saveWaveletFolder);
                    if ~folderCreated
                        fprintf('Error creating wavelet folder\n');
                        status = -1;
                        return
                    end
                end
            end
                
            % Apply denoising and save the denoised images
            for iFile = 1:length(iList)

                fileName = fullfile(inpath, iList{iFile});
                [pathF, nameF extF] = fileparts(fileName);                

                extF = '.png';
                
                if (~exist(fullfile(denoiseFolder, [nameF '_d' extF]), 'file') | overwrite)
                    if saveWaveletCoeffs
                        waveletFileName = fullfile(saveWaveletFolder, [nameF '_w.mat']);
                    else
                        waveletFileName = '';
                    end
                    imIn = imread(fileName);
                    if(greenPrnu)
                        imInBeforeGreenResize = imIn;
                        
                        if(gprnu_size == 0)
                            imIn = imInBeforeGreenResize(:,:,2);
                        else
                            imIn = imresize(imInBeforeGreenResize(:,:,2), [gprnu_size gprnu_size], interpolation_method);
                        end
                    end
                    
                    imOut = waveletDenoise(imIn, sigma0, waveletFileName);
                    imOut = uint8(round(imOut));
                    fileName = fullfile(denoiseFolder, [nameF '_d' extF]);
                    imwrite(imOut, fileName, 'png');
                end
            end
            clear imIn imOut
            
        case 'sigma'
            fprintf('using Sigma filter\n');
            windowSize = addargs.windowSize;
            stdval = addargs.stdval;
            overwrite = addargs.overwrite;
            
            % Apply denoising and save the denoised images
            for iFile = 1:length(iList)

                fileName = fullfile(inpath, iList{iFile});
                [pathF, nameF extF] = fileparts(fileName);

                extF = '.png';
                
                if (~exist(fullfile(denoiseFolder, [nameF '_d' extF]), 'file') | overwrite)
                    imIn = imread(fileName);
                    imOut = applySigmaFilter(imIn, windowSize, stdval);
                    imOut = uint8(round(imOut));
                    fileName = fullfile(denoiseFolder, [nameF '_d' extF]);
                    imwrite(imOut, fileName, 'png');
                end
            end
            clear imIn imOut
            
     case 'bm3d'
         fprintf('using BM3D colour image denoising\n');
         sigma = addargs.sigma;     % this is the estimated standard deviation of the noise in the image in range [0 255]
         overwrite = addargs.overwrite;
         
         % Apply denoising and save the denoised images
         for iFile = 1:length(iList)

             fileName = fullfile(inpath, iList{iFile});
             [pathF, nameF extF] = fileparts(fileName);
             
             extF = '.png';
             
             if (~exist(fullfile(denoiseFolder, [nameF '_d' extF]), 'file') | overwrite)
                    imIn = imread(fileName);
                    imIn = double(imIn)./255;   % Normalise to range 0 to 1
                    [NA, imOut] = CBM3D(1, imIn, sigma);
                    imOut = uint8(round(imOut.*255.0));
                    fileName = fullfile(denoiseFolder, [nameF '_d' extF]);
                    imwrite(imOut, fileName, 'png');
             end
                
         end
        otherwise
            fprintf('Denoise filter specified unkown.\n');
            status = -1;
            return
 end

status = 1;

return