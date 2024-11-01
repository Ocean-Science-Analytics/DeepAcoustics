% --- Executes on button press in LOAD AUDIO.
function LoadAudio(hObject, eventdata, handles, audiofn)

h = waitbar(0,'Loading Audio Please wait...');
handles.current_detection_file = '';
handles.current_file_id = '';
update_folders(hObject, handles);
handles = guidata(hObject);

if isempty(handles.audiofiles) && isempty(audiofn)
    close(h);
    errordlg(['No valid audio files in current audio folder. Select a folder containing audio with '...
        '"File -> Select Audio Folder", then choose the desired file in the "Audio Files" dropdown box.'])
    return
end
if isempty(audiofn)
    current_file_id = get(handles.AudioFilespopup,'Value');
    audiofn = fullfile(handles.data.settings.audiofolder,handles.audiofiles(current_file_id).name);
end

handles.data.audiodata = audioinfo(audiofn);

Calls = table(zeros(0,4),[],[],[],[],[],[],[],[],[],[],[], 'VariableNames', {'Box', 'Score', 'Type', 'Audiodata', 'DetSpect','CallID', 'ClustCat','EntThresh', 'AmpThresh', 'Accept','Ovlp','StTime'});
% Calls.Box = [0 0 1 1];
% Calls.Score = 0;
% Calls.Type = categorical({'NA'});
% Calls.Power = 1;
% Calls.Accept = false;
handles.data.calls = Calls;
% Position of the focus window
handles.data.focusCenter = handles.data.settings.focus_window_size ./ 2;
initialize_display(hObject, eventdata, handles);
close(h);