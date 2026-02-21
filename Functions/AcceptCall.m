function AcceptCall(hObject, eventdata, handles,app)
    if handles.data.currentcall > 0
        handles.data.calls.Accept(handles.data.currentcall) = true;
        handles.data.calls.Type(handles.data.currentcall) = categorical({app.textDrawType.Text});
        handles.update_position_axes = 1;
        NextCall(hObject, eventdata, handles);
    end
end