function [Calls,allAudio,spect,detection_metadata,ClusteringData,modcheck] = loadCallfile(filename,handles,bTryDT)

modcheck = struct();
data = load(filename);

% Initialize variables so can re-save without using the "append" flag which
% makes file sizes blow up
if isfield(data, 'Calls')
    Calls = data.Calls;
else
    Calls = table();
end
if isfield(data, 'allAudio')
    allAudio = data.allAudio;
else
    allAudio = [];
end
if isfield(data, 'spect')
    spect = data.spect;
else
    spect = [];
end
if isfield(data,'detection_metadata')
    detection_metadata = data.detection_metadata;
else
    detection_metadata = [];
end
if isfield(data, 'audiodata')
    audiodata = data.audiodata;
else
    audiodata = struct();
end
if isfield(data, 'ClusteringData')
    ClusteringData = data.ClusteringData;
    if ~isempty(spect)
        handles.data.settings.spect = spect;
    else
        if ~isempty(handles)
            warning('Spect settings not previously saved; appending to detections.mat now.')
            spect = handles.data.settings.spect;
            save(filename,'spect','-append');
        end
    end
    
    if length(unique(ClusteringData.Type)) > 1
        list = cellstr(unique(ClusteringData.Type));
        [indx,tf] = listdlg('PromptString',{'Select the call types you would like to load.',...
            'WARNING: Saving after this point','without modifying the file name will','overwrite your existing detections file',...
            'with only the selected call types.',' ',' '},...
            'ListString',list,'ListSize',[200,300]);
        if tf
            ClusteringData = ClusteringData(ismember(ClusteringData.Type,list(indx)),:);
        else
            error('You chose to cancel')
        end
    end
else
    ClusteringData = table();
end

