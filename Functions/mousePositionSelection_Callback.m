function  mousePositionSelection_Callback(hObject,eventdata, handles)
% This function runs when the little bar with the green lines  or the page window is clicked or 

handles.data.focusCenter = eventdata.IntersectionPoint(1);
% Ensure the new selection is within the range of audio
handles.data.focusCenter = max(handles.data.focusCenter,  handles.data.settings.focus_window_size/2);
handles.data.focusCenter = min(handles.data.focusCenter,  handles.data.audiodata.Duration - handles.data.settings.focus_window_size/2);

%% Find the call closest to the click and make it the current call
% Subset calls to those restricted to current audio file
if ~isempty(handles.data.calls)
    subCalls = handles.data.calls(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),:);
    if ~isempty(subCalls)
        callMidpoints = subCalls.Box(:,1) + subCalls.Box(:,3)/2;
        [~, closestCall] = min(abs(callMidpoints - handles.data.focusCenter));
        % Correct for index in full calls table using thisaudst
        handles.data.currentcall = closestCall + handles.data.thisaudst - 1;
    end
end

% update_fig runs guidata so we don't need that here
update_fig(hObject, handles);
end

