classdef DisplayDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgDisplay                     matlab.ui.Figure
        buttonCancel                   matlab.ui.control.Button
        buttonOK                       matlab.ui.control.Button
        buttonAutoWinSize              matlab.ui.control.Button
        editNFFT                       matlab.ui.control.NumericEditField
        labelNFFT                      matlab.ui.control.Label
        editOverlap                    matlab.ui.control.NumericEditField
        labelOverlap                   matlab.ui.control.Label
        editWinSize                    matlab.ui.control.NumericEditField
        labelWinSize                   matlab.ui.control.Label
        editFreqUppLim                 matlab.ui.control.NumericEditField
        labelFreqUppLim                matlab.ui.control.Label
        editFreqLowLim                 matlab.ui.control.NumericEditField
        labelFreqLowLim                matlab.ui.control.Label
        buttongroupSpecUnits           matlab.ui.container.ButtonGroup
        buttonSeconds                  matlab.ui.control.RadioButton
        buttonSamples                  matlab.ui.control.RadioButton
        dropdownSpecCUnits             matlab.ui.control.DropDown
        SpectrogramUnitsDropDownLabel  matlab.ui.control.Label
    end

    
    properties (Access = private)
        MainApp % Main DA GUI
        Event % Event var from main DA GUI (for interfacing with old GUIDE methods)
        Handles % Deprecated GUIDE handles from main DA GUI
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, parentapp, event, handles)
            app.MainApp = parentapp;
            app.Event = event;
            app.Handles = handles;

            % Initialize default values
            app.editFreqLowLim.Value = app.Handles.data.settings.LowFreq;
            app.editFreqUppLim.Value = app.Handles.data.settings.HighFreq;
            if find(strcmp(app.dropdownSpecCUnits.Items,app.Handles.data.settings.spect.type))
                app.dropdownSpecCUnits.Value = app.Handles.data.settings.spect.type;
            else
                error('Something wrong with spect.type in settings.mat')
            end
            app.editWinSize.Value = app.Handles.data.settings.spect.windowsizesmp;
            app.editOverlap.Value = 100 * app.Handles.data.settings.spect.noverlap ./ app.Handles.data.settings.spect.windowsize;
            app.editNFFT.Value = app.Handles.data.settings.spect.nfftsmp;
        end

        % Callback function: buttonCancel, dlgDisplay
        function appCloseRequestFcn_Callback(app, event)
            % Re-enable the Display Settings button in main app
            app.MainApp.buttonDisplaySettings.Enable = 'on';
            
            % Delete Dialog Settings app
            delete(app)
        end

        % Selection changed function: buttongroupSpecUnits
        function buttongroupSpecUnits_Callback(app, event)
            selectedButton = app.buttongroupSpecUnits.SelectedObject;
            switch selectedButton.Text
                case 'Samples'
                    app.labelWinSize.Text = 'Window Size (# of samples):';
                    app.labelNFFT.Text = 'NFFT (# of samples):';
                    app.editWinSize.Value = app.Handles.data.settings.spect.windowsizesmp;
                    app.editWinSize.ValueDisplayFormat = '%.0f';
                    app.editNFFT.Value = app.Handles.data.settings.spect.nfftsmp;
                    app.editNFFT.ValueDisplayFormat = '%.0f';
                case 'Seconds'
                    app.labelWinSize.Text = 'Window Size (seconds):';
                    app.labelNFFT.Text = 'NFFT (seconds):';
                    app.editWinSize.Value = app.Handles.data.settings.spect.windowsize;
                    app.editWinSize.ValueDisplayFormat = '%11.4g';
                    app.editNFFT.Value = app.Handles.data.settings.spect.nfft;
                    app.editNFFT.ValueDisplayFormat = '%11.4g';
            end
        end

        % Button pushed function: buttonAutoWinSize
        function buttonAutoWinSize_Callback(app, event)
            if isempty(app.Handles.data.audiodata)
                warning('Audio not loaded yet - need to know sample rate')
            else
                % Optimize the window size so that the pixels are square
                yRange(1) = app.editFreqLowLim.Value;
                yRange(2) = app.editFreqUppLim.Value;
                yRange(2) = min(yRange(2), app.Handles.data.audiodata.SampleRate / 2000);
                yRange = yRange(2) - yRange(1);
                xRange = app.Handles.focusWindow.XLim(2) - app.Handles.focusWindow.XLim(1);
                noverlap = app.editOverlap.Value / 100;
                optimalWindow = sqrt(xRange/(2000*yRange));
                optimalWindow = optimalWindow + optimalWindow.*noverlap;
                switch app.buttongroupSpecUnits.SelectedObject.Text
                    case 'Samples'
                        app.editWinSize.Value = optimalWindow*app.Handles.data.audiodata.SampleRate;
                        app.editNFFT.Value = optimalWindow*app.Handles.data.audiodata.SampleRate;
                    case 'Seconds'
                        app.editWinSize.Value = optimalWindow;
                        app.editNFFT.Value = optimalWindow;
                end
            end
        end

        % Button pushed function: buttonOK
        function buttonOK_Callback(app, event)
            %% Validate the new values and save them
            % Extract numbers from the numeric fields and return if any values
            % aren't valid
