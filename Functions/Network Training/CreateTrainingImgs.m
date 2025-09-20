function CreateTrainingImgs(app, event)
[~, ~, handles] = convertToGUIDECallbackArguments(app, event);
% hObject    handle to create_training_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Select the files to make images from
[trainingdata, trainingpath] = uigetfile([char(handles.data.settings.detectionfolder) '/*.mat'],'Select Detection File(s) for Training ','MultiSelect', 'on');
if isnumeric(trainingdata); return; end
trainingdata = cellstr(trainingdata);

% Get training settings

% Get min/max duration of detections to inform optimum image length
metadata.mindur = Inf;
metadata.maxdur = 0;
metadata.meddur = 0;
metadata.quan90dur = 0;
metadata.minfreq = Inf;
metadata.maxfreq = 0;
metadata.minSR = Inf;
metadata.maxSR = 0;

h = waitbar(0,'Loading Call File(s)');
Calls = [];
allAudio = [];
for k = 1:length(trainingdata)
    % Load the detection and audio files
    [Calls2Add,allAud2Add] = loadCallfile(fullfile(trainingpath, trainingdata{k}),handles,false);
    Calls = [Calls;Calls2Add];
    allAudio = [allAudio;allAud2Add];
    waitbar(k/length(trainingdata), h, sprintf('Loading File %g of %g', k, length(trainingdata))); 
end
close(h)

% Duration
metadata.mindur = min([Calls.Box(:,3)]);
metadata.maxdur = max([Calls.Box(:,3)]);
metadata.meddur = median([Calls.Box(:,3)]);
metadata.quan90dur = quantile([Calls.Box(:,3)],0.9);

% Frequency
metadata.minfreq = min([Calls.Box(:,2)]+[Calls.Box(:,4)]);
metadata.maxfreq = max([Calls.Box(:,2)]+[Calls.Box(:,4)]);

% SR
metadata.minSR = min([Calls.Audiodata.SampleRate]);
metadata.maxSR = max([Calls.Audiodata.SampleRate]);

uniqLabels = unique(cellstr(Calls.Type))';

app.RunTrainImgDlg(handles.data.settings.spect, metadata);
if app.TrainImgbCancel; return; end

h = waitbar(0,'Initializing');

[~, filename] = fileparts(trainingdata{1});
if length(trainingdata) > 1
    filename = [filename '&More'];
end
% Make a folder for the training images
% Default open location
strImgDir = fullfile(handles.data.squeakfolder,'Training');
% User-specified
strImgDir = uigetdir(strImgDir,'Select Folder to Output Training Images');

imgsize = app.TrainImgSettings.imSize;
imLength = app.TrainImgSettings.imLength;
repeats = app.TrainImgSettings.repeats+1;
freqlow = app.TrainImgSettings.FreqLow;
freqhigh = app.TrainImgSettings.FreqHigh;

% If augmented duplicates, create a directory to separate out augmented
% images
if repeats > 1
    status = mkdir(fullfile(strImgDir,'ImgAug'));
    if ~status
        warning('Problem making default Augmented Images directory')
    end
end

