function PostHocDenoising_Callback(hObject, eventdata, handles)

% This function uses a convolutional neural network, trained in
% "TrainPostHocDenoiser_Callback.m", to seperate noise from USVs.

% Load the network
[FileName,PathName] = uigetfile(fullfile(handles.data.squeakfolder,'Denoising Network','*.mat'),'Select Denoising Network');
try
    net=load(fullfile(PathName,FileName),'DenoiseNet');
catch
    errordlg(sprintf('Denoising network not found'))
    return
end

if exist(handles.data.settings.detectionfolder,'dir') == 0
    errordlg('Please Select Detection Folder')
    uiwait
    load_detectionFolder_Callback(hObject, eventdata, handles)
    handles = guidata(hObject);  % Get newest version of handles
end

options.imageSize = [128, 128, 1];
[ClusteringData, ~, ~, ~, ~] = CreateClusteringData(handles, 'scale_duration', true, 'fixed_frequency', true);

%Return on cancel
if isempty(ClusteringData); return; end

% Resize the images to match the input image size
images = zeros([options.imageSize, size(ClusteringData, 1)]);
for i = 1:size(ClusteringData, 1)
    images(:,:,:,i) = imresize(ClusteringData.Spectrogram{i}, options.imageSize(1:2));
end

h = waitbar(0,'Initializing');
%Iterate backwards for better performance (dynamically pre-allocate)
for j=height(ClusteringData):-1:1
    progj = height(ClusteringData)-j+1;
    waitbar(progj/height(ClusteringData), h, ['Classifying Image ' num2str(progj) ' of ' num2str(height(ClusteringData))]);
    X = images(:,:,:,j) ./ 256;
    [Cl, ~] = classify(net.DenoiseNet, X);
    clustAssign(j,1)=Cl;
end
close(h);
clusterName=unique(clustAssign);
saveChoice =  questdlg('Update files with new denoising?','Save Rejections','Yes','No','Yes');
switch saveChoice
    case 'Yes'
        UpdateCluster(ClusteringData, clustAssign, clusterName, zeros(1,height(ClusteringData)));
        update_folders(hObject, eventdata, handles);
        if isfield(handles,'current_detection_file')
            loadcalls_Callback(hObject, eventdata, handles, true)
        end
    case 'No'
        return
end

end