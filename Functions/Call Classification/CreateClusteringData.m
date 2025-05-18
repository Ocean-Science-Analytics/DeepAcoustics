function [ClusteringData, clustAssign, freqRange, maxDuration, spectrogramOptions, spect] = CreateClusteringData(handles, varargin)
%% This function prepares data for clustering
% For each file selected, create a cell array with the image, and contour
% of calls where Calls.Accept == 1

p = inputParser;
addParameter(p,'forClustering', false);
addParameter(p,'spectrogramOptions', []);
% scale_duration can eithor be logical or scaler. If scalar, scale_duration
% is the duration used at t_max to scale duration by sqrt(t_max ./ t)
% If true, than t_max is the 95th percentile of call durations
addParameter(p,'scale_duration', false);
% If scale_duration is true, use a fixed frequency range for spectrograms
addParameter(p,'fixed_frequency', false);
% fixed_frequency = [lowFreq, highFreq] for fixed frequency range
addParameter(p,'freqRange', []);
% Ask to save the data for future use
addParameter(p,'save_data', false);
addParameter(p,'for_denoise', false);
parse(p,varargin{:});
spectrogramOptions = p.Results.spectrogramOptions;

ClusteringData = {};
clustAssign = [];
maxDuration = [];
freqRange = [];
xFreq = [];
xTime = [];
stats.Power = [];

% Select the files
if p.Results.forClustering
    prompt = 'Select detection file(s) for clustering AND/OR extracted contours';
else
    prompt = 'Select detection file(s) for viewing';
end
[fileName, filePath] = uigetfile(fullfile(handles.data.settings.detectionfolder,'*.mat'),prompt,'MultiSelect', 'on');
if isnumeric(fileName); ClusteringData = {}; return; end

% If one file is selected, turn it into a cell
fileName = cellstr(fileName);

h = waitbar(0,'Initializing');
audioReader = squeakData([]);
%% Load the data
audiodata = {};
Calls = [];
spect = [];
perFileCallID = [];
for j = 1:length(fileName)
    if strcmp(char(handles.current_detection_file),fileName{j})
        uiwait(warndlg('It looks like you might be using the same Detections file that is loaded in the main GUI.  Make sure you have saved any changes (e.g., spectrogram settings) in that main window before proceeding.  Changes are NOT saved automatically.', ...
            'WARNING','modal'));
    end
    [Calls_tmp, ~, spect, ~, loaded_ClusteringData] = loadCallfile(fullfile(filePath,fileName{j}),handles,false);
    if isempty(spect)
        spect = handles.data.settings.spect;
    else
        handles.data.settings.spect = spect;
    end
    % If the files is extracted contours, rather than a detection file
    if ~isempty(loaded_ClusteringData)
        % Back-compatible load
        if ~ismember('xFreqAuto',loaded_ClusteringData.Properties.VariableNames)
            loaded_ClusteringData.xFreqAuto = loaded_ClusteringData.xFreq;
            loaded_ClusteringData.xTimeAuto = loaded_ClusteringData.xTime;
        end
        ClusteringData = [ClusteringData; table2cell(loaded_ClusteringData)];
        continue
    else
        % Remove calls that aren't accepted
        if ~p.Results.for_denoise
            Calls_tmp = Calls_tmp(Calls_tmp.Accept == 1 & ~ismember(Calls_tmp.Type,'Noise'), :);
        end
        Calls = [Calls; Calls_tmp];
        perFileCallID = [perFileCallID; repmat(j,height(Calls_tmp), 1)];
    end
end

%% Stretch the duration of calls by a factor of sqrt(t_max / t)
% This is used for VAE
if ~isempty(Calls)
    if p.Results.scale_duration
        if islogical(p.Results.scale_duration)
            maxDuration = prctile(Calls.Box(:,3),95);
        else
            maxDuration = p.Results.scale_duration;
        end

        time_padding = Calls.Box(:,3)*.25;
        Calls.Box(:,3) =  Calls.Box(:,3) + time_padding*2;
        Calls.Box(:,1) = Calls.Box(:,1) - time_padding;
    end
    % Use the box, or a fixed frequency range?
    if p.Results.fixed_frequency || ~isempty(p.Results.freqRange)
        if ~isempty(p.Results.freqRange)
            freqRange = p.Results.freqRange;
        else
            freqRange(1) = prctile(Calls.Box(:,2), 5);
            freqRange(2) = prctile(Calls.Box(:,4) + Calls.Box(:,2), 95);
        end

        freq_padding = Calls.Box(:,4)*.25;
        Calls.Box(:,2) = Calls.Box(:,2) - freq_padding;
        Calls.Box(:,4) = Calls.Box(:,4) + freq_padding*2;
    end
