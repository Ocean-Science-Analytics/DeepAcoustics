function [detector, lgraph, options, info, detname] = TrainSqueakDetector(TrainingTables, layers, sameopts, detname)

% Extract boxes delineations and store as boxLabelDatastore
% Convert training and validation data to
% datastores for dumb YOLO fn
imdsTrain = imageDatastore(TrainingTables{:,'imageFilename'});
% Depends on certain column order in TrainingTables!!
indClass = find(strcmp('imageFilename', TrainingTables.Properties.VariableNames))+1;
bldsTrain = boxLabelDatastore(TrainingTables(:,indClass:end));
dsTrain = combine(imdsTrain,bldsTrain);

list = {'Tiny YOLO (pre-trained)','CSP-DarkNet-53 (pre-trained)','ResNet-50 (pre-trained)','ResNet-50 (blank)'};
if nargin == 1 || isempty(detname)
    if nargin == 1
        strPrompt = 'Choose a base network';
    else
        strPrompt = 'Which network architecture was used to create this?';
    end
    [basemodels,tf] = listdlg('PromptString',strPrompt,'ListString',list,'SelectionMode','single','Name','Base Network');
    if ~tf
        return
    end
    detname = list{basemodels};
elseif nargin == 4
    basemodels = find(strcmp(detname,list));
end

samp = read(dsTrain);
if istable(samp)
    sampleData = samp{1,1};
    sampleImg = sampleData{1};
else
    sampleData = samp(1,1);
    sampleImg = sampleData{1};
end

% Probably 300 x 300
dim1 = size(sampleImg,1);
dim2 = size(sampleImg,2);

% Set model defaults
switch basemodels
    % Tiny & DarkNet - probably 288 x 288
    case {1,2}
        dim1 = 32*round(size(sampleImg,1)/32);
        dim2 = 32*round(size(sampleImg,2)/32);
    % ResNet50 (pre-trained) 224 x 224
    case 3
        dim1 = 224;
        dim2 = 224;
end
if dim1 ~= dim2
    error('Oops, image not square, talk to Gabi')
end

% User input so can reduce size if memory error
warning('If GPU crashes (out of memory error), you may need to reduce the image size.')
prompt = {'Enter image size (square):'};
dlg_title = 'Image Size';
num_lines = [1 length(dlg_title)+30];
definput = {num2str(dim1)};
dim1 = str2double(inputdlg(prompt,dlg_title,num_lines,definput));
dim2 = dim1;

switch basemodels
    % Tiny & DarkNet - probably 288 x 288
    case {1,2}
        if mod(dim1,32) ~= 0
            warning('COCO models require image size be a multiple of 32; automatically rounding to nearest multiple')
            dim1 = 32*round(dim1/32);
            dim2 = dim1;
        end
end

% Training image dims need to matchcase 'Tiny YOLO v4 COCO' or
% 'CSP-DarkNet-53'
inputSize = [dim1 dim2 3];
if nargin == 4
    if size(layers.InputSize,2) ~= 3
        inputSize = [dim1 dim2];
    end
end
dsTrainReSize = transform(dsTrain,@(data)preprocessData(data,inputSize));

