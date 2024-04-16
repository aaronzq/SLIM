function out = conv2_fft(in, kernel)
%% 2d convolution using DFT.
kernel_crop = kernel;

[m,n] = size(in);
[mk,nk] = size(kernel_crop);
mm = m+mk-1;
nn = n+nk-1;

in_padding = zeros(mm,nn); kernel_padding = zeros(mm,nn);
if isgpuarray(in)
    in_padding = gpuArray(single(in_padding)); kernel_padding = gpuArray(single(kernel_padding)); 
end
in_padding(floor((mk-1)/2)+1:floor((mk-1)/2)+m , floor((nk-1)/2)+1:floor((nk-1)/2)+n) = in;

if mod(m,2)==0
    if mod(mk,2)==0
        padm = floor((m-1)/2);
    else
        padm = ceil((m-1)/2);
    end    
else
    padm = floor((m-1)/2);
end
if mod(n,2)==0
    if mod(nk,2)==0
        padn = floor((n-1)/2);
    else
        padn = ceil((n-1)/2);
    end    
else
    padn = floor((n-1)/2);
end
kernel_padding(padm+1:padm+mk , padn+1:padn+nk) = kernel_crop;

temp = real(ifft2(fft2(in_padding).*fft2(ifftshift(kernel_padding))));
out = temp( floor((mk-1)/2)+1:floor((mk-1)/2)+m , floor((nk-1)/2)+1:floor((nk-1)/2)+n );
end