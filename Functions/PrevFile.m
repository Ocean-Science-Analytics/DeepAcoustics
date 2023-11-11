function PrevFile(hObject, eventdata, handles)
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles
if handles.data.thisaudst > 1
    % Load next audio file in this detections file
    LoadCalls(hObject, eventdata, handles, 0)
end