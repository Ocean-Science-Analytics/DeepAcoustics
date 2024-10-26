%function [TrainingTables, AllSettings] = ImportTrainingImgs(handles, bTraining)
function [TrainingTables, AllSettings, PathToITs] = ImportTrainingImgs(handles, bTraining)
%% Train a new neural network
cd(handles.data.squeakfolder);

TrainingTables = [];
AllSettings = [];
PathToITs = {};
% Apparently, "wind" is a function name, so initialize it as empty
wind = [];

%% Select the tables that contains the training data
if bTraining
    waitfor(msgbox('Select Image Tables for TRAINING the network (creating a network from scratch or building on an existing network)'))
    [trainingdata, trainingpath] = uigetfile('Training/*.mat','Select File(s) for Training','MultiSelect', 'on');
else
    waitfor(msgbox('Select Ground-Truthed Image Tables for EVALUATING the network (do NOT choose the images used to train the network)'))
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
    load([trainingpath trainingdata{i}],'TTable','wind','noverlap','nfft','imLength','pathtodet');
    warning(orig_state)
    % If bAug field doesn't exist, add and default to 0 and print a warning
    if ~any(strcmp('bAug', TTable.Properties.VariableNames))
        % Default augmented flag column
        TTable.bAug(:) = false;
        % Reorder columns for TrainSqueakDetector later
        otherColInds = ~find(strcmp('bAug', TTable.Properties.VariableNames));
        TTable = [TTable(:,'bAug') TTable(:,otherColInds)];
        warning('Older Images mat - any augmented images are not flagged and will be included in validation data which is not recommended')
    end

    % If concatenating more than one image table
    if i>1
        % Add missing columns
        if size(TTable,2) ~= size(TrainingTables,2)
            warning('Warning: At least one call type in one image table is not present in another image table.  If this is not as it should be, check your image tables before proceeding!')
            allvarnames = unique([TrainingTables.Properties.VariableNames,TTable.Properties.VariableNames],'stable');
            TT1varadd = allvarnames(~ismember(allvarnames,TrainingTables.Properties.VariableNames));
            TT2varadd = allvarnames(~ismember(allvarnames,TTable.Properties.VariableNames));
            for j = 1:length(TT1varadd)
                coladd = cell(size(TrainingTables,1),1);
                TrainingTables = addvars(TrainingTables,coladd);
                TrainingTables = renamevars(TrainingTables,'coladd',TT1varadd(j));
            end
            for j = 1:length(TT2varadd)
                coladd = cell(size(TTable,1),1);
                TTable = addvars(TTable,coladd);
                TTable = renamevars(TTable,'coladd',TT2varadd(j));
            end
        end
    end

    % Concat
    TrainingTables = [TrainingTables; TTable];
    AllSettings = [AllSettings; wind noverlap nfft imLength];
%     if exist('pathtodet','var')
%         PathToDet{i} = pathtodet;
%     end
    PathToITs{i} = [trainingpath trainingdata{i}];
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
    PathToITs = {};
    return
end
end