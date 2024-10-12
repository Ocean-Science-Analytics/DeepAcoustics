function ChangePlaybackRate(hObject, eventdata, handles)
    prompt = {'Playback Rate: (default = 0.0.5)'};
    dlg_title = 'Change Playback Rate';
    num_lines = [1 length(dlg_title)+30]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
    defaultans = {num2str(handles.data.settings.playback_rate)};
    rate = inputdlg(prompt,dlg_title,num_lines,defaultans);
    if isempty(rate); return; end
    
    [newrate,~,errmsg] = sscanf(rate{1},'%f',1);
    disp(errmsg);
    if ~isempty(newrate)
        handles.data.settings.playback_rate = newrate;
        handles.data.saveSettings();
        update_folders(hObject, eventdata, handles);
        handles = guidata(hObject);  % Get newest version of handles
    end
    guidata(hObject, handles);
end