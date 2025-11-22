function [vggNet,options,ClusteringData] = create_VGG_model(handles)

netog = imagePretrainedNetwork("vgg16",Weights="none");
% net = netog;
% net.Layers = net.Layers(1:end-1);
% net.Connections = net.Connections(1:end-1);
% net.OutputNames = {'fc8'};
vggNet = removeLayers(netog,'prob');

%options.imageSize = net.Layers(1).InputSize;

% Creates fixed frequency spectrograms (unless loading pre-created
% Clustering Data)
[ClusteringData, ~, options.freqRange, options.maxDuration, options.spectrogram] = CreateClusteringData(handles, 'scale_duration', true,...
    'fixed_frequency', true,'forClustering', true, 'save_data', true);

% Creates spectrograms only within the box
%[ClusteringData, ~, options.freqRange, options.maxDuration, options.spectrogram] = CreateClusteringData(handles, 'forClustering', true, 'save_data', true);

list = {'Opt 1 - Clipped Spec','Opt 1b - Do not use yet','Opt 3 - Std Dims Inset in Zeros','Opt 4 - Std Dims Inset in Noise'};
[optimize,tf] = listdlg('PromptString','Choose an image standardization method','ListString',list,'SelectionMode','single','Name','Imaging Method');

if tf == 1
    switch optimize
        %case 'Opt 1 - Clipped Spec'
        case 1
            % Only need to do if original file got overwritten while doing
            % VAE/VGG stuff, in which case Spec1 exists
            if ismember('Spec1',ClusteringData.Properties.VariableNames)
                ClusteringData.Spectrogram = ClusteringData.Spec1;
            end
        %case 'Opt 1b - Do not use yet'
        case 2
            error('I told you not to do this yet *wags finger*')
            if ~ismember('Spec1',ClusteringData.Properties.VariableNames)
                ClusteringData.Spec1 = ClusteringData.Spectrogram;
            end
        %case 'Opt 3 - Std Dims Inset in Zeros'
        case 3
            if ~ismember('Spec1',ClusteringData.Properties.VariableNames)
                ClusteringData.Spec1 = ClusteringData.Spectrogram;
            end
            ClusteringData.Spectrogram = ClusteringData.Spec3;
        %case 'Opt 4 - Std Dims Inset in Noise'
        case 4
            if ~ismember('Spec1',ClusteringData.Properties.VariableNames)
                ClusteringData.Spec1 = ClusteringData.Spectrogram;
            end
            ClusteringData.Spectrogram = ClusteringData.Spec4;
    end
else
    error('You chose to cancel')
end

% % Resize the images to match the input image size
% images = zeros([options.imageSize, size(ClusteringData, 1)]);
% for i = 1:size(ClusteringData, 1)
%     images(:,:,:,i) = imresize(ClusteringData.Spectrogram{i}, options.imageSize(1:2));
% end
% try
% figure; montage(images(:,:,:,1:32) ./ 256);
% catch
%     Disp('Not Enough Images Silly Billy'); 
% end
% images = dlarray(single(images) ./ 256, 'SSCB');
% 
% % % Divide the images into training and validation
% % [trainInd,valInd] = dividerand(size(ClusteringData, 1), .9, .1);
% % XTrain  = images(:,:,:,trainInd);
% % XTest   = images(:,:,:,valInd);
% 
% % % Load the network model
% % [lgraph,options] = VGG_model();
% % 
% % % Train the network
% % net = trainNetwork(images,lgraph,options);
% % 
% % 
% 
% options = trainingOptions('adam', ...
%     'InitialLearnRate',20,...
%     'MaxEpochs',30, ...
%     'Shuffle','never',...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.9, ...
%     'LearnRateDropPeriod',5, ...
%     'MiniBatchSize',8, ...
%     'Plots','training-progress', ...
%     'Verbose',false);
% 
% vggNet = trainnet(images,net,options);
