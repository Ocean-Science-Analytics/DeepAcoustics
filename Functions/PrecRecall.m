function PrecRecall(handles)
% Select Det File for testing network
[detfile,detpath] = uigetfile('*.mat','Select ground-truthed detections.mat file',handles.data.settings.detectionfolder);
PathToDet = fullfile(detpath,detfile);
[CallsAnn, allAudio, detaudiodata, ~, detmetadata] = loadCallfile(PathToDet,handles,false);
AudioFile = detaudiodata.Filename;

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
Calls = SqueakDetect(AudioFile,netload,Settings,1,1);
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

results = table({table2array(Calls(:,1))},{table2array(Calls(:,2))},{categorical(Calls.Type)});
results = renamevars(results,1:3,{'Box','Scores','Label'});
grdtruth = table({table2array(CallsAnn(:,'Box'))},{categorical(CallsAnn.Type)});
grdtruth = renamevars(grdtruth,1:2,{'Box','Label'});

strVer = version;
strVer = regexp(strVer,'R20[0-9]{2}[a-b]','match');
strVer = strVer{1};
strVer = regexp(strVer,'20[0-9]{2}','match');
strVer = str2double(strVer{1});
if strVer >= 2023
    odMetrics = evaluateObjectDetection(results, grdtruth, percTPThresh);
    avgprec = odMetrics.ClassMetrics.AP{'Call'};
    recallvec = odMetrics.ClassMetrics.Recall{'Call'};
    precvec = odMetrics.ClassMetrics.Precision{'Call'};
    odMetrics = evaluateObjectDetection(results, grdtruth, 0.1:0.1:0.9);
    mAP = odMetrics.ClassMetrics.mAP('Call');
else
    grdtruth = table({table2array(CallsAnn(:,'Box'))});
    grdtruth = renamevars(grdtruth,1,'Call');
    [avgprec, recallvec, precvec] = evaluateDetectionPrecision(results, grdtruth, percTPThresh);
    odMetrics = [];
    mAP = NaN;
    warning('Object detection metrics only available with Matlab 2023 or greater')
end
% Retrieve only the precision and recall values if accept all scores
prec = precvec(end);
recall = recallvec(end);

numTrueDets = height(CallsAnn);
numTP = recall*numTrueDets;
numDets = numTP/prec;
numFP = numDets-numTP;
numFN = numTrueDets - numTP;
fscore = 2*((prec*recall)/(prec+recall));

figure
scores = [results.Scores{1}(results.Label{:} == "Call")];
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
    sprintf('F-Score: %.4f', fscore);...
    sprintf('Average Prec (%.2f Ovlp Threshold): %.4f',percTPThresh, avgprec);...
    sprintf('mAP (0.1:0.1:0.9 Ovlp Threshold): %.4f', mAP)},'P/R Result');

[file,path] = uiputfile([handles.data.settings.networkfolder '\PrecRecallResults.mat'],'Save P/R Results');
save(fullfile(path,file),'NetPath','NetName','PathToDet','results','precvec','recallvec','prec','recall',...
    'numTrueDets','numTP','numDets','numFP','numFN','fscore','avgprec','mAP','odMetrics')

[~,audioname] = fileparts(AudioFile);
detectiontime=datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');

% Append date to filename
if Settings(5)
    fname = [audioname ' ' detectiontime '_Detections.mat'];
else
    fname = [audioname '_Detections.mat'];
end
[fname,fpath] = uiputfile(fullfile(handles.data.settings.networkfolder, fname),'Save the Detected Calls');

if ~isempty(Calls)
    detection_metadata = struct(...
        'Settings', Settings,...
        'detectiontime', detectiontime,...
        'networkselections', NetName);
    audiodata = audioinfo(AudioFile);
    save(fullfile(fpath,fname),'Calls','allAudio','audiodata','detection_metadata','spect','-v7.3', '-mat');
end

end

function imOut = im2Dto3D(imIn)
% Resize the images and scale the pixels to between 0 and 1. Also scale the
% corresponding bounding boxes.
    map = gray(256);
    imOut = ind2rgb(imIn,map);
end