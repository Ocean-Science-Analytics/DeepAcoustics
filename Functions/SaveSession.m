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

% Only need allAudio and detmetadata if creating new detections file
allAudio = handles.data.allAudio;
if ~isempty(handles.data.detmetadata)
    detection_metadata = handles.data.detmetadata;
else
    detectiontime = datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
    detection_metadata = struct(...
        'Settings', 'N/A or not available',...
        'detectiontime', detectiontime,...
        'networkselections', 'N/A or not available');
end

spect = handles.data.settings.spect;

h = waitbar(0.5, 'saving');

szCalls = whos('Calls');
szallAudio = whos('allAudio');
szdetmd = whos('detection_metadata');
szspect = whos('spect');
szTotal = szCalls.bytes + szspect.bytes + szdetmd.bytes + szallAudio.bytes;
if szTotal >= 2000000000
    if exist(fullfile(PathName, FileName),'file')
        save(fullfile(PathName, FileName), 'Calls','spect', '-v7.3','-append');
    else
        save(fullfile(PathName, FileName), 'Calls','allAudio','detection_metadata','spect', '-v7.3');
    end
else
    if exist(fullfile(PathName, FileName),'file')
        save(fullfile(PathName, FileName), 'Calls','spect', '-v7','-append');
    else
        save(fullfile(PathName, FileName), 'Calls','allAudio','detection_metadata','spect','-v7','-mat');
    end
end
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
close(h);
