function ViewClusters(app, event)
[~, ~, handles] = convertToGUIDECallbackArguments(app, event);

[ClusteringData,clustAssign] = CreateClusteringData(handles, 'forClustering', false);

%[~, clusterName, rejected, finished, clustAssign] = clusteringGUI(clustAssign, ClusteringData);
app.RunClusteringDlg(clustAssign, ClusteringData);
clusterName = app.clusterName;
rejected = app.rejected;
finished = app.finished;
clustAssign = app.clustAssign;

% Save the clusters
if finished == 1
    saveChoice =  questdlg('Update files with new clusters?','Save clusters','Yes','No','No');
    switch saveChoice
        case 'Yes'
            [~, ~, clustAssign] = unique(clustAssign);
            UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
        case 'No'
            return
    end
end

end