if nargin == 1
    %% Set training options
    bCustomize = questdlg('Would you like to customize your network options or use defaults?','Customize?','Customize','Defaults','Defaults');
    switch bCustomize
        %Default
        case 'Defaults'
            % Set anchor boxes (default = 8/9)
            % Must be even number for Tiny YOLO v4  & ResNet50 and divisible by 3 for
            % Darknet (# of detection heads)
            switch basemodels
            %case 'Tiny YOLO v4 COCO' or 'ResNet50'
            case {1,3,4}
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
                      'MaxEpochs',30,...
                      'Shuffle','every-epoch',...
                      'VerboseFrequency',30,...
                      'BatchNormalizationStatistics','moving', ... %YOLOv4
                      'ResetInputNormalization',false, ... %YOLOv4
                      'Plots','training-progress');
        case 'Customize'
            bAnchBox = questdlg('Do you already know how many anchor boxes you want to use?','# Anchor Boxes?','Yes','No','No');
            switch bAnchBox
            case 'Yes'
                nAnchors = str2double(inputdlg('How many anchor boxes would you like to use (minimize # while maximizing Mean IoU)?:',...
                     dlg_title,num_lines));
            case 'No'
                h = waitbar(0,'Calculating Anchor Boxes');
                %% Dynamically choose # of Anchor Boxes
                maxNumAnchors = 15;
                meanIoU = zeros([maxNumAnchors,1]);
                arranchorBoxes = cell(maxNumAnchors, 1);
                for k = 1:maxNumAnchors
                    % Estimate anchors and mean IoU.
                    [arranchorBoxes{k},meanIoU(k)] = estimateAnchorBoxes(dsTrainReSize,k);
                    waitbar(k/maxNumAnchors, h, sprintf('Trying #%g of %g Anchor Boxes', k,maxNumAnchors));      
                end
                close(h)
        
                figure
                plot(1:maxNumAnchors,meanIoU,'-o')
                ylabel("Mean IoU")
                xlabel("Number of Anchors")
                title("Number of Anchors vs. Mean IoU")
                dlg_title = 'Anchor Boxes';
                num_lines = [1 length(dlg_title)+30];
                nAnchors = str2double(inputdlg('How many anchor boxes would you like to use (minimize # while maximizing Mean IoU)?:',...
                             dlg_title,num_lines));
            end
            % Must be even number for Tiny YOLO v4 and divisible by 3 for
            % Darknet
            switch basemodels
            %case 'Tiny YOLO v4 COCO' or 'ResNet50'
            case {1,3,4}
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
            dlg_title = 'Initial Learn Rate';
            num_lines = [1 length(dlg_title)+30];
            nInitLearnRate = str2double(inputdlg('Initial Learn Rate (sdgm default = 0.01; others = 0.001)?:',...
                dlg_title,num_lines));
                           
            %% Mini-Batch Size
                % The size of the subset of the training set that is used to
                % evaluate the gradient of the loss function and update the
                % weights.
            dlg_title = 'Mini-Batch Size';
            num_lines = [1 length(dlg_title)+30];
            nMiniBatchSz = str2double(inputdlg('Mini-Batch Size (default = 16)?:',...
                dlg_title,num_lines));
                           
            %% Max # of Epochs
                % Maximum # of epochs used for training
                % Epoch = full pass of the training algorithm over the entire
                % training set
            dlg_title = 'Max # of Epochs';
            num_lines = [1 length(dlg_title)+30];
            nNumEpochs = str2double(inputdlg('Max # of Epochs (default = 30)?:',...
                dlg_title,num_lines));
                     
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
                    [dsTrainReSize, dsValReSize] = splitValData(TrainingTables,inputSize);
                case 'No'
                    dsValReSize = [];
                    %Not sure why this is here so commenting until I'm forced
                    %to remember why
                    %dsTrain = TrainingTables;
            end
            
            % Set training options
            options = trainingOptions(chSolver,...
                      'InitialLearnRate',nInitLearnRate,...
                      'MiniBatchSize',nMiniBatchSz,...
                      'MaxEpochs',nNumEpochs,...
                      'ValidationData',dsValReSize,...
                      'Shuffle','every-epoch',...
                      'Verbose',true,...
                      'VerboseFrequency',30,...
                      'BatchNormalizationStatistics','moving', ... %YOLOv4
                      'ResetInputNormalization',false, ... %YOLOv4
                      'Plots','training-progress');
    end    
    classes = TrainingTables.Properties.VariableNames(indClass:end);
    
    % Replace 0s with 1 (sometimes happens with reduced image sizes)
    anchorBoxes(anchorBoxes == 0) = 1;
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
        %case ResNet-50
        case {3,4}
            numAnchorsHalf = ceil(numAnchors/2);
            anchorBoxes = {sortedAnchors(1:numAnchorsHalf,:) 
                sortedAnchors(numAnchorsHalf+1:end,:)};
            
            % Pre-trained
            if basemodels == 3
                basenet = resnet50;
                lgraph = layerGraph(basenet);
            % Blank
            else
                S = load('Base_ResNet50.mat','blankNet');
                basenet = S.blankNet;
                lgraph = basenet;
            end
    
            % To create a YOLO v4 deep learning network you must make these changes to the base network:
            % Set the Normalization property of the ImageInputLayer in the base network to 'none'.
            % Remove the fully connected classification layer.
            
            % Define an image input layer with Normalization property value as 'none' and other property values same as that of the base network.
            layerName = basenet.Layers(1).Name;
            newinputLayer = imageInputLayer(inputSize,'Normalization','none','Name',layerName);
            
            % Remove the fully connected layer in the base network.
            
            lgraph = removeLayers(lgraph,'ClassificationLayer_fc1000');
            lgraph = replaceLayer(lgraph,layerName,newinputLayer);
            
            dlnet = dlnetwork(lgraph);
            featureExtractionLayers = ["activation_22_relu","activation_40_relu"];
    
            lgraph = yolov4ObjectDetector(dlnet,classes,anchorBoxes,DetectionNetworkSource=featureExtractionLayers,InputSize=inputSize);
    end
