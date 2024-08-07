% --- Executes on button press in multinetdect.
function DetectCalls(hObject, eventdata, handles)

if isempty(handles.audiofiles)
    errordlg('No Audio Selected')
    return
end
if isempty(handles.networkfiles)
    errordlg('No Network Selected')
    return
end

% Check if pre-existing detection file has changed to save file before loading a new one.
CheckModified(hObject, eventdata, handles);

%if exist(handles.data.settings.detectionfolder,'dir')==0
    % Find audio in folder
    path=uigetdir(handles.data.settings.detectionfolder,'Select Output Detection File Folder');
    if isnumeric(path);return;end
    handles.data.settings.detectionfolder = path;
    handles.data.saveSettings();
    update_folders(hObject, eventdata, handles);
    handles = guidata(hObject);  % Get newest version of handles
%end

audioselections = listdlg('PromptString','Select Audio Files:','ListSize',[500 300],'ListString',handles.audiofilesnames);
if isempty(audioselections)
    return
end
networkselections = listdlg('PromptString','Select Networks:','ListSize',[500 300],'ListString',handles.networkfilesnames);
if isempty(audioselections)
    return
end

Settings = [];
for k=1:length(networkselections)
    prompt = {'Total Analysis Length (Seconds; 0 = Full Duration)','Low Frequency Cutoff (Hz)','High Frequency Cutoff (Hz)','Score Threshold (0-1)','Append Date to FileName (1 = yes)'};
    dlg_title = ['Settings for ' handles.networkfiles(networkselections(k)).name];
    num_lines = [1 length(dlg_title)+30]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
    def = handles.data.settings.detectionSettings;
    % Convert freq to Hz for display
    def(2) = sprintfc('%g',str2double(def{2})*1000);
    def(3) = sprintfc('%g',str2double(def{3})*1000);
    current_settings = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));
    
    if isempty(current_settings) % Stop if user presses cancel
        return
    end

    % Convert freq inputs to kHz
    current_settings(2:3) = current_settings(2:3)/1000;
    
    Settings = [Settings, current_settings];
    handles.data.settings.detectionSettings = sprintfc('%g',Settings(:,1))';
end

if isempty(Settings)
    return
end

% Save the new settings
handles.data.saveSettings();

update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles

%% For Each File
for j = 1:length(audioselections)
    CurrentAudioFile = audioselections(j);
    % For Each Network
    Calls = [];
    allAudio = [];
    for k=1:length(networkselections)
        h = waitbar(0,'Loading neural network...');
        
        AudioFile = fullfile(handles.audiofiles(CurrentAudioFile).folder,handles.audiofiles(CurrentAudioFile).name);
        
        networkname = handles.networkfiles(networkselections(k)).name;
        networkpath = fullfile(handles.networkfiles(networkselections(k)).folder,networkname);
        NeuralNetwork=load(networkpath);%get currently selected option from menu
        close(h);
        
        Calls = [Calls; SqueakDetect(AudioFile,NeuralNetwork,Settings(:,k),j,length(audioselections))];

    end
    
    [~,audioname] = fileparts(AudioFile);
    detectiontime=datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
    
    % Set file name
    if j==1
        if Settings(5)
            fname = fullfile(handles.data.settings.detectionfolder,[audioname '_' num2str(length(audioselections)) 'AudFiles ' detectiontime '_Detections.mat']);
        else
            fname = fullfile(handles.data.settings.detectionfolder,[audioname '_' num2str(length(audioselections)) 'AudFiles_Detections.mat']);
        end
    end
    
    % Move to next audio if no calls
    if isempty(Calls)
        fprintf(1,'No Calls found in: %s \n',audioname)
        continue
    end
    
    h = waitbar(1,'Saving...');

    %% Merge overlapping boxes
    Calls = merge_boxes(Calls.Box, Calls.Score, Calls.Type, audioinfo(AudioFile), 1, 0, 0);
    
    % Correct power measure for merged calls
    % This should also now be consistent with the calculation in
    % CalculateStats
%     audioReader = squeakData([]);
%     audioReader.audiodata = audioinfo(AudioFile);
%     for i = 1:height(Calls) % Do this for each call
%         % Get spectrogram data
%         [I,windowsize,noverlap,nfft,rate,box] = CreateFocusSpectrogram(Calls(i, :),handles,true, [], audioReader);
%         stats = CalculateStats(I,windowsize,noverlap,nfft,rate,box,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);
% 
%         % Mean power of the call contour (mean needs to be before log)
%         Calls.Power(i) = stats.MeanPower;
%     end
    Calls.EntThresh(:) = handles.data.settings.EntropyThreshold;
    Calls.AmpThresh(:) = handles.data.settings.AmplitudeThreshold;
    
    % Display the number of calls
    fprintf(1,'%d Calls found in: %s \n',height(Calls),audioname)
    
    if ~isempty(Calls)
        detection_metadata = struct(...
            'Settings', Settings,...
            'detectiontime', detectiontime,...
            'networkselections', {handles.networkfiles(networkselections).name});
        audiodata = audioinfo(AudioFile);
        spect = handles.data.settings.spect;    
        allAudio = [allAudio; audioinfo(AudioFile)];
        save(fname,'Calls','allAudio','detection_metadata','spect','-v7.3','-mat');
    end
    
    delete(h)
end
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
