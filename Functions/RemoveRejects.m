function RemoveRejects(hObject, eventdata, handles)

handles.data.calls = handles.data.calls(handles.data.calls.Accept == 1, :);
handles.data.currentcall = 1;

update_fig(hObject, handles);
guidata(hObject, handles);