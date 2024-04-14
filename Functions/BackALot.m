function BackALot(hObject, eventdata, handles)
    % handles.data.windowposition = max(0, handles.data.windowposition - handles.data.settings.pageSize);
    handles.data.focusCenter = max(0, handles.data.windowposition - handles.data.settings.focus_window_size ./ 2);
    % get_closest_call_to_focus(hObject, eventdata, handles);
    
    jumps = floor(handles.data.focusCenter / handles.data.settings.pageSize);
    handles.data.windowposition = jumps*handles.data.settings.pageSize;
    
    if ~isempty(handles.data.calls)
        % if we can't page because we're at the beg of the file, make the first call
        % the current call
        if jumps == 0
            if ~isempty(handles.data.calls)
                handles.data.currentcall = 1;
                handles.data.current_call_valid = true;
            end
        % Otherwise make the last call in the new page window the current call
        % (will not necessarily be in focusWindow)
        else
            calls_within_window = find(handles.data.calls.Box(:,1) < handles.data.windowposition + handles.data.settings.pageSize, 1, 'last');
            if ~isempty(calls_within_window)
                handles.data.currentcall = calls_within_window;
                handles.data.current_call_valid = true;
            end
        end
    end
    update_fig(hObject, handles);
end