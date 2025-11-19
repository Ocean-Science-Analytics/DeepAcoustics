function data = extract_VGG_embeddings(net, ClusteringData)

net = initialize(net);

imageSize = net.Layers(1).InputSize;

data = zeros(size(ClusteringData,1),1000);
% Resize the images to match the input image size
%images = zeros([imageSize, size(ClusteringData, 1)]);
%for i = 1:size(ClusteringData, 1)
% Switch to 100 at a time for memory issues
imctr = 1;
while imctr < size(ClusteringData,1)
    images = zeros([imageSize, min(100,(size(ClusteringData,1)-imctr+1))]);
    imctrend = min(99,(size(ClusteringData,1)-imctr));
    % Grab next 100 images
    for i = imctr:(imctr+imctrend)
        im = ind2rgb(ClusteringData.Spectrogram{i},inferno(255));
        images(:,:,:,(i-imctr+1)) = imresize(im, imageSize(1:2));
    end

    images = dlarray(single(images) ./ 256, 'SSCB');

    features = predict(net,images);
    
    features = stripdims(features)';
    features = gather(extractdata(features));
    data(imctr:(imctr+imctrend),:) = double(features);

    imctr = imctr + 100;
end
% images = dlarray(single(images) ./ 256, 'SSCB');
% 
% features = predict(net,images);
% 
% features = stripdims(features)';
% features = gather(extractdata(features));
% data = double(features);
