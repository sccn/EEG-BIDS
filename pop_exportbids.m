% pop_exportbids() - Export EEGLAB study into BIDS folder structure
%
% Usage:
%     pop_exportbids(STUDY, ALLEEG, 'key', val);
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

function [STUDY,EEG,comOut] = pop_exportbids(STUDY, EEG, varargin)

comOut = '';
if isempty(STUDY)
    error('BIDS export can only export EEGLAB studies');
end
if nargin < 2
    error('This function needs at least 2 parameters');
end

if nargin < 3 && ~ischar(STUDY)
    com = [ 'bidsFolderxx = uigetdir(''Pick a BIDS output folder'');' ...
            'if ~isequal(bidsFolderxx, 0), set(findobj(gcbf, ''tag'', ''outputfolder''), ''string'', bidsFolderxx); end;' ...
            'clear bidsFolderxx;' ];
            
    cb_task         = 'pop_exportbids(''edit_task'', gcbf);';
    cb_eeg          = 'pop_exportbids(''edit_eeg'', gcbf);';
    cb_participants = 'pop_exportbids(''edit_participants'', gcbf);';
    cb_events       = 'pop_exportbids(''edit_events'', gcbf);';
    uilist = { ...
        { 'Style', 'text', 'string', 'Export EEGLAB study to BIDS', 'fontweight', 'bold'  }, ...
        {} ...
        { 'Style', 'text', 'string', 'Output folder:' }, ...
        { 'Style', 'edit', 'string',   fullfile('.', 'BIDS_EXPORT') 'tag' 'outputfolder' }, ...
        { 'Style', 'pushbutton', 'string', '...' 'callback' com }, ...
        { 'Style', 'text', 'string', 'Licence for distributing:' }, ...
        { 'Style', 'edit', 'string', 'Creative Common 0 (CC0)' 'tag' 'license'  }, ...
        { 'Style', 'text', 'string', 'CHANGES compared to previous releases:' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'changes'  'HorizontalAlignment' 'left' 'max' 3   }, ...
        { 'Style', 'pushbutton', 'string', 'Edit task & EEG info' 'tag' 'task' 'callback' cb_task }, ...
        { 'Style', 'pushbutton', 'string', 'Edit participants' 'tag' 'participants' 'callback' cb_participants }, ...
        { 'Style', 'pushbutton', 'string', 'Edit event info' 'tag' 'events' 'callback' cb_events }, ...
        { 'Style', 'checkbox', 'string', 'Do not use participants IDs and create anonymized participants IDs instead' 'tag' 'newids' }, ...
        };
    relSize = 0.7;
    geometry = { [1] [1] [1-relSize relSize*0.8 relSize*0.2] [1-relSize relSize] [1] [1] [1 1 1] [1]};
    geomvert =   [1  0.2 1                                                   1  1   3    1        1];
    userdata.EEG = EEG;
    userdata.STUDY = STUDY;
    [results,userdata,~,restag] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', uilist, 'helpcom', 'pophelp(''pop_exportbids'');', 'title', 'Export EEGLAB STUDY to BIDS -- pop_exportbids()', 'userdata', userdata );
    if length(results) == 0, return; end
    STUDY  = userdata.STUDY;
    EEG = userdata.EEG;

    % decode some outputs
    if ~isempty(strfind(restag.license, 'CC0')), restag.license = 'CC0'; end
