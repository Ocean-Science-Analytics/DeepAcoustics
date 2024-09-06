function [Calls] = CreateBoxAdj(Calls, allAudio)

% Set up adjusted box variable
Calls.BoxAdj = Calls.Box;

[~,CallsFNOnly,~] = fileparts({Calls.Audiodata.Filename});

nCumulDur = 0;
for i = 2:length(allAudio)
    % Accumulate audio durations for BoxAdj
    % Pull duration of previous audio file
    nCumulDur = nCumulDur + allAudio(i-1).Duration;
    % Get indices of rows corresponding to the previous audio file
    [~,aAFNOnly,~] = fileparts(allAudio(i).Filename); 
    nFirst = find(strcmp(CallsFNOnly,aAFNOnly),1,'first');
    nLast = find(strcmp(CallsFNOnly,aAFNOnly),1,'last');
    if ~isempty(nFirst)
        % Adjust calls
        Calls.BoxAdj(nFirst:nLast,1) = Calls.Box(nFirst:nLast,1)+nCumulDur;
    end
end