classdef AboutDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgAboutDW  matlab.ui.Figure
        buttonOK    matlab.ui.control.Button
        labelTitle  matlab.ui.control.Label
        textInfo    matlab.ui.control.TextArea
    end

    
    properties (Access = private)
        MainApp % Main DW GUI
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, parentapp, nVers)
            app.MainApp = parentapp;
            app.textInfo.Value = {'©Coffey & Marx & Ciszek, 2021'; 'Modified ©Sugarman, Ferguson, Schallert, & Alongi, 2022'; ['Version ' nVers]};
        end

        % Button pushed function: buttonOK
        function buttonOK_Callback(app, event)
            delete(app)
        end

        % Close request function: dlgAboutDW
        function appCloseRequest(app, event)
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create dlgAboutDW and hide until all components are created
            app.dlgAboutDW = uifigure('Visible', 'off');
            app.dlgAboutDW.Color = [1 1 1];
            app.dlgAboutDW.Position = [300 350 508 194];
            app.dlgAboutDW.Name = 'About DeepWaves';
            app.dlgAboutDW.CloseRequestFcn = createCallbackFcn(app, @appCloseRequest, true);

            % Create textInfo
            app.textInfo = uitextarea(app.dlgAboutDW);
            app.textInfo.HorizontalAlignment = 'center';
            app.textInfo.Position = [86 71 337 55];
            app.textInfo.Value = {'©Coffey & Marx & Ciszek, 2021'; 'Modified ©Sugarman, Ferguson, Schallert, & Alongi, 2022'; 'Version'};

            % Create labelTitle
            app.labelTitle = uilabel(app.dlgAboutDW);
            app.labelTitle.HorizontalAlignment = 'center';
            app.labelTitle.FontSize = 24;
            app.labelTitle.Position = [187 139 135 30];
            app.labelTitle.Text = 'DeepWaves';

            % Create buttonOK
            app.buttonOK = uibutton(app.dlgAboutDW, 'push');
            app.buttonOK.ButtonPushedFcn = createCallbackFcn(app, @buttonOK_Callback, true);
            app.buttonOK.Position = [205 28 100 22];
            app.buttonOK.Text = 'OK';

            % Show the figure after all components are created
            app.dlgAboutDW.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = AboutDlg_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.dlgAboutDW)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.dlgAboutDW)
        end
    end
end