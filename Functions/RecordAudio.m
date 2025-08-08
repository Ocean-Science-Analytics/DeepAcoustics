% --- Executes on button press in recordAudio.
function RecordAudio(app,event)
[hObject, eventdata, ~] = convertToGUIDECallbackArguments(app, event);
% hObject    handle to recordAudio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
get(hObject,'Value');
handles = guidata(hObject);

if eventdata.Source.Value==1
    % Check to save any currently loaded detections file
    CheckModified(hObject,eventdata,handles);
    % Update handles with changes in CheckModified
    handles = guidata(hObject);

    % Clear everything if calls are present
    if isfield(handles,'epochSpect')
        cla(handles.contourWindow);
        cla(handles.detectionAxes);
        cla(handles.focusWindow);
        cla(handles.spectrogramWindow);
        cla(handles.waveformWindow);
        Calls = table(zeros(0,4),[],[],[], 'VariableNames', {'Box', 'Score', 'Type', 'Accept'});
        set(handles.GoToCall,'Value',0);
        set(handles.GoToCallTotal,'String','/?');
        set(handles.score,'String','Score: ');
        set(handles.status,'String','');
        set(handles.text19,'String','Label: ');
        set(handles.freq,'String','Frequency: ');
        set(handles.slope,'String','Slope: ');
        set(handles.duration,'String','Duration: ');
        set(handles.sinuosity,'String','Sinuosity: ');
        set(handles.powertext,'String','Power: ');
        set(handles.tonalitytext,'String','Tonality: ');
    end
    hObject.String='Stop Recording';
    hObject.BackgroundColor=[0.84,0.08,0.18];

    app.RunRecordOptsDlg(handles.data.settings.detectionfolder,handles.data.settings.detectionSettings);

    if app.RecOptsOK
        deviceReader = audioDeviceReader(app.RecOptsSR,'Device',app.RecOptsMicroph);
        %rate = deviceReader.SampleRate;
        if app.RecOptsRecLgth <= 0
            recTime = inf;
        else
            recTime = app.RecOptsRecLgth;
        end

        % Detect Calls in RT recording?
        if ~strcmp(app.RecOptsNN,'')
            bDet = true;

            [handles.data.settings.detectionfolder,~,~] = fileparts(app.strSaveDetsFile);
            handles.data.settings.detectionSettings = app.RecOptsDetStgs;
            handles.data.saveSettings();
            update_folders(hObject, handles);
            handles = guidata(hObject);  % Get newest version of handles

            % Load neural network
            h = waitbar(0,'Loading neural network...');
            NeuralNetwork=load(app.RecOptsNN);
            [~,NeuralNetwork.netfile,~] = fileparts(app.RecOptsNN);
            NeuralNetwork.netfile = [NeuralNetwork.netfile, '.mat'];
            close(h);

            % Set detection variables
            Settings = str2double(handles.data.settings.detectionSettings);
            % Switched high- and low-freq cutoff order in dialog, but should be back
            % compatible
            % (2) High frequency cutoff (kHz)
            HighCutoff = max(Settings(2),Settings(3));
            if deviceReader.SampleRate < (HighCutoff*1000)*2
                disp('Warning: Upper frequency is above sampling rate / 2. Lowering it to the Nyquist frequency.');
                HighCutoff=floor(deviceReader.SampleRate/2)/1000;
            end
                
            % (3) Low frequency cutoff (kHz)
            LowCutoff = min(Settings(2),Settings(3));
            
            % (4) Score cutoff (kHz) - FOR MERGE BOXES FN
            score_cutoff=Settings(4);

            DetSpect.wind = NeuralNetwork.wind;
            DetSpect.noverlap = NeuralNetwork.noverlap;
            DetSpect.nfft = NeuralNetwork.nfft;
            
            % Adjust settings, so spectrograms are the same for different sample rates
            wind = round(DetSpect.wind * deviceReader.SampleRate);
            noverlap = round(DetSpect.noverlap * deviceReader.SampleRate);
            nfft = round(DetSpect.nfft * deviceReader.SampleRate);

            % Initialize variables
            AllBoxes=[];
            AllScores=[];
            AllClass=[];

            % Set audio read length to image length for network
            readLen = NeuralNetwork.imLength*deviceReader.SampleRate;
            detBuff = zeros(1,readLen);
        else
            bDet = false;
            NeuralNetwork = [];
            % Set audio read length to focus window display size
            readLen = handles.data.settings.focus_window_size*deviceReader.SampleRate;
            detBuff = [];
        end
        
        % lenmove = 20% of buffer (image length)
        lenmove = readLen-floor(readLen*0.8);

        % Setup output file
        audioffn = app.strSaveAudFile;
        % GA Note: Filename extension MUST be lowercase or Matlab throws a
        % huge fit - very stupid
        fileWriter = dsp.AudioFileWriter('SampleRate',deviceReader.SampleRate,'Filename',audioffn,'FileFormat',audioffn(strfind(audioffn,'.')+1:end));

        loop=1;
        audDur = 0;
        tic
        while toc<recTime && eventdata.Source.Value==1
            % Allocate array for one image length/focus window worth of data
            focusSig = zeros(readLen,1);
            fSind = 1;
            release(deviceReader);
            deviceReader = audioDeviceReader(app.RecOptsSR,'Device',app.RecOptsMicroph);
            deviceReader.SamplesPerFrame = 1024;

            setup(deviceReader);
            % Record audio 1024 samples at a time (ML default, seems to
            % need to be small-ish)
            while fSind<length(focusSig)
                fEind = min(fSind+1024-1,length(focusSig));
                if deviceReader.SamplesPerFrame ~= fEind-fSind+1
                    release(deviceReader);
                    deviceReader = audioDeviceReader(app.RecOptsSR,'Device',app.RecOptsMicroph);
                    deviceReader.SamplesPerFrame = fEind-fSind+1;
                end
                [focusSig(fSind:fEind),noverrun] = deviceReader();
                fSind = fSind+1024;
            end

            % Write audio to file
            % This will one day be to spot to stash the audio in a variable
            % rather than writing and reading to file
            % For now, cut-off first 20% of first write because we don't
            % want to release the fileWriter, in which case we can't change
            % the length of focusSig
            if loop == 1
                fileWriter(focusSig(lenmove+1:end));
            else
                fileWriter(focusSig);
            end
            % If first time through, load newly created audio file
            if loop == 1
                audDur = readLen-lenmove;
                windL = 1;

                % Copy audio to detection buffer
                if bDet
                    detBuff = focusSig;
                end

                LoadAudio(hObject,eventdata,handles,audioffn)
                handles = guidata(hObject);
                % Force render on screen
                drawnow

                % Reset variables for future loops
                loop = 2;
                % 80% bc if applying network, need 20% image overlap
                readLen = floor(readLen*0.8);
                % release(fileWriter);
                % fileWriter = dsp.AudioFileWriter('SampleRate',deviceReader.SampleRate,'Filename',audioffn,'FileFormat','FLAC');
            else
                audDur = audDur + readLen;
                windL = audDur - length(detBuff) + 1;
                % Copy audio to detection buffer
                if bDet
                    % MAKE SURE THIS MATH IS RIGHT
                    % Move last 20% to front of buffer
                    detBuff(1:lenmove) = detBuff(readLen+1:end);
                    % Fill in last 80% of new buffer with new signal read
                    detBuff(lenmove+1:end) = focusSig;
                end

                % Sometimes there is a problem applying audiodata - I think
                % possibly the audiofile is locked by a previous call, so I
                % added some pauses to try and give it a chance to unlock.
                % Ideally one day I will have the display accessing the
                % recorded audio directly rather than closing and opening
                % the file every time, but for now hopefully this will let
                % us limp along

                % Update loaded audio information and move focus to display
                % most recently recorded data
                attemptno = 0;
                errno = 0;
                while attemptno == errno && attemptno < 10
                    attemptno = attemptno+1;
                    try
                        % Update audiodata
                        handles.data.audiodata = audioinfo(audioffn);
                    catch
                        errno = errno+1;
                        if attemptno == 10
                            error('Problem getting audioinfo - talk to GA')
                        end
                        pause(1/1000);
                    end
                end
                guidata(hObject, handles);
                % Scroll display
                MoveFocus(readLen/deviceReader.SampleRate, hObject, eventdata, handles, true)
                % Force render on screen
                drawnow
            end
            % NEXT TIME CONTINUE HERE ASSUMING detBuff ABOVE IS CORRECT;
            % USE DETECTINFILE TO CONTINUE FILLING IN PIECES
            if bDet && loop ~= 1
                % Create spectrogram out of audio segment
                [~,fr,ti,p] = spectrogram(detBuff,wind,noverlap,nfft,deviceReader.SampleRate,'yaxis');
                % Air on the side of generosity with the bin cut-offs given
                % spectrogram settings
                upper_freq = find(fr>HighCutoff*1000,1,'first');
                lower_freq = find(fr<LowCutoff*1000,1,'last');
                % Account for buffer overflow in either direction
                if isempty(upper_freq)
                    upper_freq = length(fr);
                end
                if isempty(lower_freq)
                    lower_freq = 1;
                end
                disp(['Freq cut-offs (given spec settings) set to ' num2str(fr(lower_freq)) ' Hz and ' num2str(fr(upper_freq)) ' Hz']);
                pow = p(lower_freq:upper_freq,:);
        
                [nbboxes, scores, Class] = DetectChunk(pow,NeuralNetwork);

                if ~isempty(nbboxes)
                    % Convert boxes from pixels to time and kHz
                    bboxes = [];
                    bboxes(:,1) = ti(nbboxes(:,1)) + (windL ./ deviceReader.SampleRate);
                    bboxes(:,2) = fr(upper_freq - (nbboxes(:,2) + nbboxes(:,4))) ./ 1000;
                    bboxes(:,3) = ti(nbboxes(:,3));
                    %bboxes(:,4) = fr(nbboxes(:,4)) ./ 1000;
                    binwidth = (fr(2)-fr(1)) ./ 1000;
                    bboxes(:,4) = single(nbboxes(:,4)).*binwidth;
                    
                    % Concatenate the results
                    AllBoxes=[AllBoxes
                        bboxes];
                    AllScores=[AllScores
                        scores];
                    AllClass=[AllClass
                        Class];
    
                    % Merge boxes and send Calls info to handles
                    if ~isempty(AllBoxes)
                        Calls = merge_boxes(AllBoxes, AllScores, AllClass, DetSpect, 1, score_cutoff, 0, handles.data.audiodata, audDur, deviceReader.SampleRate);
                        if ~isequaln(Calls,handles.data.calls)
                            handles.data.calls = Calls;
                            % Force render if RT (calls guidata)
                            update_fig(hObject, handles, true);
                        end
                    end
                end
            end
        end
        % Release drivers
        release(deviceReader);
        release(fileWriter);
        % Prevent user interaction until next drawnow command - not sure
        % what the point of this is
        %drawnow nocallbacks;

        if bDet
            if ~isempty(Calls)
                detection_metadata = struct(...
                    'Settings', Settings,...
                    'detectiontime', datestr(datetime('now'),'yyyy-mm-dd HH_MM PM'),...
                    'networkselection', {NeuralNetwork.netfile});
                spect = handles.data.settings.spect;
                allAudio = audioinfo(audioffn);
                save(app.strSaveDetsFile,'Calls','allAudio','detection_metadata','spect','-v7.3','-mat');
            end
            % Check to save new det file
            %CheckModified(hObject,eventdata,handles);
            % Update handles with changes in CheckModified
            handles = guidata(hObject);
        end
    else
        msgbox('Problem setting Record Options')
    end
end

hObject.String='Record Audio';
hObject.BackgroundColor=[0.20,0.83,0.10];
eventdata.Source.Value=0;
update_folders(hObject, handles);