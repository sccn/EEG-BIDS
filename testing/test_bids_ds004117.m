clear
if ~exist('pop_loadset')
    eeglab
end

% import data
% -------------
[STUDY, ALLEEG1] = pop_importbids('ds004117'); %, 'runs', 1);

% PROCESS DATA HERE
bids_reexport(ALLEEG1, 'checkderivative', 'ds004117', 'forcesession', 'on');


































