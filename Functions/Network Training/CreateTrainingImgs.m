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
metadata.minfreq = Inf;
metadata.maxfreq = 0;
metadata.minSR = Inf;
metadata.maxSR = 0;

h = waitbar(0,'Loading Call File(s)');
for k = 1:length(trainingdata)
    % Load the detection and audio files
    [Calls] = loadCallfile([trainingpath trainingdata{k}],handles,false);
    
    % Duration
    if min([Calls.Box(:,3)]) < metadata.mindur
        metadata.mindur = min([Calls.Box(:,3)]);
    end
    if max([Calls.Box(:,3)]) > metadata.maxdur
        metadata.maxdur = max([Calls.Box(:,3)]);
    end

    % Frequency
    if min([Calls.Box(:,2)]+[Calls.Box(:,4)]) < metadata.minfreq
        metadata.minfreq = min([Calls.Box(:,2)]+[Calls.Box(:,4)]);
    end
    if max([Calls.Box(:,2)]+[Calls.Box(:,4)]) > metadata.maxfreq
        metadata.maxfreq = max([Calls.Box(:,2)]+[Calls.Box(:,4)]);
    end

    % SR
    if min([Calls.Audiodata.SampleRate]) < metadata.minSR
        metadata.minSR = min([Calls.Audiodata.SampleRate]);
    end
    if max([Calls.Audiodata.SampleRate]) > metadata.maxSR
        metadata.maxSR = max([Calls.Audiodata.SampleRate]);
    end
    waitbar(k/length(trainingdata), h, sprintf('Loading File %g of %g', k, length(trainingdata))); 
end
close(h)

app.RunTrainImgDlg(handles.data.settings.spect, metadata);

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

imLength = app.TrainImgSettings.imLength;
repeats = app.TrainImgSettings.repeats+1;

% If augmented duplicates, create a directory to separate out augmented
% images
if repeats > 1
    status = mkdir(fullfile(strImgDir,'ImgAug'));
    if ~status
        warning('Problem making default Augmented Images directory')
    end
end

TTable = table({},{},{},'VariableNames',{'bAug','imageFilename','Call'});
for k = 1:length(trainingdata)
    % Load the detection and audio files
    audioReader = squeakData();
    % Only need to re-load from the beginning if multiple Call files,
    % otherwise already loaded!
    if length(trainingdata) > 1
        [Calls] = loadCallfile([trainingpath trainingdata{k}],handles,false);
    end
    allAudio = unique({Calls.Audiodata.Filename},'stable');
    
    % Remove Rejects
    Calls = Calls(Calls.Accept == 1, :);

    for j = 1:length(allAudio)
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

        % Find max call frequency for cutoff
        % freqCutoff = max(sum(Calls.Box(:,[2,4]), 2));
        % freqCutoff = subCalls.Audiodata(1).SampleRate / 2;
        
        %% Calculate Groups of Calls
        % Calculate the distance between the end of each box and the
        % beginning of the next
        Distance = pdist2(subCalls.Box(:, 1), subCalls.Box(:, 1) + subCalls.Box(:, 3));
        % Remove calls further apart than the bin size
        Distance(Distance > imLength) = 0;
        % Get the indices of the calls by bout number by using the connected
        % components of the graph
        
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
        
        for bin = 1:length(unique(bins))
            BoutCalls = subCalls(bins == bin, :);
            
            %Center audio on middle of call bout and extract clip imLength in
            %length
            StartTime = max(min(BoutCalls.Box(:,1)), 0);
            FinishTime = max(BoutCalls.Box(:,1) + BoutCalls.Box(:,3));
            CenterTime = (StartTime+(FinishTime-StartTime)/2);
            StartTime = CenterTime - (imLength/2);
            FinishTime = CenterTime + (imLength/2);
    
            %% Read Audio
            audio = audioReader.AudioSamples(StartTime, FinishTime);
            
            % Subtract the start of the bout from the box times
            BoutCalls.Box(:,1) = BoutCalls.Box(:,1) - StartTime;
            
            % If imLength < duration of a call, beginning and/or end will clip!
            % Clip beg of call
            if any(BoutCalls.Box(:,1) < 0)
                warning("Your Image Length is probably too low - beg of call not captured")
                % Adjust duration accordingly
                BoutCalls.Box(BoutCalls.Box(:,1) < 0,3) = BoutCalls.Box(BoutCalls.Box(:,1) < 0,3) + BoutCalls.Box(BoutCalls.Box(:,1) < 0,1);
                BoutCalls.Box(BoutCalls.Box(:,1) < 0,1) = 0;
            end
            
            % Clip end of call
            if any((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) > imLength)
                warning("Your Image Length is probably too low - end of call not captured")
                BoutCalls.Box((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) > imLength, 3) = imLength-BoutCalls.Box((BoutCalls.Box(:,1)+BoutCalls.Box(:,3)) > imLength, 1);
            end
            
            try
                for replicatenumber = 1:repeats
                    IMname = sprintf('%g_%g_%g_%g.png', k, j, bin, replicatenumber);
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
                        wind,noverlap,nfft,...
                        ffn,...
                        replicatenumber);  
                    TTable = [TTable;{bAug, ffn, box}];
                end
            catch
                disp("Something wrong with calculating bounding box indices - talk to Gabi!");
            end
            waitbar(bin/length(unique(bins)), h, sprintf('Processing Det File %g of %g Aud File %g of %g', k, length(trainingdata), j, length(allAudio)));         
        end
    end
