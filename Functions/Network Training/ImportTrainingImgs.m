function [TrainingTables, AllSettings, PathToDet] = ImportTrainingImgs(handles)
%% Train a new neural network
cd(handles.data.squeakfolder);

TrainingTables = [];
AllSettings = [];
PathToDet = {};
% Apparently, "wind" is a function name, so initialize it as empty
wind = [];

%% Select the tables that contains the training data
waitfor(msgbox('Select Image Tables'))
[trainingdata, trainingpath] = uigetfile('Training/*.mat','Select File(s) for Training/Testing','MultiSelect', 'on');
%Return if cancel
if trainingdata == 0
    return
end
trainingdata = cellstr(trainingdata);

%% Load the data into a single table
for i = 1:length(trainingdata)
    load([trainingpath trainingdata{i}],'TTable','wind','noverlap','nfft','imLength','pathtodet');
    TrainingTables = [TrainingTables; TTable];
    AllSettings = [AllSettings; wind noverlap nfft imLength];
    if exist('pathtodet','var')
        PathToDet{i} = pathtodet;
    end
end
if ~all([isfile(TrainingTables.imageFilename)])
    error('Images Could Not Be Found On Path Specified in Images.mat')
end

%% Create a warning if training files were created with different parameters
warningmsg = 'Continue anyway';
if size(unique(AllSettings,'rows'),1) ~= 1
    warningmsg = questdlg({'Not all images were created with the same spectrogram settings','Network may not work as expected'}, ...
        'Warning','Continue anyway','Cancel','Cancel');
    waitfor(warningmsg)
end
if ~strcmp(warningmsg,'Continue anyway')
    TrainingTables = [];
    AllSettings = [];
    PathToDet = {};
    return
end
end