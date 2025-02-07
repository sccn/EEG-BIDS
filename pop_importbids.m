% POP_IMPORTBIDS - Import BIDS format folder structure into an EEGLAB
%                    study.
% Usage:
%   >> [STUDY ALLEEG] = pop_importbids(bidsfolder);
%   >> [STUDY ALLEEG] = pop_importbids(bidsfolder, 'key', value);
%
% Inputs:
%   bidsfolder - a loaded epoched EEG dataset structure.
%     options are 'bidsevent', 'bidschanloc' of be turned 'on' (default) or 'off'
%                 'outputdir' default is bidsfolder/derivatives/eeglab
%                 'studyName' default is eeg
%
% Optional inputs:
%  'studyName'   - [string] name of the STUDY
%  'subjects'    - [cell array] indices or names of subjects to import
%  'sessions'    - [cell array] session numbers or names to import
%  'runs'        - [cell array] run numbers or names to import
%  'bidsevent'   - ['on'|'off'] import events from BIDS .tsv file and
%                  ignore events in raw binary EEG files.
%  'bidschanloc' - ['on'|'off'] import channel location from BIDS .tsv file
%                  and ignore locations (if any) in raw binary EEG files.
%  'outputdir'   - [string] output folder (default is to use the BIDS
%                  folders).
%  'eventtype'   - [string] BIDS event column to use for EEGLAB event types.
%                  common choices are usually 'trial_type' or 'value'.
%                  Default is 'value'.
%  'bidstask'    - [string] value of a key task- allowing to analyze some
%                  tasks only
%  'metadata'    - ['on'|'off'] only import metadata. Default 'off'.
%  'ctffunc'     - ['fileio'|'ctfimport'] function to use to import CTF data
%                  Default 'fileio'.
%
% Outputs:
%   STUDY   - EEGLAB STUDY structure
%   ALLEEG  - EEGLAB ALLEEG structure
%   bids    - BIDS structure (same as ALLEEG(i).BIDS
%   stats   - BIDS metadata statistics structure
%
% Authors: Arnaud Delorme, SCCN, INC, UCSD, January, 2019
%         Cyril Pernet, University of Edinburgh
%
% Example:
% pop_importbids('/data/matlab/bids_matlab/rishikesh_study/BIDS_EEG_meditation_experiment');

% Copyright (C) Arnaud Delorme, 2018
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

function [STUDY, ALLEEG, bids, stats, commands] = pop_importbids(bidsFolder, varargin)

STUDY = [];
ALLEEG = [];
bids = [];
stats = [];
commands = '';
if nargin < 1
    bidsFolder = uigetdir('Pick a BIDS folder');
    if isequal(bidsFolder,0), return; end
    
    cb_select = [ 'tmpfolder = uigetdir;' ...
        'if ~isequal(tmpfolder, 0)' ...
        '   set(findobj(gcbf, ''tag'', ''folder''), ''string'', tmpfolder);' ...
        'end;' ...
        'clear tmpfolder;' ];
    type_fields = { 'value' 'trial_type' 'event_kind' 'event_type' };
    
    disp('Scanning folders...');
    % scan if multiple tasks are present
    [tasklist,sessions,runs] = bids_getinfofromfolder(bidsFolder);
    % scan for event fields
    type_fields = bids_geteventfieldsfromfolder(bidsFolder);
    indVal = strmatch('value', type_fields);
    if ~isempty(indVal)
        type_fields(indVal) = [];
        type_fields = {'value' type_fields{:} };
    end

    bids_event_toggle = ~isempty(type_fields);
    if isempty(type_fields) type_fields = { 'n/a' }; end
    if isempty(tasklist) tasklist = { 'n/a' }; end
    
    cb_event    = 'set(findobj(gcbf, ''userdata'', ''bidstype''), ''enable'', fastif(get(gcbo, ''value''), ''on'', ''off''));';
    cb_task     = 'set(findobj(gcbf, ''userdata'', ''task''    ), ''enable'', fastif(get(gcbo, ''value''), ''on'', ''off''));';
    cb_sess     = 'set(findobj(gcbf, ''userdata'', ''sessions''), ''enable'', fastif(get(gcbo, ''value''), ''on'', ''off''));';
    cb_run      = 'set(findobj(gcbf, ''userdata'', ''runs''    ), ''enable'', fastif(get(gcbo, ''value''), ''on'', ''off''));';
    cb_subjects = 'set(findobj(gcbf, ''userdata'', ''subjects''), ''enable'', fastif(get(gcbo, ''value''), ''on'', ''off''));';
    promptstr    = { ...
        { 'style'  'text'       'string' 'Enter study name (default is BIDS folder name)' } ...
        { 'style'  'edit'       'string' '' 'tag' 'studyName' } ...
        {} ...
        { 'style'  'checkbox'   'string' 'Use BIDS electrode.tsv files (when present) for channel locations; off: look up locations using channel labels' 'tag' 'chanlocs' 'value' 1 } ...
        { 'style'  'checkbox'   'string' 'Use BIDS event.tsv files for events and use the following BIDS field for event type' 'tag' 'events' 'value' bids_event_toggle 'callback' cb_event } ...
        { 'style'  'popupmenu'  'string' type_fields 'tag' 'typefield' 'value' 1 'userdata' 'bidstype'  'enable' fastif(bids_event_toggle, 'on', 'off') } ...
        { 'style'  'checkbox'   'string' 'Import only the following BIDS tasks' 'tag' 'bidstask' 'value' 0 'callback' cb_task } ...
        { 'style'  'popupmenu'  'string' tasklist 'tag' 'bidstaskstr' 'value' 1 'userdata' 'task'  'enable' 'off' } {} ...
        { 'style'  'checkbox'   'string' 'Import only the following sessions' 'tag' 'bidssessions' 'value' 0 'callback' cb_sess }  ...
        { 'style'  'listbox'    'string' sessions 'tag' 'bidsessionstr' 'max' 2 'value' [] 'userdata' 'sessions'  'enable' 'off' } {} ...
        { 'style'  'checkbox'   'string' 'Import only the following runs' 'tag' 'bidsruns' 'value' 0 'callback' cb_run }  ...
        { 'style'  'listbox'    'string' runs 'tag' 'bidsrunsstr' 'max' 2 'value' [] 'userdata' 'runs'  'enable' 'off' } {} ...
        { 'style'  'checkbox'   'string' 'Import only the following participant indices' 'tag' 'bidssubjects' 'value' 0 'callback' cb_subjects }  ...
        { 'style'  'edit'       'string' '' 'tag' 'bidssubjectsstr' 'userdata' 'subjects'  'enable' 'off' } {} ...
        {} ...
        { 'style'  'text'       'string' 'Study output folder' } ...
        { 'style'  'edit'       'string' fullfile(bidsFolder, 'derivatives', 'eeglab') 'tag' 'folder' 'HorizontalAlignment' 'left' } ...
        { 'style'  'pushbutton' 'string' '...' 'callback' cb_select } ...
        };
    geometry = {[2 1.5], 1, 1,[1 0.35],[0.6 0.35 0.5],[0.6 0.35 0.5],[0.6 0.35 0.5],[0.6 0.35 0.5],1,[1 2 0.5]};
    geomvert = [1 0.5, 1 1 1 1.5 1.5 1 0.5 1];
    if isempty(runs)
        promptstr(13:15) = [];
        geometry(7) = [];
        geomvert(7) = [];
    end
    if isempty(sessions)
        promptstr(10:12) = [];
        geometry(6) = [];
        geomvert(6) = [];
    end
    
    [~,~,~,res] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', promptstr, 'helpcom', 'pophelp(''pop_importbids'')', 'title', 'Import BIDS data -- pop_importbids()');
    if isempty(res), return; end
    
    if ~isempty(type_fields) && ~strcmpi(type_fields{res.typefield}, 'n/a'), options = { 'eventtype' type_fields{res.typefield} }; else options = {}; end
    if res.events,    options = { options{:} 'bidsevent' 'on' };   else options = { options{:} 'bidsevent' 'off' }; end
    if res.chanlocs,  options = { options{:} 'bidschanloc' 'on' }; else options = { options{:} 'bidschanloc' 'off' }; end
    if ~isempty(res.folder),  options = { options{:} 'outputdir' res.folder }; end
    if ~isempty(res.studyName),  options = { options{:} 'studyName' res.studyName }; end
    if res.bidstask     && ~strcmpi(tasklist{res.bidstaskstr}, 'n/a'),  options = { options{:} 'bidstask' tasklist{res.bidstaskstr} }; end
    if isfield(res, 'bidssessions')
        if res.bidssessions && ~isempty(res.bidsessionstr),  options = { options{:} 'sessions' sessions(res.bidsessionstr) }; end
    end
    if isfield(res, 'bidsruns')
        if res.bidsruns && ~isempty(res.bidsruns),  options = { options{:} 'runs' str2double(runs(res.bidsrunsstr)) }; end
    end
    if isfield(res, 'bidssubjects')
        if res.bidsruns && ~isempty(res.bidsruns),  options = { options{:} 'subjects' str2double(res.bidssubjectsstr) }; end
    end
else
    options = varargin;
end

[~,defaultStudyName] = fileparts(bidsFolder);
opt = finputcheck(options, { ...
    'bidsevent'      'string'    { 'on' 'off' }    'on';  ...
    'bidschanloc'    'string'    { 'on' 'off' }    'on'; ...
    'bidscoord'      'string'    { 'on' 'off' }    'on'; ...
    'bidstask'       {'string' 'cell'}    {'',{}}  ''; ...
    'subjects'       {'cell' 'integer'}   {{},[]}  []; ...
    'sessions'       'cell'      {}                {}; ...
    'runs'           {'cell' 'integer'}   {{},[]}  []; ...
    'metadata'       'string'    { 'on' 'off' }    'off'; ...
    'ctffunc'        'string'    { 'fileio' 'ctfimport' }    'fileio'; ...
    'eventtype'      'string'    {  }              'value'; ...
    'outputdir'      'string'    { } fullfile(bidsFolder, 'derivatives', 'eeglab'); ...
    'studyName'      'string'    { }                defaultStudyName ...
    }, 'pop_importbids');
if isstr(opt), error(opt); end

if ~exist('jsondecode.m','file')
   addpath([fileparts(which('pop_importbids.m')) filesep 'JSONio']) 
end

% Options:
% - copy folder
% - use channel location and event

% load change file
changesFile = fullfile(bidsFolder, 'CHANGES');
bids.CHANGES = '';
if exist(changesFile,'File')
    bids.CHANGES = bids_loadfile( changesFile, [], true );
end

% load Readme file
readmeFile = fullfile(bidsFolder, 'README');
bids.README = '';
if exist(readmeFile,'File')
    bids.README = bids_loadfile( readmeFile, [], true );
end

% load dataset description file
dataset_descriptionFile = fullfile(bidsFolder, 'dataset_description.json');
bids.dataset_description = '';
if exist(dataset_descriptionFile,'File')
    bids.dataset_description = bids_loadfile( dataset_descriptionFile );
end

% load participant file
participantsFile = fullfile(bidsFolder, 'participants.tsv');
bids.participants = '';
pInd = 1;
if exist(participantsFile,'File')
    bids.participants = bids_loadfile( participantsFile );
    if ~isempty(bids.participants) && ~isequal(bids.participants{1}, 'participant_id')
        pInd = find(cellfun(@(x)contains(x, 'participant_id'), bids.participants(1,:))); % sometime special chars
        if isempty(pInd)
            error('Cannot find participant_id column')
        end
    end
end
% if no participants.tsv, use subjects folder names as their IDs
if isempty(bids.participants)
    participantFolders = dir(fullfile(bidsFolder, 'sub-*'));
    bids.participants = {'participant_id' participantFolders.name }';
end

bids.participants(strcmp(bids.participants, 'sub-emptyroom'),:) = [];

% load participant sidecar file
participantsJSONFile = fullfile(bidsFolder, 'participants.json');
bids.participantsJSON = '';
if exist(participantsJSONFile,'File')
    bids.participantsJSON = bids_loadfile( participantsJSONFile );
end

% scan participants
count = 1;
commands = {};
task = [ 'task-' bidsFolder ];
bids.data = [];
bids.eventInfo = [];
bids.data.eventdesc = [];
bids.data.eventinfo = [];
inconsistentChannels = 0;
inconsistentEvents   = 0;
faileddatasets = [];

if isempty(opt.subjects)
    opt.subjects = 2:size(bids.participants,1); % indices into the participants.tsv file, ignoring first header row
else
    if iscell(opt.subjects) % match ID to particpiants and return index
        for sub = length(opt.subjects):-1:1
            if contains(opt.subjects{sub},'sub-')
                ID = extractAfter(opt.subjects{sub},'sub-');
            else
                ID = opt.subjects{sub};
            end
            test = find(cellfun(@(x) strcmp(ID,extractAfter(x,'sub-')), bids.participants(2:end,1))); % starts at 2
            if isempty(test)
                warning('sub-%s not found',ID)
            else
                sub_index(sub) = test;
            end
        end
        opt.subjects = sub_index+1;
    else % takes integers in 
        opt.subjects = opt.subjects+1;
    end
end

for iSubject = opt.subjects
    parentSubjectFolder = fullfile(bidsFolder   , bids.participants{iSubject,pInd});
    outputSubjectFolder = fullfile(opt.outputdir, bids.participants{iSubject,pInd});

    iteration = 0;
    while ~exist(parentSubjectFolder, 'dir') && iteration < 3
        fprintf(2, 'Folder %s does not exist\n', parentSubjectFolder);
        dashpos = find(bids.participants{iSubject,1} == '-');
        if ~isempty(dashpos)
            bids.participants{iSubject,1} = [ bids.participants{iSubject,1}(1:dashpos) '0' bids.participants{iSubject,1}(dashpos+1:end) ];
            parentSubjectFolder = fullfile(bidsFolder   , bids.participants{iSubject,pInd});
            outputSubjectFolder = fullfile(opt.outputdir, bids.participants{iSubject,pInd});
        end
        iteration = iteration + 1;
    end

    % find folder containing eeg
    subFolders = dir(fullfile(parentSubjectFolder, 'ses*'));
    if ~isempty(subFolders)
        subFolders = { subFolders.name };
    else
        subFolders = {''};
    end
    subjectFolder    = {};
    subjectFolderOut = {};
    if ~isempty(opt.sessions)
        subFolders = intersect(subFolders, opt.sessions);
    end        

    for iFold = 1:length(subFolders)
        subjectFolder{   iFold} = fullfile(parentSubjectFolder, subFolders{iFold}, 'eeg');
        subjectFolderOut{iFold} = fullfile(outputSubjectFolder, subFolders{iFold}, 'eeg');
        if ~exist(subjectFolder{iFold},'dir')
            subjectFolder{   iFold} = fullfile(parentSubjectFolder, subFolders{iFold}, 'meg');
            subjectFolderOut{iFold} = fullfile(outputSubjectFolder, subFolders{iFold}, 'meg');
            if ~exist(subjectFolder{iFold},'dir')
                subjectFolder{   iFold} = fullfile(parentSubjectFolder, subFolders{iFold}, 'ieeg');
                subjectFolderOut{iFold} = fullfile(outputSubjectFolder, subFolders{iFold}, 'ieeg');
            end
        end
    end

    % import data
    for iFold = 1:length(subjectFolder) % scan sessions
        if ~exist(subjectFolder{iFold},'dir')
            fprintf(2, 'No EEG data folder for subject %s session %s\n', bids.participants{iSubject,pInd}, subFolders{iFold});
        else
            
            % scans.tsv for time synch information
            %-------------------------------------
            try
                try
                    scansFile     = searchparent(fileparts(subjectFolder{iFold}), '*_scans.tsv');
                catch
                    % for some reason parent search not working - a quick workaround
                    scansFile       = searchparent(fileparts(fileparts(subjectFolder{iFold})), '*_scans.tsv');
                end
            catch
            end
            
            if exist('scansFile', 'var') && ~isempty(scansFile)
                useScans = true;
                scans = bids_loadfile( scansFile.name, scansFile);
                bids.data = setallfields(bids.data, [iSubject-1,iFold,1], struct('scans', {scans}));
            else
                useScans = false;
            end
            
            % MEG, EEG, iEEG, Motion, Physio, or BEH
            
            % which raw data - with folder inheritance
            eegFile     = searchparent(subjectFolder{iFold}, '*eeg.*');
            if isempty(eegFile)
                eegFile     = searchparent(subjectFolder{iFold}, '*_meg.*');
            end
            if isempty(eegFile)
                eegFile     = searchparent(subjectFolder{iFold}, '*_ieeg.*');
            end
            infoFile      = searchparent(subjectFolder{iFold}, '*_eeg.json');
            channelFile   = searchparent(subjectFolder{iFold}, '*_channels.tsv');
            elecFile      = searchparent(subjectFolder{iFold}, '*_electrodes.tsv');
            eventFile     = searchparent(subjectFolder{iFold}, '*_events.tsv');
            eventDescFile = searchparent(subjectFolder{iFold}, '*_events.json');
            coordFile     = searchparent(subjectFolder{iFold}, '*_coordsystem.json');
            behFile       = searchparent(fullfile(subjectFolder{iFold}, '..', 'beh'), '*_beh.tsv');
            motionFile    = searchparent(fullfile(subjectFolder{iFold}, '..', 'motion'), '*_motion.tsv');
            physioFile    = searchparent(fullfile(subjectFolder{iFold}, '..', 'physio'), '*_physio.tsv');
            
            % remove BEH files which have runs (treated separately)
           if ~isempty(behFile) && (contains(behFile(1).name, 'run') || contains(behFile(1).name, 'task'))
                behFile = {};
            end

            % check the task
            if ~isempty(opt.bidstask)
                eegFile       = filterFiles(eegFile      , opt.bidstask);
                infoFile      = filterFiles(infoFile     , opt.bidstask);
                channelFile   = filterFiles(channelFile  , opt.bidstask);
                elecFile      = filterFiles(elecFile     , opt.bidstask);
                eventFile     = filterFiles(eventFile    , opt.bidstask);
                eventDescFile = filterFiles(eventDescFile, opt.bidstask);
                coordFile     = filterFiles(coordFile    , opt.bidstask);
                behFile       = filterFiles(behFile      , opt.bidstask);
            end
            
            % check the task
            if ~isempty(opt.runs)
                eegFile       = filterFilesRun(eegFile      , opt.runs);
                infoFile      = filterFilesRun(infoFile     , opt.runs);
                channelFile   = filterFilesRun(channelFile  , opt.runs);
                elecFile      = filterFilesRun(elecFile     , opt.runs);
                eventFile     = filterFilesRun(eventFile    , opt.runs);
                eventDescFile = filterFilesRun(eventDescFile, opt.runs);
                % no runs for BEH or coordsystem
            end
            
            % raw data
            allFiles = { eegFile.name };
            ind = strmatch( 'json', cellfun(@(x)x(end-3:end), allFiles, 'uniformoutput', false) );
            if ~isempty(ind)
                eegFileJSON = allFiles(ind);
                allFiles(ind) = [];
            end
            ind = strmatch( '.set', cellfun(@(x)x(end-3:end), allFiles, 'uniformoutput', false) ); % EEGLAB
            if ~isempty(ind)
                eegFileRawAll  = allFiles(ind);
            elseif length(allFiles) == 1
                eegFileRawAll  = allFiles;
            else
                ind = strmatch( '.eeg', cellfun(@(x)x(end-3:end), allFiles, 'uniformoutput', false) ); % BVA
                if isempty(ind)
                    ind = strmatch( '.edf', cellfun(@(x)x(end-3:end), allFiles, 'uniformoutput', false) ); % EDF
                    if isempty(ind)
                        ind = strmatch( '.bdf', cellfun(@(x)x(end-3:end), allFiles, 'uniformoutput', false) ); % BDF
                        if isempty(ind)
                            ind = strmatch( '.fif', cellfun(@(x)x(end-3:end), allFiles, 'uniformoutput', false) ); % FIF
                            if isempty(ind)
                                ind = strmatch( '.gz', cellfun(@(x)x(end-2:end), allFiles, 'uniformoutput', false) ); % FIF
                                if isempty(ind) && ~isempty(allFiles)
                                    ind = strmatch( '.ds', cellfun(@(x)x(end-2:end), allFiles, 'uniformoutput', false) ); % DS
                                    if isempty(ind) && ~isempty(allFiles)
                                        ind = strmatch( '.mefd', cellfun(@(x)x(end-4:end), allFiles, 'uniformoutput', false) ); % MEFD
                                        if isempty(ind) && ~isempty(allFiles)
                                            fprintf(2, 'No EEG/MEG file found for subject %s\n', bids.participants{iSubject,pInd});
                                        end
                                    end
                                end
                            end
                            ind2 = cellfun(@(x)~isempty(strfind(x, 'acq-crosstalk')), allFiles(ind));
                            ind(ind2) = [];
                        end
                    end
                end
                eegFileRawAll  = allFiles(ind);
            end
            
            % identify non-EEG data files
            %--------------------------------------------------------------
            if ~isempty(behFile) % should be a single file
                if length(behFile) > 1
                    fprintf(2, 'More than 1 BEH file for a given subject, do not know what to do with it\n');
                end
                behData = readtable(fullfile(behFile(1).folder, behFile(1).name),'FileType','text');
            end
            
            otherModality = {}; 
            motionData = {}; % can be multiple files (tracksys, runs)
            if ~isempty(motionFile) 
                for iMotion = 1:numel(motionFile)
                    motionData{iMotion} =  readtable(fullfile(motionFile(iMotion).folder, motionFile(iMotion).name),'FileType','text');
                    motionFile(iMotion).tracksys    = extractBetween(motionFile(iMotion).name,'tracksys-','_');
                    motionFile(iMotion).run         = extractBetween(motionFile(iMotion).name,'run-','_');
                end
                otherModality{end+1} = 'motion'; 
            end
            
            physioData = {}; % can be multiple files (runs)
            if ~isempty(physioFile)
                for iPhys = 1:numel(physioFile)
                    physioData{iPhys}       = readtable(fullfile(physioFile(iPhys).folder, physioFile(iPhys).name),'FileType','text');
                    physioFile(iPhys).run   = extractBetween(physioFile(iPhys).name,'run-','_');
                end
                otherModality{end+1} = 'physio'; 
            end
            
            % skip most import if set file with no need for modication
            for iFile = 1:length(eegFileRawAll)
                try
                    eegFileName = eegFileRawAll{iFile};
                    [~,tmpFileName,fileExt] = fileparts(eegFileName);
                    eegFileRaw     = fullfile(subjectFolder{   iFold}, eegFileName);
                    eegFileNameOut = fullfile(subjectFolderOut{iFold}, [ tmpFileName '.set' ]);
                    
                    % what is the run
                    iRun = 1;
                    ind = strfind(eegFileRaw, '_run-');
                    if ~isempty(ind)
                        tmpEegFileRaw = eegFileRaw(ind(1)+5:end);
                        indUnder = find(tmpEegFileRaw == '_');
                        iRun = str2double(tmpEegFileRaw(1:indUnder(1)-1));
                        if isnan(iRun)
                            iRun = str2double(tmpEegFileRaw(1:indUnder(1)-2)); % rare case run 5H in ds003190/sub-01/ses-01/eeg/sub-01_ses-01_task-ctos_run-5H_eeg.eeg
                            if isnan(iRun)
                                error('Problem converting run information'); 
                            end
                        end
                        % check for BEH file
                        filePathTmp = fileparts(eegFileRaw);
                        behFileTmp = fullfile(filePathTmp,'..', 'beh', [eegFileRaw(1:ind(1)-1) '_beh.tsv' ]);
                        if exist(behFileTmp, 'file')
                            behData = readtable(behFileTmp,'FileType','text');
                        else
                            behData = [];
                        end
                    else
                        % check for BEH file
                        [filePathTmp, fileBaseTmp ] = fileparts(eegFileRaw);
                        behFileTmp = fullfile(filePathTmp, '..', 'beh', [fileBaseTmp(1:end-4) '_beh.tsv' ]);
                        if exist(behFileTmp, 'file')
                            try
                                behData = readtable(behFileTmp,'FileType','text');
                            catch
                                disp('Warning: could not load BEH file');
                            end
                        else
                            behData = [];
                        end
                    end
                    
                    % extract task name and modality
                    underScores = find(tmpFileName == '_');
                    if ~strcmpi(tmpFileName(underScores(end)+1:end), 'ieeg')
                        if ~strcmpi(tmpFileName(underScores(end)+1:end), 'eeg')
                            if ~strcmpi(tmpFileName(underScores(end)+1:end), 'meg.fif')
                                if ~strcmpi(tmpFileName(underScores(end)+1:end), 'meg')
                                    error('Data file name does not contain eeg, ieeg, or meg'); % theoretically impossible
                                else
                                    modality = 'meg';
                                end
                            else
                                modality = 'meg';
                            end
                        else
                            modality = 'eeg';
                        end
                    else
                        modality = 'ieeg';
                    end
                    
                    % JSON information file
                    infoData = bids_importjson([ eegFileRaw(1:end-8) '_' modality '.json' ], ['_' modality '.json']); % bids_loadfile([ eegFileRaw(1:end-8) '_eeg.json' ], infoFile);
                    bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], infoData);
    
                    if contains(tmpFileName,'task')
                        tStart = strfind(tmpFileName,'_task')+1;
                        tEnd = underScores - tStart; 
                        tEnd = min(tEnd(tEnd>0)) + tStart - 1;
                        task = tmpFileName(tStart:tEnd);
                    end
                    
                    if ~strcmpi(fileExt, '.set') || strcmpi(opt.bidsevent, 'on') || strcmpi(opt.bidschanloc, 'on') || ~strcmpi(opt.outputdir, bidsFolder)
                        fprintf('Importing file: %s\n', eegFileRaw);
                        switch lower(fileExt)
                            case '.set' % do nothing
                                if strcmpi(opt.metadata, 'on')
                                    EEG = pop_loadset( 'filename', eegFileRaw, 'loadmode', 'info' );
                                else
                                    EEG = pop_loadset( 'filename', eegFileName, 'filepath', subjectFolder{iFold});
                                end
                            case {'.bdf','.edf'}
                                EEG = pop_biosig( eegFileRaw ); % no way to read meta data only (because events in channel)
                            case '.eeg'
                                [tmpPath,tmpFileName,~] = fileparts(eegFileRaw);
                                if exist(fullfile(tmpPath, [tmpFileName '.vhdr']), 'file')
                                    ext = '.vhdr'; 
                                elseif exist(fullfile(tmpPath, [tmpFileName '.VHDR']), 'file'), 
                                    ext = '.VHDR'; 
                                else
                                    fprintf(2, 'Warning: eeg file found without BVA header file\n');
                                    break;
                                end
                                if strcmpi(opt.metadata, 'on')
                                    EEG = pop_loadbv( tmpPath, [tmpFileName ext], [], [], true );
                                else
                                    EEG = pop_loadbv( tmpPath, [tmpFileName ext] );
                                end
                            case '.fif'
                                EEG = pop_fileio(eegFileRaw); % fif folder
                            case '.gz'
                                gunzip(eegFileRaw);
                                EEG = pop_fileio(eegFileRaw(1:end-3)); % fif folder
                            case '.ds'
                                if strcmpi(opt.ctffunc, 'fileio')
                                    EEG = pop_fileio(eegFileRaw);
                                else
                                    EEG = pop_ctf_read(eegFileRaw);
                                end
                            case '.mefd'
                                if ~exist('pop_MEF3', 'file')
                                    error('MEF plugin not present, please install the MEF3 plugin first')
                                end
                                EEG = pop_MEF3(eegFileRaw); % MEF folder
                            otherwise
                                error('No EEG data found for subject/session %s', subjectFolder{iFold});
                        end
                        EEG = eeg_checkset(EEG);
    
                        % check for group information: get from participants
                        % file if doesn't exist
                        if isempty(EEG.group) && sum(ismember(lower(bids.participants(1,:)),'group'))
                            igroup = bids.participants{iSubject,ismember(lower(bids.participants(1,:)),'group')};
                            if ~isempty(igroup)
                                EEG.group = igroup;
                            end
                        end
    
                        EEGnodata = EEG;
                        EEGnodata.data = [];
                        bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('EEG', EEGnodata));
                        
                        % channel location data
                        % ---------------------
                        selected_chanfile = bids_get_file(eegFileRaw(1:end-8), '_channels.tsv', channelFile);
                        selected_elecfile = bids_get_file(eegFileRaw(1:end-8), '_electrodes.tsv', elecFile);
                        if strcmpi(opt.bidschanloc, 'on')
                            [EEG, channelData, elecData] = bids_importchanlocs(EEG, selected_chanfile, selected_elecfile);
                            if isempty(EEG.chanlocs) || ~isfield(EEG.chanlocs, 'theta') || all(cellfun(@isempty, { EEG.chanlocs.theta }))
                                EEG = bids_chan_lookup(EEG, infoData);
                            end
                        else
                            channelData = bids_loadfile(selected_chanfile);
                            elecData    = bids_loadfile(selected_elecfile);
                            if ~isfield(EEG.chanlocs, 'theta') || all(cellfun(@isempty, { EEG.chanlocs.theta }))
                                EEG = bids_chan_lookup(EEG, infoData);
                            else
                                disp('The EEG file has channel locations associated with it, we are keeping them');
                            end
                        end
                        
                        % look up EEG channel type
                        disp('Looking up/checking channel type from channel labels');
                        EEG = eeg_getchantype(EEG);
                        
                        bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('chaninfo', { channelData }));
                        bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('elecinfo', { elecData }));
                        
                        % event data
                        % ----------
                        if strcmpi(opt.bidsevent, 'on')
                            eventfile              = bids_get_file(eegFileRaw(1:end-8), '_events.tsv', eventFile);
                            selected_eventdescfile = bids_get_file(eegFileRaw(1:end-8), '_events.json', eventDescFile);
                    
			                if ~isempty(eventfile)
				                [EEG, bids, eventData, eventDesc] = bids_importeventfile(EEG, eventfile, 'bids', bids, 'eventDescFile', selected_eventdescfile, 'eventtype', opt.eventtype); 
				                if isempty(eventData), error('bidsevent on but events.tsv has no data'); end
				                bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('eventinfo', {eventData}));
				                bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('eventdesc', {eventDesc}));
			                end
                        end
                        
                        % coordsystem file
                        % ----------------
                        if strcmpi(opt.bidscoord, 'on')
                            coordFile = bids_get_file(eegFileRaw(1:end-8), '_coordsystem.json', coordFile);                   
                            [EEG, bids] = bids_importcoordsystemfile(EEG, coordFile, 'bids', bids); 
                        end
    
                        % copy information inside dataset
                        EEG.subject = bids.participants{iSubject,pInd};
                        EEG.session = iFold;
                        EEG.run = iRun;
                        EEG.task = task(6:end); % task is currently of format "task-<Task name>"
                        
                        % build `EEG.BIDS` from `bids`
                        BIDS.gInfo = bids.dataset_description;
                        BIDS.gInfo.README = bids.README;
                        BIDS.gInfo.CHANGES = bids.CHANGES;
                        BIDS.pInfo = [bids.participants(1,:); bids.participants(iSubject,:)]; % header -> iSubject info
                        BIDS.pInfoDesc = bids.participantsJSON;
                        BIDS.eInfo = bids.eventInfo;
                        BIDS.eInfoDesc = bids.data.eventdesc;
                        BIDS.tInfo = infoData;
                        BIDS.bidsstats = stats;
                        BIDS.scannedElectrodes = false;
                        if ~isempty(elecData)
                           BIDS.scannedElectrodes = true;
                        end
                        if ~isempty(behData)
                            behData = table2struct(behData);
                        end
                        BIDS.behavioral = behData;
                        EEG.BIDS = BIDS;
                        
                        if strcmpi(opt.metadata, 'off')
                            if exist(subjectFolderOut{iFold},'dir') ~= 7
                                mkdir(subjectFolderOut{iFold});
                            end
                            EEG = pop_saveset( EEG, eegFileNameOut);
                        end
                    end
                    
                    % building study command
                    commands = [ commands { 'index' count 'load' eegFileNameOut 'subject' bids.participants{iSubject,pInd} 'session' iFold 'task' task(6:end) 'run' iRun } ];
                    
                    % custom numerical fields
                    for iCol = 2:size(bids.participants,2)
                        commands = [ commands { bids.participants{1,iCol} bids.participants{iSubject,iCol} } ];
                    end
                    if isstruct(behData) && ~isempty(behData)
                        behFields = fieldnames(behData);
                        if length(behData) > 1
                            warning('Behavioral data length larger than 1, only retaining the first element');
                        end
                        for iFieldBeh = 1:length(behFields)
                            commands = [ commands { behFields{iFieldBeh} [behData(1).(behFields{iFieldBeh})] } ];
                        end
                    end
                    count = count+1;
                    
                    % check dataset consistency
                    bData = bids.data(iSubject-1,iFold,iFile);
                    if ~isempty(bData.chaninfo)
                        if size(bData.chaninfo,1)-1 ~= bData.EEG.nbchan
                            warning('Warning: inconsistency detected, %d channels in BIDS file vs %d in EEG file for %s\n', size(bData.chaninfo,1)-1, bData.EEG.nbchan, [tmpFileName,fileExt]);
                            inconsistentChannels = inconsistentChannels+1;
                        end
                    end
                    %{
                    if ~isempty(bData.eventinfo)
                        if size(bData.eventinfo,1)-1 ~= length(bData.EEG.event)
                            fprintf(2, 'Warning: inconsistency detected, %d events in BIDS file vs %d in EEG file for %s\n', size(bData.eventinfo,1)-1, length(bData.EEG.event), [tmpFileName,fileExt]);
                            inconsistentEvents = inconsistentEvents+1;
                        end
                    end
                    %}
                catch ME
                    faileddatasets = [faileddatasets eegFileRaw];
                end
            end % end for eegFileRawAll
            
            % import data of other tpyes than EEG, MEG, iEEG
            for iMod = 1:numel(otherModality)
                try
                    dataType    = otherModality{iMod}; 
                    dataFile    = eval([dataType 'File']);
                    dataRaw     = eval([dataType 'Data']); % cell array containing tables
                    subjectID   = bids.participants{iSubject,pInd}; 
                    subjectDataFolder       = subjectFolder{iFold}(1:end-3);
                    subjectDataFolderOut    = subjectFolderOut{iFold}(1:end-3); 
                     
                    if isfield(bids.data(iSubject-1,iFold,1), 'scans')
                        scansRaw  = bids.data(iSubject-1,iFold,1).scans;
                    else
                        scansRaw = [];
                    end
                    
                    for iDat = 1:numel(dataFile)
                        
                            [DATA, dataFileOut] = import_noneeg(dataType, dataFile(iDat), dataRaw{iDat}, subjectID, scansRaw, iFold, strcmpi(opt.metadata, 'on'), strcmpi(opt.bidschanloc, 'on'), useScans, subjectDataFolder, subjectDataFolderOut);
                            
                            if strcmpi(opt.metadata, 'off')
                                if exist([subjectFolderOut{iFold}(1:end-3), dataType],'dir') ~= 7
                                    mkdir(subjectFolderOut{iFold}(1:end-3), dataType);
                                end
                                pop_saveset(DATA, dataFileOut);
                            end
                        
                    end
                catch exception
                    fprintf('Error importing non i/M/EEG modality %s. Skipped\n', dataType);
                    fprintf(getReport(exception));
                end
            end
            fclose all;
        end
    end
