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
addParameter(p,'for_denoise', 0);
parse(p,varargin{:});
spectrogramOptions = p.Results.spectrogramOptions;

ClusteringData = {};
clustAssign = [];
specFF = [];
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
        if p.Results.for_denoise == 0
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
    % 
    % maxDur = max(Calls.Box(:,3));
    % maxBW = max(Calls.Box(:,4));

    Noise = [];
    warning('Spectrograms saved in Clustering Data will be padded up to 5% in both directions.')
end

%% for each call in the file, calculate stats for clustering
for i = 1:height(Calls)
    waitbar(i/height(Calls),h, sprintf('Loading File %u of %u', perFileCallID(i), length(fileName)));
    
    % Change the audio file if needed
    audioReader.audiodata = Calls.Audiodata(i);
    % Add a little padding
    fTimePad = Calls.Box(i,3)*0.05;
    fFreqPad = Calls.Box(i,4)*0.05;
    % % If for anomaly test, standardize box size to max dims
    % if p.Results.for_denoise == 2
    %     fTimePad = (maxDur-Calls.Box(i,3))/2;
    %     fFreqPad = (maxBW-Calls.Box(i,4))/2;
    % end

    %% For basic clipped spectrogram
    [I,wind,noverlap,nfft,rate,box,~,~,~,~,pow] = CreateFocusSpectrogram(Calls(i,:), handles.data, true, fTimePad, fFreqPad);
    
    % If spectrogram settings iffy
    if any(size(pow) < 3)
        warning('FFT settings suboptimal and causing calls to be skipped when creating Clustering Data - recommend changing')
        continue
    end

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

    %% For full-freq spectrogram
    [~,~,~,~,~,~,~,~,~,~,powff,pownoise] = CreateFocusSpectrogram(Calls(i,:), handles.data, true, fTimePad, fFreqPad, true);

    % If spectrogram settings iffy
    if any(size(powff) < 3)
        warning('FFT settings suboptimal and causing calls to be skipped when creating Clustering Data - recommend changing')
        continue
    end

    powff(powff==0)=.01;
    powff = log10(powff);
    powff = rescale(imcomplement(abs(powff)));
    % Create Adjusted Image for Identification
    xTile=ceil(size(powff,1)/10);
    yTile=ceil(size(powff,2)/10);
    if xTile>1 && yTile>1
        imff = adapthisteq(flipud(powff),'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
    else
        imff = adapthisteq(flipud(powff),'NumTiles',[2 2],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);    
    end

    %% Saving a bunch of Noise
    if ~any(size(pownoise) < 3)
        pownoise(pownoise==0)=.01;
        pownoise = log10(pownoise);
        pownoise = rescale(imcomplement(abs(pownoise)));
        % Create Adjusted Image for Identification
        xTile=ceil(size(pownoise,1)/10);
        yTile=ceil(size(pownoise,2)/10);
        if xTile>1 && yTile>1
            imnoise = adapthisteq(flipud(pownoise),'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
        else
            imnoise = adapthisteq(flipud(pownoise),'NumTiles',[2 2],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);    
        end

        Noise = [Noise, uint8(imnoise .* 256)];
    end

    %% Other Clustering Data info
    
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

    % Full Frequency Image
    specFF = [specFF; {uint8(imff .* 256)}];
    clustAssign = [clustAssign; Calls.Type(i)];
end

ClusteringData = cell2table(ClusteringData(:,1:18), 'VariableNames', {'Spectrogram', 'Box', 'MinFreq', 'Duration', 'xFreq', 'xTime', 'Filename', 'callID', 'Power', 'Bandwidth','FreqScale','TimeScale','NumContPts','Type','UserID','ClustAssign','xFreqAuto','xTimeAuto'});

maxDim1 = 0;
maxDim2 = 0;
% Fix duplicated time points by adding a teensy weensy bit
% to the latter of any duplications
for i = 1:height(ClusteringData)
    bDup = any(diff(ClusteringData.xTime{i})==0);
    while bDup
        indDups = [false,diff(ClusteringData.xTime{i})==0];
        ClusteringData.xTime{i}(indDups) = ClusteringData.xTime{i}(indDups)+0.0001;
        bDup = any(diff(ClusteringData.xTime{i})==0);
    end

    % Take advantage of this loop to set maxDims for for_denoise >= 2
    maxDim1 = max(maxDim1,size(ClusteringData.Spectrogram{i},1));
    maxDim2 = max(maxDim2,size(ClusteringData.Spectrogram{i},2));
end

% Only do this if variables are available from loading Dets file
if ~isempty(Calls)
    ClusteringData.SpecFF = specFF;
    
    goalAR = median(cellfun(@(im) size(im,1) ./ size(im,2), ClusteringData.Spectrogram));
    
    % Opt3 = standardize size and shape of image, but maintain size and shape
    % of actual call (snap to upper left corner of black canvas)
    % Opt4 = same as Opt 3 but canvas is filled in with noise
    if p.Results.for_denoise >= 2
        for i = 1:height(ClusteringData)
            imrep3 = zeros(maxDim1,maxDim2,'uint8');
            % for Opt 1b
            thisAR = size(ClusteringData.Spectrogram{i},1)/size(ClusteringData.Spectrogram{i},2);
            goaldim1 = size(ClusteringData.Spectrogram{i},1);
            goaldim2 = size(ClusteringData.Spectrogram{i},2);
            if thisAR < goalAR
                goaldim1 = round(goaldim2*goalAR);
            else
                goaldim2 = round(goaldim1*goalAR);
            end
            imrep1b = zeros(goaldim1,goaldim2);
            if p.Results.for_denoise == 3
                imrep4 = imrep3;
                for j = 1:(max(maxDim1,goaldim1))
                    for k = 1:(max(maxDim2,goaldim2))
                        rand1 = randi(size(Noise,1));
                        rand2 = randi(size(Noise,2));
                        if j <= maxDim1 && k <= maxDim2
                            imrep4(j,k) = Noise(rand1,rand2);
                        end
                        if j <= goaldim1 && k <= goaldim2
                            imrep1b(j,k) = Noise(rand1,rand2);
                        end
                    end
                end
            end
            imrep3(1:size(ClusteringData.Spectrogram{i},1),1:size(ClusteringData.Spectrogram{i},2)) = ClusteringData.Spectrogram{i};
            imrep4(1:size(ClusteringData.Spectrogram{i},1),1:size(ClusteringData.Spectrogram{i},2)) = ClusteringData.Spectrogram{i};
            imrep1b(1:size(ClusteringData.Spectrogram{i},1),1:size(ClusteringData.Spectrogram{i},2)) = ClusteringData.Spectrogram{i};
            ClusteringData.Spec3{i} = imrep3;
            ClusteringData.Spec4{i} = imrep4;
            ClusteringData.Spec1b{i} = imrep1b;
        end
    end
end

close(h)

if p.Results.save_data && ~isempty(Calls) % GA: audiodata not a variable so bug at some point, so commented this out and replaced with Calls check ~all(cellfun(@(x) isempty(fields(x)), audiodata)) % If audiodata has no fields, then only extracted contours were used, so don't ask to save them again
    pind = regexp(char(ClusteringData{1,'Filename'}),'\');
    pind = pind(end);
    pname = char(ClusteringData{1,'Filename'});
    pname = pname(1:pind);
    [FileName,PathName] = uiputfile(fullfile(pname,'ClusteringData.mat'),'Save extracted data for faster loading (optional)');
    if FileName ~= 0
        if isempty(spect)
            spect = handles.data.settings.spect;
        end
        save(fullfile(PathName,FileName),'ClusteringData','spect','-v7.3');
    end
end
