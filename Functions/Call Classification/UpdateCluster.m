function UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
%% This function saves the files with new cluster names

h = waitbar(0,'Initializing');

[files, ~, file_idx] = unique(ClusteringData.Filename,'stable');

% Merge "Noise" and "noise"
clusterName = mergecats(clusterName, {'Noise', 'noise'});

% Apply cluster names to clustAssign
if ~iscategorical(clustAssign) 
    clustAssign = clusterName(clustAssign);
end

% Convert rejected into a logical for indexing
rejected = logical(rejected);

% Classify all rejected calls as 'Noise'
clustAssign(rejected) = 'Noise';

% Reject all calls classified as 'Noise'
rejected(clustAssign == 'Noise') = 1;

% answer = questdlg('Cluster assignments will be saved to Calls.ClustCat.  Do you also want to overwrite the "Type" column with the cluster assignments?', ...
%     'Overwrite "Type"', ...
%     'Yes','No','No');
% switch answer
%     case 'Yes'
%     case 'No'
%     case ''
%         error('You chose to cancel the operation.')
% end

for i = 1:length(files)

    Calls = loadCallfile(files{i},[],false);

    % Find the index of the clustering data that belongs to the file
    cluster_idx = find(file_idx == i);

    if ismember('UserID',ClusteringData.Properties.VariableNames)
        % Find the index of the calls in the file that correspond the the clustering data
        [~,call_idx] = ismember(ClusteringData{cluster_idx, 'UserID'},Calls.CallID);
    else
        warning('This will not assign clusters correctly if rejected Calls were not removed from your detections file.')
        [~,call_idx] = ismember(ClusteringData{cluster_idx, 'callID'},Calls.CallID);
    end

    % Update call type with cluster names
    Calls.ClustCat(call_idx) = clustAssign(cluster_idx);

    % Handle response
%     switch answer
%         case 'Yes'
%             Calls.Type(call_idx) = clustAssign(cluster_idx);
%         case 'No'
%     end

    % Reject calls classified as 'Noise'
    Calls.Accept(call_idx(rejected(cluster_idx))) = 0;

    waitbar(i/length(files),h,['Saving File ' num2str(i) ' of '  num2str(length(files))]);
    save(files{i},'Calls', '-append');

end
close(h)
end
