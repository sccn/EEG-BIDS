% pop_importbids() - Import BIDS format folder structure into an EEGLAB
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
%  'subjects'    - [integer array] indices of subjects to import
%  'sessions'    - [cell array] session numbers or names to import
%  'runs'        - [integer array] run numbers to import
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
%
% Outputs:
%   STUDY   - EEGLAB STUDY structure
%   ALLEEG  - EEGLAB ALLEEG structure
%   bids    - bids structure
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
    
    cb_event = 'set(findobj(gcbf, ''userdata'', ''bidstype''), ''enable'', fastif(get(gcbo, ''value''), ''on'', ''off''));';
    cb_task  = 'set(findobj(gcbf, ''userdata'', ''task''    ), ''enable'', fastif(get(gcbo, ''value''), ''on'', ''off''));';
    cb_sess  = 'set(findobj(gcbf, ''userdata'', ''sessions''), ''enable'', fastif(get(gcbo, ''value''), ''on'', ''off''));';
    cb_run   = 'set(findobj(gcbf, ''userdata'', ''runs''    ), ''enable'', fastif(get(gcbo, ''value''), ''on'', ''off''));';
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
        {} ...
        { 'style'  'text'       'string' 'Study output folder' } ...
        { 'style'  'edit'       'string' fullfile(bidsFolder, 'derivatives', 'eeglab') 'tag' 'folder' 'HorizontalAlignment' 'left' } ...
        { 'style'  'pushbutton' 'string' '...' 'callback' cb_select } ...
        };
    geometry = {[2 1.5], 1, 1,[1 0.35],[0.6 0.35 0.5],[0.6 0.35 0.5],[0.6 0.35 0.5],1,[1 2 0.5]};
    geomvert = [1 0.5, 1 1 1 1.5 1.5 0.5 1];
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
else
    options = varargin;
end

