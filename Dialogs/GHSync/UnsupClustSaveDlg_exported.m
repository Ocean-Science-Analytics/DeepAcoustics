classdef UnsupClustSaveDlg_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        dlgUnsupClustSave          matlab.ui.Figure
        buttonSelectDeselect       matlab.ui.control.Button
        textareaSaveLocation       matlab.ui.control.TextArea
        SaveLocationTextAreaLabel  matlab.ui.control.Label
        buttonOK                   matlab.ui.control.Button
        panelVariables             matlab.ui.container.Panel
        labelUpdateDetsInfo        matlab.ui.control.Label
        checkboxUpdateDets         matlab.ui.control.CheckBox
        labelExpECInfo             matlab.ui.control.Label
        checkboxOverwriteEC        matlab.ui.control.CheckBox
        checkboxExpEC              matlab.ui.control.CheckBox
        labelModelInfo             matlab.ui.control.Label
        checkboxModel              matlab.ui.control.CheckBox
        labelSelectItemstoSave     matlab.ui.control.Label
        buttonBrowse               matlab.ui.control.Button
        panelImages                matlab.ui.container.Panel
        imgtSNE                    matlab.ui.control.Image
        checkboxtSNE               matlab.ui.control.CheckBox
        imgCentCont                matlab.ui.control.Image
        imgClosestCalls            matlab.ui.control.Image
        checkboxCentCont           matlab.ui.control.CheckBox
        checkboxClosestCalls       matlab.ui.control.CheckBox
        imgSilhouettes             matlab.ui.control.Image
        checkboxSilhouettes        matlab.ui.control.CheckBox
        imgClustImgs               matlab.ui.control.Image
        checkboxClustImgs          matlab.ui.control.CheckBox
    end

    
    properties (Access = private)
        CallingApp % Parent app object
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp, saveloc)
            % Link to parent app
            app.CallingApp = mainapp;
            app.textareaSaveLocation.Value = saveloc;
        end

        % Button pushed function: buttonSelectDeselect
        function buttonSelectDeselect_Callback(app, event)
            % If any checkboxes unchecked, check them all
            if ~app.checkboxClustImgs.Value || ~app.checkboxSilhouettes.Value || ...
                    ~app.checkboxClosestCalls.Value || ~app.checkboxCentCont.Value || ~app.checkboxtSNE.Value || ...
                    ~app.checkboxModel.Value || ~app.checkboxExpEC.Value || ...
                    ~app.checkboxOverwriteEC.Value || ~app.checkboxUpdateDets.Value
                app.checkboxClustImgs.Value = true;
                app.checkboxSilhouettes.Value = true;
                app.checkboxClosestCalls.Value = true;
                app.checkboxCentCont.Value = true;
                app.checkboxtSNE.Value = true;
                app.checkboxModel.Value = true;
                app.checkboxExpEC.Value = true;
                app.checkboxOverwriteEC.Value = true;
                app.checkboxUpdateDets.Value = true;
            % Otherwise, uncheck them all
            else
                app.checkboxClustImgs.Value = false;
                app.checkboxSilhouettes.Value = false;
                app.checkboxClosestCalls.Value = false;
                app.checkboxCentCont.Value = false;
                app.checkboxtSNE.Value = false;
                app.checkboxModel.Value = false;
                app.checkboxExpEC.Value = false;
                app.checkboxOverwriteEC.Value = false;
                app.checkboxUpdateDets.Value = false;
            end
        end

        % Button pushed function: buttonOK
        function buttonOK_Callback(app, event)
            % Pass values to parent app
            app.CallingApp.strUnsupSaveLoc = app.textareaSaveLocation.Value{:};
            app.CallingApp.bClustImg = app.checkboxClustImgs.Value;
            app.CallingApp.bSilh = app.checkboxSilhouettes.Value;
            app.CallingApp.bClosest = app.checkboxClosestCalls.Value;
            app.CallingApp.bContours = app.checkboxCentCont.Value;
            app.CallingApp.btSNE = app.checkboxtSNE.Value;
            app.CallingApp.bModel = app.checkboxModel.Value;
            app.CallingApp.bEEC = app.checkboxExpEC.Value;
            app.CallingApp.bECOverwrite = app.checkboxOverwriteEC.Value;
            app.CallingApp.bUpdateDets = app.checkboxUpdateDets.Value;
            
            % Delete Save dialog
            delete(app)
        end

        % Close request function: dlgUnsupClustSave
        function dlgUnsupClustSaveCloseRequest(app, event)
            % Delete Save dialog
            delete(app)
        end

        % Button pushed function: buttonBrowse
        function buttonBrowse_Callback(app, event)
            app.textareaSaveLocation.Value = uigetdir(app.textareaSaveLocation.Value{:});
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create dlgUnsupClustSave and hide until all components are created
            app.dlgUnsupClustSave = uifigure('Visible', 'off');
            app.dlgUnsupClustSave.Position = [100 100 641 814];
            app.dlgUnsupClustSave.Name = 'MATLAB App';
            app.dlgUnsupClustSave.CloseRequestFcn = createCallbackFcn(app, @dlgUnsupClustSaveCloseRequest, true);
            app.dlgUnsupClustSave.WindowStyle = 'modal';

            % Create panelImages
            app.panelImages = uipanel(app.dlgUnsupClustSave);
            app.panelImages.Title = 'Images (.png)';
            app.panelImages.Position = [25 400 593 240];

            % Create checkboxClustImgs
            app.checkboxClustImgs = uicheckbox(app.panelImages);
            app.checkboxClustImgs.Text = 'Cluster Images';
            app.checkboxClustImgs.Position = [20 160 103 22];
            app.checkboxClustImgs.Value = true;

            % Create imgClustImgs
            app.imgClustImgs = uiimage(app.panelImages);
            app.imgClustImgs.Position = [122 121 100 100];
            app.imgClustImgs.ImageSource = 'Ex_ClustImg.png';

            % Create checkboxSilhouettes
            app.checkboxSilhouettes = uicheckbox(app.panelImages);
            app.checkboxSilhouettes.Text = 'Silhouette Plot';
            app.checkboxSilhouettes.Position = [20 58 99 22];
            app.checkboxSilhouettes.Value = true;

            % Create imgSilhouettes
            app.imgSilhouettes = uiimage(app.panelImages);
            app.imgSilhouettes.Position = [121 34 70 70];
            app.imgSilhouettes.ImageSource = 'Ex_Silh.png';

            % Create checkboxClosestCalls
            app.checkboxClosestCalls = uicheckbox(app.panelImages);
            app.checkboxClosestCalls.Text = 'Closest Calls to Centroids';
            app.checkboxClosestCalls.Position = [298 160 160 22];
            app.checkboxClosestCalls.Value = true;

            % Create checkboxCentCont
            app.checkboxCentCont = uicheckbox(app.panelImages);
            app.checkboxCentCont.Text = 'Centroid Contours';
            app.checkboxCentCont.Position = [209 58 119 22];
            app.checkboxCentCont.Value = true;

            % Create imgClosestCalls
            app.imgClosestCalls = uiimage(app.panelImages);
            app.imgClosestCalls.Position = [460 136 70 70];
            app.imgClosestCalls.ImageSource = 'Ex_ClosestCall.png';

            % Create imgCentCont
            app.imgCentCont = uiimage(app.panelImages);
            app.imgCentCont.Position = [331 34 70 70];
            app.imgCentCont.ImageSource = 'Ex_CentConts.png';

            % Create checkboxtSNE
            app.checkboxtSNE = uicheckbox(app.panelImages);
            app.checkboxtSNE.Text = 't-SNE';
            app.checkboxtSNE.Position = [432 58 54 22];
            app.checkboxtSNE.Value = true;

            % Create imgtSNE
            app.imgtSNE = uiimage(app.panelImages);
            app.imgtSNE.Position = [490 34 81 70];
            app.imgtSNE.ImageSource = fullfile(pathToMLAPP, 'UnsupClustSaveDlg', 'Ex_tSNE.png');

            % Create buttonBrowse
            app.buttonBrowse = uibutton(app.dlgUnsupClustSave, 'push');
            app.buttonBrowse.ButtonPushedFcn = createCallbackFcn(app, @buttonBrowse_Callback, true);
            app.buttonBrowse.Position = [515 708 81 22];
            app.buttonBrowse.Text = 'Browse...';

            % Create labelSelectItemstoSave
            app.labelSelectItemstoSave = uilabel(app.dlgUnsupClustSave);
            app.labelSelectItemstoSave.HorizontalAlignment = 'center';
            app.labelSelectItemstoSave.FontSize = 18;
            app.labelSelectItemstoSave.Position = [236 760 171 22];
            app.labelSelectItemstoSave.Text = 'Select Items to Save';

            % Create panelVariables
            app.panelVariables = uipanel(app.dlgUnsupClustSave);
            app.panelVariables.Title = 'Variables (.mat)';
            app.panelVariables.Position = [25 65 593 336];

            % Create checkboxModel
            app.checkboxModel = uicheckbox(app.panelVariables);
            app.checkboxModel.Text = 'KMeans Model';
            app.checkboxModel.Position = [21 283 102 24];
            app.checkboxModel.Value = true;

            % Create labelModelInfo
            app.labelModelInfo = uilabel(app.panelVariables);
            app.labelModelInfo.VerticalAlignment = 'top';
            app.labelModelInfo.Position = [266 216 206 91];
            app.labelModelInfo.Text = {'Contains model information, including:'; '     Centroid Matrix'; '     Cluster Labels'; '     Model Weights'; '     # of Contour Points'; '     Parson''s Code Resolution'};

            % Create checkboxExpEC
            app.checkboxExpEC = uicheckbox(app.panelVariables);
            app.checkboxExpEC.Text = 'Expanded Clustering Data';
            app.checkboxExpEC.Position = [21 187 162 22];
            app.checkboxExpEC.Value = true;

            % Create checkboxOverwriteEC
            app.checkboxOverwriteEC = uicheckbox(app.panelVariables);
            app.checkboxOverwriteEC.Text = 'Overwrite Existing?';
            app.checkboxOverwriteEC.Position = [46 166 125 22];
            app.checkboxOverwriteEC.Value = true;

            % Create labelExpECInfo
            app.labelExpECInfo = uilabel(app.panelVariables);
            app.labelExpECInfo.Position = [266 103 277 106];
            app.labelExpECInfo.Text = {'Contains additional calculated information for each'; 'detection, including:'; '     Cluster Indices'; '     Euclidean Distance to Centroid'; '     [# of Contour Pts]-Contour'; '     # of Inflection Points'; '     Silhouette Value'};

            % Create checkboxUpdateDets
            app.checkboxUpdateDets = uicheckbox(app.panelVariables);
            app.checkboxUpdateDets.Text = 'Update "ClustCat" in Detections';
            app.checkboxUpdateDets.Position = [21 74 192 22];
            app.checkboxUpdateDets.Value = true;

            % Create labelUpdateDetsInfo
            app.labelUpdateDetsInfo = uilabel(app.panelVariables);
            app.labelUpdateDetsInfo.Position = [266 8 322 88];
            app.labelUpdateDetsInfo.Text = {'Will update the "ClustCat" variable in the active'; 'Detections.mat file(s) with the cluster assignments for this'; 'clustering run (WARNING: This will overwrite any previous '; 'clustering assignments already saved as "ClustCat". This'; 'information does not impact any future clustering runs.)'};

            % Create buttonOK
            app.buttonOK = uibutton(app.dlgUnsupClustSave, 'push');
            app.buttonOK.ButtonPushedFcn = createCallbackFcn(app, @buttonOK_Callback, true);
            app.buttonOK.Position = [268 15 109 42];
            app.buttonOK.Text = 'OK';

            % Create SaveLocationTextAreaLabel
            app.SaveLocationTextAreaLabel = uilabel(app.dlgUnsupClustSave);
            app.SaveLocationTextAreaLabel.HorizontalAlignment = 'right';
            app.SaveLocationTextAreaLabel.Position = [26 708 85 22];
            app.SaveLocationTextAreaLabel.Text = 'Save Location:';

            % Create textareaSaveLocation
            app.textareaSaveLocation = uitextarea(app.dlgUnsupClustSave);
            app.textareaSaveLocation.Editable = 'off';
            app.textareaSaveLocation.Enable = 'off';
            app.textareaSaveLocation.Position = [124 689 370 60];

            % Create buttonSelectDeselect
            app.buttonSelectDeselect = uibutton(app.dlgUnsupClustSave, 'push');
            app.buttonSelectDeselect.ButtonPushedFcn = createCallbackFcn(app, @buttonSelectDeselect_Callback, true);
            app.buttonSelectDeselect.Position = [263 652 121 22];
            app.buttonSelectDeselect.Text = 'Select/De-Select All';

            % Show the figure after all components are created
            app.dlgUnsupClustSave.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = UnsupClustSaveDlg_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.dlgUnsupClustSave)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.dlgUnsupClustSave)
        end
    end
end