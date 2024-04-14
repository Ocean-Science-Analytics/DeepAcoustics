function SetFocusCall(hObject, handles, call_index)
% Set mouse busy signal
set(handles.hFig, 'pointer', 'watch')

% Get beginning and end rows for the current audio file
handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'first');
handles.data.thisaudend = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'last');

% Subset calls to those restricted to current audio file
subCalls = handles.data.calls(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),:);

% Reset current call index accordingly
if ~isempty(subCalls)
    if select_added == 0
        % Select first call in this audio file
        call_index = handles.data.thisaudst;
    elseif select_added == -1
        % Select most recently added call (last call pre-sort, offset with
        % thisaudst, one-based indexing)
        call_index = handles.data.thisaudend;
    else
        % Handle weirdness
        if call_index < handles.data.thisaudst
            call_index = handles.data.thisaudst;
        elseif call_index > handles.data.thisaudend
            call_index = handles.data.thisaudend;
        end
    end
% If not calls in audio file, default to zero?
else
    call_index = 0;
    warning('Need to check and decide how to handle this - talk to GA')
end

% Sort calls and reset current call
[handles.data.calls,handles.data.currentcall] = SortCalls(handles.data.calls,'time',call_index);

% Move focus to new current call
handles.data.focusCenter = handles.data.calls.Box(handles.data.currentcall,1) + handles.data.calls.Box(handles.data.currentcall,3)/2;

% Update figure
update_fig(hObject, handles);

% End mouse busy signal
set(handles.hFig, 'pointer', 'arrow');