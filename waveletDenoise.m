function iOut = waveletDenoise(iIn, sigma0, fname)
%
% Function iOut = waveletDenoise(iIn)
%
% Function to apply image denoising based on the method described in Mihcak
% et al paper.
%
% Input:
%   Iin:    input image - can be uint8 or double and 8-bit or normalized
%           code values.
%   sigma0: the value for sigma0
%   fname: optional output filename for wavelet coefficients
% Output:
%   iOut:   output denoised image - type double with ...
%
% H Muammar
% 19 December 2011

fprintf('Applying wavelet denoising...\n');

if ~exist('sigma0', 'var')
    s0 = 5; % Recommended value for sigma0 for images in the range 0 - 255
else
    s0 = sigma0;
end

imS = size(iIn);
if ndims(iIn) == 3
    nChan = imS(3);
else
    nChan = 1;
end

nLevel = 4;

% Save wavelet coefficients while denoising the image - optional
if ((exist('fname') == 1) & (~isempty(fname)))
    [cA cH cV cD cS] = fwdWavelets(iIn, nLevel, 'db4', fname);
else
    [cA cH cV cD cS] = fwdWavelets(iIn, nLevel, 'db4');
end

% Apply denoising to each channel
for chan = 1:nChan
    fprintf('Denoising channel %d\n', chan);
 
    fprintf('... denoising subband level ');
    for iLevel = 1:nLevel
        fprintf('%d ', iLevel);
        % Process horizontal detail coefficient
        cHOut = denoiseWaveletCoefficientsV3(cH{1, iLevel, chan}, s0);
        cH{1, iLevel, chan} = cHOut;

        % Process vertical detail coefficient
        cVOut = denoiseWaveletCoefficientsV3(cV{1, iLevel, chan}, s0);
        cV{1, iLevel, chan} = cVOut;

        % Process diagonal detail coefficient
        cDOut = denoiseWaveletCoefficientsV3(cD{1, iLevel, chan}, s0);
        cD{1, iLevel, chan} = cDOut;
    
    end

    fprintf('\n');
end

iOut = invWavelets(cA, cH, cV, cD, 'db4', cS);

fprintf('Complete\n');

return