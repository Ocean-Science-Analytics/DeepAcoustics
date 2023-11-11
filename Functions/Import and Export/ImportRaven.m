% --------------------------------------------------------------------
function ImportRaven(hObject, eventdata, handles)
% Requires a Raven table and audio file.
% (http://www.birds.cornell.edu/brp/raven/RavenOverview.html)

% User recommendation warning
warning('%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n', 'It is highly recommended when importing a Raven selection table',...
    'that there is a "Begin File" field with the filename of the wav file',...
    'containing the annotation and a "File Offset (s)" containing the time in seconds',...
    'since the start of that wav file.  There must also be either an "End Time (s)" field',...
    'or a "Delta Time (s)" field so that the right edge of the call within the file can be calculated.',...
    'If those conditions are not met, DS will attempt to match audio files to',...
    'selection tables using the filenames, but this only works if there is a one-to-one correspondence,',...
    'and may cause unexpected behavior down the road.')

answer = questdlg('Are you trying to import multiple Raven tables and/or audio files?', ...
	'Multi-Raven Import?', ...
	'Yes - I have multiple tables and/or audio files',...
    'No - I am doing only one table and its one audio file','Cancel','Cancel');
% Handle response
switch answer
    case 'Yes - I have multiple tables and/or audio files'
        bAutoTry = false;
        
        %% Get the files
        % Select set of Raven selection tables
        [ravenname,ravenpath] = uigetfile(fullfile(handles.data.squeakfolder,'*.txt;*.csv'),...
            'Select Raven Log - Can Select Multiple','MultiSelect','on');
        % Select directory containing audio files corresponding to Raven
        % tables
        audiopath = uigetdir(ravenpath,'Select Directory Containing Corresponding Audio Files');
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
        % Select output directory for saving generated Detections.mat
        outpath = uigetdir(ravenpath,'Select Directory To Save Output Detections.mat (WARNING: Will Overwrite)');

        % If only one raven table selected, needs to be reformatted as a
        % cell array so later code works
        if ischar(ravenname)
            ravenname = {ravenname};
        end
        % Initialize container for the audio files that correspond to each
        % Raven table file
        audioname = cell(size(ravenname));
    case 'No - I am doing only one table and its one audio file'
        % Because there is a one-to-one match, we will not need to try to
        % figure out which audio files go with which tables, so setting
        % this to true will allow us to skip that part of the code
        bAutoTry = true;
        % Select single Raven selection table
        [ravenname,ravenpath] = uigetfile(fullfile(handles.data.squeakfolder,'*.txt;*.csv'),'Select Raven Log');
        % Select single audio file that goes with that selection table
        [thisaudioname, audiopath] = uigetfile({
            '*.wav;*.ogg;*.flac;*.UVD;*.au;*.aiff;*.aif;*.aifc;*.mp3;*.m4a;*.mp4' 'Audio File'
            '*.wav' 'WAVE'
            '*.flac' 'FLAC'
            '*.ogg' 'OGG'
            '*.UVD' 'Ultravox File'
            '*.aiff;*.aif', 'AIFF'
            '*.aifc', 'AIFC'
            '*.mp3', 'MP3 (it''s probably a bad idea to record in MP3'
            '*.m4a;*.mp4' 'MPEG-4 AAC'
            }, 'Select Audio File',ravenpath);
        % Select output directory for saving generated Detections.mat
        outpath = uigetdir(ravenpath,'Select Directory To Save Output Files (WARNING: Will Overwrite)');
        % Reformat variable type for name of Raven selection table file and
        % name of audio file
        ravenname = {ravenname};
        audioname = {{thisaudioname}};
    case 'Cancel'
        uiwait(msgbox('You chose to cancel the Raven import'))
        return
end

% If we are importing either multiple Raven tables or multiple audio
% files...
if ~bAutoTry
    % For every Raven selection table selected...
    for i = 1:length(ravenname)
        % Import as table (method depends on incoming file type)
        if strcmp(ravenname{i}(end-2:end),'csv')
            ravenTable = readtable([ravenpath ravenname{i}]);
        else
            ravenTable = readtable([ravenpath ravenname{i}], 'Delimiter', 'tab');
        end
        % Look for the columns we need to create Detections Table
        % BeginFile = the audio file corresponding to that detection
        if any(strcmp('BeginFile',ravenTable.Properties.VariableNames))
            % Error out if field with seconds into file is missing
            if ~ismember('FileOffset_s_', ravenTable.Properties.VariableNames)
                error('"BeginFile" is present but "FileOffset_s_" is not a field in your Raven table')
            % Error out if all fields that help figure out end time of
            % detection is missing
            elseif ~ismember('DeltaTime_s_', ravenTable.Properties.VariableNames) && ~ismember('EndTime_s_', ravenTable.Properties.VariableNames)
                error('%s\n%s\n', '"BeginFile" and "FileOffset_s_" are present but both "DeltaTime_s_"',...
                    'and "EndTime_s_" are missing from your Raven table and you need at least one of them.')
            end
            % Store the audio files that are included in this selection
            % table
            audioname{i} = unique(ravenTable.BeginFile);
        else
            % Switch to a mode that will try to auto-match an audio file
            % based on the filename of the selection table
            warning('"BeginFile" is not a field in your Raven table - will attempt to auto-match an audio file. \nThis will NOT work properly if there are multiple audio files corresponding to your Raven table')
            bAutoTry = true;
        end

        % If need to try and auto-match an audio file to a selection
        % table...
        if bAutoTry
            % First look for YYMMDD.*HHMMSS
            [thisdt,~] = regexp(ravenname{i},'([0-9]{6}).*([0-9]{6})','tokens','match');
            % If failure, then try YYMMDD.*HHMM
            if isempty(thisdt)
                [thisdt,~] = regexp(ravenname{i},'([0-9]{6}).*([0-9]{4})','tokens','match');
            end
            % If success, look for that date/time in audio file directory
            if ~isempty(thisdt)
                % First look for exact match
                audiomatch = regexp({audiodir.name},['.*' thisdt{1}{1} '.*' thisdt{1}{2} '.*'],'match');
                audiomatch = ~cellfun(@isempty, audiomatch);
                % If failure, try HHMM (assumes match attempt is for
                % HHMMSS)
                if ~any(audiomatch)
                    audiomatch = regexp({audiodir.name},['.*' thisdt{1}{1} '.*' thisdt{1}{2}(1:4) '.*'],'match');
                    audiomatch = ~cellfun(@isempty, audiomatch);
                end
            end
            % If failure to find any date/time in file name OR matched none
            % or multiple audio files to the found date/time format, alert
            % user that they will have to do the Raven table import
            % one-by-one and initialize one import to start
            if isempty(thisdt) || length(find(audiomatch)) ~= 1
                uiwait(msgbox('Could not automatically match all wav files to txt files - you will have to do them one-by-one'))
                % Select single Raven selection table
                [ravenname,ravenpath] = uigetfile(fullfile(ravenpath,'*.txt;*.csv'),'Select Raven Log');
                % Select single audio file that goes with that selection table
                [thisaudioname, audiopath] = uigetfile({
                    '*.wav;*.ogg;*.flac;*.UVD;*.au;*.aiff;*.aif;*.aifc;*.mp3;*.m4a;*.mp4' 'Audio File'
                    '*.wav' 'WAVE'
                    '*.flac' 'FLAC'
                    '*.ogg' 'OGG'
                    '*.UVD' 'Ultravox File'
                    '*.aiff;*.aif', 'AIFF'
                    '*.aifc', 'AIFC'
                    '*.mp3', 'MP3 (it''s probably a bad idea to record in MP3'
                    '*.m4a;*.mp4' 'MPEG-4 AAC'
                    }, 'Select Audio File',audiopath);
                % Reformat variable type for name of Raven selection table file and
                % name of audio file
                audioname = {{thisaudioname}};
                ravenname = {ravenname};
                break;
            else
                % If success, store the matched audio file's name for
                % further importing
                audioname{i} = {audiodir(audiomatch).name};
            end
        end
    end
end

Calls = [];
nAudCt = 0;
% For every incoming selection table...
for i = 1:length(ravenname)
    % Import as table (method depends on incoming file type)
    if strcmp(ravenname{i}(end-2:end),'csv')
        ravenTable = readtable([ravenpath ravenname{i}]);
    else
        ravenTable = readtable([ravenpath ravenname{i}], 'Delimiter', 'tab');
    end
    % For every audio file contained within this Raven selection table
    for j = 1:length(audioname{i})
        nAudCt = nAudCt+1;
        % subTable = only the dets that belong to this audio file
        if length(audioname{i}) > 1
            subTable = ravenTable(strcmp(audioname{i}{j},ravenTable.BeginFile),:);
        else
            subTable = ravenTable;
        end
        % Import audiodata
        audiodata = audioinfo(fullfile(audiopath, audioname{i}{j}));
        if audiodata.NumChannels > 1
            warning('Audio file contains more than one channel. Use channel 1...')
        end
        hc = waitbar(0,'Importing Calls from Raven Log');

        % fix some compatibility issues with Raven's naming
        if ~ismember('DeltaTime_s_', subTable.Properties.VariableNames)
            subTable.DeltaTime_s_ = subTable.EndTime_s_ - subTable.BeginTime_s_;
        end
        
        % fix some compatibility issues with Raven's naming
        if ismember('FileOffset_s_', subTable.Properties.VariableNames)
            subTable.BeginTime_s_ = subTable.FileOffset_s_;
        end

        %% Get the data from the raven file needed for Detections.mat
        Box    = [subTable.BeginTime_s_, subTable.LowFreq_Hz_/1000, subTable.DeltaTime_s_, (subTable.HighFreq_Hz_ - subTable.LowFreq_Hz_)/1000];
        Score  = ones(height(subTable),1);
        Accept = ones(height(subTable),1);

        %% Get the classification from raven, from the variable 'Tags' or 'Annotation'
        if ismember('Tags', subTable.Properties.VariableNames)
            if isa(subTable.Tags,'double')
                subTable.Tags = cellstr(num2str(subTable.Tags));
            end
            Type = categorical(subTable.Tags);
        elseif ismember('Annotation', subTable.Properties.VariableNames)
            if isa(subTable.Annotation,'double')
                subTable.Annotation = cellstr(num2str(subTable.Annotation));
            end
            Type = categorical(subTable.Annotation);
        else
            Type = categorical(repmat({'Call'}, height(subTable), 1));
        end
        Audiodata = repmat(audiodata,height(subTable),1);

        %% Put all the variables into a table
        Calls_tmp = table(Box,Score,Accept,Type,Audiodata,'VariableNames',{'Box','Score','Accept','Type','Audiodata'});
        Calls = [Calls; Calls_tmp];
        close(hc);
    end
end
% Auto-name Detections.mat using audioname
[~ ,FileName] = fileparts(audioname{1}{1});
FileName = [FileName '_' num2str(nAudCt) 'AudFiles'];
% Save Detections.mat
save(fullfile(outpath,[FileName '_Detections.mat']),'Calls');
update_folders(hObject, eventdata, handles);
