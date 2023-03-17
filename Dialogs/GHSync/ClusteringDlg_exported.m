classdef ClusteringDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgClustering       matlab.ui.Figure
        labelCallInfo       matlab.ui.control.TextArea
        labelClustName      matlab.ui.control.Label
        labelPageNofN       matlab.ui.control.Label
        labelTotalCount     matlab.ui.control.Label
        editfieldClustName  matlab.ui.control.EditField
        buttonRedo          matlab.ui.control.Button
        buttonSave          matlab.ui.control.Button
        buttonNextPage      matlab.ui.control.Button
        buttonNextClust     matlab.ui.control.Button
        buttonPrevPage      matlab.ui.control.Button
        buttonPrevClust     matlab.ui.control.Button
    end

    
    properties (Access = private)
        CallingApp % Description
        clustAssign
        ClusteringData
        currentCluster
        page
        count
        thumbnail_size
        rejected
        minfreq
        maxfreq
        image_axes
        handle_image
        ColorData
        clusterName
        clusters
        finished
    end
    
    methods (Access = private)
        
        function render_GUI(app)
            %% Colormap
            xdata = app.minfreq:app.maxfreq;
            caxis = axes(app.dlgClustering,'Units','Normalized','Position',[.92 .05 .04 .8]);
            image(1,xdata,app.ColorData,'parent',caxis)
            caxis.YDir = 'normal';
            set(caxis,'YColor','w','box','off','YAxisLocation','right');
            ylabel(caxis, 'Frequency (kHz)')
            
            %% Make the axes
            aspectRatio = median(cellfun(@(im) size(im,1) ./ size(im,2), app.ClusteringData.Spectrogram));
           
            app.thumbnail_size = round(sqrt(20000 .* [aspectRatio, 1/aspectRatio]));

            axes_spacing = .70; % Relative width of each image
            y_range = [.07, .8]; % [Start, End] of the grid
            x_range = [.05, .9];
            x_grids = 9; % Number of x grids
            y_grids = 3; % Number of y grids

            ypos = linspace(y_range(1), y_range(2) - axes_spacing * range(y_range) / y_grids, y_grids );
            xpos = linspace(x_range(1), x_range(2) - axes_spacing * range(x_range) / x_grids, x_grids );
            xpos = fliplr(xpos);

            pos = [];
            for i = 1:length(ypos)
                for j = 1:length(xpos)
                    pos(end+1,:) = [xpos(j), ypos(i), (xpos(1)-xpos(2)) * axes_spacing, (ypos(2)-ypos(1)) * axes_spacing];
                end
            end
            pos = flipud(pos);
            for i = 1 : length(ypos) * length(xpos)
                    im = zeros([app.thumbnail_size, 3]);
                    app.image_axes(i) = axes(app.dlgClustering,'Units','Normalized','Position',pos(i,:));
                    app.handle_image(i) = image(im,'parent',app.image_axes(i));
                    set(app.image_axes(i),'Visible','off')
                    set(get(app.image_axes(i),'children'),'Visible','off');
            end
            plotimages(app);
        end
        
        function plotimages(app)
            % Number of calls in each cluster
            for cl = 1:length(app.clusterName)
                app.count(cl) = sum(app.clustAssign==app.clusters(cl));
            end
            
            clustIndex = find(app.clustAssign==app.clusters(app.currentCluster));
            
            for i=1:length(app.image_axes)
                if i <= length(clustIndex) - (app.page - 1)*length(app.image_axes)
                    
                    set(get(app.image_axes(i),'children'),'Visible','on');
                    
                    callID = i + (app.page - 1)*length(app.image_axes);
                    [colorIM, rel_x, rel_y] = create_thumbnail(app,app.ClusteringData,clustIndex,callID);
                    set(app.handle_image(i), 'ButtonDownFcn',@(src,event) imgclicked(app,src,event,clustIndex(callID),i,callID));
                    add_cluster_context_menu(app, app.handle_image(i),clustIndex(callID));
                    
                    % Display the file ID and call number on mouse hover
                    [~,call_file,~] = fileparts(app.ClusteringData.Filename(clustIndex(callID)));
                    sUID = 'N/A';
                    sType = 'N/A';
                    sD2C = 'N/A';
                    sI = 'N/A';
                    sSil = 'N/A';
                    
                    if ismember('UserID',app.ClusteringData.Properties.VariableNames)
                        sUID = app.ClusteringData.UserID(clustIndex(callID));
                    end
                    if ismember('Type',app.ClusteringData.Properties.VariableNames)
                        sType = app.ClusteringData.Type(clustIndex(callID));
                    end
                    if ismember('DistToCen',app.ClusteringData.Properties.VariableNames)
                        sD2C = app.ClusteringData.DistToCen(clustIndex(callID));
                    end
                    if ismember('NumInflPts',app.ClusteringData.Properties.VariableNames)
                        sI = app.ClusteringData.NumInflPts(clustIndex(callID));
                    end
                    if ismember('Silhouette',app.ClusteringData.Properties.VariableNames)
                        sSil = app.ClusteringData.Silhouette(clustIndex(callID));
                    end

                    call_id = sprintf('Call: %u  UserID: %s  Type: %s', ...
                        app.ClusteringData.callID(clustIndex(callID)), ...
                        sUID, ...
                        sType);
                    call_stats = sprintf('Dist to Cent: %0.4f  Silh Val: %0.4f  # Infl Pts: %d', ...
                        sD2C, ...
                        sSil, ...
                        sI);
                    pointerBehavior.enterFcn = @(~,~) set(app.labelCallInfo, 'Value', {call_id, call_stats, call_file});
                    pointerBehavior.traverseFcn = [];
                    pointerBehavior.exitFcn = @(~,~) set(app.labelCallInfo, 'Value', '');
                    iptSetPointerBehavior(app.handle_image(i), pointerBehavior);

                    % Make the image red if the call is rejected
                    if app.rejected(clustIndex(callID))
                        colorIM(:,:,1) = colorIM(:,:,1) + .5;
                    end
                    
                    set(app.handle_image(i),'CData',colorIM, 'XData', []);
                    
                    config_axis(app, app.image_axes(i),clustIndex(callID), rel_x, rel_y);
                    
                    set(app.image_axes(i),'Visible','on')
                else
                    set(app.image_axes(i),'Visible','off')
                    set(get(app.image_axes(i),'children'),'Visible','off');
                end
            end
            
            % Update text
            app.labelPageNofN.Text = sprintf('Page %u of %u', app.page, ceil(app.count(app.currentCluster) / length(app.image_axes)));
            app.editfieldClustName.Value = string(app.clusterName(app.currentCluster));
            app.labelTotalCount.Text = sprintf('Total Count: %u', app.count(app.currentCluster));
            app.labelClustName.Text = sprintf('Cluster %u of %u', app.currentCluster, length(app.count));
        end
        
        function [colorIM, rel_x, rel_y] = create_thumbnail(app, ClusteringData,clustIndex,callID)
            % Resize the image while maintaining the aspect ratio by
            % padding with zeros
            im_size = size(ClusteringData.Spectrogram{clustIndex(callID)}) ;
            new_size = app.thumbnail_size;
            im = double(imresize(ClusteringData.Spectrogram{clustIndex(callID)}, app.thumbnail_size));
            pad = (app.thumbnail_size - size(im)) / 2;
            im = padarray(im, floor(pad), 'pre');
            im = padarray(im, ceil(pad), 'post');
            
            % Relative offsets for setting the tick values
            rel_size = pad ./ app.thumbnail_size;
            rel_x = [rel_size(2), 1-rel_size(2)];
            rel_y = [rel_size(1), 1-rel_size(1)];
            
            % Apply color to the greyscale images
            colorIM = ind2rgb(im,inferno(256));
            
            if ismember('NumContPts',ClusteringData.Properties.VariableNames) && ~all(ClusteringData.NumContPts==0)
                %Overlay the contour used for the k-means clustering
                resz = new_size./im_size;    
                contourtime = cell2mat(app.ClusteringData.xTime_Contour(clustIndex(callID)));
                contourfreq = cell2mat(app.ClusteringData.xFreq_Contour(clustIndex(callID)));

                conttIP = cell2mat(app.ClusteringData.InflPtVec(clustIndex(callID)));
                contfIP = contourfreq(conttIP);
                conttIP = contourtime(conttIP);

                conttext = cell2mat(app.ClusteringData.ExtPtVec(clustIndex(callID)));
                contfext = contourfreq(conttext);
                conttext = contourtime(conttext);

                ploty = resz(1)*contourfreq/ClusteringData.FreqScale(clustIndex(callID))+pad(1);
                plotyIP = resz(1)*contfIP/ClusteringData.FreqScale(clustIndex(callID))+pad(1);
                plotyext = resz(1)*contfext/ClusteringData.FreqScale(clustIndex(callID))+pad(1);

                %Save for later - compatible with update that saves only
                %spectrograms within boxes to ClusteringData
                %ploty = resz(1)*(contourfreq-ClusteringData.MinFreq(clustIndex(callID)))/ClusteringData.FreqScale(clustIndex(callID))+pad(1);
                
                ploty = size(colorIM,1)-ploty;
                plotyIP = size(colorIM,1)-plotyIP;
                plotyext = size(colorIM,1)-plotyext;
                plotx = resz(2)*contourtime/ClusteringData.TimeScale(clustIndex(callID))+pad(2);
                plotxIP = resz(2)*conttIP/ClusteringData.TimeScale(clustIndex(callID))+pad(2);
                plotxext = resz(2)*conttext/ClusteringData.TimeScale(clustIndex(callID))+pad(2);
                
