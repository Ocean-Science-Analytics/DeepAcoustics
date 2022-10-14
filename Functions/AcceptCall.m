function AcceptCall(hObject, eventdata, handles)
    handles.data.calls.Accept(handles.data.currentcall) = true;
    handles.data.calls.Type(handles.data.currentcall) = categorical({'Call'});
    handles.update_position_axes = 1;
    NextCall(hObject, eventdata, handles);
end