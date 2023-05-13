function [TrainingTables, Settings_Spec, Settings_Freq, PathToDet] = ImportTrainingImgs(handles, bTraining)
%% Train a new neural network
cd(handles.data.squeakfolder);

TrainingTables = [];
Settings_Spec = cell2table(cell(0,4),'VariableNames',{'wind','noverlap','nfft','imLength'});
Settings_Freq = [];
PathToDet = {};

%% Select the tables that contains the training data
if bTraining
    waitfor(msgbox('Select Image Tables for TRAINING the network (creating a network from scratch or building on an existing network)'))
    [trainingdata, trainingpath] = uigetfile('Training/*.mat','Select File(s) for Training','MultiSelect', 'on');
else
    waitfor(msgbox('Select Ground-Truthed Image Tables for EVALUATING the network (do NOT choose the images use to train the network)'))
    [trainingdata, trainingpath] = uigetfile('Training/*.mat','Select File(s) for Evaluation','MultiSelect', 'on');
end
%Return if cancel
if isa(trainingdata,'double') && trainingdata == 0
    return
end
if isa(trainingdata,'char')
    trainingdata = cellstr(trainingdata);
end

%% Load the data into a single table
for i = 1:length(trainingdata)
    orig_state = warning;
    warning('off','all')
    S = load([trainingpath trainingdata{i}]);
    warning(orig_state)
    if isfield(S,'Settings_Freq')
        ThisSettings_Spec = S.Settings_Spec;
        ThisSettings_Freq = S.Settings_Freq;
        TTable = S.TTable;
        pathtodet = S.pathtodet;
    else
        ThisSettings_Spec = [S.wind, S.noverlap, S.nfft, S.imLength];
        ThisSettings_Freq = [0,0];
        TTable = S.TTable;
        if isfield(S,'pathtodet')
            pathtodet = S.pathtodet;
        end
    end
    TrainingTables = [TrainingTables; TTable];
    Settings_Spec = [Settings_Spec; ThisSettings_Spec];
    Settings_Freq = [Settings_Freq; ThisSettings_Freq];
    if exist('pathtodet','var')
        PathToDet{i} = pathtodet;
    end
end
if ~all([isfile(TrainingTables.imageFilename)])
    error('Images Could Not Be Found On Path Specified in Images.mat')
end

%% Create a warning if training files were created with different parameters
warningmsg = 'Continue anyway';
if size(unique(Settings_Spec,'rows'),1) ~= 1
    warningmsg = questdlg({'Not all images were created with the same spectrogram settings','Network may not work as expected'}, ...
        'Warning','Continue anyway','Cancel','Cancel');
    waitfor(warningmsg)
end
if size(unique(Settings_Freq,'rows'),1) ~= 1
    warningmsg = questdlg({'Not all images were created with the same frequency settings','Network may not work as expected'}, ...
        'Warning','Continue anyway','Cancel','Cancel');
    waitfor(warningmsg)
end
if ~strcmp(warningmsg,'Continue anyway')
    TrainingTables = [];
    Settings_Spec = [];
    Settings_Freq = [];
    PathToDet = {};
    return
end
end