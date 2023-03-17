% --- Executes on selection change in popupmenuColorMap.
function ChangeColorMap(~, ~, handles)
    handles.data.cmapName = get(handles.popupmenuColorMap, 'String');
    handles.data.cmapName = handles.data.cmapName(get(handles.popupmenuColorMap, 'Value'));
    handles.data.cmap = feval(handles.data.cmapName{1, 1}, 256);
    colormap(handles.focusWindow, handles.data.cmap);
    colormap(handles.spectrogramWindow, handles.data.cmap);
end
