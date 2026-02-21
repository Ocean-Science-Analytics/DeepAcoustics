function PrevCall(hObject, eventdata, handles)
    if ~isempty(handles.data.thisaudst)
        if handles.data.currentcall > handles.data.thisaudst % If not the first call
            handles.data.currentcall = handles.data.currentcall-1;
            while (handles.data.currentcall > handles.data.thisaudst) && handles.data.calls.Visible(handles.data.currentcall) == 0
                handles.data.currentcall = handles.data.currentcall-1;
            end

            handles.data.focusCenter = handles.data.calls.Box(handles.data.currentcall,1) + handles.data.calls.Box(handles.data.currentcall,3)/2;
            update_fig(hObject, handles);
        else
            % Load previous audio with call
            PrevFileWCall(hObject, eventdata, handles);
        end
    else
        if isempty(handles.data.calls)
            error('No Calls Loaded')
        else
            % Load previous audio with call
            PrevFileWCall(hObject, eventdata, handles);
        end
    end
end