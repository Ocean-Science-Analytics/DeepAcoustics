classdef TrainImgDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgTrainImg              matlab.ui.Figure
        ManuallySelectValidationDataLabel  matlab.ui.control.Label
        labelFreqLowLim_2        matlab.ui.control.Label
        labelTitle               matlab.ui.control.Label
        labelAnnotationMetadata  matlab.ui.control.Label
        labelMinDur              matlab.ui.control.Label
        labelMaxDur              matlab.ui.control.Label
        labelMedDur              matlab.ui.control.Label
        labelQuan90Dur           matlab.ui.control.Label
        labelMinFreq             matlab.ui.control.Label
        labelMaxFreq             matlab.ui.control.Label
        labelMinSR               matlab.ui.control.Label
        labelMaxSR               matlab.ui.control.Label
        buttongroupSpecUnits     matlab.ui.container.ButtonGroup
        buttonSeconds            matlab.ui.control.RadioButton
        buttonSamples            matlab.ui.control.RadioButton
        editWinSize              matlab.ui.control.NumericEditField
        editOverlap              matlab.ui.control.NumericEditField
        editNFFT                 matlab.ui.control.NumericEditField
        editImgLength            matlab.ui.control.NumericEditField
        editImgSize              matlab.ui.control.NumericEditField
        editNumAugDup            matlab.ui.control.NumericEditField
        switchRandomNoise        matlab.ui.control.Switch
        switchValData            matlab.ui.control.Switch
        buttonOK                 matlab.ui.control.Button
        buttonCancel             matlab.ui.control.Button
        RandomlyAddNoiseWARNINGWilloverwriteexistingDetsfilesLabel  matlab.ui.control.Label
        labelNFFT                matlab.ui.control.Label
        labelOverlap             matlab.ui.control.Label
        labelWinSize             matlab.ui.control.Label
        labelFreqUppLim          matlab.ui.control.Label
        labelFreqLowLim          matlab.ui.control.Label
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
            movegui(app.dlgTrainImg,'center')
            app.MainApp = parentapp;
            app.HandlesSpect = spect;
            app.MainApp.TrainImgbCancel = false;

            % Initialize default values
            app.editImgLength.Value = round(metadata.quan90dur)*2;
            app.editImgSize.Value = 300;
            app.editNumAugDup.Value = 0;

            app.editWinSize.Value = app.HandlesSpect.windowsizesmp;
            app.editOverlap.Value = 100 * app.HandlesSpect.noverlap ./ app.HandlesSpect.windowsize;
            app.editNFFT.Value = app.HandlesSpect.nfftsmp;

            app.labelMinDur.Text = [app.labelMinDur.Text ' ' num2str(metadata.mindur,'%.1f')];
            app.labelMaxDur.Text = [app.labelMaxDur.Text ' ' num2str(metadata.maxdur,'%.1f')];
            app.labelMedDur.Text = [app.labelMedDur.Text ' ' num2str(metadata.meddur,'%.1f')];
            app.labelQuan90Dur.Text = [app.labelQuan90Dur.Text ' ' num2str(metadata.quan90dur,'%.1f')];
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

            app.MainApp.TrainImgSettings.bValData = strcmp(app.switchValData.Value,'Yes');

            app.MainApp.TrainImgSettings.noverlap = app.editOverlap.Value * app.editWinSize.Value / 100;
            app.MainApp.TrainImgSettings.imLength = app.editImgLength.Value;
            app.MainApp.TrainImgSettings.imSize = app.editImgSize.Value;
            app.MainApp.TrainImgSettings.repeats = app.editNumAugDup.Value;

            app.MainApp.TrainImgSettings.bRandNoise = strcmp(app.switchRandomNoise.Value,'Yes');

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
            app.dlgTrainImg.Position = [360 500 513 605];
            app.dlgTrainImg.Name = 'Display Settings';
            app.dlgTrainImg.CloseRequestFcn = createCallbackFcn(app, @appCloseRequestFcn_Callback, true);

            % Create labelFreqLowLim
            app.labelFreqLowLim = uilabel(app.dlgTrainImg);
            app.labelFreqLowLim.HorizontalAlignment = 'right';
            app.labelFreqLowLim.Position = [238 158 169 22];
            app.labelFreqLowLim.Text = 'Image Length (s):';

            % Create labelFreqUppLim
            app.labelFreqUppLim = uilabel(app.dlgTrainImg);
            app.labelFreqUppLim.HorizontalAlignment = 'right';
            app.labelFreqUppLim.Position = [258 92 149 22];
            app.labelFreqUppLim.Text = '# of augmented duplicates:';

            % Create labelWinSize
            app.labelWinSize = uilabel(app.dlgTrainImg);
            app.labelWinSize.Tag = 'labelWinSize';
            app.labelWinSize.HorizontalAlignment = 'right';
            app.labelWinSize.Position = [250 259 158 22];
            app.labelWinSize.Text = 'Window Size (# of samples):';

            % Create labelOverlap
            app.labelOverlap = uilabel(app.dlgTrainImg);
            app.labelOverlap.HorizontalAlignment = 'right';
            app.labelOverlap.Position = [334 227 73 22];
            app.labelOverlap.Text = 'Overlap (%):';

            % Create labelNFFT
            app.labelNFFT = uilabel(app.dlgTrainImg);
            app.labelNFFT.HorizontalAlignment = 'right';
            app.labelNFFT.Position = [287 193 119 22];
            app.labelNFFT.Text = 'NFFT (# of samples):';

            % Create RandomlyAddNoiseWARNINGWilloverwriteexistingDetsfilesLabel
            app.RandomlyAddNoiseWARNINGWilloverwriteexistingDetsfilesLabel = uilabel(app.dlgTrainImg);
            app.RandomlyAddNoiseWARNINGWilloverwriteexistingDetsfilesLabel.HorizontalAlignment = 'center';
            app.RandomlyAddNoiseWARNINGWilloverwriteexistingDetsfilesLabel.WordWrap = 'on';
            app.RandomlyAddNoiseWARNINGWilloverwriteexistingDetsfilesLabel.Position = [53 175 159 59];
            app.RandomlyAddNoiseWARNINGWilloverwriteexistingDetsfilesLabel.Text = {'Randomly Add Noise'; 'WARNING: Will overwrite existing Dets files'};

            % Create buttonCancel
            app.buttonCancel = uibutton(app.dlgTrainImg, 'push');
            app.buttonCancel.ButtonPushedFcn = createCallbackFcn(app, @appCancel_Callback, true);
            app.buttonCancel.Position = [271 34 100 34];
            app.buttonCancel.Text = 'Cancel';

            % Create buttonOK
            app.buttonOK = uibutton(app.dlgTrainImg, 'push');
            app.buttonOK.ButtonPushedFcn = createCallbackFcn(app, @buttonOK_Callback, true);
            app.buttonOK.Position = [140 34 100 34];
            app.buttonOK.Text = 'OK';

            % Create switchValData
            app.switchValData = uiswitch(app.dlgTrainImg, 'slider');
            app.switchValData.Items = {'No', 'Yes'};
            app.switchValData.Position = [108 145 45 20];
            app.switchValData.Value = 'Yes';

            % Create switchRandomNoise
            app.switchRandomNoise = uiswitch(app.dlgTrainImg, 'slider');
            app.switchRandomNoise.Items = {'No', 'Yes'};
            app.switchRandomNoise.Position = [108 236 45 20];
            app.switchRandomNoise.Value = 'No';

            % Create editNumAugDup
            app.editNumAugDup = uieditfield(app.dlgTrainImg, 'numeric');
            app.editNumAugDup.Limits = [0 Inf];
            app.editNumAugDup.RoundFractionalValues = 'on';
            app.editNumAugDup.ValueDisplayFormat = '%.0f';
            app.editNumAugDup.HorizontalAlignment = 'center';
            app.editNumAugDup.Position = [416 92 70 22];

            % Create editImgSize
            app.editImgSize = uieditfield(app.dlgTrainImg, 'numeric');
            app.editImgSize.Limits = [0 Inf];
            app.editImgSize.RoundFractionalValues = 'on';
            app.editImgSize.ValueDisplayFormat = '%.0f';
            app.editImgSize.HorizontalAlignment = 'center';
            app.editImgSize.Position = [416 124 70 22];

            % Create editImgLength
            app.editImgLength = uieditfield(app.dlgTrainImg, 'numeric');
            app.editImgLength.Limits = [0 Inf];
            app.editImgLength.HorizontalAlignment = 'center';
            app.editImgLength.Position = [416 157 70 22];

            % Create editNFFT
            app.editNFFT = uieditfield(app.dlgTrainImg, 'numeric');
            app.editNFFT.Limits = [0 Inf];
            app.editNFFT.ValueDisplayFormat = '%.0f';
            app.editNFFT.HorizontalAlignment = 'center';
            app.editNFFT.Position = [417 190 69 22];

            % Create editOverlap
            app.editOverlap = uieditfield(app.dlgTrainImg, 'numeric');
            app.editOverlap.Limits = [0 100];
            app.editOverlap.ValueDisplayFormat = '%3.1f';
            app.editOverlap.HorizontalAlignment = 'center';
            app.editOverlap.Position = [417 225 69 22];

            % Create editWinSize
            app.editWinSize = uieditfield(app.dlgTrainImg, 'numeric');
            app.editWinSize.Limits = [0 Inf];
            app.editWinSize.ValueDisplayFormat = '%.0f';
            app.editWinSize.HorizontalAlignment = 'center';
            app.editWinSize.Position = [417 259 69 22];

            % Create buttongroupSpecUnits
            app.buttongroupSpecUnits = uibuttongroup(app.dlgTrainImg);
            app.buttongroupSpecUnits.SelectionChangedFcn = createCallbackFcn(app, @buttongroupSpecUnits_Callback, true);
            app.buttongroupSpecUnits.TitlePosition = 'centertop';
            app.buttongroupSpecUnits.Title = 'Units of Spectrogram Parameters';
            app.buttongroupSpecUnits.Position = [152 301 209 71];

            % Create buttonSamples
            app.buttonSamples = uiradiobutton(app.buttongroupSpecUnits);
            app.buttonSamples.Text = 'Samples';
            app.buttonSamples.Position = [71 25 69 22];
            app.buttonSamples.Value = true;

            % Create buttonSeconds
            app.buttonSeconds = uiradiobutton(app.buttongroupSpecUnits);
            app.buttonSeconds.Text = 'Seconds';
            app.buttonSeconds.Position = [71 3 69 22];

            % Create labelMaxSR
            app.labelMaxSR = uilabel(app.dlgTrainImg);
            app.labelMaxSR.Position = [278 389 138 22];
            app.labelMaxSR.Text = 'Max SR (Hz):';

            % Create labelMinSR
            app.labelMinSR = uilabel(app.dlgTrainImg);
            app.labelMinSR.Position = [94 389 138 22];
            app.labelMinSR.Text = 'Min SR (Hz):';

            % Create labelMaxFreq
            app.labelMaxFreq = uilabel(app.dlgTrainImg);
            app.labelMaxFreq.Position = [278 427 138 22];
            app.labelMaxFreq.Text = 'Max Freq (Hz):';

            % Create labelMinFreq
            app.labelMinFreq = uilabel(app.dlgTrainImg);
            app.labelMinFreq.Position = [94 427 138 22];
            app.labelMinFreq.Text = 'Min Freq (Hz):';

            % Create labelQuan90Dur
            app.labelQuan90Dur = uilabel(app.dlgTrainImg);
            app.labelQuan90Dur.Position = [278 466 138 22];
            app.labelQuan90Dur.Text = '90% Quantile Dur (s):';

            % Create labelMedDur
            app.labelMedDur = uilabel(app.dlgTrainImg);
            app.labelMedDur.Position = [95 466 138 22];
            app.labelMedDur.Text = 'Median Dur (s):';

            % Create labelMaxDur
            app.labelMaxDur = uilabel(app.dlgTrainImg);
            app.labelMaxDur.Position = [279 505 138 22];
            app.labelMaxDur.Text = 'Max Dur (s):';

            % Create labelMinDur
            app.labelMinDur = uilabel(app.dlgTrainImg);
            app.labelMinDur.Position = [94 505 138 22];
            app.labelMinDur.Text = 'Min Dur (s):';

            % Create labelAnnotationMetadata
            app.labelAnnotationMetadata = uilabel(app.dlgTrainImg);
            app.labelAnnotationMetadata.HorizontalAlignment = 'center';
            app.labelAnnotationMetadata.Position = [123 537 264 22];
            app.labelAnnotationMetadata.Text = 'Annotation Metadata for Selected Training Data:';

            % Create labelTitle
            app.labelTitle = uilabel(app.dlgTrainImg);
            app.labelTitle.HorizontalAlignment = 'center';
            app.labelTitle.FontSize = 14;
            app.labelTitle.FontWeight = 'bold';
            app.labelTitle.Position = [158 568 194 22];
            app.labelTitle.Text = 'Settings for Training Images';

            % Create labelFreqLowLim_2
            app.labelFreqLowLim_2 = uilabel(app.dlgTrainImg);
            app.labelFreqLowLim_2.HorizontalAlignment = 'right';
            app.labelFreqLowLim_2.Position = [238 125 169 22];
            app.labelFreqLowLim_2.Text = 'Image Resolution (pixels):';

            % Create ManuallySelectValidationDataLabel
            app.ManuallySelectValidationDataLabel = uilabel(app.dlgTrainImg);
            app.ManuallySelectValidationDataLabel.HorizontalAlignment = 'center';
            app.ManuallySelectValidationDataLabel.Position = [45 117 174 22];
            app.ManuallySelectValidationDataLabel.Text = 'Manually Select Validation Data';

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