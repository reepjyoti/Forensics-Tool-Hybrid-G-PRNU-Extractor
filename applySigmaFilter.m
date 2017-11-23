function imOut = applySigmaFilter(imIn, windowSize, stdval)
%
% Function iOut = applySigmaFilter(imIn, windowSize)
%
% Apply Jong-Sen Lee's Sigma filter (1983) to denoise the image
%
% Input:
%   Iin: input image - can be uint8 or double and 8-bit or normalized
%           code values.
%   windowSize: the window size of the sigma filter (should be odd number)
%   stdval: standard deviation of code values for red, green and blue channels in smooth regions of the
%   image. This value is required by the sigma filter and should be
%   representative of the image being smoothed.
%
% Output:
%   iOut:   output denoised image - type double with ...
%
% H Muammar
% 20 December 2011

fprintf('Applying sigma filter for denoising...\n');

if ~exist('windowSize', 'var')
    windowSize = 7; % Recommended value for window size over which to apply the Sigma filtering
end

if ~exist('stdval', 'var')
    stdval = [2.0 2.0 2.0];   % Set it to some typical value for low noise image
end

% If input image is integer convert it to type double
if isinteger(imIn)
    imIn = double(imIn);
end

% Set the range to 0 - 255.
%rVal = max(range(range(imIn)));
rVal = max(max(imIn)) - min(min(imIn));

if rVal <= 1
    imIn = imIn.*255;     % Scale up the rgb values
end

imS = size(imIn);
if ndims(imIn) == 3
    nChan = imS(3);
else
    nChan = 1;
end

% Assign output image
imOut = repmat(0, imS);

for chan = 1:nChan
    fprintf('Denoising channel %d\n', chan);
    
    buf = padarray(imIn(:,:,chan), [windowSize windowSize], 'symmetric');
    bufS = size(buf);
    bufOut = colfilt(buf, [windowSize windowSize], 'sliding', @sigmaFiltFcn, stdval(chan));
    
    bufOut = max(bufOut, 0);
    butOut = min(bufOut, 255);
 
    imOut(:,:,chan) = bufOut(windowSize+1:bufS(1)-windowSize, ...
        windowSize+1:bufS(2)-windowSize);
end

return