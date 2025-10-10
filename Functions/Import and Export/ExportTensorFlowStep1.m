function ExportTensorFlowStep1()
    % Load neural network
    [networkname,networkpath] = uigetfile('*.mat','Select the network you want to export');
    h = waitbar(0,'Loading neural network...');
    NeuralNetwork=load(fullfile(networkpath,networkname));
    close(h);

    outpath = uigetdir(networkpath,'Create and select the output directory (should be empty and must not begin with a number)');
    
    exportNetworkToTensorFlow(NeuralNetwork.detector.Network,outpath);

        %% PDTF FILE
    % Load PDTF template to edit model details
    txtPDTF = readlines('deepAcoustics_TFTemp.pdtf');

    % Convert image size
    txtPDTF = strrep(txtPDTF,'INPUTSIZE1',num2str(NeuralNetwork.detector.InputSize(1),'%d'));
    txtPDTF = strrep(txtPDTF,'INPUTSIZE2',num2str(NeuralNetwork.detector.InputSize(2),'%d'));
    txtPDTF = strrep(txtPDTF,'INPUTSIZE3',num2str(NeuralNetwork.detector.InputSize(3),'%d'));

    % Convert anchor box info
    insertind = find(contains(txtPDTF,'ANCHORBOXMAT'));
    numDetHeads = size(NeuralNetwork.detector.AnchorBoxes,1);
    txtPDTF(insertind+numDetHeads:end+(numDetHeads-1)) = txtPDTF(insertind+1:end);
    for i = 1:(numDetHeads-1)
        txtPDTF(insertind+i) = txtPDTF(insertind);
    end

    for i = 1:numDetHeads
        abstr = '[';
        numThisHead = size(NeuralNetwork.detector.AnchorBoxes{i},1);
        for j = 1:numThisHead
            abstr = sprintf('%s[%d,%d]',abstr,NeuralNetwork.detector.AnchorBoxes{i}(j,1),NeuralNetwork.detector.AnchorBoxes{i}(j,2));
            if j<numThisHead
                abstr = sprintf('%s,',abstr);
            end
        end
        abstr = sprintf('%s]',abstr);
        if i<numDetHeads
            abstr = sprintf('%s,',abstr);
        end
        txtPDTF(insertind+i-1) = strrep(txtPDTF(insertind+i-1),'ANCHORBOXMAT',abstr);
    end

    % Convert class names
    insertind = find(contains(txtPDTF,'CLASSNAMEMAT'));
    numClasses = size(NeuralNetwork.detector.ClassNames,1);
    txtPDTF(insertind+numClasses:end+(numClasses-1)) = txtPDTF(insertind+1:end);
    for i = 1:(numClasses-1)
        txtPDTF(insertind+i) = txtPDTF(insertind);
    end

    for i = 1:numClasses
        clsstr = sprintf('"%s"',NeuralNetwork.detector.ClassNames{i});
        if i<numClasses
            clsstr = sprintf('%s,',clsstr);
        end
        txtPDTF(insertind+i-1) = strrep(txtPDTF(insertind+i-1),'CLASSNAMEMAT',clsstr);
    end
    txtPDTF = strrep(txtPDTF,'NUMCLASSES',num2str(numClasses,'%d'));

    % Convert SR (Hz)
    if ~isfield(NeuralNetwork,'samprate')
        NeuralNetwork.samprate = str2double(inputdlg('This is an older network; please enter sample rate (Hz) of audio used to train this network:','Enter SR'));
    end
    txtPDTF = strrep(txtPDTF,'SAMPRATE',num2str(NeuralNetwork.samprate,'%d'));

    % Convert FFT settings CHECK WITH JAMIE
    txtPDTF = strrep(txtPDTF,'WINSIZESEC',num2str((NeuralNetwork.imLength*1000),'%d'));
    txtPDTF = strrep(txtPDTF,'FFTSAMP',num2str(round(NeuralNetwork.nfft*NeuralNetwork.samprate),'%d'));
    txtPDTF = strrep(txtPDTF,'FFTHOPSAMP',num2str(round((NeuralNetwork.nfft-NeuralNetwork.noverlap)*NeuralNetwork.samprate),'%d'));

    % Convert min & max freq (Hz)
    if ~isfield(NeuralNetwork,'freqlow')
        dlg_title = 'Enter min and max freq cut-offs used to train this network';
        num_lines = [1 length(dlg_title)+30];
        minmaxfreq = inputdlg({'Min Freq (Hz):','Max Freq (Hz):'},dlg_title,num_lines);
        NeuralNetwork.freqlow = str2double(minmaxfreq{1});
        NeuralNetwork.freqhigh = str2double(minmaxfreq{2});
    end
    txtPDTF = strrep(txtPDTF,'MINFREQ',num2str(NeuralNetwork.freqlow,'%d'));
    txtPDTF = strrep(txtPDTF,'MAXFREQ',num2str(NeuralNetwork.freqhigh,'%d'));

    % Convert image size
    txtPDTF = strrep(txtPDTF,'IMGLENGTHMSEC',num2str((NeuralNetwork.imLength*1000),'%d'));

    writelines(txtPDTF,fullfile(outpath,'deepAcoustics.pdtf'));

    msgbox('Check the main Matlab window for any information about custom layers that need to be addressed before proceeding to Step 2.  For more information refer to the DeepAcoustics User Manual and/or Matlab documentation about the "exportNetworkToTensorFlow" function.')
end
