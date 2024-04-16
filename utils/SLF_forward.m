function forward_projection = SLF_forward(vol, angles, H, en_mask)
    
    [resolution1, resolution2, ndepth, nprojection] = size(H);
    
    x = ((1:resolution2)-resolution2/2)/resolution2;     y = x;
    [X,Y] = meshgrid(x,y);
    if en_mask
        mask = (X.^2+Y.^2)<=0.25;
    else
        mask = (X.^2+Y.^2)<=1;
    end
    mask = imresize(mask, [resolution1, resolution2], "bilinear");
    
    fpj = zeros(resolution1, resolution2, nprojection);
    for v = 1:nprojection
        for p = 1:ndepth
            perspective = imrotate(vol(:,:,p), angles(v),'bilinear','crop');
            perspective = imresize(perspective, [resolution1, resolution2], "bilinear");
            temp = real(ifft2(fft2(perspective).*fft2(ifftshift(H(:,:,p,v)))));
            fpj(:,:,v) = fpj(:,:,v) + temp.*mask;
        end
    end
    forward_projection = fpj;
    
end


    