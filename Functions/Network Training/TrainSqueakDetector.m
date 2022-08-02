function [detector, lgraph, options, info] = TrainSqueakDetector(TrainingTables, layers)

% Extract boxes delineations and store as boxLabelDatastore
% Convert training and validation data to
% datastores for dumb YOLO fn
imdsTrain = imageDatastore(TrainingTables{:,1});
bldsTrain = boxLabelDatastore(TrainingTables(:,2:end));
dsTrain = combine(imdsTrain,bldsTrain);

%% Set training options
bCustomize = questdlg('Would you like to customize your network options or use defaults?','Customize?','Customize','Defaults','Defaults');
switch bCustomize
    %Default
    case 'Defaults'
        % Set anchor boxes (default = 8)
        anchorBoxes = estimateAnchorBoxes(bldsTrain,8);
        % Set training options
        options = trainingOptions('sgdm',...
                  'InitialLearnRate',0.001,...
                  'Verbose',true,...
                  'MiniBatchSize',16,...
                  'MaxEpochs',100,...
                  'Shuffle','every-epoch',...
                  'VerboseFrequency',30,...
                  'Plots','training-progress');
    case 'Customize'
        %% Dynamically choose # of Anchor Boxes
        maxNumAnchors = 15;
        meanIoU = zeros([maxNumAnchors,1]);
        arranchorBoxes = cell(maxNumAnchors, 1);
        for k = 1:maxNumAnchors
            % Estimate anchors and mean IoU.
            [arranchorBoxes{k},meanIoU(k)] = estimateAnchorBoxes(bldsTrain,k);    
        end

        figure
        plot(1:maxNumAnchors,meanIoU,'-o')
        ylabel("Mean IoU")
        xlabel("Number of Anchors")
        title("Number of Anchors vs. Mean IoU")

        nAnchors = str2double(inputdlg('How many anchor boxes would you like to use (minimize # while maximizing Mean IoU)?:',...
                     'Anchor Boxes', [1 50]));
        if isempty(nAnchors)
            return
        else
            anchorBoxes = estimateAnchorBoxes(bldsTrain,nAnchors);
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
        bValData = questdlg({'Would you like to use ~10% of your training data to validate (recommended to assess overfitting)?';...
            "WARNING: Due to data type restrictions and unclear Matlab documentation, using validation data may prevent data shuffling between epochs, possibly (ironically) leading to overfitting."},...
            'Validation Data?','Yes','No','No');
        switch bValData
            % Select validation data - gets complicated with multiple
            % labels, so may need to give up (may need to
            % replace/supplement with a user-selected set of data)
            case 'Yes'
                % Get the indices & count of each label in TrainingTables
                indLabs = table2cell(TrainingTables(:,2:end));
                indLabs = ~cellfun(@isempty,indLabs);
                numEachLabs = sum(indLabs,1);
                % Find the # of data to select based on 10% of the
                % whichever label has the smallest representation in the
                % data, but must be at least 1
                num2select = max(1,floor(min(0.1*numEachLabs)));
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
                        
                        imdsVal = imageDatastore(valTT{:,1});
                        bldsVal = boxLabelDatastore(valTT(:,2:end));
                        dsVal = combine(imdsVal,bldsVal);                        
                end                
            case 'No'
                dsVal = [];
                dsTrain = TrainingTables;
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
                  'Plots','training-progress');
end

% Load unweighted mobilnetV2 to modify for a YOLO net
load('BlankNet.mat');

% YOLO Network Options
featureExtractionLayer = "block_12_add";
filterSize = [3 3];
numFilters = 96;
numClasses = (width(TrainingTables)-1);
numAnchors = size(anchorBoxes,1);
numPredictionsPerAnchor = 5;
numFiltersInLastConvLayer = numAnchors*(numClasses+numPredictionsPerAnchor);

% YOLO Network Layers
detectionLayers = [
    convolution2dLayer(filterSize,numFilters,"Name","yolov2Conv1","Padding", "same", "WeightsInitializer",@(sz)randn(sz)*0.01)
    batchNormalizationLayer("Name","yolov2Batch1")
    reluLayer("Name","yolov2Relu1")
    convolution2dLayer(filterSize,numFilters,"Name","yolov2Conv2","Padding", "same", "WeightsInitializer",@(sz)randn(sz)*0.01)
    batchNormalizationLayer("Name","yolov2Batch2")
    reluLayer("Name","yolov2Relu2")
    convolution2dLayer(1,numFiltersInLastConvLayer,"Name","yolov2ClassConv",...
    "WeightsInitializer", @(sz)randn(sz)*0.01)
    yolov2TransformLayer(numAnchors,"Name","yolov2Transform")
    yolov2OutputLayer(anchorBoxes,"Name","yolov2OutputLayer")
    ];

lgraph = addLayers(blankNet,detectionLayers);
lgraph = connectLayers(lgraph,featureExtractionLayer,"yolov2Conv1");

% Train the YOLO v2 network.
if nargin == 1
    [detector,info] = trainYOLOv2ObjectDetector(dsTrain,lgraph,options);
elseif nargin == 2
    [detector,info] = trainYOLOv2ObjectDetector(dsTrain,layers,options);
else
     error('This should not happen')   
end
end

