% BIDS_WRITEEVENTFILE - write events.tsv and (if toggled) events.json for individual dataset
%                       from EEG dataset
%
% Usage:
%    bids_writeeventfile(EEG, fileOut, varargin)
%
% Inputs:
%  'EEG'       - [struct] the EEG structure
%
%  'fileOut'   - [string] filepath of the desired output location with file basename
%                e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo
%
%  Optional inputs:
%
%  'stimuli'   - [cell] cell array of EEGLAB event type and corresponding file
%                names for the stimulus on your computer.
%                For example: { 'sound1' '/Users/xxxx/sounds/sound1.mp3';
%                               'img1'   '/Users/xxxx/sounds/img1.jpg' }
%                (the semicolumn above is optional). Alternatively, after
%                exporting to BIDS, create a stimuli folder and place your
%                stimuli in that folder with a README file describing them.
%
%  'eInfo'     - [cell] additional event information columns and their corresponding
%                event fields in the EEGLAB event structure in format
%                { '<BIDS field1>' '<EEG field1>';
%                  '<BIDS field2>' '<EEG field2>'}
%                Note that EEGLAB event latency, duration, and type are inserted
%                automatically as columns "sample" (latency), "onset" (latency in sec), "duration"
%                (duration in sec), and "value" (EEGLAB event type). For example
%                { 'sample' 'latency';
%                  'value' 'type' }
%
%  'eInfoDesc' - [struct] structure describing additional or/and original
%                event fields if you wish to redefine these.
%                These are EEGLAB event fields listed above.
%                See the BIDS format for more information
%                eInfo.onset.LongName = 'Event onset'; % change default value
%                eInfo.onset.Description = 'Event onset';
%                eInfo.onset.Units = 'seconds';
%                eInfo.reaction_time.LongName = 'Reaction time';
%                eInfo.reaction_time.Units = 'seconds';
%
%  'renametype' - [cell] 2 column cell table for renaming type.
%                                     For example { '2'    'standard';
%                                                   '4'    'oddball';
%                                                   '128'  'response' }
%
%  'trialtype' - [cell] 2 column cell table indicating the experiment condition of event
%                for each event type. Equivalent to BIDS trial_type field. For example { '2'    'go';
%                                                                                        '4'    'nogo' }
%
% 'checkresponse' - [string] 
%
% 'individualEventsJson' - [string] specify whether to write events.json
%                           file specifically for this dataset. Default is 'off' to only have a single
%                           top-level events.json file for the entire dataset
%
% 'ignoreemptyfields' ['on'|'off'] ignore event field defined in eInfo if
%                 it not present in the dataset. Setting to 'off' fills a
%                 column with 'n/a' for that field. Default is 'on'.
%
% Authors: Dung Truong, Arnaud Delorme, 2022

function bids_writeeventfile(EEG, fileOut, varargin)
opt = finputcheck(varargin, {
    'stimuli'    'cell'    {}    {};
    'eInfo'      'cell'    {}    {};
    'omitsample' 'string'  {'on' 'off'}    {'off'};
    'eInfoDesc'  'struct'  {}    struct([]);
    'renametype' 'cell'   {}    {};
    'trialtype'  'cell'   {}    {};
    'checkresponse' 'string'   {}    '';
    'ignoreemptyfields' 'string'  {'on' 'off'}    'on';
    'individualEventsJson' 'string'  {'on' 'off'}    'off';
    }, 'write_events_files');
if isstr(opt), error(opt); end

