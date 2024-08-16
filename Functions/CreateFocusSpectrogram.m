function [I,windowsize,noverlap,nfft,rate,box,s,fr,ti,audio,p] = CreateFocusSpectrogram(call, handles, make_spectrogram, options)
%% Extract call features for CalculateStats and display

if nargin < 3
    make_spectrogram = true;
end

rate = call.Audiodata.SampleRate;

if nargin < 4 || isempty(options)
%     yRange = mean(call.Box(1,4));
%     xRange = mean(call.Box(1,3));
%     noverlap = .5;
%     optimalWindow = sqrt(xRange/(2000*yRange));
%     optimalWindow = optimalWindow + optimalWindow.*noverlap;
    options = struct;
%     options.windowsize = optimalWindow;
%     options.overlap = optimalWindow .* noverlap;
%     options.nfft = optimalWindow;
    options.frequency_padding = 0;
    if handles.data.settings.spect.nfft == 0
        handles.data.settings.spect.nfft = handles.data.settings.spect.nfftsmp/rate;
        handles.data.settings.spect.windowsize = handles.data.settings.spect.windowsizesmp/rate;
        handles.data.settings.spect.noverlap = handles.data.settings.spect.noverlap/rate;
    elseif handles.data.settings.spect.nfftsmp == 0
        handles.data.settings.spect.nfftsmp = handles.data.settings.spect.nfft*rate;
        handles.data.settings.spect.windowsizesmp = handles.data.settings.spect.windowsize*rate;
    end
    handles.data.saveSettings();
    options.nfft = handles.data.settings.spect.nfft;
    options.overlap = handles.data.settings.spect.noverlap;
    options.windowsize = handles.data.settings.spect.windowsize;
    options.freq_range = [];
end

box = call.Box;

if isfield(options, 'freq_range') && ~isempty(options.freq_range)
    box(2) = options.freq_range(1);
    box(4) = options.freq_range(2) - options.freq_range(1);
end

if (1/options.nfft > (box(4)*1000))
    warning('%s\n%s\n','Spectrogram settings may not be ideal for this call - suggest adjusting Display Settings and increasing NFFT')
end

windowsize = round(rate * options.windowsize);
noverlap = round(rate * options.overlap);
nfft = round(rate * options.nfft);
    
if make_spectrogram
    audioreader = squeakData([]);
    audioreader.audiodata = call.Audiodata;
    audio = audioreader.AudioSamples(box(1), box(1) + box(3));
    if (length(audio) < min([windowsize,noverlap,nfft]))
        warning('Call too short to generate spectrogram, returning empty')
        I = [];
        s = [];
        fr = [];
        ti = [];
        p = [];
        return
    end
    [s, fr, ti, p] = spectrogram(audio,windowsize,noverlap,nfft,rate,'yaxis');
else
    indbox = handles.data.page_spect.t > call.Box(1) & handles.data.page_spect.t < sum(call.Box([1,3]));
    % if spect resolution issues, warning and adjust box so enough dims to
    % function
    if sum(indbox)==1
        % If last index is 1, make index before it also 1
        if indbox(end)
            indbox(end-1) = 1;
        else
            indbox(find(indbox)+1) = 1;
        end
        warning('%s\n%s\n','Recommend decreasing FFT size in Display Settings')
    end
    s  = handles.data.page_spect.s(:,indbox);
    ti = handles.data.page_spect.t(indbox);
    fr = handles.data.page_spect.f;
    p = (1/(rate*(hamming(nfft)'*hamming(nfft))))*abs(s).^2;
    p(2:end-1,:) = p(2:end-1,:).*2;
end
    
%% Get the part of the spectrogram within the box
x1 = 1;
x2 = length(ti);

min_freq = find(fr./1000 >= box(2) - options.frequency_padding,1);
min_freq = max(min_freq-1, 1);

max_freq = find(fr./1000 <= box(4) + box(2) + options.frequency_padding, 1, 'last');
max_freq = min(round(max_freq)+1, length(fr));

I=abs(s(min_freq:max_freq,x1:x2));

if isempty(I)
    error('Something wrong with box')
end

%Save for later - update that saves only boxed call
%p=p(min_freq:max_freq,x1:x2);
end