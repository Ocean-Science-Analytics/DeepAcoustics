% --- Method for detecting all calls in (an) audio file(s)
function DetectCalls(hObject, eventdata, handles)

if nargin < 4
    bRT = false;
end

if ~bRT
    if isempty(handles.audiofiles)
        errordlg('No Audio Selected')
        return
    end
    
    % Check if pre-existing detection file has changed to save file before loading a new one.
    CheckModified(hObject, eventdata, handles);

    audioselections = listdlg('PromptString','Select Audio Files:','ListSize',[500 300],'ListString',handles.audiofilesnames);
    if isempty(audioselections)
        return
    end
end

NeuralNetwork = DetectSetup(hObject, eventdata, handles, bRT);
handles = guidata(hObject);  % Get newest version of handles

Settings = str2double(handles.data.settings.detectionSettings);

detectiontime=datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
Calls = [];
allAudio = [];

% Set DetSpect from network files
DetSpect.wind = NeuralNetwork.wind;
DetSpect.noverlap = NeuralNetwork.noverlap;
DetSpect.nfft = NeuralNetwork.nfft;

%% For Each File
for j = 1:length(audioselections)
    CurrentAudioFile = audioselections(j);

    AudioFile = fullfile(handles.audiofiles(CurrentAudioFile).folder,handles.audiofiles(CurrentAudioFile).name);
    Calls_ThisAudio = DetectInFile(AudioFile,NeuralNetwork,Settings,j,length(audioselections));
    
    [~,audioname] = fileparts(AudioFile);

    % Set file name
    if j==1
        if Settings(5)
            fname = fullfile(handles.data.settings.detectionfolder,[audioname '_' num2str(length(audioselections)) 'AudFiles ' detectiontime '_Detections.mat']);
        else
            fname = fullfile(handles.data.settings.detectionfolder,[audioname '_' num2str(length(audioselections)) 'AudFiles_Detections.mat']);
        end
    end
    
    % Move to next audio if no calls
    if isempty(Calls_ThisAudio)
        fprintf(1,'No Calls found in: %s \n',audioname)
        continue
    end
    
    h = waitbar(1,'Saving...');
    
    Calls_ThisAudio.EntThresh(:) = handles.data.settings.EntropyThreshold;
    Calls_ThisAudio.AmpThresh(:) = handles.data.settings.AmplitudeThreshold;
    Calls_ThisAudio.DetSpect = repmat(DetSpect,height(Calls_ThisAudio),1);
    Calls_ThisAudio.Audiodata = repmat(audioinfo(AudioFile),height(Calls_ThisAudio),1);
    
    % Display the number of calls
    fprintf(1,'%d Calls found in: %s \n',height(Calls_ThisAudio),audioname)
    
    if ~isempty(Calls_ThisAudio)
        Calls = [Calls; Calls_ThisAudio];
    end
    allAudio = [allAudio; audioinfo(AudioFile)];
    delete(h)
end

if ~isempty(Calls)
    detection_metadata = struct(...
        'Settings', Settings,...
        'detectiontime', detectiontime,...
        'networkselection', {handles.networkfiles(networkselection).name});
    %audiodata = audioinfo(AudioFile);
    spect = handles.data.settings.spect;
    save(fname,'Calls','allAudio','detection_metadata','spect','-v7.3','-mat');
end
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