%     if ~isempty(restag.authors)
%         authors = textscan(restag.authors, '%s', 'delimiter', ';');
%         authors = authors{1}';
%     else
%         authors = { '' };
%     end
    
    % options
    options = { 'targetdir' restag.outputfolder 'License' restag.license 'CHANGES' restag.changes 'createids' fastif(restag.newids, 'on', 'off') 'individualEventsJson' 'off'};
    
    if ~isfield(EEG(1), 'BIDS') % none of the edit button was clicked
        EEG = pop_eventinfo(EEG, STUDY, 'default');
        EEG = pop_participantinfo(EEG, STUDY, 'default');
        EEG = pop_taskinfo(EEG, 'default');
    end
    if isempty(STUDY.task)
        uiList = { { 'style' 'text' 'string' 'Task name (no space, dash, underscore, or special chars)' } ...
                   { 'style' 'edit' 'string' ''} };
        res = inputgui('title', 'Missing required information', 'uilist', uiList, 'geometry', {[ 1 0.4 ]});
        if isempty(res), return; end
        if isempty(res{1})
            error('A task name is required')
        end
        STUDY.task = res{1};
    end
    if ~isfield(EEG(1).BIDS.tInfo, 'PowerLineFrequency') || isnan(EEG(1).BIDS.tInfo.PowerLineFrequency)
        uiList = { { 'style' 'text' 'string' 'You must specify power line frequency' } ...
                   { 'style' 'popupmenu' 'string' {'50' '60' }} };
        res = inputgui('title', 'Missing required information', 'uilist', uiList, 'geometry', {[ 1 0.4 ]});
        if isempty(res), return; end
        for iEEG = 1:length(EEG)
            if res{1} == 1
                EEG(iEEG).BIDS.tInfo.PowerLineFrequency = 50;
            else
                EEG(iEEG).BIDS.tInfo.PowerLineFrequency = 60;
            end
            EEG(iEEG).saved = 'no';
        end
    end

elseif ischar(STUDY)
    command = STUDY;
    fig = EEG;
    userdata = get(fig, 'userdata');
    switch command
        case 'edit_participants'
            userdata.EEG = pop_participantinfo(userdata.EEG);
        case 'edit_events'
            userdata.EEG = pop_eventinfo(userdata.EEG);
        case 'edit_task'
            userdata.EEG  = pop_taskinfo(userdata.EEG);
        case 'edit_eeg'
            userdata.EEG = pop_eegacqinfo(userdata.EEG);
    end
    set(fig, 'userdata', userdata);
    return
else
    options = varargin;
end
  
% rearrange information in BIDS structures
if ~isfield(EEG, 'BIDS')
    EEG(1).BIDS = struct([]);
end
if isfield(EEG(1).BIDS, 'gInfo') && isfield(EEG(1).BIDS.gInfo,'README')
    options = [options 'README' {EEG(1).BIDS.gInfo.README}];
    EEG(1).BIDS.gInfo = rmfield(EEG(1).BIDS.gInfo,'README');
end
if isfield(EEG(1).BIDS, 'gInfo') && isfield(EEG(1).BIDS.gInfo,'TaskName')
    options = [options 'taskName' {EEG(1).BIDS.gInfo.TaskName}];
    EEG(1).BIDS.gInfo = rmfield(EEG(1).BIDS.gInfo,'TaskName');
end
if ~isempty(STUDY.task)
    taskTmp = STUDY.task;
    taskTmp(taskTmp == '-') = [];
    taskTmp(taskTmp == '_') = [];
    taskTmp(taskTmp == ' ') = [];
    options = [options { 'taskName' taskTmp }];
end

bidsFieldsFromALLEEG = fieldnames(EEG(1).BIDS); % All EEG should share same BIDS info  -> using EEG(1)
% tInfo.SubjectArtefactDescription is not shared, arguments passed as `notes` below
for f=1:numel(bidsFieldsFromALLEEG)
    if ~isequal(bidsFieldsFromALLEEG{f}, 'behavioral') && ~isequal(bidsFieldsFromALLEEG{f}, 'bidsstats')
        options = [options bidsFieldsFromALLEEG{f} {EEG(1).BIDS.(bidsFieldsFromALLEEG{f})}];
    else
        warning('Warning: cannot re-export behavioral data yet')
    end
end

% get subjects and sessions
% -------------------------
if ~isempty(EEG(1).subject)
    allSubjects = { EEG.subject };
