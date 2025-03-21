function NextFileWCall(hObject, eventdata, handles)
update_folders(hObject, handles);
handles = guidata(hObject);  % Get newest version of handles

% Break if find calls or no calls any earlier in dataset
while isempty(handles.data.thisaudst) && handles.data.thisAllAudind < height(handles.data.allAudio)
    handles.data.thisAllAudind = handles.data.thisAllAudind + 1;
    handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.allAudio(handles.data.thisAllAudind).Filename),1,'first');

    % Subtract one because add one below
    if ~isempty(handles.data.thisaudst)
        handles.data.thisaudst = handles.data.thisaudst-1;
    end
end

% If next call found
if ~isempty(handles.data.thisaudst)
    if handles.data.thisaudend < height(handles.data.calls)
        % Check for changes to save to current file
        %CheckModified(hObject, eventdata, handles);
        % Load next audio file in this detections file
        LoadCalls(hObject, eventdata, handles, handles.data.thisaudend+1)
    end
end