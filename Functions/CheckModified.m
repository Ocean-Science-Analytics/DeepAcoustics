function CheckModified(hObject, eventdata, handles)
%Check if pre-existing detection file has changed to save file before loading a new one.
if ~isempty(handles.data.calls)
    saveChanges = 'No';
    opts.Interpreter = 'tex';
    opts.Default='Yes';
    if ~isempty(handles.current_file_id) && ~isempty(handles.current_detection_file)
        [~, ~, ~, ~, ~, modcheck] = loadCallfile(fullfile(handles.detectionfiles(handles.current_file_id).folder,  handles.current_detection_file), handles,false);
        if ~isequaln(modcheck.calls, handles.data.calls) || ~isequaln(modcheck.spect, handles.data.settings.spect)
            if ~isequaln(modcheck.calls, handles.data.calls) 
                saveChanges = questdlg('\color{red}\bf WARNING! \color{black} Detection file has been modified. Would you like to save changes?','Save Detection File?','Yes','No',opts);
            elseif ~isequaln(modcheck.spect, handles.data.settings.spect)
                saveChanges = questdlg('\color{red}\bf WARNING! \color{black} Spectrogram settings have been modified. Would you like to save changes in the det file (spect variable)?','Save Detection File?','Yes','No',opts);
            end
        end
    else
        saveChanges = questdlg('\color{red}\bf WARNING! \color{black} New detection file is unsaved. Would you like to save these detections?','Save Detection File?','Yes','No',opts);
    end
    switch saveChanges
        case 'Yes'
            SaveSession(hObject, eventdata, handles);
        case 'No'
    end
end