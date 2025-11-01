function ExportTensorFlowStep2()
    %%% EVENTUALLY come back and add catches for Python version, presence
    %%% of TF and keras, etc.
    fig = uifigure;
    d = uiprogressdlg(fig,'Title','Loading and Re-saving Model',...
        'Indeterminate','on');
    drawnow

    indir = uigetdir('','Select the directory where the results of Step 1 live');
    outdir = uigetdir(indir,'Select the directory where you want the output of Step 2 to be saved (empty directory recommended)');

    modname = strsplit(indir, filesep);
    appath = strjoin(modname(1:end-1), filesep);
    modname = modname{end};

    % Add current path to Python path so import model works
    % Apparently this needs to be added to Matlab, not Python path for load_model() to
    % work >:(
    %py.sys.path().append(appath);
    cdBU = pwd;
    cd(appath)
    addpath(appath);
    pyrun('import os')
    pyrun('os.environ["TF_USE_LEGACY_KERAS"] = "1"')

    % Import model
    matmod = py.importlib.import_module(modname);
    model = matmod.load_model();
    
    % Re-save model in formats for use in PAMGuard, etc.
    model.save(fullfile(outdir,[modname '.keras']));
    model.save(fullfile(outdir,[modname '.h5']));
    % Following ONLY works with Keras2 (python -m pip install tf_keras)
    model.save(fullfile(outdir,modname));

    %% Move PDTF FILE
    movefile(fullfile(indir,'deepAcoustics.pdtf'),fullfile(outdir,modname,'deepAcoustics.pdtf'));

    %% Zip PG folder
    zip(fullfile(outdir,[modname '.zip']), fullfile(outdir,modname));
    cd(cdBU);

    % close the wait dialog box
    close(d)
end