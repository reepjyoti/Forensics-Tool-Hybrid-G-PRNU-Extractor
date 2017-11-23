function [cA cH cV cD cS] = fwdWavelets(iIn, nLevel, wname, fname)
%
% Function [cA cH cV cD cS] = fwdWavelets(iIn, nLevel, wname, fname)
%
% Function to compute the forward wavelet transform for an image.
%
% Input:
%   iIn: input image - can be uint8 or double (0-255) or normalized pixel
%       values
%   nLevel: number of levels to calculate wavelets
%   wname: string containing wavelet decomposition filter name (e.g. 'db8')
%   fname: if defined, the cell arrays containing the wavelet coefficients
%       are saved to fname (must include folder and file name).
%
% Output:
%   cA cH CV cD: approximation, horizontal, vertical and diagonal cell
%       arrays containing wavelet coefficients
%   cS: size of original image and each level (excluding final level)
%       required for reconstruction.
%
% H Muammar
% 27 January 2012

fprintf('Calculating forward wavelet transform...\n');

% If input image is integer convert it to type double
if isinteger(iIn)
    iIn = double(iIn);
end

% The pixel values should be in the range should be in 0 - 255.
rVal = max(range(range(iIn)));

if rVal <= 1
    iIn = iIn.*255;     % Scale up the rgb values
end

imS = size(iIn);
if ndims(iIn) == 3
    nChan = imS(3);
else
    nChan = 1;
end

% Assign output image variable
iOut = repmat(0, imS);

% Initialise number of levels and configure cells
%nLevel = 4;             %# Number of decompositions
cA = cell(1,nLevel, nChan);    %# Approximation coefficients
cH = cell(1,nLevel, nChan);    %# Horizontal detail coefficients
cV = cell(1,nLevel, nChan);    %# Vertical detail coefficients
cD = cell(1,nLevel, nChan);    %# Diagonal detail coefficients
cS = zeros([2 nLevel]); % Store size of original and each level (excluding final)- required for decomposition

% Calculate the wavelet transform for each channel
for chan = 1:nChan
    fprintf('... channel %d\n', chan);
    
    % apply the decompositions using the specified decomposition filter and store the detail coefficient 
    % matrices from each step in a cell array
    if nChan > 1
        iA = iIn(:,:,chan);     % Start image
    else
        iA = iIn;   % Assume single channel image
    end

    for iLevel = 1:nLevel
        [cA{1, iLevel, chan}, cH{1, iLevel, chan}, cV{1, iLevel, chan}, cD{1, iLevel, chan}] = dwt2(iA, wname);
        iA = cA{1, iLevel, chan};
    end
end

% Calculate and save the size of each level (excluding the last) - just use 1st channel
cS(:,1) = size(iIn(:,:,1));
for i=2:nLevel
    cS(:,i) = size(cA{1, i-1, 1});
end

if (exist('fname') == 1)        % is variable fname defined?
    save(fname, 'cA', 'cH', 'cV', 'cD', 'cS', 'wname', 'nLevel');
end

return