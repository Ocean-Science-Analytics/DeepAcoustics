function NextCall(hObject, eventdata, handles)
    if handles.data.currentcall < handles.data.thisaudend % If not the last call
        handles.data.currentcall = handles.data.currentcall+1;
        handles.data.focusCenter = handles.data.calls.Box(handles.data.currentcall,1) + handles.data.calls.Box(handles.data.currentcall,3)/2;
        handles.data.current_call_valid = true;
        update_fig(hObject, handles);
    else
        NextFile(hObject, eventdata, handles);
    end
end