function [I,windowsize,noverlap,nfft,rate,box,s,fr,ti,audio,p] = CreateFocusSpectrogram(call, DAdata, make_spectrogram, nTimePad, bClipSpect)
%% Extract call features for CalculateStats and display

if nargin < 3
    make_spectrogram = true;
    nTimePad = 0;
elseif nargin == 3 || ~make_spectrogram
    nTimePad = 0;
end

rate = call.Audiodata.SampleRate;

if DAdata.settings.spect.nfft == 0
    DAdata.settings.spect.nfft = DAdata.settings.spect.nfftsmp/rate;
    DAdata.settings.spect.windowsize = DAdata.settings.spect.windowsizesmp/rate;
    DAdata.settings.spect.noverlap = DAdata.settings.spect.noverlap/rate;
elseif DAdata.settings.spect.nfftsmp == 0
    DAdata.settings.spect.nfftsmp = DAdata.settings.spect.nfft*rate;
    DAdata.settings.spect.windowsizesmp = DAdata.settings.spect.windowsize*rate;
end
DAdata.saveSettings();

box = call.Box;

if (1/DAdata.settings.spect.nfft > (box(4)*1000))
    warning('%s\n%s\n','Spectrogram settings may not be ideal for this call - suggest adjusting Display Settings')
end

windowsize = round(rate * DAdata.settings.spect.windowsize);
noverlap = round(rate * DAdata.settings.spect.noverlap);
nfft = round(rate * DAdata.settings.spect.nfft);
    
if make_spectrogram
    audioreader = squeakData([]);
    audioreader.audiodata = call.Audiodata;
    audio = audioreader.AudioSamples(box(1)-nTimePad, box(1) + box(3)+nTimePad);
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
    audio = [];
    indbox = DAdata.page_spect.t > call.Box(1) & DAdata.page_spect.t < sum(call.Box([1,3]));
    % if spect resolution issues, warning and adjust box so enough dims to
    % function
    if sum(indbox)<=1
        % Really bad spect settings - find the closest time slice to start
        % of box to claim one time slice for the call
        if sum(indbox) == 0
            [~,indflag] = min(abs(DAdata.page_spect.t-call.Box(1)));
            indbox(indflag) = true;
        end
        % Once only one time slice claimed for call, expand to 2 for display and warn
        % user
        % If last index is 1, make index before it also 1
        if indbox(end)
            indbox(end-1) = 1;
        else
            indbox(find(indbox)+1) = 1;
        end
        warning('%s\n%s\n','Recommend decreasing FFT size in Display Settings')
    end
    s  = DAdata.page_spect.s_display(:,indbox);
    ti = DAdata.page_spect.t(indbox);
    fr = DAdata.page_spect.f;
    p = (1/(rate*(hamming(nfft)'*hamming(nfft))))*abs(s).^2;
    p(2:end-1,:) = p(2:end-1,:).*2;
end
    
%% Get the part of the spectrogram within the box
x1 = 1;
x2 = length(ti);

min_freq = find(fr./1000 >= box(2),1);
min_freq = max(min_freq-1, 1);

max_freq = find(fr./1000 <= box(4) + box(2), 1, 'last');
max_freq = min(round(max_freq)+1, length(fr));

I=abs(s(min_freq:max_freq,x1:x2));

if isempty(I)
    error('Something wrong with box')
end

%Save for later - update that saves only boxed call
if nargin == 5 && bClipSpect
    p=p(min_freq:max_freq,x1:x2);
end