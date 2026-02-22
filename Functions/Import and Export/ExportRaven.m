function ExportRaven(hObject, eventdata, handles)
    expCalls = handles.data.calls;
    % Export current file as a txt file for viewing in Raven
    % http://www.birds.cornell.edu/brp/raven/RavenOverview.html
    raventable = [{'Selection'} {'View'} {'Channel'} {'Begin Time (s)'} {'End Time (s)'} {'Low Freq (Hz)'} {'High Freq (Hz)'} {'Delta Time (s)'} {'Delta Freq (Hz)'} {'Avg Power Density (dB FS)'} {'Annotation'} {'Begin Path'} {'Begin File'} {'File Offset'}];
    View = 'Spectrogram 1';
    Channel = 1;
    RavenTableType = questdlg('Do you want to save as Sound Selection Table or Selection Table? (If you do not understand the difference, try both and see which one works the way you expect. Note that a opening a Sound Selection Table in Raven will not load audio files with no detections.)','Selection Table Type',...
        'Sound Selection Table','Selection Table','Sound Selection Table');
    if isempty(RavenTableType); return; end
    switch RavenTableType % Load Model
        case 'Sound Selection Table'
            bSST = true;
        case 'Selection Table'
            bSST = false;
            [expCalls] = CreateBoxAdj(expCalls, handles.data.allAudio);
    end
    for i = 1:height(expCalls)
        if expCalls.Accept(i)
            Selection = i;
            if bSST
                BeginTime = expCalls.Box(i, 1);
                EndTime = sum(expCalls.Box(i ,[1, 3]));
            else
                BeginTime = expCalls.BoxAdj(i, 1);
                EndTime = sum(expCalls.BoxAdj(i ,[1, 3]));
            end
            LowFreq = expCalls.Box(i, 2) * 1000;
            HighFreq = sum(expCalls.Box(i, [2, 4])) * 1000;
            DeltaTime = EndTime - BeginTime;
            DeltaFreq = HighFreq - LowFreq;
            AvgPwr = 1;
            Annotation = char(expCalls.Type(i));
            BeginPath = expCalls.Audiodata(i).Filename;
            [~,thisfile,ext] = fileparts(BeginPath);
            BeginFile = [thisfile ext];
            FileOffset = expCalls.Box(i, 1);
            raventable = [raventable; {Selection} {View} {Channel} {BeginTime} {EndTime} {LowFreq} {HighFreq} {DeltaTime} {DeltaFreq} {AvgPwr} {Annotation} {BeginPath} {BeginFile} {FileOffset}];
        end
    end
    a  = cell2table(raventable);
    ravenname=[strtok(handles.detectionfiles(handles.current_file_id).name,'.') '_Raven.txt'];
    [FileName,PathName] = uiputfile(ravenname,'Save Raven Truth Table (.txt)');
    writetable(a,[PathName FileName],'delimiter','\t','WriteVariableNames',false);
    guidata(hObject, handles);
end