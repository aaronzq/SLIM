function im_crop = crop_circ_boundary(im, delta)
%%% Crop the ring artifact at the outer boundary of reconstructed image
%%% Crop only laterally, keep all axial slices
%%%
%%% Input: im, 2D/3D image matrix, same x and y resolution
%%%        delta, the radial distance to be cut from outer boundary
%%% Output: im_crop, a smaller 2D/3D image matrix after cropping
[resolution, ~, ndepth] = size(im);
x = linspace(-resolution/2,resolution/2,resolution)/resolution;     y = x;
[X,Y] = meshgrid(x,y);
mask = (X.^2+Y.^2)<=0.25;
se = strel('disk', delta);
mask = imerode(mask,se);
mask3d = double(repmat(mask,[1,1,ndepth])>0);
temp = double(im).*mask3d;
im_crop = temp(1+delta:resolution-delta,1+delta:resolution-delta,:);
end