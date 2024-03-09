classdef TrainImgDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgTrainImg           matlab.ui.Figure
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
            app.MainApp.TrainImgbCancel = false;

            % Initialize default values
            app.editImgLength.Value = 1;
            app.editNumAugDup.Value = 0;

            app.editWinSize.Value = app.HandlesSpect.windowsizesmp;
            app.editOverlap.Value = 100 * app.HandlesSpect.noverlap ./ app.HandlesSpect.windowsize;
            app.editNFFT.Value = app.HandlesSpect.nfftsmp;

            app.labelMinDurs.Text = [app.labelMinDurs.Text ' ' num2str(metadata.mindur,'%.1f')];
            app.labelMaxDurs.Text = [app.labelMaxDurs.Text ' ' num2str(metadata.maxdur,'%.1f')];
            app.labelMinFreq.Text = [app.labelMinFreq.Text ' ' num2str(round(metadata.minfreq*1000),'%d')];
            app.labelMaxFreq.Text = [app.labelMaxFreq.Text ' ' num2str(round(metadata.maxfreq*1000),'%d')];
            app.labelMinSR.Text = [app.labelMinSR.Text ' ' num2str(metadata.minSR,'%.0f')];
            app.labelMaxSR.Text = [app.labelMaxSR.Text ' ' num2str(metadata.maxSR,'%.0f')];
        end

        % Close request function: dlgTrainImg
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

        % Button pushed function: buttonCancel
        function appCancel_Callback(app, event)
            app.MainApp.TrainImgbCancel = true;
            appCloseRequestFcn_Callback(app,event)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create dlgTrainImg and hide until all components are created
            app.dlgTrainImg = uifigure('Visible', 'off');
            app.dlgTrainImg.Position = [360 500 521 450];
            app.dlgTrainImg.Name = 'Display Settings';
            app.dlgTrainImg.CloseRequestFcn = createCallbackFcn(app, @appCloseRequestFcn_Callback, true);

            % Create buttongroupSpecUnits
            app.buttongroupSpecUnits = uibuttongroup(app.dlgTrainImg);
            app.buttongroupSpecUnits.SelectionChangedFcn = createCallbackFcn(app, @buttongroupSpecUnits_Callback, true);
            app.buttongroupSpecUnits.TitlePosition = 'centertop';
            app.buttongroupSpecUnits.Title = 'Units of Spectrogram Parameters';
            app.buttongroupSpecUnits.Position = [122 234 278 71];

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
            app.labelFreqLowLim = uilabel(app.dlgTrainImg);
            app.labelFreqLowLim.HorizontalAlignment = 'right';
            app.labelFreqLowLim.Position = [145 101 169 22];
            app.labelFreqLowLim.Text = 'Image Length (s):';

            % Create labelFreqUppLim
            app.labelFreqUppLim = uilabel(app.dlgTrainImg);
            app.labelFreqUppLim.HorizontalAlignment = 'right';
            app.labelFreqUppLim.Position = [129 68 185 22];
            app.labelFreqUppLim.Text = 'Number of augmented duplicates:';

            % Create editNumAugDup
            app.editNumAugDup = uieditfield(app.dlgTrainImg, 'numeric');
            app.editNumAugDup.HorizontalAlignment = 'center';
            app.editNumAugDup.Position = [323 68 70 22];

            % Create editImgLength
            app.editImgLength = uieditfield(app.dlgTrainImg, 'numeric');
            app.editImgLength.HorizontalAlignment = 'center';
            app.editImgLength.Position = [323 100 70 22];

            % Create labelWinSize
            app.labelWinSize = uilabel(app.dlgTrainImg);
            app.labelWinSize.Tag = 'labelWinSize';
            app.labelWinSize.HorizontalAlignment = 'right';
            app.labelWinSize.Position = [157 202 158 22];
            app.labelWinSize.Text = 'Window Size (# of samples):';

            % Create editWinSize
            app.editWinSize = uieditfield(app.dlgTrainImg, 'numeric');
            app.editWinSize.Limits = [0 Inf];
            app.editWinSize.ValueDisplayFormat = '%.0f';
            app.editWinSize.HorizontalAlignment = 'center';
            app.editWinSize.Position = [324 202 69 22];

            % Create labelOverlap
            app.labelOverlap = uilabel(app.dlgTrainImg);
            app.labelOverlap.HorizontalAlignment = 'right';
            app.labelOverlap.Position = [241 170 73 22];
            app.labelOverlap.Text = 'Overlap (%):';

            % Create editOverlap
            app.editOverlap = uieditfield(app.dlgTrainImg, 'numeric');
            app.editOverlap.Limits = [0 100];
            app.editOverlap.HorizontalAlignment = 'center';
            app.editOverlap.Position = [324 168 69 22];

            % Create labelNFFT
            app.labelNFFT = uilabel(app.dlgTrainImg);
            app.labelNFFT.HorizontalAlignment = 'right';
            app.labelNFFT.Position = [194 136 119 22];
            app.labelNFFT.Text = 'NFFT (# of samples):';

            % Create editNFFT
            app.editNFFT = uieditfield(app.dlgTrainImg, 'numeric');
            app.editNFFT.Limits = [0 Inf];
            app.editNFFT.ValueDisplayFormat = '%.0f';
            app.editNFFT.HorizontalAlignment = 'center';
            app.editNFFT.Position = [324 133 69 22];

            % Create buttonOK
            app.buttonOK = uibutton(app.dlgTrainImg, 'push');
            app.buttonOK.ButtonPushedFcn = createCallbackFcn(app, @buttonOK_Callback, true);
            app.buttonOK.Position = [146 24 100 34];
            app.buttonOK.Text = 'OK';

            % Create buttonCancel
            app.buttonCancel = uibutton(app.dlgTrainImg, 'push');
            app.buttonCancel.ButtonPushedFcn = createCallbackFcn(app, @appCancel_Callback, true);
            app.buttonCancel.Position = [277 24 100 34];
            app.buttonCancel.Text = 'Cancel';

            % Create labelMaxSR
            app.labelMaxSR = uilabel(app.dlgTrainImg);
            app.labelMaxSR.Position = [343 315 138 22];
            app.labelMaxSR.Text = 'Max SR (Hz):';

            % Create labelMinSR
            app.labelMinSR = uilabel(app.dlgTrainImg);
            app.labelMinSR.Position = [343 347 138 22];
            app.labelMinSR.Text = 'Min SR (Hz):';

            % Create labelMaxFreq
            app.labelMaxFreq = uilabel(app.dlgTrainImg);
            app.labelMaxFreq.Position = [193 315 138 22];
            app.labelMaxFreq.Text = 'Max Freq (Hz):';

            % Create labelMinFreq
            app.labelMinFreq = uilabel(app.dlgTrainImg);
            app.labelMinFreq.Position = [193 347 138 22];
            app.labelMinFreq.Text = 'Min Freq (Hz):';

            % Create labelMaxDurs
            app.labelMaxDurs = uilabel(app.dlgTrainImg);
            app.labelMaxDurs.Position = [54 315 126 22];
            app.labelMaxDurs.Text = 'Max Dur (s):';

            % Create labelMinDurs
            app.labelMinDurs = uilabel(app.dlgTrainImg);
            app.labelMinDurs.Position = [54 347 127 22];
            app.labelMinDurs.Text = 'Min Dur (s):';

            % Create labelTitle
            app.labelTitle = uilabel(app.dlgTrainImg);
            app.labelTitle.HorizontalAlignment = 'center';
            app.labelTitle.FontSize = 14;
            app.labelTitle.FontWeight = 'bold';
            app.labelTitle.Position = [164 413 194 22];
            app.labelTitle.Text = 'Settings for Training Images';

            % Create AnnotationMetadataforSelectedTrainingDataLabel
            app.AnnotationMetadataforSelectedTrainingDataLabel = uilabel(app.dlgTrainImg);
            app.AnnotationMetadataforSelectedTrainingDataLabel.HorizontalAlignment = 'center';
            app.AnnotationMetadataforSelectedTrainingDataLabel.Position = [129 380 264 22];
            app.AnnotationMetadataforSelectedTrainingDataLabel.Text = 'Annotation Metadata for Selected Training Data:';

            % Show the figure after all components are created
            app.dlgTrainImg.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = TrainImgDlg_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.dlgTrainImg)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.dlgTrainImg)
        end
    end
end