function PlayCall(handles)
    % Play the sound within the boxs
    audio = handles.data.AudioSamples(...
        handles.data.calls.Box(handles.data.currentcall, 1),...
        handles.data.calls.Box(handles.data.currentcall, 1) + handles.data.calls.Box(handles.data.currentcall, 3));
    playbackRate = handles.data.audiodata.SampleRate * handles.data.settings.playback_rate; % set playback rate
    audio = resample(audio, 192000, playbackRate);
    audio = audio - mean(audio);
    % Use a window funtion to smooth the beginning and end to remove clicks
    w = hamming(2000);
    audio(1:1000) = audio(1:1000) .* w(1:1000);
    audio(end-999:end) = audio(end-999:end) .* w(1001:2000);
    soundsc(audio,192000);
end