function BackALot(hObject, eventdata, handles)
    % Rewind the length of the page window (current focusCenter =
    % windowposition (L edge of focus window) + focus_window_size ./2 )
    handles.data.focusCenter = handles.data.windowposition - handles.data.settings.pageSize + handles.data.settings.focus_window_size ./ 2;

    % If we reach the beg of the audio file, call prev file
    if handles.data.focusCenter < 0
        PrevAudFile(hObject, eventdata, handles);
    else
        % Don't go < start of audio file
        handles.data.focusCenter = max(0, handles.data.focusCenter);
        
        jumps = floor(handles.data.focusCenter / handles.data.settings.pageSize);
        handles.data.windowposition = jumps*handles.data.settings.pageSize;
        
        if ~isempty(handles.data.calls)
            % if we can't page because we're at the beg of the file, make the first call
            % the current call
            if jumps == 0
                if ~isempty(handles.data.thisaudst)
                    handles.data.currentcall = handles.data.thisaudst;
                end
            % Otherwise make the first call in the new page window the current call
            % Make sure audio matches (for mult aud per det file)
            else
                calls_within_window = find((handles.data.calls.Box(:,1) > handles.data.windowposition) & strcmp({handles.data.calls.Audiodata.Filename}',handles.data.audiodata.Filename), 1);
                if ~isempty(calls_within_window)
                    handles.data.currentcall = calls_within_window;
                end
            end
        end
        update_fig(hObject, handles);
    end
end