end

% update statistics
% -----------------
stats = bids_metadata_stats(bids, inconsistentChannels);

% study name and study creation
% -----------------------------
if strcmpi(opt.metadata, 'off')
    if isempty(commands)
        error('No dataset were found');
    end
    studyName = fullfile(opt.outputdir, [opt.studyName '.study']);
    if exist('tasklist','var') && length(tasklist)~=1 && isempty(opt.bidstask)
        [STUDY, ALLEEG]  = std_editset([], [], 'commands', commands, 'filename', studyName, 'task', 'task-mixed');
    else
        [STUDY, ALLEEG]  = std_editset([], [], 'commands', commands, 'filename', studyName, 'task', task);
    end
    
	% track failed datasets
	STUDY.etc.bidsimportinfo = [];
	STUDY.etc.bidsimportinfo.totaldatasetcount  = numel(eegFileRawAll);
	STUDY.etc.bidsimportinfo.faileddatasets     = faileddatasets;

	% import HED tags if exists in top level events.json
	% -----------------------------
	% scan for top level events.json
	top_level_eventsjson = dir(fullfile(bidsFolder, '*_events.json'));
	if ~isempty(top_level_eventsjson) && numel(top_level_eventsjson) == 1
	    top_level_eventsjson = fullfile(top_level_eventsjson.folder, top_level_eventsjson.name);
	    if plugin_status('HEDTools')
		try 
		    fMap = fieldMap.createfMapFromJson(top_level_eventsjson);
		    if fMap.hasAnnotation()
			STUDY.etc.tags = fMap.getStruct();
		    end
		catch ME
		    warning('Found top-level events.json file and tried importing HED tags but failed');
		end
	    end
	end
    [STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'resave', 'on');

    if ~isempty(options)
        commands = sprintf('[STUDY, ALLEEG] = pop_importbids(''%s'', %s);', bidsFolder, vararg2str(options));
    else
        commands = sprintf('[STUDY, ALLEEG] = pop_importbids(''%s'');', bidsFolder);
    end
