% --- Executes on button press in LOAD CALLS.
function LoadCalls(hObject, eventdata, handles, indSt, ~)
update_folders(hObject, eventdata, handles);
handles = guidata(hObject);
if nargin == 3
    indSt = 1;
end
if nargin < 5 % if "Load Calls" button pressed, load the selected file, else reload the current file
    %Check if pre-existing detection file has changed to save file before loading a new one.
    if ~isempty(handles.data.calls) && ~isempty(handles.current_file_id)
        [~, ~, ~, ~, modcheck] = loadCallfile(fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.current_detection_file), handles,false);
        if ~isequal(modcheck.calls, handles.data.calls) || ~isequal(modcheck.spect, handles.data.settings.spect)
            opts.Interpreter = 'tex';
            opts.Default='Yes';
            if ~isequal(modcheck.calls, handles.data.calls) 
                saveChanges = questdlg('\color{red}\bf WARNING! \color{black} Detection file has been modified. Would you like to save changes?','Save Detection File?','Yes','No',opts);
            elseif ~isequal(modcheck.spect, handles.data.settings.spect)
                saveChanges = questdlg('\color{red}\bf WARNING! \color{black} Spectrogram settings have been modified. Would you like to save changes in the det file (spect variable)?','Save Detection File?','Yes','No',opts);
            end
            switch saveChanges
                case 'Yes'
                    SaveSession(hObject, eventdata, handles);
                case 'No'
            end
        end
    end
    
    % Select new detections file
    [newdetfile,newdetpath] = uigetfile('*.mat','Select detections.mat file',handles.data.settings.detectionfolder);
    % If cancel, return
    if isequal(newdetfile,0)
       return;
    % Else get ready to load new file
    else
        % Update detection file info
        matsindir = dir([newdetpath '/*.mat*']);
        matsindir = {matsindir.name};
        handles.current_file_id = find(strcmp(newdetfile,matsindir));
        handles.current_detection_file = newdetfile;
        % Update Settings
        handles.data.settings.detectionfolder = newdetpath;
        handles.data.saveSettings();
        update_folders(hObject, eventdata, handles);
        handles = guidata(hObject);  % Get newest version of handles
    end
end

h = waitbar(0,'Loading Calls Please wait...');
% Whenever load new file, reset bAnnotate to false
handles.data.bAnnotate = false;
[handles.data.calls, handles.data.settings.spect, detmetadata] = loadCallfile(fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.current_detection_file), handles,false);

% Make sure audio still exists in linked locations
uniqAud = unique({handles.data.calls.Audiodata.Filename},'stable');
newpn = '';
for i = 1:length(uniqAud)
    % Get current file parts
    [~, thisfn, thisext] = fileparts(uniqAud{i});
    % Does the audio file exist in the current set location?
    bExist = exist(uniqAud{i},'file');
    % If not...
    if ~bExist
        % ...and we recently set a new file path, check that path for this
        % audio file
        if ~strcmp(newpn,'')
            bExist = exist(fullfile(newpn,[thisfn thisext]),'file');
        end
        % If we're still not finding the audio file, ask user to supply new
        % path
        if ~bExist
            newpn = uigetdir(handles.data.settings.audiofolder,['Select folder containing ',thisfn]);
            % Double-check that they chose a good path
            if ~exist(fullfile(newpn,[thisfn thisext]),'file')
                error([thisfn ' not found in ' newpn])
            end
        end
        % Replace old path with new, good path
        indrep = find(strcmp({handles.data.calls.Audiodata.Filename},uniqAud{i}));
        for j = indrep
            handles.data.calls.Audiodata(j).Filename = fullfile(newpn,[thisfn thisext]);
        end
    end
end

if nargin < 5
    indSt = 1;
    % Get names of audio files contributing to this detection file
    allAudio = unique({handles.data.calls.Audiodata.Filename},'stable');
    if length(allAudio) > 1
        audioselection = listdlg('PromptString','Select which Audio to Load :','ListSize',[500 300],'SelectionMode','single','ListString',allAudio);
        indSt = find(strcmp({handles.data.calls.Audiodata.Filename},allAudio{audioselection}),1,'first');
    end
end
% Get audio info for the correct audio file
% indSt == 0 => We want the previous audio file
if indSt == 0
    handles.data.audiodata = handles.data.calls.Audiodata(handles.data.thisaudst-1);
    handles.data.thisaudst = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'first');
else
    handles.data.audiodata = handles.data.calls.Audiodata(indSt);
    handles.data.thisaudst = indSt;
end
handles.data.thisaudend = find(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),1,'last');
if ~isempty(detmetadata)
    handles.data.settings.detectionSettings = sprintfc('%g',detmetadata.Settings)';
end

% Position of the focus window to the first call in the file
handles.data.focusCenter = handles.data.calls.Box(1,1) + handles.data.calls.Box(1,3)/2;

% For some unknown reason, if "h" is closed after running
% "initialize_display", then holding down an arror key will be a little
% slower. See update_fig.m for details
close(h);
initialize_display(hObject, eventdata, handles);