[~,defaultStudyName] = fileparts(bidsFolder);
opt = finputcheck(options, { ...
    'bidsevent'      'string'    { 'on' 'off' }    'on';  ...
    'bidschanloc'    'string'    { 'on' 'off' }    'on'; ...
    'bidscoord'      'string'    { 'on' 'off' }    'on'; ...
    'bidstask'       'string'    {}                ''; ...
    'subjects'       'integer'   {}                []; ...
    'sessions'       'cell'      {}                {}; ...
    'runs'           'integer'   {}                []; ...
    'metadata'       'string'    { 'on' 'off' }    'off'; ...
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
    bids.CHANGES = importalltxt( changesFile );
end

% load Readme file
readmeFile = fullfile(bidsFolder, 'README');
bids.README = '';
if exist(readmeFile,'File')
    bids.README = importalltxt( readmeFile );
end

% load dataset description file
dataset_descriptionFile = fullfile(bidsFolder, 'dataset_description.json');
bids.dataset_description = '';
if exist(dataset_descriptionFile,'File')
    if exist('jsondecode.m','file')
        bids.dataset_description = jsondecode(importalltxt( dataset_descriptionFile ));
    else
        bids.dataset_description = jsonread(dataset_descriptionFile);
    end
end

% load participant file
participantsFile = fullfile(bidsFolder, 'participants.tsv');
bids.participants = '';
if exist(participantsFile,'File')
    bids.participants = importtsv( participantsFile );
end
% if no participants.tsv, use subjects folder names as their IDs
if isempty(bids.participants)
    participantFolders = dir(fullfile(bidsFolder, 'sub-*'));
    bids.participants = {'participant_id' participantFolders.name }';
end

% load participant sidecar file
participantsJSONFile = fullfile(bidsFolder, 'participants.json');
bids.participantsJSON = '';
if exist(participantsJSONFile,'File')
    if exist('jsondecode.m','file')
        bids.participantsJSON = jsondecode(importalltxt( participantsJSONFile ));
    else
        bids.participantsJSON = jsonread(participantsJSONFile);
    end
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
if isempty(opt.subjects)
    opt.subjects = 2:size(bids.participants,1); % indices into the participants.tsv file, ignoring first header row
else
    opt.subjects = opt.subjects+1;
end
for iSubject = opt.subjects
    
    parentSubjectFolder = fullfile(bidsFolder   , bids.participants{iSubject,1});
    outputSubjectFolder = fullfile(opt.outputdir, bids.participants{iSubject,1});
    
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
            fprintf(2, 'No EEG data folder for subject %s session %s\n', bids.participants{iSubject,1}, subFolders{iFold});
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
                scans = loadfile( scansFile.name, scansFile);
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
                                    ind = strmatch( '.mefd', cellfun(@(x)x(end-4:end), allFiles, 'uniformoutput', false) ); % MEFD
                                    if isempty(ind) && ~isempty(allFiles)
                                        fprintf(2, 'No EEG file found for subject %s\n', bids.participants{iSubject,1});
                                    end
                                end
                            end
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
                    if isnan(iRun) || iRun == 0
                        iRun = str2double(tmpEegFileRaw(1:indUnder(1)-2)); % rare case run 5H in ds003190/sub-01/ses-01/eeg/sub-01_ses-01_task-ctos_run-5H_eeg.eeg
                        if isnan(iRun) || iRun == 0
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
                
                % JSON information file
                infoData = loadfile([ eegFileRaw(1:end-8) '_eeg.json' ], infoFile);
                bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], infoData);
                    
                % extract task name
                underScores = find(tmpFileName == '_');
                if ~strcmpi(tmpFileName(underScores(end)+1:end), 'eeg')
                    if ~strcmpi(tmpFileName(underScores(end)+1:end), 'ieeg')
                        if ~strcmpi(tmpFileName(underScores(end)+1:end), 'meg.fif')
                            if ~strcmpi(tmpFileName(underScores(end)+1:end), 'meg')
                                error('Data file name does not contain eeg, ieeg, or meg'); % theoretically impossible
                            end
                        end
                    end
                end
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
                            if exist(fullfile(tmpPath, [tmpFileName '.vhdr']), 'file'), ext = '.vhdr'; else ext = '.VMRK'; end
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
                            EEG = pop_fileio(eegFileRaw); % fif folder
                        case '.mefd'
                            if ~exist('pop_matmef', 'file')
                                error('MEF plugin not present, please install the MATMEF plugin first')
                            end
                            EEG = pop_matmef(eegFileRaw); % fif folder
                        otherwise
                            error('No EEG data found for subject/session %s', subjectFolder{iFold});
                    end
                    EEG = eeg_checkset(EEG);
                    EEGnodata = EEG;
                    EEGnodata.data = [];
                    bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('EEG', EEGnodata));
                    
                    % channel location data
                    % ---------------------
                    selected_chanfile = bids_get_file(eegFileRaw(1:end-8), '_channels.tsv', channelFile);
                    selected_elecfile = bids_get_file(eegFileRaw(1:end-8), '_electrodes.tsv', elecFile);
                    if strcmpi(opt.bidschanloc, 'on')
                        [EEG, channelData, elecData] = eeg_importchanlocs(EEG, selected_chanfile, selected_elecfile);
                        if isempty(selected_elecfile) && (isempty(EEG.chanlocs) || ~isfield(EEG.chanlocs, 'theta') || any(~cellfun(@isempty, { EEG.chanlocs.theta })))
                            dipfitdefs;
                            EEG = pop_chanedit(EEG, 'cleanlabels', 'on', 'lookup', template_models(2).chanfile);
                        end
                    else
                        channelData = loadfile(selected_chanfile);
                        elecData    = loadfile(selected_elecfile);
                        if ~isfield(EEG.chanlocs, 'theta') || all(cellfun(@isempty, { EEG.chanlocs.theta }))
                            dipfitdefs;
                            EEG = pop_chanedit(EEG, 'cleanlabels', 'on', 'lookup', template_models(2).chanfile);
                        else
                            disp('The EEG file has channel locations associated with it, we are keeping them');
                        end
                    end
                    bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('chaninfo', { channelData }));
                    bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('elecinfo', { elecData }));
                    
                    % event data
                    % ----------
                    if strcmpi(opt.bidsevent, 'on')
                        eventfile              = bids_get_file(eegFileRaw(1:end-8), '_events.tsv', eventFile);
                        selected_eventdescfile = bids_get_file(eegFileRaw(1:end-8), '_events.json', eventDescFile);
                
                        [EEG, bids, eventData, eventDesc] = eeg_importeventsfiles(EEG, eventfile, 'bids', bids, 'eventDescFile', selected_eventdescfile, 'eventtype', opt.eventtype); 
                        if isempty(eventData), error('bidsevent on but events.tsv has no data'); end
                        bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('eventinfo', {eventData}));
                        bids.data = setallfields(bids.data, [iSubject-1,iFold,iFile], struct('eventdesc', {eventDesc}));
                    end
                    
                    % coordsystem file
                    % ----------------
                    if strcmpi(opt.bidscoord, 'on')
                        coordFile = bids_get_file(eegFileRaw(1:end-8), '_coordsystem.json', coordFile);
