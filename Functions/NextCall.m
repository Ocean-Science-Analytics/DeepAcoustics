function NextCall(hObject, eventdata, handles)
    if handles.data.currentcall < height(handles.data.calls) % If not the last call
        handles.data.currentcall=handles.data.currentcall+1;
        handles.data.focusCenter = handles.data.calls.Box(handles.data.currentcall,1) + handles.data.calls.Box(handles.data.currentcall,3)/2;
    end
    handles.data.current_call_valid = true;
    update_fig(hObject, handles);
end