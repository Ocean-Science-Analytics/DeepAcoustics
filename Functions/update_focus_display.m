function handles = update_focus_display(handles)

if ~isempty(handles.current_detection_file)
    set(handles.displayfile,'String',char(handles.current_detection_file))
else
    set(handles.displayfile,'String','')
end

[~,audiofn,audioext] = fileparts({handles.data.allAudio.Filename});
audiofn = strcat(audiofn,audioext);
set(handles.dropdownAudFile,'String',audiofn);

% Set current audio dropdown
set(handles.dropdownAudFile,'Value',handles.data.thisAllAudind);

set(handles.dropdownAudFile,'Visible','on');
set(handles.dropdownAudFile,'Enable','on');

% Values for the spectrogram are already calculated in renderEpochSpectrogram
s_f  = handles.data.page_spect.s_display(:,handles.data.page_spect.t > handles.current_focus_position(1) & handles.data.page_spect.t < sum(handles.current_focus_position([1,3])));
ti_f = handles.data.page_spect.t(handles.data.page_spect.t > handles.current_focus_position(1) & handles.data.page_spect.t < sum(handles.current_focus_position([1,3])));
fr_f = handles.data.page_spect.f;

% Plot Spectrogram
set(handles.spect,'CData',s_f,'XData', ti_f,'YData',fr_f/1000);
handles.data.settings.HighFreq = min(handles.data.settings.HighFreq, handles.data.audiodata.SampleRate/2000);
set(handles.focusWindow,...
    'Xlim', [handles.current_focus_position(1), handles.current_focus_position(1) + handles.current_focus_position(3)],...
    'Ylim',[handles.data.settings.LowFreq, handles.data.settings.HighFreq]);

if isempty(handles.data.calls) 
    return
end
% If StTime exists as a variable, and there are calls to display, and the
% contents of StTime are datetime format, set start time of the file to the StTime of
% the first call in the audio file - the # of seconds into file the call is
if any(strcmp('StTime', handles.data.calls.Properties.VariableNames)) && ...
        ~isempty(handles.data.thisaudst) && ~isempty(handles.data.thisaudend) && ...
        isa(handles.data.calls.StTime(handles.data.thisaudst),'datetime') && ...
        ~isnat(handles.data.calls.StTime(handles.data.thisaudst))
    sttime = handles.data.calls.StTime(handles.data.thisaudst) - handles.data.calls.Box(handles.data.thisaudst,1)/86400;
else
    sttime = 0;
end
%Update spectrogram ticks and transform labels to
%minutes:seconds.milliseconds
set_tick_timestamps(handles.focusWindow, true, sttime);

% Don't update the call info the there aren't any calls in the page view
% Subset of calls restricted to current audio file
subCalls = handles.data.calls(strcmp({handles.data.calls.Audiodata.Filename},handles.data.audiodata.Filename),:);
if isempty(subCalls) || handles.data.currentcall == 0 || ~any(handles.data.calls.Box(handles.data.currentcall,1) > ti_f(1) &...
        sum(handles.data.calls.Box(handles.data.currentcall,[1,3]),2) < ti_f(end))
    return
end

% If a call was not saved with an Entropy or Amplitude threshold, apply
% global settings to that call
if ~any(strcmp('EntThresh',handles.data.calls.Properties.VariableNames)) || ...
    isempty(handles.data.calls.EntThresh(handles.data.currentcall)) || ...
    handles.data.calls.EntThresh(handles.data.currentcall) == 0
    
    handles.data.calls.EntThresh(handles.data.currentcall) = handles.data.settings.EntropyThreshold;
end
if ~any(strcmp('AmpThresh',handles.data.calls.Properties.VariableNames)) || ...
    isempty(handles.data.calls.AmpThresh(handles.data.currentcall)) || ...
    handles.data.calls.AmpThresh(handles.data.currentcall) == 0

    handles.data.calls.AmpThresh(handles.data.currentcall) = handles.data.settings.AmplitudeThreshold;
end

% Set the sliders to the saved values
set(handles.TonalitySlider, 'Value', handles.data.calls.EntThresh(handles.data.currentcall));