%                     
                        [EEG, bids] = eeg_importcoordsystemfiles(EEG, coordFile, 'bids', bids); 
                    end

                    % copy information inside dataset
                    EEG.subject = bids.participants{iSubject,1};
                    EEG.session = iFold;
                    EEG.run = iRun;
                    EEG.task = task(6:end); % task is currently of format "task-<Task name>"
                    
                    % build `EEG.BIDS` from `bids`
                    BIDS.gInfo = bids.dataset_description;
                    BIDS.gInfo.README = bids.README;
                    BIDS.pInfo = [bids.participants(1,:); bids.participants(iSubject,:)]; % header -> iSubject info
                    BIDS.pInfoDesc = bids.participantsJSON;
                    BIDS.eInfo = bids.eventInfo;
                    BIDS.eInfoDesc = bids.data.eventdesc;
                    BIDS.tInfo = infoData;
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
                commands = [ commands { 'index' count 'load' eegFileNameOut 'subject' bids.participants{iSubject,1} 'session' iFold 'task' task(6:end) 'run' iRun } ];
                
                % custom numerical fields
                for iCol = 2:size(bids.participants,2)
                    commands = [ commands { bids.participants{1,iCol} bids.participants{iSubject,iCol} } ];
                end
                if isstruct(behData) && ~isempty(behData)
                    behFields = fieldnames(behData);
                    for iFieldBeh = 1:length(behFields)
                        commands = [ commands { behFields{iFieldBeh} behData.(behFields{iFieldBeh}) } ];
                    end
                end
                count = count+1;
                
                % check dataset consistency
                bData = bids.data(iSubject-1,iFold,iFile);
                if ~isempty(bData.chaninfo)
                    if size(bData.chaninfo,1)-1 ~= bData.EEG.nbchan
                        fprintf(2, 'Warning: inconsistency detected, %d channels in BIDS file vs %d in EEG file for %s\n', size(bData.chaninfo,1)-1, bData.EEG.nbchan, [tmpFileName,fileExt]);
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
            end % end for eegFileRaw
            
            % import data of other tpyes than EEG, MEG, iEEG
            for iMod = 1:numel(otherModality)

                dataType    = otherModality{iMod}; 
                dataFile    = eval([dataType 'File']);
                dataRaw     = eval([dataType 'Data']); % cell array containing tables
                subjectID   = bids.participants{iSubject,1}; 
                subjectDataFolder       = subjectFolder{iFold}(1:end-3);
                subjectDataFolderOut    = subjectFolderOut{iFold}(1:end-3); 
                 
                if isfield(bids.data(iSubject-1,iFold,1), 'scans')
                    scansRaw  = bids.data(iSubject-1,iFold,1).scans;
                else
                    scansRaw = [];
                end
                
                [DATA, dataFileOut] = import_noneeg(dataType, dataFile, dataRaw, subjectID, scansRaw, iFold, strcmpi(opt.metadata, 'on'), strcmpi(opt.bidschanloc, 'on'), useScans, subjectDataFolder, subjectDataFolderOut);
                
                if strcmpi(opt.metadata, 'off')
                    if exist([subjectFolderOut{iFold}(1:end-3), dataType],'dir') ~= 7
                        mkdir(subjectFolderOut{iFold}(1:end-3), dataType);
                    end
                    pop_saveset(DATA, dataFileOut);
                end
            end
            
            fclose all;
        end
    end
