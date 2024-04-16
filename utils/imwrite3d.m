function imwrite3d(img, name)
imwrite(img(:,:,1), name);

for i = 2:size(img, 3)
    imwrite((img(:,:,i)), name,  'WriteMode', 'append');
end

