classdef clusteringGUI < handle
    
    properties
        currentCluster = 1
        page = 1
        thumbnail_size = [200 200]
        clustAssign
        clusters
        rejected
        ClusteringData
        minfreq
        maxfreq
        fig
        image_axes = gobjects()
        handle_image = gobjects()
        ColorData
        totalCount
        count
        clusterName
        pagenumber
        finished
        call_id_text      
        txtbox
    end
    
    methods
        function [obj, NewclusterName, NewRejected, NewFinished, NewClustAssign] = clusteringGUI(clustAssign, ClusteringData, parentapp, parentevent)
            
            obj.clustAssign = clustAssign;
            %Image, Lower freq, delta time, Time points, Freq points, File path, Call ID in file, power, RelBox
            obj.ClusteringData = ClusteringData;
            obj.rejected = zeros(1,length(obj.clustAssign));
            
%             obj.minfreq = prctile(ClusteringData.MinFreq, 5);
%             obj.maxfreq = prctile(ClusteringData.MinFreq + ClusteringData.Bandwidth, 95);
            %This is going to be scaled from 0 to the Nyquist, not the
            %boxed call
            obj.minfreq = 0;
            %Assumes all calls in ClusteringData were recorded at the same
            %SR
            obj.maxfreq = size(ClusteringData.Spectrogram{1},1)*ClusteringData.FreqScale(1);
            obj.ColorData = jet(256); % Color by mean frequency
            % obj.ColorData = HSLuv_to_RGB(256, 'H',  [270 0], 'S', 100, 'L', 75, 'type', 'HSL'); % Make a color map for each category
            obj.ColorData = reshape(obj.ColorData,size(obj.ColorData,1),1,size(obj.ColorData,2));
            
            if iscategorical(obj.clustAssign)
                obj.clusterName =unique(obj.clustAssign);
                obj.clusters = unique(obj.clustAssign);
            else
                obj.clusterName = categorical(unique(obj.clustAssign(~isnan(obj.clustAssign))));
                obj.clusters = (unique(obj.clustAssign(~isnan(obj.clustAssign))));
            end
            
            obj.fig = dialog('Visible','off','Position',[360,500,600,600],'WindowStyle','Normal','resize', 'on','WindowState','maximized' );
            obj.fig.CloseRequestFcn = @(src,event) finished_Callback(obj, src, event, parentapp, parentevent);
            set(obj.fig,'color',[.1, .1, .1]);
            
            movegui(obj.fig,'center');
            %             set(obj.fig,'WindowButtonMotionFcn', @(hObject, eventdata) mouse_over_Callback(obj, hObject, eventdata));
            
            txt = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.1 .1 .1],...
                'ForegroundColor','w',...
                'Style','text',...
                'Position',[120 565 80 30],...
                'String','Name:');
            
            obj.txtbox = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Style','edit',...
                'String','',...
                'Position',[120 550 80 30],...
                'Callback',@(src,event) txtbox_Callback(obj,src,event));
            
            
            obj.totalCount = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.1 .1 .1],...
                'ForegroundColor','w',...
                'Style','text',...
                'String','',...
                'Position',[330 542.5 200 30],...
                'HorizontalAlignment','left');
            
            
            back = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[20 550 80 30],...
                'String','Back',...
                'Callback',@(src,event) back_Callback(obj, src, event));
            
            next = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[220 550 80 30],...
                'String','Next',...
                'Callback',@(src,event) next_Callback(obj, src, event));
            
            apply = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[440 550 60 30],...
                'String','Save',...
                'Callback',@(src,event)  finished_Callback(obj, src, event, parentapp, parentevent));
            
            if nargin == 2
                redo = uicontrol('Parent',obj.fig,...
                    'BackgroundColor',[.149 .251 .251],...
                    'ForegroundColor','w',...
                    'Position',[510 550 60 30],...
                    'String','Redo',...
                    'Callback',@(src,event) finished_Callback(obj, src, event, parentapp, parentevent));
            else
                redo = uicontrol('Parent',obj.fig,...
                    'BackgroundColor',[.149 .251 .251],...
                    'ForegroundColor','w',...
                    'Position',[510 550 60 30],...
                    'String','Cancel',...
                    'Callback',@(src,event) finished_Callback(obj, src, event, parentapp, parentevent));
            end
            %% Paging
            nextpage = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[220 517 80 30],...
                'String','Next Page',...
                'Callback',@(src,event) nextpage_Callback(obj, src, event));
            
            backpage = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.149 .251 .251],...
                'ForegroundColor','w',...
                'Position',[20 517 80 30],...
                'String','Previous Page',...
                'Callback',@(src,event, h) backpage_Callback(obj, src, event));
            
            obj.pagenumber = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.1 .1 .1],...
                'ForegroundColor','w',...
                'Style','text',...
                'String','',...
                'Position',[118 509 80 30],...
                'HorizontalAlignment','center');
            
            
