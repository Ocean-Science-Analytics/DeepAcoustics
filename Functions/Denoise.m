function Denoise(handles)

%% Get FFT settings
if handles.data.settings.spect.nfft == 0
    handles.data.settings.spect.nfft = handles.data.settings.spect.nfftsmp/handles.data.audiodata.SampleRate;
    handles.data.settings.spect.windowsize = handles.data.settings.spect.windowsizesmp/handles.data.audiodata.SampleRate;
    handles.data.settings.spect.noverlap = handles.data.settings.spect.noverlap/handles.data.audiodata.SampleRate;
elseif handles.data.settings.spect.nfftsmp == 0
    handles.data.settings.spect.nfftsmp = handles.data.settings.spect.nfft*handles.data.audiodata.SampleRate;
    handles.data.settings.spect.windowsizesmp = handles.data.settings.spect.windowsize*handles.data.audiodata.SampleRate;
end
handles.data.saveSettings();
windowsize = round(handles.data.audiodata.SampleRate * handles.data.settings.spect.windowsize);
noverlap = round(handles.data.audiodata.SampleRate * handles.data.settings.spect.noverlap);
nfft = round(handles.data.audiodata.SampleRate * handles.data.settings.spect.nfft);

%% Get average spectrogram of entire wav file
h = waitbar(0,'Denoising');
window_stop = 0;
med_s = zeros(floor(nfft/2)+1,ceil(handles.data.audiodata.TotalSamples/handles.data.audiodata.SampleRate/handles.data.settings.pageSize));
ind_med_s = 1;
for i = 1:size(med_s,2)
    waitbar(i ./ size(med_s,2), h,'Averaging Spectra');
    window_start = window_stop;
    window_stop = window_start+handles.data.settings.pageSize;
    audio = handles.data.AudioSamples(window_start, window_stop);
    [s, ~, ~] = spectrogram(audio,windowsize,noverlap,nfft,handles.data.audiodata.SampleRate,'yaxis');
    s = scaleSpectrogram(s, handles.data.settings.spect.type, windowsize, handles.data.audiodata.SampleRate);
    med_s(:,ind_med_s) = median(s,2);
    ind_med_s = ind_med_s+1;
end
handles.data.medspec = median(med_s,2);
close(h);

handles.data.bDenoise = true;