function PrevCall(hObject, eventdata, handles)
    if handles.data.currentcall > 1 % If not the first call
        handles.data.currentcall=handles.data.currentcall-1;
        handles.data.focusCenter = handles.data.calls.Box(handles.data.currentcall,1) + handles.data.calls.Box(handles.data.currentcall,3)/2;
    end
    handles.data.current_call_valid = true;
    update_fig(hObject, eventdata, handles);
end