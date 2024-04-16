function backward_projection = SLF_backward(projection, angles, Ht,en_mask)
    
    [~, resolution2, ndepth, nprojection] = size(Ht);
    

    x = ((1:resolution2)-resolution2/2)/resolution2;     y = x;
    [X,Y] = meshgrid(x,y);
    if en_mask
        mask = (X.^2+Y.^2)<=0.25;
    else
        mask = (X.^2+Y.^2)<=1;
    end
    bpj = zeros(resolution2, resolution2, ndepth);
    
    for v = 1:nprojection
        for p = 1:ndepth
            perspective = real(ifft2(fft2(projection(:,:,v)).*fft2(ifftshift(Ht(:,:,p,v)))));
            perspective = imresize(perspective, [resolution2, resolution2], "bilinear");
            bpj(:,:,p) = bpj(:,:,p) + mask.*imrotate(perspective, -angles(v),'bilinear','crop');
        end
    end

    backward_projection = bpj;
    
end

