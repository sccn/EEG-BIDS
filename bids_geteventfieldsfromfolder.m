% bids_geteventfiledsfromfolder() - Scan bids folders recursively to get the list of event fields
%                                   from the first events.tsv file
%
% Usage:
%   >> fields = bids_geteventfieldsfromfolder(bidsfolder);
%
% Inputs:
%   bidsfolder - a loaded epoched EEG dataset structure.
%
% Outputs:
%   fields   - [cell array] list of event fields in events.tsv
%
% Authors: Dung Truong, Arnaud Delorme, SCCN, INC, UCSD, March, 2022

% Copyright (C) Dung Truong, 2022
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

function fields = bids_geteventfieldsfromfolder(bidsFolder)

fields = {};
files = dir(bidsFolder);
[files(:).folder] = deal(bidsFolder);
%fprintf('Scanning %s\n', bidsFolder);
for iFile = 1:length(files)
    if files(iFile).isdir && files(iFile).name(1) ~= '.'
        fieldlistTmp = bids_geteventfieldsfromfolder(fullfile(files(iFile).folder, fullfile(files(iFile).name)));
        if ~isempty(fieldlistTmp)
            fieldsTmp = setdiff(fieldlistTmp, {'onset', 'duration', 'sample', 'stim_file', 'response_time'});
            fields = union(fields, fieldsTmp);
        end
    else
        if ~isempty(strfind(files(iFile).name, 'events.tsv'))
             res = loadtxt( fullfile(files(iFile).folder, files(iFile).name), 'verbose', 'off', 'delim', 9, 'convert', 'off');
             fields = union(fields, res(1,:));
%             % other solutions
%             res = readtable( fullfile(files(iFile).folder, files(iFile).name), 'filetype', 'delimitedtext', 'delimiter', char(9));
%             fields = union(fields, fieldnames(res)); % has additional fields Properties, Rows and Variables that need to be removeds
        end
    end
end