end
%% for each call in the file, calculate stats for clustering
for i = 1:height(Calls)
    waitbar(i/height(Calls),h, sprintf('Loading File %u of %u', perFileCallID(i), length(fileName)));
    
    % Change the audio file if needed
    audioReader.audiodata = Calls.Audiodata(i);
        
    [I,wind,noverlap,nfft,rate,box,~,~,~,~,pow] = CreateFocusSpectrogram(Calls(i,:), handles.data);
    
    % If spectrogram settings iffy
    if any(size(pow) < 3)
        warning('FFT settings suboptimal and causing calls to be skipped when creating Clustering Data - recommend changing')
        continue
    end

    % im = mat2gray(flipud(I),[0 max(max(I))/4]); % Set max brightness to 1/4 of max
    % im = mat2gray(flipud(I), prctile(I, [1 99], 'all')); % normalize brightness
    pow(pow==0)=.01;
    pow = log10(pow);
    pow = rescale(imcomplement(abs(pow)));
    % Create Adjusted Image for Identification
    xTile=ceil(size(pow,1)/10);
    yTile=ceil(size(pow,2)/10);
    if xTile>1 && yTile>1
    im = adapthisteq(flipud(pow),'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
    else
    im = adapthisteq(flipud(pow),'NumTiles',[2 2],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);    
    end
    
    spectrange = audioReader.audiodata.SampleRate / 2000; % get frequency range of spectrogram in KHz
    FreqScale = spectrange / (1 + floor(nfft / 2)); % size of frequency pixels
    TimeScale = (wind - noverlap) / audioReader.audiodata.SampleRate; % size of time pixels

    if p.Results.forClustering
        % If each call was saved with its own Entropy and Amplitude
        % Threshold, run CalculateStats with those values,
        % otherwise run with global settings
        if any(strcmp('EntThresh',Calls.Properties.VariableNames)) && ...
            ~isempty(Calls.EntThresh(i))
            % Calculate statistics
            stats = CalculateStats(I,wind,noverlap,nfft,rate,box,Calls.EntThresh(i),Calls.AmpThresh(i));
        else
            stats = CalculateStats(I,wind,noverlap,nfft,rate,box,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);
        end
        xFreq = FreqScale * (stats.ridgeFreq_smooth) + Calls.Box(i,2);
        xTime = stats.ridgeTime * TimeScale;
    else
        stats.DeltaTime = box(3);
    end
    % Preserve automatic contours (xFreq and xTime could be manipulated
    % later with contour tracing tool)
    xFreqAuto = xFreq;
    xTimeAuto = xTime;
    
    ClusteringData = [ClusteringData
        [{uint8(im .* 256)} % Image
        {box}
        {box(2)} % Lower freq
        {stats.DeltaTime} % Delta time
        {xFreq} % Time points
        {xTime} % Freq points
        {[filePath fileName{perFileCallID(i)}]} % File path
        {perFileCallID(i)} % Call ID in file
        {stats.Power}
        {box(4)}
        {FreqScale}
        {TimeScale}
        {0}
        {Calls.Type(i)}
        {Calls.CallID(i)}
        {Calls.ClustCat(i)}
        {xFreqAuto}
        {xTimeAuto}
        ]'];
    
    clustAssign = [clustAssign; Calls.Type(i)];
end

ClusteringData = cell2table(ClusteringData(:,1:18), 'VariableNames', {'Spectrogram', 'Box', 'MinFreq', 'Duration', 'xFreq', 'xTime', 'Filename', 'callID', 'Power', 'Bandwidth','FreqScale','TimeScale','NumContPts','Type','UserID','ClustAssign','xFreqAuto','xTimeAuto'});

% Fix duplicated time points by adding a teensy weensy bit
% to the latter of any duplications
for i = 1:height(ClusteringData)
    bDup = any(diff(ClusteringData.xTime{i})==0);
    while bDup
        indDups = [false,diff(ClusteringData.xTime{i})==0];
        ClusteringData.xTime{i}(indDups) = ClusteringData.xTime{i}(indDups)+0.0001;
        bDup = any(diff(ClusteringData.xTime{i})==0);
    end
end

close(h)

if p.Results.save_data && ~all(cellfun(@(x) isempty(fields(x)), audiodata)) % If audiodata has no fields, then only extracted contours were used, so don't ask to save them again
    pind = regexp(char(ClusteringData{1,'Filename'}),'\');
    pind = pind(end);
    pname = char(ClusteringData{1,'Filename'});
    pname = pname(1:pind);
    [FileName,PathName] = uiputfile(fullfile(pname,'Extracted Contours.mat'),'Save extracted data for faster loading (optional)');
    if FileName ~= 0
        if isempty(spect)
            spect = handles.data.settings.spect;
        end
        save(fullfile(PathName,FileName),'ClusteringData','spect','-v7.3');
    end
end
