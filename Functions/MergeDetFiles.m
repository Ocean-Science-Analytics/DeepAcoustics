function MergeDetFiles(hObject, eventdata, handles)

cd(handles.data.squeakfolder);
[detectionFilename, detectionFilepath] = uigetfile([handles.data.settings.detectionfolder '/*.mat'],'Select Detection File(s) for Merging','MultiSelect', 'on');
if isnumeric(detectionFilename); return; end

[audiofile, audiopath] = uigetfile({
    '*.wav;*.ogg;*.flac;*.UVD;*.au;*.aiff;*.aif;*.aifc;*.mp3;*.m4a;*.mp4' 'Audio File'
    '*.wav' 'WAVE'
    '*.flac' 'FLAC'
    '*.ogg' 'OGG'
    '*.UVD' 'Ultravox File'
    '*.aiff;*.aif', 'AIFF'
    '*.aifc', 'AIFC'
    '*.mp3', 'MP3 (it''s probably a bad idea to record in MP3'
    '*.m4a;*.mp4' 'MPEG-4 AAC'
    }, 'Select Corresponding Audio File',handles.data.settings.audiofolder);
    
if isnumeric(audiofile); return; end

hc = waitbar(0,'Merging Output Structures');

cd(handles.data.squeakfolder);
detectionFilename = cellstr(detectionFilename);

AllBoxes = [];
AllScores = [];
AllClass = [];
AllAccept = [];
allAudio = [];

for j = 1:length(detectionFilename)
    [Calls, allAudio_ThisFile] = loadCallfile(fullfile(detectionFilepath, detectionFilename{j}),handles,false);
    allAudio = [allAudio; allAudio_ThisFile];

    AllBoxes = [AllBoxes; Calls.Box];
    AllScores = [AllScores; Calls.Score];
    AllClass = [AllClass; Calls.Type];
    AllAccept = [AllAccept; Calls.Accept];
end

% Audio info
audio_info = audioinfo([audiopath audiofile]);
if audio_info.NumChannels > 1
    warning('Audio file contains more than one channel. Use channel 1...')
end

clear('Calls')
%% Merge overlapping boxes
waitbar(.5,hc,'Writing Output Structure');
Calls = merge_boxes(AllBoxes, AllScores .* AllAccept, AllClass, audio_info, 1, 0, 0);

[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, '*.mat'), 'Save Merged Detections');
waitbar(1/2, hc, 'Saving...');
detectiontime = datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
detection_metadata = struct(...
    'Settings', 'N/A; Det Merge',...
    'detectiontime', detectiontime,...
    'networkselections', 'N/A; Det Merge');
spect = handles.data.settings.spect;
save(fullfile(PathName, FileName),'Calls','allAudio','detection_metadata','spect','-v7.3');
update_folders(hObject, eventdata, handles);
close(hc);
