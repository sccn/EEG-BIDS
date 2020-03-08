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

if nargin < 2
    com = [ 'bidsFolderxx = uigetdir(''Pick a BIDS output folder'');' ...
            'if ~isequal(bidsFolderxx, 0), set(findobj(gcbf, ''tag'', ''outputfolder''), ''string'', bidsFolderxx); end;' ...
            'clear bidsFolderxx;' ];
            
    uilist = { ...
        { 'Style', 'text', 'string', 'Export EEGLAB study to BIDS', 'fontweight', 'bold'  }, ...
        {} ...
        { 'Style', 'text', 'string', 'Output folder:' }, ...
        { 'Style', 'edit', 'string',   fullfile('.', 'BIDS_EXPORT') 'tag' 'outputfolder' }, ...
        { 'Style', 'pushbutton', 'string', '...' 'callback' com }, ...
        { 'Style', 'text', 'string', 'Experiment name:' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'name' }, ...
        { 'Style', 'text', 'string', 'Reference and link:' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'refs'  }, ...
        { 'Style', 'text', 'string', 'Authors (A Lee; B Lin):' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'authors'  }, ...
        { 'Style', 'text', 'string', 'Licence for distributing:' }, ...
        { 'Style', 'edit', 'string', 'Creative Common 0 (CC0)' 'tag' 'license'  }, ...
        { 'Style', 'text', 'string', 'README (describe experiment in a one or two sentences):' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'readme' 'HorizontalAlignment' 'left' 'max' 3 }, ...
        { 'Style', 'text', 'string', 'CHANGES (current and previous version information):' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'changes'  'HorizontalAlignment' 'left' 'max' 3   }, ...
        };
    relSize = 0.7;
    geometry = { [1] [1] [1-relSize relSize*0.8 relSize*0.2] [1-relSize relSize] [1-relSize relSize] [1-relSize relSize] [1-relSize relSize] [1] [1] [1] [1]};
    geomvert =   [1  0.2 1         1           1           1           1           1   3   1   3 ];
    [results,~,~,restag] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', uilist, 'helpcom', 'pophelp(''pop_exportbids'');', 'title', 'Export EEGLAB STUDY to BIDS -- pop_exportbids()' );
    if length(results) == 0, return; end
    
    % decode some outputs
    if ~isempty(strfind(restag.license, 'CC0')), restag.license = 'CC0'; end
    if ~isempty(restag.authors)
        authors = textscan(restag.authors, '%s', 'delimiter', ';');
        authors = authors{1}';
    else
        authors = { '' };
    end
    
    % options
    options = { 'targetdir' restag.outputfolder 'Name' restag.name 'ReferencesAndLinks' { restag.refs } 'License' restag.license 'Authors' authors 'README' restag.readme 'CHANGES' restag.changes };
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
files = struct('file',{}, 'session', [], 'run', []);
for iSubj = 1:length(uniqueSubjects)
    indS = strmatch( STUDY.subject{iSubj}, { STUDY.datasetinfo.subject }, 'exact' );
    for iFile = 1:length(indS)
        files(iSubj).file{iFile} = fullfile( STUDY.datasetinfo(indS(iFile)).filepath, STUDY.datasetinfo(indS(iFile)).filename);
        files(iSubj).session(iFile) = iFile; % In this tool we allow only one file per session. Number of session = length(files per subject)
        files(iSubj).run(iFile) = 1; % In this tool we allow only one file per session -> run = 1
    end
end
bids_export(files, options{:});

% history
% -------
if nargin < 1
    com = sprintf('pop_exportbids(STUDY, %s);', vararg2str(options));
end