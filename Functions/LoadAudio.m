% --- Executes on button press in LOAD AUDIO.
function LoadAudio(hObject, eventdata, handles, audiofn)

h = waitbar(0,'Loading Audio Please wait...');
handles.current_detection_file = '';
handles.current_file_id = '';
update_folders(hObject, handles);
handles = guidata(hObject);

if nargin < 4
    [audiofn, audiopn] = uigetfile('*','Select audio file to load',handles.data.settings.audiofolder);
    if audiofn==0
        error('You chose to cancel')
    end
    audiofn = fullfile(audiopn,audiofn);
    
    audiodir = [dir([audiopn '\*.wav']); ...
        dir([audiopn '\*.ogg']); ...
        dir([audiopn '\*.flac']); ...
        dir([audiopn '\*.UVD']); ...
        dir([audiopn '\*.au']); ...
        dir([audiopn '\*.aiff']); ...
        dir([audiopn '\*.aif']); ...
        dir([audiopn '\*.aifc']); ...
        dir([audiopn '\*.mp3']); ...
        dir([audiopn '\*.m4a']); ...
        dir([audiopn '\*.mp4'])];
    
    allAudio = [];
    for i = 1:length(audiodir)
        allAudio = [allAudio; audioinfo(fullfile(audiopn, audiodir(i).name))];
    end
else
    allAudio = audioinfo(audiofn);
    [audiopn,~,~] = fileparts(audiofn);
end

handles.data.settings.audiofolder = audiopn;
handles.data.saveSettings();
update_folders(hObject, handles);

handles.data.audiodata = audioinfo(audiofn);
handles.data.allAudio = allAudio;
handles.data.thisAllAudind = 1;

Calls = table(zeros(0,4),[],[],[],[],[],[],[],[],[],[],[], 'VariableNames', {'Box', 'Score', 'Type', 'Audiodata', 'DetSpect','CallID', 'ClustCat','EntThresh', 'AmpThresh', 'Accept','Ovlp','StTime'});
% Calls.Box = [0 0 1 1];
% Calls.Score = 0;
% Calls.Type = categorical({'NA'});
% Calls.Power = 1;
% Calls.Accept = false;
handles.data.calls = Calls;
handles.data.thisaudst = [];
handles.data.thisaudend = [];
handles.data.currentcall = 0;
% Position of the focus window
handles.data.focusCenter = handles.data.settings.focus_window_size ./ 2;
initialize_display(hObject, eventdata, handles);
close(h);