%             obj.call_id_text = uicontrol('Parent',obj.fig,...
%                 'BackgroundColor',[.1 .1 .1],...
%                 'ForegroundColor','w',...
%                 'Style','text',...
%                 'String','',...
%                 'FontSize',12,...
%                 'Position',[100 470 400 30],...
%                 'HorizontalAlignment','center');
            obj.call_id_text = uicontrol('Parent',obj.fig,...
                'BackgroundColor',[.1 .1 .1],...
                'ForegroundColor','w',...
                'Style','text',...
                'String','',...
                'FontSize',10,...
                'Position',[320 495 250 45],...
                'HorizontalAlignment','center');
            
            
            obj.render_GUI();
            
            % Wait for d to close before running to completion
            set( findall(obj.fig, '-property', 'Units' ), 'Units', 'Normalized');
            obj.fig.Visible = 'on';
            
            % Enable pointer management for the figure for mouse hover over
            iptPointerManager(obj.fig, 'enable');
                    
            uiwait(obj.fig);
            NewclusterName = obj.clusterName;
            NewRejected = obj.rejected;
            NewFinished = obj.finished;
            NewClustAssign = obj.clustAssign;
            
        end
        
        function render_GUI(obj)
            
            %% Colormap
            xdata = obj.minfreq:obj.maxfreq;
            caxis = axes(obj.fig,'Units','Normalized','Position',[.88 .05 .04 .8]);
            image(1,xdata,obj.ColorData,'parent',caxis)
            caxis.YDir = 'normal';
            set(caxis,'YColor','w','box','off','YAxisLocation','right');
            ylabel(caxis, 'Frequency (kHz)')
            
            %% Make the axes
            aspectRatio = median(cellfun(@(im) size(im,1) ./ size(im,2), obj.ClusteringData.Spectrogram));
            
            % Choose a number of rows and columns to fill the space with
            % the average call aspect ratio
            % nFrames = 10;
            % figureAspectRatio = 1;
            % x_grids = sqrt(aspectRatio * figureAspectRatio * nFrames);
            % x_grids = ceil(x_grids);
            % y_grids = ceil(nFrames / x_grids);
        
            obj.thumbnail_size = round(sqrt(20000 .* [aspectRatio, 1/aspectRatio]));

            axes_spacing = .70; % Relative width of each image
            y_range = [.05, .75]; % [Start, End] of the grid
            x_range = [.05, .85];
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
                    im = zeros([obj.thumbnail_size, 3]);
                    obj.image_axes(i) = axes(obj.fig,'Units','Normalized','Position',pos(i,:));
                    obj.handle_image(i) = image(im,'parent',obj.image_axes(i));
                    set(obj.image_axes(i),'Visible','off')
                    set(get(obj.image_axes(i),'children'),'Visible','off');
            end
            plotimages(obj);
        end
        
        function [colorIM, rel_x, rel_y] = create_thumbnail(obj, ClusteringData,clustIndex,callID)
            % Resize the image while maintaining the aspect ratio by
            % padding with zeros
            im_size = size(ClusteringData.Spectrogram{clustIndex(callID)}) ;
            %new_size = floor(im_size .* min(obj.thumbnail_size ./ im_size));
            new_size = obj.thumbnail_size;
            im = double(imresize(ClusteringData.Spectrogram{clustIndex(callID)}, obj.thumbnail_size));
            %im = double(imresize(ClusteringData.Spectrogram{clustIndex(callID)}, new_size));
            pad = (obj.thumbnail_size - size(im)) / 2;
            im = padarray(im, floor(pad), 'pre');
            im = padarray(im, ceil(pad), 'post');
            
            % Relative offsets for setting the tick values
            rel_size = pad ./ obj.thumbnail_size;
            rel_x = [rel_size(2), 1-rel_size(2)];
            rel_y = [rel_size(1), 1-rel_size(1)];
            
