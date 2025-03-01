classdef RecordOptsDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgRecordOpts                   matlab.ui.Figure
        MicrophoneDropDownLabel         matlab.ui.control.Label
        labelRecOpts                    matlab.ui.control.Label
        textareaSaveLocation            matlab.ui.control.TextArea
        SaveLocationTextAreaLabel       matlab.ui.control.Label
        buttonBrowse                    matlab.ui.control.Button
        AudioFilenameEditFieldLabel     matlab.ui.control.Label
        SampleRateHzEditFieldLabel      matlab.ui.control.Label
        RecordingLengthsecEditFieldLabel  matlab.ui.control.Label
        checkboxCont                    matlab.ui.control.CheckBox
        editfieldRecLgth                matlab.ui.control.NumericEditField
        editfieldSR                     matlab.ui.control.NumericEditField
        editfieldAudFN                  matlab.ui.control.EditField
        dropdownAudFType                matlab.ui.control.DropDown
        dropdownMicroph                 matlab.ui.control.DropDown
        checkboxLoadNet                 matlab.ui.control.CheckBox
        NetworkSettingsPanel            matlab.ui.container.Panel
        DetectionsFilenameLabel         matlab.ui.control.Label
        textareaNetLoad                 matlab.ui.control.TextArea
        buttonBrowseNet                 matlab.ui.control.Button
        editfieldLFCutoff               matlab.ui.control.NumericEditField
        editfieldHFCutoff               matlab.ui.control.NumericEditField
        editfieldScoreThresh            matlab.ui.control.NumericEditField
        editfieldDetFN                  matlab.ui.control.EditField
        labelMat                        matlab.ui.control.Label
        ScoreThreshold01EditFieldLabel  matlab.ui.control.Label
        HighFrequencyCutoffHzEditFieldLabel  matlab.ui.control.Label
        LowFrequencyCutoffHzEditFieldLabel  matlab.ui.control.Label
        NetworktoLoadLabel              matlab.ui.control.Label
        buttonOK                        matlab.ui.control.Button
    end

    
    properties (Access = private)
        CallingApp % Parent app object
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp, saveloc, defSettings)
            % Link to parent app
            app.CallingApp = mainapp;

            % Set opening defaults
            app.textareaSaveLocation.Value = saveloc;
            app.editfieldAudFN.Value = char(datetime('now','Format','yyMMdd_HHmm'));
            app.editfieldDetFN.Value = [char(datetime('now','Format','yyMMdd_HHmm')),'_Detections'];
            app.editfieldLFCutoff.Value = str2double(defSettings{2})*1000;
            app.editfieldHFCutoff.Value = str2double(defSettings{3})*1000;
            app.editfieldScoreThresh.Value = str2double(defSettings{4});
            
            % Refresh audio devices in Matlab
            audiodevreset;
            % Temp device reader just to get microphone list
            deviceReader = audioDeviceReader(44100);
            app.dropdownMicroph.Items = getAudioDevices(deviceReader);
            app.dropdownMicroph.Value = app.dropdownMicroph.Items{1};
            release(deviceReader);
        end

        % Button pushed function: buttonOK
        function buttonOK_Callback(app, event)
            % Pass values to parent app
            app.CallingApp.strSaveAudFile = fullfile(app.textareaSaveLocation.Value{:},[app.editfieldAudFN.Value,lower(app.dropdownAudFType.Value)]);
            app.CallingApp.RecOptsRecLgth = app.editfieldRecLgth.Value;
            app.CallingApp.RecOptsSR = app.editfieldSR.Value;
            app.CallingApp.RecOptsMicroph = app.dropdownMicroph.Value;
            app.CallingApp.RecOptsNN = '';
            app.CallingApp.strSaveDetsFile = '';
            app.CallingApp.RecOptsDetStgs = '';

            if strcmp(app.textareaNetLoad.Value{:},'') || strcmp(app.textareaNetLoad.Value{:},'Select network to load...')
                % ERROR BUT ALSO ALLOW EXIT
                msgbox('No Network Selected - will record without detecting')
            elseif app.checkboxLoadNet.Value
                app.CallingApp.RecOptsNN = app.textareaNetLoad.Value{:};
                app.CallingApp.strSaveDetsFile = fullfile(app.textareaSaveLocation.Value{:},[app.editfieldDetFN.Value,'.mat']);
                Settings = [0; app.editfieldLFCutoff.Value; app.editfieldHFCutoff.Value; app.editfieldScoreThresh.Value; 0];
                Settings(2:3) = Settings(2:3)/1000;
                app.CallingApp.RecOptsDetStgs = sprintfc('%g',Settings(:,1))';
            end

            app.CallingApp.RecOptsOK = true;
            
            % Delete Save dialog
            delete(app)
        end

        % Close request function: dlgRecordOpts
        function dlgRecordOptsCloseRequest(app, event)
            % Delete Save dialog
            app.CallingApp.RecOptsOK = false;
            delete(app)
        end

        % Button pushed function: buttonBrowse
        function buttonBrowse_Callback(app, event)
            app.textareaSaveLocation.Value = {uigetdir(app.textareaSaveLocation.Value{:})};
        end

        % Value changed function: checkboxCont
        function checkboxCont_Callback(app, event)
            if app.checkboxCont.Value
                app.editfieldRecLgth.Editable = 'off';
                app.editfieldRecLgth.Enable = 'off';
                app.editfieldRecLgth.Value = 0;
            else
                app.editfieldRecLgth.Editable = 'on';
                app.editfieldRecLgth.Enable = 'on';
            end            
        end

        % Value changed function: checkboxLoadNet
        function checkboxLoadNet_Callback(app, event)
            if app.checkboxLoadNet.Value
                app.buttonBrowseNet.Enable = 'on';
            else
                app.buttonBrowseNet.Enable = 'off';
            end   
        end

        % Button pushed function: buttonBrowseNet
        function buttonBrowseNet_Callback(app, event)
            [nnfn, nnpn] = uigetfile(app.textareaSaveLocation.Value{:});
            app.textareaNetLoad.Value = {fullfile(nnpn,nnfn)};
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create dlgRecordOpts and hide until all components are created
            app.dlgRecordOpts = uifigure('Visible', 'off');
            app.dlgRecordOpts.Position = [100 100 641 773];
            app.dlgRecordOpts.Name = 'MATLAB App';
            app.dlgRecordOpts.CloseRequestFcn = createCallbackFcn(app, @dlgRecordOptsCloseRequest, true);
            app.dlgRecordOpts.WindowStyle = 'modal';

            % Create buttonOK
            app.buttonOK = uibutton(app.dlgRecordOpts, 'push');
            app.buttonOK.ButtonPushedFcn = createCallbackFcn(app, @buttonOK_Callback, true);
            app.buttonOK.Position = [269 36 109 42];
            app.buttonOK.Text = 'OK';

            % Create NetworkSettingsPanel
            app.NetworkSettingsPanel = uipanel(app.dlgRecordOpts);
            app.NetworkSettingsPanel.TitlePosition = 'centertop';
            app.NetworkSettingsPanel.Title = 'Network Settings';
            app.NetworkSettingsPanel.Position = [14 103 613 298];

            % Create NetworktoLoadLabel
            app.NetworktoLoadLabel = uilabel(app.NetworkSettingsPanel);
            app.NetworktoLoadLabel.HorizontalAlignment = 'right';
            app.NetworktoLoadLabel.Position = [20 217 96 22];
            app.NetworktoLoadLabel.Text = 'Network to Load:';

            % Create LowFrequencyCutoffHzEditFieldLabel
            app.LowFrequencyCutoffHzEditFieldLabel = uilabel(app.NetworkSettingsPanel);
            app.LowFrequencyCutoffHzEditFieldLabel.HorizontalAlignment = 'right';
            app.LowFrequencyCutoffHzEditFieldLabel.Position = [179 151 148 22];
            app.LowFrequencyCutoffHzEditFieldLabel.Text = 'Low Frequency Cutoff (Hz)';

            % Create HighFrequencyCutoffHzEditFieldLabel
            app.HighFrequencyCutoffHzEditFieldLabel = uilabel(app.NetworkSettingsPanel);
            app.HighFrequencyCutoffHzEditFieldLabel.HorizontalAlignment = 'right';
            app.HighFrequencyCutoffHzEditFieldLabel.Position = [176 112 151 22];
            app.HighFrequencyCutoffHzEditFieldLabel.Text = 'High Frequency Cutoff (Hz)';

            % Create ScoreThreshold01EditFieldLabel
            app.ScoreThreshold01EditFieldLabel = uilabel(app.NetworkSettingsPanel);
            app.ScoreThreshold01EditFieldLabel.HorizontalAlignment = 'right';
            app.ScoreThreshold01EditFieldLabel.Position = [205 73 122 22];
            app.ScoreThreshold01EditFieldLabel.Text = 'Score Threshold (0-1)';

            % Create labelMat
            app.labelMat = uilabel(app.NetworkSettingsPanel);
            app.labelMat.Position = [538 34 28 22];
            app.labelMat.Text = '.mat';

            % Create editfieldDetFN
            app.editfieldDetFN = uieditfield(app.NetworkSettingsPanel, 'text');
            app.editfieldDetFN.Position = [342 34 190 22];
            app.editfieldDetFN.Value = 'Filename';

            % Create editfieldScoreThresh
            app.editfieldScoreThresh = uieditfield(app.NetworkSettingsPanel, 'numeric');
            app.editfieldScoreThresh.Limits = [0 1];
            app.editfieldScoreThresh.Position = [342 73 100 22];

            % Create editfieldHFCutoff
            app.editfieldHFCutoff = uieditfield(app.NetworkSettingsPanel, 'numeric');
            app.editfieldHFCutoff.Limits = [0 Inf];
            app.editfieldHFCutoff.ValueDisplayFormat = '%11d';
            app.editfieldHFCutoff.Position = [342 112 100 22];

            % Create editfieldLFCutoff
            app.editfieldLFCutoff = uieditfield(app.NetworkSettingsPanel, 'numeric');
            app.editfieldLFCutoff.Limits = [0 Inf];
            app.editfieldLFCutoff.ValueDisplayFormat = '%11d';
            app.editfieldLFCutoff.Position = [342 151 100 22];

            % Create buttonBrowseNet
            app.buttonBrowseNet = uibutton(app.NetworkSettingsPanel, 'push');
            app.buttonBrowseNet.ButtonPushedFcn = createCallbackFcn(app, @buttonBrowseNet_Callback, true);
            app.buttonBrowseNet.Position = [515 226 81 22];
            app.buttonBrowseNet.Text = 'Browse...';

            % Create textareaNetLoad
            app.textareaNetLoad = uitextarea(app.NetworkSettingsPanel);
            app.textareaNetLoad.Editable = 'off';
            app.textareaNetLoad.Enable = 'off';
            app.textareaNetLoad.Position = [129 198 370 60];
            app.textareaNetLoad.Value = {'Select network to load...'};

            % Create DetectionsFilenameLabel
            app.DetectionsFilenameLabel = uilabel(app.NetworkSettingsPanel);
            app.DetectionsFilenameLabel.HorizontalAlignment = 'right';
            app.DetectionsFilenameLabel.Position = [213 34 114 22];
            app.DetectionsFilenameLabel.Text = 'Detections Filename';

            % Create checkboxLoadNet
            app.checkboxLoadNet = uicheckbox(app.dlgRecordOpts);
            app.checkboxLoadNet.ValueChangedFcn = createCallbackFcn(app, @checkboxLoadNet_Callback, true);
            app.checkboxLoadNet.Text = 'Load Network to Detect Calls';
            app.checkboxLoadNet.Position = [239 412 177 22];
            app.checkboxLoadNet.Value = true;

            % Create dropdownMicroph
            app.dropdownMicroph = uidropdown(app.dlgRecordOpts);
            app.dropdownMicroph.Items = {'Default'};
            app.dropdownMicroph.Position = [251 477 295 22];
            app.dropdownMicroph.Value = 'Default';

            % Create dropdownAudFType
            app.dropdownAudFType = uidropdown(app.dlgRecordOpts);
            app.dropdownAudFType.Items = {'.FLAC', '.WAV'};
            app.dropdownAudFType.Position = [476 520 71 22];
            app.dropdownAudFType.Value = '.FLAC';

            % Create editfieldAudFN
            app.editfieldAudFN = uieditfield(app.dlgRecordOpts, 'text');
            app.editfieldAudFN.Position = [252 518 213 22];
            app.editfieldAudFN.Value = 'Filename';

            % Create editfieldSR
            app.editfieldSR = uieditfield(app.dlgRecordOpts, 'numeric');
            app.editfieldSR.Limits = [0 Inf];
            app.editfieldSR.ValueDisplayFormat = '%11d';
            app.editfieldSR.Position = [263 559 100 22];
            app.editfieldSR.Value = 44100;

            % Create editfieldRecLgth
            app.editfieldRecLgth = uieditfield(app.dlgRecordOpts, 'numeric');
            app.editfieldRecLgth.Limits = [0 Inf];
            app.editfieldRecLgth.Editable = 'off';
            app.editfieldRecLgth.Enable = 'off';
            app.editfieldRecLgth.Position = [396 600 100 22];

            % Create checkboxCont
            app.checkboxCont = uicheckbox(app.dlgRecordOpts);
            app.checkboxCont.ValueChangedFcn = createCallbackFcn(app, @checkboxCont_Callback, true);
            app.checkboxCont.Text = 'Continuous';
            app.checkboxCont.Position = [151 600 83 22];
            app.checkboxCont.Value = true;

            % Create RecordingLengthsecEditFieldLabel
            app.RecordingLengthsecEditFieldLabel = uilabel(app.dlgRecordOpts);
            app.RecordingLengthsecEditFieldLabel.HorizontalAlignment = 'right';
            app.RecordingLengthsecEditFieldLabel.Enable = 'off';
            app.RecordingLengthsecEditFieldLabel.Position = [251 600 130 22];
            app.RecordingLengthsecEditFieldLabel.Text = 'Recording Length (sec)';

            % Create SampleRateHzEditFieldLabel
            app.SampleRateHzEditFieldLabel = uilabel(app.dlgRecordOpts);
            app.SampleRateHzEditFieldLabel.HorizontalAlignment = 'right';
            app.SampleRateHzEditFieldLabel.Position = [148 559 100 22];
            app.SampleRateHzEditFieldLabel.Text = 'Sample Rate (Hz)';

            % Create AudioFilenameEditFieldLabel
            app.AudioFilenameEditFieldLabel = uilabel(app.dlgRecordOpts);
            app.AudioFilenameEditFieldLabel.HorizontalAlignment = 'right';
            app.AudioFilenameEditFieldLabel.Position = [149 518 88 22];
            app.AudioFilenameEditFieldLabel.Text = 'Audio Filename';

            % Create buttonBrowse
            app.buttonBrowse = uibutton(app.dlgRecordOpts, 'push');
            app.buttonBrowse.ButtonPushedFcn = createCallbackFcn(app, @buttonBrowse_Callback, true);
            app.buttonBrowse.Position = [527 667 81 22];
            app.buttonBrowse.Text = 'Browse...';

            % Create SaveLocationTextAreaLabel
            app.SaveLocationTextAreaLabel = uilabel(app.dlgRecordOpts);
            app.SaveLocationTextAreaLabel.HorizontalAlignment = 'right';
            app.SaveLocationTextAreaLabel.Position = [38 667 85 22];
            app.SaveLocationTextAreaLabel.Text = 'Save Location:';

            % Create textareaSaveLocation
            app.textareaSaveLocation = uitextarea(app.dlgRecordOpts);
            app.textareaSaveLocation.Editable = 'off';
            app.textareaSaveLocation.Enable = 'off';
            app.textareaSaveLocation.Position = [136 648 370 60];

            % Create labelRecOpts
            app.labelRecOpts = uilabel(app.dlgRecordOpts);
            app.labelRecOpts.HorizontalAlignment = 'center';
            app.labelRecOpts.FontSize = 18;
            app.labelRecOpts.Position = [237 727 171 23];
            app.labelRecOpts.Text = 'Record Options';

            % Create MicrophoneDropDownLabel
            app.MicrophoneDropDownLabel = uilabel(app.dlgRecordOpts);
            app.MicrophoneDropDownLabel.HorizontalAlignment = 'right';
            app.MicrophoneDropDownLabel.Position = [168 477 68 22];
            app.MicrophoneDropDownLabel.Text = 'Microphone';

            % Show the figure after all components are created
            app.dlgRecordOpts.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = RecordOptsDlg_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.dlgRecordOpts)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.dlgRecordOpts)
        end
    end
end