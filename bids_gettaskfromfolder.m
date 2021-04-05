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

function tasklist = bids_gettaskfromfolder(bidsFolder)

tasklist = {};
if exist(bidsFolder, 'dir') && bidsFolder(end) ~= '.'
    files = dir(bidsFolder);
    [files(:).folder] = deal(bidsFolder);
    %fprintf('Scanning %s\n', bidsFolder);
    for iFile = 1:length(files)
        tasklistTmp = bids_gettaskfromfolder(fullfile(files(iFile).folder, fullfile(files(iFile).name)));
        if ~isempty(tasklistTmp)
            newTasks = tasklistTmp(~ismember(tasklistTmp, tasklist));
            if ~isempty(newTasks)
                tasklist = [ tasklist newTasks ];
            end
        end
    end
else
    if ~isempty(strfind(bidsFolder, 'eeg')) && ~isempty(strfind(bidsFolder, 'task'))
        pos = strfind(bidsFolder, 'task');
        tmpStr = bidsFolder(pos+5:end);
        underS = find(tmpStr == '_');
        tasklist = { tmpStr(1:underS(1)-1) };
    end
end
