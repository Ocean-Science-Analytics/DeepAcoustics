function SaveSession(hObject, eventdata, handles, bAuto)

if nargin < 4
    bAuto = false;
end

if isfield(handles,'current_detection_file') && ~isempty(handles.current_detection_file)
    handles.SaveFile = fullfile(handles.data.settings.detectionfolder,handles.current_detection_file);
else
    % Get current file parts
    [thispn, thisfn, ~] = fileparts(handles.data.audiodata.Filename);
    handles.SaveFile = fullfile(thispn, [thisfn '_Detections.mat']);
end

% temp = handles.data.audiodata.samples;
% handles.data.audiodata.samples = [];
guidata(hObject, handles);

Calls = handles.data.calls;
audiodata = handles.data.audiodata;
if bAuto
    [PathName, FileName, thisext] = fileparts(handles.SaveFile);
    FileName = [FileName thisext];
else
    [FileName, PathName] = uiputfile(handles.SaveFile, 'Save Session (.mat)');
end
if FileName == 0
    return
end
h = waitbar(0.5, 'saving');

spect = handles.data.settings.spect;
save(fullfile(PathName, FileName), 'Calls','audiodata','spect', '-v7.3');
% handles.data.audiodata.samples = temp;
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
close(h);