end

% search parent folders (outward search) for the file of given fileName
% ---------------------
function outFile = searchparent(folder, fileName)
% search nestedly outward
% only get exact match and filter out hidden file
outFile = '';
parent = folder;
count = 4;
while ~any(arrayfun(@(x) strcmp(lower(x.name),'dataset_description.json'), dir(parent))) && isempty(outFile) && count > 0 % dataset_description indicates root BIDS folder
    outFile = filterHiddenFile(folder, dir(fullfile(parent, fileName)));
    parent = fileparts(parent);
    count = count-1;
end
if isempty(outFile)
    outFile = filterHiddenFile(parent, dir(fullfile(parent, fileName)));
end

function fileList = filterHiddenFile(folder, fileList)
isGoodFile = true(1,numel(fileList));
% loop to identify hidden files
for iFile = 1:numel(fileList) %'# loop only non-dirs
    % on OSX, hidden files start with a dot
    isGoodFile(iFile) = logical(~strcmp(fileList(iFile).name(1),'.'));
    if isGoodFile(iFile) && ispc
        % check for hidden Windows files - only works on Windows
        [~,stats] = fileattrib(fullfile(folder,fileList(iFile).name));
        if stats.hidden
            isGoodFile(iFile) = false;
        end
    end
end

% remove bad files
fileList = fileList(isGoodFile);

