%% 3D Reconstruction code for squeezed light field microscopy (SLIM) using Richardson-Lucy Deconvolution
% Wang, Zhaoqiang, et al. "Kilohertz volumetric imaging of in-vivo dynamics using squeezed light field microscopy." bioRxiv (2024)
% Tested on Matlab 2022a, 2023a, GPU is recommended 
%
% Usage:
% 1. Modify User parameters section for correct file path, save path, PSF and SLIM hardware configurations 
% 2. Run
%
addpath('./utils');
%% User parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%User parameters%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main file directory
filePath = './examples/beads';
psfPath = 'PSF_320';

% read PSFs, implementation is subject to PSF data naming conventions
psfName = {};
psfLocations = -200:4:200; % 200 um to 200 um at a step size 4 um
for p = 1:length(psfLocations)
    psfName{p}=[num2str(psfLocations(p)) '.tiff.tif'];
end

% data directory
dataPath = 'data/beads_100ms_ROI_1455_320_LED';

% read raw data, implementation is subject to data naming conventions
dataName = {};
saveName = {};
ind=1;
for d = 1:1
    dataName{ind}=['ss_single_' num2str(d) '.tiff']; % PVCAM teledyne saves images in ss_single_i.tiff
    saveName{ind}=['ss_single_' num2str(d)];
    ind = ind + 1;
end

% hardware configurations
scaleRatio = 0.2;                          % vertical squeezing ratio
RESOLUTION = 295;                          % horizontal pixel resolution of each sub-aperture
PSF_background = 200;                      % PSF data background, not used if loadExistingPSF = true
background = 1500;                         % raw image background
loadExistingPSF = true;                    % whether to load PSF mat file saved during previous reconstruction session; if not, PSF will be read and processed from raw PSF images

% deconvolution configurations
iter = 16;                                 % iteration number
intensityScale = 0.1;                      % global intensity scaling of recontruction results before saving
debug = false;                             % debug mode; if enabled, it will save and show intermediate results
usingGPU = true;                           % whether to use GPU; highly recommended 
conv_type = 'simple_fft';                  % convolution implementation: 'space_domain', space domain convolution, slowest; 'fft', fft based convolution; 'simple_fft', simplified fft based convolution, might be subject to artifacts (rarely though), fastest 


% in-plane rotations angles
% the 29 sub-aperture setup used in the paper
angles = 2*[-25.85;-35;-43.65;32.18;23.57;-9.75;-19.2;-37.85;35.66;13.295;7.74;-3.65;-6.15;-41;41.9;38.795;4.405;0.905;9.915;16.35;26.125;-28.28;-15.3;-11.955;19.405;28.85;-47.5;-31.4;-20.85];
% the 19 sub-aperture setup used in the paper
% angles = 2*[-9.75;-19.2;-37.85;35.66;13.295;7.74;-3.65;-6.15;-41;41.9;38.795;4.405;0.905;9.915;16.35;26.125;-28.28;-15.3;-11.955;];

% load calibration file which saves the center position of each sub-aperture. This file is generated by utils/calibration_semiauto.m and saved in the PSF folders
load(fullfile(filePath, psfPath, 'Calibration.mat'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create folders and save user parameters
if ~exist(fullfile(filePath, 'Recon_RL'), 'dir')
    mkdir(fullfile(filePath, 'Recon_RL'));
end
savePath = fullfile(filePath, 'Recon_RL', dataPath);
if ~exist(savePath, 'dir')
    mkdir(savePath);
end
parameterPath = fullfile(savePath, 'Parameters');
if ~exist(parameterPath, 'dir')
    mkdir(parameterPath);
end
jsonText = jsonencode(var2struct('filePath','psfPath','psfName','dataPath','dataName','saveName','scaleRatio',...
    'RESOLUTION','PSF_background','background','loadExistingPSF','iter','intensityScale','debug','usingGPU','conv_type',...
    'angles','ROIpositions', 'savePath'),"PrettyPrint",true);
fid = fopen(fullfile(parameterPath,'Parameters.json'), 'w');
fprintf(fid, '%s', jsonText);
fclose(fid);
%% read PSFs
if ~loadExistingPSF
    [H, Ht] = SLF_get_PSFs(fullfile(filePath,psfPath), psfName, ROIpositions, [RESOLUTION,round(RESOLUTION*scaleRatio)], PSF_background, true, false, true);
else
    load(fullfile(filePath,psfPath,['PSF_resolution_' num2str(RESOLUTION) '_' num2str(round(RESOLUTION*scaleRatio)) '_z_' num2str(length(psfName)) '_subaperture_' num2str(size(ROIpositions,1)) '.mat']))
end

if usingGPU
    H = gpuArray(single(H));
    Ht = gpuArray(single(Ht));
    forward_func = @(vol) SLF_forward_GPU(vol, angles, H, true, conv_type);
    backward_func = @(projection) SLF_backward_GPU(projection, angles, Ht, true, conv_type);
else
    forward_func = @(vol) SLF_forward(vol, angles, H, true);
    backward_func = @(projection) SLF_backward(projection, angles, Ht, true);
end
%% reconstruction
for t = 1:length(dataName)  

disp(['Reconstructing frame ' num2str(t) '...']);
img = flipud(double(imread(fullfile(filePath, dataPath, dataName{t}))));   % image flip here is not required by the algorithm, but only related to camera orientation in our setup
img = double(uint16(img-background));
measurements = zeros(round(RESOLUTION*scaleRatio), RESOLUTION, length(angles));

if debug
    figure; imagesc(img);hold on;
end

for i=1:length(angles)
    r1 = ROIpositions(i,2) + ceil(-RESOLUTION*scaleRatio/2);
    r2 = ROIpositions(i,2) + ceil(RESOLUTION*scaleRatio/2) - 1;
    c1 = ROIpositions(i,1) + ceil(-RESOLUTION/2);
    c2 = ROIpositions(i,1) + ceil(RESOLUTION/2) - 1;
    measurements(:,:,i) = img(r1:r2,c1:c2);
    if debug
        rectangle('Position',[c1 r1 RESOLUTION round(RESOLUTION*scaleRatio)], 'EdgeColor','r');    
    end
end
if debug
    hold off;
end

if debug
    imwrite3d(uint16(measurements), fullfile(savePath, 'temp1.tif'));
    temp2 = zeros(RESOLUTION,RESOLUTION,length(angles));
    for i=1:length(angles)
        temp2(:,:,i) = imrotate(imresize(measurements(:,:,i),[RESOLUTION,RESOLUTION], 'Method', 'bilinear'),-angles(i),'bilinear','crop');
    end
    imwrite3d(uint16(temp2), fullfile(savePath, 'temp2.tif'));
end

if usingGPU
    measurements = gpuArray(single(measurements));
    initGuess = gpuArray(backward_func(measurements));
else
    initGuess = backward_func(measurements);
end

[IR, err] = RL_solver_acc(measurements, initGuess, forward_func, backward_func, iter, true);
err(end)
if usingGPU
    IR_CPU = gather(IR);
else
    IR_CPU = IR;
end
imwrite3d(uint16(IR_CPU* intensityScale), fullfile(savePath, [saveName{t} '.tif']));
end
disp('Reconstructions all finished.');