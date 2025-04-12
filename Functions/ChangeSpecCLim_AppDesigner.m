function ChangeSpecCLim_AppDesigner(app,event)
clim_change = [0,0];
if ~isempty(event)
    switch event.Source.Tag
        case 'high_clim_plus'
            clim_change = [0, .1];
        case 'high_clim_minus'
            clim_change = [0, -.1];
        case 'low_clim_plus'
            clim_change = [.1, 0];
        case 'low_clim_minus'
            clim_change = [-.1, 0];
    end
end

app.DAdata.settings.spectrogramContrast = app.DAdata.settings.spectrogramContrast + range(app.DAdata.settings.spectrogramContrast) .* clim_change;

% Don't let the clim go below zero if using amplitude
if strcmp(app.DAdata.settings.spect.type, 'Amplitude')
    app.DAdata.settings.spectrogramContrast(1) = max(app.DAdata.settings.spectrogramContrast(1), -mean(app.DAdata.clim) ./ range(app.DAdata.clim));
end

clim = mean(app.DAdata.clim) + range(app.DAdata.clim) .* app.DAdata.settings.spectrogramContrast;
app.winPage.CLim = clim;
app.winFocus.CLim = clim;
% set(handles.spectrogramWindow,'Clim',clim)
% set(handles.focusWindow,'Clim',clim)
% guidata(hObject.Parent, handles);
