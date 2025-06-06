classdef CallReviewDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgCallReview            matlab.ui.Figure
        panelImgs                matlab.ui.container.Panel
        panelButtons             matlab.ui.container.Panel
        buttonNext               matlab.ui.control.Button
        buttonPrev               matlab.ui.control.Button
        buttonReject             matlab.ui.control.Button
        buttonSaveClose          matlab.ui.control.Button
        panelTop                 matlab.ui.container.Panel
        ofCallstoDisplayLabel_3  matlab.ui.control.Label
        ofCallstoDisplayLabel_2  matlab.ui.control.Label
        ConvertAllLabel          matlab.ui.control.Label
        ToLabel                  matlab.ui.control.Label
        dropdownCallType         matlab.ui.control.DropDown
        AssignCallTypeLabel      matlab.ui.control.Label
        dropdownConvertFrom      matlab.ui.control.DropDown
        dropdownConvertTo        matlab.ui.control.DropDown
        buttonConvertApply       matlab.ui.control.Button
        editfieldCallIndex       matlab.ui.control.NumericEditField
        labelTotalCalls          matlab.ui.control.Label
        CallLabel                matlab.ui.control.Label
        ofCallstoDisplayLabel    matlab.ui.control.Label
        editfieldNum2Disp        matlab.ui.control.NumericEditField
        editfieldnTimePad        matlab.ui.control.NumericEditField
        editfieldnFreqPad        matlab.ui.control.NumericEditField
    end

    
    properties (Access = private)
        CallingApp      % Parent app object
        detfilename     % Full path to loaded dets file
        Calls           % Master data container
        allAudio        % Audio info for Calls
        spect           % Spectrogram info for Calls
        detmetadata     % Detection metadata for Calls
        indNumDisp      % # of Calls to display
        indSt           % Call index start
        indEnd          % Call index end
        indSel          % Call index/indices selected
        strConvFrom     % Call type to convert from
        strConvTo       % Call type to convert to
        nTimePad        % Pad displayed spectrogram (time)
        nFreqPad        % Pad displayed spectrogram (freq kHz)
    end
    
    methods (Access = private)
        
        % Call whenever a new call is displayed on screen
        function RevPlotNew(app)
            % Set call index
            app.editfieldCallIndex.Value = app.indSt;
            app.editfieldNum2Disp.Value = app.indNumDisp;
            app.editfieldnTimePad.Value = app.nTimePad;
            app.editfieldnFreqPad.Value = app.nFreqPad*1000;

            RevPlotRefresh(app);
        end
        
        % Call whenever changes are made to the contour
        function RevPlotRefresh(app)
            % (Re)set dropdowns calltype list
            app.dropdownCallType.Items = [cellstr(unique(app.Calls.Type)); 'Add New Call Type'];
            app.indSel = [];
            app.dropdownCallType.Value = char(app.Calls.Type(min(app.indSt)));

            app.dropdownConvertFrom.Items = ['Select...'; cellstr(unique(app.Calls.Type))];
            app.dropdownConvertTo.Items = ['Select...'; cellstr(unique(app.Calls.Type)); 'Add New Call Type'];
            app.dropdownConvertFrom.Value = 'Select...';
            app.dropdownConvertTo.Value = 'Select...';

            %% For each call on display, create spectrogram image
            d = uiprogressdlg(app.dlgCallReview,'Title','Please Wait',...
                'Message','Creating Spectrograms');
            montTile = tiledlayout(app.panelImgs,'flow','TileSpacing','Tight','Padding','Tight');
            app.indEnd = min(app.indSt+app.indNumDisp-1,height(app.Calls));
            for i = app.indSt:app.indEnd
                d.Value = (i-app.indSt+1)/(app.indEnd-app.indSt+1);
                ax1 = nexttile(montTile);

                % Create spectrogram image
                [~,wind,noverlap,nfft,~,~,~,~,~,~,pow] = CreateFocusSpectrogram(app.Calls(i,:), app.CallingApp.DAdata, true, app.nTimePad);

                if (1/app.CallingApp.DAdata.settings.spect.nfft > (app.Calls.Box(i,4)*1000))
                    error('%s\n%s\n','Spectrogram settings bad - recommend loading Calls in DA, adjusting Display Settings, save, and try again')
                end
                
                % If spectrogram settings iffy
                if any(size(pow) < 3)
                    warning('FFT settings suboptimal and causing calls to be skipped')
                    im = zeros(10,10);
                else
                    pow(pow==0)=.01;
                    pow = log10(pow);
                    pow = rescale(imcomplement(abs(pow)));
                    % Create Adjusted Image for Identification
                    xTile=ceil(size(pow,1)/10);
                    yTile=ceil(size(pow,2)/10);
                    if xTile>1 && yTile>1
                        im = adapthisteq(flipud(pow),'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
                    else
                        im = adapthisteq(flipud(pow),'NumTiles',[2 2],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);    
                    end
                end
            
                im = uint8(im .* 256);

                spectrange = app.Calls.Audiodata(i).SampleRate / 2000; % get frequency range of spectrogram in KHz
                FreqScale = spectrange / (1 + floor(nfft / 2)); % size of frequency pixels
                TimeScale = (wind - noverlap) / app.Calls.Audiodata(i).SampleRate; % size of time pixels

                % Plot boxed portion of spectrogram
                plotspec = flipud(im);
                lowfreq = app.Calls.Box(i,2)-app.nFreqPad;
                highfreq = app.Calls.Box(i,2)+app.Calls.Box(i,4)+app.nFreqPad;
                lowfreq = max(0.001,lowfreq);
                highfreq = min(spectrange,highfreq);
                specindymin = floor(lowfreq/FreqScale);
                specindymax = ceil(highfreq/FreqScale);
                specindymin = max(specindymin,1);
                ax1.XLim = [1,size(plotspec,2)];
                ax1.YLim = [specindymin,specindymax];
                imagesc(ax1,[1,size(plotspec,2)],[specindymin,specindymax],plotspec(specindymin:specindymax,:),"HitTest","off");
                ax1.YDir = "normal";
                title(ax1,sprintf('%s (%s)',num2str(i),app.Calls.Type(i)));
                % Make axes in proper units
                ax1.XTick = [size(plotspec,2)];
                ax1.XTickLabel{1} = ax1.XTick(1)*TimeScale;
                for j = 1:length(ax1.YTick)
                    ax1.YTickLabel{j} = round(ax1.YTick(j)*FreqScale*1000);
                end
                ax1.ButtonDownFcn = @(btn,event) panelImgsClick_Callback(app,event);
                disableDefaultInteractivity(ax1)
                ax1.Toolbar.Visible = 'off'; 
            end
            close(d)
        end

        function panelImgsClick_Callback(app,event)
            thisSel = regexp(event.Source.Title.String,'\d+','match');
            thisSel = str2double(thisSel{1});
            % If selection was already selected, un-select
            if ismember(thisSel,app.indSel)
                app.indSel(app.indSel==thisSel) = [];
                event.Source.Children.AlphaData = 1;
            % If selection not already select, select
            else
                app.indSel = union(thisSel,app.indSel);
                event.Source.Children.AlphaData = 0.5;
            end
            if isempty(app.indSel)
                app.dropdownCallType.Enable = "off";
                app.dropdownCallType.Value = char(app.Calls.Type(min(app.indSt)));
            else
                app.dropdownCallType.Enable = "on";
                app.dropdownCallType.Value = char(app.Calls.Type(min(app.indSel)));
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp, detfilename, handles)
            % Link to parent app
            app.CallingApp = mainapp;
            app.detfilename = detfilename;

            h = uiprogressdlg(app.dlgCallReview,'Title','Please Wait',...
                'Message','Loading Calls','Indeterminate','on');
            [app.Calls, app.allAudio, app.spect, app.detmetadata] = loadCallfile(detfilename, handles, false);
            app.CallingApp.DAdata.settings.spect = app.spect;
            close(h);

            % Link Parent to UIAxes
            app.panelImgs.Parent = app.dlgCallReview;

            % Sort Types by frequency b/c categorical
            typesort = countcats(app.Calls.Type);
            [~,typesort] = sort(typesort,'descend');
            app.Calls.Type = reordercats(app.Calls.Type,typesort);

            % Set call index limits
            app.editfieldCallIndex.Limits = [1,height(app.Calls)];
            app.labelTotalCalls.Text = ['/',num2str(height(app.Calls)),' Total Calls'];

            % Default strings
            app.strConvFrom = 'Select...';
            app.strConvTo = 'Select...';

            % Plot first call, default contour
            app.indNumDisp = 9;
            app.indSt = 1;
            app.nTimePad = 0.5;
            app.nFreqPad = 0.01;
            app.RevPlotNew();
        end

        % Button pushed function: buttonSaveClose
        function buttonSaveClose_Callback(app, event)
            dlgCallReviewCloseRequest(app, event);
        end

        % Close request function: dlgCallReview
        function dlgCallReviewCloseRequest(app, event)
            %Save Edited Dets
            [FileName, PathName] = uiputfile(app.detfilename, 'Save Session (.mat)');
            if FileName ~= 0
                Calls = app.Calls;
                allAudio = app.allAudio;
                detection_metadata = app.detmetadata;
                spect = app.spect;
                szCalls = whos('Calls');
                szallAudio = whos('allAudio');
                szdetmd = whos('detection_metadata');
                szspect = whos('spect');
                szTotal = szCalls.bytes + szspect.bytes + szdetmd.bytes + szallAudio.bytes;
                if szTotal >= 2000000000
                    if exist(fullfile(PathName, FileName),'file')
                        save(fullfile(PathName, FileName), 'Calls', '-v7.3','-append');
                    else
                        save(fullfile(PathName, FileName), 'Calls','allAudio','detection_metadata','spect', '-v7.3');
                    end
                else
                    if exist(fullfile(PathName, FileName),'file')
                        save(fullfile(PathName, FileName), 'Calls','-v7','-append');
                    else
                        save(fullfile(PathName, FileName), 'Calls','allAudio','detection_metadata','spect','-v7','-mat');
                    end
                end
            end
            
            % Delete Save dialog
            delete(app)
        end

        % Button pushed function: buttonNext
        function buttonNext_Callback(app, event)
            app.indSt = min(height(app.Calls)-app.indNumDisp+1,app.indSt+app.indNumDisp);
            app.RevPlotNew();
        end

        % Button pushed function: buttonPrev
        function buttonPrev_Callback(app, event)
            app.indSt = max(1,app.indSt-app.indNumDisp);
            app.RevPlotNew();
        end

        % Value changed function: editfieldCallIndex
        function editfieldCallIndex_Callback(app, event)
            % Go to new call index
            app.indSt = app.editfieldCallIndex.Value;
            app.RevPlotNew();
        end

        % Value changed function: dropdownCallType
        function dropdownCallType_Callback(app, event)
             newcalltype = app.dropdownCallType.Value;
             if strcmp(newcalltype,'Add New Call Type')
                prompt = {'Enter call type:'};
                definput = {''};
                dlg_title = 'Set Custom Label';
                num_lines=[1,60]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='none';
                new_label = inputdlg(prompt,dlg_title,num_lines,definput,options);
                newcalltype = new_label{1};
             end
             app.Calls.Type(app.indSel) = categorical(cellstr(newcalltype));
             app.RevPlotRefresh();
        end

        % Button pushed function: buttonReject
        function buttonReject_Callback(app, event)
            newcalltype = 'Noise';
            if isempty(app.indSel)
                %app.Calls.Type(app.indSt:app.indEnd) = categorical(cellstr(newcalltype));
                msgbox('No calls selected')
            else
                app.Calls.Type(app.indSel) = categorical(cellstr(newcalltype));
            end
            app.RevPlotRefresh();
        end

        % Value changed function: editfieldNum2Disp
        function editfieldNum2Disp_Callback(app, event)
            app.indNumDisp = app.editfieldNum2Disp.Value;
            app.RevPlotNew();
        end

        % Value changed function: dropdownConvertFrom
        function dropdownConvertFrom_Callback(app, event)
            app.strConvFrom = app.dropdownConvertFrom.Value;
            if ~strcmp(app.strConvFrom,'Select...')
                app.dropdownConvertTo.Enable = "on";
            else
                app.dropdownConvertTo.Enable = "off";
                app.buttonConvertApply.Enable = "off";
            end
        end

        % Value changed function: dropdownConvertTo
        function dropdownConvertTo_Callback(app, event)
            app.strConvTo = app.dropdownConvertTo.Value;
            if ~strcmp(app.strConvTo,'Select...')
                if strcmp(app.strConvTo,'Add New Call Type')
                    prompt = {'Enter call type:'};
                    definput = {''};
                    dlg_title = 'Set Custom Label';
                    num_lines=[1,60]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='none';
                    new_label = inputdlg(prompt,dlg_title,num_lines,definput,options);
                    app.strConvTo = new_label{1};
                    app.dropdownConvertTo.Items = ['Select...'; cellstr(unique(app.Calls.Type)); app.strConvTo; 'Add New Call Type'];
                    app.dropdownConvertTo.Value = app.strConvTo;
                end
                app.buttonConvertApply.Enable = "on";
            else
                app.buttonConvertApply.Enable = "off";
            end
        end

        % Button pushed function: buttonConvertApply
        function buttonConvertApply_Callback(app, event)
            app.indSel = find(app.Calls.Type==app.strConvFrom);
            app.Calls.Type(app.indSel) = categorical(cellstr(app.strConvTo));
            app.buttonConvertApply.Enable = "off";
            app.dropdownConvertTo.Enable = "off";
            app.RevPlotRefresh();
        end

        % Value changed function: editfieldnTimePad
        function editfieldnTimePad_Callback(app, event)
            app.nTimePad = app.editfieldnTimePad.Value;
            app.RevPlotNew();
        end

        % Value changed function: editfieldnFreqPad
        function editfieldnFreqPad_Callback(app, event)
            app.nFreqPad = app.editfieldnFreqPad.Value/1000;
            app.RevPlotNew();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create dlgCallReview and hide until all components are created
            app.dlgCallReview = uifigure('Visible', 'off');
            app.dlgCallReview.Position = [100 100 696 726];
            app.dlgCallReview.Name = 'Call Review Dialog';
            app.dlgCallReview.CloseRequestFcn = createCallbackFcn(app, @dlgCallReviewCloseRequest, true);
            app.dlgCallReview.WindowStyle = 'modal';

            % Create panelTop
            app.panelTop = uipanel(app.dlgCallReview);
            app.panelTop.AutoResizeChildren = 'off';
            app.panelTop.BorderColor = [0.9412 0.9412 0.9412];
            app.panelTop.HighlightColor = [0.9412 0.9412 0.9412];
            app.panelTop.Position = [35 593 617 109];

            % Create editfieldnFreqPad
            app.editfieldnFreqPad = uieditfield(app.panelTop, 'numeric');
            app.editfieldnFreqPad.Limits = [0 Inf];
            app.editfieldnFreqPad.ValueDisplayFormat = '%d';
            app.editfieldnFreqPad.ValueChangedFcn = createCallbackFcn(app, @editfieldnFreqPad_Callback, true);
            app.editfieldnFreqPad.Position = [552 11 62 22];

            % Create editfieldnTimePad
            app.editfieldnTimePad = uieditfield(app.panelTop, 'numeric');
            app.editfieldnTimePad.Limits = [0 Inf];
            app.editfieldnTimePad.ValueDisplayFormat = '%.3f';
            app.editfieldnTimePad.ValueChangedFcn = createCallbackFcn(app, @editfieldnTimePad_Callback, true);
            app.editfieldnTimePad.Position = [395 11 62 22];
            app.editfieldnTimePad.Value = 0.5;

            % Create editfieldNum2Disp
            app.editfieldNum2Disp = uieditfield(app.panelTop, 'numeric');
            app.editfieldNum2Disp.Limits = [0 Inf];
            app.editfieldNum2Disp.ValueDisplayFormat = '%d';
            app.editfieldNum2Disp.ValueChangedFcn = createCallbackFcn(app, @editfieldNum2Disp_Callback, true);
            app.editfieldNum2Disp.Position = [552 40 62 22];

            % Create ofCallstoDisplayLabel
            app.ofCallstoDisplayLabel = uilabel(app.panelTop);
            app.ofCallstoDisplayLabel.HorizontalAlignment = 'right';
            app.ofCallstoDisplayLabel.Position = [429 40 114 22];
            app.ofCallstoDisplayLabel.Text = '# of Calls to Display:';

            % Create CallLabel
            app.CallLabel = uilabel(app.panelTop);
            app.CallLabel.HorizontalAlignment = 'right';
            app.CallLabel.Position = [8 40 39 22];
            app.CallLabel.Text = 'Call #:';

            % Create labelTotalCalls
            app.labelTotalCalls = uilabel(app.panelTop);
            app.labelTotalCalls.Position = [108 40 121 22];
            app.labelTotalCalls.Text = '/ ? Total Calls';

            % Create editfieldCallIndex
            app.editfieldCallIndex = uieditfield(app.panelTop, 'numeric');
            app.editfieldCallIndex.Limits = [0 Inf];
            app.editfieldCallIndex.ValueDisplayFormat = '%d';
            app.editfieldCallIndex.ValueChangedFcn = createCallbackFcn(app, @editfieldCallIndex_Callback, true);
            app.editfieldCallIndex.Position = [55 40 46 22];

            % Create buttonConvertApply
            app.buttonConvertApply = uibutton(app.panelTop, 'push');
            app.buttonConvertApply.ButtonPushedFcn = createCallbackFcn(app, @buttonConvertApply_Callback, true);
            app.buttonConvertApply.Enable = 'off';
            app.buttonConvertApply.Position = [561 73 53 23];
            app.buttonConvertApply.Text = 'Apply';

            % Create dropdownConvertTo
            app.dropdownConvertTo = uidropdown(app.panelTop);
            app.dropdownConvertTo.Items = {'Select...'};
            app.dropdownConvertTo.ValueChangedFcn = createCallbackFcn(app, @dropdownConvertTo_Callback, true);
            app.dropdownConvertTo.Enable = 'off';
            app.dropdownConvertTo.Position = [459 73 95 22];
            app.dropdownConvertTo.Value = 'Select...';

            % Create dropdownConvertFrom
            app.dropdownConvertFrom = uidropdown(app.panelTop);
            app.dropdownConvertFrom.Items = {'Select...'};
            app.dropdownConvertFrom.ValueChangedFcn = createCallbackFcn(app, @dropdownConvertFrom_Callback, true);
            app.dropdownConvertFrom.Position = [341 73 95 22];
            app.dropdownConvertFrom.Value = 'Select...';

            % Create AssignCallTypeLabel
            app.AssignCallTypeLabel = uilabel(app.panelTop);
            app.AssignCallTypeLabel.HorizontalAlignment = 'right';
            app.AssignCallTypeLabel.Position = [8 73 110 22];
            app.AssignCallTypeLabel.Text = 'Assign to Selection:';

            % Create dropdownCallType
            app.dropdownCallType = uidropdown(app.panelTop);
            app.dropdownCallType.Items = {'Call'};
            app.dropdownCallType.ValueChangedFcn = createCallbackFcn(app, @dropdownCallType_Callback, true);
            app.dropdownCallType.Enable = 'off';
            app.dropdownCallType.Position = [122 73 138 22];
            app.dropdownCallType.Value = 'Call';

            % Create ToLabel
            app.ToLabel = uilabel(app.panelTop);
            app.ToLabel.HorizontalAlignment = 'right';
            app.ToLabel.Position = [441 73 16 22];
            app.ToLabel.Text = 'To:';

            % Create ConvertAllLabel
            app.ConvertAllLabel = uilabel(app.panelTop);
            app.ConvertAllLabel.HorizontalAlignment = 'right';
            app.ConvertAllLabel.Position = [271 73 66 22];
            app.ConvertAllLabel.Text = 'Convert All:';

            % Create ofCallstoDisplayLabel_2
            app.ofCallstoDisplayLabel_2 = uilabel(app.panelTop);
            app.ofCallstoDisplayLabel_2.HorizontalAlignment = 'right';
            app.ofCallstoDisplayLabel_2.Position = [459 11 84 22];
            app.ofCallstoDisplayLabel_2.Text = 'Freq Pad (Hz):';

            % Create ofCallstoDisplayLabel_3
            app.ofCallstoDisplayLabel_3 = uilabel(app.panelTop);
            app.ofCallstoDisplayLabel_3.HorizontalAlignment = 'right';
            app.ofCallstoDisplayLabel_3.Position = [297 11 89 22];
            app.ofCallstoDisplayLabel_3.Text = 'Time Pad (sec):';

            % Create panelButtons
            app.panelButtons = uipanel(app.dlgCallReview);
            app.panelButtons.AutoResizeChildren = 'off';
            app.panelButtons.BorderColor = [0.9412 0.9412 0.9412];
            app.panelButtons.HighlightColor = [0.9412 0.9412 0.9412];
            app.panelButtons.Position = [35 8 628 131];

            % Create buttonSaveClose
            app.buttonSaveClose = uibutton(app.panelButtons, 'push');
            app.buttonSaveClose.ButtonPushedFcn = createCallbackFcn(app, @buttonSaveClose_Callback, true);
            app.buttonSaveClose.Position = [232 23 138 42];
            app.buttonSaveClose.Text = 'Save & Close';

            % Create buttonReject
            app.buttonReject = uibutton(app.panelButtons, 'push');
            app.buttonReject.ButtonPushedFcn = createCallbackFcn(app, @buttonReject_Callback, true);
            app.buttonReject.Position = [247 88 109 23];
            app.buttonReject.Text = 'Reject';

            % Create buttonPrev
            app.buttonPrev = uibutton(app.panelButtons, 'push');
            app.buttonPrev.ButtonPushedFcn = createCallbackFcn(app, @buttonPrev_Callback, true);
            app.buttonPrev.Position = [13 78 109 42];
            app.buttonPrev.Text = 'Prev';

            % Create buttonNext
            app.buttonNext = uibutton(app.panelButtons, 'push');
            app.buttonNext.ButtonPushedFcn = createCallbackFcn(app, @buttonNext_Callback, true);
            app.buttonNext.Position = [505 78 109 42];
            app.buttonNext.Text = 'Next';

            % Create panelImgs
            app.panelImgs = uipanel(app.dlgCallReview);
            app.panelImgs.Position = [48 147 601 434];

            % Show the figure after all components are created
            app.dlgCallReview.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CallReviewDlg_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.dlgCallReview)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.dlgCallReview)
        end
    end
end