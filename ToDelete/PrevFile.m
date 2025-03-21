function PrevFileWCall(hObject, eventdata, handles)
update_folders(hObject, handles);
handles = guidata(hObject);  % Get newest version of handles
if handles.data.thisaudst > 1
    % Check for changes to save to current file
    %CheckModified(hObject, eventdata, handles);
    % Load next audio file in this detections file
    LoadCalls(hObject, eventdata, handles, handles.data.thisaudst-1);
end