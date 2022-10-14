function PrevFile(hObject, eventdata, handles)
numfiles = length(handles.detectionfiles);
%Make sure we actually have an active Detections folder
if numfiles > 0
    handles.current_file_id = get(handles.popupmenuDetectionFiles,'Value');
    % Check for a previous file
    if handles.current_file_id > 1
        % If confirmed possible, decrement file
        handles.current_file_id = handles.current_file_id - 1;
        % Make sure the drop-down matches what's happening internally
        handles.popupmenuDetectionFiles.Value = handles.current_file_id;
        handles.current_detection_file = handles.detectionfiles(handles.current_file_id).name;
        % Last argument (1) bypasses the behavior of pressing the LoadCalls button
        LoadCalls(hObject, eventdata, handles, 1);
    end
end