function SortCalls(hObject, eventdata, handles, sort_type, show_waitbar, select_added)
% Sort current file by score
set(handles.hFig, 'pointer', 'watch')
if nargin < 5
    show_waitbar = 1;
end
if nargin < 6
   select_added = 0; 
end
if show_waitbar
    h = waitbar(0,'Sorting...');
end

% First sort by audio file name and reset beg and end Calls table indices
[~,idx] = sort({handles.data.calls.Audiodata.Filename});
handles.data.calls = handles.data.calls(idx, :);
handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'first');
handles.data.thisaudend = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'last');

% Then subset calls to those restricted to current audio file
subCalls = handles.data.calls(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),:);
if ~isempty(subCalls)
    switch sort_type
        case 'score'
            [~,idx] = sort(subCalls.Score);
        case 'time'
            [~,idx] = sortrows(subCalls.Box, 1);
        case 'duration'
            [~,idx] = sortrows(subCalls.Box, 4);
        case 'frequency'
            [~,idx] = sort(sum(subCalls.Box(:, [2, 2, 4]), 2));
    end
    
    % Reset current call index accordingly
    if select_added == 0
        % Select first call in this audio file
        handles.data.currentcall = handles.data.thisaudst;
    elseif select_added == -1
        % Select most recently added call (last call pre-sort, offset with
        % thisaudst, one-based indexing)
        handles.data.currentcall = find(idx == size(subCalls,1)) + handles.data.thisaudst - 1;
    else
        if handles.data.currentcall < handles.data.thisaudst || handles.data.currentcall > handles.data.thisaudend
            error('Something wrong indexing currentcall - talk to GA')
        end
        % Select currently selected call (compensating for index post-sort,
        % offset with thisaudst, one-based indexing)
        handles.data.currentcall = find(idx == (select_added - handles.data.thisaudst + 1)); 
    end
    subCalls = subCalls(idx, :);
    % Added sorted subset back to main structure
    handles.data.calls(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),:) = subCalls;
    % Move focus to new current call
    handles.data.focusCenter = handles.data.calls.Box(handles.data.currentcall,1) + handles.data.calls.Box(handles.data.currentcall,3)/2;
end

update_fig(hObject, eventdata, handles);

if show_waitbar
    close(h);
end

set(handles.hFig, 'pointer', 'arrow');
end
