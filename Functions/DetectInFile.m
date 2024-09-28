function  Calls=DetectInFile(inputfile,networkfile,Settings,currentFile,totalFiles)
% Find Squeaks
Calls = table();
h = waitbar(0,'Initializing');

% Get the audio info
audio_info = audioinfo(inputfile);

if audio_info.NumChannels > 1
    warning('Audio file contains more than one channel. Detection will use the mean of all channels.')
end

% Get network and spectrogram settings
network=networkfile.detector;
wind=networkfile.wind;
noverlap=networkfile.noverlap;
nfft=networkfile.nfft;

% Adjust settings, so spectrograms are the same for different sample rates
wind = round(wind * audio_info.SampleRate);
noverlap = round(noverlap * audio_info.SampleRate);
nfft = round(nfft * audio_info.SampleRate);

%% Get settings
% (1) Detection length (s)
if Settings(1)>audio_info.Duration
    DetectLength=audio_info.Duration;
    [~,fname,fext] = fileparts(inputfile);
    fname = [fname fext];
    disp([fname ' is shorter then the requested analysis duration. Only the first ' num2str(audio_info.Duration) ' will be processed.'])
elseif Settings(1)==0
    DetectLength=audio_info.Duration;
else
    DetectLength=Settings(1);
end

%Detection chunk size (s)
chunksize=networkfile.imLength*.8;

%Overlap between chucks (s)
overlap=networkfile.imLength*.2;

% Switched high- and low-freq cutoff order in dialog, but should be back
% compatible
% (2) High frequency cutoff (kHz)
HighCutoff = max(Settings(2),Settings(3));
if audio_info.SampleRate < (HighCutoff*1000)*2
    disp('Warning: Upper frequency is above sampling rate / 2. Lowering it to the Nyquist frequency.');
    HighCutoff=floor(audio_info.SampleRate/2)/1000;
end

% (3) Low frequency cutoff (kHz)
LowCutoff = min(Settings(2),Settings(3));

% (4) Score cutoff (kHz)
score_cutoff=Settings(4);

%% Detect Calls
% Initialize variables
AllBoxes=[];
AllScores=[];
AllClass=[];

% Break the audio file into chunks
chunks = linspace(1,(DetectLength - overlap) * audio_info.SampleRate,round(DetectLength / chunksize));
for i = 1:length(chunks)-1
    try
        DetectStart = tic;
        
        % Get the audio windows
        windL = chunks(i);
        windR = chunks(i+1) + overlap*audio_info.SampleRate;
        
        % Read the audio
        audio = audioread(audio_info.Filename,double(floor([windL, windR])));
        
        %% Mix multichannel audio:
        % By default, take the mean of multichannel audio.
        % Another method could be to take the max of the multiple channels,
        % or just take the first channel.
        audio = audio - mean(audio,1);
        switch 'mean'
            case 'first'
                audio = audio(:,1);
            case 'mean'
                audio = mean(audio,2);
            case 'max'
                [~,index] = max(abs(audio'));
                audio = audio(sub2ind(size(audio),1:size(audio,1),index));
        end

        % Create spectrogram out of audio segment
        [~,fr,ti,p] = spectrogram(audio(:,1),wind,noverlap,nfft,audio_info.SampleRate,'yaxis'); % Just use the first audio channel
        % Air on the side of generosity with the bin cut-offs given
        % spectrogram settings
        upper_freq = find(fr>HighCutoff*1000,1,'first');
        lower_freq = find(fr<LowCutoff*1000,1,'last');
        % Account for buffer overflow in either direction
        if isempty(upper_freq)
            upper_freq = length(fr);
        end
        if isempty(lower_freq)
            lower_freq = 1;
        end
        if i==1
            disp(['Freq cut-offs (given spec settings) set to ' num2str(fr(lower_freq)) ' Hz and ' num2str(fr(upper_freq)) ' Hz']);
        end
        pow = p(lower_freq:upper_freq,:);
        
        [nbboxes, scores, Class] = DetectChunk(fr,ti,pow,network);

        % Convert boxes from pixels to time and kHz
        bboxes = [];
        bboxes(:,1) = ti(nbboxes(:,1)) + (windL ./ audio_info.SampleRate);
        bboxes(:,2) = fr(upper_freq - (nbboxes(:,2) + nbboxes(:,4))) ./ 1000;
        bboxes(:,3) = ti(nbboxes(:,3));
        %bboxes(:,4) = fr(nbboxes(:,4)) ./ 1000;
        binwidth = (fr(2)-fr(1)) ./ 1000;
        bboxes(:,4) = single(nbboxes(:,4)).*binwidth;
        
        % Concatenate the results
        AllBoxes=[AllBoxes
            bboxes];
        AllScores=[AllScores
            scores];
        AllClass=[AllClass
            Class];
        
        t = toc(DetectStart);
        waitbar(...
            i/(length(chunks)-1),...
            h,...
            sprintf(['Detection Speed: ' num2str((chunksize + overlap) / t,'%.1f') 'x  Call Fragments Found:' num2str(length(AllBoxes(:,1)),'%.0f') '\n File ' num2str(currentFile) ' of ' num2str(totalFiles)]));
        
    catch ME
        waitbar(...
            i/(length(chunks)-1),...
            h,...
            sprintf('Error in Network, Skiping Audio Chunk'));
        disp('Error in Network, Why Broken?');
        warning( getReport( ME, 'extended', 'hyperlinks', 'on' ) );
    end
end
% Return is nothing was found
if isempty(AllScores); close(h); return; end

h = waitbar(1,h,'Merging Boxes...');
DetSpect.wind = networkfile.wind;
DetSpect.noverlap = networkfile.noverlap;
DetSpect.nfft = networkfile.nfft;
Calls = merge_boxes(AllBoxes, AllScores, AllClass, DetSpect, 1, score_cutoff, 0, audio_info);
close(h);
end


