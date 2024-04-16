%% SLIM semi-auto calibration: find centroid for each sub-aperture images
% This code is only for reference. Any calibration method that finds center
% location of sub-aperture will serve the same purpose

% specify the PSF image at 0 um depth
filepath = '../example/beads/PSF_320';
filename = '0.tiff.tif';

scaleRatio = 0.2;  % vertical squeezing ratio
RESOLUTION = 305;  % horizontal pixel resolution of each sub-aperture
background = 200;  % PSF data background
thresholding = 30; % initial PSF binarize thresholding, will update itself automatically
num_roi = 29;      % number of sub-apertures
% num_roi = 19;
 arrangement = [5,6,7,6,5]; % number of sub-apertures on each row
% arrangement = [6,7,6]; 
angles = 2*[-25.85;-35;-43.65;32.18;23.57;-9.75;-19.2;-37.85;35.66;13.295;7.74;-3.65;-6.15;-41;41.9;38.795;4.405;0.905;9.915;16.35;26.125;-28.28;-15.3;-11.955;19.405;28.85;-47.5;-31.4;-20.85]; % rotation angles
% angles = 2*[-9.75;-19.2;-37.85;35.66;13.295;7.74;-3.65;-6.15;-41;41.9;38.795;4.405;0.905;9.915;16.35;26.125;-28.28;-15.3;-11.955;]; % rotation angles


%% Follow instructions displayed in the Command Window
calibration_img = flipud(double(imread(fullfile(filepath,filename))));
calibration_img = calibration_img - background; calibration_img(calibration_img<0)=0;
while 1
    image_bw = calibration_img>thresholding;
    image_bw = bwpropfilt(image_bw, 'Area', [5, 100]);
    stats = regionprops(image_bw,'Centroid');
    num_roi_detect = length(stats);
    if num_roi_detect > num_roi
        thresholding = thresholding + 10;
    elseif num_roi_detect < num_roi
        thresholding = thresholding - 10;
    else
        break;
    end
end

ROIpositions = zeros(num_roi,2);
ROIpositions_temp = ROIpositions;
for idx=1:size(ROIpositions_temp,1)
    ROIpositions_temp(idx,:)=stats(idx).Centroid;
end
[~, idx_sort]=sort(ROIpositions_temp(:,2),'ascend');
for row=1:length(arrangement)
    temp = ROIpositions_temp(idx_sort(1+sum(arrangement(1:row-1)):sum(arrangement(1:row))),:);
    [~, idx_sort2]=sort(temp(:,1),'ascend');
    ROIpositions(1+sum(arrangement(1:row-1)):sum(arrangement(1:row)),:)=temp(idx_sort2,:);
end

ROIpositions = round(ROIpositions);

figure; imagesc(image_bw); axis equal; set(gcf,'Position',[680,77,1198,901]); hold on;
plot(ROIpositions(:,1),ROIpositions(:,2),'r*');
confirm = input('Satisfied with current detection? Enter to proceed', 's');

for i=1:size(ROIpositions,1)
    disp(['Finetune patch: ' num2str(i)]);
    while true
        r1 = ROIpositions(i,2) + ceil(-RESOLUTION*scaleRatio/2);
        r2 = ROIpositions(i,2) + ceil(RESOLUTION*scaleRatio/2) - 1;
        c1 = ROIpositions(i,1) + ceil(-RESOLUTION/2);
        c2 = ROIpositions(i,1) + ceil(RESOLUTION/2) - 1;
        patch = imrotate( imresize(calibration_img(r1:r2,c1:c2),[RESOLUTION,RESOLUTION], 'Method', 'bilinear'),-angles(i),'bilinear','crop');
        figure; imagesc(patch); axis equal; set(gcf,'Position',[680,77,1198,901]);hold on; 
        plot(ceil(RESOLUTION/2),ceil(RESOLUTION/2),'r*'); hold off;
        adjust = input('Translate the center coordinate: w,a,s,d: ', 's');
        if ~isempty(adjust)
            if adjust=='w'
                ROIpositions(i,2)=ROIpositions(i,2)-1;
            elseif adjust=='s'
                ROIpositions(i,2)=ROIpositions(i,2)+1;
            elseif adjust=='a'
                ROIpositions(i,1)=ROIpositions(i,1)-1; 
            elseif adjust=='d'
                ROIpositions(i,1)=ROIpositions(i,1)+1;
            else
                disp('Invalid input.');
            end
            close(gcf);
        else
            disp('Next patch...');
            close(gcf);
            break;
        end
    end
            
end
save(fullfile(filepath, 'Calibration.mat'), 'ROIpositions');
clearvars  -except ROIpositions
ROIpositions








