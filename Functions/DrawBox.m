function DrawBox(hObject, eventdata, handles)
current_box = drawrectangle( 'Parent',handles.focusWindow,...
                            'FaceAlpha',0,...
                            'LineWidth',1 );
% Don't do anything if the new box is empty
if current_box.Position(3) == 0 || current_box.Position(4) == 4
    delete(current_box)
    return
end
new_box = table();
new_box.Box = current_box.Position;
new_box.Score = 1;
new_box.Type = categorical({'Call'});
DetSpect.wind = 0;
DetSpect.noverlap = 0;
DetSpect.nfft = 0;
new_box.DetSpect = DetSpect;
new_box.CallID = categorical({'None'});
new_box.ClustCat = categorical({'None'});
new_box.EntThresh = handles.data.settings.EntropyThreshold;
new_box.AmpThresh = handles.data.settings.AmplitudeThreshold;
new_box.Accept = true;
new_box.Ovlp = 0;
new_box.StTime = 0;
handles.data.calls = [handles.data.calls; new_box];

%Now delete the roi and render the figure. The roi will be rendered along
%with the existing boxes.
handles.data.current_call_valid = true;
SortCalls(hObject, eventdata, handles, 'time', 0, -1);
delete(current_box)