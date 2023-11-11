function MergeDetFiles(hObject, eventdata, handles)

cd(handles.data.squeakfolder);
[detectionFilename, detectionFilepath] = uigetfile([handles.data.settings.detectionfolder '/*.mat'],'Select Detection File(s) for Merging','MultiSelect', 'on');
if isnumeric(detectionFilename); return; end

hc = waitbar(0,'Merging Output Structures');

cd(handles.data.squeakfolder);
detectionFilename = cellstr(detectionFilename);

% Concatenate detection files
Calls_temp = [];

for j = 1:length(detectionFilename)
    Calls_ThisFile = loadCallfile(fullfile(detectionFilepath, detectionFilename{j}),handles,false);
    Calls_temp = [Calls_temp; Calls_ThisFile];
end

%% Merge overlapping boxes in det files from same audio
waitbar(.5,hc,'Writing Output Structure');
Calls = [];
uniqAudio = unique(Calls.Audiodata,'stable');
for i = 1:length(uniqAudio)
    Calls_ThisAudio = Calls_temp(Calls_temp.Audiodata == uniqAudio(i));
    Calls_ThisAudio = merge_boxes(Calls_ThisAudio.Box, Calls_ThisAudio.Score, Calls_ThisAudio.Type, uniqAudio(i), Calls_ThisAudio.DetSpect(1), 1, 0, 0);
    Calls = [Calls; Calls_ThisAudio];
end

[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, '*.mat'), 'Save Merged Detections');
waitbar(1/2, hc, 'Saving...');
save(fullfile(PathName, FileName),'Calls','-v7.3');
update_folders(hObject, eventdata, handles);
close(hc);
