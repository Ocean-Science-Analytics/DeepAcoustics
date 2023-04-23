function PrecRecall(hObject, eventdata, handles)
% Select Images for testing network
[TestingTables, AllSettings, PathToDet] = ImportTrainingImgs(handles);
% Extract boxes delineations and store as boxLabelDatastore
% Convert training and validation data to
% datastores for dumb YOLO fns
imdsTest = imageDatastore(TestingTables{:,1});
bldsTest = boxLabelDatastore(TestingTables(:,2:end));

[NetName, NetPath] = uigetfile(handles.data.settings.networkfolder,'Select Existing Network');
netload = load([NetPath NetName]);
detector = netload.detector;

results = detect(detector,imdsTest);

prompt = 'Threshold for overlap (0-1) that counts as a true positive:';
dlgtitle = 'True Positive Threshold';
definput = {'0.5'};
percTPThresh = inputdlg(prompt,dlgtitle,[1 50],definput);
percTPThresh = str2double(percTPThresh);
if percTPThresh < 0 || percTPThresh > 1
    error('Threshold for overlap must be between 0 and 1')
end

[ap, recall, prec] = evaluateDetectionPrecision(results, bldsTest, percTPThresh);
% Retrieve only the precision and recall values if accept all scores
prec = prec(end);
recall = recall(end);

if isempty(PathToDet)
    warning('If selected Detections.mats do not match those used to create the Image Tables, P/R statistics will be incorrect.')
    [trainingdata, trainingpath] = uigetfile([char(handles.data.settings.detectionfolder) '/*.mat'],'Select Detection File(s) used for Testing ','MultiSelect', 'on');
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
if height(CallsAnn ~= numTrainBoxes)
    msgbox('Something went wrong with creating your image table - talk to Gabi')
end

numTrueDets = height(CallsAnn);
numTP = recall*numTrueDets;
numDets = numTP/prec;
numFP = numDets-numTP;
numFN = numTrueDets - numTP;
fscore = 2*((prec*recall)/(prec+recall));

msgbox({sprintf('# True Positives: %u',int16(numTP)); ...
    sprintf('# False Positives: %u', int16(numFP));...
    sprintf('# of False Negatives: %u', int16(numFN));...
    sprintf('Precision: %.4f',prec);...
    sprintf('Recall: %.4f', recall);...
    sprintf('F-Score: %.4f', fscore)},'P/R Result');

answer = questdlg('Would you like to display the ground-truthed Detections.mat corresponding to the currently loaded file?', ...
    'Annotation Display?',...
    'Yes','No','No');