% Filter files
% ------------
function fileList = filterFiles(fileList, taskList)
keepInd = zeros(1,length(fileList));
for iFile = 1:length(fileList)
    if contains(fileList(iFile).name, taskList)
        keepInd(iFile) = 1;
    elseif contains(fileList(iFile).name, taskList,'IgnoreCase',true)
        warning('matching task ignore case')
        keepInd(iFile) = 1;
    end
end
fileList = fileList(logical(keepInd));

% Filter file runs
% ----------------
function fileList = filterFilesRun(fileList, runs)
if ~iscell(runs)
    runs = {runs}; % integer now in a cell
end
keepInd = arrayfun(@(x) contains(extractAfter(x.name,'run-'),runs), fileList);
% keepInd = zeros(1,length(fileList));
% for iFile = 1:length(fileList)
%     runInd = strfind(fileList(iFile).name, '_run-');
%     if ~isempty(runInd)
%         strTmp = fileList(iFile).name(runInd+5:end);
%         underScore = find(strTmp == '_');
%         if any(runs == str2double(strTmp(1:underScore(1)-1)))
%             keepInd(iFile) = 1;
%         end
%     end
% end
fileList = fileList(logical(keepInd));


% set structure
% -------------
function sdata = setallfields(sdata, indices, newdata)
if isempty(newdata), return; end
if ~isstruct(newdata), error('Can only assign structures'); end
if length(indices) < 3, error('Must have 3 indices'); end
allFields = fieldnames(newdata);
for iField = 1:length(allFields)
    sdata(indices(1), indices(2), indices(3)).(allFields{iField}) = newdata.(allFields{iField});
