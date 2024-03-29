function SaveSession(hObject, eventdata, handles, bAuto)

if nargin < 4
    bAuto = false;
end

if isfield(handles,'current_detection_file') && ~isempty(handles.current_detection_file)
    handles.SaveFile = fullfile(handles.data.settings.detectionfolder,handles.current_detection_file);
else
    uniqAudio = unique({handles.data.calls.Audiodata.Filename},'stable');
    % Get current file parts
    [thispn, thisfn, ~] = fileparts(uniqAudio{1});
    handles.SaveFile = fullfile(thispn, [thisfn '_' num2str(length(uniqAudio)) '_Detections.mat']);
end

guidata(hObject, handles);

Calls = handles.data.calls;
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

szCalls = whos('Calls');
szspect = whos('spect');
szTotal = szCalls.bytes + szspect.bytes;
if szTotal >= 2000000000
    save(fullfile(PathName, FileName), 'Calls','spect', '-v7.3');
else
    save(fullfile(PathName, FileName), 'Calls','spect', '-v7');
end
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
close(h);
