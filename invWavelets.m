function iOut = invWavelets(cA, cH, cV, cD, wname, cS, fname)
%
% Function iOut = invWavelets(cA, cH, cV, cD, wname, cS, fname)
%
% Calculate the inverse wavelet transform to reconstruct image.
%
% Input:
%   cA cH cV cD: approximation, horizontal, vertical and diagonal
%               wavelet coefficients
%   wname: wavelet decomposition filter name (e.g. 'db8')
%   cS: size of original image and each level (excluding final level)
%       required for reconstruction.
%   fname: if specified then the variables are read from 'fname'
%
% Usage:
%   Pass parameter variables containing wavelet coefficients, decomposition filter
%   name and size
%           iOut = invWavelets(cA, cH, cV, cD, 'db4', cS);
%   Get parameter values from stored file
%           iOut = invWavelets('','','','','','','c:\images\waveletcoeffs.mat');
%
%
% H Muammar
% 27 January 2012

fprintf('Calculating inverse wavelet transform...\n');

if (exist('fname') == 1)
    load(fname);
end

% Extract number of channels from cA
imS = size(cA);
if ndims(cA) == 3
    nChan = imS(3);
else
    nChan = 1;
end

% Assign output image variable
iOut = repmat(0, [cS(:,1)' nChan]);

nLevel = imS(2);

 % Now do a full reconstuction
 for chan = 1:nChan
    fprintf('... channel %d\n', chan);
    fullRecon = cA{1, nLevel, chan};
    for iLevel = nLevel:-1:1
        fullRecon = idwt2(fullRecon, cH{1, iLevel, chan}, cV{1, iLevel, chan},...
            cD{1, iLevel, chan}, wname, cS(:,iLevel));
    end

    fullRecon = max(fullRecon, 0);
    fullRecon = min(fullRecon, 255);
    
    iOut(:,:,chan) = fullRecon;
 end
 
 return