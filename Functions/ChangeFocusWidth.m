function ChangeFocusWidth(app, event)
if strcmp(app.dropdownFocus.Value,'Custom')
    % Make dialog
    prompt = {'Enter desired width of focus window (in seconds):'};
    dlgtitle = 'Adjust Focus Width';
    dims = [1 20];
    definput = {'5'};
    nNewValue = inputdlg(prompt,dlgtitle,dims,definput);
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
    update_fig(hObject, eventdata, handles);
else
    guidata(hObject, handles);
end
