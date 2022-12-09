function UnsupClust(app,event)
    [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event);    
% Cluster with k-means or adaptive
%     SuperBatch = questdlg({'Do you want to do a super batch run using a special mat?'; ...
%         'If you do not know what this is, say No.'},'Super Batch','Yes','No','No');
    SuperBatch = 'No';
    bSuperBatch = false;
    nruns = 1;
    switch SuperBatch                         
        case 'Yes'
            % Load batch file
            [batchfn, exportpath] = uigetfile('*.mat','Select .mat file containing a "batchtable" variable');
            load(fullfile(exportpath,batchfn),'batchtable');
            bSuperBatch = true;
            nruns = height(batchtable);
            
            % Default questdlg options
            choice = 'K-means (recommended)';
            FromExisting = 'No';
            saveChoice = false;
            %bJen = 'Yes';
            bUpdate = false;
            
            % Load data for clustering
            [ClusteringData, ~, ~, ~, spectrogramOptions] = CreateClusteringData(handles, 'forClustering', true, 'save_data', true);
            if isempty(ClusteringData); return; end
            BatchCDSt = ClusteringData;
    end
    
    for j = 1:nruns
        %Reset Clustering Data if running batch
        if bSuperBatch
            ClusteringData = BatchCDSt;
        end
        finished = 0; % Repeated until
        while ~finished
            if ~bSuperBatch
                choice = questdlg('Choose clustering method:','Clustering Method','ARTwarp','K-means (recommended)', 'Variational Autoencoder','K-means (recommended)');
            end
            switch choice
                case []
                    return
    
                case {'K-means (recommended)', 'Variational Autoencoder'}
                    if ~bSuperBatch
                        FromExisting = questdlg('Use previously saved model? E.g. KMeans Model.mat','Load saved model mat?','Yes','No','No');
                    end
                    switch FromExisting % Load Model
                        case 'No'
                            % Get parameter weights
                            switch choice
                                case 'K-means (recommended)'
                                    if ~bSuperBatch
                                        [ClusteringData, ~, ~, ~, spectrogramOptions] = CreateClusteringData(handles, 'forClustering', true, 'save_data', true);
                                        if isempty(ClusteringData); return; end
                                        clusterParameters= inputdlg({'Number of Contour Pts','Slope Weight','Concavity Weight','Frequency Weight', ...
                                            'Relative Frequency Weight','Duration Weight','Infl Pt Weight','Parsons Weight','Parsons Resolution'}, ...%,'Parsons2 weight'},
                                            'Choose cluster parameters:',[1 30; 1 30; 1 30; 1 30; 1 30; 1 30; 1 30; 1 30; 1 15],{'20','0','0','0','1','0','0','0','4'});%,'0'});
                                        if isempty(clusterParameters); return; end
                                        num_pts = str2double(clusterParameters{1});
                                        slope_weight = str2double(clusterParameters{2});
                                        concav_weight = str2double(clusterParameters{3});
                                        freq_weight = str2double(clusterParameters{4});
                                        relfreq_weight = str2double(clusterParameters{5});
                                        duration_weight = str2double(clusterParameters{6});
                                        ninflpt_weight = str2double(clusterParameters{7});
                                        pc_weight = str2double(clusterParameters{8});
                                        RES = str2double(clusterParameters{9});
                                        if RES <= 0
                                            warning('RES cannot be <= 0; assuming pc_weight is 0')
                                            pc_weight = 0;
                                        end
                                        %pc2_weight = str2double(clusterParameters{8});
                                    else
                                        num_pts = 20;
                                        slope_weight = batchtable.slope_weight(j);
                                        concav_weight = batchtable.concav_weight(j);
                                        freq_weight = 0;
                                        relfreq_weight = batchtable.relfreq_weight(j);
                                        duration_weight = batchtable.duration_weight(j);
                                        RES = 4;
                                        pc_weight = batchtable.pc_weight(j);
                                        ninflpt_weight = batchtable.ninflpt_weight(j);
                                    end
                                    ClusteringData{:,'NumContPts'} = num_pts;
                                    data = get_kmeans_data(ClusteringData, num_pts, RES, slope_weight, concav_weight, freq_weight, relfreq_weight, duration_weight, pc_weight, ninflpt_weight);%, pc2_weight);
                                case 'Variational Autoencoder'
                                    [encoderNet, decoderNet, options, ClusteringData] = create_VAE_model(handles);
                                    data = extract_VAE_embeddings(encoderNet, options, ClusteringData);
                            end
    
                            % Make a k-means model and return the centroids
                            if ~bSuperBatch
                                C = get_kmeans_centroids(data);
                                if isempty(C); return; end
                            else
                                C = get_kmeans_centroids(data,batchtable(j,:),exportpath);
                                if isempty(C)
                                    finished = 1;
                                    continue;
                                end
                            end
    
                        case 'Yes'
                            [FileName,PathName] = uigetfile(fullfile(handles.data.squeakfolder,'Clustering Models','*.mat'), ...
                                'Select a previously created model .mat file (e.g. KMeans Model.mat)');
                            if isnumeric(FileName); return;end
                            switch choice
                                case 'K-means (recommended)'
                                    spectrogramOptions = [];
                                    % Preset variables
                                    num_pts = 20;
                                    RES = 1;
                                    freq_weight = 0;
                                    relfreq_weight = 0;
                                    slope_weight = 0;
                                    concav_weight = 0;
                                    duration_weight = 0;
                                    pc_weight = 0;
                                    ninflpt_weight = 0;
                                    % Load existing model to replace variables as
                                    % needed
                                    load(fullfile(PathName,FileName),'C','num_pts',...
                                        'RES','freq_weight','relfreq_weight','slope_weight',...
                                        'concav_weight','duration_weight','pc_weight','ninflpt_weight',...%'pc2_weight',...
                                        'clusterName','spectrogramOptions');
                                    ClusteringData = CreateClusteringData(handles, 'forClustering', true, 'spectrogramOptions', spectrogramOptions, 'save_data', true);
                                    if isempty(ClusteringData); return; end
    
                                    ClusteringData{:,'NumContPts'} = num_pts;
                                    data = get_kmeans_data(ClusteringData, num_pts, RES, slope_weight, concav_weight, freq_weight, relfreq_weight, duration_weight, pc_weight, ninflpt_weight);%, pc2_weight);
                                case 'Variational Autoencoder'
                                    C = [];
                                    load(fullfile(PathName,FileName),'C','encoderNet','decoderNet','options');
                                    [ClusteringData] = CreateClusteringData(handles, 'spectrogramOptions', options.spectrogram, 'scale_duration', options.maxDuration, 'freqRange', options.freqRange, 'save_data', true);
                                    if isempty(ClusteringData); return; end
                                    data = extract_VAE_embeddings(encoderNet, options, ClusteringData);
    
                                    % If the model was created through create_tsne_Callback, C won't exist, so make it.
                                    if isempty(C)
                                        C = get_kmeans_centroids(data);
                                    end
                            end
                    end
    
                    [clustAssign,D] = knnsearch(C,data,'Distance','euclidean');
    
                    ClusteringData.DistToCen = D;
                    ClusteringData.ClustAssign = clustAssign;
    
                    %% Save contour used in ClusteringData
        %             contourfreqsl = cellfun(@(x) {imresize(x',[1 num_pts+1])}, ClusteringData.xFreq,'UniformOutput',0);
        %             contourtimesl = cellfun(@(x) {imresize(x,[1 num_pts+1])}, ClusteringData.xTime,'UniformOutput',0);
        %             contourfreq = cellfun(@(x) {imresize(x',[1 num_pts])}, ClusteringData.xFreq,'UniformOutput',0);
        %             contourtime = cellfun(@(x) {imresize(x,[1 num_pts])}, ClusteringData.xTime,'UniformOutput',0);
    
                    if ismember('NumContPts',ClusteringData.Properties.VariableNames) && ~all(ClusteringData.NumContPts==0)
    
                        contoursmth = cellfun(@(x) smooth(x,5), ClusteringData.xFreq,'UniformOutput',false);
                        contourtimecc = cellfun(@(x) {linspace(min(x),max(x),num_pts+8)},ClusteringData.xTime,'UniformOutput',false);
                        contourfreqcc = cellfun(@(x,y,z) {interp1(x,y,z{:})},ClusteringData.xTime,contoursmth,contourtimecc,'UniformOutput',false);
                        contourtimesl = cellfun(@(x) {linspace(min(x),max(x),num_pts+1)},ClusteringData.xTime,'UniformOutput',false);
                        contourfreqsl = cellfun(@(x,y,z) {interp1(x,y,z{:})},ClusteringData.xTime,contoursmth,contourtimesl,'UniformOutput',false);
                        contourtime = cellfun(@(x) {linspace(min(x),max(x),num_pts)},ClusteringData.xTime,'UniformOutput',false);
                        contourfreq = cellfun(@(x,y,z) {interp1(x,y,z{:})},ClusteringData.xTime,contoursmth,contourtime,'UniformOutput',false);
    
                        %Now all based on contoursmth
%                         ClusteringData(:,'xFreq_Smooth') = contoursmth;
%                         ClusteringData(:,'xFreq_Contour_CC') = contourfreqcc;
%                         ClusteringData(:,'xTime_Contour_CC') = contourtimecc;
%                         ClusteringData(:,'xFreq_Contour_Sl') = contourfreqsl;
%                         ClusteringData(:,'xTime_Contour_Sl') = contourtimesl;
                        ClusteringData(:,'xFreq_Contour') = contourfreq;
                        ClusteringData(:,'xTime_Contour') = contourtime;
    
                        % Calculate and save # of inflection points based on full
                        % contours for each whistle
            %             concavall   = cellfun(@(x) diff(x,2),ClusteringData.xFreq,'UniformOutput',false);
            %             % Normalize with entire dataset
            %             [~,mu,sigma] = zscore(cell2mat(concavall));
            %             ninflpt     = cellfun(@(x) get_infl_pts((diff(x,2)-mu)./sigma),ClusteringData.xFreq,'UniformOutput',false);
                        %contourfreqcc   = cell2mat(cellfun(@(x) x{:}, contourfreqcc,'UniformOutput',false)); 
                        contourfreqcc   = cellfun(@(x) x{:}, contourfreqcc,'UniformOutput',false); 
                        %contourfreqcc   = cellfun(@(x) x{:}, contoursmth,'UniformOutput',false); 
                        % First deriv (deltax = 2 pts)
                        %concavall   = contourfreqcc(:,5:end)-contourfreqcc(:,1:end-4);
                        concavall   = cellfun(@(x) x(5:end)-x(1:end-4),contourfreqcc,'UniformOutput',false);
                        % Second deriv (deltax = 2 pts)
                        %concavall   = concavall(:,5:end)-concavall(:,1:end-4);
                        concavall   = cellfun(@(x) x(5:end)-x(1:end-4),concavall,'UniformOutput',false);
                        % Second deriv (deltax = 2 pts)
                        % Normalize concavity over entire dataset
                        %zccall = num2cell(zscore(concavall,0,'all'),2);
                        %[~,mu,sigma] = zscore(cell2mat(concavall),0,'all');
                        thresh_pos = cell2mat(concavall);
                        thresh_pos = thresh_pos(thresh_pos > 0);
                        thresh_pos = median(thresh_pos);
                        thresh_neg = cell2mat(concavall);
                        thresh_neg = thresh_neg(thresh_neg < 0);
                        thresh_neg = median(thresh_neg);
                        % Calculate # of inflection pts for each contour
                        %ninflpt     = cellfun(@(x) get_infl_pts(x),zccall,'UniformOutput',false);
                        ninflpt     = cellfun(@(x) get_infl_pts(x,thresh_pos,thresh_neg),concavall,'UniformOutput',false);
                        ClusteringData(:,'NumInflPts') = ninflpt;
                        vecIP = cellfun(@(x) getIPcont(x,thresh_pos,thresh_neg),concavall,'UniformOutput',false);
                        ClusteringData(:,'InflPtVec') = vecIP;

                        contourtimesl4ext = cellfun(@(x) {linspace(min(x),max(x),num_pts+4)},ClusteringData.xTime,'UniformOutput',false);
                        contourfreqsl4ext = cellfun(@(x,y,z) {interp1(x,y,z{:})},ClusteringData.xTime,contoursmth,contourtimesl4ext,'UniformOutput',false);
                        contourfreqsl4ext   = cellfun(@(x) x{:}, contourfreqsl4ext,'UniformOutput',false); 
                        slopeall   = cellfun(@(x) x(5:end)-x(1:end-4),contourfreqsl4ext,'UniformOutput',false);
                        thresh_pos = cell2mat(slopeall);
                        thresh_pos = thresh_pos(thresh_pos > 0);
                        %thresh_pos = median(thresh_pos);
                        thresh_pos_steep = quantile(thresh_pos,0.6);
                        thresh_pos_shall = quantile(thresh_pos,0.2);
                        thresh_neg = cell2mat(slopeall);
                        thresh_neg = thresh_neg(thresh_neg < 0);
                        %thresh_neg = median(thresh_neg);
                        thresh_neg_steep = quantile(thresh_neg,0.4);
                        thresh_neg_shall = quantile(thresh_neg,0.8);

                        %nextpt     = cellfun(@(x) get_infl_pts(x,thresh_pos,thresh_neg),slopeall,'UniformOutput',false);
                        n0pos1 = cellfun(@(x) get_infl_pts(x,thresh_pos_steep,thresh_pos_shall),slopeall,'UniformOutput',false);
                        n0neg1 = cellfun(@(x) get_infl_pts(x,thresh_neg_shall,thresh_neg_steep),slopeall,'UniformOutput',false);
                        nextpt = cellfun(@plus,n0pos1,n0neg1,'UniformOutput',false);
                        ClusteringData(:,'NumExtPts') = nextpt;
                        %vecext = cellfun(@(x) getIPcont(x,thresh_pos,thresh_neg),slopeall,'UniformOutput',false);
                        vecext0pos1 = cellfun(@(x) getIPcont(x,thresh_pos_steep,thresh_pos_shall),slopeall,'UniformOutput',false);
                        vecext0neg1 = cellfun(@(x) getIPcont(x,thresh_neg_shall,thresh_neg_steep),slopeall,'UniformOutput',false);
                        vecext = cellfun( @(x,y) [x,y], vecext0pos1, vecext0neg1, 'UniformOutput', false );
                        ClusteringData(:,'ExtPtVec') = vecext;
    
                        
        % Normalize concavity over entire dataset
        %zccall = num2cell(zscore(concavall,0,'all'),2);
        % Calculate # of inflection pts for each contour
    
                        %% Centroid contours
                        if relfreq_weight > 0
                            % Generate relative frequencies
                            allrelfreq = cellfun(@(x) x{:},contourfreqsl,'UniformOutput',false);
                            allrelfreq = cell2mat(allrelfreq);
                            allrelfreq = allrelfreq(:,2:end)-allrelfreq(:,1);
                            allrelfreq = zscore(allrelfreq,0,'all');
    
                            minylim = min(allrelfreq,[],'all');
                            maxylim = max(allrelfreq,[],'all');
    
                            % Make the figure
                            figCentCont = figure('Color','w','Position',[50,50,800,800]);
                            montTile = tiledlayout('flow','TileSpacing','none');
    
                            for i = unique(clustAssign)'
                                thisclust = allrelfreq(ClusteringData.ClustAssign == i,:);
                                thiscent = C(i,num_pts+1:2*num_pts);
                                % Undo normalization for scaling
                                thiscent = (thiscent-0.001)./relfreq_weight;
    
                                maxcont = max(thisclust,[],1);
                                mincont = min(thisclust,[],1);
    
                                nexttile
                                plot(1:num_pts,thiscent,1:num_pts,maxcont,'r--',1:num_pts,mincont,'r--')
                                ylim([minylim maxylim])
                                title(sprintf('(%d)  n = %d',i,size(thisclust,1)))
                            end
    
                            title(montTile, 'Centroid Contours with Max and Min Call Variation')
                        end
                        if bSuperBatch
                            figfilename = sprintf('CentroidContours_%s_%dClusters.png',batchtable.modelname{j},size(C,1));
                            saveas(gcf, fullfile(exportpath,figfilename));
                            close(gcf);
                        end
                    end
    
                    %% Silhouette Graph for This Run
                    figSilh = figure();
                    [s,~] = silhouette(data,clustAssign);
                    % Stats         
                    maxS = max(s);
                    %minS = min(s);
                    meanS = mean(s);
                    medianS = median(s);
    
                    % Prop of k that fall below zero (total N that fall below zero/N)
                    below_zero = length(s(s<=0))/length(s);
    
                    % Mean silhouette value of those that are above zero.
                    meanAbv_zero = mean(s(s>0));
    
                    % Silhouette values > .8
                    greater8 = length(s(s>0.8))/length(s);
    
                    % clusters with zero negative members
                    greater0 = length(s(s>0))/length(s);

                    % Count singleton clusters
                    ctsing = 0;
                    % Calc proportion of clusters > mean S value
                    ct1 = 0;
                    ct2 = 0;
                    accummu = 0;
                    uniqCA = unique(clustAssign);
                    for i=1:length(uniqCA)
                        accummu = accummu + mean(s(clustAssign==uniqCA(i)));
                        if sum(clustAssign==uniqCA(i)) == 1
                            ctsing = ctsing+1;
                        end
                    end
                    accummu = accummu/length(uniqCA);
                    for i=1:length(uniqCA)
                        if mean(s(clustAssign==uniqCA(i)))>=meanS
                            ct1 = ct1+1;
                        end
                        if mean(s(clustAssign==uniqCA(i)))>=accummu
                            ct2 = ct2+1;
                        end
                    end
                    propCAbMean1 = ct1/length(uniqCA);
                    propCAbMean2 = ct2/length(uniqCA);

                    xline(meanS,'--r','LineWidth',3);
                    xline(accummu,':g','LineWidth',3);
                    xlim([-1 1])
                    yticklabels(1:size(C,1))
                    title(sprintf('Silhouettes of Clusters - %d Clusters',size(C,1)),...
                        {sprintf('Mean1 (overall mean, red dashed) = %0.2f  Mean2 (mean by clust, green dotted) = %0.2f',meanS, accummu),...
                        sprintf('Med = %0.2f  Max = %0.2f  Prop<=0 = %0.2f',...
                        medianS, maxS, below_zero),...
                        sprintf('Prop of Cl>Mean1 = %0.2f  Prop of Cl>Mean2 = %0.2f  # Sngtons = %d', ...
                        propCAbMean1,propCAbMean2,ctsing)})
                    if bSuperBatch
                        figfilename = sprintf('SingleSilhouette_%s_%dClusters.png',batchtable.modelname{j},size(C,1));
                        saveas(gcf, fullfile(exportpath,figfilename));
                        close(gcf);
                    end
                    
                    ClusteringData(:,'Silhouette') = num2cell(s);
    
                    %% Sort the calls by how close they are to the cluster center
                    [~,idx] = sort(D);
                    clustAssign = clustAssign(idx);
                    ClusteringData = ClusteringData(idx,:);
    
                    %% Make a montage with the top calls in each class
                    try
                        % Find the median call length
                        [~, i] = unique(clustAssign,'sorted');
                        maxlength = cellfun(@(spect) size(spect,2), ClusteringData.Spectrogram(i));
                        maxlength = round(prctile(maxlength,75));
                        maxBandwidth = cellfun(@(spect) size(spect,1), ClusteringData.Spectrogram(i));
                        maxBandwidth = round(prctile(maxBandwidth,75));
    
                        % Make the figure
                        figClosest = figure('Color','w','Position',[50,50,800,800]);
        %                 ax_montage = axes(f_montage);
                        % Make the image stack
                        %montageI = [];
                        montTile = tiledlayout('flow','TileSpacing','none');
                        for i = unique(clustAssign)'
                            index = find(clustAssign==i,1);
                            tmp = ClusteringData.Spectrogram{index,1};
                            tmp = padarray(tmp,[0,max(maxlength-size(tmp,2),0)],'both');
                            tmp = rescale(tmp,1,256);
                            %montageI(:,:,i) = floor(imresize(tmp,[maxBandwidth,maxlength]));
    
                            nexttile
                            image(imtile(floor(imresize(tmp,[maxBandwidth,maxlength])), inferno, 'BackgroundColor', 'w', 'GridSize',[1 1]))
                            title(sprintf('(%d)  ID = %s',i,ClusteringData.UserID(index)))
                            %title(num2str(i))
                            axis off
                        end
        %                 image(ax_montage, imtile(montageI, inferno, 'BackgroundColor', 'w', 'BorderSize', 2, 'GridSize',[5 NaN]))
        %                 axis(ax_montage, 'off')
                        title(montTile, 'Closest call to each cluster center')
                    catch
                        disp('For some reason, I couldn''t make a montage of the call exemplars')
                    end
                    
                    if bSuperBatch
                        figfilename = sprintf('ClosestCall_%s_%dClusters.png',batchtable.modelname{j},size(C,1));
                        saveas(gcf, fullfile(exportpath,figfilename));
                        close(gcf);
                    end
    
                    %% Undo sort
                    clustAssign(idx) = clustAssign;
                    ClusteringData(idx,:) = ClusteringData;
    
                case 'ARTwarp'
                    ClusteringData = CreateClusteringData(handles, 'forClustering', true, 'save_data', true);
                    if isempty(ClusteringData); return; end
                    FromExisting = questdlg('Use previously saved model? E.g. KMeans Model.mat','Load saved model mat?','Yes','No','No');
                    switch FromExisting% Load Art Model
                        case 'No'
                            %% Get settings
                            prompt = {'Matching Threshold:','Duplicate Category Merge Threshold:','Outlier Threshold','Learning Rate:','Interations:','Shape Importance','Frequency Importance','Duration Importance'};
                            dlg_title = 'ARTwarp';
                            num_lines = [1 50];
                            defaultans = {'5','2.5','8','0.001','5','4','1','1'};
                            settings = inputdlg(prompt,dlg_title,num_lines,defaultans);
                            if isempty(settings)
                                return
                            end
                            %% Cluster
                            try
                                [ARTnet, clustAssign] = ARTwarp2(ClusteringData.xFreq,settings);
                            catch ME
                                disp(ME)
                            end
    
                        case 'Yes'
                            [FileName,PathName] = uigetfile(fullfile(handles.data.squeakfolder,'Clustering Models','*.mat'), ...
                                'Select a previously created model .mat file (e.g. ARTwarp Model.mat)');
                            load(fullfile(PathName,FileName),'ARTnet','settings');
                            if exist('ARTnet', 'var') ~= 1
                                warndlg('ARTnet model could not be found. Is this file a trained ARTwarp2 model?')
                                continue
                            end
    
                    end
                    [clustAssign] = GetARTwarpClusters(ClusteringData.xFreq,ARTnet,settings);
            end
    
            %     data = freq;
            %         epsilon = 0.0001;
            % mu = mean(data);
            % data = data - mean(data)
            % A = data'*data;
            % [V,D,~] = svd(A);
            % whMat = sqrt(size(data,1)-1)*V*sqrtm(inv(D + eye(size(D))*epsilon))*V';
            % Xwh = data*whMat;
            % invMat = pinv(whMat);
            %
            % data = Xwh
            %
            % data  = (freq-mean(freq)) ./ std(freq)
            % [clustAssign, C]= kmeans(data,10,'Distance','sqeuclidean','Replicates',10);
    
    
            %% Assign Names
            % If the
            if strcmp(choice, 'K-means (recommended)') && strcmp(FromExisting, 'Yes')
                clustAssign = categorical(clustAssign, 1:size(C,1), cellstr(clusterName));
            end
    
            %% Sort the calls by how close they are to the cluster center
            [~,idx] = sort(ClusteringData.DistToCen);
            clustAssign = clustAssign(idx);
            ClusteringData = ClusteringData(idx,:);
    
            %% Jen Res Settings
    %         if ~bSuperBatch
    %             bJen =  questdlg('Are you Jen?','Ultrawide Resolution Quick Fix','Yes','No','No');
    %         end
    %         switch bJen
    %             case 'Yes'
    %                 ClusteringData(:,'IsJen') = num2cell(ones(height(ClusteringData),1));
    %             case 'No'
    %                 ClusteringData(:,'IsJen') = num2cell(zeros(height(ClusteringData),1));
    %         end
    
            if ~bSuperBatch
                %[~, clusterName, rejected, finished, clustAssign] = clusteringGUI(clustAssign, ClusteringData, app, event);
                app.RunClusteringDlg(clustAssign, ClusteringData);
                clusterName = app.clusterName;
                rejected = app.rejected;
                finished = app.finished;
                clustAssign = app.clustAssign;
            else
                finished = 1;
            end
            % Standardize clustering GUI image axes?
        %     saveChoice =  questdlg('Standardize clustering GUI image axes?','Standardize axes','Yes','No','No');
        %     switch saveChoice
        %         case 'Yes'
        %             CDBU = ClusteringData;
        %             %ClusteringData{:,'StandSpec'} = ClusteringData{:,'Spectrogram'};
        %             if length(unique(ClusteringData.TimeScale)) > 1
        %                 warning('%s\n%s\n%s',...
        %                     'WARNING: It looks like the spectrograms in this collection were not run consistently.',...
        %                     'This may be because you are loading multiple Extracted Contours that were run separately.',...
        %                     'Recommend running the original detection mats instead or the Clustering GUI images may look weird.')
        %                 bProceed = questdlg('Do you wish to proceed anyway?','Yes','No','No');
        %                 if strcmp(bProceed,'No')
        %                     error('You chose to stop.')
        %                 end
        %             end
        %             CDDurs = cell2mat(cellfun(@(x) size(x,2),ClusteringData.Spectrogram,'UniformOutput',false)).*ClusteringData.TimeScale;
        %             %resz = max(cell2mat(cellfun(@size,ClusteringData.Spectrogram,'UniformOutput',false)));
        %             pad = [zeros(size(CDDurs,1),1) max(CDDurs)-CDDurs];
        %             pad = floor(pad./ClusteringData.TimeScale);
        %             pad = num2cell(pad,2);
        %             ClusteringData.Spectrogram = cellfun(@(x,y) padarray(x, y, 255, 'post'),ClusteringData.Spectrogram,pad,'UniformOutput',false);
        %             [~, clusterName, rejected, finished, clustAssign] = clusteringGUI(clustAssign, ClusteringData);
        %             ClusteringData = CDBU;
        %             clear CDBU CDDurs pad
        %         case 'No'
        %             [~, clusterName, rejected, finished, clustAssign] = clusteringGUI(clustAssign, ClusteringData);%, ...
        %             %[str2double(handles.data.settings.detectionSettings{3}) str2double(handles.data.settings.detectionSettings{2})]);
        %     end
    
            %% Undo sort
            clustAssign(idx) = clustAssign;
            ClusteringData(idx,:) = ClusteringData;
        end
        % Will only happen for batch batch silhouettes
        if isempty(C)
            continue;
        end
        %% Update Files
        % Save the clustering model
        dlgprog = uiprogressdlg(app.mainfigure,'Title','Saving Model',...
                'Indeterminate','on');
        drawnow
        if finished == 1 && FromExisting(1) == 'N'
            switch choice
                case 'K-means (recommended)'
                    if ~bSuperBatch
                        if app.bModel
                            save(fullfile(app.strUnsupSaveLoc, 'KMeans Model.mat'), 'C', 'num_pts','RES','freq_weight',...
                                'relfreq_weight', 'slope_weight', 'concav_weight', 'duration_weight', 'pc_weight',... % 'pc2_weight',
                                'ninflpt_weight','clusterName', 'spectrogramOptions');
                        end
                    else
                        PathName = exportpath;
                        FileName = sprintf('KMeansModel_%s_%dClusters.mat',batchtable.modelname{j},size(C,1));
                        if ~isnumeric(FileName)
                            save(fullfile(PathName, FileName), 'C', 'num_pts','RES','freq_weight',...
                                'relfreq_weight', 'slope_weight', 'concav_weight', 'duration_weight', 'pc_weight',... % 'pc2_weight',
                                'ninflpt_weight','spectrogramOptions');
                        end
                    end
                case 'ARTwarp'
                    [FileName, PathName] = uiputfile(fullfile(handles.data.squeakfolder, 'Clustering Models', 'ARTwarp Model.mat'), 'Save clustering model');
                    if ~isnumeric(FileName)
                        save(fullfile(PathName, FileName), 'ARTnet', 'settings');
                    end
                case 'Variational Autoencoder'
                    [FileName, PathName] = uiputfile(fullfile(handles.data.squeakfolder, 'Clustering Models', 'Variational Autoencoder Model.mat'), 'Save clustering model');
                    if ~isnumeric(FileName)
                        save(fullfile(PathName, FileName), 'C', 'encoderNet', 'decoderNet', 'options', 'clusterName');
                    end
            end
        end
        close(dlgprog)
    end
    
    dlgprog = uiprogressdlg(app.mainfigure,'Title','Saving Other Things',...
            'Indeterminate','on');
    drawnow
    % Only Save if Save selected in Clustering GUI
    if finished == 1
        %% Save the cluster assignments & silhoutte values
        if ~bSuperBatch
            saveChoice =  app.bEEC;
        end
        switch saveChoice
            case true
                % Set up variables to save
                ClusteringData{:,'ClustAssign'} = clustAssign;
                spect = handles.data.settings.spect;

                % Set save file name based on user options
                strFullFile = fullfile(app.strUnsupSaveLoc, 'Extracted Contours.mat');
                % If user chose not to overwrite, check that file exists and
                % increment # in file name until a save won't overwrite an
                % existing file
                if ~app.bECOverwrite && isfile(strFullFile)
                    nAddInt = 1;
                    while isfile(strFullFile)
                        strReplace = sprintf('Contours(%d).mat',nAddInt);
                        strFullFile = regexprep(strFullFile,'Contour.+[.]mat',strReplace);
                        nAddInt = nAddInt + 1;
                    end
                end
                save(strFullFile,'ClusteringData','spect','-v7.3');
            case false
        end
        
        % Save the clusters
        if ~bSuperBatch
            bUpdate =  app.bUpdateDets;
        end
        switch bUpdate
            case true
                UpdateCluster(ClusteringData, clustAssign, clusterName, rejected)
                update_folders(hObject, eventdata, handles);
                if isfield(handles,'current_detection_file')
                    LoadCalls(hObject, eventdata, handles, true)
                end
            case false
        end

        if isvalid(figSilh) && app.bSilh
            saveas(figSilh,fullfile(app.strUnsupSaveLoc,'Silhouettes.png'));
            close(figSilh)
        end
        if isvalid(figClosest) && app.bClosest
            saveas(figClosest,fullfile(app.strUnsupSaveLoc,'ClosestCalls.png'));
            close(figClosest)
        end
        if isvalid(figCentCont) && app.bContours
            saveas(figCentCont,fullfile(app.strUnsupSaveLoc,'CentroidContours.png'));
            close(figCentCont)
        end
    end
    close(dlgprog)
end

%% Dyanamic Time Warping
% for use as a custom distance function for pdist, kmedoids
function D = dtw2(ZI,ZJ)
    D = zeros(size(ZJ,1),1);
    for i = 1:size(ZJ,1)
        D(i) = dtw(ZI,ZJ(i,:),3);
    end
end

function data = get_kmeans_data(ClusteringData, num_pts, RES, slope_weight, concav_weight, freq_weight, relfreq_weight, duration_weight, pc_weight, ninflpt_weight)%, pc2_weight)
    % Parameterize the data for kmeans
    %ReshapedX   = cell2mat(cellfun(@(x) imresize(x',[1 num_pts+1]) ,ClusteringData.xFreq,'UniformOutput',0));
    % Smooth contour
    allconts    = cellfun(@(x) smooth(x,5), ClusteringData.xFreq,'UniformOutput',false);
    % Linear interpolation
    timelsp     = cellfun(@(x) linspace(min(x),max(x),num_pts+1),ClusteringData.xTime,'UniformOutput',false);
    ReshapedX   = cell2mat(cellfun(@(x,y,z) interp1(x,y,z),ClusteringData.xTime,allconts,timelsp,'UniformOutput',false));
    slope       = diff(ReshapedX,1,2);
    %ReshapedX   = cell2mat(cellfun(@(x) imresize(x',[1 num_pts+2]) ,ClusteringData.xFreq,'UniformOutput',0));
    timelsp     = cellfun(@(x) linspace(min(x),max(x),num_pts+2),ClusteringData.xTime,'UniformOutput',false);
    ReshapedX   = cell2mat(cellfun(@(x,y,z) interp1(x,y,z),ClusteringData.xTime,allconts,timelsp,'UniformOutput',false));
    concav      = diff(ReshapedX,2,2);
    % Pull concavity based on full contour
    %concavall   = cellfun(@(x) diff(x,2),ClusteringData.xFreq,'UniformOutput',false);
    
    % Pull concavity based on 20-pt contour
    timelsp     = cellfun(@(x) linspace(min(x),max(x),num_pts+4),ClusteringData.xTime,'UniformOutput',false);
    concavall   = cellfun(@(x,y,z) interp1(x,y,z),ClusteringData.xTime,allconts,timelsp,'UniformOutput',false);
    % First deriv (deltax = 2 pts)
    %concavall   = concavall(:,5:end)-concavall(:,1:end-4);
    concavall   = cellfun(@(x) x(5:end)-x(1:end-4),concavall,'UniformOutput',false);
    %Better (smoothed) slope
    slope = zscore(cell2mat(concavall),[],'all');
    
    timelsp     = cellfun(@(x) linspace(min(x),max(x),num_pts+8),ClusteringData.xTime,'UniformOutput',false);
    concavall   = cellfun(@(x,y,z) interp1(x,y,z),ClusteringData.xTime,allconts,timelsp,'UniformOutput',false);
    % First deriv (deltax = 2 pts)
    %concavall   = concavall(:,5:end)-concavall(:,1:end-4);
    concavall   = cellfun(@(x) x(5:end)-x(1:end-4),concavall,'UniformOutput',false);
    % Second deriv (deltax = 2 pts)
    %concavall   = concavall(:,5:end)-concavall(:,1:end-4);
    concavall   = cellfun(@(x) x(5:end)-x(1:end-4),concavall,'UniformOutput',false);
    % Normalize concavity over entire dataset
    %better (smoothed) concav
    concav = zscore(cell2mat(concavall),[],'all');
    thresh_pos = cell2mat(concavall);
    thresh_pos = thresh_pos(thresh_pos > 0);
    thresh_pos = median(thresh_pos);
    thresh_neg = cell2mat(concavall);
    thresh_neg = thresh_neg(thresh_neg < 0);
    thresh_neg = median(thresh_neg);
    %zccall = num2cell(zscore(concavall,0,'all'),2);
    % Calculate # of inflection pts for each contour
    ninflpt     = cell2mat(cellfun(@(x) get_infl_pts(x,thresh_pos,thresh_neg),concavall,'UniformOutput',false));
    %ninflpt     = cell2mat(cellfun(@(x) get_infl_pts(x),zccall,'UniformOutput',false));
    %MX          = quantile(slope,0.9,'all');
    %MX          = 2*std(slope,0,'all');
    %MX          = max(slope,[],'all');
    % RES must be > 0
    RES         = max(RES, 1);
    MX          = (max(slope,[],'all')/(RES+1))*RES;
    pc          = round(slope.*(RES/MX));
    pc(pc>RES)  = RES;
    pc(pc<-RES) = -RES;
    %slope       = zscore(slope,0,'all');
    %concav       = zscore(concav,0,'all');
    %freq        = cell2mat(cellfun(@(x) imresize(x',[1 num_pts]) ,ClusteringData.xFreq,'UniformOutput',0));
    timelsp     = cellfun(@(x) linspace(min(x),max(x),num_pts),ClusteringData.xTime,'UniformOutput',false);
    freq        = cell2mat(cellfun(@(x,y,z) interp1(x,y,z),ClusteringData.xTime,allconts,timelsp,'UniformOutput',false));
    %Recode relfreq to take out the first useless contour pt (that's always 0)
    %but keep num of contour pts at num_pts
    timelsp     = cellfun(@(x) linspace(min(x),max(x),num_pts+1),ClusteringData.xTime,'UniformOutput',false);
    relfreq     = cell2mat(cellfun(@(x,y,z) interp1(x,y,z),ClusteringData.xTime,allconts,timelsp,'UniformOutput',false));
    relfreq     = relfreq(:,2:end)-relfreq(:,1);
    
    % MX2         = (max(relfreq,[],'all')/(RES+1))*RES;
    % pc2          = round(relfreq.*(RES/MX2));
    % pc2(pc2>RES)  = RES;
    % pc2(pc2<-RES) = -RES;
    
    freq        = zscore(freq,0,'all');
    relfreq     = zscore(relfreq,0,'all');
    duration    = repmat(ClusteringData.Duration,[1 num_pts]);
    duration    = zscore(duration,0,'all');
    pc          = zscore(pc,0,'all');
    % pc2       = zscore(pc2,0,'all');
    ninflpt    = repmat(ninflpt,[1 num_pts]);
    ninflpt     = zscore(ninflpt,0,'all');
    
    data = [
        freq        .*  freq_weight+.001,...
        relfreq     .*  relfreq_weight+.001,...
        slope       .*  slope_weight+.001,...
        concav      .*  concav_weight+.001,...
        duration    .*  duration_weight+.001,...
        pc          .*  pc_weight+0.001,...
        ninflpt     .*  ninflpt_weight+0.001...
    %     pc2       .*  pc2_weight+0.001,...
        ];
end

% # of Inflection Pt Calculations
function ninflpt = get_infl_pts(cont_concav,thresh_pos,thresh_neg)
    % Given a contour of concavity values
    ninflpt = cont_concav;
    % Separate concav values into three categories using +/- 1 SD as
    % cut-offs
    ninflpt(cont_concav<=thresh_neg) = -1;
    ninflpt(cont_concav>=thresh_pos) = 1;
    ninflpt(cont_concav>thresh_neg & cont_concav<thresh_pos) = 0;
    % Remove zeros and count changes between -1 and 1 and vice versa
    ninflpt = length(find(diff(ninflpt(ninflpt~=0))));
end

% Indices of Inflection Point Calculations
function xvals = getIPcont(cont_concav,thresh_pos,thresh_neg)
    % Given a contour of concavity values
    ninflpt = cont_concav;
    % Initialized IP vec to zeros
    xvals = zeros(1, length(ninflpt));
    % Separate concav values into three categories using +/- 1 SD as
    % cut-offs
    ninflpt(cont_concav<=thresh_neg) = -1;
    ninflpt(cont_concav>=thresh_pos) = 1;
    ninflpt(cont_concav>thresh_neg & cont_concav<thresh_pos) = 0;
    % For every contour point
    for i = 1:length(ninflpt)
        % If it's nonzero
        if ninflpt(i) ~= 0
            % Look at the rest of the future contour
            subvec = ninflpt(i+1:end);
            % Find the next nonzero value
            testind = find(subvec,1,'first')+i;
            testval = ninflpt(testind);
            % If there's a sign switch, it's an inflection point!
            if ninflpt(i)*testval == -1
                % Store the index of the inflection point as halfway
                % between the sign change (or as close as you can get)
                xvals(i) = floor((testind-i)/2)+i;
            end
        end
    end
    % Remove zeros
    xvals = xvals(xvals~=0);
end

function C = get_kmeans_centroids(data,varargin)
    % Make a k-means model and return the centroids
    if nargin == 1
        list = {'Elbow Optimized','Elbow w/ Min Clust Size','User Defined','User Defined w/ Min Clust Size','Silhouette Batch'};
        [optimize,tf] = listdlg('PromptString','Choose a clustering method','ListString',list,'SelectionMode','single','Name','Clustering Method');
    elseif nargin == 3
        batchtable = varargin{1};
        exportpath = varargin{2};
        tf = 1;
        if strcmp(batchtable.runtype{:},'User Defined')
            optimize = 3;
        elseif strcmp(batchtable.runtype{:},'Silhouette Batch')
            optimize = 5;
        else
            error('Something wrong with runtype in batch file')
        end
    else
        error('Something wrong with number of arguments passed to function')
    end
    %optimize = questdlg('Optimize Cluster Number?','Cluster Optimization','Elbow Optimized','Elbow w/ Min Clust Size','User Defined','Elbow Optimized');
    C = [];
    if tf == 1
        switch optimize
            %case 'Elbow Optimized'
            case 1
                opt_options = inputdlg({'Max Clusters','Replicates'},'Cluster Optimization',[1 50; 1 50],{'100','3'});
                if isempty(opt_options); return; end
    
                %Cap the max clusters to the number of samples.
                if size(data,1) < str2double(opt_options{1})
                    opt_options{1} = num2str(size(data,1));
                end
                [~,C] = kmeans_opt(data, str2double(opt_options{1}), 0, str2double(opt_options{2}));
    
            %case 'Elbow w/ Min Clust Size'
            case 2
                opt_options = inputdlg({'Max Clusters','Replicates','Min Clust Size'},'Cluster Optimization',[1 50; 1 50; 1 50],{'100','10','1'});
                if isempty(opt_options); return; end
                k = str2double(opt_options{1});
                nReps = str2double(opt_options{2});
                minclsz = str2double(opt_options{3});
    
                %Cap the max clusters to the number of samples.
                if size(data,1) < k
                    k = size(data,1);
                end
                [IDX,C] = kmeans_opt(data, k, 0, nReps);
                Celb = C;
                [GC,~] = groupcounts(IDX);
                numcl = length(GC);
                while min(GC) < minclsz
                    numcl = numcl - 1;
                    [IDX,C] = kmeans(data,numcl,'Distance','sqeuclidean','Replicates',nReps);
                    [GC,~] = groupcounts(IDX);
                end
                if numcl == 1
                    warning('Reached a single cluster. Proceeding with basic elbow-optimized method.')
                    C = Celb;
                end
    
            %case 'User Defined'
            case 3
                if nargin == 1
                    opt_options = inputdlg({'# of Clusters','Replicates'},'Choose Model Options',[1; 1],{'15','10'});
                    if isempty(opt_options); return; end
                    k = str2double(opt_options{1});
                    nReps = str2double(opt_options{2});
                else
                    k = batchtable.k;
                    nReps = 1000;
                end
                [~, C] = kmeans(data,k,'Distance','sqeuclidean','Replicates',nReps);

            %case 'User Defined w/ Min Clust Size'
            case 4
                opt_options = inputdlg({'Starting # of Clusters','Replicates','Min Clust Size'},'Choose Model Options',[1; 1; 1],{'15','10','1'});
                if isempty(opt_options); return; end
                k = str2double(opt_options{1});
                nReps = str2double(opt_options{2});
                minclsz = str2double(opt_options{3});

                [IDX, C] = kmeans(data,k,'Distance','sqeuclidean','Replicates',nReps);
                Cog = C;
                [GC,~] = groupcounts(IDX);
                numcl = length(GC);
                while min(GC) < minclsz
                    numcl = numcl - 1;
                    [IDX,C] = kmeans(data,numcl,'Distance','sqeuclidean','Replicates',nReps);
                    [GC,~] = groupcounts(IDX);
                end
                if numcl == 1
                    warning('Reached a single cluster. Proceeding with the specified starting # of clusters.')
                    C = Cog;
                end

            %case 'Silhouette Batch'
            case 5
                %% User options
                if nargin == 1
                    opt_options = inputdlg({'Min # of Clusters','Max # of Clusters','Replicates'},'Batch Options',[1; 1; 1],{'2','30','10'});
                    minclust = str2double(opt_options{1});
                    maxclust = str2double(opt_options{2});
                    nReps = str2double(opt_options{3});
                else
                    minclust = 2;
                    maxclust = 100;
                    nReps = 1000;
                end
                    
                %% Silhouette loop
                % Preallocate
                maxS = zeros(1,(maxclust-minclust+1));
                %minS = zeros(1,(maxclust-minclust+1));
                meanS = zeros(1,(maxclust-minclust+1));
                medianS = zeros(1,(maxclust-minclust+1));
                below_zero = zeros(1,(maxclust-minclust+1));
                meanAbv_zero = zeros(1,(maxclust-minclust+1));
                greater8 = zeros(1,(maxclust-minclust+1));
                greater0 = zeros(1,(maxclust-minclust+1));
                ctsing = zeros(1,(maxclust-minclust+1));
                accummu = zeros(1,(maxclust-minclust+1));
                propCAbMean1 = zeros(1,(maxclust-minclust+1));
                propCAbMean2 = zeros(1,(maxclust-minclust+1));
                
                fig = uifigure;
                d = uiprogressdlg(fig,'Title','Silhouette Loop - Please Wait',...
                    'Message','Running silhouettes...');
                drawnow
                
                for k = minclust:maxclust
                    ind = k-minclust+1;
                    d.Value = ind/(maxclust-minclust+1); 
                    d.Message = sprintf('Running silhouette %d of %d',ind,maxclust-minclust+1);
                    drawnow
        
                    clust = kmeans(data,k,'Distance','sqeuclidean','Replicates',nReps);
                    s = silhouette(data,clust);
                    ind = k-minclust+1;
    
                    % Making numeric vectors for line plots         
                    maxS(ind) = max(s);
                    %minS(ind) = min(s);
                    meanS(ind) = mean(s);
                    medianS(ind) = median(s);
    
                    % Prop of k that fall below zero (total N that fall below zero/N)
                    below_zero(ind) = length(s(s<=0))/length(s);
    
                    % Mean silhouette value of those that are above zero.
                    meanAbv_zero(ind) = mean(s(s>0));
    
                    % Silhouette values > .8
                    greater8(ind) = length(s(s>0.8))/length(s);
    
                    % clusters with zero negative members
                    greater0(ind) = length(s(s>0))/length(s);
                    
                    % Count singleton clusters
                    thisctsing = 0;
                    % Calc proportion of clusters > mean S value
                    ct1 = 0;
                    ct2 = 0;
                    thisaccummu = 0;
                    uniqCA = unique(clust);
                    for i=1:length(uniqCA)
                        thisaccummu = thisaccummu + mean(s(clust==uniqCA(i)));
                        if sum(clust==uniqCA(i)) == 1
                            thisctsing = thisctsing+1;
                        end
                    end
                    ctsing(ind) = thisctsing;
                    accummu(ind) = thisaccummu/length(uniqCA);
                    for i=1:length(uniqCA)
                        if mean(s(clust==uniqCA(i)))>=meanS(ind)
                            ct1 = ct1+1;
                        end
                        if mean(s(clust==uniqCA(i)))>=accummu(ind)
                            ct2 = ct2+1;
                        end
                    end
                    propCAbMean1(ind) = ct1/length(uniqCA);
                    propCAbMean2(ind) = ct2/length(uniqCA);
                end
                close(d)
                delete(fig)
    
                %% Silhouettes Plot
                figure()
                colororder({'b','k'})
                yyaxis left
                xvals = minclust:maxclust;
                %plot(xvals, greater8, 'Color', 'blue');
                plot(xvals, meanS, '-b');
                hold on;
                %plot(xvals, greater0, 'Color', 'red');
                plot(xvals, accummu, '-r');
                plot(xvals, maxS, '-g');
                plot(xvals, medianS, '-y');
                %plot(xvals, below_zero, 'Color', 'yellow');
                %plot(xvals, meanAbv_zero, 'Color', 'magenta');
                plot(xvals, propCAbMean1, '-m');
                plot(xvals, propCAbMean2, '-c');
                ylabel('Silhouette Value')
                yyaxis right
                plot(xvals, ctsing, '-k');
                hold off;
                title(sprintf('Silhouette Values for k = %d through %d Clusters',minclust,maxclust));
                legend('Overall Mean', 'Mean by Cluster', 'Max S', 'Median S', 'Prop > Overall Mean', 'Prop > Mean by Cluster', '# Singletons',...
                    'Location','southeast')%, 'Best Mean S', 'Best Min S')
                legend('boxoff')
                xlabel('Number of clusters (k)')
                ylabel('# of Singleton Clusters')
                
                if nargin == 3
                    figfilename = sprintf('BatchSilhouette_%s_%dClusters.png',batchtable.modelname{:},k);
                    saveas(gcf, fullfile(exportpath,figfilename));
                    close(gcf);
                end
        end
    end
end