%                 dotheight = 1;
%                 dotlength = 5;
%                 
%                 if ClusteringData.IsJen(clustIndex(callID)) == 1
                    % Trying to deal with different spectrogram resolutions
                    % Dot length should be two unless the resolution is
                    % such that time steps are wide relative to freq, then should be 1
                    dlmin = min(2,floor(size(colorIM,2)/ClusteringData.NumContPts(clustIndex(callID))));
                    dlmin = max(dlmin, 1);
                    dotheight = max(floor(size(colorIM,1)/size(colorIM,2)/2),2);
                    dotlength = max(floor(size(colorIM,2)/size(colorIM,1)/2),dlmin);
%                     dotheight = min(dotheight,5);
%                     dotlength = min(dotlength,5);
%                 end
                
                %Limit values for boundary/indexing issues
                plotx(plotx<1) = 1;
                ploty(ploty<1) = 1;
                plotx(plotx>(size(colorIM,2)-dotlength)) = size(colorIM,2)-dotlength;
                ploty(ploty>(size(colorIM,1)-dotheight)) = size(colorIM,1)-dotheight;
                plotxIP(plotxIP<1) = 1;
                plotyIP(plotyIP<1) = 1;
                plotxIP(plotxIP>(size(colorIM,2)-dotlength)) = size(colorIM,2)-dotlength;
                plotyIP(plotyIP>(size(colorIM,1)-dotheight)) = size(colorIM,1)-dotheight;
                plotxext(plotxext<1) = 1;
                plotyext(plotyext<1) = 1;
                plotxext(plotxext>(size(colorIM,2)-dotlength)) = size(colorIM,2)-dotlength;
                plotyext(plotyext>(size(colorIM,1)-dotheight)) = size(colorIM,1)-dotheight;

                for i = 1:length(ploty)
                    maxd1 = size(colorIM,1);
                    maxd2 = size(colorIM,2);
                    maxd1 = min(maxd1,int16(ploty(i))+dotheight);
                    maxd2 = min(maxd2,int16(plotx(i))+dotlength);
                    colorIM(int16(ploty(i)):maxd1,int16(plotx(i)):maxd2,:) = colorIM(int16(ploty(i)):maxd1,int16(plotx(i)):maxd2,:)+0.75;
                end
                for i = 1:length(plotyIP)
                    maxd1 = size(colorIM,1);
                    maxd2 = size(colorIM,2);
                    maxd1 = min(maxd1,int16(plotyIP(i))+dotheight);
                    maxd2 = min(maxd2,int16(plotxIP(i))+dotlength);
                    colorIM(int16(plotyIP(i)):maxd1,int16(plotxIP(i)):maxd2,1:2) = 0;
                end
                for i = 1:length(plotyext)
                    maxd1 = size(colorIM,1);
                    maxd2 = size(colorIM,2);
                    maxd1 = min(maxd1,int16(plotyext(i))+dotheight);
                    maxd2 = min(maxd2,int16(plotxext(i))+dotlength);
                    colorIM(int16(plotyext(i)):maxd1,int16(plotxext(i)):maxd2,1) = 0;
                    colorIM(int16(plotyext(i)):maxd1,int16(plotxext(i)):maxd2,3) = 0;
                    colorIM(int16(plotyext(i)):maxd1,int16(plotxext(i)):maxd2,2) = 0.5;
                end
            end
        end

        % Click image to toggle rejected/not
        function imgclicked(app,~,event,i,plotI,callID)
            if( event.Button ~= 1 ) % Return if not left clicked
                return
            end
            % clustIndex + callID used in create_thumbnail to index the
            % call
            clustIndex = find(app.clustAssign == app.clusters(app.currentCluster));
            % Toggle rejected/not
            app.rejected(i) = ~app.rejected(i);
            % Recreate thumbnail accordingly
            [colorIM, ~, ~] = app.create_thumbnail(app.ClusteringData,clustIndex,callID);
            if app.rejected(i)
                colorIM(:,:,1) = colorIM(:,:,1) + .5;
            end            
            set(app.handle_image(plotI),'CData',colorIM);
        end

        % Create Cluster Reassignment Menu
        function add_cluster_context_menu(app, clickedimg, i)
            unique_clusters = unique(app.clusterName);
            
            c = uicontextmenu(app.dlgClustering);
            for ci=1:length(unique_clusters)
                uimenu(c,'text',string(app.clusterName(ci)),'Callback',@(src,event) assign_cluster(app,src,event,i,unique_clusters(ci)));
            end
            
            % Assign cluster reassignment menu to clicked image
            set(clickedimg, 'UIContextMenu',c);
        end
        
        % If Context Menu used to select new cluster, reassign cluster and
        % regenerate images
        function assign_cluster(app,~,~,i, clusterLabel)
            app.clustAssign(i) = clusterLabel;
            plotimages(app);
        end
        
        function config_axis(app, axis_handles,i, rel_x, rel_y)
            set(axis_handles,'xcolor','w');
            set(axis_handles,'ycolor','w');
            
            x_lim = xlim(axis_handles);
            x_span = x_lim(2) - x_lim(1);
            xtick_positions = linspace(x_span*rel_x(1)+x_lim(1), x_span*rel_x(2)+x_lim(1),4);
            x_ticks = linspace(0,size(app.ClusteringData.Spectrogram{i},2)*app.ClusteringData.TimeScale(i),4);
            x_ticks = arrayfun(@(x) sprintf('%.3f',x),x_ticks(2:end),'UniformOutput',false);
            
            y_lim = ylim(axis_handles);
            y_span = y_lim(2) - y_lim(1);
            ytick_positions = linspace(y_span*rel_y(1)+y_lim(1), y_span*rel_y(2)+y_lim(1),4);            
            
            %Save for later - compatible with update that saves only boxed
            %call
            %y_ticks = linspace(obj.ClusteringData.MinFreq(i),obj.ClusteringData.MinFreq(i)+obj.ClusteringData.Bandwidth(i),3);
            y_ticks = linspace(app.minfreq,app.maxfreq,4);
            y_ticks = arrayfun(@(x) sprintf('%.1f',x),y_ticks(1:end),'UniformOutput',false);
            y_ticks = flip(y_ticks);
            
            yticks(axis_handles,ytick_positions);
            xticks(axis_handles,xtick_positions(2:end));
            xticklabels(axis_handles,x_ticks);
            yticklabels(axis_handles,y_ticks);
            
            sUID = 'N/A';
            sType = 'N/A';
            sD2C = 'N/A';
            sI = 'N/A';
            sSil = 'N/A';
            if ismember('UserID',app.ClusteringData.Properties.VariableNames)
                sUID = app.ClusteringData.UserID(i);
            end
            if ismember('Type',app.ClusteringData.Properties.VariableNames)
                sType = app.ClusteringData.Type(i);
            end
            if ismember('DistToCen',app.ClusteringData.Properties.VariableNames)
                sD2C = app.ClusteringData.DistToCen(i);
            end
            if ismember('NumInflPts',app.ClusteringData.Properties.VariableNames)
                sI = app.ClusteringData.NumInflPts(i);
            end
            if ismember('Silhouette',app.ClusteringData.Properties.VariableNames)
                sSil = app.ClusteringData.Silhouette(i);
            end
            
            title(axis_handles,{sprintf('%s %s I: %d',sUID, sType, sI); ...
                sprintf('D: %0.3f  S: %0.3f', sD2C, sSil)}, ...
                'Color','white','Interpreter','none');
            
            xlabel(axis_handles,'Time (s)');
            ylabel(axis_handles,'Frequency (kHz)');
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp, clustAssign, ClusteringData)
            app.dlgClustering.Visible = 'off';
            
            app.CallingApp = mainapp;
            app.clustAssign = clustAssign;
            app.ClusteringData = ClusteringData;
            app.currentCluster = 1;
            app.page = 1;
            app.count = 0;
            app.thumbnail_size = [200 200];
            app.rejected = zeros(1,length(app.clustAssign)); 
            %This is going to be scaled from 0 to the Nyquist, not the
            %boxed call
            app.minfreq = 0;
            %Assumes all calls in ClusteringData were recorded at the same
            %SR
            app.maxfreq = size(app.ClusteringData.Spectrogram{1},1)*app.ClusteringData.FreqScale(1);
            app.image_axes = gobjects();
            app.handle_image = gobjects();
            app.ColorData = jet(256); % Color by mean frequency
            app.ColorData = reshape(app.ColorData,size(app.ColorData,1),1,size(app.ColorData,2));

            if iscategorical(app.clustAssign)
                app.clusterName = unique(app.clustAssign);
                app.clusters = unique(app.clustAssign);
            else
                app.clusterName = categorical(unique(app.clustAssign(~isnan(app.clustAssign))));
                app.clusters = (unique(app.clustAssign(~isnan(app.clustAssign))));
            end

            app.finished = 2;

            movegui(app.dlgClustering,"center");
            app.render_GUI();

            % Wait for d to close before running to completion
            set( findall(app.dlgClustering, '-property', 'Units' ), 'Units', 'Normalized');
            app.dlgClustering.Visible = 'on';
            
            % Enable pointer management for the figure for mouse hover over
            iptPointerManager(app.dlgClustering, 'enable');
        end

        % Close request function: dlgClustering
        function dlgClusteringCloseRequest(app, event)
            % Pass values to parent app
            app.CallingApp.rejected = app.rejected;
            app.CallingApp.finished = app.finished;
            app.CallingApp.clusterName = app.clusterName;
            app.CallingApp.clustAssign = app.clustAssign;

            delete(app)
        end

        % Value changed function: editfieldClustName
        function editfieldClustNameChanged_Callback(app, event)
            app.clusterName(app.currentCluster) = app.editfieldClustName.Value;
        end

        % Button pushed function: buttonPrevClust
        function buttonPrevClust_Callback(app, event)
            app.clusterName(app.currentCluster) = app.editfieldClustName.Value;
            if app.currentCluster > 1
                app.currentCluster = app.currentCluster-1;
                app.page = 1;
                app.plotimages();
            end
        end

        % Button pushed function: buttonNextClust
        function buttonNextClust_Callback(app, event)
            app.clusterName(app.currentCluster) = app.editfieldClustName.Value;
            if app.currentCluster < length(app.clusterName)
                app.currentCluster = app.currentCluster + 1;
                app.page = 1;
                app.plotimages();
            end
        end

        % Button pushed function: buttonSave
        function buttonSave_Callback(app, event)
            app.finished = 1;
            
            % Progress bar to disable user access to GUI
            dlgprog = uiprogressdlg(app.dlgClustering,'Title','Saving In Progress',...
                'Indeterminate','on');
            drawnow

            % Get default path for Save Dialog (location of detections.mat)
            pind = regexp(char(app.ClusteringData{1,'Filename'}),'\');
            pind = pind(end);
            pname = char(app.ClusteringData{1,'Filename'});
            pname = pname(1:pind);

            % Run Save dialog
            app.CallingApp.RunUnsupClustSaveDlg(pname);
            
            % Save the cluster images
            switch app.CallingApp.bClustImg
                case true
                    % Start at beginning
                    app.currentCluster = 1;
                    app.page = 1;
                    app.plotimages();
                    
                    % Cycle through all clusters
                    numclusts = length(app.clusterName);
                    for i = 1:numclusts
                        % Save current display
                        thisfnm = ['ClusteringImg_',sprintf('%03d',app.currentCluster),'_',sprintf('%03d',app.page),'.png'];
                        exportapp(app.dlgClustering,fullfile(app.CallingApp.strUnsupSaveLoc,thisfnm));
                        % Cycle through all pages for that
                        % cluster
                        numpgs = ceil(app.count(app.currentCluster) / length(app.image_axes));
                        for j = 1:numpgs-1
                            % Next page
                            buttonNextPage_Callback(app, event);
                            % Save current display
                            thisfnm = ['ClusteringImg_',sprintf('%03d',app.currentCluster),'_',sprintf('%03d',app.page),'.png'];
                            exportapp(app.dlgClustering,fullfile(app.CallingApp.strUnsupSaveLoc,thisfnm));
                        end
                        % Next cluster
                        buttonNextClust_Callback(app, event);
                    end
                case false
            end
            % Close progress dialog
            close(dlgprog)
            % Close Clustering GUI
            dlgClusteringCloseRequest(app, event)
        end

        % Button pushed function: buttonRedo
        function buttonRedo_Callback(app, event)
            app.finished = 0;
            dlgClusteringCloseRequest(app, event)
        end

        % Button pushed function: buttonNextPage
        function buttonNextPage_Callback(app, event)
            if app.page < ceil(app.count(app.currentCluster) / length(app.image_axes))
                app.page = app.page + 1;
                app.plotimages();
            end
        end

        % Button pushed function: buttonPrevPage
        function buttonPrevPage_Callback(app, event)
            if app.page > 1
                app.page = app.page - 1;
                app.plotimages();
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create dlgClustering and hide until all components are created
            app.dlgClustering = uifigure('Visible', 'off');
            app.dlgClustering.Color = [0.102 0.102 0.102];
            colormap(app.dlgClustering, 'parula');
            app.dlgClustering.Position = [360 500 1373 857];
            app.dlgClustering.Name = 'Clustering Dialog';
            app.dlgClustering.CloseRequestFcn = createCallbackFcn(app, @dlgClusteringCloseRequest, true);
            app.dlgClustering.WindowStyle = 'modal';

            % Create buttonPrevClust
            app.buttonPrevClust = uibutton(app.dlgClustering, 'push');
            app.buttonPrevClust.ButtonPushedFcn = createCallbackFcn(app, @buttonPrevClust_Callback, true);
            app.buttonPrevClust.BackgroundColor = [0.149 0.251 0.251];
            app.buttonPrevClust.FontColor = [1 1 1];
            app.buttonPrevClust.Position = [31 801 123 30];
            app.buttonPrevClust.Text = 'Previous Cluster';

            % Create buttonPrevPage
            app.buttonPrevPage = uibutton(app.dlgClustering, 'push');
            app.buttonPrevPage.ButtonPushedFcn = createCallbackFcn(app, @buttonPrevPage_Callback, true);
            app.buttonPrevPage.BackgroundColor = [0.149 0.251 0.251];
            app.buttonPrevPage.FontColor = [1 1 1];
            app.buttonPrevPage.Position = [31 764 123 30];
            app.buttonPrevPage.Text = 'Previous Page';

            % Create buttonNextClust
            app.buttonNextClust = uibutton(app.dlgClustering, 'push');
            app.buttonNextClust.ButtonPushedFcn = createCallbackFcn(app, @buttonNextClust_Callback, true);
            app.buttonNextClust.BackgroundColor = [0.149 0.251 0.251];
            app.buttonNextClust.FontColor = [1 1 1];
            app.buttonNextClust.Position = [352 801 123 30];
            app.buttonNextClust.Text = 'Next Cluster';

            % Create buttonNextPage
            app.buttonNextPage = uibutton(app.dlgClustering, 'push');
            app.buttonNextPage.ButtonPushedFcn = createCallbackFcn(app, @buttonNextPage_Callback, true);
            app.buttonNextPage.BackgroundColor = [0.149 0.251 0.251];
            app.buttonNextPage.FontColor = [1 1 1];
            app.buttonNextPage.Position = [352 764 123 30];
            app.buttonNextPage.Text = 'Next Page';

            % Create buttonSave
            app.buttonSave = uibutton(app.dlgClustering, 'push');
            app.buttonSave.ButtonPushedFcn = createCallbackFcn(app, @buttonSave_Callback, true);
            app.buttonSave.BackgroundColor = [0.149 0.251 0.251];
            app.buttonSave.FontColor = [1 1 1];
            app.buttonSave.Position = [1083 801 123 30];
            app.buttonSave.Text = 'Save';

            % Create buttonRedo
            app.buttonRedo = uibutton(app.dlgClustering, 'push');
            app.buttonRedo.ButtonPushedFcn = createCallbackFcn(app, @buttonRedo_Callback, true);
            app.buttonRedo.BackgroundColor = [0.149 0.251 0.251];
            app.buttonRedo.FontColor = [1 1 1];
            app.buttonRedo.Position = [1218 801 123 30];
            app.buttonRedo.Text = 'Redo';

            % Create editfieldClustName
            app.editfieldClustName = uieditfield(app.dlgClustering, 'text');
            app.editfieldClustName.ValueChangedFcn = createCallbackFcn(app, @editfieldClustNameChanged_Callback, true);
            app.editfieldClustName.HorizontalAlignment = 'center';
            app.editfieldClustName.FontColor = [1 1 1];
            app.editfieldClustName.BackgroundColor = [0.149 0.251 0.251];
            app.editfieldClustName.Position = [184 784 152 26];

            % Create labelTotalCount
            app.labelTotalCount = uilabel(app.dlgClustering);
            app.labelTotalCount.FontColor = [1 1 1];
            app.labelTotalCount.Position = [489 804 99 22];
            app.labelTotalCount.Text = 'Total Count: ';

            % Create labelPageNofN
            app.labelPageNofN = uilabel(app.dlgClustering);
            app.labelPageNofN.FontColor = [1 1 1];
            app.labelPageNofN.Position = [226 763 67 22];
            app.labelPageNofN.Text = 'Page # of #';

            % Create labelClustName
            app.labelClustName = uilabel(app.dlgClustering);
            app.labelClustName.FontColor = [1 1 1];
            app.labelClustName.Position = [219 809 82 22];
            app.labelClustName.Text = 'Cluster Name:';

            % Create labelCallInfo
            app.labelCallInfo = uitextarea(app.dlgClustering);
            app.labelCallInfo.HorizontalAlignment = 'center';
            app.labelCallInfo.FontSize = 16;
            app.labelCallInfo.FontColor = [1 1 1];
            app.labelCallInfo.BackgroundColor = [0 0 0];
            app.labelCallInfo.Position = [587 757 479 81];
            app.labelCallInfo.Value = {'Call:   UserID:   Type:   '; 'Dist to Cent:   Silhouette Val:   NumInfl Pts:   '; 'Filename:'};

            % Show the figure after all components are created
            app.dlgClustering.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ClusteringDlg_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.dlgClustering)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.dlgClustering)
        end
    end
end