%% Synthesize a stack from a series of 3D reconstrution
% this is for scanning light sheet mode where each measurement only
% captures several slices where light sheet are shed.
% this script combines multiple measurement reconstruction during a scan

% a lightsheet.xlsx file is used to indicate which measurement reconstruct
% which layers of the synthesized stack.

% This code is only for reference. Refer to the manuscript for more details


filePath = 'E:\GaoLab\ScaleLightField\20240315';
dataPath = 'Recon_RL/data/fish4_240us_4000fps_ROI_1455_320_m5_100mV_100Hz_scanning';
savePath = fullfile(filePath, 'Recon_RL/data/fish4_240us_4000fps_ROI_1455_320_m5_100mV_100Hz_scanning_Scanning');
scanningT = readtable(fullfile(filePath, '/data/fish4_240us_4000fps_ROI_1455_320_m5_100mV_100Hz_scanning', 'lightsheet.xlsx'));

if ~exist(savePath, 'dir')
    mkdir(savePath);
end

dataName = {};
ind=1;
for d = 41:80
    dataName{ind}=['ss_single_' num2str(d) '.tif'];
    ind = ind + 1;
end

% light sheet scanning parameters
nStep = 40;
nSlice = 78;

% 
RESOLUTION = 295;
initTime = 1;
%% reconstruction
idxStep = 1;
idxTime = initTime; 
for t = 1:length(dataName)
    
if idxStep==1
    disp(['Reconstructing time step ' num2str(idxTime) '...']);
    tic;
    zeroStack = zeros(RESOLUTION, RESOLUTION, nSlice);
end
if scanningT{idxStep,2}==0
    if idxStep<nStep
        idxStep = idxStep+1;
    else
        idxStep = 1;
        imwrite3d(uint16(zeroStack), fullfile(savePath, ['time_' num2str(idxTime) '.tif']));
        idxTime = idxTime + 1;
        disp(['Finished time step ' num2str(idxTime-1) ' in ... ' num2str(toc) 's']);
    end
    continue;
end

img3d = imread3d(fullfile(filePath, dataPath, dataName{t}));

zeroStack(:,:,scanningT{idxStep,3}) = img3d(:,:,scanningT{idxStep,2});
zeroStack(:,:,scanningT{idxStep,5}) = img3d(:,:,scanningT{idxStep,4});

if idxStep<nStep
    idxStep = idxStep + 1;
else
    idxStep = 1;   
    imwrite3d(uint16(zeroStack), fullfile(savePath, ['time_' num2str(idxTime) '.tif']));
    idxTime = idxTime + 1;
    disp(['Finished time step ' num2str(idxTime-1) ' in ... ' num2str(toc) 's']);
end

end

disp('Reconstructions all finished.');