function PerfMetrics(handles)
% Select Det File for testing network
[detfile,detpath] = uigetfile('*.mat','Select ground-truthed detections.mat file',handles.data.settings.detectionfolder);
PathToDet = fullfile(detpath,detfile);
[CallsAnn, allAudio, ~, detmetadata] = loadCallfile(PathToDet,handles,false);

[NetName, NetPath] = uigetfile(handles.data.settings.networkfolder,'Select Network to Evaluate');
lastwarn('');
netload = load([NetPath NetName]);
[warnMsg, ~] = lastwarn;
if ~isempty(warnMsg)
    error('Problem pathing to ValidationData - Talk to Gabi')
end

if ~isempty(detmetadata)
    Settings = detmetadata.Settings;
else
    prompt = {'Total Analysis Length (Seconds; 0 = Full Duration)','Low Frequency Cutoff (Hz)','High Frequency Cutoff (Hz)','Score Threshold (0-1)','Append Date to FileName (1 = yes)'};
    dlg_title = 'Settings for This Network';
    num_lines = [1 length(dlg_title)+30]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
    def = handles.data.settings.detectionSettings;
    % Convert freq to Hz for display
    def(2) = sprintfc('%g',str2double(def{2})*1000);
    def(3) = sprintfc('%g',str2double(def{3})*1000);
    Settings = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));
end

if isempty(Settings) % Stop if user presses cancel
    return
end

% Convert frequency inputs to kHz
Settings(2:3) = Settings(2:3)/1000;

fig = uifigure;
d = uiprogressdlg(fig,'Title','Detecting Calls',...
    'Indeterminate','on');
drawnow

Calls = [];
for i = 1:length(allAudio)
    % Run detector
    AudioFile = allAudio(i).Filename;
    Calls_ThisAudio = SqueakDetect(AudioFile,netload,Settings,1,1);

    % Add detections to all Calls tables
    if ~isempty(Calls_ThisAudio)
        Calls = [Calls; Calls_ThisAudio];
    end
end
Calls = CreateBoxAdj(Calls,allAudio);
CallsAnn = CreateBoxAdj(CallsAnn,allAudio);
close(d)
close(fig)

prompt = 'Threshold for overlap (0-1) that counts as a true positive:';
dlg_title = 'True Positive Threshold';
num_lines = [1 length(dlg_title)+30]; 
definput = {'0.5'};
percTPThresh = inputdlg(prompt,dlg_title,num_lines,definput);
percTPThresh = str2double(percTPThresh);
if percTPThresh < 0 || percTPThresh > 1
    error('Threshold for overlap must be between 0 and 1')
end

if isempty(Calls)
    msgbox('No Calls detected in audio file(s)')
    return
end

results = table({table2array(Calls(:,'BoxAdj'))},{table2array(Calls(:,2))},{categorical(Calls.Type)});
results = renamevars(results,1:3,{'Box','Scores','Label'});
grdtruth = table({table2array(CallsAnn(:,'BoxAdj'))},{categorical(CallsAnn.Type)});
grdtruth = renamevars(grdtruth,1:2,{'Box','Label'});

uniqClass = netload.detector.ClassNames;
nTypes = length(uniqClass);

% Set underlying category possibilities for annotated calls so eOD() can
% run below
grdtruth.Label{:} = setcats(grdtruth.Label{:},uniqClass);

strVer = version;
strVer = regexp(strVer,'R20[0-9]{2}[a-b]','match');
strVer = strVer{1};
strVer = regexp(strVer,'20[0-9]{2}','match');
strVer = str2double(strVer{1});
if strVer >= 2023
    odMetrics = evaluateObjectDetection(results, grdtruth, percTPThresh);
    odMetricsmAP = evaluateObjectDetection(results, grdtruth, 0.1:0.1:0.9);
    avgprec = zeros(nTypes,1);
    mAP = zeros(nTypes,1);
    prec = zeros(nTypes,1);
    recall = zeros(nTypes,1);
    recallvec = cell(nTypes,1);
    precvec = cell(nTypes,1);
    for i = 1:nTypes
        avgprec(i) = odMetrics.ClassMetrics.AP{uniqClass(i)};
        recallvec{i} = odMetrics.ClassMetrics.Recall{uniqClass(i)};
        precvec{i} = odMetrics.ClassMetrics.Precision{uniqClass(i)};
        mAP(i) = odMetricsmAP.ClassMetrics.mAP(uniqClass(i));

        % Retrieve only the precision and recall values if accept all scores
        prec(i) = precvec{i}(end);
        recall(i) = recallvec{i}(end);
    end
