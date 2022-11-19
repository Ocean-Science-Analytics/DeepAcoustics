classdef DeepWaves_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        mainfigure                matlab.ui.Figure
        menuFile                  matlab.ui.container.Menu
        menuSelectNet             matlab.ui.container.Menu
        menuSelectAudio           matlab.ui.container.Menu
        menuSelectDet             matlab.ui.container.Menu
        menuSaveSess              matlab.ui.container.Menu
        menuImpExp                matlab.ui.container.Menu
        menuExpRaven              matlab.ui.container.Menu
        menuExpSpect              matlab.ui.container.Menu
        menuExpAudio              matlab.ui.container.Menu
        menuExpExcel              matlab.ui.container.Menu
        menuExpSV                 matlab.ui.container.Menu
        menuImpRaven              matlab.ui.container.Menu
        menuImpSV                 matlab.ui.container.Menu
        menuImpUV                 matlab.ui.container.Menu
        menuImpMUPET              matlab.ui.container.Menu
        menuImpXBAT               matlab.ui.container.Menu
        menuTools                 matlab.ui.container.Menu
        menuNetTrain              matlab.ui.container.Menu
        menuCreateTrainImg        matlab.ui.container.Menu
        menuTrainDetNet           matlab.ui.container.Menu
        menuTrainPostHocDenoiser  matlab.ui.container.Menu
        menuTrainSupClass         matlab.ui.container.Menu
        menuAutoReview            matlab.ui.container.Menu
        menuBatchReject           matlab.ui.container.Menu
        menuRemoveRejects         matlab.ui.container.Menu
        menuPostHocDenoising      matlab.ui.container.Menu
        menuSetStaticBoxHeight    matlab.ui.container.Menu
        menuCallClass             matlab.ui.container.Menu
        menuAddCustomLabels       matlab.ui.container.Menu
        menuUnsupClust            matlab.ui.container.Menu
        menuSupClass              matlab.ui.container.Menu
        menuViewClust             matlab.ui.container.Menu
        menuSyntaxAnalysis        matlab.ui.container.Menu
        menuCreatetSNE            matlab.ui.container.Menu
        menuMergeDetFiles         matlab.ui.container.Menu
        menuChangePlaybackRate    matlab.ui.container.Menu
        menuChangeDisplayRange    matlab.ui.container.Menu
        menuChangeContourThresh   matlab.ui.container.Menu
        menuSeparateLong22s       matlab.ui.container.Menu
        menuHelp                  matlab.ui.container.Menu
        menuAbout                 matlab.ui.container.Menu
        menuViewManual            matlab.ui.container.Menu
        menuKeyboardShortcuts     matlab.ui.container.Menu
        textClustAssign           matlab.ui.control.Label
        textLabel                 matlab.ui.control.Label
        buttonPrevFile            matlab.ui.control.Button
        buttonNextFile            matlab.ui.control.Button
        sliderTonality            matlab.ui.control.Slider
        textDetReview             matlab.ui.control.Label
        textNavigation            matlab.ui.control.Label
        buttonRecordAudio         matlab.ui.control.StateButton
        buttonLowCLimMinus        matlab.ui.control.Button
        buttonLowCLimPlus         matlab.ui.control.Button
        buttonHighCLimPlus        matlab.ui.control.Button
        buttonHighCLimMinus       matlab.ui.control.Button
        buttonInvertCmap          matlab.ui.control.Button
        textSettings              matlab.ui.control.Label
        textDetectLoadRecord      matlab.ui.control.Label
        buttonLoadAudio           matlab.ui.control.Button
        buttonFwdABit             matlab.ui.control.Button
        buttonBackABit            matlab.ui.control.Button
        textScale                 matlab.ui.control.Label
        buttonDisplaySettings     matlab.ui.control.Button
        dropdownPage              matlab.ui.control.DropDown
        textPage                  matlab.ui.control.Label
        textFocus                 matlab.ui.control.Label
        dropdownFocus             matlab.ui.control.DropDown
        buttonFwdALot             matlab.ui.control.Button
        buttonBackALot            matlab.ui.control.Button
        textWaveform              matlab.ui.control.Label
        textTonality              matlab.ui.control.Label
        textContour               matlab.ui.control.Label
        textUserID                matlab.ui.control.Label
        textColorMap              matlab.ui.control.Label
        textRelPwr                matlab.ui.control.Label
        buttonMultiDetect         matlab.ui.control.Button
        textSinuosity             matlab.ui.control.Label
        textSlope                 matlab.ui.control.Label
        textDuration              matlab.ui.control.Label
        buttonDraw                matlab.ui.control.Button
        textFrequency             matlab.ui.control.Label
        dropdownColorMap          matlab.ui.control.DropDown
        textStatus                matlab.ui.control.Label
        textScore                 matlab.ui.control.Label
        textCalls                 matlab.ui.control.Label
        buttonLoadCalls           matlab.ui.control.Button
        buttonRejectCall          matlab.ui.control.Button
        dropdownDetCallFiles      matlab.ui.control.DropDown
        textDetCallFiles          matlab.ui.control.Label
        buttonDetectCalls         matlab.ui.control.Button
        dropdownAudioFiles        matlab.ui.control.DropDown
        textAudioFiles            matlab.ui.control.Label
        textNeuralNet             matlab.ui.control.Label
        dropdownNeuralNet         matlab.ui.control.DropDown
        buttonPrevCall            matlab.ui.control.Button
        buttonNextCall            matlab.ui.control.Button
        buttonPlayCall            matlab.ui.control.Button
        textLowCLim               matlab.ui.control.Label
        textHighCLim              matlab.ui.control.Label
        buttonAcceptCall          matlab.ui.control.Button
        winPage                   matlab.ui.control.UIAxes
        winContour                matlab.ui.control.UIAxes
        axesPage                  matlab.ui.control.UIAxes
        winWaveform               matlab.ui.control.UIAxes
        winFocus                  matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        appAbout % About DeepWaves Dialog
        appDisplay % Display Settings Dialog
        appUnsupClustSave % Save Dialog for Unsupervised Clustering Runs
        appClustering % Description
    end
    
    properties (Access = public)
        % Save Dialog variables
        strUnsupSaveLoc % Save location for Unsupervised Clustering Products
        bClustImg % Save clustering images
        bSilh % Save silhouette plot
        bClosest % Save closest calls image
        bContours % Save centroid contours image
        bModel % Save KMeans Model.mat
        bEEC % Save Expanded Extracted Contours.mat
        bECOverwrite % Overwrite existing EC.mat
        bUpdateDets % Update detections.mat with cluster assignments

        % Clustering Dialog variables
        rejected
        finished
        clusterName
        clustAssign
    end
    
    methods (Access = public)
        function UpdateDisplaySettings(app, event, newhandles)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            % Transfer new settings from Display app
            handles = newhandles;
            handles.data.saveSettings();
            if ~isempty(handles.data.audiodata)
                update_fig(hObject, eventdata, handles, true);
                % Update the color limits because changing from amplitude to
                % power would mess with them
                handles.data.clim = prctile(handles.data.page_spect.s_display(20:10:end-20, 1:20:end),[10,90], 'all')';
                ChangeSpecCLim(hObject,[],handles);
    
                handles.focusWindow.Colorbar.Label.String = handles.data.settings.spect.type;
                handles.spectrogramWindow.Colorbar.Label.String = handles.data.settings.spect.type;
            end
            guidata(hObject, handles);
        end
        
        function RunUnsupClustSaveDlg(app,saveloc)
            app.appUnsupClustSave = UnsupClustSaveDlg(app, saveloc);
            waitfor(app.appUnsupClustSave);
        end
        
        function RunClusteringDlg(app,clustAssign,ClusteringData)
            app.appClustering = ClusteringDlg(app,clustAssign,ClusteringData);
            waitfor(app.appClustering);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function DeepWaves_OpeningFcn(app, varargin)
            % Add paths
            addpath(genpath('Dialogs'))
            addpath(genpath('Functions'))
            
            app.mainfigure.Visible = 'off';
            % Ensure that the app appears on screen when run
            movegui(app.mainfigure, 'onscreen');

            % Initialize properties
            app.strUnsupSaveLoc = ""; % Save location for Unsupervised Clustering Products
            app.bClustImg = false; % Save clustering images
            app.bSilh = false;  % Save silhouette plot
            app.bClosest = false;  % Save closest calls image
            app.bContours = false;  % Save centroid contours image
            app.bModel = false;  % Save KMeans Model.mat
            app.bEEC = false;  % Save Expanded Extracted Contours.mat
            app.bECOverwrite = false;  % Overwrite existing EC.mat
            app.bUpdateDets = false;  % Update detections.mat with cluster assignments

            % Matlab bug fix
        	allAxes = findall(app.mainfigure, 'Type', 'axes');
	        arrayfun(@(ax) disableDefaultInteractivity(ax), allAxes)      
	        oncleanup = onCleanup(@() arrayfun(@(ax) enableDefaultInteractivity(ax), allAxes));
            
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app); %#ok<ASGLU>
            
            % Very Important Logo (Original Mouse in DS from hjw; Fluke from gca)
            disp '                                                                                                                                 .---.'
            disp '                                                                                                      _..__        __.._       /  .  \  '
            disp '                                                                                                      \    ''''''\/''''''    /       |\_/|   |'
            disp '                                                                                                     _ ''-._       ._.-''  _      |   |   |'
            disp '    ._______________________________________________________________________________________________.;,\_.;,\_.;,/_.;,\_.;,\_____|___|__,|'
            disp '   /  .-.                                                                                                                              |'
            disp '  |  /   \                                                                                                                             |'
            disp '  | |\_.  |                                                                                                                            |'
            disp '  |\|  | /|        ,---,                                   ---.            ---.                                                        |'
            disp '  | `---'' |      .''  .'' `\                      ,-.---.  ''--/ \          ''--/;                                                         |'
            disp '  |       |    ,---.''     \                     \    /  \ |  :  |        ; |  :                                    .--.---.            |'
            disp '  |       |    |   |  .`\  |                    |   :    | \  \  ''       / :  /,--.--.                    ,---.   /  /  .  /           |'
            disp '  |       |    :   : |  ''  |   ,---.     ,---.  |   | .\ : :  :  : ''/^\ : /  |/       \                  /     \ |  :  /---`           |'
            disp '  |       |    |   '' ''  ;  :  /     \   /     \ .   : |: | \  \  \''/   \/   /.--.  .-. |                /    /  ||  :  ;_              |'
            disp '  |       |    ''   | ;  .  | /    /  | /    /  ||   |  \ :  :  |  ''''   ''''  ;  \__\/: . . ---.      ---..    '' / | \  \   `.            |'
            disp '  |       |    |   | :  |  ''.    '' / |.    '' / ||   : .  |   \  \         :   ," .--.; |''--/ \    /''--/''   ;   /|  `-\--\  \           |'
            disp '  |       |    ''   : | /  ; ''   ;   /|''   ;   /|:     |`-''    ''''---/``\--''''  /  /  ,.  ||  :  |  ; |  :''   |  / | /--/`--'' ;           |'
            disp '  |       |    |   | ''` ,/  ''   |  / |''   |  / |:   : :                     ;  :   .''   \`  \  \'' /  / |   :    |''--''.     /           |'
            disp '  |       |    ;   :  .''    |   :    ||   :    ||   | :                     |  ,     .-./ ;  :  ''''  ;   \   \  /   `--''---''            |'
            disp '  |       |    |   ,.''       \   \  /  \   \  / `---''.|                      `--`---''      \  \    /''    `----''                        |'
            disp '  |       |    ''---''          `----''    `----''    `---`                                      `--```                                    |'
            disp '  |       |                                                                                                                            |'
            disp '  \       |____________________________________________________________________________________________________________________________/'
            disp '   \     /'
            disp '    `---'''
            disp '  '
            disp '  '
            disp '  '
            
            % Set Handles
            hFig = hObject;
            handles.hFig=hFig;
            
            % % Fullscreen
            % warning ('off','all');
            % pause(0.00001);
            % frame_h = get(handle(gcf),'JavaFrame');
            % set(frame_h,'Maximized',1);
            
            % Create a class to hold the data
            squeakfolder = fileparts(mfilename('fullpath'));
            
            % Add to MATLAB path and check for toolboxes
            if ~isdeployed
                % Add DeepWaves to the path
                addpath(squeakfolder);
                addpath(genpath(fullfile(squeakfolder, 'Functions')));
                savepath
            
                %% Display error message if running on matlab before 2017b or toolboxes not found
                if verLessThan('matlab','9.9')
                    errordlg(['Warning, DeepWaves V3 requires MATLAB 2021 or later. It looks like you are use MATLAB ' version('-release')],'upgrade your matlab')
                end
            
                try
                    verLessThan('nnet','1');
                catch
                    warning('Deep Learning Toolbox not found')
                end
            
                try
                    verLessThan('curvefit','1');
                catch
                    warning('Curve Fitting Toolbox not found')
                end
            
                try
                    verLessThan('vision','1');
                catch
                    warning('Computer Vision System Toolbox not found')
                end
            
                try
                    verLessThan('images','1');
                catch
                    warning('Image Processing Toolbox not found')
                end
            
                try
                    verLessThan('parallel','1');
                catch
                    warning('Parallel Computing Toolbox not found')
                end
            end
            
            handles.data = squeakData(squeakfolder);
            
            set ( hFig, 'Color', [.1 .1 .1] );
            handles.output = hObject;
            cd(handles.data.squeakfolder);
            
            %% Display version
            try % Read the current changelog and find the version (## number)
                fid = fopen(fullfile(handles.data.squeakfolder,'CHANGELOG.md'));
                changelog = fscanf(fid,'%c');
                fclose(fid);
                tokens = regexp(changelog, '## ([.\d])+', 'tokens');
                handles.DWVersion =  tokens{1}{:};
            catch
                handles.DWVersion = '? -- can''t read CHANGELOG.md. Make sure you have the latest version!';
            end
            fprintf(1,'%s %s\n\n', 'DeepWaves version', handles.DWVersion);
            try % Check if a new version is avaliable by comparing changelog to whats online
                WebChangelog = webread('https://raw.githubusercontent.com/Ocean-Science-Analytics/DeepWaves/main/CHANGELOG.md');
                [changes, tokens] = regexp(WebChangelog, '## ([.\d])+', 'start', 'tokens');
                WebVersion = tokens{1}{:};
                if ~strcmp(WebVersion, handles.DWVersion)
                    fprintf(1,'%s\n%s\n\n%s\n',...
                        'A new version of DeepWaves is avaliable.',...
                        '<a href="https://github.com/Ocean-Science-Analytics/DeepWaves">Download it here!</a>',...
                        WebChangelog(1:changes(2)-1))
                end
            catch
                fprintf(1,'Can''t check for a updates online right now\n');
            end
            
            if ~(exist(fullfile(handles.data.squeakfolder,'Background.png'), 'file')==2)
                disp('Background image not found')
                background = zeros(280);
                fonts = listTrueTypeFonts;
                background = insertText(background,[10 8],'DeepWaves','Font',char(datasample(fonts,1)),'FontSize',30);
                background = insertText(background,[10 80],'DeepWaves','Font',char(datasample(fonts,1)),'FontSize',30);
                background = insertText(background,[10 150],'DeepWaves','Font',char(datasample(fonts,1)),'FontSize',30);
                background = insertText(background,[10 220],'DeepWaves','Font',char(datasample(fonts,1)),'FontSize',30);
                handles.background = background;
            else
                handles.background=imread('Background.png');
            end
%             if ~(exist(fullfile(handles.data.squeakfolder,'DeepWaves.fig'), 'file')==2)
%                 errordlg('"DeepWaves.fig" not found');
%             end
            
            
            % Cool Background Image
            imshow(handles.background, 'Parent', handles.focusWindow);
            set(handles.focusWindow,'Color',[0.1 0.1 0.1],'YColor',[1 1 1],'XColor',[1 1 1]);
            set(handles.focusWindow,'XTick',[]);
            set(handles.focusWindow,'YTick',[]);
            update_folders(hObject, eventdata, handles);
            handles = guidata(hObject);  % Get newest version of handles
            
            % Set the sliders to the saved values
            set(handles.TonalitySlider, 'Value', handles.data.settings.EntropyThreshold);
            
            % Set the page and focus window dropdown boxes to the values defined in
            % squeakData, and set the current value to the one closest to the save value.
            handles.epochWindowSizePopup.String = compose('%gs', handles.data.pageSizes);
            [~, handles.epochWindowSizePopup.Value] =  min(abs(handles.data.pageSizes - handles.data.settings.pageSize));
            handles.focusWindowSizePopup.String = compose('%gs', handles.data.focusSizes);
            [~, handles.focusWindowSizePopup.Value] =  min(abs(handles.data.focusSizes - handles.data.settings.focus_window_size));
            
            %epochWindowSizePopup_CreateFcn
            handles.data.settings.pagesize = handles.epochWindowSizePopup.Value;
            %focusWindowSizePopup_CreateFcn
            handles.data.settings.focus_window_size = handles.focusWindowSizePopup.Value;
            
            guidata(hObject, handles);
            
            set(handles.contourWindow,'Color',[0.1 0.1 0.1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Clim',[0,1]);
            set(handles.contourWindow,'XTickLabel',[]);
            set(handles.contourWindow,'XTick',[]);
            set(handles.contourWindow,'YTick',[]);
            
            set(handles.waveformWindow,'Color',[0.1 0.1 0.1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Clim',[0,1]);
            set(handles.waveformWindow,'XTickLabel',[]);
            set(handles.waveformWindow,'XTick',[]);
            set(handles.waveformWindow,'YTick',[]);
            
            C = spatialPattern([1000,10000],-2);
            imagesc(C(1:900,1:10000),'Parent', handles.spectrogramWindow);
            colormap(handles.spectrogramWindow,inferno);
            set(handles.spectrogramWindow,'Color',[0.1 0.1 0.1],'YColor',[1 1 1],'XColor',[1 1 1]);
            set(handles.spectrogramWindow,'XTickLabel',[]);
            set(handles.spectrogramWindow,'XTick',[]);
            set(handles.spectrogramWindow,'YTick',[]);
            
            % imagesc(C(900:1000,1:10000),'Parent', handles.detectionAxes);
            % colormap(handles.detectionAxes,inferno);
            set(handles.detectionAxes,'Color',[64/255 10/255 103/255],'YColor',[1 1 1],'XColor',[1 1 1]);
            set(handles.detectionAxes,'XTickLabel',[]);
            set(handles.detectionAxes,'XTick',[]);
            set(handles.detectionAxes,'YTick',[]);
            set(handles.spectrogramWindow,'Parent',handles.hFig);
            
            % Set the list of colormaps
            handles.popupmenuColorMap.String = {
                'inferno'
                'magma'
                'plasma'
                'viridis'
                'cubehelix'
                'gray'
                'jet'
                'turbo'
                'hot'
                'parula'
                'hsv'
                'cool'
                'spring'
                'summer'
                'autumn'
                'winter'
                'bone'
                'copper'
                'pink'};

            app.mainfigure.Visible = 'on';
        end

        % Window key press function: mainfigure
        function mainfigure_WindowKeyPressFcn(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            %disp(eventdata);
            switch eventdata.Character
                case 'p'
                    PlayCall(handles);
                case {'e', 29} % char(29) is right arrow key
                    NextCall(hObject, eventdata, handles);
                case {'q', 28} % char(28) is left arrow key
                    PrevCall(hObject, eventdata, handles);
                case 'a'
                    AcceptCall(hObject, eventdata, handles);
                case 'r'
                    RejectCall(hObject, eventdata, handles);
                case 'd'
                    DrawBox(hObject, eventdata, handles);
                case 127 % Delete key
                    handles.data.calls(handles.data.currentcall,:) = [];
                    SortCalls(hObject, [], handles, 'time', 0, handles.data.currentcall - 1);
                case 30 % char(30) is up arrow key
                    MoveFocus(+ handles.data.settings.focus_window_size, hObject, eventdata, handles)
                case 31 % char(31) is down arrow key
                    MoveFocus(- handles.data.settings.focus_window_size, hObject, eventdata, handles)
                case 32 % 'space'
                    FwdALot(hObject, eventdata, handles);
                case handles.data.labelShortcuts
                    %% Update the call labels
                    % Index of the shortcut
                    idx = contains(handles.data.labelShortcuts, eventdata.Character);
                    handles.data.calls.Type(handles.data.currentcall) = categorical(handles.data.settings.labels(idx));
                    update_fig(hObject, eventdata, handles);
            end
        end

        % Menu selected function: menuSelectNet
        function menuSelectNet_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % Find networks
            path=uigetdir(handles.data.settings.networkfolder,'Select Network Folder');
            if isnumeric(path);return;end
            handles.data.settings.networkfolder = path;
            handles.data.saveSettings();
            update_folders(hObject, eventdata, handles);
        end

        % Menu selected function: menuSelectAudio
        function menuSelectAudio_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % Find audio in folder
            path=uigetdir(handles.data.settings.audiofolder,'Select Audio File Folder');
            if isnumeric(path);return;end
            handles.data.settings.audiofolder = path;
            handles.data.saveSettings();
            update_folders(hObject, eventdata, handles);
        end

        % Menu selected function: menuSelectDet
        function menuSelectDet_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % Find audio in folder
            path=uigetdir(handles.data.settings.detectionfolder,'Select Detection File Folder');
            if isnumeric(path);return;end
            handles.data.settings.detectionfolder = path;
            handles.data.saveSettings();
            update_folders(hObject, eventdata, handles);
        end

        % Menu selected function: menuSaveSess
        function menuSaveSess_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            SaveSession(hObject, eventdata, handles);
        end

        % Menu selected function: menuExpRaven
        function menuExpRaven_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ExportRaven(hObject, eventdata, handles);
        end

        % Menu selected function: menuExpSpect
        function menuExpSpect_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ExportSpect(hObject, eventdata, handles);
        end

        % Menu selected function: menuExpAudio
        function menuExpAudio_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ExportAudio(hObject, eventdata, handles);
        end

        % Menu selected function: menuExpExcel
        function menuExpExcel_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ExportExcel(hObject, eventdata, handles);
        end

        % Menu selected function: menuExpSV
        function menuExpSV_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ExportSV(hObject, eventdata, handles);
        end

        % Menu selected function: menuImpRaven
        function menuImpRaven_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ImportRaven(hObject, eventdata, handles);
        end

        % Menu selected function: menuImpSV
        function menuImpSV_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ImportSV(hObject, eventdata, handles);
        end

        % Menu selected function: menuImpUV
        function menuImpUV_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ImportUV(hObject, eventdata, handles);
        end

        % Menu selected function: menuImpMUPET
        function menuImpMUPET_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ImportMUPET(hObject, eventdata, handles);
        end

        % Menu selected function: menuImpXBAT
        function menuImpXBAT_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ImportXBAT(hObject, eventdata, handles);
        end

        % Menu selected function: menuCreateTrainImg
        function menuCreateTrainImg_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            CreateTrainingImgs(hObject, eventdata, handles);
        end

        % Menu selected function: menuTrainDetNet
        function menuTrainDetNet_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            TrainDetNet(hObject, eventdata, handles);
        end

        % Menu selected function: menuTrainPostHocDenoiser
        function menuTrainPostHocDenoiser_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            TrainPostHocDenoiser(hObject, eventdata, handles);
        end

        % Menu selected function: menuTrainSupClass
        function menuTrainSupClass_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            TrainSupClass(hObject, eventdata, handles);
        end

        % Menu selected function: menuBatchReject
        function menuBatchReject_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            BatchReject(hObject, eventdata, handles);
        end

        % Menu selected function: menuRemoveRejects
        function menuRemoveRejects_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            RemoveRejects(hObject, eventdata, handles);
        end

        % Menu selected function: menuPostHocDenoising
        function menuPostHocDenoising_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            PostHocDenoising(hObject, eventdata, handles);
        end

        % Menu selected function: menuSetStaticBoxHeight
        function menuSetStaticBoxHeight_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            SetStaticBoxHeight(hObject, eventdata, handles);
        end

        % Menu selected function: menuAddCustomLabels
        function menuAddCustomLabels_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            AddCustomLabels(hObject, eventdata, handles);
        end

        % Menu selected function: menuUnsupClust
        function menuUnsupClust_Callback(app, event)
            UnsupClust(app, event);
        end

        % Menu selected function: menuSupClass
        function menuSupClass_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            SupClass(hObject, eventdata, handles);
        end

        % Menu selected function: menuViewClust
        function menuViewClust_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ViewClusters(hObject, eventdata, handles);
        end

        % Menu selected function: menuSyntaxAnalysis
        function menuSyntaxAnalysis_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            SyntaxAnalysis(hObject, eventdata, handles);
        end

        % Menu selected function: menuCreatetSNE
        function menuCreatetSNE_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            CreatetSNE(hObject, eventdata, handles);
        end

        % Menu selected function: menuMergeDetFiles
        function menuMergeDetFiles_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            MergeDetFiles(hObject, eventdata, handles);
        end

        % Menu selected function: menuChangePlaybackRate
        function menuChangePlaybackRate_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangePlaybackRate(hObject, eventdata, handles);
        end

        % Menu selected function: menuChangeDisplayRange
        function menuChangeDisplayRange_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangeDisplayRange(hObject, eventdata, handles);
        end

        % Menu selected function: menuChangeContourThresh
        function menuChangeContourThresh_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangeContourThresh(hObject, eventdata, handles);
        end

        % Menu selected function: menuSeparateLong22s
        function menuSeparateLong22s_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            SeparateLong22s(hObject, eventdata, handles);
        end

        % Menu selected function: menuAbout
        function menuAbout_Callback(app, event)
            [~, ~, handles] = convertToGUIDECallbackArguments(app, event); 

            % Disable About menu option while About dialog open
            app.menuAbout.Enable = 'off';

            % Call About dialog
            app.appAbout = AboutDlg(app,handles.DWVersion);
        end

        % Menu selected function: menuViewManual
        function menuViewManual_Callback(app, event)
            web('https://github.com/DrCoffey/DeepSqueak/wiki','-browser');
        end

        % Menu selected function: menuKeyboardShortcuts
        function menuKeyboardShortcuts_Callback(app, event)
            % Display a list of keyboard shortcuts
            Keyboard_Shortcuts = [
                "Save file", "ctrl + s"
                "Next call", "e, right arrow"
                "Previous call", "q, left arrow"
                "Accept call", "a"
                "Reject call", "r"
                "Delete call", "delete, right click"
                "Redraw box", "d"
                "Play call audio", "p"
                "Set call label", "See ""Add Custom Labels"", double click"
                "Slide focus forward", "up arrow"
                "Slide focus back", "down arrow"
                "Next page", "space"
                ];
            CreateStruct.Interpreter = 'tex';
            CreateStruct.WindowStyle = 'modal';
            msgbox(['\fontname{Courier}\fontsize{12}' sprintf('%-20s |   %s\n', Keyboard_Shortcuts')], 'Keyboard Shortcuts', CreateStruct)
        end

        % Value changed function: sliderTonality
        function sliderTonality_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            %GA 210807: Slider now only used for individual adjustments, so I don't think I want to save to
            %handles.data.settings.EntropyThreshold=(get(hObject,'Value'));
            %settings.mat
            %handles.data.saveSettings();
            %update_focus_display has preference for existing EntThresh, so need to
            %overwrite for this call
            handles.data.calls.EntThresh(handles.data.currentcall) = (get(hObject,'Value'));
            update_fig(hObject, eventdata, handles);
        end

        % Value changed function: dropdownNeuralNet
        function dropdownNeuralNet_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            guidata(hObject, handles);
        end

        % Value changed function: dropdownAudioFiles
        function dropdownAudioFiles_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            guidata(hObject, handles);
        end

        % Value changed function: dropdownDetCallFiles
        function dropdownDetCallFiles_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            guidata(hObject, handles);
        end

        % Button pushed function: buttonDetectCalls
        function buttonDetectCalls_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); 
            DetectCalls(hObject, eventdata, handles, true)
        end

        % Button pushed function: buttonMultiDetect
        function buttonMultiDetect_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); 
            DetectCalls(hObject, eventdata, handles, false)
        end

        % Button pushed function: buttonLoadCalls
        function buttonLoadCalls_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            LoadCalls(hObject, eventdata, handles)
        end

        % Button pushed function: buttonLoadAudio
        function buttonLoadAudio_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            LoadAudio(hObject, eventdata, handles)
        end

        % Button pushed function: buttonAcceptCall
        function buttonAcceptCall_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            AcceptCall(hObject, eventdata, handles);
        end

        % Button pushed function: buttonRejectCall
        function buttonRejectCall_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            RejectCall(hObject, eventdata, handles);
        end

        % Button pushed function: buttonDraw
        function buttonDraw_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            DrawBox(hObject, eventdata, handles);
        end

        % Button pushed function: buttonPlayCall
        function buttonPlayCall_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            PlayCall(hObject, eventdata, handles);
        end

        % Button pushed function: buttonBackALot
        function buttonBackALot_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            BackALot(hObject, eventdata, handles);
        end

        % Button pushed function: buttonBackABit
        function buttonBackABit_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to topLeftButton (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            MoveFocus(handles.data.settings.focus_window_size*(-1), hObject, eventdata, handles)
        end

        % Button pushed function: buttonPrevCall
        function buttonPrevCall_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            PrevCall(hObject, eventdata, handles);
        end

        % Button pushed function: buttonNextCall
        function buttonNextCall_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            NextCall(hObject, eventdata, handles);
        end

        % Button pushed function: buttonFwdABit
        function buttonFwdABit_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to topRightButton (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            MoveFocus(handles.data.settings.focus_window_size*(1), hObject, eventdata, handles)
        end

        % Button pushed function: buttonFwdALot
        function buttonFwdALot_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            FwdALot(hObject, eventdata, handles);
        end

        % Button pushed function: buttonPrevFile
        function buttonPrevFile_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            PrevFile(hObject, eventdata, handles);
        end

        % Button pushed function: buttonNextFile
        function buttonNextFile_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            NextFile(hObject, eventdata, handles);
        end

        % Value changed function: dropdownFocus
        function dropdownFocus_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangeFocusWidth(hObject, eventdata, handles);
        end

        % Value changed function: dropdownPage
        function dropdownPage_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangePageWidth(hObject, eventdata, handles);
        end

        % Value changed function: dropdownColorMap
        function dropdownColorMap_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangeColorMap(hObject, eventdata, handles);
        end

        % Button pushed function: buttonInvertCmap
        function buttonInvertCmap_Callback(app, event)
            colormap(app.winPage, flipud(colormap(app.winPage)))
            colormap(app.winFocus, flipud(colormap(app.winFocus)))
        end

        % Close request function: mainfigure
        function mainfigureCloseRequest(app, event)
            delete(app.appAbout)
            delete(app.appDisplay)
            delete(app.appUnsupClustSave)
            delete(app.appClustering)
            delete(app)
        end

        % Button pushed function: buttonHighCLimMinus
        function buttonHighCLimMinus_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangeSpecCLim(hObject, eventdata, handles);
        end

        % Button pushed function: buttonHighCLimPlus
        function buttonHighCLimPlus_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangeSpecCLim(hObject, eventdata, handles);
        end

        % Button pushed function: buttonLowCLimMinus
        function buttonLowCLimMinus_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangeSpecCLim(hObject, eventdata, handles);
        end

        % Button pushed function: buttonLowCLimPlus
        function buttonLowCLimPlus_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            ChangeSpecCLim(hObject, eventdata, handles);
        end

        % Value changed function: buttonRecordAudio
        function buttonRecordAudio_Callback(app, event)
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            RecordAudio(hObject, eventdata, handles);
        end

        % Button pushed function: buttonDisplaySettings
        function buttonDisplaySettings_Callback(app, event)
            [~, ~, handles] = convertToGUIDECallbackArguments(app, event); 

            % Disable About menu option while About dialog open
            app.buttonDisplaySettings.Enable = 'off';

            % Call About dialog
            app.appDisplay = DisplayDlg(app, event, handles);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create mainfigure and hide until all components are created
            app.mainfigure = uifigure('Visible', 'off');
            app.mainfigure.Position = [680 230 1422 809];
            app.mainfigure.Name = 'DeepWaves';
            app.mainfigure.CloseRequestFcn = createCallbackFcn(app, @mainfigureCloseRequest, true);
            app.mainfigure.WindowKeyPressFcn = createCallbackFcn(app, @mainfigure_WindowKeyPressFcn, true);
            app.mainfigure.BusyAction = 'cancel';
            app.mainfigure.HandleVisibility = 'callback';
            app.mainfigure.Tag = 'figure1';

            % Create menuFile
            app.menuFile = uimenu(app.mainfigure);
            app.menuFile.Text = 'File';
            app.menuFile.Tag = 'folders';

            % Create menuSelectNet
            app.menuSelectNet = uimenu(app.menuFile);
            app.menuSelectNet.MenuSelectedFcn = createCallbackFcn(app, @menuSelectNet_Callback, true);
            app.menuSelectNet.Text = 'Select Network Folder';
            app.menuSelectNet.Tag = 'load_networks';

            % Create menuSelectAudio
            app.menuSelectAudio = uimenu(app.menuFile);
            app.menuSelectAudio.MenuSelectedFcn = createCallbackFcn(app, @menuSelectAudio_Callback, true);
            app.menuSelectAudio.Text = 'Select Audio Folder';
            app.menuSelectAudio.Tag = 'select_audio';

            % Create menuSelectDet
            app.menuSelectDet = uimenu(app.menuFile);
            app.menuSelectDet.MenuSelectedFcn = createCallbackFcn(app, @menuSelectDet_Callback, true);
            app.menuSelectDet.Text = 'Select Detection Folder';
            app.menuSelectDet.Tag = 'load_detectionFolder';

            % Create menuSaveSess
            app.menuSaveSess = uimenu(app.menuFile);
            app.menuSaveSess.MenuSelectedFcn = createCallbackFcn(app, @menuSaveSess_Callback, true);
            app.menuSaveSess.Separator = 'on';
            app.menuSaveSess.Accelerator = 'S';
            app.menuSaveSess.Text = 'Save Session';
            app.menuSaveSess.Tag = 'savesession';

            % Create menuImpExp
            app.menuImpExp = uimenu(app.menuFile);
            app.menuImpExp.Separator = 'on';
            app.menuImpExp.Text = 'Import / Export';
            app.menuImpExp.Tag = 'export';

            % Create menuExpRaven
            app.menuExpRaven = uimenu(app.menuImpExp);
            app.menuExpRaven.MenuSelectedFcn = createCallbackFcn(app, @menuExpRaven_Callback, true);
            app.menuExpRaven.Text = 'Export to Raven';
            app.menuExpRaven.Tag = 'export_raven';

            % Create menuExpSpect
            app.menuExpSpect = uimenu(app.menuImpExp);
            app.menuExpSpect.MenuSelectedFcn = createCallbackFcn(app, @menuExpSpect_Callback, true);
            app.menuExpSpect.Text = 'Export Spectrogram';
            app.menuExpSpect.Tag = 'esportspect';

            % Create menuExpAudio
            app.menuExpAudio = uimenu(app.menuImpExp);
            app.menuExpAudio.MenuSelectedFcn = createCallbackFcn(app, @menuExpAudio_Callback, true);
            app.menuExpAudio.Text = 'Export Audio';
            app.menuExpAudio.Tag = 'exportaudio';

            % Create menuExpExcel
            app.menuExpExcel = uimenu(app.menuImpExp);
            app.menuExpExcel.MenuSelectedFcn = createCallbackFcn(app, @menuExpExcel_Callback, true);
            app.menuExpExcel.Text = 'Export Excel Log (Call Statistics)';
            app.menuExpExcel.Tag = 'excel';

            % Create menuExpSV
            app.menuExpSV = uimenu(app.menuImpExp);
            app.menuExpSV.MenuSelectedFcn = createCallbackFcn(app, @menuExpSV_Callback, true);
            app.menuExpSV.Text = 'Export to Sonic Visualizer';
            app.menuExpSV.Tag = 'sonic_visualizer';

            % Create menuImpRaven
            app.menuImpRaven = uimenu(app.menuImpExp);
            app.menuImpRaven.MenuSelectedFcn = createCallbackFcn(app, @menuImpRaven_Callback, true);
            app.menuImpRaven.Separator = 'on';
            app.menuImpRaven.Text = 'Import from Raven';
            app.menuImpRaven.Tag = 'import_raven';

            % Create menuImpSV
            app.menuImpSV = uimenu(app.menuImpExp);
            app.menuImpSV.MenuSelectedFcn = createCallbackFcn(app, @menuImpSV_Callback, true);
            app.menuImpSV.Text = 'Import from Sonic Visualizer';
            app.menuImpSV.Tag = 'import_from_sonic_visualizer';

            % Create menuImpUV
            app.menuImpUV = uimenu(app.menuImpExp);
            app.menuImpUV.MenuSelectedFcn = createCallbackFcn(app, @menuImpUV_Callback, true);
            app.menuImpUV.Text = 'Import from Ultravox';
            app.menuImpUV.Tag = 'Import_From_Ultravox';

            % Create menuImpMUPET
            app.menuImpMUPET = uimenu(app.menuImpExp);
            app.menuImpMUPET.MenuSelectedFcn = createCallbackFcn(app, @menuImpMUPET_Callback, true);
            app.menuImpMUPET.Text = 'Import from MUPET';
            app.menuImpMUPET.Tag = 'ImportFromMUPET';

            % Create menuImpXBAT
            app.menuImpXBAT = uimenu(app.menuImpExp);
            app.menuImpXBAT.MenuSelectedFcn = createCallbackFcn(app, @menuImpXBAT_Callback, true);
            app.menuImpXBAT.Text = 'Import from X-BAT';
            app.menuImpXBAT.Tag = 'Import_from_X_BAT';

            % Create menuTools
            app.menuTools = uimenu(app.mainfigure);
            app.menuTools.Text = 'Tools';
            app.menuTools.Tag = 'Untitled_2';

            % Create menuNetTrain
            app.menuNetTrain = uimenu(app.menuTools);
            app.menuNetTrain.Text = 'Network Training';
            app.menuNetTrain.Tag = 'training';

            % Create menuCreateTrainImg
            app.menuCreateTrainImg = uimenu(app.menuNetTrain);
            app.menuCreateTrainImg.MenuSelectedFcn = createCallbackFcn(app, @menuCreateTrainImg_Callback, true);
            app.menuCreateTrainImg.Text = 'Create Detection Network Training Images';
            app.menuCreateTrainImg.Tag = 'create_training_images';

            % Create menuTrainDetNet
            app.menuTrainDetNet = uimenu(app.menuNetTrain);
            app.menuTrainDetNet.MenuSelectedFcn = createCallbackFcn(app, @menuTrainDetNet_Callback, true);
            app.menuTrainDetNet.Text = 'Train Detection Network';
            app.menuTrainDetNet.Tag = 'trainnew';

            % Create menuTrainPostHocDenoiser
            app.menuTrainPostHocDenoiser = uimenu(app.menuNetTrain);
            app.menuTrainPostHocDenoiser.MenuSelectedFcn = createCallbackFcn(app, @menuTrainPostHocDenoiser_Callback, true);
            app.menuTrainPostHocDenoiser.Text = 'Train Post Hoc Denoiser';
            app.menuTrainPostHocDenoiser.Tag = 'TrainPostHocDenoiser';

            % Create menuTrainSupClass
            app.menuTrainSupClass = uimenu(app.menuNetTrain);
            app.menuTrainSupClass.MenuSelectedFcn = createCallbackFcn(app, @menuTrainSupClass_Callback, true);
            app.menuTrainSupClass.Text = 'Train Supervised Classifier';
            app.menuTrainSupClass.Tag = 'TrainSupervisedClassifier';

            % Create menuAutoReview
            app.menuAutoReview = uimenu(app.menuTools);
            app.menuAutoReview.Text = 'Automatic Review';
            app.menuAutoReview.Tag = 'Untitled_3';

            % Create menuBatchReject
            app.menuBatchReject = uimenu(app.menuAutoReview);
            app.menuBatchReject.MenuSelectedFcn = createCallbackFcn(app, @menuBatchReject_Callback, true);
            app.menuBatchReject.Text = 'Batch Reject by Threshold';
            app.menuBatchReject.Tag = 'Batch_Reject_by_Threshold';

            % Create menuRemoveRejects
            app.menuRemoveRejects = uimenu(app.menuAutoReview);
            app.menuRemoveRejects.MenuSelectedFcn = createCallbackFcn(app, @menuRemoveRejects_Callback, true);
            app.menuRemoveRejects.Text = 'Remove Rejected Calls';
            app.menuRemoveRejects.Tag = 'removereject';

            % Create menuPostHocDenoising
            app.menuPostHocDenoising = uimenu(app.menuAutoReview);
            app.menuPostHocDenoising.MenuSelectedFcn = createCallbackFcn(app, @menuPostHocDenoising_Callback, true);
            app.menuPostHocDenoising.Text = 'Post Hoc Denoising';
            app.menuPostHocDenoising.Tag = 'PostHocDenoising';

            % Create menuSetStaticBoxHeight
            app.menuSetStaticBoxHeight = uimenu(app.menuAutoReview);
            app.menuSetStaticBoxHeight.MenuSelectedFcn = createCallbackFcn(app, @menuSetStaticBoxHeight_Callback, true);
            app.menuSetStaticBoxHeight.Text = 'Set Static Box Height (Frequency)';
            app.menuSetStaticBoxHeight.Tag = 'set_static_box_height';

            % Create menuCallClass
            app.menuCallClass = uimenu(app.menuTools);
            app.menuCallClass.Text = 'Call Classification';
            app.menuCallClass.Tag = 'CallClassification';

            % Create menuAddCustomLabels
            app.menuAddCustomLabels = uimenu(app.menuCallClass);
            app.menuAddCustomLabels.MenuSelectedFcn = createCallbackFcn(app, @menuAddCustomLabels_Callback, true);
            app.menuAddCustomLabels.Text = 'Add Custom Labels';
            app.menuAddCustomLabels.Tag = 'customlabels';

            % Create menuUnsupClust
            app.menuUnsupClust = uimenu(app.menuCallClass);
            app.menuUnsupClust.MenuSelectedFcn = createCallbackFcn(app, @menuUnsupClust_Callback, true);
            app.menuUnsupClust.Text = 'Unsupervised Clustering';
            app.menuUnsupClust.Tag = 'UnsupervisedClustering';

            % Create menuSupClass
            app.menuSupClass = uimenu(app.menuCallClass);
            app.menuSupClass.MenuSelectedFcn = createCallbackFcn(app, @menuSupClass_Callback, true);
            app.menuSupClass.Text = 'Supervised Classification';
            app.menuSupClass.Tag = 'SupervisedClassification';

            % Create menuViewClust
            app.menuViewClust = uimenu(app.menuCallClass);
            app.menuViewClust.MenuSelectedFcn = createCallbackFcn(app, @menuViewClust_Callback, true);
            app.menuViewClust.Text = 'View Clusters';
            app.menuViewClust.Tag = 'ViewClusters';

            % Create menuSyntaxAnalysis
            app.menuSyntaxAnalysis = uimenu(app.menuCallClass);
            app.menuSyntaxAnalysis.MenuSelectedFcn = createCallbackFcn(app, @menuSyntaxAnalysis_Callback, true);
            app.menuSyntaxAnalysis.Text = 'Syntax Analysis';
            app.menuSyntaxAnalysis.Tag = 'SyntaxAnalysis';

            % Create menuCreatetSNE
            app.menuCreatetSNE = uimenu(app.menuCallClass);
            app.menuCreatetSNE.MenuSelectedFcn = createCallbackFcn(app, @menuCreatetSNE_Callback, true);
            app.menuCreatetSNE.Text = 'Create t-SNE / UMAP embedding';
            app.menuCreatetSNE.Tag = 'create_tsne';

            % Create menuMergeDetFiles
            app.menuMergeDetFiles = uimenu(app.menuTools);
            app.menuMergeDetFiles.MenuSelectedFcn = createCallbackFcn(app, @menuMergeDetFiles_Callback, true);
            app.menuMergeDetFiles.Text = 'Merge Detection Files';
            app.menuMergeDetFiles.Tag = 'merge';

            % Create menuChangePlaybackRate
            app.menuChangePlaybackRate = uimenu(app.menuTools);
            app.menuChangePlaybackRate.MenuSelectedFcn = createCallbackFcn(app, @menuChangePlaybackRate_Callback, true);
            app.menuChangePlaybackRate.Text = 'Change Playback Rate';
            app.menuChangePlaybackRate.Tag = 'Change_Playback_Rate';

            % Create menuChangeDisplayRange
            app.menuChangeDisplayRange = uimenu(app.menuTools);
            app.menuChangeDisplayRange.MenuSelectedFcn = createCallbackFcn(app, @menuChangeDisplayRange_Callback, true);
            app.menuChangeDisplayRange.Text = 'Change Display Range';
            app.menuChangeDisplayRange.Tag = 'Change_Display_Range';

            % Create menuChangeContourThresh
            app.menuChangeContourThresh = uimenu(app.menuTools);
            app.menuChangeContourThresh.MenuSelectedFcn = createCallbackFcn(app, @menuChangeContourThresh_Callback, true);
            app.menuChangeContourThresh.Text = 'Change Contour Threshold';
            app.menuChangeContourThresh.Tag = 'ChangeContourThreshold';

            % Create menuSeparateLong22s
            app.menuSeparateLong22s = uimenu(app.menuTools);
            app.menuSeparateLong22s.MenuSelectedFcn = createCallbackFcn(app, @menuSeparateLong22s_Callback, true);
            app.menuSeparateLong22s.Text = 'Separate Long 22s';
            app.menuSeparateLong22s.Tag = 'SeperateLong22s';

            % Create menuHelp
            app.menuHelp = uimenu(app.mainfigure);
            app.menuHelp.Text = 'Help';
            app.menuHelp.Tag = 'Help';

            % Create menuAbout
            app.menuAbout = uimenu(app.menuHelp);
            app.menuAbout.MenuSelectedFcn = createCallbackFcn(app, @menuAbout_Callback, true);
            app.menuAbout.Text = 'About DeepWaves';
            app.menuAbout.Tag = 'AboutDeepWaves';

            % Create menuViewManual
            app.menuViewManual = uimenu(app.menuHelp);
            app.menuViewManual.MenuSelectedFcn = createCallbackFcn(app, @menuViewManual_Callback, true);
            app.menuViewManual.Separator = 'on';
            app.menuViewManual.Text = 'View Manual';
            app.menuViewManual.Tag = 'ViewManual';

            % Create menuKeyboardShortcuts
            app.menuKeyboardShortcuts = uimenu(app.menuHelp);
            app.menuKeyboardShortcuts.MenuSelectedFcn = createCallbackFcn(app, @menuKeyboardShortcuts_Callback, true);
            app.menuKeyboardShortcuts.Text = 'Keyboard_Shortcuts';
            app.menuKeyboardShortcuts.Tag = 'Keyboard_Shortcuts';

            % Create winFocus
            app.winFocus = uiaxes(app.mainfigure);
            app.winFocus.FontSize = 13.3333333333333;
            app.winFocus.NextPlot = 'replace';
            app.winFocus.Box = 'on';
            app.winFocus.Tag = 'focusWindow';
            app.winFocus.Position = [253 366 1129 442];

            % Create winWaveform
            app.winWaveform = uiaxes(app.mainfigure);
            app.winWaveform.AmbientLightColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.winWaveform.XColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.winWaveform.YColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.winWaveform.Color = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.winWaveform.FontSize = 11.3333333333333;
            app.winWaveform.NextPlot = 'replace';
            app.winWaveform.Box = 'on';
            app.winWaveform.Tag = 'waveformWindow';
            app.winWaveform.Position = [3 205 228 143];

            % Create axesPage
            app.axesPage = uiaxes(app.mainfigure);
            app.axesPage.XColor = [1 1 1];
            app.axesPage.YColor = [1 1 1];
            app.axesPage.FontSize = 10.6666666666667;
            app.axesPage.GridColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.axesPage.MinorGridColor = [0.1 0.1 0.1];
            app.axesPage.NextPlot = 'replace';
            app.axesPage.Box = 'on';
            app.axesPage.Tag = 'detectionAxes';
            app.axesPage.Position = [259 135 1120 43];

            % Create winContour
            app.winContour = uiaxes(app.mainfigure);
            app.winContour.XColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.winContour.YColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.winContour.ZColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.winContour.Color = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.winContour.FontSize = 10.6666666666667;
            app.winContour.NextPlot = 'replace';
            app.winContour.Tag = 'contourWindow';
            app.winContour.Position = [3 372 228 127];

            % Create winPage
            app.winPage = uiaxes(app.mainfigure);
            app.winPage.FontSize = 12;
            app.winPage.NextPlot = 'replace';
            app.winPage.Box = 'on';
            app.winPage.Tag = 'spectrogramWindow';
            app.winPage.Position = [255 188 1125 181];

            % Create buttonAcceptCall
            app.buttonAcceptCall = uibutton(app.mainfigure, 'push');
            app.buttonAcceptCall.ButtonPushedFcn = createCallbackFcn(app, @buttonAcceptCall_Callback, true);
            app.buttonAcceptCall.HandleVisibility = 'off';
            app.buttonAcceptCall.Interruptible = 'off';
            app.buttonAcceptCall.Tag = 'AcceptCall';
            app.buttonAcceptCall.BackgroundColor = [0.949019607843137 0.450980392156863 0.101960784313725];
            app.buttonAcceptCall.FontWeight = 'bold';
            app.buttonAcceptCall.FontColor = [1 1 1];
            app.buttonAcceptCall.Position = [492 88 94 24];
            app.buttonAcceptCall.Text = 'Accept Call (a)';

            % Create textHighCLim
            app.textHighCLim = uilabel(app.mainfigure);
            app.textHighCLim.HandleVisibility = 'off';
            app.textHighCLim.Tag = 'text34';
            app.textHighCLim.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textHighCLim.VerticalAlignment = 'top';
            app.textHighCLim.WordWrap = 'on';
            app.textHighCLim.FontSize = 13.3333333333333;
            app.textHighCLim.FontWeight = 'bold';
            app.textHighCLim.FontColor = [1 1 1];
            app.textHighCLim.Position = [1215 43 108 18];
            app.textHighCLim.Text = 'High Color Limit';

            % Create textLowCLim
            app.textLowCLim = uilabel(app.mainfigure);
            app.textLowCLim.HandleVisibility = 'off';
            app.textLowCLim.Tag = 'text35';
            app.textLowCLim.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textLowCLim.VerticalAlignment = 'top';
            app.textLowCLim.WordWrap = 'on';
            app.textLowCLim.FontSize = 13.3333333333333;
            app.textLowCLim.FontWeight = 'bold';
            app.textLowCLim.FontColor = [1 1 1];
            app.textLowCLim.Position = [1215 18 106 18];
            app.textLowCLim.Text = 'Low Color Limit';

            % Create buttonPlayCall
            app.buttonPlayCall = uibutton(app.mainfigure, 'push');
            app.buttonPlayCall.ButtonPushedFcn = createCallbackFcn(app, @buttonPlayCall_Callback, true);
            app.buttonPlayCall.Tag = 'PlayCall';
            app.buttonPlayCall.BackgroundColor = [0.858823529411765 0.32156862745098 0.219607843137255];
            app.buttonPlayCall.FontWeight = 'bold';
            app.buttonPlayCall.FontColor = [1 1 1];
            app.buttonPlayCall.Position = [598 57 90 24];
            app.buttonPlayCall.Text = 'Play Call (p)';

            % Create buttonNextCall
            app.buttonNextCall = uibutton(app.mainfigure, 'push');
            app.buttonNextCall.ButtonPushedFcn = createCallbackFcn(app, @buttonNextCall_Callback, true);
            app.buttonNextCall.Tag = 'NextCall';
            app.buttonNextCall.BackgroundColor = [0.568627450980392 0.141176470588235 0.4];
            app.buttonNextCall.FontSize = 14.6666666666667;
            app.buttonNextCall.FontWeight = 'bold';
            app.buttonNextCall.FontColor = [1 1 1];
            app.buttonNextCall.Tooltip = 'Next Call';
            app.buttonNextCall.Position = [827 88 33.0000000000001 24];
            app.buttonNextCall.Text = '>';

            % Create buttonPrevCall
            app.buttonPrevCall = uibutton(app.mainfigure, 'push');
            app.buttonPrevCall.ButtonPushedFcn = createCallbackFcn(app, @buttonPrevCall_Callback, true);
            app.buttonPrevCall.Tag = 'PreviousCall';
            app.buttonPrevCall.BackgroundColor = [0.568627450980392 0.141176470588235 0.4];
            app.buttonPrevCall.FontSize = 14.6666666666667;
            app.buttonPrevCall.FontWeight = 'bold';
            app.buttonPrevCall.FontColor = [1 1 1];
            app.buttonPrevCall.Tooltip = 'Previous Call';
            app.buttonPrevCall.Position = [784 88 31 24];
            app.buttonPrevCall.Text = '<';

            % Create dropdownNeuralNet
            app.dropdownNeuralNet = uidropdown(app.mainfigure);
            app.dropdownNeuralNet.Items = {'Neural Network Matrix'};
            app.dropdownNeuralNet.ValueChangedFcn = createCallbackFcn(app, @dropdownNeuralNet_Callback, true);
            app.dropdownNeuralNet.Tag = 'neuralnetworkspopup';
            app.dropdownNeuralNet.FontSize = 10.6666666666667;
            app.dropdownNeuralNet.FontColor = [1 1 1];
            app.dropdownNeuralNet.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.dropdownNeuralNet.Position = [12 133 239 23];
            app.dropdownNeuralNet.Value = 'Neural Network Matrix';

            % Create textNeuralNet
            app.textNeuralNet = uilabel(app.mainfigure);
            app.textNeuralNet.Tag = 'neuralnetworks';
            app.textNeuralNet.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textNeuralNet.VerticalAlignment = 'top';
            app.textNeuralNet.WordWrap = 'on';
            app.textNeuralNet.FontSize = 16;
            app.textNeuralNet.FontWeight = 'bold';
            app.textNeuralNet.FontColor = [1 1 1];
            app.textNeuralNet.Position = [12 156 238 20];
            app.textNeuralNet.Text = 'Neural Networks';

            % Create textAudioFiles
            app.textAudioFiles = uilabel(app.mainfigure);
            app.textAudioFiles.Tag = 'textAudioFiles';
            app.textAudioFiles.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textAudioFiles.VerticalAlignment = 'top';
            app.textAudioFiles.WordWrap = 'on';
            app.textAudioFiles.FontSize = 16;
            app.textAudioFiles.FontWeight = 'bold';
            app.textAudioFiles.FontColor = [1 1 1];
            app.textAudioFiles.Position = [12 101 238 21];
            app.textAudioFiles.Text = 'Audio Files';

            % Create dropdownAudioFiles
            app.dropdownAudioFiles = uidropdown(app.mainfigure);
            app.dropdownAudioFiles.Items = {'Audio Wave File'};
            app.dropdownAudioFiles.ValueChangedFcn = createCallbackFcn(app, @dropdownAudioFiles_Callback, true);
            app.dropdownAudioFiles.Tag = 'AudioFilespopup';
            app.dropdownAudioFiles.FontSize = 10.6666666666667;
            app.dropdownAudioFiles.FontColor = [1 1 1];
            app.dropdownAudioFiles.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.dropdownAudioFiles.Position = [12 76 238 26];
            app.dropdownAudioFiles.Value = 'Audio Wave File';

            % Create buttonDetectCalls
            app.buttonDetectCalls = uibutton(app.mainfigure, 'push');
            app.buttonDetectCalls.ButtonPushedFcn = createCallbackFcn(app, @buttonDetectCalls_Callback, true);
            app.buttonDetectCalls.Tag = 'multinetdect';
            app.buttonDetectCalls.BackgroundColor = [0.949019607843137 0.450980392156863 0.101960784313725];
            app.buttonDetectCalls.FontWeight = 'bold';
            app.buttonDetectCalls.FontColor = [1 1 1];
            app.buttonDetectCalls.Position = [275 86 90 24];
            app.buttonDetectCalls.Text = 'Detect Calls';

            % Create textDetCallFiles
            app.textDetCallFiles = uilabel(app.mainfigure);
            app.textDetCallFiles.Tag = 'textdetectedcallfiles';
            app.textDetCallFiles.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textDetCallFiles.VerticalAlignment = 'top';
            app.textDetCallFiles.WordWrap = 'on';
            app.textDetCallFiles.FontSize = 16;
            app.textDetCallFiles.FontWeight = 'bold';
            app.textDetCallFiles.FontColor = [1 1 1];
            app.textDetCallFiles.Position = [12 46 239 22];
            app.textDetCallFiles.Text = 'Detected Call Files';

            % Create dropdownDetCallFiles
            app.dropdownDetCallFiles = uidropdown(app.mainfigure);
            app.dropdownDetCallFiles.Items = {'Completed Detection Files'};
            app.dropdownDetCallFiles.ValueChangedFcn = createCallbackFcn(app, @dropdownDetCallFiles_Callback, true);
            app.dropdownDetCallFiles.Tag = 'popupmenuDetectionFiles';
            app.dropdownDetCallFiles.FontSize = 10.6666666666667;
            app.dropdownDetCallFiles.FontColor = [1 1 1];
            app.dropdownDetCallFiles.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.dropdownDetCallFiles.Position = [11 24 239 23];
            app.dropdownDetCallFiles.Value = 'Completed Detection Files';

            % Create buttonRejectCall
            app.buttonRejectCall = uibutton(app.mainfigure, 'push');
            app.buttonRejectCall.ButtonPushedFcn = createCallbackFcn(app, @buttonRejectCall_Callback, true);
            app.buttonRejectCall.Tag = 'RejectCall';
            app.buttonRejectCall.BackgroundColor = [0.949019607843137 0.450980392156863 0.101960784313725];
            app.buttonRejectCall.FontWeight = 'bold';
            app.buttonRejectCall.FontColor = [1 1 1];
            app.buttonRejectCall.Position = [596 88 89 24];
            app.buttonRejectCall.Text = 'Reject Call (r)';

            % Create buttonLoadCalls
            app.buttonLoadCalls = uibutton(app.mainfigure, 'push');
            app.buttonLoadCalls.ButtonPushedFcn = createCallbackFcn(app, @buttonLoadCalls_Callback, true);
            app.buttonLoadCalls.Tag = 'loadcalls';
            app.buttonLoadCalls.BackgroundColor = [0.568627450980392 0.141176470588235 0.4];
            app.buttonLoadCalls.FontWeight = 'bold';
            app.buttonLoadCalls.FontColor = [1 1 1];
            app.buttonLoadCalls.Position = [275 56 91.0000000000001 24];
            app.buttonLoadCalls.Text = 'Load Calls';

            % Create textCalls
            app.textCalls = uilabel(app.mainfigure);
            app.textCalls.Tag = 'Ccalls';
            app.textCalls.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textCalls.VerticalAlignment = 'top';
            app.textCalls.WordWrap = 'on';
            app.textCalls.FontSize = 16;
            app.textCalls.FontWeight = 'bold';
            app.textCalls.FontColor = [1 1 1];
            app.textCalls.Position = [9 776 192 24];
            app.textCalls.Text = 'Calls: 0/0';

            % Create textScore
            app.textScore = uilabel(app.mainfigure);
            app.textScore.Tag = 'score';
            app.textScore.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textScore.VerticalAlignment = 'top';
            app.textScore.WordWrap = 'on';
            app.textScore.FontSize = 16;
            app.textScore.FontWeight = 'bold';
            app.textScore.FontColor = [1 1 1];
            app.textScore.Position = [9 752 192 24];
            app.textScore.Text = 'Score:';

            % Create textStatus
            app.textStatus = uilabel(app.mainfigure);
            app.textStatus.Tag = 'status';
            app.textStatus.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textStatus.VerticalAlignment = 'top';
            app.textStatus.WordWrap = 'on';
            app.textStatus.FontSize = 16;
            app.textStatus.FontWeight = 'bold';
            app.textStatus.FontColor = [1 1 1];
            app.textStatus.Position = [9 728 192 24];
            app.textStatus.Text = 'Status:';

            % Create dropdownColorMap
            app.dropdownColorMap = uidropdown(app.mainfigure);
            app.dropdownColorMap.Items = {'inferno', 'magma', 'plasma', 'viridis', 'cubehelix', 'black&white', 'gray', 'jet', 'hot', 'parula', 'hsv', 'cool', 'spring', 'summer', 'autumn', 'winter', 'bone', 'copper', 'pink'};
            app.dropdownColorMap.ValueChangedFcn = createCallbackFcn(app, @dropdownColorMap_Callback, true);
            app.dropdownColorMap.Tag = 'popupmenuColorMap';
            app.dropdownColorMap.FontSize = 10.6666666666667;
            app.dropdownColorMap.FontWeight = 'bold';
            app.dropdownColorMap.FontColor = [1 1 1];
            app.dropdownColorMap.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.dropdownColorMap.Position = [1250 70 124 24];
            app.dropdownColorMap.Value = 'inferno';

            % Create textFrequency
            app.textFrequency = uilabel(app.mainfigure);
            app.textFrequency.Tag = 'freq';
            app.textFrequency.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textFrequency.VerticalAlignment = 'top';
            app.textFrequency.WordWrap = 'on';
            app.textFrequency.FontSize = 16;
            app.textFrequency.FontWeight = 'bold';
            app.textFrequency.FontColor = [1 1 1];
            app.textFrequency.Position = [9 632 192 24];
            app.textFrequency.Text = 'Frequency (KHz):';

            % Create buttonDraw
            app.buttonDraw = uibutton(app.mainfigure, 'push');
            app.buttonDraw.ButtonPushedFcn = createCallbackFcn(app, @buttonDraw_Callback, true);
            app.buttonDraw.Tag = 'rectangle';
            app.buttonDraw.BackgroundColor = [0.858823529411765 0.32156862745098 0.219607843137255];
            app.buttonDraw.FontWeight = 'bold';
            app.buttonDraw.FontColor = [1 1 1];
            app.buttonDraw.Position = [490 57 94 24];
            app.buttonDraw.Text = 'Draw (d)';

            % Create textDuration
            app.textDuration = uilabel(app.mainfigure);
            app.textDuration.Tag = 'duration';
            app.textDuration.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textDuration.VerticalAlignment = 'top';
            app.textDuration.WordWrap = 'on';
            app.textDuration.FontSize = 16;
            app.textDuration.FontWeight = 'bold';
            app.textDuration.FontColor = [1 1 1];
            app.textDuration.Position = [9 608 192 24];
            app.textDuration.Text = 'Duration (ms):';

            % Create textSlope
            app.textSlope = uilabel(app.mainfigure);
            app.textSlope.Tag = 'slope';
            app.textSlope.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textSlope.VerticalAlignment = 'top';
            app.textSlope.WordWrap = 'on';
            app.textSlope.FontSize = 16;
            app.textSlope.FontWeight = 'bold';
            app.textSlope.FontColor = [1 1 1];
            app.textSlope.Position = [9 584 192 24];
            app.textSlope.Text = 'Slope (KHz/s):';

            % Create textSinuosity
            app.textSinuosity = uilabel(app.mainfigure);
            app.textSinuosity.Tag = 'sinuosity';
            app.textSinuosity.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textSinuosity.VerticalAlignment = 'top';
            app.textSinuosity.WordWrap = 'on';
            app.textSinuosity.FontSize = 16;
            app.textSinuosity.FontWeight = 'bold';
            app.textSinuosity.FontColor = [1 1 1];
            app.textSinuosity.Position = [9 560 192 24];
            app.textSinuosity.Text = 'Sinuosity:';

            % Create buttonMultiDetect
            app.buttonMultiDetect = uibutton(app.mainfigure, 'push');
            app.buttonMultiDetect.ButtonPushedFcn = createCallbackFcn(app, @buttonMultiDetect_Callback, true);
            app.buttonMultiDetect.Tag = 'multinetdect_1';
            app.buttonMultiDetect.BackgroundColor = [0.949019607843137 0.450980392156863 0.101960784313725];
            app.buttonMultiDetect.FontWeight = 'bold';
            app.buttonMultiDetect.FontColor = [1 1 1];
            app.buttonMultiDetect.Position = [374 87 85.0000000000001 24];
            app.buttonMultiDetect.Text = 'Multi Detect';

            % Create textRelPwr
            app.textRelPwr = uilabel(app.mainfigure);
            app.textRelPwr.Tag = 'powertext';
            app.textRelPwr.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textRelPwr.VerticalAlignment = 'top';
            app.textRelPwr.WordWrap = 'on';
            app.textRelPwr.FontSize = 16;
            app.textRelPwr.FontWeight = 'bold';
            app.textRelPwr.FontColor = [1 1 1];
            app.textRelPwr.Position = [9 536 192 24];
            app.textRelPwr.Text = 'Rel Pwr:';

            % Create textColorMap
            app.textColorMap = uilabel(app.mainfigure);
            app.textColorMap.Tag = 'text17';
            app.textColorMap.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textColorMap.VerticalAlignment = 'top';
            app.textColorMap.WordWrap = 'on';
            app.textColorMap.FontSize = 13.3333333333333;
            app.textColorMap.FontWeight = 'bold';
            app.textColorMap.FontColor = [1 1 1];
            app.textColorMap.Position = [1250 94 124 18];
            app.textColorMap.Text = 'Color Map';

            % Create textUserID
            app.textUserID = uilabel(app.mainfigure);
            app.textUserID.Tag = 'text19';
            app.textUserID.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textUserID.VerticalAlignment = 'top';
            app.textUserID.WordWrap = 'on';
            app.textUserID.FontSize = 16;
            app.textUserID.FontWeight = 'bold';
            app.textUserID.FontColor = [1 1 1];
            app.textUserID.Position = [9 704 192 24];
            app.textUserID.Text = 'User ID:';

            % Create textContour
            app.textContour = uilabel(app.mainfigure);
            app.textContour.Tag = 'text20';
            app.textContour.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textContour.VerticalAlignment = 'top';
            app.textContour.WordWrap = 'on';
            app.textContour.FontSize = 10.6666666666667;
            app.textContour.FontWeight = 'bold';
            app.textContour.FontColor = [1 1 1];
            app.textContour.Position = [9 494 121 16];
            app.textContour.Text = 'Contour';

            % Create textTonality
            app.textTonality = uilabel(app.mainfigure);
            app.textTonality.Tag = 'tonalitytext';
            app.textTonality.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textTonality.VerticalAlignment = 'top';
            app.textTonality.WordWrap = 'on';
            app.textTonality.FontSize = 16;
            app.textTonality.FontWeight = 'bold';
            app.textTonality.FontColor = [1 1 1];
            app.textTonality.Position = [9 512 192 24];
            app.textTonality.Text = 'Tonality:';

            % Create textWaveform
            app.textWaveform = uilabel(app.mainfigure);
            app.textWaveform.Tag = 'text23';
            app.textWaveform.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textWaveform.VerticalAlignment = 'top';
            app.textWaveform.WordWrap = 'on';
            app.textWaveform.FontSize = 10.6666666666667;
            app.textWaveform.FontWeight = 'bold';
            app.textWaveform.FontColor = [1 1 1];
            app.textWaveform.Position = [12 342 121 16];
            app.textWaveform.Text = 'Waveform';

            % Create buttonBackALot
            app.buttonBackALot = uibutton(app.mainfigure, 'push');
            app.buttonBackALot.ButtonPushedFcn = createCallbackFcn(app, @buttonBackALot_Callback, true);
            app.buttonBackALot.Tag = 'backwardButton';
            app.buttonBackALot.BackgroundColor = [0.949019607843137 0.450980392156863 0.101960784313725];
            app.buttonBackALot.FontSize = 14.6666666666667;
            app.buttonBackALot.FontWeight = 'bold';
            app.buttonBackALot.FontColor = [1 1 1];
            app.buttonBackALot.Tooltip = 'Previous Page';
            app.buttonBackALot.Position = [700 88 40 24];
            app.buttonBackALot.Text = '<<<';

            % Create buttonFwdALot
            app.buttonFwdALot = uibutton(app.mainfigure, 'push');
            app.buttonFwdALot.ButtonPushedFcn = createCallbackFcn(app, @buttonFwdALot_Callback, true);
            app.buttonFwdALot.Tag = 'forwardButton';
            app.buttonFwdALot.BackgroundColor = [0.949019607843137 0.450980392156863 0.101960784313725];
            app.buttonFwdALot.FontSize = 14.6666666666667;
            app.buttonFwdALot.FontWeight = 'bold';
            app.buttonFwdALot.FontColor = [1 1 1];
            app.buttonFwdALot.Tooltip = 'Next Page';
            app.buttonFwdALot.Position = [899 88 40 24];
            app.buttonFwdALot.Text = '>>>';

            % Create dropdownFocus
            app.dropdownFocus = uidropdown(app.mainfigure);
            app.dropdownFocus.Items = {'0.25s', '0.5s', '1s'};
            app.dropdownFocus.ValueChangedFcn = createCallbackFcn(app, @dropdownFocus_Callback, true);
            app.dropdownFocus.Tag = 'focusWindowSizePopup';
            app.dropdownFocus.FontSize = 10.6666666666667;
            app.dropdownFocus.FontColor = [1 1 1];
            app.dropdownFocus.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.dropdownFocus.Position = [962 72 73 22];
            app.dropdownFocus.Value = '0.5s';

            % Create textFocus
            app.textFocus = uilabel(app.mainfigure);
            app.textFocus.Tag = 'text25';
            app.textFocus.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textFocus.VerticalAlignment = 'top';
            app.textFocus.WordWrap = 'on';
            app.textFocus.FontSize = 13.3333333333333;
            app.textFocus.FontWeight = 'bold';
            app.textFocus.FontColor = [1 1 1];
            app.textFocus.Position = [962 94 73 18];
            app.textFocus.Text = 'Focus';

            % Create textPage
            app.textPage = uilabel(app.mainfigure);
            app.textPage.Tag = 'text26';
            app.textPage.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textPage.VerticalAlignment = 'top';
            app.textPage.WordWrap = 'on';
            app.textPage.FontSize = 13.3333333333333;
            app.textPage.FontWeight = 'bold';
            app.textPage.FontColor = [1 1 1];
            app.textPage.Position = [1049 94 70 18];
            app.textPage.Text = 'Page';

            % Create dropdownPage
            app.dropdownPage = uidropdown(app.mainfigure);
            app.dropdownPage.Items = {'2s', '3s', '5s', '10s', ''};
            app.dropdownPage.ValueChangedFcn = createCallbackFcn(app, @dropdownPage_Callback, true);
            app.dropdownPage.Tag = 'epochWindowSizePopup';
            app.dropdownPage.FontSize = 10.6666666666667;
            app.dropdownPage.FontColor = [1 1 1];
            app.dropdownPage.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.dropdownPage.Position = [1049 72 70 22];
            app.dropdownPage.Value = '2s';

            % Create buttonDisplaySettings
            app.buttonDisplaySettings = uibutton(app.mainfigure, 'push');
            app.buttonDisplaySettings.ButtonPushedFcn = createCallbackFcn(app, @buttonDisplaySettings_Callback, true);
            app.buttonDisplaySettings.Tag = 'spectrogramScalePopup';
            app.buttonDisplaySettings.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.buttonDisplaySettings.FontSize = 10.6666666666667;
            app.buttonDisplaySettings.FontColor = [1 1 1];
            app.buttonDisplaySettings.Position = [1129 72 99 22];
            app.buttonDisplaySettings.Text = 'Display Settings';

            % Create textScale
            app.textScale = uilabel(app.mainfigure);
            app.textScale.Tag = 'AmplitudeScaleText';
            app.textScale.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textScale.VerticalAlignment = 'top';
            app.textScale.WordWrap = 'on';
            app.textScale.FontSize = 13.3333333333333;
            app.textScale.FontWeight = 'bold';
            app.textScale.FontColor = [1 1 1];
            app.textScale.Position = [1131 94 74 18];
            app.textScale.Text = 'Scale';

            % Create buttonBackABit
            app.buttonBackABit = uibutton(app.mainfigure, 'push');
            app.buttonBackABit.ButtonPushedFcn = createCallbackFcn(app, @buttonBackABit_Callback, true);
            app.buttonBackABit.Tag = 'topLeftButton';
            app.buttonBackABit.BackgroundColor = [0.858823529411765 0.32156862745098 0.219607843137255];
            app.buttonBackABit.FontSize = 14.6666666666667;
            app.buttonBackABit.FontWeight = 'bold';
            app.buttonBackABit.FontColor = [1 1 1];
            app.buttonBackABit.Tooltip = 'Previous Window';
            app.buttonBackABit.Position = [743 88 37.0000000000001 24];
            app.buttonBackABit.Text = '<<';

            % Create buttonFwdABit
            app.buttonFwdABit = uibutton(app.mainfigure, 'push');
            app.buttonFwdABit.ButtonPushedFcn = createCallbackFcn(app, @buttonFwdABit_Callback, true);
            app.buttonFwdABit.Tag = 'topRightButton';
            app.buttonFwdABit.BackgroundColor = [0.858823529411765 0.32156862745098 0.219607843137255];
            app.buttonFwdABit.FontSize = 14.6666666666667;
            app.buttonFwdABit.FontWeight = 'bold';
            app.buttonFwdABit.FontColor = [1 1 1];
            app.buttonFwdABit.Tooltip = 'Next Window';
            app.buttonFwdABit.Position = [864 88 31 24];
            app.buttonFwdABit.Text = '>>';

            % Create buttonLoadAudio
            app.buttonLoadAudio = uibutton(app.mainfigure, 'push');
            app.buttonLoadAudio.ButtonPushedFcn = createCallbackFcn(app, @buttonLoadAudio_Callback, true);
            app.buttonLoadAudio.Tag = 'loadAudioFile';
            app.buttonLoadAudio.BackgroundColor = [0.568627450980392 0.141176470588235 0.4];
            app.buttonLoadAudio.FontWeight = 'bold';
            app.buttonLoadAudio.FontColor = [1 1 1];
            app.buttonLoadAudio.Position = [374 56 85.0000000000001 24];
            app.buttonLoadAudio.Text = 'Load Audio';

            % Create textDetectLoadRecord
            app.textDetectLoadRecord = uilabel(app.mainfigure);
            app.textDetectLoadRecord.Tag = 'text29';
            app.textDetectLoadRecord.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textDetectLoadRecord.VerticalAlignment = 'top';
            app.textDetectLoadRecord.WordWrap = 'on';
            app.textDetectLoadRecord.FontSize = 13.3333333333333;
            app.textDetectLoadRecord.FontWeight = 'bold';
            app.textDetectLoadRecord.FontColor = [1 1 1];
            app.textDetectLoadRecord.Position = [277 115 203 18];
            app.textDetectLoadRecord.Text = {'Detect, Load, & Record -------'; '________________________________________'};

            % Create textSettings
            app.textSettings = uilabel(app.mainfigure);
            app.textSettings.Tag = 'text31';
            app.textSettings.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textSettings.VerticalAlignment = 'top';
            app.textSettings.WordWrap = 'on';
            app.textSettings.FontSize = 13.3333333333333;
            app.textSettings.FontWeight = 'bold';
            app.textSettings.FontColor = [1 1 1];
            app.textSettings.Position = [962 116 412 18];
            app.textSettings.Text = 'Settings ----------------------------------------------------------------------------------------';

            % Create buttonInvertCmap
            app.buttonInvertCmap = uibutton(app.mainfigure, 'push');
            app.buttonInvertCmap.ButtonPushedFcn = createCallbackFcn(app, @buttonInvertCmap_Callback, true);
            app.buttonInvertCmap.Tag = 'invert_cmap';
            app.buttonInvertCmap.Icon = 'invert_cmap_image.png';
            app.buttonInvertCmap.IconAlignment = 'center';
            app.buttonInvertCmap.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.buttonInvertCmap.FontSize = 10.6666666666667;
            app.buttonInvertCmap.FontColor = [1 1 1];
            app.buttonInvertCmap.Position = [1380 72 31 23];
            app.buttonInvertCmap.Text = '';

            % Create buttonHighCLimMinus
            app.buttonHighCLimMinus = uibutton(app.mainfigure, 'push');
            app.buttonHighCLimMinus.ButtonPushedFcn = createCallbackFcn(app, @buttonHighCLimMinus_Callback, true);
            app.buttonHighCLimMinus.Tag = 'high_clim_minus';
            app.buttonHighCLimMinus.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.buttonHighCLimMinus.FontSize = 10.6666666666667;
            app.buttonHighCLimMinus.FontColor = [1 1 1];
            app.buttonHighCLimMinus.Position = [1336 42 30 22];
            app.buttonHighCLimMinus.Text = '-';

            % Create buttonHighCLimPlus
            app.buttonHighCLimPlus = uibutton(app.mainfigure, 'push');
            app.buttonHighCLimPlus.ButtonPushedFcn = createCallbackFcn(app, @buttonHighCLimPlus_Callback, true);
            app.buttonHighCLimPlus.Tag = 'high_clim_plus';
            app.buttonHighCLimPlus.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.buttonHighCLimPlus.FontSize = 10.6666666666667;
            app.buttonHighCLimPlus.FontColor = [1 1 1];
            app.buttonHighCLimPlus.Position = [1371 42 30 22];
            app.buttonHighCLimPlus.Text = '+';

            % Create buttonLowCLimPlus
            app.buttonLowCLimPlus = uibutton(app.mainfigure, 'push');
            app.buttonLowCLimPlus.ButtonPushedFcn = createCallbackFcn(app, @buttonLowCLimPlus_Callback, true);
            app.buttonLowCLimPlus.Tag = 'low_clim_plus';
            app.buttonLowCLimPlus.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.buttonLowCLimPlus.FontSize = 10.6666666666667;
            app.buttonLowCLimPlus.FontColor = [1 1 1];
            app.buttonLowCLimPlus.Position = [1371 17 30 22];
            app.buttonLowCLimPlus.Text = '+';

            % Create buttonLowCLimMinus
            app.buttonLowCLimMinus = uibutton(app.mainfigure, 'push');
            app.buttonLowCLimMinus.ButtonPushedFcn = createCallbackFcn(app, @buttonLowCLimMinus_Callback, true);
            app.buttonLowCLimMinus.Tag = 'low_clim_minus';
            app.buttonLowCLimMinus.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.buttonLowCLimMinus.FontSize = 10.6666666666667;
            app.buttonLowCLimMinus.FontColor = [1 1 1];
            app.buttonLowCLimMinus.Position = [1336 17 30 22];
            app.buttonLowCLimMinus.Text = '-';

            % Create buttonRecordAudio
            app.buttonRecordAudio = uibutton(app.mainfigure, 'state');
            app.buttonRecordAudio.ValueChangedFcn = createCallbackFcn(app, @buttonRecordAudio_Callback, true);
            app.buttonRecordAudio.Tag = 'recordAudio';
            app.buttonRecordAudio.Text = 'Record Audio';
            app.buttonRecordAudio.BackgroundColor = [0.392156862745098 0.831372549019608 0.0745098039215686];
            app.buttonRecordAudio.FontWeight = 'bold';
            app.buttonRecordAudio.FontColor = [1 1 1];
            app.buttonRecordAudio.Position = [274 24 92.0000000000001 25];

            % Create textNavigation
            app.textNavigation = uilabel(app.mainfigure);
            app.textNavigation.Tag = 'text30';
            app.textNavigation.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textNavigation.VerticalAlignment = 'top';
            app.textNavigation.WordWrap = 'on';
            app.textNavigation.FontSize = 13.3333333333333;
            app.textNavigation.FontWeight = 'bold';
            app.textNavigation.FontColor = [1 1 1];
            app.textNavigation.Position = [700 115 239 18];
            app.textNavigation.Text = 'Navigation -----------------------------------------';

            % Create textDetReview
            app.textDetReview = uilabel(app.mainfigure);
            app.textDetReview.Tag = 'text18';
            app.textDetReview.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textDetReview.VerticalAlignment = 'top';
            app.textDetReview.WordWrap = 'on';
            app.textDetReview.FontSize = 13.3333333333333;
            app.textDetReview.FontWeight = 'bold';
            app.textDetReview.FontColor = [1 1 1];
            app.textDetReview.Position = [494 115 196 18];
            app.textDetReview.Text = 'Detection Review ------------------';

            % Create sliderTonality
            app.sliderTonality = uislider(app.mainfigure);
            app.sliderTonality.Limits = [0 1];
            app.sliderTonality.MajorTicks = [];
            app.sliderTonality.Orientation = 'vertical';
            app.sliderTonality.ValueChangedFcn = createCallbackFcn(app, @sliderTonality_Callback, true);
            app.sliderTonality.MinorTicks = [];
            app.sliderTonality.Tag = 'TonalitySlider';
            app.sliderTonality.FontSize = 10.6666666666667;
            app.sliderTonality.Position = [223 223 3 118];

            % Create buttonNextFile
            app.buttonNextFile = uibutton(app.mainfigure, 'push');
            app.buttonNextFile.ButtonPushedFcn = createCallbackFcn(app, @buttonNextFile_Callback, true);
            app.buttonNextFile.Tag = 'NextFile';
            app.buttonNextFile.BackgroundColor = [0.870588235294118 0.113725490196078 0.580392156862745];
            app.buttonNextFile.FontSize = 14.6666666666667;
            app.buttonNextFile.FontWeight = 'bold';
            app.buttonNextFile.FontColor = [1 1 1];
            app.buttonNextFile.Tooltip = 'Next File';
            app.buttonNextFile.Position = [827 57 33.0000000000001 24];
            app.buttonNextFile.Text = '>|';

            % Create buttonPrevFile
            app.buttonPrevFile = uibutton(app.mainfigure, 'push');
            app.buttonPrevFile.ButtonPushedFcn = createCallbackFcn(app, @buttonPrevFile_Callback, true);
            app.buttonPrevFile.Tag = 'PrevFile';
            app.buttonPrevFile.BackgroundColor = [0.870588235294118 0.113725490196078 0.580392156862745];
            app.buttonPrevFile.FontSize = 14.6666666666667;
            app.buttonPrevFile.FontWeight = 'bold';
            app.buttonPrevFile.FontColor = [1 1 1];
            app.buttonPrevFile.Tooltip = 'Prev File';
            app.buttonPrevFile.Position = [784 57 33.0000000000001 24];
            app.buttonPrevFile.Text = '|<';

            % Create textLabel
            app.textLabel = uilabel(app.mainfigure);
            app.textLabel.Tag = 'text36';
            app.textLabel.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textLabel.VerticalAlignment = 'top';
            app.textLabel.WordWrap = 'on';
            app.textLabel.FontSize = 16;
            app.textLabel.FontWeight = 'bold';
            app.textLabel.FontColor = [1 1 1];
            app.textLabel.Position = [9 680 192 24];
            app.textLabel.Text = 'Label:';

            % Create textClustAssign
            app.textClustAssign = uilabel(app.mainfigure);
            app.textClustAssign.Tag = 'text37';
            app.textClustAssign.BackgroundColor = [0.101960784313725 0.101960784313725 0.101960784313725];
            app.textClustAssign.VerticalAlignment = 'top';
            app.textClustAssign.WordWrap = 'on';
            app.textClustAssign.FontSize = 16;
            app.textClustAssign.FontWeight = 'bold';
            app.textClustAssign.FontColor = [1 1 1];
            app.textClustAssign.Position = [9 656 192 24];
            app.textClustAssign.Text = 'Clust Assign:';

            % Show the figure after all components are created
            app.mainfigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = DeepWaves_exported(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.mainfigure)

                % Execute the startup function
                runStartupFcn(app, @(app)DeepWaves_OpeningFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.mainfigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.mainfigure)
        end
    end
end