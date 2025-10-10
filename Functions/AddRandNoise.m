function AddRandNoise(app,event,inpCallFile,freqlow,freqhigh,listCallTypes)
warning('This will save a temporary noise file to your Dets location. Cancel operation if you do not want this to happen!')

if nargin < 6
    listCallTypes = [];
end

if nargin == 2
    [detfile,detpath] = uigetfile('*.mat','Select detections.mat file to add noise samples to'); 
else
    [detpath,detfile,detext] = fileparts(inpCallFile);
    detfile = [detfile,detext];
end

[~, ~, handles] = convertToGUIDECallbackArguments(app, event);

% Initialize success flag
bNoiseSuccess = false;

% Load the dets file
[Calls,allAudio,spect,detection_metadata] = loadCallfile(fullfile(detpath,detfile),handles,false,listCallTypes);

if nargin == 2
    freqlow = max(detection_metadata.Settings(2)*1000,detection_metadata.Settings(3)*1000);
    freqhigh = min(detection_metadata.Settings(2)*1000,detection_metadata.Settings(3)*1000);
end

% For now, don't run if Noise already in file (can handle this differently
% in the future if desired)
if any(Calls.Type=='Noise')
    if nargin == 2
        error('Noise already in file')
    else
        warning('Noise already in file - skipping Random Noise generation')
        return
    end
end

% Noise size parameters (base on majority of signal box sizes/shapes)
%%% MAYBE USE RANDOM SELECTION OF ASPECT RATIO INSTEAD OF COMBINING RANDOM
%%% COMBOS OF DUR AND BW
NegMinDur = quantile(Calls.Box(:,3),0.05);
NegMaxDur = quantile(Calls.Box(:,3),0.95);
NegMinAR = quantile(Calls.Box(:,3)./Calls.Box(:,4),0.05);
NegMaxAR = quantile(Calls.Box(:,3)./Calls.Box(:,4),0.95);
NegMinBW = max(freqhigh-freqlow,quantile(Calls.Box(:,4),0.05));
NegMaxBW = min(freqhigh-freqlow,quantile(Calls.Box(:,4),0.95));

% Try to generate the same amount of Noise as signals if possible
nNumApproxNeg = height(Calls);
% Calculate space between all calls (relies on Calls being sorted by start
% time)
nSpace = zeros(1,height(Calls)+1);
nCallInd = 1;
nSpace2Add = 0;
for i = 1:height(allAudio)
    if nCallInd <= height(Calls) && strcmp(Calls.Audiodata(nCallInd).Filename,allAudio(i).Filename)
        % For first call in audio file, add space between beginning of
        % audio file and start of the call, and all the accumulated space
        % from audio files without calls before it
        nSpace(nCallInd) = nSpace(nCallInd) + Calls.Box(nCallInd,1) + nSpace2Add;
        % Reset accumulated space counter
        nSpace2Add = 0;
        % Start incrementing Calls index; for other calls in this file, add
        % to their Space allocations
        nCallInd = nCallInd+1;
        while nCallInd <= height(Calls) && strcmp(Calls.Audiodata(nCallInd).Filename,allAudio(i).Filename)
            nSpaceBW = Calls.Box(nCallInd,1)-(Calls.Box(nCallInd-1,1)+Calls.Box(nCallInd-1,3));
            % Only add gap if it exists (don't add negatives from
            % overlapping calls)
            nSpace(nCallInd) = nSpace(nCallInd)+max(0,nSpaceBW);
            nCallInd = nCallInd+1;
        end
        % For first call in next audiofile (or very last call), add space between end of audio file
        % and last call
        nSpaceBW = (allAudio(i).Duration-(Calls.Box(nCallInd-1,1)+Calls.Box(nCallInd-1,3)));
        % Don't add negative if a box goes off the end of the audio
        % (possible with dets annotated somewhere where audio can be
        % stitched together)
        nSpace(nCallInd) = nSpace(nCallInd) + max(0,nSpaceBW);
    else
        nSpace2Add = allAudio(i).Duration;
    end
end

dPropSpace = sum(nSpace)/sum([allAudio.Duration]);
if dPropSpace < 0.5
    warning('Calls take up more than half the audio, which means the proportion of Noise may not be 50:50')
end

