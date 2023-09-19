% bids_gettaskfromfolder() - Scan bids folders to get the list of tasks
%
% Usage:
%   >> tasklist = bids_gettaskfromfolder(bidsfolder);
%
% Inputs:
%   bidsfolder - a loaded epoched EEG dataset structure.
%
% Outputs:
%   tasklist   - [cell array] list of tasks
%
% Authors: Arnaud Delorme, SCCN, INC, UCSD, March, 2021

% Copyright (C) Arnaud Delorme, 2021
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [tasklist,sessions,runs] = bids_getinfofromfolder(bidsFolder)

tasklist = {};
sessions = {};
runs     = {};
files = dir(bidsFolder);
[files(:).folder] = deal(bidsFolder);
%fprintf('Scanning %s\n', bidsFolder);
for iFile = 1:length(files)
    if files(iFile).isdir && files(iFile).name(end) ~= '.' && length(files(iFile).name) > 2 &&  ~isequal(lower(files(iFile).name(end-2:end)), '.ds')
        if length(files(iFile).name) > 2 && strcmpi(files(iFile).name(1:3), 'ses')
            sessions = union(sessions, { files(iFile).name });
        end

        [tasklistTmp,sessionTmp,runsTmp] = bids_getinfofromfolder(fullfile(files(iFile).folder, fullfile(files(iFile).name)));
        tasklist = union(tasklist, tasklistTmp);
        sessions = union(sessions, sessionTmp);
        runs     = union(runs    , runsTmp);
     else
        if (~isempty(strfind(files(iFile).name, 'eeg')) || ~isempty(strfind(files(iFile).name, 'meg'))) && ~isempty(strfind(files(iFile).name, '_task'))
            pos = strfind(files(iFile).name, '_task');
            tmpStr = files(iFile).name(pos+6:end);
            underS = find(tmpStr == '_');
            newTask = tmpStr(1:underS(1)-1);
            tasklist = union( tasklist, { newTask });
        end
        if (~isempty(strfind(files(iFile).name, 'eeg')) || ~isempty(strfind(files(iFile).name, 'meg')))  && ~isempty(strfind(files(iFile).name, '_run'))
            pos = strfind(files(iFile).name, '_run');
            tmpStr = files(iFile).name(pos+5:end);
            underS = find(tmpStr == '_');
            newRun = tmpStr(1:underS(1)-1);
            runs = union( runs, { newRun } );
        end
    end
end
