function RemoveRejects(hObject, eventdata, handles)

handles.data.calls = handles.data.calls(handles.data.calls.Accept == 1, :);

if ~isempty(handles.data.calls)
    % If no calls left in current audio file, but calls in other files, load
    % first audio file and its calls
    if ~any(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename))
        handles.data.audiodata = handles.data.calls.Audiodata(1);
    end
    handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'first');
    handles.data.thisaudend = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'last');
    handles.data.currentcall = handles.data.thisaudst;
else
    handles.data.thisaudst = 1;
    handles.data.thisaudend = 1;
    handles.data.currentcall = 1;
end

update_fig(hObject, handles);
guidata(hObject, handles);