end

% get BIDS file
function filestr = bids_get_file(baseName, ext, alternateFile)
filestr = '';
if exist([ baseName ext ], 'file')
    filestr = [ baseName ext ];
else
    if ~isempty(alternateFile) && isfield(alternateFile, 'folder') && isfield(alternateFile, 'name')
        tmpFile = fullfile(alternateFile(1).folder, alternateFile(1).name);
        if exist(tmpFile, 'file')
            filestr = tmpFile;
        end
    end
end

% format other data types than EEG, MEG, iEEG
%--------------------------------------------
function [DATA, dataFileOut] = import_noneeg(dataType, dataFile, dataRaw, subject, scansData, session, onlyMetadata, useChanlocs, useScans, subjectFolder, subjectDataFolderOut)

disp(['Processing ' dataType ' data'])

    % replace extension tsv with set
    [~,fileName,fileExt] = fileparts(dataFile.name);
    dataFileOut   = fullfile(subjectDataFolderOut, dataType, [fileName '.set']);

    % check for json file that might be applicable to the current file in current directory using rule 2.b and 2.c
    % of https://bids-specification.readthedocs.io/en/stable/common-principles.html#the-inheritance-principle
    bids_entity = strsplit(fileName, '_');
    bids_entity = bids_entity{end};
    dataFileJSON = fullfile([subjectFolder, dataType], ['*_' bids_entity '.json']);
    % resolve wildcard if applicable
    dataFileJSONDir = dir(dataFileJSON);
    if ~isempty(dataFileJSONDir)
        for u=1:numel(dataFileJSONDir)
            dataFileJSONName_parts = strsplit(dataFileJSONDir(u).name, '_');
            dataFileJSONName_parts = dataFileJSONName_parts(1:end-1); % only consider the suffices
            if all(cellfun(@(x) contains(fileName, x), dataFileJSONName_parts))
                dataFileJSON = fullfile(dataFileJSONDir(u).folder, dataFileJSONDir(u).name);
                break
            end
        end
    end
    infoData        = bids_importjson(dataFileJSON);    
    
    % check or construct needed channel files according to the data type
    switch dataType
        case 'motion'
            % look for associated *_channels.tsv
            % since *_motion.json share the same principle and already
            % looked up above, we only change the postfix
            channelFileMotion   = [dataFileJSON(1:end-numel('motion.json')) 'channels.tsv']; % replace 'motion.json' with 'channels.tsv'
            % channelFile         = searchparent([subjectFolder, dataType], channelFileMotion);
            channelData         = bids_loadfile(channelFileMotion); %channelFile(1).name, channelFile);
        case 'physio'
            % channel file (for physio data, hidden in json file as 'columns')
            channelData = {'name', 'type', 'units'};
            for Ci = 1:numel(infoData.Columns)
                channelData{end + 1,1} = [char(infoData.Columns{Ci})] ;
            end
    end
    
    switch lower(fileExt)
        case '.set' % do nothing
            if onlyMetadata 
                DATA = pop_loadset( 'filename', dataFile.name, 'loadmode', 'info' );
            else
                DATA = pop_loadset( 'filename', dataFile.name );
            end
        case '.tsv'
            DATA        = eeg_emptyset;
            DATA.data   = table2array(dataRaw)';
            
            if strcmp(dataType,'motion')
                if isfield(infoData, 'SamplingFrequencyEffective')
                    % 'SamplingFrequencyEffective' can be used if nominal
                    % https://bids-specification.readthedocs.io/en/stable/modality-specific-files/motion.html#motion-specific-fields
                    DATA.srate                      = infoData.SamplingFrequencyEffective;
                    if isfield(infoData, 'SamplingFrequency')
                        DATA.etc.nominal_srate      = infoData.SamplingFrequency;
                    end
                else
                    DATA.srate                  = infoData.SamplingFrequency;
                end
            else
                try
                    DATA.srate  = infoData.SamplingFrequencyEffective; % Actual sampling rate used in motion data. Note that the unit of the time must be in second.
                catch
                    DATA.srate  = infoData.SamplingFrequency; % Generic physio data
                end
            end
            
            % find latency channel
            headers     = dataRaw.Properties.VariableNames;
            
            useLatency = 0;
            if strcmp(dataType,'motion')
                latencyInd = find(strcmpi(channelData(:,strcmp(channelData(1,:),'type')), 'latency'));
                useLatency = ~isempty(latencyInd);
                if useLatency
                    latencyHeader   = channelData{latencyInd,strcmp(channelData(1,:),'name')};
                    latencyRowInData = find(strcmp(headers, latencyHeader));
                end
            elseif strcmp(dataType,'physio')
                % check if the tracking system comes with latency
                latencyInd      = find(contains(channelData(:,strcmp(channelData(1,:),'name')), 'latency'));
                useLatency = ~isempty(latencyInd);
                if useLatency
                    latencyHeader   = channelData{latencyInd,strcmp(channelData(1,:),'name')};
                    latencyRowInData = find(strcmp(headers, latencyHeader));
                end
            end
            
            % reconstruct time : use scans.tsv for synching
            % it computes offset between motion and eeg data
            if useScans
                
                for Coli = 1:size(scansData, 2)
                    if strcmp(scansData{1,Coli}, 'acq_time')
                        acqTimeColi = Coli;
                    elseif strcmp(scansData{1,Coli}, 'filename')
                        fNameColi = Coli;
                    end
                end
                
                for Rowi = 1:size(scansData, 1)
                    
                    sesString = '';
                    taskString = '';
                    runString = '';
                    trackSysString = '';
                    
                    if exist('tracksys', 'var') && ~isempty(tracksys)
                        trackSysString = tracksys;
                    end
                    
                    splitName       = regexp(dataFileOut,'_','split');
                    for SNi = 1:numel(splitName)
                        if contains(splitName{SNi}, 'ses-')
                            sesString = splitName{SNi}(5:end);
                        elseif contains(splitName{SNi}, 'task-')
                            taskString = splitName{SNi}(6:end);
                        elseif contains(splitName{SNi}, 'run-')
                            runString = splitName{SNi}(5:end);
                        end
                    end
                    
                    % find files that matches in session, task, tracking system (in case it is motion data), and run
                    if contains(scansData{Rowi,fNameColi}, 'eeg.') &&...
                            contains(scansData(Rowi,fNameColi), sesString) && contains(scansData(Rowi,fNameColi), taskString) &&...
                            contains(scansData(Rowi,fNameColi), runString)
                        eegAcqTime      = scansData(Rowi,acqTimeColi);
                    elseif contains(scansData(Rowi,fNameColi), sesString) && contains(scansData(Rowi,fNameColi), taskString) &&...
                            contains(scansData(Rowi,fNameColi), runString) && contains(scansData(Rowi,fNameColi), trackSysString) &&...
                            contains(scansData(Rowi,fNameColi), dataType)
                        otherAcqTime    = scansData(Rowi,acqTimeColi);
                    end
                end
                
                startTime = seconds(datetime(otherAcqTime{1}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS') - datetime(eegAcqTime{1}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
                
            else
                if isfield(infoData, 'StartTime')
                    if isnumeric(infoData.StartTime)
                        startTime  = infoData.StartTime;
                    else
                        startTime = 0;
                        disp('Field Start time in motion json file is non-numeric - assume no offset to eeg data')
                    end
                else
                    startTime = 0;
                    disp('Field Start time in motion json file is empty - assume no offset to eeg data')
                end
            end
            
            DATA.etc.starttime = startTime;
            
            if useLatency
                DATA.times = (DATA.data(latencyRowInData,:) - DATA.data(latencyRowInData,1))*1000;
                DATA.data(latencyRowInData,:)   = [];
            else
                if isfield(infoData, 'TrackingSystems')
                    % tsi should have been defined above when srate was being read in
                    DATA.times  = (0:1000/infoData.TrackingSystems(tsi).SamplingFrequencyEffective:infoData.TrackingSystems(tsi).RecordingDuration*1000); % time is in ms
                elseif isfield(infoData, 'RecordingDuration')
                    DATA.times  = (0:1000/infoData.SamplingFrequency:infoData.RecordingDuration*1000); % time is in ms
                else
                    DATA.times  = (0:1000/infoData.SamplingFrequency:(size(DATA.data,2)/infoData.SamplingFrequency)*1000); % time is in ms
                end
            end
            
            DATA.nbchan = size(DATA.data,1);
            DATA.pnts   = size(DATA.data,2);
            
        otherwise
            error(['No ' dataType 'data found for subject/session ' subjectFolder{iFold}]);
    end


if useChanlocs
    chanlocs = [];
    for iChan = 2:size(channelData,1)
        % the fields below are all required
        for iField = 1:size(channelData,2)
            fName = string(channelData(1,iField));
            if strcmp(fName, 'name')
                fName = 'labels';
            end
            chanlocs(iChan-1).(fName)   = channelData{iChan,iField};
        end
        if size(channelData,2) > 3
            chanlocs(iChan-1).status = channelData{iChan,4};
        end
    end
    if useLatency
        chanlocs(latencyRowInData)   = [];
    end
end

% copy information inside dataset
DATA.subject = subject;
DATA.session = session;
DATA.chanlocs = chanlocs;

% look up channel locations
% -------------------------
function EEG = bids_chan_lookup(EEG, infodata)

EGIflag = false;
if isfield(infodata, 'ManufacturersModelName') && contains(lower(infodata.ManufacturersModelName), 'ges')
    EGIflag = true;
end
if isfield(infodata, 'Manufacturer') && contains(lower(infodata.Manufacturer), 'egi')
    EGIflag = true;
end
if EGIflag
    EEG = readegilocs(EEG);
else
   dipfitdefs;
   EEG = eeg_checkchanlocs(EEG);
   EEG = pop_chanedit(EEG, 'cleanlabels', 'on', 'lookup', template_models(2).chanfile);
end