elseif ~isempty(STUDY.datasetinfo(1).subject)
    allSubjects = { STUDY.datasetinfo.subject };
else
    error('No subject info found in either EEG or STUDY.datasetinfo. Please add using Study > Edit STUDY info');
end
if ~isempty(STUDY.datasetinfo(1).session)
    allSessions = { STUDY.datasetinfo.session };
else
    allSessions = { EEG.session };
end
[~,inds] = unique(allSubjects);
uniqueSubjects = allSubjects(sort(inds));
allSessions(cellfun(@isempty, allSessions)) = { 1 };
allSessions = cellfun(@num2str, allSessions, 'uniformoutput', false);
uniqueSessions = unique(allSessions);

% export STUDY to BIDS
% --------------------
pInfo = {}; % each EEG file has its own pInfo --> need to aggregate
if isfield(EEG(1), 'BIDS') && isfield(EEG(1).BIDS,'pInfo') 
    pInfo = EEG(1).BIDS.pInfo(1,:);
end
subjects = struct('file',{}, 'session', [], 'run', [], 'task', {});

% duration field (mandatory)
if ~isempty(EEG(1).event) && ~isfield(EEG(1).event, 'duration')
    for iEEG = 1:length(EEG)
        EEG(iEEG).event(1).duration = [];
        EEG(iEEG).saved = 'no';
    end
end

% resave dataset
fileAbsent = any(cellfun(@isempty, { EEG.filename }));
if fileAbsent
    error('Datasets need to be saved before being exported');
end
saved = any(cellfun(@(x)isequal(x, 'no'), { EEG.saved }));

for iSubj = 1:length(uniqueSubjects)
    indS = strmatch( uniqueSubjects{iSubj}, allSubjects, 'exact' );
    for iFile = 1:length(indS)
        subjects(iSubj).file{iFile} = fullfile( EEG(indS(iFile)).filepath, EEG(indS(iFile)).filename);

        if isfield(EEG(indS(iFile)), 'session') && ~isempty(EEG(indS(iFile)).session)
            subjects(iSubj).session(iFile) = EEG(indS(iFile)).session;
        else
            subjects(iSubj).session(iFile) = iFile;
        end
        if isfield(EEG(indS(iFile)), 'run') && ~isempty(EEG(indS(iFile)).run)
            subjects(iSubj).run(iFile) = EEG(indS(iFile)).run;
        else
            subjects(iSubj).run(iFile) = 1;  % Assume only one run
        end
        if isfield(EEG(indS(iFile)), 'task') && ~isempty(EEG(indS(iFile)).task)
            subjects(iSubj).task{iFile} = EEG(indS(iFile)).task; 
            % blank task field will be filled in bids_export.m
        end
        if isfield(EEG(indS(iFile)).BIDS, 'tInfo') && isfield(EEG(indS(iFile)).BIDS.tInfo, 'SubjectArtefactDescription')...
                && ~isempty(EEG(indS(iFile)).BIDS.tInfo.SubjectArtefactDescription)
            subjects(iSubj).notes{iFile} = EEG(indS(iFile)).BIDS.tInfo.SubjectArtefactDescription;
        end
    end
    if isfield(EEG(indS(1)), 'BIDS') && isfield(EEG(indS(1)).BIDS,'pInfo')
        pInfo = [pInfo; EEG(indS(1)).BIDS.pInfo(2,:)];
    end
end
if ~isempty(pInfo)
    options = [options 'pInfo' {pInfo}];
end
if nargin < 3
    bids_export(subjects, 'interactive', 'on', options{:});
else
    bids_export(subjects, options{:});
end
disp('Done');

% history
% -------
if nargin < 3
    % Issue: README file and other inserted as plain text
    % The history should have the relevant fields
    % comOut = sprintf('pop_exportbids(STUDY, %s);', vararg2str(options));
end
