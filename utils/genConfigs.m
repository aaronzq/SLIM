%% User parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%User parameters%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

configName = 'config1';

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
usingGPU = false;                           % whether to use GPU; highly recommended 
conv_type = 'simple_fft';                  % convolution implementation: 'space_domain', space domain convolution, slowest; 'fft', fft based convolution; 'simple_fft', simplified fft based convolution, might be subject to artifacts (rarely though), fastest 

% in-plane rotations angles
% the 29 sub-aperture setup used in the paper
angles = 2*[-25.85;-35;-43.65;32.18;23.57;-9.75;-19.2;-37.85;35.66;13.295;7.74;-3.65;-6.15;-41;41.9;38.795;4.405;0.905;9.915;16.35;26.125;-28.28;-15.3;-11.955;19.405;28.85;-47.5;-31.4;-20.85];
% the 19 sub-aperture setup used in the paper
% angles = 2*[-9.75;-19.2;-37.85;35.66;13.295;7.74;-3.65;-6.15;-41;41.9;38.795;4.405;0.905;9.915;16.35;26.125;-28.28;-15.3;-11.955;];

% load calibration file which saves the center position of each sub-aperture. This file is generated by utils/calibration_semiauto.m and saved in the PSF folders
load(fullfile(filePath, psfPath, 'Calibration.mat'));
savePath = fullfile(filePath, 'Recon_RL', dataPath);

configPath = './RUN';
if ~exist(configPath, 'dir')
    mkdir(configPath);
end

jsonText = jsonencode(var2struct('filePath','psfPath','psfName','scaleRatio',...
    'RESOLUTION','PSF_background','background','loadExistingPSF','iter','intensityScale','debug','usingGPU','conv_type',...
    'angles','ROIpositions', 'dataPath','dataName','savePath','saveName'),"PrettyPrint",true);
fid = fopen(fullfile(configPath,[configName, '.json' ]), 'w');
fprintf(fid, '%s', jsonText);
fclose(fid);