switch answer
    case 'Yes'
        [annfile, annpath] = uigetfile('','Select a ground-truthed Detections.mat to evaluate the loaded file');
        CallsAnn = loadCallfile(fullfile(annpath,annfile),handles,false);
        Calls = handles.data.calls;
        
        if isempty(Calls)
            error('You have to load a Detections.mat file first!')
        end
        
        % Create Val Column
        Calls.Ovlp = zeros(height(Calls),1);
        Calls.IndMatch = zeros(height(Calls),1);
        % For every real call
        for i = 1:height(CallsAnn)
            % Extract the true
            thisbox = CallsAnn.Box(i,:);
            % Start and end re beg of wav file
            thisboxst = thisbox(1);
            thisboxend = thisbox(1)+thisbox(3);
            % Indices where det call starts during true call (det call start is
            % after true call start but before end)
            indA = Calls.Box(:,1) >= thisboxst & Calls.Box(:,1) < thisboxend;
            % Indices where det call starts before true call (det call start is
            % before true call start and end is after true call start)
            indB = Calls.Box(:,1) < thisboxst & (Calls.Box(:,1)+Calls.Box(:,3)) >= thisboxst;
            ind = indA | indB;
            % Subset of dets that overlap with this true call
            Calls_sub = Calls.Box(ind,:);
            % Calculate percentage overlap
            percOvlp = bboxOverlapRatio(thisbox,Calls_sub);
            % Find the detected call with the most overlap
            [percOvlp,indMax] = max(percOvlp);
            % Ind = indices of calls that overlap with true call
            ind = find(ind);
            % Ind = index of call with the most overlap with true call
            ind = ind(indMax);
            % Only if the Ovlp is better than the detected call's overlap with
            % any other true call, save Ovlp & index of true call that
            % corresponds to that Ovlp
            if percOvlp > Calls.Ovlp(ind)
                Calls.Ovlp(ind) = percOvlp;
                Calls.IndMatch(ind) = i;
            end
        end
        
        % Check for a true call represented by two det calls
        bDupsFound = false;
        % Vec of true call indices that overlapped with a det call (looking for
        % duplicates in this vector)
        vecNonZero = [Calls.IndMatch(find([Calls.IndMatch]))];
        % Vector of unique true call indices that overlapped with a det call
        [~, ia, ~] = unique(vecNonZero,'first');
        % Vector of indices of vecNonZero that correspond to duplicates
        indDup = ~ismember(1:numel(vecNonZero),ia);
        % Retrieve indices of true calls that are represented twice
        indDup = unique(vecNonZero(indDup));
        % For every real call
        for i = 1:height(CallsAnn)
            if ismember(i,indDup)
                bDupsFound = true;
                warning('Capability untested - talk to Gabi if you see this message')
                % Subset of dets that overlap with this true call
                CallsPerc_sub = Calls.Ovlp([Calls.IndMatch] == i);
                % Find the detected call with the most overlap
                [~,indMax] = max(CallsPerc_sub);
                % Ind = indices of calls that overlap with true call
                ind = find([Calls.IndMatch] == i);
                % Indwin = index of call with the most overlap with true call
                indwin = ind(indMax);
                % Indlose = index of other calls, reset to 0
                indlose = ind(~ismember(1:numel(ind),indMax));
                Calls.Ovlp(indlose) = 0;
                Calls.IndMatch(indwin) = 0;
            end
        end
        
        % Now that duplicates removed, roll through ground-truthed calls again in
        % case there are substitutes that could be filled in for the duplicates
        % that got reset to zero (i.e., there were GT calls with less overlap in
        % the first loop that got excluded, but the winning GT call was duplicated
        % for multiple det calls, so there's a second chance for assignment)
        if bDupsFound
            % For every real call
            for i = 1:height(CallsAnn)
                % If still unassigned
                if ~ismember(i,[Calls.IndMatch])
                    warning('Capability untested - talk to Gabi if you see this message')
                    % Extract the true
                    thisbox = CallsAnn.Box(i,:);
                    % Start and end re beg of wav file
                    thisboxst = thisbox(1);
                    thisboxend = thisbox(1)+thisbox(3);
                    % Indices where det call starts during true call (det call start is
                    % after true call start but before end)
                    indA = Calls.Box(:,1) >= thisboxst & Calls.Box(:,1) < thisboxend;
                    % Indices where det call starts before true call (det call start is
                    % before true call start and end is after true call start)
                    indB = Calls.Box(:,1) < thisboxst & (Calls.Box(:,1)+Calls.Box(:,3)) >= thisboxst;
                    ind = indA | indB;
                    % Remove Calls that still have a better match
                    ind = ind & Calls.IndMatch == 0;
                    % Subset of dets that overlap with this true call and remain
                    % unassigned
                    Calls_sub = Calls.Box(ind,:);
                    % Calculate percentage overlap
                    percOvlp = bboxOverlapRatio(thisbox,Calls_sub);
                    % Find the detected call with the most overlap
                    [percOvlp,indMax] = max(percOvlp);
                    % Ind = indices of calls that overlap with true call
                    ind = find(ind);
                    % Ind = index of call with the most overlap with true call
                    ind = ind(indMax);
                    % Save Ovlp & index of true call that
                    % corresponds to that Ovlp
                    Calls.Ovlp(ind) = percOvlp;
                    Calls.IndMatch(ind) = i;
                end
            end
        end
        
        % If there are STILL duplicates, error and cry at Gabi because that sure
        % makes things complicated...
        uniqIM = unique(Calls.IndMatch);
        % (+1 for the 0)
        if length(uniqIM) ~= length(find(Calls.IndMatch))+1
            error('Overlaps are too complicated to calculate Precision/Recall - talk to Gabi about further development')
        end
        
        % prompt = 'Threshold for overlap (0-1) that counts as a true positive:';
        % dlgtitle = 'True Positive Threshold';
        % definput = {'0.5'};
        % percTPThresh = inputdlg(prompt,dlgtitle,[1 50],definput);
        % percTPThresh = str2double(percTPThresh);
        % if percTPThresh < 0 || percTPThresh > 1
        %     error('Threshold for overlap must be between 0 and 1')
        % end
        % 
        % numDets = height(Calls);
        % numTP = length(find(Calls.Ovlp >= percTPThresh));
        % numFP = numDets-numTP;
        % numFN = height(CallsAnn) - numTP;
        % prec = numTP/numDets;
        % recall = numTP/height(CallsAnn);
        % fscore = 2*((prec*recall)/(prec+recall));
        % 
        % msgbox({sprintf('# True Positives: %u',numTP); ...
        %     sprintf('# False Positives: %u', numFP);...
        %     sprintf('# of False Negatives: %u', numFN);...
        %     sprintf('Precision: %.4f',prec);...
        %     sprintf('Recall: %.4f', recall);...
        %     sprintf('F-Score: %.4f', fscore)},'P/R Result');
        
        handles.data.calls = Calls;
        handles.data.bAnnotate = true;
        handles.data.anncalls = CallsAnn;
        update_fig(hObject, eventdata, handles);
end