%             newValues = struct();
%             for numericFields = {'LowFreq', 'HighFreq', 'windowsize', 'noverlap', 'nfft'}
%                 newValues.(numericFields{:}) =  sscanf(ui.(numericFields{:}).String,'%f', 1);
%                 if isempty(newValues.(numericFields{:}))
%                     errordlg(['Invalid value for ' prompt.(numericFields{:})])
%                     return
%                 end
%             end
            
            % Make sure that the low frequency cutoff is less than high cutoff
            if app.editFreqLowLim.Value >= app.editFreqUppLim.Value
                errordlg('High frequency cutoff must be greater than low frequency cutoff!')
                return
            end
            
            if app.editOverlap.Value >= 95
                errordlg('Spectrogram overlap must be less than 95%')
                return
            end
            
            switch app.buttongroupSpecUnits.SelectedObject.Text
                case 'Samples'
                    app.Handles.data.settings.spect.windowsize = 0;
                    app.Handles.data.settings.spect.nfft = 0;
                    app.Handles.data.settings.spect.windowsizesmp = app.editWinSize.Value;
                    app.Handles.data.settings.spect.nfftsmp = app.editNFFT.Value;
                case 'Seconds'
                    app.Handles.data.settings.spect.windowsize = app.editWinSize.Value;
                    app.Handles.data.settings.spect.nfft = app.editNFFT.Value;
                    app.Handles.data.settings.spect.windowsizesmp = 0;
                    app.Handles.data.settings.spect.nfftsmp = 0;
            end
            app.Handles.data.settings.LowFreq = app.editFreqLowLim.Value;
            app.Handles.data.settings.HighFreq = app.editFreqUppLim.Value;
            app.Handles.data.settings.spect.type = app.dropdownSpecCUnits.Value;
            app.Handles.data.settings.spect.noverlap = app.editOverlap.Value * app.editWinSize.Value / 100;
            
            UpdateDisplaySettings(app.MainApp, app.Event, app.Handles)

            appCloseRequestFcn_Callback(app,event)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create dlgDisplay and hide until all components are created
            app.dlgDisplay = uifigure('Visible', 'off');
            app.dlgDisplay.Position = [360 500 350 500];
            app.dlgDisplay.Name = 'Display Settings';
            app.dlgDisplay.CloseRequestFcn = createCallbackFcn(app, @appCloseRequestFcn_Callback, true);

            % Create SpectrogramUnitsDropDownLabel
            app.SpectrogramUnitsDropDownLabel = uilabel(app.dlgDisplay);
            app.SpectrogramUnitsDropDownLabel.HorizontalAlignment = 'right';
            app.SpectrogramUnitsDropDownLabel.Position = [39 354 108 22];
            app.SpectrogramUnitsDropDownLabel.Text = 'Spectrogram Units:';

            % Create dropdownSpecCUnits
            app.dropdownSpecCUnits = uidropdown(app.dlgDisplay);
            app.dropdownSpecCUnits.Items = {'Amplitude', 'Power Spectral Density'};
            app.dropdownSpecCUnits.Position = [162 354 155 22];
            app.dropdownSpecCUnits.Value = 'Amplitude';

            % Create buttongroupSpecUnits
            app.buttongroupSpecUnits = uibuttongroup(app.dlgDisplay);
            app.buttongroupSpecUnits.SelectionChangedFcn = createCallbackFcn(app, @buttongroupSpecUnits_Callback, true);
            app.buttongroupSpecUnits.TitlePosition = 'centertop';
            app.buttongroupSpecUnits.Title = 'Units of Spectrogram Parameters';
            app.buttongroupSpecUnits.Position = [39 261 278 71];

            % Create buttonSamples
            app.buttonSamples = uiradiobutton(app.buttongroupSpecUnits);
            app.buttonSamples.Text = 'Samples';
            app.buttonSamples.Position = [105 26 69 22];
            app.buttonSamples.Value = true;

            % Create buttonSeconds
            app.buttonSeconds = uiradiobutton(app.buttongroupSpecUnits);
            app.buttonSeconds.Text = 'Seconds';
            app.buttonSeconds.Position = [105 4 69 22];

            % Create labelFreqLowLim
            app.labelFreqLowLim = uilabel(app.dlgDisplay);
            app.labelFreqLowLim.HorizontalAlignment = 'right';
            app.labelFreqLowLim.Position = [53 444 169 22];
            app.labelFreqLowLim.Text = 'Frequency Lower Limit (kHz):';

            % Create editFreqLowLim
            app.editFreqLowLim = uieditfield(app.dlgDisplay, 'numeric');
            app.editFreqLowLim.Position = [231 444 70 22];

            % Create labelFreqUppLim
            app.labelFreqUppLim = uilabel(app.dlgDisplay);
            app.labelFreqUppLim.HorizontalAlignment = 'right';
            app.labelFreqUppLim.Position = [53 410 169 22];
            app.labelFreqUppLim.Text = 'Frequency Upper Limit (kHz):';

            % Create editFreqUppLim
            app.editFreqUppLim = uieditfield(app.dlgDisplay, 'numeric');
            app.editFreqUppLim.Position = [231 410 70 22];

            % Create labelWinSize
            app.labelWinSize = uilabel(app.dlgDisplay);
            app.labelWinSize.Tag = 'labelWinSize';
            app.labelWinSize.HorizontalAlignment = 'right';
            app.labelWinSize.Position = [58 217 158 22];
            app.labelWinSize.Text = 'Window Size (# of samples):';

            % Create editWinSize
            app.editWinSize = uieditfield(app.dlgDisplay, 'numeric');
            app.editWinSize.ValueDisplayFormat = '%.0f';
            app.editWinSize.HorizontalAlignment = 'center';
            app.editWinSize.Position = [225 217 69 22];

            % Create labelOverlap
            app.labelOverlap = uilabel(app.dlgDisplay);
            app.labelOverlap.HorizontalAlignment = 'right';
            app.labelOverlap.Position = [142 167 73 22];
            app.labelOverlap.Text = 'Overlap (%):';

            % Create editOverlap
            app.editOverlap = uieditfield(app.dlgDisplay, 'numeric');
            app.editOverlap.HorizontalAlignment = 'center';
            app.editOverlap.Position = [225 167 69 22];

            % Create labelNFFT
            app.labelNFFT = uilabel(app.dlgDisplay);
            app.labelNFFT.HorizontalAlignment = 'right';
            app.labelNFFT.Position = [95 118 119 22];
            app.labelNFFT.Text = 'NFFT (# of samples):';

            % Create editNFFT
            app.editNFFT = uieditfield(app.dlgDisplay, 'numeric');
            app.editNFFT.ValueDisplayFormat = '%.0f';
            app.editNFFT.HorizontalAlignment = 'center';
            app.editNFFT.Position = [225 118 69 22];

            % Create buttonAutoWinSize
            app.buttonAutoWinSize = uibutton(app.dlgDisplay, 'push');
            app.buttonAutoWinSize.ButtonPushedFcn = createCallbackFcn(app, @buttonAutoWinSize_Callback, true);
            app.buttonAutoWinSize.Position = [20 162 113 33];
            app.buttonAutoWinSize.Text = 'Auto Window Size';

            % Create buttonOK
            app.buttonOK = uibutton(app.dlgDisplay, 'push');
            app.buttonOK.ButtonPushedFcn = createCallbackFcn(app, @buttonOK_Callback, true);
            app.buttonOK.Position = [61 35 100 34];
            app.buttonOK.Text = 'OK';

            % Create buttonCancel
            app.buttonCancel = uibutton(app.dlgDisplay, 'push');
            app.buttonCancel.ButtonPushedFcn = createCallbackFcn(app, @appCloseRequestFcn_Callback, true);
            app.buttonCancel.Position = [192 35 100 34];
            app.buttonCancel.Text = 'Cancel';

            % Show the figure after all components are created
            app.dlgDisplay.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = DisplayDlg_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.dlgDisplay)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.dlgDisplay)
        end
    end
end