% write event file information
% --- _events.json
[folderOut,fileOut,~] = fileparts(fileOut);
fileOut = fullfile(folderOut,fileOut);
if ~isempty(EEG.event)
    if strcmpi(opt.individualEventsJson,'on')
        jsonwrite([ fileOut '_events.json' ], opt.eInfoDesc,struct('indent','  '));
    end
    % --- _events.tsv
    
    fid = fopen( [ fileOut '_events.tsv' ], 'w');
    
    % -- parse eInfo
    if isempty(opt.eInfo)
        if isfield(EEG.event, 'onset')          opt.eInfo(end+1,:) = { 'onset'    'onset' };
        else                                    opt.eInfo(end+1,:) = { 'onset'    'latency' }; end
        opt.eInfo(end+1,:) = { 'duration'  'duration' };
        opt.eInfo(end+1,:) = { 'sample'    'latency' };
        if isfield(EEG.event, 'trial_type')     opt.eInfo(end+1,:) = { 'trial_type'    'trial_type' };
        elseif ~isempty(opt.trialtype)          opt.eInfo(end+1,:) = { 'trial_type'    'xxxx' }; end % to be filled with event type based on opt.trialtype mapping
        if isfield(EEG.event, 'value')          opt.eInfo(end+1,:) = { 'value'         'value' };
        else                                    opt.eInfo(end+1,:) = { 'value'         'type' }; end
        if isfield(EEG.event, 'response_time'), opt.eInfo(end+1,:) = { 'response_time' 'response_time' }; end
        if isfield(EEG.event, 'stim_file'),     opt.eInfo(end+1,:) = { 'stim_file'     'stim_file' }; end
        if isfield(EEG.event, 'HED'),           opt.eInfo(end+1,:) = { 'HED'           'HED' }; end
    else
        bids_fields = opt.eInfo(:,1);
        if ~any(strcmp(bids_fields,'onset'))
            if isfield(EEG.event, 'onset')
                opt.eInfo(end+1,:) = { 'onset' 'onset' };
            else
                opt.eInfo(end+1,:) = { 'onset' 'latency' };
            end
        end
        if ~any(strcmp(bids_fields,'duration')), opt.eInfo(end+1,:) = { 'duration' 'duration' }; end
        if ~any(strcmp(bids_fields,'sample')) && isfield(EEG.event, 'latency'), opt.eInfo(end+1,:) = { 'sample' 'latency' }; end
        if ~any(strcmp(bids_fields,'value'))
            if isfield(EEG.event, 'value')
                opt.eInfo(end+1,:) = { 'value' 'value' };
            else
                opt.eInfo(end+1,:) = { 'value' 'type' };
            end
        end
        if ~isempty(opt.trialtype), opt.eInfo(end+1,:) = { 'trial_type' 'xxxx' }; end
    end
    if ~isempty(opt.stimuli)
        opt.eInfo(end+1,:) = { 'stim_file' '' };
    end
    
    % reorder fields to put required and default fields first
    fieldOrder = { 'onset' 'duration' 'sample' 'value'}; % 'HED' }; % remove HED from default column in events.tsv as HED tags should be put in events.json instead
                                                         %  'trial_type' 'response_time' 'stim_file' }; % no longer required by BIDS by default
    newOrder = []; 
    for iField = 1:length(fieldOrder)
        ind = strmatch(fieldOrder{iField}, opt.eInfo(:,1)', 'exact');
        newOrder = [ newOrder ind ];
    end
    remainingInd = setdiff([1:size(opt.eInfo,1)], newOrder);
    newOrder = [ newOrder remainingInd];
    opt.eInfo = opt.eInfo(newOrder,:);
    
    % scan events
    eventFields = fieldnames(EEG.event);
    for iEvent = 1:length(EEG.event)
        
        str = {};
        for iField = 1:size(opt.eInfo,1)

            if iField > 2 && isempty(strmatch(opt.eInfo{iField,2}, eventFields, 'exact')) && strcmpi(opt.ignoreemptyfields, 'on')
                if iEvent == 1
                    fprintf('Field %s not found in the dataset events and ignored\n', opt.eInfo{iField,2} )
                    if iField == size(opt.eInfo,1)
                        fprintf(fid, '\n');
                    end
                end
            else

                if iEvent == 1
                    if strcmpi(opt.omitsample, 'off') || ~isequal(opt.eInfo{iField,1}, 'sample')
                        if iField == 1
                            fprintf(fid, '%s', opt.eInfo{iField,1});
                        else
                            fprintf(fid, '\t%s', opt.eInfo{iField,1});
                        end
                        if iField == size(opt.eInfo,1)
                            fprintf(fid, '\n');
                        end
                    end
                end

                tmpField = opt.eInfo{iField,2};
                if strcmpi(tmpField, 'n/a')
                    str{end+1} = tmpField;
                else
                    switch opt.eInfo{iField,1}

                        case 'onset'
                            onset = (EEG.event(iEvent).(tmpField)-1)/EEG.srate;
                            str{end+1} = num2str(onset, 10);

                        case 'duration'
                            if isfield(EEG.event, tmpField) && ~isempty(EEG.event(iEvent).(tmpField))
                                duration = num2str(EEG.event(iEvent).(tmpField)/EEG.srate, 10);
                            else
                                duration = 'n/a';
                            end
                            if isempty(duration) || strcmpi(duration, 'NaN')
                                duration = 'n/a';
                            end
                            str{end+1} = duration;

                        case 'sample'
                            if ~strcmpi(opt.omitsample, 'on')
                                if isfield(EEG.event, tmpField)
                                    sample = num2str(EEG.event(iEvent).(tmpField)-1);
                                else
                                    sample = 'n/a';
                                end
                                if isempty(sample) || strcmpi(sample, 'NaN')
                                    sample = 'n/a';
                                end
                                str{end+1} = sample;
                            end

                        case 'trial_type'
                            % trial type (which is the experimental condition - not the same as EEGLAB)
                            if isfield(EEG.event(iEvent), tmpField) && ~isempty(EEG.event(iEvent).(tmpField))
                                trialType = EEG.event(iEvent).(tmpField);
                                if isnumeric(trialType)
                                    trialType = num2str(trialType);
                                end
                                str{end+1} = trialType;
                            else
                                str{end+1} = 'n/a';
                            end

                        case 'response_time'
                            if isfield(EEG.event, tmpField)
                                response_time = num2str(EEG.event(iEvent).(tmpField));
                            else
                                response_time = 'n/a';
                            end
                            if isempty(response_time) || strcmpi(response_time, 'NaN')
                                response_time = 'n/a';
                            end
                            str{end+1} = response_time;

                        case 'stim_file'
                            if isempty(tmpField)
                                indStim = strmatch(EEG.event(iEvent).type, opt.stimuli(:,1));
                                if ~isempty(indStim)
                                    stim_file = opt.stimuli{indStim, 2};
                                else
                                    stim_file = 'n/a';
                                end
                            elseif isfield(EEG.event, tmpField)
                                if ~isempty(opt.stimuli)
                                    error('Cannot use "stim_file" as a BIDS event field and use the "stimuli" option')
                                end
                                stim_file = num2str(EEG.event(iEvent).(tmpField));
                            else
                                stim_file = 'n/a';
                            end
                            if isempty(stim_file) || strcmpi(stim_file, 'NaN')
                                stim_file = 'n/a';
                            end
                            str{end+1} = stim_file;

                        case 'value'
                            if  isfield(EEG.event, tmpField) && ~isempty(EEG.event(iEvent).(tmpField))
                                if isempty(opt.renametype)
                                    eventValue = num2str(EEG.event(iEvent).(tmpField));
                                else
                                    posType = strmatch(num2str(EEG.event(iEvent).(tmpField)), opt.renametype(:,1), 'exact');
                                    if ~isempty(posType)
                                        eventValue = opt.renametype{posType,2};
                                    else
                                        eventValue = num2str(EEG.event(iEvent).(tmpField));
                                    end
                                end
                                if ~isempty(opt.checkresponse)
                                    if iEvent+1 <= length(EEG.event) && strcmpi(EEG.event(iEvent+1).type, opt.checkresponse) && ~strcmpi(EEG.event(iEvent).type, opt.checkresponse)
                                        eventValue = [ eventValue '_with_reponse' ];
                                        response_time = (EEG.event(iEvent+1).latency - EEG.event(iEvent).latency)/EEG.srate;
                                        str{end-1} = num2str(response_time*1000,'%1.0f');
                                    end
                                end
                            else
                                eventValue = 'n/a';
                            end
                            if isequal(eventValue, 'NaN') || isempty(eventValue)
                                eventValue = 'n/a';
                            end
                            str{end+1} = eventValue;

                        otherwise
                            if isfield(EEG.event, opt.eInfo{iField,2})
                                tmpVal = EEG.event(iEvent).(opt.eInfo{iField,2});
                                if isnumeric(tmpVal)
                                    tmpVal = num2str(tmpVal);
                                elseif iscell(tmpVal)
                                    tmpVal = tmpVal{1};
                                end
                                if isequal(tmpVal, 'NaN') || isempty(tmpVal)
                                    tmpVal = 'n/a';
                                end
                            else
                                tmpVal = 'n/a';
                            end
                            assert(ischar(tmpVal));
                            str{end+1} = tmpVal;
                    end % switch
                end
            end
        end
        strConcat = sprintf('%s\t', str{:});
        fprintf(fid, '%s\n', strConcat(1:end-1));
    end
    fclose(fid);
end
