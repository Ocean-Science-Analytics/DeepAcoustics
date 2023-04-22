function [detector, lgraph, options, info] = TrainSqueakDetector(TrainingTables, layers, sameopts)

% Extract boxes delineations and store as boxLabelDatastore
% Convert training and validation data to
% datastores for dumb YOLO fn
imdsTrain = imageDatastore(TrainingTables{:,1});
bldsTrain = boxLabelDatastore(TrainingTables(:,2:end));
dsTrain = combine(imdsTrain,bldsTrain);

if nargin == 1
    list = {'Tiny YOLO v4 COCO','CSP-DarkNet-53','ResNet-50','Other'};
    [basemodels,tf] = listdlg('PromptString','Choose a base network','ListString',list,'SelectionMode','single','Name','Base Network');
    if ~tf
        return
    end
    
    samp = read(dsTrain);
    if istable(samp)
        sampleData = samp{1,1};
        sampleImg = sampleData{1};
    else
        sampleData = samp(1,1);
        sampleImg = sampleData{1};
    end
    
    dim1 = size(sampleImg,1);
    dim2 = size(sampleImg,2);
    
    if basemodels == 1
        dim1 = 32*round(size(sampleImg,1)/32);
        dim2 = 32*round(size(sampleImg,2)/32);
    elseif basemodels == 2
        if dim1 ~= dim2
            error('Oops, image not square, talk to Gabi')
        end
        warning('If GPU crashes, Darknet COCO may require a smaller image size.')
        prompt = {'Enter image size (square):'};
        dlgtitle = 'Image Size';
        dims = [1 35];
        definput = {num2str(dim1)};
        dim1 = str2double(inputdlg(prompt,dlgtitle,dims,definput));
        if mod(dim1,32) ~= 0
            warning('COCO models require image size be a multiple of 32; automatically rounding to nearest multiple')
            dim1 = 32*round(dim1/32);
        end
        dim2 = dim1;
    end
    
    % Training image dims need to matchcase 'Tiny YOLO v4 COCO' or 'CSP-DarkNet-53
    inputSize = [dim1 dim2];
    dsTrainReSize = transform(dsTrain,@(data)preprocessData(data,inputSize));
    
    %% Set training options
    bCustomize = questdlg('Would you like to customize your network options or use defaults?','Customize?','Customize','Defaults','Defaults');
    switch bCustomize
        %Default
        case 'Defaults'
            % Set anchor boxes (default = 8/9)
            % Must be even number for Tiny YOLO v4 and divisible by 3 for
            % Darknet
            switch basemodels
            %case 'Tiny YOLO v4 COCO'
            case 1
                nAnchors = 8;
            %case 'CSP Darknet53 COCO'
            case 2
                nAnchors = 9;
            end
            anchorBoxes = estimateAnchorBoxes(dsTrainReSize,nAnchors);
            % Set training options
            options = trainingOptions('sgdm',...
                      'InitialLearnRate',0.01,...
                      'Verbose',true,...
                      'MiniBatchSize',16,...
                      'MaxEpochs',100,...
                      'Shuffle','every-epoch',...
                      'VerboseFrequency',30,...
                      'BatchNormalizationStatistics','moving', ... %YOLOv4
                      'ResetInputNormalization',false, ... %YOLOv4
                      'Plots','training-progress');
        case 'Customize'
            %% Dynamically choose # of Anchor Boxes
            maxNumAnchors = 15;
            meanIoU = zeros([maxNumAnchors,1]);
            arranchorBoxes = cell(maxNumAnchors, 1);
            for k = 1:maxNumAnchors
                % Estimate anchors and mean IoU.
                [arranchorBoxes{k},meanIoU(k)] = estimateAnchorBoxes(dsTrainReSize,k);    
            end
    
            figure
            plot(1:maxNumAnchors,meanIoU,'-o')
            ylabel("Mean IoU")
            xlabel("Number of Anchors")
            title("Number of Anchors vs. Mean IoU")
    
            nAnchors = str2double(inputdlg('How many anchor boxes would you like to use (minimize # while maximizing Mean IoU)?:',...
                         'Anchor Boxes', [1 50]));
            % Must be even number for Tiny YOLO v4 and divisible by 3 for
            % Darknet
            switch basemodels
            %case 'Tiny YOLO v4 COCO'
            case 1
                if mod(nAnchors,2) ~= 0
                    nAnchors = nAnchors + 1;
                end
            %case 'CSP Darknet53 COCO'
            case 2
                if mod(nAnchors,3) == 1
                    nAnchors = nAnchors + 2;
                elseif mod(nAnchors,3) == 2
                    nAnchors = nAnchors + 1;
                end
            end
            if isempty(nAnchors)
                return
            else
                anchorBoxes = estimateAnchorBoxes(dsTrainReSize,nAnchors);
            end
            
            %% Solver for network
            % sgdm = Stochasitic Gradient Descent with Momentum optimizer
                % Evaluates the negative gradient of the loss at each iteration
                % and updates parameters with subset of training data
                % Different subsets ("Mini-Batch") used at each iteration
                % Full pass of trianing algorithm over entire training set with
                % Mini-Batches = one Epoch
                % Momentum Optimizer = SGD can oscillate along path of descent
                % toward optimum; adding momentum reduces this oscilalation
            % rmsprop = RMSProp optimizer
                % SGDM uses single learning rate for all parameters; RMSProp
                % seeks to improve training by different learning rates by
                % parameter
                % Decreases learning rates of parameters with large gradients;
                % increases learning rates of paramters with small gradients
            % adam = Adam optimizer
                % Similar to RMSProp but with momentum
            opts = {'sgdm','rmsprop','adam'};
            [indx,tf] = listdlg('PromptString',{'Select the solver for the training network:',''},...
                'SelectionMode','single','ListString',opts);
            if ~tf
                return
            else
                chSolver = opts{indx};
                % If I ever want to add more user-selected parameters, here is
                % where I could ask the user to set Momentum,
                % GradientDecayFactor, and SquaredGradientDecayFactor
    %             switch chSolver
    %                 case 'sgdm'
    %                 case 'rmsprop'
    %                 case 'adam'
            end
            
            %% Initial learn rate
                % Default for sdgm solver is 0.01, 0.001 for others
                % If too low, increases training time
                % If too high, can lead to suboptimal result or diverge
            nInitLearnRate = str2double(inputdlg('Initial Learn Rate (sdgm default = 0.01; others = 0.001)?:',...
                         'Initial Learn Rate', [1 50]));
                           
            %% Mini-Batch Size
                % The size of the subset of the training set that is used to
                % evaluate the gradient of the loss function and update the
                % weights.
            nMiniBatchSz = str2double(inputdlg('Mini-Batch Size (default = 16)?:',...
                         'Mini-Batch Size', [1 50]));
                           
            %% Max # of Epochs
                % Maximum # of epochs used for training
                % Epoch = full pass of the training algorithm over the entire
                % training set
            nNumEpochs = str2double(inputdlg('Max # of Epochs (default = 100)?:',...
                         'Max # of Epochs', [1 50]));
                     
            %% Validation Data
                % Used to determine if network is overfitting
            bValData = questdlg({'Would you like to use a proportion of your training data to validate (recommended to assess overfitting)?';...
                "WARNING: Due to data type restrictions and unclear Matlab documentation, using validation data may prevent data shuffling between epochs, possibly (ironically) leading to overfitting."},...
                'Validation Data?','Yes','No','No');
            switch bValData
                % Select validation data - gets complicated with multiple
                % labels, so may need to give up (may need to
                % replace/supplement with a user-selected set of data)
                case 'Yes'
                    % Have user supply %
                    valprop = inputdlg('What proportion of your training data would you like to allocate for validation (default = 0.1)?:','Validation Data Proportion');
                    valprop = str2double(valprop{1});
                    if valprop <= 0 || valprop >= 1
                        msgbox('Improper validation % - proceeding without validation data')
                        dsVal = [];
                    else
                        % Get the indices & count of each label in TrainingTables
                        indLabs = table2cell(TrainingTables(:,2:end));
                        indLabs = ~cellfun(@isempty,indLabs);
                        numEachLabs = sum(indLabs,1);
                        % Find the # of data to select based on 10% of the
                        % whichever label has the smallest representation in the
                        % data, but must be at least 1
                        num2select = max(1,floor(min(valprop*numEachLabs)));
                        % Set order of label selection from min to max
                        % representation
                        [~,ordLab] = sort(numEachLabs);
                        indSel = false(size(indLabs,1),1);
                        for i = 1:length(numEachLabs)
                            % Amt to select from this label, accounting for
                            % representation pulled from previous iterations of
                            % this for loop
                            numThisSelect = num2select - sum(indSel & indLabs(:,i));
                            % Get the indices of data rows containing this label
                            thisColInd = find(indLabs(:,ordLab(i)));
                            % Randomly select num2select indices for valdata
                            indSel(randsample(thisColInd,numThisSelect)) = true;
                        end
                        % Calculate proportion of each label represented in
                        % validation data
                        propSel = sum(indSel & indLabs)./numEachLabs;
                        dispInfo = [TrainingTables.Properties.VariableNames(2:end);num2cell(propSel*100)];
                        dispInfo = sprintf('%s: %0.1f%% ',dispInfo{:});
                        answer = questdlg({'Here are the proportions corresponding to each label selected for validation:';...
                            dispInfo; 'Do you wish to proceed?'}, ...
                            'Check Proportions', ...
                            'Yes','No','Yes');
                        switch answer
                            case 'No'
                                return
                            case 'Yes'
                                valTT = TrainingTables(indSel,:);
                                TrainingTables = TrainingTables(~indSel,:);
                                
                                % Convert training and validation data to
                                % datastores for dumb YOLO fn
                                imdsTrain = imageDatastore(TrainingTables{:,1});
                                bldsTrain = boxLabelDatastore(TrainingTables(:,2:end));
                                dsTrain = combine(imdsTrain,bldsTrain);
                                %dsTrainReSize = transform(dsTrain,@(data)preprocessData(data,inputSize));
                                
                                imdsVal = imageDatastore(valTT{:,1});
                                bldsVal = boxLabelDatastore(valTT(:,2:end));
                                dsVal = combine(imdsVal,bldsVal);                        
                        end
                    end
                case 'No'
                    dsVal = [];
                    %Not sure why this is here so commenting until I'm forced
                    %to remember why
                    %dsTrain = TrainingTables;
            end
            
            % Set training options
            options = trainingOptions(chSolver,...
                      'InitialLearnRate',nInitLearnRate,...
                      'MiniBatchSize',nMiniBatchSz,...
                      'MaxEpochs',nNumEpochs,...
                      'ValidationData',dsVal,...
                      'Shuffle','every-epoch',...
                      'Verbose',true,...
                      'VerboseFrequency',30,...
                      'BatchNormalizationStatistics','moving', ... %YOLOv4
                      'ResetInputNormalization',false, ... %YOLOv4
                      'Plots','training-progress');
    end
    
    % % Load unweighted mobilnetV2 to modify for a YOLO net
    % load('BlankNet.mat');
    % 
    % % YOLO Network Options
    % featureExtractionLayer = "block_12_add";
    % filterSize = [3 3];
    % numFilters = 96;
    % numClasses = (width(TrainingTables)-1);
    % numAnchors = size(anchorBoxes,1);
    % numPredictionsPerAnchor = 5;
    % numFiltersInLastConvLayer = numAnchors*(numClasses+numPredictionsPerAnchor);
    % 
    % % YOLO v2 Network Layers
    % detectionLayers = [
    %     convolution2dLayer(filterSize,numFilters,"Name","yolov2Conv1","Padding", "same", "WeightsInitializer",@(sz)randn(sz)*0.01)
    %     batchNormalizationLayer("Name","yolov2Batch1")
    %     reluLayer("Name","yolov2Relu1")
    %     convolution2dLayer(filterSize,numFilters,"Name","yolov2Conv2","Padding", "same", "WeightsInitializer",@(sz)randn(sz)*0.01)
    %     batchNormalizationLayer("Name","yolov2Batch2")
    %     reluLayer("Name","yolov2Relu2")
    %     convolution2dLayer(1,numFiltersInLastConvLayer,"Name","yolov2ClassConv",...
    %     "WeightsInitializer", @(sz)randn(sz)*0.01)
    %     yolov2TransformLayer(numAnchors,"Name","yolov2Transform")
    %     yolov2OutputLayer(anchorBoxes,"Name","yolov2OutputLayer")
    %     ];
    % 
    % lgraph = addLayers(blankNet,detectionLayers);
    % lgraph = connectLayers(lgraph,featureExtractionLayer,"yolov2Conv1");
    
    classes = TrainingTables.Properties.VariableNames(2:end);
    
    %Compute the area of each anchor box and sort them in descending order.
    area = anchorBoxes(:,1).*anchorBoxes(:,2);
    [~,idx] = sort(area,"descend");
    sortedAnchors = anchorBoxes(idx,:);
    %There are two detection heads in the YOLO v4 network, so divide
    %evenly...ish
    numAnchors = size(anchorBoxes,1);
    
    % Load pre-trained CNN (see Deep Learning Toolbox documentation on
    % Pretrained Deep Neural Networks)
    switch basemodels
        %case 'Tiny YOLO v4 COCO'
        case 1
            numAnchorsHalf = ceil(numAnchors/2);
            anchorBoxes = {sortedAnchors(1:numAnchorsHalf,:) 
                sortedAnchors(numAnchorsHalf+1:end,:)};
            lgraph = yolov4ObjectDetector("tiny-yolov4-coco",classes,anchorBoxes,InputSize=inputSize);
        %case 'CSP Darknet53 COCO'
        case 2
            numAnchorsThird = ceil(numAnchors/3);
            anchorBoxes = {sortedAnchors(1:numAnchorsThird,:)
                sortedAnchors(numAnchorsThird+1:numAnchorsThird*2,:)
                sortedAnchors(numAnchorsThird*2+1:end,:)};
            lgraph = yolov4ObjectDetector("csp-darknet53-coco",classes,anchorBoxes,InputSize=inputSize);
        %case 'ResNet-50'
        case 3
            numAnchorsHalf = ceil(numAnchors/2);
            anchorBoxes = {sortedAnchors(1:numAnchorsHalf,:) 
                sortedAnchors(numAnchorsHalf+1:end,:)};
    
            S = load('Base_ResNet50.mat','blankNet');
            basenet = S.blankNet;
    
            % To create a YOLO v4 deep learning network you must make these changes to the base network:
            % Set the Normalization property of the ImageInputLayer in the base network to 'none'.
            % Remove the fully connected classification layer.
            
            % Define an image input layer with Normalization property value as 'none' and other property values same as that of the base network.
            %imageSize = basenet.Layers(1).InputSize;
            layerName = basenet.Layers(1).Name;
            newinputLayer = imageInputLayer(inputSize,'Normalization','none','Name',layerName);
            
            % Remove the fully connected layer in the base network.
            lgraph = basenet;
            lgraph = removeLayers(lgraph,'ClassificationLayer_fc1000');
            lgraph = replaceLayer(lgraph,layerName,newinputLayer);
            
            dlnet = dlnetwork(lgraph);
            featureExtractionLayers = ["activation_22_relu","activation_40_relu"];
    
            lgraph = yolov4ObjectDetector(dlnet,classes,anchorBoxes,DetectionNetworkSource=featureExtractionLayers,InputSize=inputSize);
        %case 'Other' - not fleshed out needs work
        case 4
            error('This implementation has not been developed yet')
            numAnchorsThird = ceil(numAnchors/3);
            anchorBoxes = {sortedAnchors(1:numAnchorsThird,:)
                sortedAnchors(numAnchorsThird+1:numAnchorsThird*2,:)
                sortedAnchors(numAnchorsThird*2+1:end)};
            [fn,pn] = uigetfile('*.mat');
            S = load(fullfile(pn,fn),'blankNet');
            basenet = S.blankNet;
            if isa(basenet,'nnet.cnn.LayerGraph')
                error('Selected file does not contain the right variable or variable type')
            end
            lgraph = basenet;
    end
