function MoveFocus(focus_offset, hObject, eventdata, handles, bRT)
    if nargin < 5
        bRT = false;
    end
    % Move the focus window one unit over
    new_position = handles.data.focusCenter + focus_offset;
    new_position = min(new_position, handles.data.audiodata.Duration - handles.data.settings.focus_window_size ./ 2);
    new_position = max(new_position, handles.data.settings.focus_window_size ./ 2);
    handles.data.focusCenter = new_position;
    
    if new_position > handles.data.windowposition + handles.data.settings.pageSize
        FwdALot(hObject, eventdata, handles);
    elseif new_position < handles.data.windowposition
        BackALot(hObject, eventdata, handles);
    else
        if ~isempty(handles.data.calls)
            calls_within_window = find(...
                ((handles.data.calls.Box(:,1) > new_position - handles.data.settings.focus_window_size/2 & ...
                handles.data.calls.Box(:,1) < new_position + handles.data.settings.focus_window_size/2) | ...
                (sum(handles.data.calls.Box(:,[1,3]),2) > new_position - handles.data.settings.focus_window_size/2 &...
                sum(handles.data.calls.Box(:,[1,3]),2) < new_position + handles.data.settings.focus_window_size/2)) & ...
                strcmp({handles.data.calls.Audiodata.Filename}',handles.data.audiodata.Filename));
            if ~isempty(calls_within_window)
                handles.data.currentcall = calls_within_window(1);
            end
        end
    
        guidata(hObject,handles);
        % Force render if RT
        update_fig(hObject, handles, bRT);
    end
end