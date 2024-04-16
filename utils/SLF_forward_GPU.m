function forward_projection = SLF_forward_GPU(vol, angles, H, en_mask, conv_type)
[resolution1, resolution2, ndepth, nprojection] = size(H);
x = ((1:resolution2)-resolution2/2)/resolution2;     y = x;
[X,Y] = meshgrid(x,y);
if en_mask
    mask = (X.^2+Y.^2)<=0.25;
else
    mask = (X.^2+Y.^2)<=1;
end
% mask = gpuArray(mask);
mask = gpuArray(single(imresize(mask, [resolution1, resolution2], "bilinear")));
fpj = gpuArray.zeros(resolution1, resolution2, nprojection, 'single');
for v = 1:nprojection
    for p = 1:ndepth
        perspective = imrotate(vol(:,:,p), angles(v),'bilinear','crop');
        perspective = imresize(perspective, [resolution1, resolution2], "bilinear");
        switch conv_type
            case 'space_domain'
                temp = conv2(perspective,H(:,:,p,v),'same');
            case 'fft'
                temp = conv2_fft(perspective, H(:,:,p,v));
            case 'simple_fft'
                temp = real(ifft2(fft2(perspective).*fft2(ifftshift(H(:,:,p,v)))));
        end        
        fpj(:,:,v) = fpj(:,:,v) + temp.*mask;
    end
end
forward_projection = fpj;
end