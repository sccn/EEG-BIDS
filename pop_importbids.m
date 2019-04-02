% pop_importbids() - Import BIDS format folder structure into an EEGLAB
%                    study.
% Usage:
%           >> [STUDY ALLEEG] = pop_importbids(bidsfolder);
% Inputs:
%   bidsfolder - a loaded epoched EEG dataset structure.
%
% Authors: Arnaud Delorme, SCCN, INC, UCSD, January, 2019
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
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [STUDY, ALLEEG, bids, commands] = pop_importbids(bidsFolder, varargin)

if nargin < 1
    bidsFolder = uigetdir('Pick a BIDS folder');
    if isequal(bidsFolder,0), return; end
    
    cb_select = [ 'tmpfolder = uigetdir;' ...
        'if ~isequal(tmpfolder, 0)' ...
        '   set(findobj(gcbf, ''tag'', ''folder''), ''string'', tmpfolder);' ...
        'end;' ...
        'clear tmpfolder;' ];
    
    promptstr    = { { 'style'  'checkbox'  'string' 'Overwrite events with BIDS event files' 'tag' 'events' 'value' 0 } ...
        { 'style'  'checkbox'  'string' 'Overwrite channel locations with BIDS channel location files' 'tag' 'chanlocs' 'value' 0 } ...
        { 'style'  'text'      'string' 'Select study output folder (default is BIDS folder)' } ...
        { 'style'  'edit'        'string' '' 'tag' 'folder' } ...
        { 'style'  'pushbutton'  'string' '...' 'callback' cb_select } ...
        };
    geometry = { [1] [1] [2 1 0.5] };
    
    [~,~,~,res] = inputgui( 'geometry', geometry, 'uilist', promptstr, 'helpcom', 'pophelp(''pop_importbids'')', 'title', 'Import BIDS data -- pop_importbids()');
    if isempty(res), return; end
    
    options = { };
    if res.events,    options = { options{:} 'bidsevent' 'on' }; end
    if res.chanlocs,  options = { options{:} 'bidschanloc' 'on' }; end
    if ~isempty(res.folder),  options = { options{:} 'outputdir' res.folder }; end
else
    options = varargin;
end

opt = finputcheck(options, { 'bidsevent'      'string'    { 'on' 'off' }    'off';
                             'bidschanloc'    'string'    { 'on' 'off' }    'off';
                             'outputdir'      'string'    { }               bidsFolder}, 'pop_importbids');
if isstr(opt), error(opt); end

% Options:
% - copy folder
% - use channel location and event

% load change file
changesFile = fullfile(bidsFolder, 'CHANGES');
bids.CHANGES = '';
if exist(changesFile)
    bids.CHANGES = importalltxt( changesFile );
end

% load Readme file
readmeFile = fullfile(bidsFolder, 'README');
bids.README = '';
if exist(readmeFile)
    bids.README = importalltxt( readmeFile );
end

% load dataset description file
dataset_descriptionFile = fullfile(bidsFolder, 'dataset_description.json');
bids.dataset_description = '';
if exist(dataset_descriptionFile)
    bids.dataset_description = jsondecode(importalltxt( dataset_descriptionFile ));
end

% load participant file
participantsFile = fullfile(bidsFolder, 'participants.tsv');
bids.participants = '';
if exist(participantsFile)
    bids.participants = importtsv( participantsFile );
end

% load participant file
participantsJSONFile = fullfile(bidsFolder, 'participants.json');
bids.participantsJSON = '';
if exist(participantsJSONFile)
    bids.participantsJSON = jsondecode(importalltxt( participantsJSONFile ));
end

