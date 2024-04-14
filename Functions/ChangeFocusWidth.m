function ChangeFocusWidth(app, event)
if strcmp(app.dropdownFocus.Value,'Custom')
    % Make dialog
    prompt = {'Enter desired width of focus window (in seconds):'};
    dlg_title = 'Adjust Focus Width';
    num_lines = [1 length(dlg_title)+30];
    definput = {'5'};
    nNewValue = inputdlg(prompt,dlg_title,num_lines,definput);
    % Add custom value to Items and set Value
    app.dropdownFocus.Items = [app.dropdownFocus.Items, [nNewValue{1},'s']];
    app.dropdownFocus.Items = unique(app.dropdownFocus.Items);
    app.dropdownFocus.Value = [nNewValue{1},'s'];
end
focus_seconds = regexp(app.dropdownFocus.Value,'([\d*.])*','match');
focus_seconds = str2double(focus_seconds{1});

% Still working with handles (one day I'll finish transitioning out of it)
[hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event);
handles.data.settings.focus_window_size = focus_seconds;
handles.data.saveSettings();

if ~isempty(handles.data.audiodata)
    update_fig(hObject, handles);
else
    guidata(hObject, handles);
end