% Initialize NoiseCalls
NoiseCalls = [];
% Number of successfully created noise samples
nNoiseSamps = 0;
% Number images processed for creating noise
nImgProcessed = 0;
% Call index we're at in time
nCallInd = 1;
% Very rough approximation of time until next call
nTimeUntilNextCall = nSpace(1);
for j = 1:length(allAudio)
    % Load the audio file
    audioReader = squeakData();
    audioReader.audiodata = allAudio(j);

    % Randomly set seed of random number generator
    rng("shuffle");

    FinishTime = 0;
    % Check for space to write a negative image
    while (audioReader.audiodata.Duration-FinishTime) > NegMaxDur
        % Set start time of this image and increment FinishTime, so now
        % FinishTime is end time of this image (and start time of next)
        NegStTime = FinishTime;
        FinishTime = FinishTime+NegMaxDur;

        % Calculate how much we want to make a noise sample out of each image
        % (this will go inside next loop)
        % I.e., we want the proportion of noise that we still need to make
        nNoiseLeft = nNumApproxNeg-nNoiseSamps;

        % Account for amount of space left taken up by calls (to help balance
        % noise, otherwise the proportion of noise needed will probably
        % increase as we go when we can't make noise bc of calls)
        % Track about where in Calls we're at
        vCallsThisFile = find(strcmp({Calls.Audiodata.Filename},audioReader.audiodata.Filename));
        if ~isempty(vCallsThisFile)
            vCallSts = Calls.Box(vCallsThisFile,1);
            % If index of next call has changed, reset nTimeUntilNextCall
            % (won't be exactly accurate because won't account for the time
            % in the current image, but should be close enough)
            % for nSpaceLeft calculation
            if nCallInd ~= min(vCallsThisFile(vCallSts >= NegStTime))
                nCallInd = min(vCallsThisFile(vCallSts >= NegStTime));
                nTimeUntilNextCall = nSpace(nCallInd);
            end
        end
        
        % Note this is accounting for time dimension only
        nSpaceLeft = nSpace(nCallInd:end);
        nSpaceLeft(nCallInd) = max(0,nTimeUntilNextCall);
        % nSpace(nCallInd) is the space available before nCallInd, which is
        % being eaten away by nTimeSinceLastCall, so have to subtract, but
        % adding max(0,X) to account for any endpoint miscalculation on my
        % part that may introduce a negative (should be close enough)
        nSpaceLeft = max(0,floor(sum(nSpaceLeft)/NegMaxDur));
        dPropLeft = min(1,nNoiseLeft/nSpaceLeft);
                        
        % Randomly decide to make image or not
        if rand <= dPropLeft
            % Try nTries times to make a nonoverlapping box before moving
            % to next image
            nTries = 3;
            for i = 1:nTries
                % Random duration based on Calls range of sizes
                NegDur = rand*(NegMaxDur-NegMinDur)+NegMinDur;
                NegAR = rand*(NegMaxAR-NegMinAR)+NegMinAR;
                NegTSt = rand*(FinishTime-NegDur-NegStTime)+NegStTime;
                freqNyq = floor(audioReader.audiodata.SampleRate/2)/1000;
                NegBW = NegDur/NegAR;
                % In case aspect ratio not doing a great job
                if NegBW>=(freqhigh-freqlow)
                    NegBW = rand*(NegMaxBW-NegMinBW)+NegMinBW;
                end
                % freqhigh-NegBW is the highest possible starting freq
                % freqlow is the lowest possible starting freq
                % so starting freq is anywhere between those two extremes
                NegFSt = rand*(freqhigh-NegBW-freqlow)+freqlow;
                NegBox = [NegTSt,NegFSt,NegDur,NegBW];
                % Sanity check
                if NegTSt < 0 || (NegTSt+NegDur) > audioReader.audiodata.Duration || ...
                        NegFSt <= 0 || (NegFSt+NegBW) > freqNyq
                    error('Problem automatically generating Noise - talk to GA (DA tech support)')
                end
    
                %%%% MAKE SURE NOISE DOES NOT OVERLAP WITH A CALL BEFORE
                %%%% PROCEEDING
                vCallOvlp = bboxOverlapRatio([Calls.Box(vCallsThisFile,:)],NegBox);
                if ~any(vCallOvlp)
                    NoiseCalls_tmp = table(NegBox,1,1,categorical({'Noise'}),audioReader.audiodata,'VariableNames',{'Box','Score','Accept','Type','Audiodata'});
                    NoiseCalls = [NoiseCalls; NoiseCalls_tmp];
        
                    bNoiseSuccess = true;
                    nNoiseSamps = nNoiseSamps + 1;
                    % Break Try for loop if successful
                    break
                end
            end
        end
        nImgProcessed = nImgProcessed + 1;
        % Approach next call
        nTimeUntilNextCall = nTimeUntilNextCall-NegMaxDur;
    end
end

if ~bNoiseSuccess
    if nargin == 2
        error('There was not enough room between Calls to generate Noise')
    else
        warning('There was not enough room between Calls to generate Noise')
    end
else
    CallsBU = Calls;
    Calls = NoiseCalls;
    % Unique call ID for noise calls
    Calls.CallID = categorical(arrayfun(@(x) ['N' num2str(x)],1:height(Calls),'UniformOutput',false))';
    % Temporarily save Noise file so can loadCallFile() which will clean
    % things up (probably not the most efficient thing ever, but will do
    % for now)
    save(fullfile(detpath,'TempNoiseCalls.mat'),'Calls','allAudio','detection_metadata','spect');
    [NoiseCalls] = loadCallfile(fullfile(detpath,'TempNoiseCalls.mat'),handles,false);
    delete(fullfile(detpath,'TempNoiseCalls.mat'));
    % Merge
    Calls = [CallsBU; NoiseCalls];
    % Sort Calls after adding Noise
    Calls = SortCalls(Calls,'time');
    % Save new file!
    if nargin == 2
        [outfile,outpath] = uiputfile('*.mat','Save New Dets w Noise File');
    else
        % Overwrite existing det file if running from Create Training
        % Images
        outfile = detfile;
        outpath = detpath;
    end
    save(fullfile(outpath,outfile),'Calls','allAudio','detection_metadata','spect');
end