elseif nargin == 4
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
            [dsTrainReSize, dsValReSize] = splitValData(TrainingTables,inputSize);
        case 'No'
            dsValReSize = [];
            %Not sure why this is here so commenting until I'm forced
            %to remember why
            %dsTrain = TrainingTables;
    end
    warn_msg = ['If you get the following error:\n',...
        'Error using images.dltrain.internal.dltrain>iValidateSupportedTrainingOptions\n',...
        'Unsupported value for trainingOptions BatchNormalizationStatistics Name/Value. Only moving is supported.\n',...
        'This may be because you used ValidationData to create your network and then moved your training images.\n',...
        'Find out where Matlab is looking for your training images (by loading your network into an empty Matlab environment -\n%s'];
    warning(warn_msg,'should produce a helpful error with the filepath for which it is searching) and put your images back in that directory.')
    lgraph = layers;
    options = sameopts;
    options.ValidationData = dsValReSize;
else
     error('This should not happen')   
end

% Train network
[detector,info] = trainYOLOv4ObjectDetector(dsTrainReSize,lgraph,options);
end

function data = preprocessData(data,targetSize)
% Resize the images and scale the pixels to between 0 and 1. Also scale the
% corresponding bounding boxes.
for ii = 1:size(data,1)
    I = data{ii,1};
    imgSize = size(I);
    
    bboxes = data{ii,2};
    
    if size(targetSize,2) == 3 && targetSize(:,3) == 3
        map = gray(256);
        I = ind2rgb(I,map);
    end
    I = im2single(imresize(I,targetSize(1:2)));
    scale = targetSize(1:2)./imgSize(1:2);
    bboxes = bboxresize(bboxes,scale);
    
    data(ii,1:2) = {I,bboxes};
end
end

function [dsTrainReSize, dsValReSize] = splitValData(TrainingTables,inputSize)
% Depends on certain column order in TrainingTables!!
indClass = find(strcmp('imageFilename', TrainingTables.Properties.VariableNames))+1;

% Have user supply %
valprop = inputdlg('What proportion of your (non-augmented) training data would you like to allocate for validation (default = 0.1)?:','Validation Data Proportion');
valprop = str2double(valprop{1});
if valprop <= 0 || valprop >= 1
    msgbox('Improper validation % - proceeding without validation data')
    % Convert training and validation data to
    % datastores for dumb YOLO fn
    imdsTrain = imageDatastore(TrainingTables{:,'imageFilename'});
    bldsTrain = boxLabelDatastore(TrainingTables(:,indClass:end));
    dsTrain = combine(imdsTrain,bldsTrain);
    dsTrainReSize = transform(dsTrain,@(data)preprocessData(data,inputSize));
    dsValReSize = [];
else
    % Subset non-augmented images
    %nonAugTTables = TrainingTables(~TrainingTables.bAug,:);
    % Get the indices & count of each label in TrainingTables
    indLabs = table2cell(TrainingTables(:,indClass:end));
    indLabs = ~cellfun(@isempty,indLabs);
    % Do not include augmented images in selection
    indLabs(logical(TrainingTables.bAug),:) = 0;
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
        numThisSelect = num2select - sum(indSel & indLabs(:,ordLab(i)));
        % Get the indices of data rows containing this label
        thisColInd = find(indLabs(:,ordLab(i)));
        % Randomly select num2select indices for valdata
        indSel(randsample(thisColInd,numThisSelect)) = true;
    end
    % Calculate proportion of each label represented in
    % validation data
    propSel = sum(indSel & indLabs)./numEachLabs;
    dispInfo = [TrainingTables.Properties.VariableNames(indClass:end);num2cell(propSel*100)];
    dispInfo = sprintf('%s: %0.1f%% ',dispInfo{:});
    answer = questdlg({'Here are the proportions corresponding to each label selected for validation:';...
        dispInfo; 'Do you wish to proceed?'}, ...
        'Check Proportions', ...
        'Yes','No','Yes');
    switch answer
        case 'No'
            dsTrainReSize = [];
            dsValReSize = [];
            return
        case 'Yes'
            valTT = TrainingTables(indSel,:);
            TrainingTables = TrainingTables(~indSel,:);
            
            % Convert training and validation data to
            % datastores for dumb YOLO fn
            imdsTrain = imageDatastore(TrainingTables{:,'imageFilename'});
            bldsTrain = boxLabelDatastore(TrainingTables(:,indClass:end));
            dsTrain = combine(imdsTrain,bldsTrain);
            dsTrainReSize = transform(dsTrain,@(data)preprocessData(data,inputSize));
            
            imdsVal = imageDatastore(valTT{:,'imageFilename'});
            bldsVal = boxLabelDatastore(valTT(:,indClass:end));
            dsVal = combine(imdsVal,bldsVal);   
            dsValReSize = transform(dsVal,@(data)preprocessData(data,inputSize));                     
    end
end
end