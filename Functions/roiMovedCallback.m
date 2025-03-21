function  roiMovedCallback(rectangle,evt)
% This runs when a box's rectangle is resized or moved
hObject = get(rectangle,'Parent');
handles = guidata(hObject);
tag = str2double(get(rectangle,'Tag'));
handles.data.calls{tag,'Box'} = rectangle.Position;
% Adjust focus
handles.data.focusCenter = handles.data.calls.Box(tag,1) + handles.data.calls.Box(tag,3)/2;
% Update figure
update_fig(hObject, handles);
end

