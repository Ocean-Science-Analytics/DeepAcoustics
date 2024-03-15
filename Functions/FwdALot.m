function FwdALot(hObject, eventdata, handles)
    % handles.data.windowposition = min(handles.data.audiodata.Duration - handles.data.settings.pageSize, handles.data.windowposition + handles.data.settings.pageSize);
    handles.data.focusCenter = handles.data.windowposition + handles.data.settings.pageSize + handles.data.settings.focus_window_size ./ 2;
    handles.data.focusCenter = min(handles.data.focusCenter, handles.data.audiodata.Duration - handles.data.settings.focus_window_size ./ 2);
    
    jumps = floor(handles.data.focusCenter / handles.data.settings.pageSize);
    handles.data.windowposition = jumps*handles.data.settings.pageSize;
    
    if ~isempty(handles.data.calls)
        % handles.data.focusCenter = max(0, handles.data.windowposition - handles.data.settings.focus_window_size ./ 2);
        % get_closest_call_to_focus(hObject, eventdata, handles);
        
        % if we can't page because we're at the end of the file, make the last call
        % the current call
        if jumps == 0
            if ~isempty(handles.data.calls)
                handles.data.currentcall = height(handles.data.calls);
                handles.data.current_call_valid = true;
            end
        % Otherwise make the first call in the new page window the current call
        % (will not necessarily be in focusWindow)
        else
            calls_within_window = find(handles.data.calls.Box(:,1) > handles.data.windowposition, 1);
            if ~isempty(calls_within_window)
                handles.data.currentcall = calls_within_window;
                handles.data.current_call_valid = true;
            end
        end
    end
    
    update_fig(hObject, eventdata, handles);
end