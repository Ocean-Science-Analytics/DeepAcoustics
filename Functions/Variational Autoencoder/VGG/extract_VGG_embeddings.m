function data = extract_VGG_embeddings(net, ClusteringData)

imageSize = net.Layers(1).InputSize;

% Resize the images to match the input image size
images = zeros([imageSize, size(ClusteringData, 1)]);
for i = 1:size(ClusteringData, 1)
    im = ind2rgb(ClusteringData.Spectrogram{i},inferno(255));
    images(:,:,:,i) = imresize(im, imageSize(1:2));
end
images = dlarray(single(images) ./ 256, 'SSCB');

net = initialize(net);
features = predict(net,images);

features = stripdims(features)';
features = gather(extractdata(features));
data = double(features);
