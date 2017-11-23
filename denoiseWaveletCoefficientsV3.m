function cHTP = denoiseWaveletCoefficientsV3(cHT, s0)
%
% Function to apply denoising to Wavelet coefficients
% Revision:
% V2: More efficient implementation using colfilt().
%
% H Muammar
% 16 December 2011

v0 = s0.^2;

cHTS = size(cHT);

windowSizes = [3 5 7 9];

varE = repmat(0, [length(windowSizes) cHTS(1).*cHTS(2)]);

k = 1;
for w = windowSizes
    
    p = floor(w./2);    % number of pixels of padding needed at top/bottom left/right
    buf = padarray(cHT, [p p], 'symmetric');
    bufS = size(buf);
    
    c = im2col(buf, [w w], 'sliding');  % Rearrange image blocks in columns
    
    csum = sum(c.^2, 1);    % Sum neighbourhood windows
    csum = csum./(w.^2);
    
    csum = csum - v0;
    
    varE(k, :) = max(csum, 0);
    
    k = k + 1;
end

varMin = min(varE, [], 1);

% Convert minimum variances back to an image
varEst = col2im(varMin, [w w], bufS, 'sliding');

cHTP = cHT.*varEst./(varEst + v0);

return