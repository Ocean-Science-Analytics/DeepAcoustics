function BackALot(hObject, eventdata, handles)
    % Rewind the length of the page window (current focusCenter =
    % windowposition (L edge of focus window) + focus_window_size ./2 )
    % Don't go < start of audio file
    handles.data.focusCenter = max(0, handles.data.windowposition - handles.data.settings.pageSize + handles.data.settings.focus_window_size ./ 2);
    
    jumps = floor(handles.data.focusCenter / handles.data.settings.pageSize);
    handles.data.windowposition = jumps*handles.data.settings.pageSize;
    
    % if we can't page because we're at the beg of the file, make the first call
    % the current call
    if jumps == 0
        if ~isempty(handles.data.thisaudst)
            handles.data.currentcall = handles.data.thisaudst;
            handles.data.current_call_valid = true;
        end
    % Otherwise make the first call in the new page window the current call
    % Make sure audio matches (for mult aud per det file)
    else
        calls_within_window = find((handles.data.calls.Box(:,1) > handles.data.windowposition) & strcmp({handles.data.calls.Audiodata.Filename}',handles.data.audiodata.Filename), 1);
        if ~isempty(calls_within_window)
            handles.data.currentcall = calls_within_window;
            handles.data.current_call_valid = true;
        end
    end
    update_fig(hObject, eventdata, handles);
end