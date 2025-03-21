% --- Executes on button press in LOAD CALLS.
function LoadCalls(hObject, eventdata, handles, indCall, indAud)
update_folders(hObject, handles);
handles = guidata(hObject);

% if "Load Calls" button pressed, check for modifications to current file,
% then load a user selected file, else reload the current file
h = waitbar(0,'Loading Calls Please wait...');
if nargin < 4
    CheckModified(hObject,eventdata,handles);
    
    % Select new detections file
    [newdetfile,newdetpath] = uigetfile('*.mat','Select detections.mat file to load',handles.data.settings.detectionfolder);
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
        update_folders(hObject, handles);
        handles = guidata(hObject);  % Get newest version of handles
    end

    [handles.data.calls, handles.data.allAudio, handles.data.settings.spect, handles.data.detmetadata] = loadCallfile(fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.current_detection_file), handles,false);
    
    % If not automatically reloading due to another function (e.g. Next/Prev
    % Call) user needs to pick which audio file to load
    % Default to first/only audio file
    indAud = 1;
    indCall = 0;
    % Get names of audio files contributing to this detection file
    allAudio = {handles.data.allAudio.Filename};
    % If more than one audio file, have user pick which one to start
    if length(allAudio) > 1
        indAud = listdlg('PromptString','Select which Audio to Load :','ListSize',[500 300],'SelectionMode','single','ListString',allAudio);
    end
end

if nargin == 4 && indCall == 0
    error('This should not happen')
end

% Get audio info for the correct audio file
% indCall == 0 => We want to load indAud, whether there are calls in it or
% not
if indCall == 0
    handles.data.thisAllAudind = indAud;
else
    % We want to load the audiofile corresponding to the specified call
    % index to load
    handles.data.thisAllAudind = find(strcmp({handles.data.allAudio.Filename},handles.data.calls.Audiodata(indCall).Filename));
    if length(handles.data.thisAllAudind) ~= 1
        error('This should not happen')
    end
end

handles.data.audiodata = handles.data.allAudio(handles.data.thisAllAudind);
handles.data.thisaudst = [];
handles.data.thisaudend = [];
handles.data.currentcall = 0;
if ~isempty(handles.data.calls)
    handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'first');
    handles.data.thisaudend = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'last');
end

if ~isempty(handles.data.detmetadata) && isa(handles.data.detmetadata.Settings,'double')
    handles.data.settings.detectionSettings = sprintfc('%g',handles.data.detmetadata.Settings)';
end

% Position of the focus window to the first call in the file (unless no
% calls)
handles.data.focusCenter = handles.data.settings.focus_window_size ./ 2;
if ~isempty(handles.data.thisaudst)
    handles.data.focusCenter = handles.data.calls.Box(handles.data.thisaudst,1) + handles.data.calls.Box(handles.data.thisaudst,3)/2;
    handles.data.currentcall = handles.data.thisaudst;
end

% For some unknown reason, if "h" is closed after running
% "initialize_display", then holding down an arror key will be a little
% slower. See update_fig.m for details
close(h);
initialize_display(hObject, eventdata, handles);