elseif nargin == 3
    warn_msg = ['If you get the following error:\n',...
        'Error using images.dltrain.internal.dltrain>iValidateSupportedTrainingOptions\n',...
        'Unsupported value for trainingOptions BatchNormalizationStatistics Name/Value. Only moving is supported.\n',...
        'This may be because you used ValidationData to create your network and then moved your training images.\n',...
        'Find out where Matlab is looking for your training images (by loading your network into an empty Matlab environment -\n%s'];
    warning(warn_msg,'should produce a helpful error with the filepath for which it is searching) and put your images back in that directory.')
    lgraph = layers;
    options = sameopts;
else
     error('This should not happen')   
end

% Train network
[detector,info] = trainYOLOv4ObjectDetector(dsTrain,lgraph,options);
end

function data = preprocessData(data,targetSize)
% Resize the images and scale the pixels to between 0 and 1. Also scale the
% corresponding bounding boxes.

for ii = 1:size(data,1)
    I = data{ii,1};
    imgSize = size(I);
    
    bboxes = data{ii,2};

    I = im2single(imresize(I,targetSize(1:2)));
    scale = targetSize(1:2)./imgSize(1:2);
    bboxes = bboxresize(bboxes,scale);
    
    data(ii,1:2) = {I,bboxes};
end
end
