function PrevFile(hObject, eventdata, handles)
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles
numfiles = length(handles.detectionfiles);
%Make sure we actually have an active Detections folder
if numfiles > 0
    % Check for a previous file
    if handles.current_file_id > 1
        % If confirmed possible, decrement file
        handles.current_file_id = handles.current_file_id - 1;
        handles.current_detection_file = handles.detectionfiles(handles.current_file_id).name;
        % If make fourth argument 1, will bypass the behavior of pressing
        % the LoadCalls button but won't save changes
        LoadCalls(hObject, eventdata, handles);%, 1);
    end
end