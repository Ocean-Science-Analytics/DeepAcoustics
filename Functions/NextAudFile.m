function NextAudFile(hObject, eventdata, handles)
update_folders(hObject, handles);
handles = guidata(hObject);  % Get newest version of handles
if handles.data.thisAllAudind < height(handles.data.allAudio)
    % Check for changes to save to current file
    %CheckModified(hObject, eventdata, handles);
    % Load next audio file in this detections file
    LoadCalls(hObject, eventdata, handles, 0, handles.data.thisAllAudind+1);
end