end
close(h)

%matpath = uigetdir(fullfile(handles.data.squeakfolder,'Training'),'Select Directory to Save Images.mat');
%pathtodet = fullfile(trainingpath,trainingdata{k});
%save(fullfile(matpath,[filename '_Images.mat']),'TTable','wind','noverlap','nfft','imLength','pathtodet');
[filename,matpath] = uiputfile(fullfile(handles.data.squeakfolder,'Training',[filename,'_Images.mat']));
save(fullfile(matpath,filename),'TTable','wind','noverlap','nfft','imLength');
%save(fullfile(handles.data.squeakfolder,'Training',[filename '_Images.mat']),'TTable','wind','noverlap','nfft','imLength');
disp(['Created ' num2str(height(TTable)) ' Training Images']);
end


% Create training images and boxes
function [im, box] = CreateTrainingData(audio,rate,Calls,wind,noverlap,nfft,filename,replicatenumber)
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
    else
        AmplitudeFactor = 1;
        StretchFactor = nFFTexp;
    end
    if width(audio)>height(audio)
        audio=audio';
    end
    
    %thiswind = round(rate * wind*StretchFactor);
    %thisnfft = round(rate * nfft*StretchFactor);
    thisnoverlap = noverlap/nfft;
    thisnfft = round(2^StretchFactor);
    % Assume window == NFFT
    thiswind = thisnfft;
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

% -- remove frequencies below well outside of the box
% GA: Removing this because I think it removes informative noise from
% images and even if it did make sense, it doesn't make sense to do it on the low freq end and not the
% high freq end
% lowCut=(min(Calls.Box(:,2))-(min(Calls.Box(:,2))*.75))*1000;
% min_freq  = find(fr>lowCut);
% p = p(min_freq,:);


% % Add brown noise to adjust the amplitude
% if replicatenumber > 1
%     AmplitudeFactor = spatialPattern(size(p), -3);
%     AmplitudeFactor = AmplitudeFactor ./ std(AmplitudeFactor, [], 'all');
%     AmplitudeFactor = AmplitudeFactor .* range(AmplitudeRange) ./ 2 + mean(AmplitudeRange);
% end
% im = log10(p);
% im = (im - mean(im, 'all')) * std(im, [],'all');
% im = rescale(im + AmplitudeFactor .* im.^3 ./ (im.^2+2), 'InputMin',-1 ,'InputMax', 5);


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

% Find the box within the spectrogram
x1 = axes2pix(length(ti), ti, Calls.Box(:,1));
x2 = axes2pix(length(ti), ti, Calls.Box(:,3));
y1 = axes2pix(length(fr), fr./1000, Calls.Box(:,2));
y2 = axes2pix(length(fr), fr./1000, Calls.Box(:,4));
box = ceil([x1, length(fr)-y1-y2, x2, y2]);
box = box(Calls.Accept == 1, :);
% No zeros (must be at least 1)
box(box <= 0) = 1;
% start time index must be at least 1 less than (length of ti - 1)
box(box(:,1) > length(ti)-2,1) = length(ti)-2;
% 3+1 = right edge of box needs to be <= length(ti) (right edge of image)
box((box(:,3)+box(:,1)) >= length(ti),3) = length(ti)-1-box((box(:,3)+box(:,1)) >= length(ti),1);
% start freq index must be at least 1 less than (length of fr - 1)
% actual axis of im = length(fr)-1 (frequencies must correspond
% to between pixels not the pixels themselves)
box(box(:,2) > length(fr)-2,2) = length(fr)-2;
% 4+2 = bottom edge of box needs to be <= length(fr) (bottom edge of image)
% <= because actual axis of im = length(fr)-1 (frequencies must correspond
% to between pixels not the pixels themselves)
box((box(:,4)+box(:,2)) >= length(fr),4) = length(fr)-1-box((box(:,4)+box(:,2)) >= length(fr),2);

% resize images for 300x300 YOLO Network (Could be bigger but works nice)
targetSize = [300 300];
sz=size(im);
im = imresize(im,targetSize);
box = bboxresize(box,targetSize./sz);

if any((box(:,1)+box(:,3)) > 300,'all') || any((box(:,2)+box(:,4)) > 300,'all')
    error('Training image bounding indices still not working right - talk to Gabi')
end

% Insert box for testing
% im = insertShape(im, 'rectangle', box);
imwrite(im, filename, 'BitDepth', 8);
end