% scan participants
count = 1;
commands = {};
task = [ 'task-' bidsFolder ];
for iSubject = 2:size(bids.participants,1)
    
    parentSubjectFolder = fullfile(bidsFolder   , bids.participants{iSubject,1});
    outputSubjectFolder = fullfile(opt.outputdir, bids.participants{iSubject,1});
    
    % find folder containing eeg
    if exist(fullfile(parentSubjectFolder, 'eeg'))
        subjectFolder = { fullfile(parentSubjectFolder, 'eeg') };
        subjectFolderOut = { fullfile(outputSubjectFolder, 'eeg') };
    else
        subFolders = dir(fullfile(parentSubjectFolder, 'ses*'));
        subjectFolder    = {};
        subjectFolderOut = {};
        
        for iFold = 1:length(subFolders)
            subjectFolder{   iFold} = fullfile(parentSubjectFolder, subFolders(iFold).name, 'eeg');
            subjectFolderOut{iFold} = fullfile(outputSubjectFolder, subFolders(iFold).name, 'eeg');
        end
    end
    
    % import data
    for iFold = 1:length(subjectFolder)
        if ~exist(subjectFolder{iFold})
            error(sprintf('No EEG data found for subject %s', bids.participants{iSubject,1}));
        end
        
        % which raw data - with folder inheritance
        eegFile     = dir(fullfile(subjectFolder{iFold}, '*eeg.*'));
        channelFile = searchparent(subjectFolder{iFold}, '*_channels.tsv');
        elecFile    = searchparent(subjectFolder{iFold}, '*_electrodes.tsv');
        eventFile   = dir(fullfile(subjectFolder{iFold}, '*_events.tsv'));
                
        % raw data
        allFiles = { eegFile.name };
        ind = strmatch( 'json', cellfun(@(x)x(end-3:end), allFiles, 'uniformoutput', false) );
        if ~isempty(ind)
            eegFileJSON = allFiles{ind};
            allFiles(ind) = [];
        end
        ind = strmatch( '.set', cellfun(@(x)x(end-3:end), allFiles, 'uniformoutput', false) );
        if ~isempty(ind)
            eegFileRaw  = allFiles{ind};
        elseif length(allFiles) == 1
            eegFileRaw  = allFiles{1};
        else
            ind = strmatch( '.eeg', allFiles);
            if ~isempty(ind)
                error(sprintf('No EEG data found for subject %s', bids.participants{iSubject,1}));
            end
            eegFileRaw  = allFiles{ind};
        end
        [~,tmpFileName,fileExt] = fileparts(eegFileRaw);
        eegFileRaw     = fullfile(subjectFolder{   iFold}, eegFileRaw);
        eegFileNameOut = fullfile(subjectFolderOut{iFold}, [ tmpFileName '.set' ]);
        
        % extract task name
        underScores = find(tmpFileName == '_');
        if ~strcmpi(tmpFileName(underScores(end)+1:end), 'eeg')
            error('EEG file name does not contain eeg'); % theoretically impossible
        end
        if isempty(findstr('ses', tmpFileName(underScores(end-1)+1:underScores(end)-1)))
            task = tmpFileName(underScores(end-1)+1:underScores(end)-1);
        end
        
        % skip most import if set file with no need for modication
        if ~strcmpi(fileExt, '.set') || strcmpi(opt.bidsevent, 'on') || strcmpi(opt.bidschanloc, 'on') || ~strcmpi(opt.outputdir, bidsFolder)
            switch lower(fileExt)
                case '.set', % do nothing
                    EEG = pop_loadset( eegFileRaw );
                case {'.bdf','.edf'},
                    EEG = pop_biosig( eegFileRaw );
                case '.eeg',
                    EEG = pop_loadbva( eegFileRaw );
                otherwise
                    error(sprintf('No EEG data found for subject %s', bids.participants{iSubject,1}));
            end
            
            % channel location data
            % ---------------------
            if strcmpi(opt.bidschanloc, 'on')
                channelData = [];
                if ~isempty(channelFile)
                    channelData = importtsv( fullfile(subjectFolder{iFold}, channelFile.name));
                end
                elecData = [];
                if ~isempty(elecFile)
                    elecData = importtsv( fullfile(subjectFolder{iFold}, elecFile.name));
                end
                chanlocs = [];
                for iChan = 2:size(channelData,1)
                    % the fields below are all required
                    chanlocs(iChan-1).labels = channelData{iChan,1};
                    chanlocs(iChan-1).type   = channelData{iChan,2};
                    chanlocs(iChan-1).unit   = channelData{iChan,3};
                    if size(channelData,2) > 3
                        chanlocs(iChan-1).status = channelData{iChan,4};
                    end
                    if ~isempty(elecData)
                        indElec = strmatch(chanlocs(iChan-1).labels, elecData(:,1), 'exact');
                        chanlocs(iChan-1).X = elecData{indElec,2};
                        chanlocs(iChan-1).Y = elecData{indElec,3};
                        chanlocs(iChan-1).Z = elecData{indElec,4};
                    end
                end
                if length(chanlocs) ~= EEG.nbchan
                    error('Different number of channels in channel location file and EEG file');
                end
                if isfield(chanlocs, 'X')
                    EEG.chanlocs = convertlocs(chanlocs, 'cart2all');
                else
                    EEG.chanlocs = chanlocs;
                end
            end
            
            % event data
            % ----------
            if strcmpi(opt.bidsevent, 'on')
                eventData = [];
                if ~isempty(eventFile)
                    eventData = importtsv( fullfile(subjectFolder{iFold}, eventFile.name));
                end
                events = struct([]);
                for iEvent = 2:size(eventData,1)
                    events(end+1).latency  = eventData{iEvent,1}*EEG.srate+1; % convert to samples
                    events(end).duration   = eventData{iEvent,2}*EEG.srate;   % convert to samples
                    if size(eventData,2) > 2 && strcmpi(eventData{1,3}, 'trial_type')
                        events(end).type = eventData{iEvent,3};
                    end
                    if size(eventData,2) > 3 && strcmpi(eventData{1,4}, 'response_time') && ~strcmpi(eventData{iEvent,4}, 'n/a')
                        events(end+1).type   = 'response';
                        events(end).latency  = (eventData{iEvent,1}+eventData{iEvent,4})*EEG.srate+1; % convert to samples
                        events(end).duration = 0;
                    end
                end
                EEG.event = events;
                EEG = eeg_checkset(EEG, 'eventconsistency');
            end
            
            % copy information inside dataset
            EEG.subject = bids.participants{iSubject,1};
            EEG.session = iFold;
            
            if exist(subjectFolderOut{iFold}) ~= 7
                mkdir(subjectFolderOut{iFold});
            end
            EEG = pop_saveset( EEG, eegFileNameOut);
        end
        
        % building study command
        commands = { commands{:} 'index' count 'load' eegFileNameOut 'subject' bids.participants{iSubject,1} 'session' iFold };
        for iCol = 2:size(bids.participants,2)
            commands = { commands{:} bids.participants{1,iCol} bids.participants{iSubject,iCol} };
        end
        count = count+1;
    end
