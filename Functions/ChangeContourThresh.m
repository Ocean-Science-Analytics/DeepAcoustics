function ChangeContourThresh(hObject, eventdata, handles)
    % Change the contour threshold
    prompt = {'Tonality Threshold: (range = 0-1, default = 0.215)', 'Amplitude Percentile Threshold: (range = 0-1, default = 0.825)'};
    dlg_title = 'New Contour Threshold:';
    num_lines = [1 length(dlg_title)+30]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
    defaultans = {num2str(handles.data.settings.EntropyThreshold),num2str(handles.data.settings.AmplitudeThreshold)};
    threshold = inputdlg(prompt,dlg_title,num_lines,defaultans,options);
    if isempty(threshold); return; end
    
    [EntropyThreshold,~,errmsg] = sscanf(threshold{1},'%f',1);
    disp(errmsg);
    [AmplitudeThreshold,~,errmsg] = sscanf(threshold{2},'%f',1);
    disp(errmsg);
    
    if ~isempty(EntropyThreshold) && ~isempty(AmplitudeThreshold)
    
        if AmplitudeThreshold < .001 || AmplitudeThreshold > .999
            disp('Warning! Amplitude Percentile Threshold Must be (0 > 1), Reverting to Default (.825)');
            AmplitudeThreshold = handles.data.defaultSettings.AmplitudeThreshold;
        end
        if EntropyThreshold < .001 || EntropyThreshold > .999
            disp('Warning! Tonality Threshold Must be (0 > 1), Reverting to Default (.215)');
            EntropyThreshold = handles.data.defaultSettings.EntropyThreshold;
        end
    
        % Add option to apply to all or just current det
        answer = questdlg('Would you like to apply these settings to all detections?', ...
            'Apply to all detections?', ...
            'All Detections','Only This Detection','Only This Detection');
        % Handle response
        switch answer
            case 'All Detections'
                handles.data.calls.EntThresh(:) = EntropyThreshold;
                handles.data.calls.AmpThresh(:) = AmplitudeThreshold;
                
                %Save global settings in settings.mat
                handles.data.settings.EntropyThreshold = EntropyThreshold;
                handles.data.settings.AmplitudeThreshold = AmplitudeThreshold;
                handles.data.saveSettings();
            case 'Only This Detection'
                handles.data.calls.EntThresh(handles.data.currentcall) = EntropyThreshold;
                handles.data.calls.AmpThresh(handles.data.currentcall) = AmplitudeThreshold;
                
                %Do NOT save global settings in settings.mat
            % If close (X) or Esc, cancel whole operation
            case ''
                return;
        end
    
        update_folders(hObject, eventdata, handles);
        try
            update_fig(hObject, handles);
        catch
            disp('Could not update figure. Is a call loaded?')
        end
    end
    guidata(hObject, handles);
end