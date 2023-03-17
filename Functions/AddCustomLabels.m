function AddCustomLabels(hObject, eventdata, handles)
    % Define call categories
    prompt = {
        'Label 1  --- Key 1'
        'Label 2  --- Key 2'
        'Label 3  --- Key 3'
        'Label 4  --- Key 4'
        'Label 5  --- Key 5'
        'Label 6  --- Key 6'
        'Label 7  --- Key 7'
        'Label 8  --- Key 8'
        'Label 9  --- Key 9'
        'Label 10  --- Key 0'
        'Label 11  --- Key -'
        'Label 12  --- Key ='
        'Label 13  --- Key !'
        'Label 14  --- Key @'
        'Label 15  --- Key #'   
        'Label 16  --- Key $'   
        'Label 17  --- Key %'
        'Label 18  --- Key ^'    
        'Label 19  --- Key &'
        'Label 20  --- Key *'
        'Label 21  --- Key ('
        'Label 22  --- Key )'
        'Label 23  --- Key _'
        'Label 24  --- Key +'    
        };
    
    dlg_title = 'Set Custom Label Names';
    num_lines=[1,60]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='none';
    old_labels = handles.data.settings.labels;
    new_labels = inputdlgcol(prompt,dlg_title,num_lines,old_labels,options,3);
    if ~isempty(new_labels)
        handles.data.settings.labels = new_labels;
        handles.data.saveSettings();
        update_folders(hObject, eventdata, handles);
    end
    guidata(hObject, handles);
end