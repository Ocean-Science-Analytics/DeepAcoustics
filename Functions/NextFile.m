function NextFile(hObject, eventdata, handles)
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles
numfiles = length(handles.detectionfiles);
%Make sure we actually have an active Detections folder
if numfiles > 0
    % Check for a next file
    if handles.current_file_id < numfiles
        % Check for changes to save to current file
        CheckModified(hObject, eventdata, handles);
        % If confirmed possible, increment to next file
        handles.current_file_id = handles.current_file_id + 1;
        handles.current_detection_file = handles.detectionfiles(handles.current_file_id).name;
        % If make fourth argument 1, will bypass manual selection of det
        % file
        LoadCalls(hObject, eventdata, handles, true);
    end
end