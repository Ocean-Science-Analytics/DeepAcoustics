function Calls = AddDateTime(Calls,audiodata,detname)

vecStTime = Calls.StTime;
for i = 1:height(Calls)
    % Skip if D/T already assigned
    if isnat(vecStTime(i))
        audioname = audiodata.Filename;
        % Get only the filename (not path)
        [~,audioname,~] = fileparts(audioname);
        
        % Try to figure out Date/Time of start of Detections.mat using audio file
        % First, count pairs of numbers (need at least 10 for four-digit time, 12
        % for six-digit time)
        thisdt = [];
        [nPairs,~] = regexp(audioname,'([0-9]{2})','tokens','match');
        nPairs = size(nPairs,2);
        if nPairs >= 6
            % First look for YYYYMMDD.*HHMMSS
            [thisdt,~] = regexp(audioname,'([0-9]{8}).*([0-9]{6})','tokens','match');
            % If failure, then try YYMMDD.*HHMMSS
            if isempty(thisdt)
                % Look for YYMMDD.*HHMMSS
                [thisdt,~] = regexp(audioname,'([0-9]{6})','tokens','match');
                % If failure, then try YYMMDD.*HHMM
                if size(thisdt,2) < 2
                    [thisdt,~] = regexp(audioname,'([0-9]{6}).*([0-9]{4})','tokens','match');
                    if ~isempty(thisdt)
                        % Unnest (assume last array contains date/time) (ST)
                        thisdt = thisdt{end};
                        thissec = 0;
                    end
                % If success
                else
                    % Assume the last two arrays contain the date/time (ST)
                    thisdt = thisdt(end-1:end);
                    % Unnest
                    thisdt{1} = thisdt{1}{1};
                    thisdt{2} = thisdt{2}{1};
                    thissec = str2double(thisdt{2}(5:6));
                end
            else
                % Unnest (assume last array contains date/time) (ST)
                thisdt = thisdt{end};
                if ~strcmp(thisdt{1}(1:2),'20')
                    if strcmp(thisdt{1}(1:2),'19')
                        warning('Ask Gabi about integrating data from the 90s')
                        break
                    else
                        warning('Date/time format not recognizable - please use YYMMDD.*HHMMSS in your audio file or talk to Gabi about your particular D/T format')
                        break
                    end
                end
                % Get rid of lead year
                thisdt{1} = thisdt{1}(end-5:end);
                thissec = str2double(thisdt{2}(5:6));
            end
        % Try looking for YYMMDD.*HHMM
        elseif nPairs >= 5
            [thisdt,~] = regexp(audioname,'([0-9]{6}).*([0-9]{4})','tokens','match');
            if ~isempty(thisdt)
                % Unnest (assume last array contains date/time) (ST)
                thisdt = thisdt{end};
                thissec = 0;
            end
        end
        % If all failure (and not just drawing boxes), ask for user input
        if isempty(thisdt)
            if nargin > 1
                answer = questdlg({'Auto detect failed. Would you like to manually input the start date/time of the following file?:'; ...
                    detname},'Manual Input Date/Time','Yes','No','Yes');
                switch answer
                    case 'Yes'
                        dlg_title = 'Custom Input';
                        num_lines=[1 length(dlg_title)+30];
                        dlgin = inputdlg({'Year (2-digit):','Month (2-digit):','Day:',...
                            'Hour:','Minute:','Second:'},...
                            dlg_title, num_lines); 
                        if ~isempty(dlgin)
                            thisdt = {[dlgin{1} dlgin{2} dlgin{3}] [dlgin{4} dlgin{5} dlgin{6}]};
                            thissec = str2double(thisdt{2}(5:6));
                        end
                end
            end
        end
    
        % Stash d/t variables and do a sanity check
        if ~isempty(thisdt)
            % Fill in variables from filename (seconds taken care of already)
            thisyr = str2double(thisdt{1}(1:2));
            thismo = str2double(thisdt{1}(3:4));
            thisday = str2double(thisdt{1}(5:6));
            thishr = str2double(thisdt{2}(1:2));
            thismin = str2double(thisdt{2}(3:4));
    
            % Sanity check of date/time
            % Check year
            bNope = thisyr > (year(datetime('today'))-2000);
            % Check month
            bNope = bNope | (thismo < 1 || thismo > 12);
            % Check day
            bNope = bNope | (thisday < 1 || thisday > 31);
            % Check hour
            bNope = bNope | (thishr > 23);
            % Check min
            bNope = bNope | (thismin > 59);
            % Check sec
            bNope = bNope | (thissec > 59);
        end
        
        % Warning if problem
        if isempty(thisdt) || bNope
            warning('Date/time format not recognizable - please use YYMMDD.*HHMMSS in your audio file or talk to Gabi about your particular D/T format')
            break
        end
        
        filest = datetime(thisyr+2000,thismo,thisday,thishr,thismin,thissec,'Format','yyyy-MM-dd HH:mm:ss.SSS');
        vecStTime(i) = filest+Calls.Box(i,1)/86400;
    end
end

Calls.StTime = vecStTime;
