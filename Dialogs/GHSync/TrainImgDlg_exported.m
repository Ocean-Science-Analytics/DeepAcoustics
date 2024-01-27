classdef TrainImgDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgDisplay            matlab.ui.Figure
        AnnotationMetadataforSelectedTrainingDataLabel  matlab.ui.control.Label
        labelTitle            matlab.ui.control.Label
        labelMinDurs          matlab.ui.control.Label
        labelMaxDurs          matlab.ui.control.Label
        labelMinFreq          matlab.ui.control.Label
        labelMaxFreq          matlab.ui.control.Label
        labelMinSR            matlab.ui.control.Label
        labelMaxSR            matlab.ui.control.Label
        buttonCancel          matlab.ui.control.Button
        buttonOK              matlab.ui.control.Button
        editNFFT              matlab.ui.control.NumericEditField
        labelNFFT             matlab.ui.control.Label
        editOverlap           matlab.ui.control.NumericEditField
        labelOverlap          matlab.ui.control.Label
        editWinSize           matlab.ui.control.NumericEditField
        labelWinSize          matlab.ui.control.Label
        editImgLength         matlab.ui.control.NumericEditField
        editNumAugDup         matlab.ui.control.NumericEditField
        labelFreqUppLim       matlab.ui.control.Label
        labelFreqLowLim       matlab.ui.control.Label
        buttongroupSpecUnits  matlab.ui.container.ButtonGroup
        buttonSeconds         matlab.ui.control.RadioButton
        buttonSamples         matlab.ui.control.RadioButton
    end

    
    properties (Access = private)
        MainApp % Main DA GUI
        HandlesSpect % Default spect settings from handles
        Metadata % Metadata from incoming det files
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, parentapp, spect, metadata)
            app.MainApp = parentapp;
            app.HandlesSpect = spect;

            % Initialize default values
            app.editImgLength.Value = 1;
            app.editNumAugDup.Value = 0;

            app.editWinSize.Value = app.HandlesSpect.windowsizesmp;
            app.editOverlap.Value = 100 * app.HandlesSpect.noverlap ./ app.HandlesSpect.windowsize;
            app.editNFFT.Value = app.HandlesSpect.nfftsmp;

            app.labelMinDurs.Text = [app.labelMinDurs.Text ' ' num2str(metadata.mindur,'%.1f')];
            app.labelMaxDurs.Text = [app.labelMaxDurs.Text ' ' num2str(metadata.maxdur,'%.1f')];
            app.labelMinFreq.Text = [app.labelMinFreq.Text ' ' num2str(metadata.minfreq*1000,'%d')];
            app.labelMaxFreq.Text = [app.labelMaxFreq.Text ' ' num2str(metadata.maxfreq*1000,'%d')];
            app.labelMinSR.Text = [app.labelMinSR.Text ' ' num2str(metadata.minSR,'%.0f')];
            app.labelMaxSR.Text = [app.labelMaxSR.Text ' ' num2str(metadata.maxSR,'%.0f')];
        end

        % Callback function: buttonCancel, dlgDisplay
        function appCloseRequestFcn_Callback(app, event)
            % Delete Train Img Settings app
            delete(app)
        end

        % Selection changed function: buttongroupSpecUnits
        function buttongroupSpecUnits_Callback(app, event)
            selectedButton = app.buttongroupSpecUnits.SelectedObject;
            switch selectedButton.Text
                case 'Samples'
                    app.labelWinSize.Text = 'Window Size (# of samples):';
                    app.labelNFFT.Text = 'NFFT (# of samples):';
                    app.editWinSize.Value = app.HandlesSpect.windowsizesmp;
                    app.editWinSize.ValueDisplayFormat = '%.0f';
                    app.editNFFT.Value = app.HandlesSpect.nfftsmp;
                    app.editNFFT.ValueDisplayFormat = '%.0f';
                case 'Seconds'
                    app.labelWinSize.Text = 'Window Size (seconds):';
                    app.labelNFFT.Text = 'NFFT (seconds):';
                    app.editWinSize.Value = app.HandlesSpect.windowsize;
                    app.editWinSize.ValueDisplayFormat = '%11.4g';
                    app.editNFFT.Value = app.HandlesSpect.nfft;
                    app.editNFFT.ValueDisplayFormat = '%11.4g';
            end
        end

        % Button pushed function: buttonOK
        function buttonOK_Callback(app, event)
            %% Validate the new values and save them            
            if app.editOverlap.Value >= 95
                errordlg('Spectrogram overlap must be less than 95%')
                return
            end
            
            switch app.buttongroupSpecUnits.SelectedObject.Text
                case 'Samples'
                    app.MainApp.TrainImgSettings.windowsize = 0;
                    app.MainApp.TrainImgSettings.nfft = 0;
                    app.MainApp.TrainImgSettings.windowsizesmp = app.editWinSize.Value;
                    app.MainApp.TrainImgSettings.nfftsmp = app.editNFFT.Value;
                case 'Seconds'
                    app.MainApp.TrainImgSettings.windowsize = app.editWinSize.Value;
                    app.MainApp.TrainImgSettings.nfft = app.editNFFT.Value;
                    app.MainApp.TrainImgSettings.windowsizesmp = 0;
                    app.MainApp.TrainImgSettings.nfftsmp = 0;
            end
            app.MainApp.TrainImgSettings.noverlap = app.editOverlap.Value * app.editWinSize.Value / 100;
            app.MainApp.TrainImgSettings.imLength = app.editImgLength.Value;
            app.MainApp.TrainImgSettings.repeats = app.editNumAugDup.Value;

            appCloseRequestFcn_Callback(app,event)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create dlgDisplay and hide until all components are created
            app.dlgDisplay = uifigure('Visible', 'off');
            app.dlgDisplay.Position = [360 500 395 450];
            app.dlgDisplay.Name = 'Display Settings';
            app.dlgDisplay.CloseRequestFcn = createCallbackFcn(app, @appCloseRequestFcn_Callback, true);

            % Create buttongroupSpecUnits
            app.buttongroupSpecUnits = uibuttongroup(app.dlgDisplay);
            app.buttongroupSpecUnits.SelectionChangedFcn = createCallbackFcn(app, @buttongroupSpecUnits_Callback, true);
            app.buttongroupSpecUnits.TitlePosition = 'centertop';
            app.buttongroupSpecUnits.Title = 'Units of Spectrogram Parameters';
            app.buttongroupSpecUnits.Position = [60 234 278 71];

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
            app.labelFreqLowLim.Position = [66 101 169 22];
            app.labelFreqLowLim.Text = 'Image Length (s):';

            % Create labelFreqUppLim
            app.labelFreqUppLim = uilabel(app.dlgDisplay);
            app.labelFreqUppLim.HorizontalAlignment = 'right';
            app.labelFreqUppLim.Position = [50 68 185 22];
            app.labelFreqUppLim.Text = 'Number of augmented duplicates:';

            % Create editNumAugDup
            app.editNumAugDup = uieditfield(app.dlgDisplay, 'numeric');
            app.editNumAugDup.HorizontalAlignment = 'center';
            app.editNumAugDup.Position = [244 68 70 22];

            % Create editImgLength
            app.editImgLength = uieditfield(app.dlgDisplay, 'numeric');
            app.editImgLength.HorizontalAlignment = 'center';
            app.editImgLength.Position = [244 100 70 22];

            % Create labelWinSize
            app.labelWinSize = uilabel(app.dlgDisplay);
            app.labelWinSize.Tag = 'labelWinSize';
            app.labelWinSize.HorizontalAlignment = 'right';
            app.labelWinSize.Position = [78 202 158 22];
            app.labelWinSize.Text = 'Window Size (# of samples):';

            % Create editWinSize
            app.editWinSize = uieditfield(app.dlgDisplay, 'numeric');
            app.editWinSize.Limits = [0 Inf];
            app.editWinSize.ValueDisplayFormat = '%.0f';
            app.editWinSize.HorizontalAlignment = 'center';
            app.editWinSize.Position = [245 202 69 22];

            % Create labelOverlap
            app.labelOverlap = uilabel(app.dlgDisplay);
            app.labelOverlap.HorizontalAlignment = 'right';
            app.labelOverlap.Position = [162 170 73 22];
            app.labelOverlap.Text = 'Overlap (%):';

            % Create editOverlap
            app.editOverlap = uieditfield(app.dlgDisplay, 'numeric');
            app.editOverlap.Limits = [0 100];
            app.editOverlap.HorizontalAlignment = 'center';
            app.editOverlap.Position = [245 168 69 22];

            % Create labelNFFT
            app.labelNFFT = uilabel(app.dlgDisplay);
            app.labelNFFT.HorizontalAlignment = 'right';
            app.labelNFFT.Position = [115 136 119 22];
            app.labelNFFT.Text = 'NFFT (# of samples):';

            % Create editNFFT
            app.editNFFT = uieditfield(app.dlgDisplay, 'numeric');
            app.editNFFT.Limits = [0 Inf];
            app.editNFFT.ValueDisplayFormat = '%.0f';
            app.editNFFT.HorizontalAlignment = 'center';
            app.editNFFT.Position = [245 133 69 22];

            % Create buttonOK
            app.buttonOK = uibutton(app.dlgDisplay, 'push');
            app.buttonOK.ButtonPushedFcn = createCallbackFcn(app, @buttonOK_Callback, true);
            app.buttonOK.Position = [80 24 100 34];
            app.buttonOK.Text = 'OK';

            % Create buttonCancel
            app.buttonCancel = uibutton(app.dlgDisplay, 'push');
            app.buttonCancel.ButtonPushedFcn = createCallbackFcn(app, @appCloseRequestFcn_Callback, true);
            app.buttonCancel.Position = [211 24 100 34];
            app.buttonCancel.Text = 'Cancel';

            % Create labelMaxSR
            app.labelMaxSR = uilabel(app.dlgDisplay);
            app.labelMaxSR.Position = [264 315 124 22];
            app.labelMaxSR.Text = 'Max SR (Hz):';

            % Create labelMinSR
            app.labelMinSR = uilabel(app.dlgDisplay);
            app.labelMinSR.Position = [264 347 124 22];
            app.labelMinSR.Text = 'Min SR (Hz):';

            % Create labelMaxFreq
            app.labelMaxFreq = uilabel(app.dlgDisplay);
            app.labelMaxFreq.Position = [133 315 123 22];
            app.labelMaxFreq.Text = 'Max Freq (Hz):';

            % Create labelMinFreq
            app.labelMinFreq = uilabel(app.dlgDisplay);
            app.labelMinFreq.Position = [133 347 123 22];
            app.labelMinFreq.Text = 'Min Freq (Hz):';

            % Create labelMaxDurs
            app.labelMaxDurs = uilabel(app.dlgDisplay);
            app.labelMaxDurs.Position = [15 315 107 22];
            app.labelMaxDurs.Text = 'Max Dur (s):';

            % Create labelMinDurs
            app.labelMinDurs = uilabel(app.dlgDisplay);
            app.labelMinDurs.Position = [15 347 107 22];
            app.labelMinDurs.Text = 'Min Dur (s):';

            % Create labelTitle
            app.labelTitle = uilabel(app.dlgDisplay);
            app.labelTitle.HorizontalAlignment = 'center';
            app.labelTitle.FontSize = 14;
            app.labelTitle.FontWeight = 'bold';
            app.labelTitle.Position = [99 413 194 22];
            app.labelTitle.Text = 'Settings for Training Images';

            % Create AnnotationMetadataforSelectedTrainingDataLabel
            app.AnnotationMetadataforSelectedTrainingDataLabel = uilabel(app.dlgDisplay);
            app.AnnotationMetadataforSelectedTrainingDataLabel.HorizontalAlignment = 'center';
            app.AnnotationMetadataforSelectedTrainingDataLabel.Position = [64 380 264 22];
            app.AnnotationMetadataforSelectedTrainingDataLabel.Text = 'Annotation Metadata for Selected Training Data:';

            % Show the figure after all components are created
            app.dlgDisplay.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = TrainImgDlg_exported(varargin)

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