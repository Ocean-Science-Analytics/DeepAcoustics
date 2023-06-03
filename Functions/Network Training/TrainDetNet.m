function TrainDetNet(hObject, eventdata, handles)
%% Train a new neural network
[TrainingTables, Settings_Spec, Settings_Freq, ~] = ImportTrainingImgs(handles,true);
if isempty(TrainingTables); return; end

%% Train the network
choice = questdlg('Train from existing network?', 'Existing Network?', 'Yes', 'Yes - TensorFlow', 'No', 'Yes');
switch choice
    case 'Yes'
        detname = [];
        [NetName, NetPath] = uigetfile(handles.data.settings.networkfolder,'Select Existing Network');

        netload = load([NetPath NetName]);
        warningmsg = 'Continue anyway';
        if isfield(netload,'Settings_Freq')
            netFreqSettings = netload.Settings_Freq;
        else
            netFreqSettings = [0,0];
            warningmsg = questdlg({'This is an older network.  If you did not use the full frequency spectrum','to create your training images, network may not work as expected'}, ...
                'Warning','Continue anyway','Cancel','Cancel');
            waitfor(warningmsg)
        end
        if ~strcmp(warningmsg,'Continue anyway')
            return
        end
        detector = netload.detector;
        options = netload.options;
        detname = netload.detname;
        if any(netFreqSettings ~= Settings_Freq) && ~all(~netFreqSettings)
            error('Your network frequency settings do not match the frequencies used to generate your test images. Try using %d and %d kHz to create your images.',netFreqSettings(1),netFreqSettings(2))
        end
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
wind = max(Settings_Spec.wind);
noverlap = max(Settings_Spec.noverlap);
nfft = max(Settings_Spec.nfft);
imLength = max(Settings_Spec.imLength);
options.ValidationData = [];
Settings_Spec = table(wind,noverlap,nfft,imLength);

version = handles.DWVersion;
save(fullfile(PathName,FileName),'detector','layers','options','info','Settings_Spec','Settings_Freq','version','detname');

%% Update the menu
update_folders(hObject, eventdata, handles);
guidata(hObject, handles);

