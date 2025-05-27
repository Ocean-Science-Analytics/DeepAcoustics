%function [TrainingTables, AllSettings] = ImportTrainingImgs(handles, bTraining)
function [TrainingTables, AllSettings, PathToITs] = ImportTrainingImgs(tablepath)%, bTraining)
%% Train a new neural network

TrainingTables = [];
AllSettings = [];
PathToITs = {};
% Apparently, "wind" is a function name, so initialize it as empty
wind = [];

%% Load the data into a single table
for i = 1:length(tablepath)
    orig_state = warning;
    warning('off','all')
    load(tablepath{i},'*Table','wind','noverlap','nfft','imLength','pathtodet');
    % Oops, saved val tables as VTable, so need to accommodate
    if exist('VTable','var')
        TTable = VTable;
    end
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
    PathToITs{i} = tablepath{i};
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