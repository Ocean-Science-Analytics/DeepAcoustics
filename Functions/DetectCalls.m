% --- Method for detecting all calls in (an) audio file(s)
function DetectCalls(app,event)

[hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); 

% Check if pre-existing detection file has changed to save file before loading a new one.
CheckModified(hObject, eventdata, handles);

[audfiles,audpn] = uigetfile({'*.wav;*.ogg;*.flac;*.UVD;*.au;*.aiff;*.aif;*.mp3;*.m4a;*.mp4',...
    'Audio Files (*.wav,*.ogg,*.flac,*.UVD,*.au,*.aiff,*.aif,*.mp3,*.m4a,*.mp4)'},...
    'Select Audio Files',handles.data.settings.audiofolder,'MultiSelect','on');

NeuralNetwork = DetectSetup(hObject, eventdata, handles);
handles = guidata(hObject);  % Get newest version of handles

Settings = str2double(handles.data.settings.detectionSettings);

detectiontime=datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
Calls = [];
allAudio = [];

% Set DetSpect from network files
DetSpect.wind = NeuralNetwork.wind;
DetSpect.noverlap = NeuralNetwork.noverlap;
DetSpect.nfft = NeuralNetwork.nfft;

if ~iscell(audfiles)
    audfiles = {audfiles};
end
%% For Each File
for j = 1:length(audfiles)
    AudioFile = fullfile(audpn,audfiles{j});
    Calls_ThisAudio = DetectInFile(AudioFile,NeuralNetwork,Settings,j,length(audfiles));
    
    [~,audioname] = fileparts(AudioFile);

    % Set file name
    if j==1
        if Settings(5)
            fname = fullfile(handles.data.settings.detectionfolder,[audioname '_' num2str(length(audfiles)) 'AudFiles ' detectiontime '_Detections.mat']);
        else
            fname = fullfile(handles.data.settings.detectionfolder,[audioname '_' num2str(length(audfiles)) 'AudFiles_Detections.mat']);
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
        'networkselection', {NeuralNetwork.netfile});
    spect = handles.data.settings.spect;
    save(fname,'Calls','allAudio','detection_metadata','spect','-v7.3','-mat');
end
update_folders(hObject,handles);
