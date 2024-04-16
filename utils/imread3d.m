function img3d = imread3d(filename)

    file_info = imfinfo(filename);
    img3d = zeros(file_info(1).Height,file_info(1).Width, length(file_info));
    for i = 1:size(img3d,3)
        img3d(:,:,i) = imread(filename, Index=i);
    end

end