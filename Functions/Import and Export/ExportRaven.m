function ExportRaven(hObject, eventdata, handles)
    % Export current file as a txt file for viewing in Raven
    % http://www.birds.cornell.edu/brp/raven/RavenOverview.html
    raventable = [{'Selection'} {'View'} {'Channel'} {'Begin Time (s)'} {'End Time (s)'} {'Low Freq (Hz)'} {'High Freq (Hz)'} {'Delta Time (s)'} {'Delta Freq (Hz)'} {'Avg Power Density (dB FS)'} {'Annotation'} {'Begin Path'} {'File Offset'}];
    View = 'Spectrogram 1';
    Channel = 1;
    for i = 1:height(handles.data.calls)
        if handles.data.calls.Accept(i)
            Selection = i;
            BeginTime = handles.data.calls.Box(i, 1);
            EndTime = sum(handles.data.calls.Box(i ,[1, 3]));
            LowFreq = handles.data.calls.Box(i, 2) * 1000;
            HighFreq = sum(handles.data.calls.Box(i, [2, 4])) * 1000;
            DeltaTime = EndTime - BeginTime;
            DeltaFreq = HighFreq - LowFreq;
            AvgPwr = 1;
            Annotation = char(handles.data.calls.Type(i));
            BeginPath = handles.data.calls.Audiodata(i).Filename;
            FileOffset = handles.data.calls.Box(i, 1);
            raventable = [raventable; {Selection} {View} {Channel} {BeginTime} {EndTime} {LowFreq} {HighFreq} {DeltaTime} {DeltaFreq} {AvgPwr} {Annotation} {BeginPath} {FileOffset}];
        end
    end
    a  = cell2table(raventable);
    ravenname=[strtok(handles.detectionfiles(handles.current_file_id).name,'.') '_Raven.txt'];
    [FileName,PathName] = uiputfile(ravenname,'Save Raven Truth Table (.txt)');
    writetable(a,[PathName FileName],'delimiter','\t','WriteVariableNames',false);
    guidata(hObject, handles);
end