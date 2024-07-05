% --- Executes on button press in LOAD CALLS.
function LoadCalls(hObject, eventdata, handles, ~)
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);
% if "Load Calls" button pressed, check for changes, then select a file to load,
% else reload the current (or load Next/Prev) file
if nargin == 3 
    % Check if pre-existing detection file has changed to save file before loading a new one.
    CheckModified(hObject,eventdata,handles);
    
    % Select new detections file
    [newdetfile,newdetpath] = uigetfile('*.mat','Select detections.mat file',handles.data.settings.detectionfolder);
    % If cancel, return
    if isequaln(newdetfile,0)
       return;
    % Else get ready to load new file
    else
        % Update detection file info
        matsindir = dir([newdetpath '/*.mat*']);
        matsindir = {matsindir.name};
        handles.current_file_id = find(strcmp(newdetfile,matsindir));
        handles.current_detection_file = newdetfile;
        % Update Settings
        handles.data.settings.detectionfolder = newdetpath;
        handles.data.saveSettings();
        update_folders(hObject, eventdata, handles);
        handles = guidata(hObject);  % Get newest version of handles
    end
end

h = waitbar(0,'Loading Calls Please wait...');
% Whenever load new file, reset bAnnotate to false
handles.data.bAnnotate = false;
handles.data.calls = [];
handles.data.allAudio = [];
handles.data.audiodata = [];
[handles.data.calls, handles.data.allAudio, handles.data.audiodata, handles.data.settings.spect, detmetadata] = loadCallfile(fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.current_detection_file), handles,false);
if ~isempty(detmetadata)
    handles.data.settings.detectionSettings = sprintfc('%g',detmetadata.Settings)';
end

% Position of the focus window to the first call in the file
handles.data.focusCenter = handles.data.calls.Box(1,1) + handles.data.calls.Box(1,3)/2;

% For some unknown reason, if "h" is closed after running
% "initialize_display", then holding down an arror key will be a little
% slower. See update_fig.m for details
close(h);
initialize_display(hObject, eventdata, handles);
