function NextFile(hObject, eventdata, handles)
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles
if handles.data.thisaudend < height(handles.data.calls)
    % Check for changes to save to current file
    CheckModified(hObject, eventdata, handles);
    % Load next audio file in this detections file
    LoadCalls(hObject, eventdata, handles, handles.data.thisaudend+1)
end