end

% update statistics
% -----------------
% compute basic statistics
stats.README             = 0;
stats.TaskDescription    = 0;
stats.Instructions       = 0;
stats.EEGReference       = 0;
stats.PowerLineFrequency = 0;
stats.ChannelTypes       = 0;
stats.ElectrodePositions = 0;
stats.ParticipantsAgeAndGender = 0;
stats.SubjectArtefactDescription = 0;
stats.eventConsistency   = 0;
stats.channelConsistency = 0;
stats.EventDescription    = 0;
if ~isempty(bids.README), stats.README = 1; end
if ismember('age'   , bids.participants(1,:)) && ismember('gender', bids.participants(1,:))
    stats.ParticipantsAgeAndGender = 1; 
end
if checkBIDSfield(bids, 'TaskDescription'),            stats.TaskDescription = 1; end
if checkBIDSfield(bids, 'Instructions'),               stats.Instructions = 1; end
if checkBIDSfield(bids, 'EEGReference'),               stats.EEGReference = 1; end
if checkBIDSfield(bids, 'PowerLineFrequency'),         stats.PowerLineFrequency = 1; end
if checkBIDSfield(bids, 'elecinfo'),                   stats.ElectrodePositions = 1; end
if checkBIDSfield(bids, 'eventdesc'),                  stats.EventDescription   = 1; end
if checkBIDSfield(bids, 'SubjectArtefactDescription'), stats.SubjectArtefactDescription   = 1; end
if isfield(bids.data, 'chaninfo') && ~isempty(bids.data(1).chaninfo) && ~isempty(strmatch('type', lower(bids.data(1).chaninfo(1,:)), 'exact'))
    stats.ChannelTypes = 1;
end
stats.channelConsistency = fastif(inconsistentChannels > 0, 0, 1);
stats.eventConsistency   = fastif(inconsistentEvents   > 0, 0, 1);

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
    
    if ~isempty(options)
        commands = sprintf('[STUDY, ALLEEG] = pop_importbids(''%s'', %s);', bidsFolder, vararg2str(options));
    else
        commands = sprintf('[STUDY, ALLEEG] = pop_importbids(''%s'');', bidsFolder);
    end
end

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

% check BIDS data field present
% -----------------------------
function res = checkBIDSfield(bids, fieldName)
res = false;
if isfield(bids.data, fieldName)
    fieldContent = { bids.data.(fieldName) };
    fieldContent(cellfun(@isempty, fieldContent)) = [];
    if ~isempty(fieldContent), res = true; end
end

% Import full text file
% ---------------------
function str = importalltxt(fileName)

str = [];
fid =fopen(fileName, 'r');
while ~feof(fid)
    str = [str 10 fgetl(fid) ];
end
str(1) = [];

% search parent folders (outward search) for the file of given fileName
% ---------------------
function outFile = searchparent(folder, fileName)
% search nestedly outward
% only get exact match and filter out hidden file
outFile = '';
parent = folder;
while ~any(arrayfun(@(x) strcmp(lower(x.name),'dataset_description.json'), dir(parent))) && isempty(outFile) % dataset_description indicates root BIDS folder
    outFile = filterHiddenFile(folder, dir(fullfile(parent, fileName)));
    parent = fileparts(parent);
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
    if ~isempty(strfind(fileList(iFile).name, taskList))
        keepInd(iFile) = 1;
    end
end
fileList = fileList(logical(keepInd));

