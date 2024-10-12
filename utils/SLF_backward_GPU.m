function backward_projection = SLF_backward_GPU(projection, angles, Ht, en_mask, conv_type)
%%%  Backward projection for SLF using gpuArray
%%%  Input:
%%%     projection: row,col,view
%%%  Output:
%%%     backward_projection: row,col,depth
%%%  Author: Zhaoqiang Wang, 2023 

[~, resolution2, ndepth, nprojection] = size(Ht);
x = ((1:resolution2)-resolution2/2)/resolution2;     y = x;
[X,Y] = meshgrid(x,y);
if en_mask
    mask = (X.^2+Y.^2)<=0.25;
else
    mask = (X.^2+Y.^2)<=1;
end
mask = gpuArray(single(mask));
bpj = gpuArray.zeros(resolution2, resolution2, ndepth, 'single');
for v = 1:nprojection
    for p = 1:ndepth
        switch conv_type
            case 'space_domain'
                perspective = conv2(projection(:,:,v), Ht(:,:,p,v), 'same');
            case 'fft'
                perspective = conv2_fft(projection(:,:,v), Ht(:,:,p,v));
            case 'simple_fft'
                perspective = real(ifft2(fft2(projection(:,:,v)).*fft2(ifftshift(Ht(:,:,p,v)))));
        end      
        perspective = imresize(perspective, [resolution2, resolution2], "bilinear");
        bpj(:,:,p) = bpj(:,:,p) + mask.*imrotate(perspective, -angles(v),'bilinear','crop');
    end
end
backward_projection = bpj;
end
