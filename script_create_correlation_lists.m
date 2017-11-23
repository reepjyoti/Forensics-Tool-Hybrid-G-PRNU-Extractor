% Script script_create_correlation_lists.m
%
% A script to create the correlation lists needed by
% run_lucasdigicamident.m.
%
% Format of the correlation list file:
%
% <Camera 1 Reference PRNU data file (.mat)>  <Noise residual from image 1 (.mat) >
% <Camera 1 Reference PRNU data file (.mat)>  <Noise residual from image 2 (.mat) >
% <Camera 1 Reference PRNU data file (.mat)>  <Noise residual from image 3 (.mat) >
%            . . .
% <Camera 1 Reference PRNU data file (.mat)>  <Noise residual from image n (.mat) >
% <Camera 2 Reference PRNU data file (.mat)>  <Noise residual from image 1 (.mat) >
% <Camera 2 Reference PRNU data file (.mat)>  <Noise residual from image 2 (.mat) >
% <Camera 2 Reference PRNU data file (.mat)>  <Noise residual from image 3 (.mat) >
%            . . .
% <Camera 2 Reference PRNU data file (.mat)>  <Noise residual from image n (.mat) >
%
%
%
% H Muammar
% Created: 4 April 2012
%
% THE SOFTWARE FURNISHED UNDER THIS AGREEMENT IS PROVIDED ON AN 'AS IS' BASIS, 
% WITHOUT ANY WARRANTIES OR REPRESENTATIONS EXPRESS OR IMPLIED, INCLUDING, 
% BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS
% FOR A PARTICULAR PURPOSE.
clear

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% Script set up - please edit the following entries according to your
% requirements.

% Set up left hand column PRNU reference file name for camera 1 and camera
% 2. If only one camera is needed then comment out the variable lhcT2
lhcT1 = 'Kodak-V550-S_FF_AVE_S_L.mat';
%lhcT2 = 'Kodak-V550-B_FF_AVE_M_L.mat';

% Now save the result to a file
fileName = 'c:\images\prnu\your-correlation-list.txt';
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% Set up right hand column reference file names
startPath = 'c:\';
FilterSpec = fullfile(startPath, '*.mat');  % Look for .mat files only
% Allow user to specify images and file path
[rhc, inPath, FilterIndex] = uigetfile(FilterSpec, 'Please select noise residual file(s)', 'Multiselect', 'on');

fprintf('Script starting ...\n');

srhc = size(rhc, 2);
list = cell(2, 2.*srhc);

for i=1:srhc
    list(:, i) = {lhcT1, rhc{i}};
end

if exist('lhcT2', 'var') == 1
    k = 0;
    for i=srhc+1:2*srhc
        k = k + 1;
        list(:,i) = {lhcT2, rhc{k}};
    end
end

fid = fopen(fileName, 'wt');

for i=1:2*srhc
    fprintf(fid, '%s %s\n', list{1, i}, list{2, i});
end

fclose(fid);

fprintf('Script complete ...\n');