[I,windowsize,noverlap,nfft,rate,box,~,~,~] = CreateFocusSpectrogram(handles.data.calls(handles.data.currentcall,:),handles.data,false);

stats = CalculateStats(I,windowsize,noverlap,nfft,rate,box,handles.data.calls.EntThresh(handles.data.currentcall),handles.data.calls.AmpThresh(handles.data.currentcall));

% plot Ridge Detection
set(handles.ContourScatter,'XData',stats.ridgeTime','YData',stats.ridgeFreq_smooth);
set(handles.contourWindow,'Xlim',[1 size(I,2)],'Ylim',[1 size(I,1)]);

% Plot Slope
X = [ones(size(stats.ridgeTime)); stats.ridgeTime]';
ls = X \ (stats.ridgeFreq_smooth);
handles.ContourLine.XData = [1 size(I,2)];
handles.ContourLine.YData = [ls(1), ls(1) + ls(2) * size(I,2)];

% Update call statistics text
set(handles.GoToCall,'Value',handles.data.currentcall);
set(handles.GoToCallTotal,'String',['/' num2str(height(handles.data.calls))]);

set(handles.score,'String',['Score: ' num2str(handles.data.calls.Score(handles.data.currentcall))]);
if any(strcmp('Ovlp', handles.data.calls.Properties.VariableNames))
    set(handles.ovlp,'String',['Ovlp: ' num2str(handles.data.calls.Ovlp(handles.data.currentcall))]);
else
    set(handles.ovlp,'String','Ovlp: N/A')
end
if handles.data.calls.Accept(handles.data.currentcall)
    set(handles.status,'String','Accepted');
    set(handles.status,'ForegroundColor',[0,1,0]); 
else
    set(handles.status,'String','Rejected');
    set(handles.status,'ForegroundColor',[1,0,0])       
end
if any(strcmp('CallID', handles.data.calls.Properties.VariableNames))
    set(handles.text19,'String',['User ID: ' char(handles.data.calls.CallID(handles.data.currentcall))]);
else
    set(handles.text19,'String','User ID: N/A');
end
set(handles.text36,'String',['Label: ' char(handles.data.calls.Type(handles.data.currentcall))]);
if any(strcmp('ClustCat', handles.data.calls.Properties.VariableNames))
    set(handles.text37,'String',['Clust Assign: ' char(handles.data.calls.ClustCat(handles.data.currentcall))]);
else
    set(handles.text37,'String','Clust Assign: N/A');
end
set(handles.freq,'String',['Frequency: ' num2str(stats.PrincipalFreq,'%.1f') ' kHz']);
set(handles.slope,'String',['Slope: ' num2str(stats.Slope,'%.3f') ' kHz/s']);
set(handles.duration,'String',['Duration: ' num2str(stats.DeltaTime*1000,'%.0f') ' ms']);
set(handles.sinuosity,'String',['Sinuosity: ' num2str(stats.Sinuosity,'%.4f')]);
set(handles.powertext,'String',['Rel Pwr: ' num2str(stats.MeanPower) ' dB/Hz']);
set(handles.tonalitytext,'String',['Tonality: ' num2str(stats.SignalToNoise,'%.4f')]);
% Waveform
PlotAudio = handles.data.AudioSamples(handles.data.calls.Box(handles.data.currentcall,1),...
    sum(handles.data.calls.Box(handles.data.currentcall,[1,3])));
PlotAudio = PlotAudio - movmean(PlotAudio, 100);
set(handles.Waveform,...
'XData', length(stats.Entropy) * ((1:length(PlotAudio)) / length(PlotAudio)),...
'YData', (PlotAudio - min(PlotAudio)) / (max(PlotAudio) - min(PlotAudio)) - 1);

% % SNR
y = 0-stats.Entropy;
x = 1:length(stats.Entropy);
z = zeros(size(x));
col = double(stats.Entropy < 1-handles.data.calls.EntThresh(handles.data.currentcall));  % This is the color, vary with x in this case.
set(handles.SNR, 'XData', [x;x], 'YData', [y;y], 'ZData', [z;z], 'CData', [col;col]);
set(handles.waveformWindow, 'XLim', [x(1), x(end)]);
end