else
    if nTypes > 1
        error('Multi-Class not set up for Matlab functions in versions < 2023 - update Matlab or beg Gabi');
    end
    grdtruth = table({table2array(CallsAnn(:,'BoxAdj'))});
    grdtruth = renamevars(grdtruth,1,'Call');
    [avgprec, recallvec, precvec] = evaluateDetectionPrecision(results, grdtruth, percTPThresh);
    odMetrics = [];
    mAP = NaN;
    warning('Object detection metrics only available with Matlab 2023 or greater')
end

numTrueDets = zeros(nTypes,1);
for i = 1:nTypes
    numTrueDets(i) = sum(CallsAnn.Type==uniqClass(i));
end
numTP = recall.*numTrueDets;
numDets = numTP./prec;
numFP = numDets-numTP;
numFN = numTrueDets - numTP;
fscore = 2.*((prec.*recall)./(prec+recall));

scores = cell(nTypes,1);
for i = 1:nTypes
    scores{i} = [results.Scores{1}(results.Label{:} == uniqClass(i))];
    scores{i} = sort(scores{i},'descend');
    scores{i} = [scores{i};0];
    figure
    scatter(recallvec{i},precvec{i},[],scores{i},'filled','MarkerEdgeColor',[0 0 0])
    grid on
    c = colorbar;
    c.Label.String = 'Score Threshold';
    title({sprintf('Call Type: %s',uniqClass{i}); ...
        sprintf('Average Precision = %.1f',avgprec(i))})
    xlabel('Recall')
    ylabel('Precision')

    msgbox({sprintf('Call Type: %s',uniqClass{i});...
        'Values for Score Threshold == 0:'; ...
        sprintf('# True Positives: %u',int16(numTP(i))); ...
        sprintf('# False Positives: %u', int16(numFP(i)));...
        sprintf('# of False Negatives: %u', int16(numFN(i)));...
        sprintf('Precision: %.4f',prec(i));...
        sprintf('Recall: %.4f', recall(i));...
        sprintf('F-Score: %.4f', fscore(i));...
        sprintf('Average Prec (%.2f Ovlp Threshold): %.4f',percTPThresh, avgprec(i));...
        sprintf('mAP (0.1:0.1:0.9 Ovlp Threshold): %.4f', mAP(i))},'P/R Result');
end

[file,path] = uiputfile([handles.data.settings.networkfolder '\PerformanceMetrics.mat'],'Save Performance Metrics');
save(fullfile(path,file),'NetPath','NetName','PathToDet','results','precvec','recallvec','prec','recall',...
    'numTrueDets','numTP','numDets','numFP','numFN','fscore','avgprec','mAP','odMetrics','odMetricsmAP')

[~,audioname] = fileparts(AudioFile);
detectiontime=datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');

% Append date to filename
if Settings(5)
    fname = [audioname '_' num2str(length(allAudio)) 'AudFiles ' detectiontime '_Detections.mat'];
else
    fname = [audioname '_' num2str(length(allAudio)) 'AudFiles_Detections.mat'];
end
[fname,fpath] = uiputfile(fullfile(handles.data.settings.networkfolder, fname),'Save the Detected Calls');

if ~isempty(Calls)
    detection_metadata = struct(...
        'Settings', Settings,...
        'detectiontime', detectiontime,...
        'networkselections', NetName);
    spect = handles.data.settings.spect;
    save(fullfile(fpath,fname),'Calls','allAudio','detection_metadata','spect','-v7.3', '-mat');
end

end

function imOut = im2Dto3D(imIn)
% Resize the images and scale the pixels to between 0 and 1. Also scale the
% corresponding bounding boxes.
    map = gray(256);
    imOut = ind2rgb(imIn,map);
end