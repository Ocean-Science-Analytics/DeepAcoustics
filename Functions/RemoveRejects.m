function RemoveRejects(hObject, eventdata, handles)

handles.data.calls = handles.data.calls(handles.data.calls.Accept == 1, :);
% If no calls left in current audio file, but calls in other files, load
% first audio file and its calls
if ~any(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename)) && ~isempty(handles.data.calls)
    handles.data.audiodata = handles.data.calls.Audiodata(1);
end
handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'first');
handles.data.thisaudend = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'last');
handles.data.currentcall = handles.data.thisaudst;

update_fig(hObject, eventdata, handles);
guidata(hObject, handles);