classdef ContTraceDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgContTrace     matlab.ui.Figure
        buttonPrev       matlab.ui.control.Button
        buttonNext       matlab.ui.control.Button
        buttonClear      matlab.ui.control.Button
        buttonGen        matlab.ui.control.Button
        buttonAdd        matlab.ui.control.Button
        buttonDel        matlab.ui.control.Button
        buttonSaveClose  matlab.ui.control.Button
        winContour       matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        CallingApp      % Parent app object
        ClusteringData  % Master data container
        spect           % Spect settings (for save fn)
        EntThresh       % Entropy threshold default for auto generating contour
        AmpThresh       % Amplitude threshold default for auto generating contour
        indcall         % Call index
        xTimeEdit       % Edited time points
        xFreqEdit       % Edited freq points
        plSc            % Scatter plot handle (for manipulating contour)
        brushCont       % Data selection brush
        bAddOn          % Is Add Mode active?
    end
    
    methods (Access = private)
        
        % Call whenever a new call is displayed on screen
        function CTPlotNew(app)
            % Default edit containers
            app.xTimeEdit = app.ClusteringData.xTime{app.indcall};
            app.xFreqEdit = app.ClusteringData.xFreq{app.indcall};

            CTPlotRefresh(app);
            % 
            % % Plot boxed portion of spectrogram
            % plotspec = flipud(app.ClusteringData.Spectrogram{app.indcall});
            % specindymin = floor(app.ClusteringData.Box(app.indcall,2)/app.ClusteringData.FreqScale(app.indcall));
            % specindymax = ceil((app.ClusteringData.Box(app.indcall,2)+app.ClusteringData.Box(app.indcall,4))/app.ClusteringData.FreqScale(app.indcall));
            % app.winContour.XLim = [1,size(plotspec,2)];
            % app.winContour.YLim = [specindymin,specindymax];
            % imagesc([1,size(plotspec,2)],[specindymin,specindymax],plotspec(specindymin:specindymax,:),'Parent',app.winContour);
            % app.winContour.YDir = "normal";
            % hold(app.winContour,"on");
            % 
            % % Plot contour
            % plotx = app.xTimeEdit/app.ClusteringData.TimeScale(app.indcall);
            % ploty = app.xFreqEdit/app.ClusteringData.FreqScale(app.indcall);
            % app.plSc = scatter(plotx,ploty,25,'MarkerEdgeColor',[0 0 0],...
            %     'MarkerFaceColor',[1 1 1],'LineWidth',1.5,'Parent',app.winContour);
            % 
            % hold(app.winContour,"off");
        end
        
        % Call whenever changes are made to the contour
        function CTPlotRefresh(app)
            % Plot boxed portion of spectrogram
            plotspec = flipud(app.ClusteringData.Spectrogram{app.indcall});
            specindymin = floor(app.ClusteringData.Box(app.indcall,2)/app.ClusteringData.FreqScale(app.indcall));
            specindymax = ceil((app.ClusteringData.Box(app.indcall,2)+app.ClusteringData.Box(app.indcall,4))/app.ClusteringData.FreqScale(app.indcall));
            app.winContour.XLim = [1,size(plotspec,2)];
            app.winContour.YLim = [specindymin,specindymax];
            imagesc([1,size(plotspec,2)],[specindymin,specindymax],plotspec(specindymin:specindymax,:),'Parent',app.winContour);%,'ButtonDownFcn','winContClick_Callback(app)');
            app.winContour.YDir = "normal";
            hold(app.winContour,"on");

            % Plot contour
            plotx = app.xTimeEdit/app.ClusteringData.TimeScale(app.indcall);
            ploty = app.xFreqEdit/app.ClusteringData.FreqScale(app.indcall);
            app.plSc = scatter(plotx,ploty,25,'MarkerEdgeColor',[0 0 0],...
                'MarkerFaceColor',[1 1 1],'LineWidth',1.5,'Parent',app.winContour);%,'ButtonDownFcn','winContClick_Callback(app)');
            app.brushCont = brush(app.winContour);

            hold(app.winContour,"off");
            % Necessary for adding points
            set(get(app.winContour,'Children'),'HitTest','off');
        end

        function CTInterpolate(app)
            % ADD INTERPOLATION STEP
        end

        % Save edited contours to ClusteringData (should be called any time
        % Next/Prev/OK is pushed)
        function CTChangeCont(app)
            % Check changes
            if isempty(app.xTimeEdit) || isempty(app.xFreqEdit)
                % Warn user
                msgbox('Edited contour is empty; not saving changes')
            else
                % If all good, save to ClusteringData
                app.ClusteringData.xTime{app.indcall} = app.xTimeEdit;
                app.ClusteringData.xFreq{app.indcall} = app.xFreqEdit;
            end
        end

    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp, ClusteringData, spect, EntThresh, AmpThresh)
            % Link to parent app
            app.CallingApp = mainapp;
            app.ClusteringData = ClusteringData;
            app.spect = spect;
            app.EntThresh = EntThresh;
            app.AmpThresh = AmpThresh;

            % Setup function to manually add points
            app.bAddOn = false;

            % Plot first call, default contour
            app.indcall = 1;
            app.CTPlotNew();
        end

        % Button pushed function: buttonSaveClose
        function buttonSaveClose_Callback(app, event)
            % Save any changes on this screen
            app.CTChangeCont();
            
            dlgContTraceCloseRequest(app, event);
        end

        % Close request function: dlgContTrace
        function dlgContTraceCloseRequest(app, event)
            %Save Extracted Contours
            pind = regexp(char(app.ClusteringData{1,'Filename'}),'\');
            pind = pind(end);
            pname = char(app.ClusteringData{1,'Filename'});
            pname = pname(1:pind);
            [FileName,PathName] = uiputfile(fullfile(pname,'Extracted Contours.mat'),'Save edited contour data');
            if FileName ~= 0
                ClusteringData = app.ClusteringData;
                spect = app.spect;
                save(fullfile(PathName,FileName),'ClusteringData','spect','-v7.3');
            end
            
            % Delete Save dialog
            delete(app)
        end

        % Button pushed function: buttonNext
        function buttonNext_Callback(app, event)
            % Save any changes on this screen
            app.CTChangeCont();
            
            if app.indcall ~= height(app.ClusteringData)
                app.indcall = app.indcall+1;
                app.CTPlotNew();
            end
        end

        % Button pushed function: buttonPrev
        function buttonPrev_Callback(app, event)
            % Save any changes on this screen
            app.CTChangeCont();
            
            if app.indcall ~= 1
                app.indcall = app.indcall-1;
                app.CTPlotNew();
            end
        end

        % Button pushed function: buttonClear
        function buttonClear_Callback(app, event)
            app.xTimeEdit = [];
            app.xFreqEdit = [];

            app.CTPlotRefresh();
        end

        % Button pushed function: buttonGen
        function buttonGen_Callback(app, event)
            app.xFreqEdit = app.ClusteringData.xFreqAuto{app.indcall};
            app.xTimeEdit = app.ClusteringData.xTimeAuto{app.indcall};

            app.CTPlotRefresh();
        end

        % Button pushed function: buttonDel
        function buttonDel_Callback(app, event)
                    brushLog = logical(get(app.plSc, 'BrushData'));

                    if ~any(brushLog)
                        if strcmp(app.brushCont.Enable,'off')
                            app.brushCont.Enable = 'on';
                        else
                            app.brushCont.Enable = 'off';
                        end
                    else
                        app.xFreqEdit = app.xFreqEdit(~brushLog);
                        app.xTimeEdit = app.xTimeEdit(~brushLog);
    
                        app.CTPlotRefresh();
                    end
        end

        % Button pushed function: buttonAdd
        function buttonAdd_Callback(app, event)
            app.brushCont.Enable = 'off';
            app.bAddOn = ~app.bAddOn;
            if app.bAddOn
                app.buttonAdd.BackgroundColor = [1 0 0];
            else
                app.buttonAdd.BackgroundColor = [0.96,0.96,0.96];
            end
        end

        % Button down function: winContour
        function winContClick_Callback(app, event)
            if app.bAddOn
                hold(app.winContour,'on')
                app.xTimeEdit = [app.xTimeEdit,app.winContour.CurrentPoint(1,1)*app.ClusteringData.TimeScale(app.indcall)];
                app.xFreqEdit = [app.xFreqEdit;app.winContour.CurrentPoint(1,2)*app.ClusteringData.FreqScale(app.indcall)];
                [app.xTimeEdit, sortTimeInd] = sort(app.xTimeEdit);
                app.xFreqEdit = app.xFreqEdit(sortTimeInd);
                app.CTPlotRefresh();
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create dlgContTrace and hide until all components are created
            app.dlgContTrace = uifigure('Visible', 'off');
            app.dlgContTrace.Position = [100 100 696 648];
            app.dlgContTrace.Name = 'MATLAB App';
            app.dlgContTrace.CloseRequestFcn = createCallbackFcn(app, @dlgContTraceCloseRequest, true);
            app.dlgContTrace.WindowStyle = 'modal';

            % Create winContour
            app.winContour = uiaxes(app.dlgContTrace);
            app.winContour.XColor = [0.102 0.102 0.102];
            app.winContour.YColor = [0.102 0.102 0.102];
            app.winContour.ZColor = [0.102 0.102 0.102];
            app.winContour.Color = [0.102 0.102 0.102];
            app.winContour.FontSize = 10.6666666666667;
            app.winContour.NextPlot = 'add';
            app.winContour.ButtonDownFcn = createCallbackFcn(app, @winContClick_Callback, true);
            app.winContour.Tag = 'contourWindow';
            app.winContour.Position = [48 182 601 445];

            % Create buttonSaveClose
            app.buttonSaveClose = uibutton(app.dlgContTrace, 'push');
            app.buttonSaveClose.ButtonPushedFcn = createCallbackFcn(app, @buttonSaveClose_Callback, true);
            app.buttonSaveClose.Position = [294 30 109 42];
            app.buttonSaveClose.Text = 'Save & Close';

            % Create buttonDel
            app.buttonDel = uibutton(app.dlgContTrace, 'push');
            app.buttonDel.ButtonPushedFcn = createCallbackFcn(app, @buttonDel_Callback, true);
            app.buttonDel.Position = [382 98 100 23];
            app.buttonDel.Text = 'Delete Points';

            % Create buttonAdd
            app.buttonAdd = uibutton(app.dlgContTrace, 'push');
            app.buttonAdd.ButtonPushedFcn = createCallbackFcn(app, @buttonAdd_Callback, true);
            app.buttonAdd.Position = [382 138 100 23];
            app.buttonAdd.Text = 'Add Points';

            % Create buttonGen
            app.buttonGen = uibutton(app.dlgContTrace, 'push');
            app.buttonGen.ButtonPushedFcn = createCallbackFcn(app, @buttonGen_Callback, true);
            app.buttonGen.Position = [215 100 109 21];
            app.buttonGen.Text = 'Auto Contour';

            % Create buttonClear
            app.buttonClear = uibutton(app.dlgContTrace, 'push');
            app.buttonClear.ButtonPushedFcn = createCallbackFcn(app, @buttonClear_Callback, true);
            app.buttonClear.Position = [215 140 109 21];
            app.buttonClear.Text = 'Clear Contour';

            % Create buttonNext
            app.buttonNext = uibutton(app.dlgContTrace, 'push');
            app.buttonNext.ButtonPushedFcn = createCallbackFcn(app, @buttonNext_Callback, true);
            app.buttonNext.Position = [540 119 109 42];
            app.buttonNext.Text = 'Next';

            % Create buttonPrev
            app.buttonPrev = uibutton(app.dlgContTrace, 'push');
            app.buttonPrev.ButtonPushedFcn = createCallbackFcn(app, @buttonPrev_Callback, true);
            app.buttonPrev.Position = [48 119 109 42];
            app.buttonPrev.Text = 'Prev';

            % Show the figure after all components are created
            app.dlgContTrace.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ContTraceDlg_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.dlgContTrace)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.dlgContTrace)
        end
    end
end