% Filter file runs
% ----------------
function fileList = filterFilesRun(fileList, runs)
keepInd = zeros(1,length(fileList));
for iFile = 1:length(fileList)
    runInd = strfind(fileList(iFile).name, '_run-');
    if ~isempty(runInd)
        strTmp = fileList(iFile).name(runInd+5:end);
        underScore = find(strTmp == '_');
        if any(runs == str2double(strTmp(1:underScore(1)-1)))
            keepInd(iFile) = 1;
        end
    end
end
fileList = fileList(logical(keepInd));

% import JSON or TSV file
% -----------------------
function data = loadfile(localFile, globalFile)
[~,~,ext] = fileparts(localFile);
data = [];
localFile = dir(localFile);
if ~isempty(localFile)
    if strcmpi(ext, '.tsv')
        data = importtsv( fullfile(localFile(1).folder, localFile(1).name));
    else
        if exist('jsondecode.m','file')
            data = jsondecode( importalltxt( fullfile(localFile(1).folder, localFile(1).name) ));
        else
            data = jsonread(fullfile(localFile(1).folder, localFile(1).name));
        end
    end        
elseif nargin > 1 && ~isempty(globalFile)
    if strcmpi(ext, '.tsv')
        data = importtsv( fullfile(globalFile(1).folder, globalFile(1).name));
    else
        if exist('jsondecode.m','file')
            data = jsondecode( importalltxt( fullfile(globalFile(1).folder, globalFile(1).name) ));
        else
            data = jsonread(fullfile(globalFile(1).folder, globalFile(1).name));
        end
    end
end

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

% Import tsv file
% ---------------
function res = importtsv( fileName)

res = loadtxt( fileName, 'verbose', 'off', 'delim', 9);

for iCol = 1:size(res,2)
    % search for NaNs in numerical array
    indNaNs = cellfun(@(x)strcmpi('n/a', x), res(:,iCol));
    if ~isempty(indNaNs)
        allNonNaNVals = res(find(~indNaNs),iCol);
        allNonNaNVals(1) = []; % header
        testNumeric   = cellfun(@isnumeric, allNonNaNVals);
        if all(testNumeric)
            res(find(indNaNs),iCol) = { NaN };
        elseif ~all(~testNumeric)
            % Convert numerical value back to string
            res(:,iCol) = cellfun(@num2str, res(:,iCol), 'uniformoutput', false);
        end
    end
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

for iDat = 1:numel(dataFile)
    
    % replace extension tsv with set
    [~,fileName,fileExt] = fileparts(dataFile(iDat).name);
    dataFileOut   = fullfile(subjectDataFolderOut, dataType, [fileName '.set']);
    dataFileJSON  = [fileName '.json'];
    
    % JSON information file
    infoFile        = searchparent([subjectFolder, dataType], dataFileJSON);
    infoData        = loadfile(infoFile.name, infoFile);
    
    % check or construct needed channel files according to the data type
    switch dataType
        case 'motion'
            channelFileMotion   = [fileName(1:end-6) 'channels.tsv']; % replace _motion with _channels
            channelFile         = searchparent([subjectFolder, dataType], channelFileMotion);
            channelData         = loadfile(channelFile(1).name, channelFile);
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
                DATA = pop_loadset( 'filename', dataFile(iDat).name, 'loadmode', 'info' );
            else
                DATA = pop_loadset( 'filename', dataFile(iDat).name );
            end
        case '.tsv'
            DATA        = eeg_emptyset;
            DATA.data   = table2array(dataRaw{iDat})';
            
            if strcmp(dataType,'motion')
                DATA.srate                  = infoData.SamplingFrequencyEffective;
                DATA.etc.nominal_srate      = infoData.SamplingFrequency;
            else
                try
                    DATA.srate  = infoData.SamplingFrequencyEffective; % Actual sampling rate used in motion data. Note that the unit of the time must be in second.
                catch
                    DATA.srate  = infoData.SamplingFrequency; % Generic physio data
                end
            end
            
            % find latency channel
            headers     = dataRaw{1}.Properties.VariableNames;
            
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


