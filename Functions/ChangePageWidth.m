function  ChangePageWidth(app, event)
if strcmp(app.dropdownPage.Value,'Custom')
    % Make dialog
    prompt = {'Enter desired width of page window (in seconds):'};
    dlgtitle = 'Adjust Page Width';
    dims = [1 20];
    definput = {'30'};
    nNewValue = inputdlg(prompt,dlgtitle,dims,definput);
    % Add custom value to Items and set Value
    app.dropdownPage.Items = [app.dropdownPage.Items, [nNewValue{1},'s']];
    app.dropdownPage.Items = unique(app.dropdownPage.Items);
    app.dropdownPage.Value = [nNewValue{1},'s'];
end
page_seconds = regexp(app.dropdownPage.Value,'([\d*.])*','match');
page_seconds = str2double(page_seconds{1});

% Still working with handles (one day I'll finish transitioning out of it)
[hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event);
handles.data.settings.pageSize = page_seconds;
handles.data.saveSettings();

if ~isempty(handles.data.audiodata)
    update_fig(hObject, eventdata, handles, true);
else
    guidata(hObject, handles);
end
