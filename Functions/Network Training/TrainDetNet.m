function TrainDetNet(hObject, ~, handles)
%% Train a new neural network
cd(handles.data.squeakfolder);
%% Select the tables that contains the training data
waitfor(msgbox('Select Image Tables for TRAINING the network (creating a network from scratch or building on an existing network)'))
[trainingdata, trainingpath] = uigetfile('Training/*.mat','Select File(s) for Training','MultiSelect', 'on');

%Return if cancel
if isa(trainingdata,'double') && trainingdata == 0
    return
end
if isa(trainingdata,'char')
    trainingdata = cellstr(trainingdata);
end
[TrainingTables, AllSettings, PathToITs] = ImportTrainingImgs(fullfile(trainingpath,trainingdata));

bManVal = questdlg('Do you have Validation Image Tables, too?', ...
    'Validation Data', ...
    'Yes','No','Yes');
switch bManVal
    case 'Yes'
        waitfor(msgbox('Select Image Tables for VALIDATING the network'))
        [valdata, valpath] = uigetfile('Validation/*.mat','Select File(s) for Validation','MultiSelect', 'on');

        %Return if cancel
        if isa(valdata,'double') && valdata == 0
            return
        end
        if isa(valdata,'char')
            valdata = cellstr(valdata);
        end
        [ValTables, ~, PathToVITs] = ImportTrainingImgs(fullfile(valpath,valdata));
        if ~isequal(ValTables.Properties.VariableNames,TrainingTables.Properties.VariableNames) 
            error('Unique call types between training and validation data do not match. If you still want this functionality, talk to Gabi.')
        end
    case 'No'
        ValTables = [];
        PathToVITs = [];
end

if isempty(TrainingTables); return; end

%% Train the network
choice = questdlg('Train from existing network?', 'Existing Network?', 'Yes', 'Yes - TensorFlow', 'No', 'Yes');
switch choice
    case 'Yes'
        [NetName, NetPath] = uigetfile(handles.data.settings.networkfolder,'Select Existing Network');
        netload = load([NetPath NetName]);
        detector = netload.detector;
        options = netload.options;
        detname = netload.detname;
        % Add to image tables record
        PathToITs = [netload.PathToITs,PathToITs];
        if isfield(netload,'PathToVITs')
            PathToVITs = [netload.PathToVITs,PathToVITs];
        end

        if (~any(strcmp(TrainingTables.Properties.VariableNames,'USV')) && any(detector.ClassNames==categorical({'USV'})))
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
        
        if any(~ismember(unique(TrainingTables.Properties.VariableNames(3:end)),detector.ClassNames))
            error('New training tables have new call classes not present in network, which is not allowed by Matlab at the time of coding.')
        end

        [detector, layers, options, info, detname] = TrainSqueakDetector(TrainingTables, ValTables, detector, options, detname);
    case 'Yes - TensorFlow'
        detector = importTensorFlowLayers(uigetdir(pwd,'Please select the folder containing saved TensorFlow 2 model (saved_model.pb & variables subfolder)'));
        [detector, layers, options, info, detname] = TrainSqueakDetector(TrainingTables, ValTables, detector);
    case 'No'
        ansCont = questdlg(['WARNING: If you proceed, this network will be trained on the following call types:', ...
            unique(TrainingTables.Properties.VariableNames(3:end))...
            'Due to Matlab limitations at the time of coding, you will not be able to later build on this network with additional call types.  Do you wish to proceed?'],'Call Types Warning','Yes','No','Yes');
        switch ansCont
            case 'Yes'
                [detector, layers, options, info, detname] = TrainSqueakDetector(TrainingTables, ValTables);
            case 'No'
                return
        end
end

%% Save the new network
[FileName,PathName] = uiputfile(fullfile(handles.data.settings.networkfolder,'*.mat'),'Save New Network');
wind = max(AllSettings(:,1));
noverlap = max(AllSettings(:,2));
nfft = max(AllSettings(:,3));
imLength = max(AllSettings(:,4));
% See ValDataIssue commit from Apr 2023
options.ValidationData = [];

version = handles.DAVersion;
save(fullfile(PathName,FileName),'detector','layers','options','info','wind','noverlap','nfft','version','imLength','detname','PathToITs','PathToVITs');

%% Update the menu
update_folders(hObject, handles);
%guidata(hObject, handles);

