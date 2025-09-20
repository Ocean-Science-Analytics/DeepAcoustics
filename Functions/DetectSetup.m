% --- Method for detecting all calls in (an) audio file(s)
function NeuralNetwork = DetectSetup(hObject,~,handles) 

if isempty(handles.networkfiles)
    errordlg('No Network Selected')
    return
end

networkselection = listdlg('PromptString','Select a Network:','ListSize',[500 300],'SelectionMode','single','ListString',handles.networkfilesnames);
if isempty(networkselection)
    return
end

% Chooose output directory for Dets file
path=uigetdir(handles.data.settings.detectionfolder,'Select Output Folder');
if isnumeric(path);return;end
handles.data.settings.detectionfolder = path;
handles.data.saveSettings();
update_folders(hObject, handles);
handles = guidata(hObject);  % Get newest version of handles

% Load neural network
h = waitbar(0,'Loading neural network...');
networkname = handles.networkfiles(networkselection).name;
networkpath = handles.networkfiles(networkselection).folder;
NeuralNetwork=load(fullfile(networkpath,networkname));%get currently selected option from menu
NeuralNetwork.netfile = networkname;
close(h);

% Prompt for detection settings
dlg_title = ['Settings for Running ' handles.networkfiles(networkselection).name];
num_lines=[1 length(dlg_title)+30]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
def = handles.data.settings.detectionSettings;
if isfield(NeuralNetwork,'freqlow')
    prompt = {'Total Analysis Length (Seconds; 0 = Full Duration)','Score Threshold (0-1)','Append Date to FileName (1 = yes)'};
    % Remove freq limits (will carryover from network settings)
    def = def([1,4:5]);
else
    % Back-compatible
    warning('This is an older network - we recommend recreating if possible to preserve associated metadata')
    prompt = {'Total Analysis Length (Seconds; 0 = Full Duration)','Low Frequency Cutoff (Hz)','High Frequency Cutoff (Hz)','Score Threshold (0-1)','Append Date to FileName (1 = yes)'};
    % Convert freq to Hz for display
    def(2) = sprintfc('%g',str2double(def{2})*1000);
    def(3) = sprintfc('%g',str2double(def{3})*1000);
end
Settings = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));

if isempty(Settings) % Stop if user presses cancel
    return
end
if isfield(NeuralNetwork,'freqlow')
    % Get settings from network
    Settings(4:5) = Settings(2:3);
    Settings(2) = NeuralNetwork.freqlow/1000;
    Settings(3) = NeuralNetwork.freqhigh/1000;
else
    % Back-compatible
    % Convert freq inputs to kHz
    Settings(2:3) = Settings(2:3)/1000;
end

handles.data.settings.detectionSettings = sprintfc('%g',Settings)';

% Save the new settings
handles.data.saveSettings();

update_folders(hObject, handles);
% I think this unnecessary now bc no other code and handles is not returned
%handles = guidata(hObject);  % Get newest version of handles