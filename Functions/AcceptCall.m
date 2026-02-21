function AcceptCall(hObject, eventdata, handles,app)
    if handles.data.currentcall > 0
        % if Accept already true, do NOT change label
        if ~handles.data.calls.Accept(handles.data.currentcall)
            handles.data.calls.Accept(handles.data.currentcall) = true;
            handles.data.calls.Type(handles.data.currentcall) = categorical({app.textDrawType.Text});
        end
        handles.update_position_axes = 1;
        NextCall(hObject, eventdata, handles);
    end
end