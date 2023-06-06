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

NeuralNetworks = cell(1,length(networkselections));
h = waitbar(0,'Loading neural network(s)...');
Settings = [];
for k=1:length(networkselections)
    % Load all networks first so that checks don't have to happen for every
    % audio file
    networkname = handles.networkfiles(networkselections(k)).name;
    networkpath = fullfile(handles.networkfiles(networkselections(k)).folder,networkname);
    networkfile=load(networkpath);%get currently selected option from menu

    % Get network and spectrogram settings
    dlg_title = ['Settings for ' networkname];
    num_lines=[1 100]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
    def = handles.data.settings.detectionSettings;
    if isfield(networkfile,'Settings_Freq')
        %netFreqSettings = networkfile.Settings_Freq;
        %wind = networkfile.Settings_Spec.wind;
        %noverlap = networkfile.Settings_Spec.noverlap;
        %nfft = networkfile.Settings_Spec.nfft;
        %imLength = networkfile.Settings_Spec.imLength;
        % Settings for each network
        prompt = {'Total Analysis Length (Seconds; 0 = Full Duration)','Score Threshold (0-1)','Append Date to FileName (1 = yes)'};
        def = def([1,4:5]);
        current_settings = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));
        
        if isempty(current_settings) % Stop if user presses cancel
            return
        end
        current_settings(4:5) = current_settings(2:3);
        current_settings(2:3) = networkfile.Settings_Freq;
    else
        thisnet = networkfile;
        networkfile = struct();
        networkfile.Settings_Freq = [0,0];
        warningmsg = questdlg({'This is an older network.  If you did not use the full frequency spectrum','to create your training images, network may not work as expected'}, ...
            'Warning','Continue anyway','Cancel','Cancel');
        waitfor(warningmsg)
        if ~strcmp(warningmsg,'Continue anyway')
            return
        end
        networkfile.Settings_Spec = cell2table(cell(0,4),'VariableNames',{'wind','noverlap','nfft','imLength'});
        networkfile.Settings_Spec = [thisnet.wind, thisnet.noverlap, thisnet.nfft, thisnet.imLength];
        networkfile.detector = thisnet.detector;
        % Settings for each network
        prompt = {'Total Analysis Length (Seconds; 0 = Full Duration)','Low Frequency Cutoff (kHZ)','High Frequency Cutoff (kHZ)','Score Threshold (0-1)','Append Date to FileName (1 = yes)'};
        current_settings = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));
        
        if isempty(current_settings) % Stop if user presses cancel
            return
        end
    end
    NeuralNetworks{k} = networkfile;
    
    Settings = [Settings, current_settings];
    handles.data.settings.detectionSettings = sprintfc('%g',Settings(:,1))';
end
close(h);

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
    AudioFile = fullfile(handles.audiofiles(CurrentAudioFile).folder,handles.audiofiles(CurrentAudioFile).name);
    % For Each Network
    Calls = [];
    for k=1:length(networkselections)
        Calls = [Calls; SqueakDetect(AudioFile,NeuralNetworks{k},Settings(:,k),j,length(audioselections))];
    end
    
    [~,audioname] = fileparts(AudioFile);
    detectiontime=datestr(datetime('now'),'yyyy-mm-dd HH_MM PM');
    
    if isempty(Calls)
        fprintf(1,'No Calls found in: %s \n',audioname)
        continue
    end
    
    h = waitbar(1,'Saving...');

    %% Merge overlapping boxes
    Calls = merge_boxes(Calls.Box, Calls.Score, Calls.Type, audioinfo(AudioFile), 1, 0, 0);
    
    Calls.EntThresh(:) = handles.data.settings.EntropyThreshold;
    Calls.AmpThresh(:) = handles.data.settings.AmplitudeThreshold;
    
    %% Save the file
    % Save the Call table, detection metadata, and results of audioinfo
    
    % Append date to filename
    if Settings(5)
        fname = fullfile(handles.data.settings.detectionfolder,[audioname ' ' detectiontime '_Detections.mat']);
    else
        fname = fullfile(handles.data.settings.detectionfolder,[audioname '_Detections.mat']);
    end
    
    % Display the number of calls
    fprintf(1,'%d Calls found in: %s \n',height(Calls),audioname)
    
    if ~isempty(Calls)
        detection_metadata = struct(...
            'Settings', Settings,...
            'detectiontime', detectiontime,...
            'networkselections', {handles.networkfiles(networkselections).name});
        audiodata = audioinfo(AudioFile);
        save(fname,'Calls', 'detection_metadata', 'audiodata' ,'-v7.3', '-mat');
    end
    
    delete(h)
end
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);
