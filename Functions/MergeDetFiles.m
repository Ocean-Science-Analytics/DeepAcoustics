function MergeDetFiles(hObject, eventdata, handles)

cd(handles.data.squeakfolder);
[detectionFilename, detectionFilepath] = uigetfile([handles.data.settings.detectionfolder '/*.mat'],'Select Detection File(s) for Merging','MultiSelect', 'on');
if isnumeric(detectionFilename); return; end

hc = waitbar(0,'Merging Output Structures');

cd(handles.data.squeakfolder);
detectionFilename = cellstr(detectionFilename);

% Concatenate detection files
Calls_temp = [];
allAudio = [];

for j = 1:length(detectionFilename)
    [Calls_ThisFile, allAudio_ThisFile] = loadCallfile(fullfile(detectionFilepath, detectionFilename{j}),handles,false);
    Calls_temp = [Calls_temp; Calls_ThisFile];
    allAudio = [allAudio; allAudio_ThisFile];
end

%% Merge overlapping boxes in det files from same audio
waitbar(.5,hc,'Writing Output Structure');
Calls = [];
uniqAudio = unique({handles.data.calls.Audiodata.Filename},'stable');
for i = 1:length(uniqAudio)
    Calls_ThisAudio = Calls_temp(Calls_temp.Audiodata == uniqAudio(i));
    Calls_ThisAudio = merge_boxes(Calls_ThisAudio.Box, Calls_ThisAudio.Score, Calls_ThisAudio.Type, Calls_ThisAudio.DetSpect(1), 1, 0, 0, uniqAudio(i));
    Calls = [Calls; Calls_ThisAudio];
end

[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, '*.mat'), 'Save Merged Detections');
waitbar(1/2, hc, 'Saving...');
detectiontime = datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
detection_metadata = struct(...
    'Settings', 'N/A; Det Merge',...
    'detectiontime', detectiontime,...
    'networkselections', 'N/A; Det Merge');
spect = handles.data.settings.spect;
save(fullfile(PathName, FileName),'Calls','allAudio','detection_metadata','spect','-v7.3');
update_folders(hObject, handles);
close(hc);