end

% study name and study creation
% -----------------------------
[~,studyName] = fileparts(bidsFolder);
studyName = fullfile(opt.outputdir, [ studyName '.study' ]);
[STUDY, ALLEEG]  = std_editset([], [], 'commands', commands, 'filename', studyName, 'task', task);
commands = sprintf('std_editset([],[], %s);', vararg2str( { 'commands', commands, 'filename', studyName, 'task', task } ));

% Import full text file
% ---------------------
function str = importalltxt(fileName)

str = [];
fid =fopen(fileName, 'r');
while ~feof(fid)
    str = [str 10 fgetl(fid) ];
end
str(1) = [];

% search parent folders
% ---------------------
function outFile = searchparent(folder, fileName)
    outFile = dir(fullfile(folder, fileName));
    if isempty(outFile)
        outFile = dir(fullfile(fileparts(folder), fileName));
    end
    if isempty(outFile)
        outFile = dir(fullfile(fileparts(fileparts(folder)), fileName));
    end
    if isempty(outFile)
        outFile = dir(fullfile(fileparts(fileparts(fileparts(folder))), fileName));
    end

% Import tsv file
% ---------------
function res = importtsv( fileName)

res = loadtxt( fileName, 'verbose', 'off');

for iCol = 1:size(res,2)
    % search for NaNs
    indNaNs = cellfun(@(x)strcmpi('n/a', x), res(:,iCol));
    if ~isempty(indNaNs)
        allNonNaNVals = res(find(~indNaNs),iCol);
        allNonNaNVals(1) = []; % header
        testNumeric   = cellfun(@isnumeric, allNonNaNVals);
        if all(testNumeric)
            res(find(indNaNs),iCol) = { NaN };
        elseif ~all(~testNumeric)
            error('Mixture of numeric and non-numeric values in table');
        end
    end
end
