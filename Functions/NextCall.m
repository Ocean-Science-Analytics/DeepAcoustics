function NextCall(hObject, eventdata, handles)
    if ~isempty(handles.data.thisaudst)
        if handles.data.currentcall < handles.data.thisaudend % If not the last call
            handles.data.currentcall = handles.data.currentcall+1;
            handles.data.focusCenter = handles.data.calls.Box(handles.data.currentcall,1) + handles.data.calls.Box(handles.data.currentcall,3)/2;
            update_fig(hObject, handles);
        else
            % Load next audio with call
            NextFileWCall(hObject, eventdata, handles);
        end
    else
        % Load next audio with call
        NextFileWCall(hObject, eventdata, handles);
    end
end