%% Unpack the data
if isfield(data, 'Calls')
    % Deal with potentially weird data type issues
    Calls.Box = double(Calls.Box);
    Calls.Score = double(Calls.Score);

    %% Supply defaults for any misc missing variables
    if ~any(strcmp('Audiodata', Calls.Properties.VariableNames)) && ~isempty(audiodata)
        Calls.Audiodata = repmat(audiodata,height(Calls),1);
    elseif ~any(strcmp('Audiodata', Calls.Properties.VariableNames))
        error('Could not identify audio info since multi-file update - complain to GA')
    end

    % Make sure audio exists in linked locations
    uniqAud = unique({Calls.Audiodata.Filename},'stable');
    if ~isempty(allAudio)
        % This should only come up if the wrong audio folder was assigned
        % to a detections file during an older version of DA
        if any(~ismember(uniqAud,unique({allAudio.Filename})))
            [~, Calls_fns, Calls_exts] = fileparts(uniqAud);
            Calls_fns = strcat(Calls_fns,Calls_exts);
            Calls_fns = sprintf('\n%s', Calls_fns{:});
            if nargout < 6
                warning(['Mismatch b/w previously saved audio folder and detections folder. You are about to be asked to correct this. The folder you select should contain at least:',Calls_fns])
            end
            allAudio = [];
        end
    end

    if isempty(allAudio)
        if nargout < 6
            bUpdate = questdlg('This is an older detections file that is lacking complete allAudio information - do you want to fix this now (recommended)?','Assign allAudio?','Yes','No','No');
            switch bUpdate
            case 'Yes'
                % Find audio in folder (default to directory of first call in
                % Calls)
                [audiopath,~,~] = fileparts(Calls.Audiodata(1).Filename);
                % If Calls directory doesn't exist, open preset audiofolder
                if exist(audiopath,'file') ~= 7
                    audiopath = handles.data.settings.audiofolder;
                end
                audiopath = uigetdir(audiopath,'Select Folder Containing All Audio Files Used to Generate This Detections File');
                % Update audio folder
                if ~strcmp(handles.data.settings.audiofolder,audiopath)
                    handles.data.settings.audiofolder = audiopath;
                    handles.data.saveSettings();
                    %update_folders(hObject, handles);
                end
                audiodir = [dir([audiopath '\*.wav']); ...
                    dir([audiopath '\*.ogg']); ...
                    dir([audiopath '\*.flac']); ...
                    dir([audiopath '\*.UVD']); ...
                    dir([audiopath '\*.au']); ...
                    dir([audiopath '\*.aiff']); ...
                    dir([audiopath '\*.aif']); ...
                    dir([audiopath '\*.aifc']); ...
                    dir([audiopath '\*.mp3']); ...
                    dir([audiopath '\*.m4a']); ...
                    dir([audiopath '\*.mp4'])];
    
                for i = 1:length(audiodir)
                    allAudio = [allAudio; audioinfo(fullfile(audiopath, audiodir(i).name))];
                end

                [~, Calls_fns, Calls_exts] = fileparts(uniqAud);
                [~, allAud_fns, ~] = fileparts(unique({allAudio.Filename}));
                if any(~ismember(Calls_fns,allAud_fns))
                    Calls_fns = strcat(Calls_fns,Calls_exts);
                    Calls_fns = sprintf('\n%s', Calls_fns{:});
                    warning(['Mismatch b/w selected audio folder and detections folder. Folder should contain:',Calls_fns])
                    allAudio = [];
                end
                %save(filename,'allAudio','-append');
                save(filename,'Calls','allAudio','detection_metadata','spect');

                % This should only come up if the wrong audio folder was assigned
                % to a detections file during an older version of DA
                % Make sure allAudio is reflected in Audiodata
                if any(~ismember(uniqAud,unique({allAudio.Filename})))
                    uniqAllAud = unique({allAudio.Filename});
                    for i = 1:length(uniqAud)
                        indrep = find(strcmp({Calls.Audiodata.Filename},uniqAud{i}));
                        [~,thisFN,~] = fileparts(uniqAud{i});
                        indAud = strcmp(thisFN,allAud_fns);
                        for j = 1:length(indrep)
                            Calls.Audiodata(indrep(j)).Filename = uniqAllAud{indAud};
                        end
                    end
                end
            case 'No'
                warning('This is an older detections file that is lacking complete allAudio information')
            end
        end
    end

    if ~isempty(allAudio)
        uniqAud = unique({allAudio.Filename});
    end

    [newpn,~,~] = fileparts(filename);
    if nargout < 6
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
                    if ~strcmp(handles.data.settings.audiofolder,newpn)
                        handles.data.settings.audiofolder = newpn;
                        handles.data.saveSettings();
                        %update_folders(hObject, handles);
                    end
                end
                % Replace old path with new, good path
                % Audiodata
                indrep = find(strcmp({Calls.Audiodata.Filename},uniqAud{i}));
                for j = 1:length(indrep)
                    Calls.Audiodata(indrep(j)).Filename = fullfile(newpn,[thisfn thisext]);
                end
                if ~isempty(allAudio)
                    % allAudio
                    indrep = find(strcmp({allAudio.Filename},uniqAud{i}));
                    for j = 1:length(indrep)
                        allAudio(indrep(j)).Filename = fullfile(newpn,[thisfn thisext]);
                    end
                end
            end
        end
    end

    if ~any(strcmp('DetSpect', Calls.Properties.VariableNames)) || ~isstruct(Calls.DetSpect) || isempty(fieldnames(Calls.DetSpect(1)))
        DetSpect.wind = 0;
        DetSpect.noverlap = 0;
        DetSpect.nfft = 0;
        Calls.DetSpect = repmat(DetSpect,height(Calls),1);
        Calls.DetSpect(:) = DetSpect;
    end
    if ~any(strcmp('CallID', Calls.Properties.VariableNames)) || length(unique(Calls.CallID)) ~= height(Calls)
        warning('CallID non-existent or not unique - replacing with 1:height(Calls)')
        Calls.CallID = categorical(1:height(Calls))';
    end
    if ~any(strcmp('ClustCat', Calls.Properties.VariableNames))
        clustcat = cell(1,height(Calls));
        clustcat(:) = {'None'};
        Calls.ClustCat = categorical(clustcat)';
    end
    if ~any(strcmp('EntThresh', Calls.Properties.VariableNames)) || all(Calls.EntThresh(:) == 0)
        Calls.EntThresh(:) = handles.data.settings.EntropyThreshold;
    end
    if ~any(strcmp('AmpThresh', Calls.Properties.VariableNames)) || all(Calls.AmpThresh(:) == 0)
        Calls.AmpThresh(:) = handles.data.settings.AmplitudeThreshold;
    end
    if ~any(strcmp('Accept', Calls.Properties.VariableNames))
        Calls.Accept(:) = 1;
    end
    if ~any(strcmp('Ovlp', Calls.Properties.VariableNames))
        Calls.Ovlp(:) = 0;
    end
    if ~any(strcmp('StTime', Calls.Properties.VariableNames)) || ~isa(Calls.StTime(1),'datetime') || (isequaln(Calls.StTime(1),NaT) && bTryDT)
        if bTryDT
            [~,fnonly,~] = fileparts(filename);
            Calls = AddDateTime(Calls,fnonly);
        else
            if any(strcmp('StTime', Calls.Properties.VariableNames))
                Calls.StTime = [];
            end
            Calls.StTime = NaT(height(Calls),1);
        end
        %save(filename,'Calls','-append');
        save(filename,'Calls','allAudio','detection_metadata','spect');
    end

    if isempty(spect)
        if ~isempty(handles)
            warning('Spect settings not previously saved; appending to detections.mat now.')
            spect = handles.data.settings.spect;
            %save(filename,'spect','-append');
            save(filename,'Calls','allAudio','detection_metadata','spect');
        end
    else
        if spect.nfft == 0
            spect.nfft = spect.nfftsmp/Calls.Audiodata(1).SampleRate;
            spect.windowsize = spect.windowsizesmp/Calls.Audiodata(1).SampleRate;
            spect.noverlap = spect.noverlap/Calls.Audiodata(1).SampleRate;
        elseif spect.nfftsmp == 0
            spect.nfftsmp = spect.nfft*Calls.Audiodata(1).SampleRate;
            spect.windowsizesmp = spect.windowsize*Calls.Audiodata(1).SampleRate;
        elseif spect.nfft ~= spect.nfftsmp/Calls.Audiodata(1).SampleRate || ...
                spect.windowsize ~= spect.windowsizesmp/Calls.Audiodata(1).SampleRate
            if nargout < 6
                waitfor(msgbox('Something is weird about the spectrogram settings saved with this file.  Highly recommend loading, opening Display Settings, and resaving in the general DA GUI.'))
            end
        end
    end
    
    if nargout > 0 && nargout < 6 && length(unique(Calls.Type)) > 1
        list = cellstr(unique(Calls.Type));
        [indx,tf] = listdlg('PromptString',{'Select the call types you would like to load.',...
            'WARNING: Saving after this point','without modifying the file name will','overwrite your existing detections file',...
            'with only the selected call types.',' ',' '},...
            'ListString',list,'ListSize',[200,300]);
        if tf
            Calls = Calls(ismember(Calls.Type,list(indx)),:);
        else
            error('You chose to cancel')
        end
    end

    if nargout == 6
        %% Output for detection mat modification check
        modcheck.calls = data.Calls;
        modcheck.spect = spect;
    else
        % This may not actually be working right because this fn doesn't
        % have the power to update handles...
        handles.data.settings.spect = spect;
    end
