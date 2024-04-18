% BIDS_IMPORTEVENTFILE - create EEG.event from events.tsv and optionally events.json files
%
% Usage:
%    [EEG, ~, ~, ~] = bids_importeventfile(EEG, eventfile, 'key', value)
%
% Inputs:
%  'EEG'        - [struct] the EEG structure to which event information will be imported
%  'eventfile'  - [string] path to the events.tsv file. 
%                 e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo_events.tsv
%
% Optional inputs:
%  'bids'          - [struct] structure that saves imported BIDS information. Default is []
%  'eventDescFile' - [string] path to events.json file if applicable. Default is empty
%  'eventtype'     - [string] BIDS event column to be used as type in EEG.event. Default is 'value'
%
%  'usevislab'     - [string] Whether to use VisLab's functions. Default 'off'
% Outputs:
%   EEG     - [struct] the EEG structure with event info imported
%   bids    - [struct] structure that saves BIDS information with event information
%   eventData - [cell array] imported data from events.tsv
%   eventDesc - [struct] imported data from events.json
%
% Authors: Dung Truong, Arnaud Delorme, 2022

function [EEG, bids, eventData, eventDesc] = bids_importeventfile(EEG, eventfile, varargin)
g = finputcheck(varargin,  {'eventDescFile'   'string'   [] '';
                            'bids'            'struct'   [] struct([]);
                            'eventtype'       'string'   [] 'value' ;
                            'usevislab'       'string'   { 'on' 'off'} 'off' }, 'eeg_importeventsfiles', 'ignore');
if isstr(g), error(g); end

% use Kay's old implementation
if strcmpi(g.usevislab, 'on')
    [EEG, bids, eventData, eventDesc] = eeg_importeventsfiles(EEG, eventfile, varargin{:}); %change to Kay's function
    return;
end
    
bids = g.bids;
                        
% ---------
% load files
eventData = bids_loadfile( eventfile, '');
eventDesc = bids_importjson(g.eventDescFile, '_events.json');

% ----------
% event data
bids(1).eventInfo = {}; % for eInfo. Default is empty. If replacing EEG.event with events.tsv, match field names accordingly
if isempty(eventData)
    warning('No data found in events.tsv');
else
    events       = struct([]);
    indSample    = strmatch('sample', lower(eventData(1,:)), 'exact');
    indType      = strmatch('type', lower(eventData(1,:)), 'exact');
    indTrialType = strmatch('trial_type', lower(eventData(1,:)), 'exact');
    if ~isempty(indType) && isempty(indTrialType)
        eventData(1,indType) = { 'trial_type' }; % renaming type as trial_type because erased below
    end
    
    for iField = 1:length(eventData(1,:))
        eventData{1,iField} = cleanvarname(eventData{1,iField});
    end
    indTrial = strmatch( g.eventtype, lower(eventData(1,:)), 'exact');
    for iEvent = 2:size(eventData,1)
        events(end+1).latency  = eventData{iEvent,1}*EEG.srate+1; % convert to samples
        if EEG.trials > 1
            events(end).epoch = floor(events(end).latency/EEG.pnts)+1;
        end
        events(end).duration   = eventData{iEvent,2}*EEG.srate;   % convert to samples
        bids.eventInfo = {'onset' 'latency'; 'duration' 'duration'}; % order in events.tsv: onset duration
        if ~isempty(indSample)
            events(end).sample = eventData{iEvent,indSample} + 1;
            bids.eventInfo(end+1,:) = {'sample' 'sample'};
        end
        for iField = 1:length(eventData(1,:))
            if ~any(strcmpi(eventData{1,iField}, {'onset', 'duration', 'sample', g.eventtype}))
                events(end).(eventData{1,iField}) = eventData{iEvent,iField};
                bids.eventInfo(end+1,:) = { eventData{1,iField} eventData{1,iField} };
            end
        end
        if ~isempty(indTrial)
            events(end).type = eventData{iEvent,indTrial};
            bids.eventInfo(end+1,:) = { g.eventtype 'type' };
        end                           
        %                         if size(eventData,2) > 3 && strcmpi(eventData{1,4}, 'response_time') && ~strcmpi(eventData{iEvent,4}, 'n/a')
        %                             events(end+1).type   = 'response';
        %                             events(end).latency  = (eventData{iEvent,1}+eventData{iEvent,4})*EEG.srate+1; % convert to samples
        %                             events(end).duration = 0;
        %                         end
    end
    EEG.event = events; 
    EEG = eeg_checkset(EEG, 'makeur'); % add urevent
    EEG = eeg_checkset(EEG, 'eventconsistency');

    % save BIDS information in raw form
    bids.eInfoDesc = eventDesc;
    EEG.BIDS = bids;
end    

function nameout = cleanvarname(namein)

% Routine to remove unallowed characters from strings
% nameout can be use as a variable or field in a structure

% custom change
if strcmp(namein,'#')
    namein = 'nb';
end

% 1st char must be a letter
for l=1:length(namein)
    if isletter(namein(l))
        nameout = namein(l:end);
        break % exist for loop
    end
end

% remove usual suspects
stringcheck = [strfind(namein,'('), ...
    strfind(namein,')') ...
    strfind(namein,'[') ...
    strfind(namein,']') ...
    strfind(namein,'{') ...
    strfind(namein,'}') ...
    strfind(namein,'-') ...
    strfind(namein,'+') ...
    strfind(namein,'*') ...
    strfind(namein,'/') ...
    strfind(namein,'#') ...
    strfind(namein,'%') ...
    strfind(namein,'&') ...
    strfind(namein,'@') ...
    ];

if ~isempty(stringcheck)
    nameout(stringcheck) = [];
end

% last check
if ~isvarname(nameout)
    nameout(1) = upper(nameout(1));
    if ~isvarname(nameout)
        error('the variable name to use is still invalid, check chars to remove')
    end
end