function SaveSession(hObject, eventdata, handles, bAuto)

if nargin < 4
    bAuto = false;
end

if isfield(handles,'current_detection_file')
    handles.SaveFile = handles.detectionfiles(handles.current_file_id).name;
    handles.SaveFile = handles.current_detection_file;
else
    uniqAudio = unique(handles.data.calls.Audiodata,'stable');
    handles.SaveFile = [uniqAudio(1).Filename '_' num2str(length(uniqAudio)) '_Detections.mat'];
end

guidata(hObject, handles);

Calls = handles.data.calls;
if bAuto
    FileName = handles.SaveFile;
    PathName = handles.data.settings.detectionfolder;
else
    [FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, handles.SaveFile), 'Save Session (.mat)');
end
if FileName == 0
    return
end
h = waitbar(0.5, 'saving');

spect = handles.data.settings.spect;
save(fullfile(PathName, FileName), 'Calls','spect', '-v7.3');
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
close(h);