if app.TrainImgSettings.bRandNoise
    warning('This will overwrite your existing Dets files!')
    uniqLabels = cellstr(['Noise',uniqLabels']);
    % Call AddRandNoise for each Dets file!
    for k = 1:length(trainingdata)
        waitbar(k/length(trainingdata), h, sprintf('Adding Noise to File %g of %g', k, length(trainingdata))); 
        AddRandNoise(app,event,fullfile(trainingpath, trainingdata{k}),freqlow,freqhigh);
    end
end
TTable = array2table(zeros(0,2+length(uniqLabels)));
TTable.Properties.VariableNames = ['bAug','imageFilename',uniqLabels];

valdata = [];
valpath = [];
VTable = TTable;
if app.TrainImgSettings.bValData
    % Select the files to make validation images from
    [valdata, valpath] = uigetfile([char(handles.data.settings.detectionfolder) '/*.mat'],'Select Detection File(s) for Validation ','MultiSelect', 'on');
    if isnumeric(valdata); return; end
    valdata = cellstr(valdata);

    % Make a folder for the training images
    % Default open location
    strVImgDir = fullfile(handles.data.squeakfolder,'Validation');
    % User-specified
    strVImgDir = uigetdir(strVImgDir,'Select Folder to Output Validation Images - DIFFERENT from Training Images');
    if strcmp(strImgDir,strVImgDir)
        error('Training and Validation Images must be in different directories')
    end
    % If augmented duplicates, create a directory to separate out augmented
    % images
    if repeats > 1
        status = mkdir(fullfile(strVImgDir,'ImgAug'));
        if ~status
            warning('Problem making default Augmented Images directory')
        end
    end
end

nTCallsTotal = 0;
nVCallsTotal = 0;
nCallsWhole = [];
nCallsSplit = [];
nPiecesTotal = [];
allindst = 0;

concatdata = [trainingdata, valdata];
loadpath = trainingpath;
nLenTData = length(trainingdata);
for k = 1:length(concatdata)
    % Load the detection and audio files
    audioReader = squeakData();
    % Only need to re-load from the beginning if multiple Call files OR RandNoise added!!!,
    % otherwise already loaded!
    if length(concatdata) > 1 || app.TrainImgSettings.bRandNoise
        if k > 1
            allindst = allindst+height(Calls);
        end
        [Calls,allAudio] = loadCallfile(fullfile(loadpath, concatdata{k}),handles,false);
    end
    allAudio = unique({allAudio.Filename},'stable');
    
    % Remove Rejects
    Calls = Calls(Calls.Accept == 1, :);

    % Count total training and validation calls
    if k <= nLenTData
        nTCallsTotal = nTCallsTotal + height(Calls);
        % Next round we're loading validation data
        if k == nLenTData
            loadpath = valpath;
        end
    else
        nVCallsTotal = nVCallsTotal + height(Calls);
        % Switch to Validation directory!
        strImgDir = strVImgDir;
    end
    nCallsWhole = [nCallsWhole,ones(1,height(Calls))];
    nCallsSplit = [nCallsSplit,zeros(1,height(Calls))];
    nPiecesTotal = [nPiecesTotal,ones(1,height(Calls))];

    for j = 1:length(allAudio)
        indC = find(strcmp({Calls.Audiodata.Filename},allAudio{j}));
        if ~isempty(indC)
            subCalls = Calls(strcmp({Calls.Audiodata.Filename},allAudio{j}),:);
            audioReader.audiodata = subCalls.Audiodata(1);
            
            % Correct and retrieve spect settings (need SR to complete)
            if app.TrainImgSettings.nfft == 0
                app.TrainImgSettings.nfft = app.TrainImgSettings.nfftsmp/audioReader.audiodata.SampleRate;
                app.TrainImgSettings.windowsize = app.TrainImgSettings.windowsizesmp/audioReader.audiodata.SampleRate;
                app.TrainImgSettings.noverlap = app.TrainImgSettings.noverlap/audioReader.audiodata.SampleRate;
            elseif app.TrainImgSettings.nfftsmp == 0
                app.TrainImgSettings.nfftsmp = app.TrainImgSettings.nfft*audioReader.audiodata.SampleRate;
                app.TrainImgSettings.windowsizesmp = app.TrainImgSettings.windowsize*audioReader.audiodata.SampleRate;
            end
    
            wind = app.TrainImgSettings.windowsize;
            noverlap = app.TrainImgSettings.noverlap;
            nfft = app.TrainImgSettings.nfft;

            % Warn if any (parts of) boxes are outside selected frequency
            % limits
            % I was worried about this possibly making empty training images but
            % I think by adding the freq limits to AddRandNoise this is
            % at least mostly alleviated
            % This could still happen but those instances should not end up
            % in the Tables files, which I think is the important thing
            % (that and that it's not happening a ton)
            if any(subCalls.Box(subCalls.Type~='Noise',2)<(freqlow/1000)) || ...
                  any((subCalls.Box(subCalls.Type~='Noise',2)+subCalls.Box(subCalls.Type~='Noise',4))>(freqhigh/1000)) 
                warning('Some portions of training calls are outside your selected frequency limits and will be excluded from training')
            end
    
            bins = SplitBouts(subCalls,imLength,imLength);
                
            for bin = 1:length(unique(bins))
                indSC = find(bins==bin);
                BoutCalls = subCalls(bins == bin, :);
                
                %Center audio on middle of call bout and extract clip imLength in
                %length
                StartTime = max(min(BoutCalls.Box(:,1)), 0);
                FinishTime = max(BoutCalls.Box(:,1) + BoutCalls.Box(:,3));
                CenterTime = (StartTime+(FinishTime-StartTime)/2);
    
                % Number of images we have to make to cover this whole bout,
                % even if we have to split calls to do it
                nDiv = ceil((FinishTime-StartTime)/imLength);
    
                % Get overall start of bout when using whole image sizes
                % centered on entire bout
                StartTime = max(0,CenterTime - (nDiv/2)*imLength);
    
                % Get all starts accounting for splitting calls
                StartTimes = StartTime:imLength:(StartTime+imLength*nDiv);
                % Last one is bout end
                StartTimes = StartTimes(1:(end-1));
    
                BoutCallsBU = BoutCalls;
    
                % For each subbout in this bout
                for iSplit = 1:nDiv
                    calcProg = (bin-1)+(iSplit/nDiv);
                    waitbar(calcProg/length(unique(bins)), h, sprintf('Processing Det File %g of %g Aud File %g of %g', k, length(concatdata), j, length(allAudio)));   
                    % Reset BoutCalls before editing
                    BoutCalls = BoutCallsBU;
                    StartTime = StartTimes(iSplit);
                    FinishTime = StartTime+imLength;
            
                    %% Read Audio
                    audio = audioReader.AudioSamples(StartTime, FinishTime);
                    
                    % Subtract the start of the bout from the box times
                    BoutCalls.Box(:,1) = BoutCalls.Box(:,1) - StartTime;
    
                    % Remove calls that are not in image
                    % nRm is to help with indexing (but only needed for calls
                    % that affect indexing i.e. the earlier ones)
                    nRm = 0;
                    if any((BoutCalls.Box(:,1) < 0) & ((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) <= 0))
                        nRm = nRm+sum((BoutCalls.Box(:,1) < 0) & ((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) <= 0));
                        BoutCalls((BoutCalls.Box(:,1) < 0) & ((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) <= 0),:) = [];
                    end
                    if any((BoutCalls.Box(:,1) >= imLength))
                        %nRm = nRm+sum((BoutCalls.Box(:,1) >= imLength));
                        BoutCalls((BoutCalls.Box(:,1) >= imLength),:) = [];
                    end
                    
                    % If imLength < duration of a call, beginning and/or end will clip!
                    % Clip beg of call
                    if any(BoutCalls.Box(:,1) < 0)
                        warning("Your calls had to be split to fit into the chosen image size")
                        % Update counts
                        nCallsWhole(allindst+nRm+(indC(indSC(BoutCalls.Box(:,1) < 0)))) = 0;
                        nCallsSplit(allindst+nRm+(indC(indSC(BoutCalls.Box(:,1) < 0)))) = 1;
                        % nPieces only updated here because otherwise will
                        % double-count one end
                        nPiecesTotal(allindst+nRm+(indC(indSC(BoutCalls.Box(:,1) < 0)))) = nPiecesTotal(allindst+nRm+(indC(indSC(BoutCalls.Box(:,1) < 0))))+1;
                        % Adjust duration accordingly
                        BoutCalls.Box(BoutCalls.Box(:,1) < 0,3) = BoutCalls.Box(BoutCalls.Box(:,1) < 0,3) + BoutCalls.Box(BoutCalls.Box(:,1) < 0,1);
                        BoutCalls.Box(BoutCalls.Box(:,1) < 0,1) = 0;
                    end
                    
                    % Clip end of call
                    if any((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) > imLength)
                        warning("Your calls had to be split to fit into the chosen image size")
                        % Update counts
                        nCallsWhole(allindst+nRm+(indC(indSC((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) > imLength)))) = 0;
                        nCallsSplit(allindst+nRm+(indC(indSC((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) > imLength)))) = 1;
                        BoutCalls.Box((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) > imLength, 3) = imLength-BoutCalls.Box((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) > imLength, 1);
                    end
                    
                    try
                        for replicatenumber = 1:repeats
                            IMname = sprintf('%g_%g_%g_%g_%g.png', k, j, bin, iSplit, replicatenumber);
                            ffn = fullfile(strImgDir,IMname);
                            % Insert augmented images folder into filename to separate augs
                            % from ogs
                            bAug = false;
                            if replicatenumber > 1
                                ffn = fullfile(strImgDir,'ImgAug',IMname);
                                bAug = true;
                            end
                            [~,box] = CreateTrainingData(...
                                audio,...
                                audioReader.audiodata.SampleRate,...
                                BoutCalls,...
                                uniqLabels,...
                                wind,noverlap,nfft,...
                                freqlow,freqhigh,...
                                imgsize,...
                                ffn,...
                                replicatenumber);
                            if ~isempty(box)
                                if k <= nLenTData
                                    TTable = [TTable;[{bAug}, {ffn}, box]];
                                else
                                    VTable = [VTable;[{bAug}, {ffn}, box]];
                                end
                            end
                        end
                    catch
                        disp("Something wrong with calculating bounding box indices - talk to Gabi!");
                    end
                end      
            end
        end
    end
end
close(h)

nNoiseT = 0;
if ismember('Noise',TTable.Properties.VariableNames)
     nNoiseT = height(cell2mat([TTable.Noise]));
end
nNoiseV = 0;
if ismember('Noise',VTable.Properties.VariableNames)
     nNoiseV = height(cell2mat([VTable.Noise]));
end

if ismember('Call',TTable.Properties.VariableNames)
    if sum(nPiecesTotal(1:nTCallsTotal))~=height(cell2mat([TTable.Call(~TTable.bAug)]))   
        error('Call counts not adding up; talk to Gabi')
    end
end

if ismember('Call',VTable.Properties.VariableNames)
    if sum(nPiecesTotal(nTCallsTotal+1:end))~=height(cell2mat([VTable.Call(~VTable.bAug)]))    
        error('Call counts not adding up; talk to Gabi')
    end
end

msgbox({'Final Call Information:'; ...
    sprintf('# Total Calls in Det Files: %u',nTCallsTotal); ...
    sprintf('# Whole Calls in Images File: %u', sum(nCallsWhole(1:nTCallsTotal)));...
    sprintf('# Split Calls in Images File: %u', sum(nCallsSplit(1:nTCallsTotal)));...
    sprintf('# Total Call Pieces in Images File: %u', sum(nPiecesTotal(1:nTCallsTotal)));...
    sprintf('# Noise in Images File: %u', nNoiseT);...
    sprintf('# Total Calls in Det Files (Val): %u',nVCallsTotal); ...
    sprintf('# Whole Calls in Images File (Val): %u', sum(nCallsWhole(nTCallsTotal+1:end)));...
    sprintf('# Split Calls in Images File (Val): %u', sum(nCallsSplit(nTCallsTotal+1:end)));...
    sprintf('# Total Call Pieces in Images File (Val): %u', sum(nPiecesTotal(nTCallsTotal+1:end)));...
    sprintf('# Noise in Images File (Val): %u', nNoiseV);...
    },'Images Output');

[filename,matpath] = uiputfile(fullfile(handles.data.squeakfolder,'Training',[filename,'_Images.mat']));
save(fullfile(matpath,filename),'TTable','wind','noverlap','nfft','freqlow','freqhigh','imLength');
disp(['Created ' num2str(height(TTable)) ' Training Images']);

if nVCallsTotal > 0
    [filename,matpath] = uiputfile(fullfile(handles.data.squeakfolder,'Validation',[filename,'_ValImages.mat']));
    save(fullfile(matpath,filename),'VTable','wind','noverlap','nfft','freqlow','freqhigh','imLength');
    disp(['Created ' num2str(height(VTable)) ' Validation Images']);
end
end


% Create training images and boxes
function [im, sepbox] = CreateTrainingData(audio,rate,Calls,uniqLabels,wind,noverlap,nfft,freqlow,freqhigh,imgsize,filename,replicatenumber)
sepbox = [];
AmplitudeRange = [.5, 1.5];
%StretchRange = [0.75, 1.25];
% Order of current unaugmented FFT
nFFTexp = log(round(rate * nfft))/log(2);
% Limit FFT sizes to min of 16 and max of 131072 - can change if necessary
StretchRange = [max(nFFTexp - 2,4), min(nFFTexp+2,17)];
p = [];
nCountTries = 0;
while any(size(p) < 3) && nCountTries < 5
    nCountTries = nCountTries+1;
    % Augment by adjusting the gain
    % The first training image should not be augmented
    if replicatenumber > 1
        AmplitudeFactor = range(AmplitudeRange).*rand() + AmplitudeRange(1);
        StretchFactor = range(StretchRange).*rand() + StretchRange(1);
        thisnfft = round(2^StretchFactor);
        % Assume window == NFFT
        thiswind = thisnfft;
    else
        AmplitudeFactor = 1;
        thisnfft = nfft*rate;
        thiswind = wind*rate;
    end
    if width(audio)>height(audio)
        audio=audio';
    end
    
    thisnoverlap = noverlap/nfft;
    % Keep same overlap?
    thisnoverlap = round(thisnoverlap*thisnfft);
    
    if thisnoverlap >= thiswind
        warning('Overlap must be less than window size - automatically reducing to window size-1 (this may be due to data augmentation)')
        thisnoverlap = thiswind-1;
    end

    % Make the spectrogram
    [~, fr, ti, p] = spectrogram(audio(:,1),...
        thiswind,...
        thisnoverlap,...
        thisnfft,...
        rate,...
        'yaxis');

    if any(size(p) < 3)
        if replicatenumber == 1
            error('FFT settings suboptimal and causing losses in training data - recommend changing')
        else
            warning('Data augmentation exacerbating suboptimal FFT settings - recommend changing')
        end
    end
end

% If trying a different random augmentation adjustment didn't work
if any(size(p) < 3)
    error('FFT settings suboptimal and causing losses in training data - recommend changing')
end

upper_freq = find(fr>freqhigh,1,'first');
lower_freq = find(fr<freqlow,1,'last');
% Account for buffer overflow in either direction
if isempty(upper_freq)
    upper_freq = length(fr);
end
if isempty(lower_freq)
    lower_freq = 1;
end
p = p(lower_freq:upper_freq,:);
frlen = size(p,1);
tilen = size(p,2);

% -- convert power spectral density to [0 1]
p(p==0)=.01;
p = log10(p);
p = rescale(imcomplement(abs(p)));

% Create adjusted image from power spectral density
alf=.4*AmplitudeFactor;

% Create Adjusted Image for Identification
xTile=ceil(size(p,1)/50);
yTile=ceil(size(p,2)/50);
if xTile>1 && yTile>1
im = adapthisteq(flipud(p),'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',alf);
else
im = adapthisteq(flipud(p),'NumTiles',[2 2],'ClipLimit',.005,'Distribution','rayleigh','Alpha',alf);    
end

% resize images for 300x300 YOLO Network (Could be bigger but works nice)
targetSize = [imgsize imgsize];
sz=size(im);

%% MAKE SURE THESE COORDINATES ACCOUNT FOR FREQ TRIMMING
if ~isempty(Calls)
    % Find the box within the spectrogram
    x1 = axes2pix(length(ti), ti, Calls.Box(:,1));
    x2 = axes2pix(length(ti), ti, Calls.Box(:,3));
    y1 = axes2pix(length(fr), fr./1000, Calls.Box(:,2));
    y2 = axes2pix(length(fr), fr./1000, Calls.Box(:,4));
    % upper_freq should account for trim, lower freq should be accounted
    % for using frlen limits below
    box = ceil([x1, upper_freq-y1-y2, x2, y2]);

    % No zeros (must be at least 1)
    box(box <= 0) = 1;
    % start time index must be at least 1 less than (length of ti - 1)
    box(box(:,1) > tilen-2,1) = tilen-2;
    % 3+1 = right edge of box needs to be <= tilen (right edge of image)
    box((box(:,3)+box(:,1)) >= tilen,3) = tilen-1-box((box(:,3)+box(:,1)) >= tilen,1);
    % start freq index must be at least 1 less than (length of fr - 1)
    % actual axis of im = frlen-1 (frequencies must correspond
    % to between pixels not the pixels themselves)
    % First correct bandwidth (affected if shift freq); if becomes < 1
    % Reject Call
    box(box(:,2) > frlen-2,4) = box(box(:,2) > frlen-2,4)-(box(box(:,2) > frlen-2,2)-(frlen-2));
    Calls.Accept(box(:,4)<1) = 0;
    % Now correct starting freq
    box(box(:,2) > frlen-2,2) = frlen-2;
    % 4+2 = bandwidth of box needs to be <= frlen (bandwidth of image)
    % <= because actual axis of im = frlen-1 (frequencies must correspond
    % to between pixels not the pixels themselves)
    box((box(:,4)+box(:,2)) >= frlen,4) = frlen-1-box((box(:,4)+box(:,2)) >= frlen,2);

    % Remove calls we dropped because outside freq limits
    box = box(Calls.Accept == 1, :);
    Calls = Calls(Calls.Accept == 1,:);

    if ~isempty(box)
        box = bboxresize(box,targetSize./sz);
    
        if any((box(:,1)+box(:,3)) > imgsize,'all') || any((box(:,2)+box(:,4)) > imgsize,'all')
            error('Training image bounding indices still not working right - talk to Gabi')
        end
    
        sepbox = cell(1,length(uniqLabels));
        for i = 1:length(uniqLabels)
            sepbox{i} = {box(Calls.Type==uniqLabels{i},:)};
        end
    end
end

im = imresize(im,targetSize);
% Insert box for testing
% im = insertShape(im, 'rectangle', box);
imwrite(im, filename, 'BitDepth', 8);
end

% Function for splitting Calls into Bouts using gaps and imLength
% I thought I could do something really clever with this but ran into too
% many complicated problems, so until I'm feeling super clever with lots of
% free time (lol) I'm basically reverting this back to what it was
% originally by implementing "mingap"
function [bins] = SplitBouts(BoutCalls,imLength,mingap)
    % Initialize return value to all same bout
    bins = ones(height(BoutCalls),1);

    % Get all gaps between calls (if any)
    vGaps = zeros(1,height(BoutCalls));
    for i = 1:height(BoutCalls)
        allGaps = BoutCalls.Box(:,1)-(BoutCalls.Box(i, 1) + BoutCalls.Box(i, 3));
        % Negative => call overlaps or preceeds focus
        % call; set to zero to allow retrieval of relevant min
        allGaps = allGaps(allGaps > 0);
        if ~isempty(allGaps)
            % Get minimum gap between this call and all subsequent
            % calls
            vGaps(i) = min(allGaps);
        end
    end
    % Get rid of zeros (default) and any below mingap
    vGaps = vGaps(vGaps>mingap);
    
    % Duration of all incoming calls
    maxDur = max(BoutCalls.Box(:, 1) + BoutCalls.Box(:, 3))+BoutCalls.Box(1,1);
    % Max gap iterator (1 = max() which is about to happen, so skip)
    maxkval = 1;
    % While any sub-bout is > imLength, try to reduce using data
    % gaps
    while maxDur >= imLength
        if length(vGaps) < maxkval
            % No gaps left to split on
            return
        else
            % First pass
            if maxkval == 1
                % Set first max gap iterator to where gaps < imLength, but break if run
                % out of gaps
                gapReduce = max(vGaps);
                while gapReduce > imLength && length(vGaps) >= maxkval
                    gapReduce = maxk(vGaps,maxkval);
                    gapReduce = min(gapReduce);
                    % Increment max gap iterator
                    maxkval = maxkval+1;
                end
            else
                % Will split bout using the max gap selected with the next
                % max gap iterator
                gapReduce = maxk(vGaps,maxkval);
                gapReduce = min(gapReduce);
                % Increment max gap iterator
                maxkval = maxkval+1;
            end
        end
        Distance = pdist2(BoutCalls.Box(:, 1), BoutCalls.Box(:, 1) + BoutCalls.Box(:, 3));
        % Remove calls further apart than gapReduce
        Distance(Distance > gapReduce) = 0;

        % Create chuncks of audio file that contain non-overlapping call bouts
        bn=1;
        while bn<height(Distance)
            % For each row (beginning of call), find the last column (end of call)
            % following it within imLength (delineate this call bout)
            lst=find(Distance(bn,bn:end)>0,1,'last')+bn-1;
            % For every other call (beginning of call) in the call bout (within that imLength), delete
            % all the distances to calls beyond the call bout
            for ii=bn+1:lst
                Distance(ii,lst+1:end)=zeros(length(Distance(ii,lst+1:end)),1);
            end
            if isempty(lst)
                bn = bn+1;
            else
                bn = lst+1;
            end
        end
        
        % Identify & number call bouts
        G = graph(Distance,'upper');
        bins = conncomp(G);

        maxDur = 0;
        for bin = 1:length(unique(bins))
            binCalls = BoutCalls(bins == bin, :);
            
            %Center audio on middle of call bout and extract clip imLength in
            %length
            StartTime = max(min(binCalls.Box(:,1)), 0);
            FinishTime = max(binCalls.Box(:,1) + binCalls.Box(:,3));

            maxDur = max(maxDur,FinishTime-StartTime);
        end
    end
end

% % Function for calculating wiggle room for centering image on bout
% function [times] = BoutWiggles(Calls,bins,imLength)
%     nBins = length(unique(bins));
%     times = zeros(nBins,2);
%     AllStart = zeros(nBins,1);
%     AllFinish = zeros(nBins,1);
%     AllCenter = zeros(nBins,1);
%     for bin = 1:nBins
%         BoutCalls = Calls(bins == bin, :);
%         % Ideal Start/Finish/Center times if center on bout
%         StartTime = max(min(BoutCalls.Box(:,1)), 0);
%         FinishTime = max(BoutCalls.Box(:,1) + BoutCalls.Box(:,3));
%         AllCenter(bin) = (StartTime+(FinishTime-StartTime)/2);
% 
%         % Number of images we have to make to cover this whole bout,
%         % even if we have to split calls to do it
%         nDiv = ceil((FinishTime-StartTime)/imLength);
% 
%         % Get overall start of bout when using whole image sizes
%         % centered on entire bout
%         AllStart(bin) = CenterTime - (nDiv/2)*imLength;
%         AllFinish(bin) = CenterTime + (nDiv/2)*imLength;
%     end
% 
%     for bin = 1:nBins
%         bOvlp
%     end
% end


