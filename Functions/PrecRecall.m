function PrecRecall(handles)
% Select Det File for testing network
[TestingTables, ~, PathToDet] = ImportTrainingImgs(handles,false);
% Extract boxes delineations and store as boxLabelDatastore
% Convert training and validation data to
% datastores for dumb YOLO fns
imdsTest = imageDatastore(TestingTables{:,1});
bldsTest = boxLabelDatastore(TestingTables(:,2:end));

[NetName, NetPath] = uigetfile(handles.data.settings.networkfolder,'Select Network to Evaluate');
lastwarn('');
netload = load([NetPath NetName]);
[warnMsg, ~] = lastwarn;
if ~isempty(warnMsg)
    error('Problem pathing to ValidationData - Talk to Gabi')
end
detector = netload.detector;

if size(detector.InputSize,2) == 3
    imdsTest = transform(imdsTest, @(x) im2Dto3D(x));
end

fig = uifigure;
d = uiprogressdlg(fig,'Title','Detecting Calls',...
    'Indeterminate','on');
drawnow
results = detect(detector,imdsTest);
close(d)
close(fig)

prompt = 'Threshold for overlap (0-1) that counts as a true positive:';
dlgtitle = 'True Positive Threshold';
definput = {'0.5'};
percTPThresh = inputdlg(prompt,dlgtitle,[1 50],definput);
percTPThresh = str2double(percTPThresh);
if percTPThresh < 0 || percTPThresh > 1
    error('Threshold for overlap must be between 0 and 1')
end

[avgprec, recallvec, precvec] = evaluateDetectionPrecision(results, bldsTest, percTPThresh);
% Retrieve only the precision and recall values if accept all scores
prec = precvec(end);
recall = recallvec(end);

if isempty(PathToDet)
    warning('If selected Detections.mats do not match those used to create the Image Tables, P/R statistics will be incorrect.')
    [trainingdata, trainingpath] = uigetfile([char(handles.data.settings.detectionfolder) '/*.mat'],'Select Ground-Truthed Detection File(s) to Use for Testing ','MultiSelect', 'on');
    if isnumeric(trainingdata); return; end
    trainingdata = cellstr(trainingdata);
    for i = 1:length(trainingdata)
        PathToDet{i} = fullfile(trainingpath,trainingdata{i});
    end
end
CallsAnn = [];
for i = 1:length(PathToDet)
    CallsAnn = [CallsAnn; loadCallfile(PathToDet{i},handles,false)];
end
numTrainBoxes = 0;
for i = 1:height(bldsTest.LabelData)
    numTrainBoxes = numTrainBoxes + length(bldsTest.LabelData{i,2});
end
if height(CallsAnn) ~= numTrainBoxes
    msgbox('Something went wrong with creating your image table - talk to Gabi')
end

numTrueDets = height(CallsAnn);
numTP = recall*numTrueDets;
numDets = numTP/prec;
numFP = numDets-numTP;
numFN = numTrueDets - numTP;
fscore = 2*((prec*recall)/(prec+recall));

figure
scores = [results.Scores];
scores = vertcat(scores{:});
scores = sort(scores,'descend');
scores = [scores;0];
scatter(recallvec,precvec,[],scores,'filled','MarkerEdgeColor',[0 0 0])
grid on
c = colorbar;
c.Label.String = 'Score Threshold';
title(sprintf('Average Precision = %.1f',avgprec))
xlabel('Recall')
ylabel('Precision')

msgbox({'Values for Score Threshold == 0:'; ...
    sprintf('# True Positives: %u',int16(numTP)); ...
    sprintf('# False Positives: %u', int16(numFP));...
    sprintf('# of False Negatives: %u', int16(numFN));...
    sprintf('Precision: %.4f',prec);...
    sprintf('Recall: %.4f', recall);...
    sprintf('F-Score: %.4f', fscore)},'P/R Result');

[file,path] = uiputfile([handles.data.settings.networkfolder '\PrecRecallResults.mat']);
save(fullfile(path,file),'NetPath','NetName','PathToDet','results','precvec','recallvec','prec','recall','numTrueDets','numTP','numDets','numFP','numFN','fscore')
end

function imOut = im2Dto3D(imIn)
% Resize the images and scale the pixels to between 0 and 1. Also scale the
% corresponding bounding boxes.
    map = gray(256);
    imOut = ind2rgb(imIn,map);
end