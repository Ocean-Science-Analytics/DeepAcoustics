function TrainDetNet(hObject, eventdata, handles)
%% Train a new neural network
[TrainingTables, AllSettings, ~] = ImportTrainingImgs(handles,true);
if isempty(TrainingTables); return; end

%% Train the network
choice = questdlg('Train from existing network?', 'Existing Network?', 'Yes', 'Yes - TensorFlow', 'No', 'Yes');
switch choice
    case 'Yes'
        detname = [];
        [NetName, NetPath] = uigetfile(handles.data.settings.networkfolder,'Select Existing Network');
        load([NetPath NetName],'detector','options');
        if (~any(strcmp(TrainingTables.Properties.VariableNames,'USV')) && detector.ClassNames==categorical({'USV'}))
            choice = questdlg('It looks like you are trying to build on an older USV model.  Do you want to make sure new detections are also labelled USV? (Recommend Yes unless you know what you are doing.)', 'Yes', 'No');
            switch choice
                case 'Yes'
                    if length(TrainingTables.Properties.VariableNames) ~= 2
                        error('Cannot proceed as desired - talk to Gabi.')
                    else
                        TrainingTables.Properties.VariableNames{2} = 'USV';
                    end
            end
        end
        [detector, layers, options, info, detname] = TrainSqueakDetector(TrainingTables,detector,options,detname);
    case 'Yes - TensorFlow'
        detector = importTensorFlowLayers(uigetdir(pwd,'Please select the folder containing saved TensorFlow 2 model (saved_model.pb & variables subfolder)'));
        [detector, layers, options, info, detname] = TrainSqueakDetector(TrainingTables,detector);
    case 'No'
        [detector, layers, options, info, detname] = TrainSqueakDetector(TrainingTables);
end

%% Save the new network
[FileName,PathName] = uiputfile(fullfile(handles.data.settings.networkfolder,'*.mat'),'Save New Network');
wind = max(AllSettings(:,1));
noverlap = max(AllSettings(:,2));
nfft = max(AllSettings(:,3));
imLength = max(AllSettings(:,4));
options.ValidationData = [];

version = handles.DWVersion;
save(fullfile(PathName,FileName),'detector','layers','options','info','wind','noverlap','nfft','version','imLength','detname');

%% Update the menu
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);

