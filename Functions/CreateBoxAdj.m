function [Calls] = CreateBoxAdj(Calls, allAudio)

% Set up adjusted box variable
Calls.BoxAdj = Calls.Box;

nCumulDur = 0;
for i = 2:length(allAudio)
    % Accumulate audio durations for BoxAdj
    % Get indices of rows corresponding to the previous audio file
    nPrevFirst = find(strcmp({Calls.Audiodata.Filename},allAudio(i-1)),1,'first');
    nPrevLast = find(strcmp({Calls.Audiodata.Filename},allAudio(i-1)),1,'last');
    % Pull duration of previous audio file
    nCumulDur = nCumulDur + Calls.Audiodata(nPrevFirst).Duration;
    % Adjust calls
    Calls.BoxAdj(nPrevFirst:nPrevLast,1) = Calls.Box(nPrevFirst:nPrevLast,1)+nCumulDur;
end