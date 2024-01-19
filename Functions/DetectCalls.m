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
networkselection = listdlg('PromptString','Select a Network:','ListSize',[500 300],'SelectionMode','single','ListString',handles.networkfilesnames);
if isempty(networkselection)
    return
end

% Set detection settings
prompt = {'Total Analysis Length (Seconds; 0 = Full Duration)','Low Frequency Cutoff (kHZ)','High Frequency Cutoff (kHZ)','Score Threshold (0-1)','Append Date to FileName (1 = yes)'};
dlg_title = ['Settings for ' handles.networkfiles(networkselection).name];
num_lines=[1 length(dlg_title)+30]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
def = handles.data.settings.detectionSettings;
Settings = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));

if isempty(Settings) % Stop if user presses cancel
    return
end

handles.data.settings.detectionSettings = sprintfc('%g',Settings(:,1))';

% Save the new settings
handles.data.saveSettings();

update_folders(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles

detectiontime=datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
Calls = [];
%% For Each File
for j = 1:length(audioselections)
    CurrentAudioFile = audioselections(j);

    h = waitbar(0,'Loading neural network...');
    networkname = handles.networkfiles(networkselection).name;
    networkpath = fullfile(handles.networkfiles(networkselection).folder,networkname);
    NeuralNetwork=load(networkpath);%get currently selected option from menu
    close(h);
    
    AudioFile = fullfile(handles.audiofiles(CurrentAudioFile).folder,handles.audiofiles(CurrentAudioFile).name);
    Calls_ThisAudio = SqueakDetect(AudioFile,NeuralNetwork,Settings,j,length(audioselections));
    
    [~,audioname] = fileparts(AudioFile);
    
    if isempty(Calls_ThisAudio)
        fprintf(1,'No Calls found in: %s \n',audioname)
        continue
    end
    
    h = waitbar(1,'Saving...');
    
    Calls_ThisAudio.EntThresh(:) = handles.data.settings.EntropyThreshold;
    Calls_ThisAudio.AmpThresh(:) = handles.data.settings.AmplitudeThreshold;

    DetSpect.wind = NeuralNetwork.wind;
    DetSpect.noverlap = NeuralNetwork.noverlap;
    DetSpect.nfft = NeuralNetwork.nfft;
    Calls_ThisAudio.DetSpect = repmat(DetSpect,height(Calls_ThisAudio),1);
    Calls_ThisAudio.Audiodata = repmat(audioinfo(AudioFile),height(Calls_ThisAudio),1);
    
    %% Save the file
    % Save the Call table, detection metadata, and results of audioinfo
    
    % Append date to filename
    if j==1
        if Settings(5)
            fname = fullfile(handles.data.settings.detectionfolder,[audioname '_' num2str(length(audioselections)) 'AudFiles ' detectiontime '_Detections.mat']);
        else
            fname = fullfile(handles.data.settings.detectionfolder,[audioname '_' num2str(length(audioselections)) 'AudFiles_Detections.mat']);
        end
    end
    
    % Display the number of calls
    fprintf(1,'%d Calls found in: %s \n',height(Calls_ThisAudio),audioname)
    
    if ~isempty(Calls_ThisAudio)
        Calls = [Calls; Calls_ThisAudio];
    end
    delete(h)
end

if ~isempty(Calls)
    detection_metadata = struct(...
        'Settings', Settings,...
        'detectiontime', detectiontime,...
        'networkselection', {handles.networkfiles(networkselection).name});
    %audiodata = audioinfo(AudioFile);
    spect = handles.data.settings.spect;
    save(fname,'Calls','detection_metadata','spect','-v7.3','-mat');
end
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
