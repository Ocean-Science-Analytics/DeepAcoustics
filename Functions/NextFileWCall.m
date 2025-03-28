function NextFileWCall(hObject, eventdata, handles)
update_folders(hObject, handles);
handles = guidata(hObject);  % Get newest version of handles

% Break if find calls or no calls any later in dataset
while isempty(handles.data.thisaudst) && handles.data.thisAllAudind < height(handles.data.allAudio)
    handles.data.thisAllAudind = handles.data.thisAllAudind + 1;
    handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.allAudio(handles.data.thisAllAudind).Filename),1,'first');
    handles.data.thisaudend = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.allAudio(handles.data.thisAllAudind).Filename),1,'last');

    % Set thisaudend to one before thisaudst so that indexing below is
    % correct (i.e., LoadCalls will load actual thisaudst and then reset
    % thisaudst and thisaudend correctly)
    if ~isempty(handles.data.thisaudst)
        handles.data.thisaudend = handles.data.thisaudst-1;
    end
end

% If next call found
if ~isempty(handles.data.thisaudst)
    if handles.data.thisaudend < height(handles.data.calls)
        % Check for changes to save to current file
        %CheckModified(hObject, eventdata, handles);
        % Load first call in the next audio file with dets in this detections file
        LoadCalls(hObject, eventdata, handles, handles.data.thisaudend+1)
    end
end