% --- Executes on button press in LOAD CALLS.
function LoadCalls(hObject, eventdata, handles, ~)
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);
if nargin == 3 % if "Load Calls" button pressed, load the selected file, else reload the current file  
    %Check if pre-existing detection file has changed to save file before loading a new one.
    if ~isempty(handles.data.calls)
        [~, ~, ~, modcheck] = loadCallfile(fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.current_detection_file), handles);
        if ~isequal(modcheck.calls, handles.data.calls) || ~isequal(modcheck.spect, handles.data.settings.spect)
            opts.Interpreter = 'tex';
            opts.Default='Yes';
            if ~isequal(modcheck.calls, handles.data.calls) 
                saveChanges = questdlg('\color{red}\bf WARNING! \color{black} Detection file has been modified. Would you like to save changes?','Save Detection File?','Yes','No',opts);
            elseif ~isequal(modcheck.spect, handles.data.settings.spect)
                saveChanges = questdlg('\color{red}\bf WARNING! \color{black} Spectrogram settings have been modified. Would you like to save changes in the det file (spect variable)?','Save Detection File?','Yes','No',opts);
            end
            switch saveChanges
                case 'Yes'
                    SaveSession(hObject, eventdata, handles);
                case 'No'
            end
        end
    end
    
    % Select new detections file
    [newdetfile,newdetpath] = uigetfile('*.mat');
    % If cancel, return
    if isequal(newdetfile,0)
       return;
    % Else get ready to load new file
    else
        % Update detection file info
        matsindir = dir([handles.data.settings.detectionfolder '/*.mat*']);
        matsindir = {matsindir.name};
        handles.current_file_id = find(strcmp(newdetfile,matsindir));
        handles.current_detection_file = newdetfile;
        % Update Settings
        handles.data.settings.detectionfolder = newdetpath;
        handles.data.saveSettings();
        update_folders(hObject, eventdata, handles);
    end
end

h = waitbar(0,'Loading Calls Please wait...');
% Whenever load new file, reset bAnnotate to false
handles.data.bAnnotate = false;
handles.data.calls = [];
handles.data.audiodata = [];
[handles.data.calls, handles.data.audiodata] = loadCallfile(fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.current_detection_file), handles);

% Position of the focus window to the first call in the file
handles.data.focusCenter = handles.data.calls.Box(1,1) + handles.data.calls.Box(1,3)/2;

% For some unknown reason, if "h" is closed after running
% "initialize_display", then holding down an arror key will be a little
% slower. See update_fig.m for details
close(h);
initialize_display(hObject, eventdata, handles);
