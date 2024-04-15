function SetFocusCall(hObject, handles, call_index)
% Set mouse busy signal
set(handles.hFig, 'pointer', 'watch')

% Subset calls to those restricted to current audio file
subCalls = handles.data.calls;

% Reset current call index accordingly
if ~isempty(subCalls)
    if call_index == 0
        % Select first call in this audio file
        call_index = 1;
    elseif call_index == -1
        % Select most recently added call (last call pre-sort, offset with
        % thisaudst, one-based indexing)
        call_index = height(subCalls);
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