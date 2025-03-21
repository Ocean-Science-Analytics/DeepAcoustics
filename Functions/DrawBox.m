function DrawBox(hObject, ~, handles, app)
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
new_box.Type = categorical({app.textDrawType.Text});
new_box.Audiodata = handles.data.audiodata;
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
% Check for Date/Time??
new_box.StTime = NaT;
new_box = AddDateTime(new_box,handles.data.audiodata);
if any(contains(handles.data.calls.Properties.VariableNames,'BoxAdj'))
    new_box.BoxAdj = new_box.Box;
end
handles.data.calls = [handles.data.calls; new_box];

%Now delete the roi and render the figure. The roi will be rendered along
%with the existing boxes.

% Sort calls and reset current call (new call is at end of table, thus
% using height of calls to index SortCalls)
[handles.data.calls,handles.data.currentcall] = SortCalls(handles.data.calls,'time',height(handles.data.calls));
% Get beginning and end rows for the current audio file
handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'first');
handles.data.thisaudend = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'last');
% Move focus to new current call
handles.data.focusCenter = handles.data.calls.Box(handles.data.currentcall,1) + handles.data.calls.Box(handles.data.currentcall,3)/2;
% Update figure
update_fig(hObject, handles);

delete(current_box)