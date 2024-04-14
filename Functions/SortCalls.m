function [Calls,call_index] = SortCalls(Calls, sort_type, call_index)

if nargin < 3
    call_index = 0;
end
% First sort by selected variable
switch sort_type
    case 'score'
        [~,idx] = sort(Calls.Score);
    case 'time'
        [~,idx] = sortrows(Calls.Box, 1);
    case 'duration'
        [~,idx] = sortrows(Calls.Box, 4);
    case 'frequency'
        [~,idx] = sort(sum(Calls.Box(:, [2, 2, 4]), 2));
end
if call_index > 0
    call_index = find(idx == call_index); 
end
Calls = Calls(idx, :);

% Then sort by audio file (should preserve order of previous sort within an
% audio file
%[~,idx] = sort({Calls.Audiodata.Filename});
% if call_index > 0
%     call_index = find(idx == call_index); 
% end
% Calls = Calls(idx, :);

end