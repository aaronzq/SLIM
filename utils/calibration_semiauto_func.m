function roi_positions = calibration_semiauto_func(img, scale_ratio, resolution, num_roi, arrangement, angles, bg, varargin)
    
    if nargin < 7
        error('Not enough input arguments.');
    elseif nargin == 7
        thresholding = 30;
        imflipud = true;
        imfliplr = false;
    elseif nargin == 8
        thresholding = varargin{1};
        imflipud = true;
        imfliplr = false;
    elseif nargin == 9 
        thresholding = varargin{1};
        imflipud = varargin{2};
        imfliplr = false;
    else
        thresholding = varargin{1};
        imflipud = varargin{2};
        imfliplr = varargin{3};
    end
    
    if imflipud
        calibration_img = flipud(double(img));
    end
    if imfliplr
        calibration_img = fliplr(calibration_img);
    end
    calibration_img = calibration_img - bg; calibration_img(calibration_img<0)=0;
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
    
    h=figure; imagesc(image_bw); axis equal; set(gcf,'Position',[680,77,1198,901]); hold on;
    plot(ROIpositions(:,1),ROIpositions(:,2),'r*');
    confirm = input('Satisfied with current detection? Enter to proceed', 's');
    
    for i=1:size(ROIpositions,1)
        disp(['Finetune patch: ' num2str(i)]);
        while true
            r1 = ROIpositions(i,2) + ceil(-resolution*scale_ratio/2);
            r2 = ROIpositions(i,2) + ceil(resolution*scale_ratio/2) - 1;
            c1 = ROIpositions(i,1) + ceil(-resolution/2);
            c2 = ROIpositions(i,1) + ceil(resolution/2) - 1;
            patch = imrotate( imresize(calibration_img(r1:r2,c1:c2),[resolution,resolution], 'Method', 'bilinear'),-angles(i),'bilinear','crop');
            figure; imagesc(patch); axis equal; set(gcf,'Position',[680,77,1198,901]);hold on; 
            plot(ceil(resolution/2),ceil(resolution/2),'r*'); hold off;
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
    roi_positions = ROIpositions;
    close(h);
end