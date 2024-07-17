function r = SLF_Recon_Wrapper(config_file, parallel, verbose)

r = 0;

if parallel 
    verbose = false;
end

if isa(config_file, 'struct')
    config_struct = config_file;
elseif (isa(config_file, 'char') | isa(config_file, 'string'))
    fid = fopen(config_file, 'r');
    if fid>=3
        config_struct = jsondecode(fscanf(fid, '%s'));
    else
        error('Invalid path for configuration file.');
    end
else
    error('Invalid config file type.');
end

try
    % main file directory
    filePath = config_struct.filePath;
    psfPath = config_struct.psfPath;

    % read PSFs
    psfName = config_struct.psfName;
    loadExistingPSF = config_struct.loadExistingPSF;           % whether to load PSF mat file saved during previous reconstruction session; if not, PSF will be read and processed from raw PSF images

    % hardware configurations
    scaleRatio = config_struct.scaleRatio;                     % vertical squeezing ratio
    RESOLUTION = config_struct.RESOLUTION;                     % horizontal pixel resolution of each sub-aperture
    PSF_background = config_struct.PSF_background;             % PSF data background, not used if loadExistingPSF = true
    background = config_struct.background;                     % raw image background

    % deconvolution configurations
    iter = config_struct.iter;                                 % iteration number
    intensityScale = config_struct.intensityScale;             % global intensity scaling of recontruction results before saving
    usingGPU = false;                                          % whether to use GPU; highly recommended 
    conv_type = 'simple_fft';                                  % convolution implementation: 'space_domain', space domain convolution, slowest; 'fft', fft based convolution; 'simple_fft', simplified fft based convolution, might be subject to artifacts (rarely though), fastest 

    % in-plane rotations angles
    angles = config_struct.angles;
    ROIpositions = config_struct.ROIpositions;

    % data directory
    dataPath = config_struct.dataPath;
    dataName = config_struct.dataName;
    savePath = fullfile(filePath, config_struct.savePath, dataPath);
    saveName = config_struct.saveName;

catch ME
    if strcmp(ME.identifier, 'MATLAB:nonExistentField')
        variable_name = split(ME.message, '"');
        error(['Invalid configuration file with missing variable: ' variable_name{2}]);
    else
        throw(ME);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create folders and save user parameters
if ~exist(fullfile(filePath, 'Recon_RL'), 'dir')
    mkdir(fullfile(filePath, 'Recon_RL'));
end
if ~exist(savePath, 'dir')
    mkdir(savePath);
end
parameterPath = fullfile(savePath, 'Parameters');
if ~exist(parameterPath, 'dir')
    mkdir(parameterPath);
end
jsonText = jsonencode(var2struct('filePath','psfPath','psfName','scaleRatio',...
    'RESOLUTION','PSF_background','background','loadExistingPSF','iter','intensityScale','usingGPU','conv_type',...
    'angles','ROIpositions', 'dataPath','dataName','savePath','saveName'),"PrettyPrint",true);
fid = fopen(fullfile(parameterPath,['Parameters_' char(datetime('now','format','yyyy-MM-dd-HH-mm-ss-SSS')), '.json' ]), 'w');
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
if parallel
    parfor t = 1:length(dataName)  
        
        tic;

        if verbose
            disp(['Reconstructing frame ' num2str(t) '...']);
        end

        img = flipud(double(imread(fullfile(filePath, dataPath, dataName{t}))));   % image flip here is not required by the algorithm, but only related to camera orientation in our setup
        img = double(uint16(img-background));
        measurements = zeros(round(RESOLUTION*scaleRatio), RESOLUTION, length(angles));

        for i=1:length(angles)
            r1 = ROIpositions(i,2) + ceil(-RESOLUTION*scaleRatio/2);
            r2 = ROIpositions(i,2) + ceil(RESOLUTION*scaleRatio/2) - 1;
            c1 = ROIpositions(i,1) + ceil(-RESOLUTION/2);
            c2 = ROIpositions(i,1) + ceil(RESOLUTION/2) - 1;
            measurements(:,:,i) = img(r1:r2,c1:c2);
        end

        if usingGPU
            measurements = gpuArray(single(measurements));
            initGuess = gpuArray(backward_func(measurements));
        else
            initGuess = backward_func(measurements);
        end

        [IR, ~] = RL_solver_acc(measurements, initGuess, forward_func, backward_func, iter, verbose);

        if usingGPU
            IR_CPU = gather(IR);
        else
            IR_CPU = IR;
        end
        imwrite3d(uint16(IR_CPU* intensityScale), fullfile(savePath, [saveName{t} '.tif']));
        
        disp(['Reconstructed frame ' dataName{t} ' in ' num2str(toc) '.'])

    end
else
    for t = 1:length(dataName)  
        if verbose
            disp(['Reconstructing frame ' num2str(t) '...']);
        end
    
        img = flipud(double(imread(fullfile(filePath, dataPath, dataName{t}))));   % image flip here is not required by the algorithm, but only related to camera orientation in our setup
        img = double(uint16(img-background));
        measurements = zeros(round(RESOLUTION*scaleRatio), RESOLUTION, length(angles));
    
        for i=1:length(angles)
            r1 = ROIpositions(i,2) + ceil(-RESOLUTION*scaleRatio/2);
            r2 = ROIpositions(i,2) + ceil(RESOLUTION*scaleRatio/2) - 1;
            c1 = ROIpositions(i,1) + ceil(-RESOLUTION/2);
            c2 = ROIpositions(i,1) + ceil(RESOLUTION/2) - 1;
            measurements(:,:,i) = img(r1:r2,c1:c2);
        end
    
        if usingGPU
            measurements = gpuArray(single(measurements));
            initGuess = gpuArray(backward_func(measurements));
        else
            initGuess = backward_func(measurements);
        end
    
        [IR, ~] = RL_solver_acc(measurements, initGuess, forward_func, backward_func, iter, verbose);
    
        if usingGPU
            IR_CPU = gather(IR);
        else
            IR_CPU = IR;
        end
        imwrite3d(uint16(IR_CPU* intensityScale), fullfile(savePath, [saveName{t} '.tif']));
    end
end

if verbose
    disp('Reconstructions all finished.');
end

r = 1;

end