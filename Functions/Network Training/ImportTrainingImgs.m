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
    load(tablepath{i},'*Table','wind','noverlap','nfft','freqlow','freqhigh','samprate','imLength');
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
    if exist('freqlow','var')
        TheseSettings = [wind noverlap nfft freqlow freqhigh imLength];
        if exist('samprate','var')
            TheseSettings = [wind noverlap nfft freqlow freqhigh samprate imLength];
        end
    else
        TheseSettings = [wind noverlap nfft imLength];
    end
    if isempty(AllSettings) || size(AllSettings,2) == size(TheseSettings,2)
        AllSettings = [AllSettings; TheseSettings];
    else
        error('Mix of new and old image tables - please recreate older image tables to preserve metadata')
    end
    PathToITs{i} = tablepath{i};
end

% Check that image path still good, and have user replace if not
[trypath,~,~] = fileparts(tablepath{1});
indRePath = ~isfile(TrainingTables.imageFilename);
while any(indRePath)
    [thispath,thisfn,thisext] = fileparts(TrainingTables.imageFilename{find(indRePath,1,"first")});
    % Print previous location to terminal window (long paths not
    % visible in uigetdir)
    warning(['Previous location: ',thispath])
    newpn = uigetdir(trypath,['Select folder containing ',[thisfn thisext],' (see terminal window for previous location)']);
    % Double-check that they chose a good path
    if ~exist(fullfile(newpn,[thisfn thisext]),'file')
        error([thisfn ' not found in ' newpn])
    end
    [~,fn2rep,ext2rep] = fileparts(TrainingTables.imageFilename(indRePath));
    repiFn = fullfile(newpn,strcat(fn2rep,ext2rep));
    TrainingTables.imageFilename(indRePath) = repiFn;

    % Reset indices we still need to fix
    indRePath = ~isfile(TrainingTables.imageFilename);
    if any(indRePath)
        [~,thisfn,thisext] = fileparts(TrainingTables.imageFilename{find(indRePath,1,"first")});
        % Check for default ImgAug path adjustment
        lastslash = regexp(newpn,filesep);
        lastslash = lastslash(end);
        testaug = newpn(lastslash+1:end);
        % If new selected path is not an ImgAug folder, try adding an
        % ImgAug folder, otherwise, try adding the parent folder
        if ~strcmp(testaug,'ImgAug')
            newpn = fullfile(newpn,'ImgAug');
        else
            newpn = newpn(1:lastslash-1);
        end
        % If default ImgAug folder adjustment worked, try replacing
        % remaining stragglers with that path
        if exist(fullfile(newpn,[thisfn thisext]),'file')
            [~,fn2rep,ext2rep] = fileparts(TrainingTables.imageFilename(indRePath));
            repiFn = fullfile(newpn,strcat(fn2rep,ext2rep));
            TrainingTables.imageFilename(indRePath) = repiFn;

            % Reset indices we still need to fix
            indRePath = ~isfile(TrainingTables.imageFilename);
        end
    end
end

%% Create a warning if training files were created with different parameters
warningmsg = 'Continue anyway';
if size(unique(AllSettings,'rows'),1) ~= 1
    warningmsg = questdlg({'Not all images were created with the same settings','Network may not work as expected'}, ...
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