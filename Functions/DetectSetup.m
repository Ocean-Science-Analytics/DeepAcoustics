% --- Method for detecting all calls in (an) audio file(s)
function NeuralNetwork = DetectSetup(hObject,eventdata,handles) 

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

% Prompt for detection settings
prompt = {'Total Analysis Length (Seconds; 0 = Full Duration)','Low Frequency Cutoff (Hz)','High Frequency Cutoff (Hz)','Score Threshold (0-1)','Append Date to FileName (1 = yes)'};
dlg_title = ['Settings for ' handles.networkfiles(networkselection).name];
num_lines=[1 length(dlg_title)+30]; options.Resize='off'; options.WindowStyle='modal'; options.Interpreter='tex';
def = handles.data.settings.detectionSettings;
% Convert freq to Hz for display
def(2) = sprintfc('%g',str2double(def{2})*1000);
def(3) = sprintfc('%g',str2double(def{3})*1000);

% If RT, don't need analysis length
% if bRT
%     prompt = prompt(2:end);
%     def = def(2:end);
% end

% Execute prompt
Settings = str2double(inputdlg(prompt,dlg_title,num_lines,def,options));

if isempty(Settings) % Stop if user presses cancel
    return
end

% if bRT
%     Settings(2:5) = Settings(1:4);
%     Settings(1) = 0;
% end

% Convert freq inputs to kHz
Settings(2:3) = Settings(2:3)/1000;

handles.data.settings.detectionSettings = sprintfc('%g',Settings(:,1))';

% Save the new settings
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