%             % Apply color to the greyscale images
                %this type of color scaling isn't applicable as is because
                %all call images have the same frequency span
%             freqRange = [ClusteringData.MinFreq(clustIndex(callID)),...
%                 ClusteringData.MinFreq(clustIndex(callID)) + ClusteringData.Bandwidth(clustIndex(callID))];
%             freqRange = [obj.minfreq, obj.maxfreq];
%             % Account for any padding on the y axis
%             freqRange = freqRange + range(freqRange) .* rel_y(1) .* [-1, 1];

%             freqdata = linspace(freqRange(2) ,freqRange(1), obj.thumbnail_size(1));
%             colorMask = interp1(linspace(obj.minfreq, obj.maxfreq, size(obj.ColorData,1)), obj.ColorData, freqdata, 'nearest', 'extrap');
%             colorIM = im .* colorMask ./ 255;
            colorIM = ind2rgb(im,inferno(256));
            
            if ismember('NumContPts',ClusteringData.Properties.VariableNames) && ~all(ClusteringData.NumContPts==0)
                %Overlay the contour used for the k-means clustering
                resz = new_size./im_size;            
                %contourfreq = cell2mat(cellfun(@(x) imresize(x',[1 ClusteringData.NumContPts(clustIndex(callID))]) ,table2cell(obj.ClusteringData(clustIndex(callID),'xFreq')),'UniformOutput',0));
                %contourtime = cell2mat(cellfun(@(x) imresize(x',[ClusteringData.NumContPts(clustIndex(callID)) 1]) ,table2cell(obj.ClusteringData(clustIndex(callID),'xTime')),'UniformOutput',0))';
                
                contourtime = cell2mat(obj.ClusteringData.xTime_Contour(clustIndex(callID)));
                contourfreq = cell2mat(obj.ClusteringData.xFreq_Contour(clustIndex(callID)));
                
                conttIP = cell2mat(obj.ClusteringData.InflPtVec(clustIndex(callID)));
                contfIP = contourfreq(conttIP);
                conttIP = contourtime(conttIP);

                conttext = cell2mat(obj.ClusteringData.ExtPtVec(clustIndex(callID)));
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
        
        function obj = config_axis(obj, axis_handles,i, rel_x, rel_y)
            set(axis_handles,'xcolor','w');
            set(axis_handles,'ycolor','w');
            
            x_lim = xlim(axis_handles);
            x_span = x_lim(2) - x_lim(1);
            xtick_positions = linspace(x_span*rel_x(1)+x_lim(1), x_span*rel_x(2)+x_lim(1),4);
            %x_ticks = linspace(0,obj.ClusteringData.Duration(i),4);
            x_ticks = linspace(0,size(obj.ClusteringData.Spectrogram{i},2)*obj.ClusteringData.TimeScale(i),4);
            x_ticks = arrayfun(@(x) sprintf('%.3f',x),x_ticks(2:end),'UniformOutput',false);
            
            y_lim = ylim(axis_handles);
            y_span = y_lim(2) - y_lim(1);
            ytick_positions = linspace(y_span*rel_y(1)+y_lim(1), y_span*rel_y(2)+y_lim(1),4);            
            
            
            %Save for later - compatible with update that saves only boxed
            %call
            %y_ticks = linspace(obj.ClusteringData.MinFreq(i),obj.ClusteringData.MinFreq(i)+obj.ClusteringData.Bandwidth(i),3);
            y_ticks = linspace(obj.minfreq,obj.maxfreq,4);
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
            if ismember('UserID',obj.ClusteringData.Properties.VariableNames)
                sUID = obj.ClusteringData.UserID(i);
            end
            if ismember('Type',obj.ClusteringData.Properties.VariableNames)
                sType = obj.ClusteringData.Type(i);
            end
            if ismember('DistToCen',obj.ClusteringData.Properties.VariableNames)
                sD2C = obj.ClusteringData.DistToCen(i);
            end
            if ismember('NumInflPts',obj.ClusteringData.Properties.VariableNames)
                sI = obj.ClusteringData.NumInflPts(i);
            end
            if ismember('Silhouette',obj.ClusteringData.Properties.VariableNames)
                sSil = obj.ClusteringData.Silhouette(i);
            end
            
            title(axis_handles,{sprintf('%s %s I: %d',sUID, sType, sI); ...
                sprintf('D: %0.3f  S: %0.3f', sD2C, sSil)}, ...
                'Color','white','Interpreter','none');
            
%             if any(strcmp('Type', obj.ClusteringData.Properties.VariableNames)) && ...
%                     any(strcmp('DistToCen', obj.ClusteringData.Properties.VariableNames)) 
%                 if any(strcmp('UserID', obj.ClusteringData.Properties.VariableNames))
%                     title(axis_handles,{sprintf('%s %s I: %d',obj.ClusteringData.UserID(i), obj.ClusteringData.Type(i), obj.ClusteringData.NumInflPts(i)); ...
%                         sprintf('D: %0.3f  S: %0.3f', obj.ClusteringData.DistToCen(i), obj.ClusteringData.Silhouette(i))}, ...
%                         'Color','white','Interpreter','none');
%                 else
%                     title(axis_handles,{sprintf('%s I: %d', obj.ClusteringData.Type(i), obj.ClusteringData.NumInflPts(i));  ...
%                         sprintf('D: %0.3f  S: %0.3f', obj.ClusteringData.DistToCen(i), obj.ClusteringData.Silhouette(i))}, ...
%                         'Color','white','Interpreter','none');
%                 end
%             end
            xlabel(axis_handles,'Time (s)');
            ylabel(axis_handles,'Frequency (kHz)');
        end
        
        function obj = plotimages(obj)
            % Number of calls in each cluster
            for cl = 1:length(obj.clusterName)
                obj.count(cl) = sum(obj.clustAssign==obj.clusters(cl));
            end
            
            clustIndex = find(obj.clustAssign==obj.clusters(obj.currentCluster));
            
            for i=1:length(obj.image_axes)
                if i <= length(clustIndex) - (obj.page - 1)*length(obj.image_axes)
                    % set(image_axes(i),'Visible','off')
                    
                    set(get(obj.image_axes(i),'children'),'Visible','on');
                    
                    callID = i + (obj.page - 1)*length(obj.image_axes);
                    [colorIM, rel_x, rel_y] = obj.create_thumbnail(obj.ClusteringData,clustIndex,callID);
                    set(obj.handle_image(i), 'ButtonDownFcn',@(src,event) clicked(obj,src,event,clustIndex(callID),i,callID));
                    obj.add_cluster_context_menu(obj.handle_image(i),clustIndex(callID));
                    
                    
                    % Display the file ID and call number on mouse hover
                    [~,call_file,~] = fileparts(obj.ClusteringData.Filename(clustIndex(callID)));
                    sUID = 'N/A';
                    sType = 'N/A';
                    sD2C = 'N/A';
                    sI = 'N/A';
                    sSil = 'N/A';
                    
                    if ismember('UserID',obj.ClusteringData.Properties.VariableNames)
                        sUID = obj.ClusteringData.UserID(clustIndex(callID));
                    end
                    if ismember('Type',obj.ClusteringData.Properties.VariableNames)
                        sType = obj.ClusteringData.Type(clustIndex(callID));
                    end
                    if ismember('DistToCen',obj.ClusteringData.Properties.VariableNames)
                        sD2C = obj.ClusteringData.DistToCen(clustIndex(callID));
                    end
                    if ismember('NumInflPts',obj.ClusteringData.Properties.VariableNames)
                        sI = obj.ClusteringData.NumInflPts(clustIndex(callID));
                    end
                    if ismember('Silhouette',obj.ClusteringData.Properties.VariableNames)
                        sSil = obj.ClusteringData.Silhouette(clustIndex(callID));
                    end

                    call_id = sprintf('Call: %u  UserID: %s  Type: %s', ...
                        obj.ClusteringData.callID(clustIndex(callID)), ...
                        sUID, ...
                        sType);
                    call_stats = sprintf('Dist to Cent: %0.5f  Silhouette Val: %0.5f  Num Infl Pts: %d', ...
                        sD2C, ...
                        sSil, ...
                        sI);
%                     if any(strcmp('Type', obj.ClusteringData.Properties.VariableNames))
%                             if any(strcmp('UserID', obj.ClusteringData.Properties.VariableNames))
%                                 call_id = sprintf('Call: %u  UserID: %s  Type: %s', ...
%                                     obj.ClusteringData.callID(clustIndex(callID)), ...
%                                     obj.ClusteringData.UserID(clustIndex(callID)), ...
%                                     obj.ClusteringData.Type(clustIndex(callID)));
%                             else
%                                 call_id = sprintf('Call: %u  Type: %s', ...
%                                     obj.ClusteringData.callID(clustIndex(callID)), ...
%                                     obj.ClusteringData.Type(clustIndex(callID)));
%                             end
%                     else
%                         call_id = sprintf('Call: %u', obj.ClusteringData.callID(clustIndex(callID)));
%                     end
%                     if any(strcmp('DistToCen', obj.ClusteringData.Properties.VariableNames)) 
%                         if any(strcmp('Silhouette', obj.ClusteringData.Properties.VariableNames)) 
%                             call_stats = sprintf('Dist to Cent: %0.5f  Silhouette Val: %0.5f  Num Infl Pts: %d', ...
%                                 obj.ClusteringData.DistToCen(clustIndex(callID)), ...
%                                 obj.ClusteringData.Silhouette(clustIndex(callID)), ...
%                                 obj.ClusteringData.NumInflPts(clustIndex(callID)));
%                         else 
%                             call_stats = sprintf('Dist to Cent: %0.5f  Num Infl Pts: %d', ...
%                                 obj.ClusteringData.DistToCen(clustIndex(callID)), ...
%                                 obj.ClusteringData.NumInflPts(clustIndex(callID)));
%                         end
%                     else
%                         call_stats = '';
%                     end
                    pointerBehavior.enterFcn = @(~,~) set(obj.call_id_text, 'string', {call_id, call_stats, call_file});
                    pointerBehavior.traverseFcn = [];
                    pointerBehavior.exitFcn = @(~,~) set(obj.call_id_text, 'string', '');
                    iptSetPointerBehavior(obj.handle_image(i), pointerBehavior);



                    % Make the image red if the call is rejected
                    if obj.rejected(clustIndex(callID))
                        colorIM(:,:,1) = colorIM(:,:,1) + .5;
                    end
                    
                    set(obj.handle_image(i),'CData',colorIM, 'XData', []);
                    
                    obj.config_axis(obj.image_axes(i),clustIndex(callID), rel_x, rel_y);
                    
                    set(obj.image_axes(i),'Visible','on')
                    
                else
                    set(obj.image_axes(i),'Visible','off')
                    set(get(obj.image_axes(i),'children'),'Visible','off');
                end
                
            end
            
            % Update text
            obj.pagenumber.String = sprintf('Page %u of %u', obj.page, ceil(obj.count(obj.currentCluster) / length(obj.image_axes)));
            obj.txtbox.String = string(obj.clusterName(obj.currentCluster));
            obj.totalCount.String = sprintf('total count: %u', obj.count(obj.currentCluster));
            obj.fig.Name = sprintf('Cluster %u of %u', obj.currentCluster, length(obj.count));
            
        end
        
        function obj = add_cluster_context_menu(obj, hObject, i)
            unique_clusters = unique(obj.clusterName);
            
            c = uicontextmenu(obj.fig);
            for ci=1:length(unique_clusters)
                uimenu(c,'text',string(obj.clusterName(ci)),'Callback',@(src,event) assign_cluster(obj, src, event,i,unique_clusters(ci)));
            end
            
            set(hObject, 'UIContextMenu',c);
        end
        
        function obj = assign_cluster(obj, hObject,eventdata,i, clusterLabel)
            obj.clustAssign(i) = clusterLabel;
            obj.plotimages();
        end
        
        function obj = clicked(obj, hObject,eventdata,i,plotI,callID)
            if( eventdata.Button ~= 1 ) % Return if not left clicked
                return
            end
            
            clustIndex = find(obj.clustAssign == obj.clusters(obj.currentCluster));
            
            obj.rejected(i) = ~obj.rejected(i);
            
            [colorIM, ~, ~] = obj.create_thumbnail(obj.ClusteringData,clustIndex,callID);
           
            if obj.rejected(i)
                colorIM(:,:,1) = colorIM(:,:,1) + .5;
            end            
            set(obj.handle_image(plotI),'CData',colorIM);
        end
        
        function obj = next_Callback(obj, hObject, eventdata)
            obj.clusterName(obj.currentCluster) = get(obj.txtbox,'String');
            if obj.currentCluster < length(obj.clusterName)
                obj.currentCluster = obj.currentCluster + 1;
                obj.page = 1;
                obj.plotimages();
            end
        end
        
        function obj = back_Callback(obj, hObject, eventdata)
            obj.clusterName(obj.currentCluster) = get(obj.txtbox,'String');
            if obj.currentCluster > 1
                obj.currentCluster = obj.currentCluster-1;
                obj.page = 1;
                obj.plotimages();
            end
        end
        
        function obj = nextpage_Callback(obj, hObject, eventdata)
            if obj.page < ceil(obj.count(obj.currentCluster) / length(obj.image_axes))
                obj.page = obj.page + 1;
                obj.plotimages();
            end
        end
        
        function obj = backpage_Callback(obj, hObject, eventdata)
            if obj.page > 1
                obj.page = obj.page - 1;
                obj.plotimages();
            end
        end
        
        function obj = txtbox_Callback(obj, hObject, eventdata)
            obj.clusterName(obj.currentCluster) = get(hObject,'String');
        end

        function obj = finished_Callback(obj, hObject, eventdata, parentapp, parentevent)
            % If window is closed, finished = 2
            % If clicked apply, finished = 1
            % If clicked redo, finished = 0
            switch eventdata.EventName
                case 'Close'
                    obj.finished = 2;
                otherwise
                    switch hObject.String
                        case 'Save'
                            obj.finished = 1;
                            
                            hObject.Enable = 'off';
                            pind = regexp(char(obj.ClusteringData{1,'Filename'}),'\');
                            pind = pind(end);
                            pname = char(obj.ClusteringData{1,'Filename'});
                            pname = pname(1:pind);
                            parentapp.RunUnsupClustSaveDlg(pname);
                            
                            % Save the cluster images
                            %saveChoice =  questdlg('Save file with Cluster Images? (NOT recommended for big datasets)','Save images','Yes','No','No');
                            switch parentapp.bClustImg
                                case true
                                    % Start at beginning
                                    obj.currentCluster = 1;
                                    obj.page = 1;
                                    obj.plotimages();
                                    %montarr = {};
                                    
                                    % Cycle through all clusters
                                    numclusts = length(obj.clusterName);
                                    for i = 1:numclusts
                                    %while obj.currentCluster <= length(obj.clusterName)
                                        % Save current display
%                                         [thisim,~] = frame2im(getframe(obj.fig));
%                                         montarr = [montarr, thisim];
                                        thisfnm = ['ClusteringImg_',sprintf('%03d',obj.currentCluster),'_',sprintf('%03d',obj.page),'.png'];
                                        saveas(obj.fig,fullfile(parentapp.strUnsupSaveLoc,thisfnm));
                                        % Cycle through all pages for that
                                        % cluster
                                        numpgs = ceil(obj.count(obj.currentCluster) / length(obj.image_axes));
                                        for j = 1:numpgs-1
                                        %while obj.page < ceil(obj.count(obj.currentCluster) / length(obj.image_axes))
                                            % Next page
                                            nextpage_Callback(obj, hObject, eventdata);
                                            % Save current display
%                                             [thisim,~] = frame2im(getframe(obj.fig));
%                                             montarr = [montarr, thisim];
                                            thisfnm = ['ClusteringImg_',sprintf('%03d',obj.currentCluster),'_',sprintf('%03d',obj.page),'.png'];
                                            saveas(obj.fig,fullfile(parentapp.strUnsupSaveLoc,thisfnm));
                                        end
                                        % Next cluster
                                        next_Callback(obj, hObject, eventdata);
                                    end
                                case false
                            end
                        case 'Redo'
                            obj.finished = 0;
                    end
            end
            set(obj.fig,  'closerequestfcn', '');
            delete(obj.fig);
            obj.fig = [];
        end
        
    end
end