elseif nargout < 5 % If ClusteringData is requested, we don't need Calls
    error('This doesn''t appear to be a detection file!')
end

if nargout < 5
    
    %% Make sure there's nothing wrong with the call file
    if isempty(Calls)
        disp(['No calls in file: ' filename]);
    else
        % Backwards compatibility with struct format for detection files
        if isstruct(Calls)
            Calls = struct2table(Calls, 'AsArray', true);
        end

        % Remove calls with boxes of size zero
        Calls(Calls.Box(:,4) == 0, :) = [];
        Calls(Calls.Box(:,3) == 0, :) = [];

        % Remove calls above Nyquist frequency
        inddel = zeros(height(Calls),1);
        for i = 1:height(Calls)
            % If bottom of bounding box is above audio's Nyquist, display
            % warning and remove call
            if Calls.Box(i,2) >= Calls.Audiodata(i).SampleRate/2000
                inddel(i) = 1;
            end
        end
        if any(inddel)
            warning('Some Calls were above Nyquist and were automatically removed (perhaps your audio was decimated after detections were established?)')
            Calls(i,:) = [];
        end
        
        % Remove any old variables that we don't use anymore
        Calls = removevars(Calls, intersect(Calls.Properties.VariableNames, {'RelBox', 'Rate', 'Audio','Power'}));
        
        % Sort calls by time
        Calls = SortCalls(Calls,'time');
    end
    
    
    %% If audiodata isn't present, make it so
    if ~isempty(handles) && (~any(strcmp('Audiodata', Calls.Properties.VariableNames)) && (isempty(audiodata) || ~isfield(audiodata, 'Filename') || ~isfile(audiodata.Filename)))
        error('This should never happen.  If it does let GA know and she will figure out how to fix it.')
        % Does anything in the audio folder match the filename? If so, assume
        % this is the matching audio file, else select the right one.
%         [~, detection_name] = fileparts(filename);
%         filename_match = [];
%         for i = 1:length(handles.audiofilesnames)
%             [~, name_only] = fileparts(handles.audiofiles(i).name);
%             filename_match(i) = contains(detection_name, name_only);
%         end
%         filename_match = find(filename_match);
%         
%         % Did we find a matching file?
%         if ~isempty(filename_match)
%             audio_file = fullfile(handles.audiofiles(filename_match).folder, handles.audiofiles(filename_match).name);
%         else
%             [file, path] = uigetfile({
%                 '*.wav;*.ogg;*.flac;*.UVD;*.au;*.aiff;*.aif;*.aifc;*.mp3;*.m4a;*.mp4' 'Audio File'
%                 '*.wav' 'WAVE'
%                 '*.flac' 'FLAC'
%                 '*.ogg' 'OGG'
%                 '*.UVD' 'Ultravox File'
%                 '*.aiff;*.aif', 'AIFF'
%                 '*.aifc', 'AIFC'
%                 '*.mp3', 'MP3 (it''s probably a bad idea to record in MP3'
%                 '*.m4a;*.mp4' 'MPEG-4 AAC'
%                 }, sprintf('Importing from standard DeepAcoustics. Select audio matching the detection file %s',detection_name), detection_name);
%             audio_file = fullfile(path, file);
%             if isequal(file,0) % If user pressed cancel
%                 errordlg('DeepAcoustics requires the audio file accompanying the detection file.')
%                 return
%             end
%         end
%         
%         audiodata = audioinfo(audio_file);
%         disp('Saving call file with updated audio')
%         save(filename, 'audiodata', '-append');
%     end
%     if audiodata.NumChannels > 1
%         warning('Audio file contains more than one channel. Use channel 1...')
    end
end
