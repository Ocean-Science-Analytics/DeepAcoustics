% --------------------------------------------------------------------
function import_raven_Callback(hObject, eventdata, handles)
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
        [ravenname,ravenpath] = uigetfile(fullfile(handles.data.squeakfolder,'*.txt;*.csv'),...
            'Select Raven Log - Can Select Multiple','MultiSelect','on');
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
        outpath = uigetdir(ravenpath,'Select Directory To Save Output Files (WARNING: Will Overwrite)');

        if ischar(ravenname)
            ravenname = {ravenname};
        end
        audioname = cell(size(ravenname));
    case 'No - I am doing only one table and its one audio file'
        bAutoTry = true;
        [ravenname,ravenpath] = uigetfile(fullfile(handles.data.squeakfolder,'*.txt;*.csv'),'Select Raven Log');
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
        outpath = uigetdir(ravenpath,'Select Directory To Save Output Files (WARNING: Will Overwrite)');
        audioname = {{thisaudioname}};
        ravenname = {ravenname};
    case 'Cancel'
        uiwait(msgbox('You chose to cancel the Raven import'))
        return
end

if ~bAutoTry
    for i = 1:length(ravenname)
        if strcmp(ravenname{i}(end-2:end),'csv')
            ravenTable = readtable([ravenpath ravenname{i}]);
        else
            ravenTable = readtable([ravenpath ravenname{i}], 'Delimiter', 'tab');
        end

        if any(strcmp('BeginFile',ravenTable.Properties.VariableNames))
            if ~ismember('FileOffset_s_', ravenTable.Properties.VariableNames)
                error('"BeginFile" is present but "FileOffset_s_" is not a field in your Raven table')
            elseif ~ismember('DeltaTime_s_', ravenTable.Properties.VariableNames) && ~ismember('EndTime_s_', ravenTable.Properties.VariableNames)
                error('%s\n%s\n', '"BeginFile" and "FileOffset_s_" are present but both "DeltaTime_s_"',...
                    'and "EndTime_s_" are missing from your Raven table and you need at least one of them.')
            end
            audioname{i} = unique(ravenTable.BeginFile);
        else
            warning('"BeginFile" is not a field in your Raven table - will attempt to auto-match a wav file')
            bAutoTry = true;
        end

        if bAutoTry
            [datetime,~] = regexp(ravenname{i},'([0-9]{6}).*([0-9]{6})','tokens','match');
            if isempty(datetime)
                [datetime,~] = regexp(ravenname{i},'([0-9]{6}).*([0-9]{4})','tokens','match');
            end
            if ~isempty(datetime)
                audiomatch = regexp({audiodir.name},['.*' datetime{1}{1} '.*' datetime{1}{2} '.*'],'match');
                audiomatch = ~cellfun(@isempty, audiomatch);
                if ~any(audiomatch)
                    audiomatch = regexp({audiodir.name},['.*' datetime{1}{1} '.*' datetime{1}{2}(1:4) '.*'],'match');
                    audiomatch = ~cellfun(@isempty, audiomatch);
                end
            end
            if isempty(datetime) || length(find(audiomatch)) ~= 1
                uiwait(msgbox('Could not automatically match all wav files to txt files - you will have to do them one-by-one'))
                [ravenname,ravenpath] = uigetfile(fullfile(ravenpath,'*.txt;*.csv'),'Select Raven Log');
                %ravenTable = readtable([ravenpath ravenname], 'Delimiter', 'tab');
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
                audioname = {{thisaudioname}};
                ravenname = {ravenname};
                break;
            else
                audioname{i} = {audiodir(audiomatch).name};
            end
        end
    end
end

for i = 1:length(ravenname)
    if strcmp(ravenname{i}(end-2:end),'csv')
        ravenTable = readtable([ravenpath ravenname{i}]);
    else
        ravenTable = readtable([ravenpath ravenname{i}], 'Delimiter', 'tab');
    end
    for j = 1:length(audioname{i})
        if length(audioname{i}) > 1
            subTable = ravenTable(strcmp(audioname{i}{j},ravenTable.BeginFile),:);
        else
            subTable = ravenTable;
        end
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

        %% Get the data from the raven file
        Box    = [subTable.BeginTime_s_, subTable.LowFreq_Hz_/1000, subTable.DeltaTime_s_, (subTable.HighFreq_Hz_ - subTable.LowFreq_Hz_)/1000];
        Score  = ones(height(subTable),1);
        Accept = ones(height(subTable),1);

        %% Get the classification from raven, from the variable 'Tags' or 'Annotation'
        if ismember('Tags', subTable.Properties.VariableNames)
            Type = categorical(subTable.Tags);
        elseif ismember('Annotation', subTable.Properties.VariableNames)
            Type = categorical(subTable.Annotation);
        else
            Type = categorical(repmat({'Call'}, height(subTable), 1));
        end

        %% Put all the variables into a table
        Calls = table(Box,Score,Accept,Type,'VariableNames',{'Box','Score','Accept','Type'});

        [~ ,FileName] = fileparts(audioname{i}{j});
        %[FileName, PathName] = uiputfile(fullfile(handles.data.settings.detectionfolder, [name '.mat']),'Save Call File');
        save(fullfile(outpath,[FileName '_Detections.mat']),'Calls', 'audiodata','-v7.3');
        close(hc);
    end
end
update_folders(hObject, eventdata, handles);
