% pop_exportbids() - Export EEGLAB study into BIDS folder structure
%
% Usage:
%     pop_exportbids(STUDY, 'key', val);
%
% Inputs:
%   bidsfolder - a loaded epoched EEG dataset structure.
%
% Note: 'key', val arguments are the same as the one in bids_export()
% 
% Authors: Arnaud Delorme, SCCN, INC, UCSD, January, 2019

% Copyright (C) Arnaud Delorme, 2019
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
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function com = pop_exportbids(STUDY, varargin)

com = '';
if isempty(STUDY)
    error('BIDS export can only export EEGLAB studies');
end

if nargin < 1
    bidsFolder = uisetdir('Pick a BIDS output folder');
    if isequal(bidsFolder,0), return; end
    
    options = { 'targetdir' bidsFolder };
else
    options = varargin;
end

% get subjects and sessions
% -------------------------
allSubjects = { STUDY.datasetinfo.subject };
allSessions = { STUDY.datasetinfo.session };
uniqueSubjects = unique(allSubjects);
allSessions(cellfun(@isempty, allSessions)) = { 1 };
allSessions = cellfun(@num2str, allSessions, 'uniformoutput', false);
uniqueSessions = unique(allSessions);

% check if STUDY is compatible
% ----------------------------
for iSubj = 1:length(uniqueSubjects)
	indS = strmatch( STUDY.subject{iSubj}, { STUDY.datasetinfo.subject }, 'exact' );
    if length(indS) ~= length(unique(allSessions(indS)))
        error('STUDY is not compatible: some files need to be merged prior to exporting the data as there can only be one file per subject per session in BIDS');
    end
end

% export STUDY to BIDS
% --------------------
allFiles = {};
for iSubj = 1:length(uniqueSubjects)
	indS = strmatch( STUDY.subject{iSubj}, { STUDY.datasetinfo.subject }, 'exact' );
	files = {};
	for iFile = 1:length(indS)
		files{iFile} = fuillfile( STUDY.datasetinfo(indS(iFile)).filepath, STUDY.datasetinfo(indS(iFile)).filename);
	end
	if length(files) == 1, files = files{1}; end
	allfiles{end+1} = files;
end
bids_export(allfiles, options{:});

% history
% -------
if nargin < 1
    com = sprintf('pop_exportbids(STUDY, %s);', vararg2str(options));
end