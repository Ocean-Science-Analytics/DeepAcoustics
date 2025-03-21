function RejectCall(hObject, eventdata, handles)
    if handles.data.currentcall > 0
        handles.data.calls.Accept(handles.data.currentcall) = false;
        handles.data.calls.Type(handles.data.currentcall) = categorical({'Noise'});
        handles.update_position_axes = 1;
        NextCall(hObject, eventdata, handles);
    end
end