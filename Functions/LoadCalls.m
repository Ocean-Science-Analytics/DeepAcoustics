% --- Executes on button press in LOAD CALLS.
function LoadCalls(hObject, eventdata, handles, indSt)
update_folders(hObject, eventdata, handles);
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
        update_folders(hObject, eventdata, handles);
        handles = guidata(hObject);  % Get newest version of handles
    end

    [handles.data.calls, handles.data.allAudio, handles.data.settings.spect, handles.data.detmetadata] = loadCallfile(fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.current_detection_file), handles,false);
    
    % If not automatically reloading due to another function (e.g. Next/Prev
    % Call) user needs to pick which audio file to load
    % Default to first/only audio file
    indSt = 1;
    % Get names of audio files contributing to this detection file
    allAudio = unique({handles.data.calls.Audiodata.Filename},'stable');
    % If more than one audio file, have user pick which one to start
    if length(allAudio) > 1
        audioselection = listdlg('PromptString','Select which Audio to Load :','ListSize',[500 300],'SelectionMode','single','ListString',allAudio);
        indSt = find(strcmp({handles.data.calls.Audiodata.Filename},allAudio{audioselection}),1,'first');
    end
end

% Get audio info for the correct audio file
% indSt == 0 => We want the previous audio file
if indSt == 0
    handles.data.audiodata = handles.data.calls.Audiodata(handles.data.thisaudst-1);
    handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'first');
else
    handles.data.audiodata = handles.data.calls.Audiodata(indSt);
    handles.data.thisaudst = indSt;
end
handles.data.thisaudend = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'last');
if ~isempty(handles.data.detmetadata) && isa(handles.data.detmetadata.Settings,'double')
    handles.data.settings.detectionSettings = sprintfc('%g',handles.data.detmetadata.Settings)';
end

% Position of the focus window to the first call in the file
handles.data.focusCenter = handles.data.calls.Box(handles.data.thisaudst,1) + handles.data.calls.Box(handles.data.thisaudst,3)/2;

% For some unknown reason, if "h" is closed after running
% "initialize_display", then holding down an arror key will be a little
% slower. See update_fig.m for details
close(h);
initialize_display(hObject, eventdata, handles);
