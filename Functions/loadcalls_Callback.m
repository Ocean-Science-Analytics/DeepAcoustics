% --- Executes on button press in LOAD CALLS.
function loadcalls_Callback(hObject, eventdata, handles, reload_current_file)
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);
if nargin == 3 % if "Load Calls" button pressed, load the selected file, else reload the current file
    if isempty(handles.detectionfiles)
        close(h);
        errordlg(['No valid detection files in current folder. Select a folder containing detection files with '...
            '"File -> Select Detection Folder", then choose the desired file in the "Detected Call Files" dropdown box.'])
        return
    end
    
    %Check if detection file has changed to save file before loading a new one.
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
                    savesession_Callback(hObject, eventdata, handles);
                case 'No'
            end
        end
    end
    
    handles.current_file_id = get(handles.popupmenuDetectionFiles,'Value');
    handles.current_detection_file = handles.detectionfiles(handles.current_file_id).name;
end

h = waitbar(0,'Loading Calls Please wait...');
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
