function [H, Ht] = SLF_get_PSFs(filePath, fileName, coordinates, resolutions, background, normalize_psf, visualize, save_mat)
% Read PSF images and construct H and Ht matrix for deconvoltuion
% coordinates: x and y coordinates, the center of each sub-aperture
% resolutions: x and y resolutions of each sub-aperture image
% background:  PSF raw image background
% normalize_psf: if enabled, it will normalize each PSF by its pixel value summation
% visualize: if enabled, it will save the PSF in tiff file
% save_mat: if enabled, it will save the H and Ht matrix in mat

% note here it flips the input PSF image upside down before processing. and
% it assumes the input coordinates are also calibrated on a flipped image
% Image flip here is not required by the algorithm itself, but only related to 
% camera orientation in our own setup

%%%  Author: Zhaoqiang Wang, 2023 

    H = zeros(resolutions(2), resolutions(1), length(fileName), size(coordinates,1));
    Ht = H;
    
    for p = 1:length(fileName) 
        img = double(imread(fullfile(filePath, fileName{p})));    
        img = flipud(img);
        img = double(uint16(img-background));      
        for v = 1:size(coordinates,1)
            subimg = img(coordinates(v,2)+ceil(-resolutions(2)/2):coordinates(v,2)+ceil(resolutions(2)/2)-1, ...
                coordinates(v,1)+ceil(-resolutions(1)/2):coordinates(v,1)+ceil(resolutions(1)/2)-1);
            H(:,:,p,v) = subimg;
            Ht(:,:,p,v) = imrotate(squeeze(H(:,:,p,v)),180);
            HtPower = sum(Ht(:,:,p,v),'all');
            if HtPower > 0
                Ht(:,:,p,v) = Ht(:,:,p,v) ./ HtPower;
            end
            if normalize_psf
            %%%%% normalize the PSF individually,to alleviates artifacts arising from 
            %%%%% the PSF power variation during experimental PSF calibration         
                HPower = sum(H(:,:,p,v),'all');
                if HPower > 0
                    H(:,:,p,v) = H(:,:,p,v) ./ HPower;
                end
            end
        end
    end    
    if visualize
        if ~exist(fullfile(filePath, 'visualize'), 'dir')
            mkdir(fullfile(filePath, 'visualize'));
        end
        for v = 1:size(coordinates,1)
            cube = H(:,:,:,v);
            imwrite3d(uint16(cube+cube*normalize_psf*9999), fullfile(filePath, 'visualize', ['PSFv' num2str(v) '.tif']));
        end
    end    
    if save_mat
        save(fullfile(filePath, ['PSF_resolution_' num2str(resolutions(1)) '_' num2str(resolutions(2)) '_z_' num2str(length(fileName)) '_subaperture_' num2str(size(coordinates,1)) '.mat']), 'H', 'Ht');
    end

end