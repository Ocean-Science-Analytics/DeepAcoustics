function ImportMUPET(hObject, eventdata, handles)

[mupetname, mupetpath] = uigetfile('*.csv','Select MUPET Log');
MUPET = readtable([mupetpath mupetname]);

[audioname, audiopath] = uigetfile({
    '*.wav;*.ogg;*.flac;*.UVD;*.au;*.aiff;*.aif;*.aifc;*.mp3;*.m4a;*.mp4' 'Audio File'
    '*.wav' 'WAVE'
    '*.flac' 'FLAC'
    '*.ogg' 'OGG'
    '*.UVD' 'Ultravox File'
    '*.aiff;*.aif', 'AIFF'
    '*.aifc', 'AIFC'
    '*.mp3', 'MP3 (it''s probably a bad idea to record in MP3'
    '*.m4a;*.mp4' 'MPEG-4 AAC'
    }, ['Select Audio File for ' mupetname], handles.data.settings.audiofolder);
if FileName == 0
    return
end
audiodata = audioinfo([audiopath audioname]);

Calls = struct('Box',struct,'Score',struct,'Accept',struct,'Type',struct);
hc = waitbar(0,'Importing Calls from MUPET Log');
for i=1:length(MUPET.SyllableNumber)
    waitbar(i/length(MUPET.SyllableNumber),hc);
    Calls(i).Box = [MUPET.SyllableStartTime_sec_(i), MUPET.minimumFrequency_kHz_(i), MUPET.syllableDuration_msec_(i)/1000, MUPET.frequencyBandwidth_kHz_(i)];
    Calls(i).Score = 1;
    Calls(i).Accept=1;
    Calls(i).Type=categorical({'Call'});
    Calls(i).Audiodata = audiodata;
end
Calls = struct2table(Calls);
[~, name] = fileparts(mupetname);
[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, [name '_Detections.mat']),'Save Call File');
detectiontime = datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
detection_metadata = struct(...
    'Settings', 'N/A; MUPET Import',...
    'detectiontime', detectiontime,...
    'networkselections', 'N/A; MUPET Import');
spect = handles.data.settings.spect;
allAudio = audiodata;
% Save Detections.mat
save([PathName, FileName],'Calls','allAudio','detection_metadata','spect','-v7.3');
close(hc);
update_folders(hObject, handles);
