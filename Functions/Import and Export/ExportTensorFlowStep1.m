function ExportTensorFlowStep1()
    % Load neural network
    [networkname,networkpath] = uigetfile('*.mat','Select the network you want to export');
    h = waitbar(0,'Loading neural network...');
    NeuralNetwork=load(fullfile(networkpath,networkname));
    close(h);

    outpath = uigetdir(networkpath,'Create and select the output directory (should be empty and must not begin with a number)');
    
    exportNetworkToTensorFlow(NeuralNetwork.detector.Network,outpath);

    % Add some extra model metadata to model.py file
    modelpy = readlines(fullfile(outpath,'model.py'));

    % Convert image size info to np string
    imgszstr = sprintf('[%d,%d,%d]',NeuralNetwork.detector.InputSize(1),NeuralNetwork.detector.InputSize(2),NeuralNetwork.detector.InputSize(3));

    % Convert anchor box info to np string
    abstr = '[';
    numDetHeads = size(NeuralNetwork.detector.AnchorBoxes,1);
    for i = 1:numDetHeads
        abstr = sprintf('%s[',abstr);
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
    end
    abstr = sprintf('%s]',abstr);

    insertind = find(strcmp(modelpy,'def create_model():'));
    inserttext = ["import numpy as np";""; ...
        sprintf("imgsize = %s",imgszstr);...
        sprintf("anchorBoxes = np.array(%s)",abstr);""];
    modelpy(insertind+length(inserttext):end+length(inserttext)) = modelpy(insertind:end);
    modelpy(insertind:insertind+length(inserttext)-1) = inserttext;

    % Append pre and postprocess fns
    prepostfnstr = readlines('TFprepostfns.txt');
    modelpy(end+1:end+length(prepostfnstr)) = prepostfnstr;

    writelines(modelpy,fullfile(outpath,'model.py'));

    msgbox('Check the main Matlab window for any information about custom layers that need to be addressed before proceeding to Step 2.  For more information refer to the DeepAcoustics User Manual and/or Matlab documentation about the "exportNetworkToTensorFlow" function.')
end
