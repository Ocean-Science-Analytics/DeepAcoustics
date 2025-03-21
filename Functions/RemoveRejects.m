function RemoveRejects(hObject, ~, handles)

% Remove rejects
handles.data.calls = handles.data.calls(handles.data.calls.Accept == 1, :);

LoadCalls(hObject, eventdata, handles, 0, handles.data.thisAllAudind);

update_fig(hObject, handles);
guidata(hObject, handles);