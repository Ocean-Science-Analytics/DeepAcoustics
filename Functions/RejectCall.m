function RejectCall(hObject, eventdata, handles)
    handles.data.calls.Accept(handles.data.currentcall) = false;
    handles.data.calls.Type(handles.data.currentcall) = categorical({'Noise'});
    handles.update_position_axes = 1;
    NextCall(hObject, eventdata, handles);
end