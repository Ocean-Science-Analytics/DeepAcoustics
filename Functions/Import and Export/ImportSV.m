function ImportSV(hObject, eventdata, handles)

HZ_IN_KHZ = 1000;

[svname, svpath] = uigetfile('*.csv','Select Sonic visualizer box layer');
sv_table = readtable([svpath svname],'Delimiter', ',');

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
    }, ['Select Audio File for ' svname],handles.data.settings.audiofolder);

Calls  = cell2table(cell(0,5), 'VariableNames', {'Box', 'Score', 'Accept', 'Type', 'Tag'});
hc = waitbar(0,'Importing Calls from Sonic Visualizer');
n_rows = size(sv_table,1);
for i=1:n_rows
    waitbar(i/n_rows,hc);
    call_start = sv_table{i,1};
    call_duration = sv_table{i,2} - call_start;
    call_frequency_start = sv_table{i,3};
    call_frequency_length = sv_table{i,4} - call_frequency_start;
    call_label = 'Call';
    if size(sv_table,2) == 5
       call_label = cellstr(sv_table{i,5});     
    end

    box = [call_start,call_frequency_start/HZ_IN_KHZ, call_duration, call_frequency_length/HZ_IN_KHZ];
    
    new_call = {box,1,1,categorical(call_label),1,i};
    Calls = [Calls;new_call];
    
end
[~, box_file_name] = fileparts(svname);

audiodata = audioinfo(fullfile(audiopath, audioname));
Calls.Audiodata = repmat(audiodata,height(Calls),1);

% FileName = [audio_file_name, datestr(datetime('now'),'mmm-dd-yyyy hh_MM AM'), ' ',box_file_name, '.mat'];
% FilePath = [handles.data.settings.detectionfolder, FileName];
[FileName, ~] = uiputfile(fullfile(handles.data.settings.detectionfolder, [box_file_name '_Detections.mat']),'Save Call File');
FilePath = [handles.data.settings.detectionfolder, FileName];
detectiontime = datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
detection_metadata = struct(...
    'Settings', 'N/A; SV Import',...
    'detectiontime', detectiontime,...
    'networkselections', 'N/A; SV Import');
spect = handles.data.settings.spect;
allAudio = audiodata;
save(FilePath,'Calls','allAudio','detection_metadata','spect','-v7.3');
close(hc);
update_folders(hObject, handles);
