function Calls = AddDateTime(Calls,audiodata,detname)

audioname = audiodata.Filename;
% Get only the filename (not path)
[~,audioname,~] = fileparts(audioname);

% Try to figure out Date/Time of start of Detections.mat using audio file
% First look for YYMMDD.*HHMMSS
[thisdt,~] = regexp(audioname,'([0-9]{6}).*([0-9]{6})','tokens','match');
% If failure, then try YYMMDD.*HHMM
if isempty(thisdt)
    [thisdt,~] = regexp(audioname,'([0-9]{6}).*([0-9]{4})','tokens','match');
    if ~isempty(thisdt)
        thissec = 0;
    else
        answer = questdlg({'Auto detect failed. Would you like to manually input the start date/time of the following file?:'; ...
            detname},'Manual Input Date/Time','Yes','No','Yes');
        switch answer
            case 'Yes'
                dlgin = inputdlg({'Year (2-digit):','Month (2-digit):','Day:',...
                    'Hour:','Minute:','Second:'},...
                      'Custom Input', [1 30; 1 30; 1 30; 1 30; 1 30; 1 30]); 
                if ~isempty(dlgin)
                    thisdt = {{[dlgin{1} dlgin{2} dlgin{3}] [dlgin{4} dlgin{5} dlgin{6}]}};
                    thissec = str2double(thisdt{1}{2}(5:6));
                end
        end
    end
else
    thissec = str2double(thisdt{1}{2}(5:6));
end

% Stash d/t variables and do a sanity check
if ~isempty(thisdt)
    % Fill in variables from filename (seconds taken care of already)
    thisyr = str2double(thisdt{1}{1}(1:2));
    thismo = str2double(thisdt{1}{1}(3:4));
    thisday = str2double(thisdt{1}{1}(5:6));
    thishr = str2double(thisdt{1}{2}(1:2));
    thismin = str2double(thisdt{1}{2}(3:4));

    % Sanity check of date/time
    % Check year
    bNope = thisyr > 99;
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

% Error if problem
if isempty(thisdt) || bNope
    warning('Date/time format not recognizable - please use YYMMDD.*HHMMSS in your audio file or talk to Gabi about your particular D/T format')
    return
end

filest = datetime(thisyr+2000,thismo,thisday,thishr,thismin,thissec,'Format','yyyy-MM-dd HH:mm:ss.SSS');
Calls.StTime = filest+Calls.Box(:,1)/86400;