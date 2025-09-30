% eeg_writechanfile - write channels.tsv from single EEG dataset. The
%                     function also outputs channels count
%
% Usage:
%    channelsCount = eeg_writechanfile(EEG, fileOut)
%
%  
%
% Inputs:
%  'EEG'       - [struct] the EEG structure
%
%  'fileOut'   - [string] filepath of the desired output location with file basename
%                e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo
%
% Outputs:
%
%   channelsCount - [struct] count of different types of channels
%
% Authors: Dung Truong, Arnaud Delorme, 2022

function bids_writechanfile(EEG, fileOut)

fid = fopen( [ fileOut '_channels.tsv' ], 'w');

isEMG = isfield(EEG, 'etc') && isfield(EEG.etc, 'datatype') && strcmpi(EEG.etc.datatype, 'emg');
isiEEG = isfield(EEG, 'etc') && isfield(EEG.etc, 'datatype') && strcmpi(EEG.etc.datatype, 'ieeg');

if isempty(EEG.chanlocs)
    if isiEEG
        fprintf(fid, 'name\ttype\tunits\tlow_cutoff\thigh_cutoff\n');
        for iChan = 1:EEG.nbchan
            fprintf(fid, 'E%d\tiEEG\tmicroV\tn/a\tn/a\n', iChan);
        end
    elseif isEMG
        % EMG - only write REQUIRED columns when no chanlocs
        fprintf(fid, 'name\ttype\tunits\n');
        for iChan = 1:EEG.nbchan
            fprintf(fid, 'E%d\tEMG\tV\n', iChan);
        end
    else
        fprintf(fid, 'name\ttype\tunits\n');
        for iChan = 1:EEG.nbchan
            fprintf(fid, 'E%d\tEEG\tmicroV\n', iChan);
        end
    end
    channelsCount = struct([]);
else
    % Determine which columns to write based on available data
    columnsToWrite = {'name', 'type', 'units'}; % REQUIRED

    if isEMG
        % Check EMG RECOMMENDED columns for actual data
        recommendedFields = {'signal_electrode', 'reference', 'group', 'target_muscle', ...
                             'placement_scheme', 'placement_description', 'interelectrode_distance', ...
                             'low_cutoff', 'high_cutoff', 'sampling_frequency'};

        availableFields = {};
        missingFields = {};

        for iField = 1:length(recommendedFields)
            fieldName = recommendedFields{iField};
            hasData = false;

            % Check if any channel has this field with actual data
            for iChan = 1:EEG.nbchan
                if isfield(EEG.chanlocs(iChan), fieldName) && ...
                   ~isempty(EEG.chanlocs(iChan).(fieldName)) && ...
                   ~strcmpi(EEG.chanlocs(iChan).(fieldName), 'n/a')
                    hasData = true;
                    break;
                end
            end

            if hasData
                columnsToWrite{end+1} = fieldName;
                availableFields{end+1} = fieldName;
            else
                missingFields{end+1} = fieldName;
            end
        end

        % Display warning about missing RECOMMENDED columns
        if ~isempty(missingFields)
            fprintf('Note: The following RECOMMENDED EMG channel columns are not included (no data available): %s\n', ...
                    strjoin(missingFields, ', '));
        end
    elseif isiEEG
        % iEEG includes low_cutoff and high_cutoff
        columnsToWrite = [columnsToWrite, {'low_cutoff', 'high_cutoff'}];
    end

    % Write header
    fprintf(fid, '%s\n', strjoin(columnsToWrite, '\t'));

    % Write data
    acceptedChannelTypes = { 'AUDIO' 'EEG' 'EOG' 'ECG' 'EMG' 'EYEGAZE' 'GSR' 'HEOG' 'MISC' 'PUPIL' 'REF' 'RESP' 'SYSCLOCK' 'TEMP' 'TRIG' 'VEOG' };
    for iChan = 1:EEG.nbchan
        values = {};

        % Name (always)
        values{end+1} = EEG.chanlocs(iChan).labels;

        % Type
        if ~isfield(EEG.chanlocs, 'type') || isempty(EEG.chanlocs(iChan).type)
            type = 'n/a';
        elseif ismember(upper(EEG.chanlocs(iChan).type), acceptedChannelTypes)
            type = upper(EEG.chanlocs(iChan).type);
        else
            type = 'MISC';
        end
        values{end+1} = type;

        % Unit
        if isfield(EEG.chanlocs(iChan), 'unit')
            unit = EEG.chanlocs(iChan).unit;
        else
            if strcmpi(type, 'eeg')
                unit = 'uV';
            else
                unit = 'n/a';
            end
        end
        values{end+1} = unit;

        % Additional columns (only those determined to have data)
        for iCol = 4:length(columnsToWrite)
            fieldName = columnsToWrite{iCol};

            if isfield(EEG.chanlocs(iChan), fieldName) && ~isempty(EEG.chanlocs(iChan).(fieldName))
                val = EEG.chanlocs(iChan).(fieldName);
                if isnumeric(val)
                    values{end+1} = num2str(val);
                else
                    values{end+1} = val;
                end
            else
                values{end+1} = 'n/a';
            end
        end

        fprintf(fid, '%s\n', strjoin(values, '\t'));
    end
end
fclose(fid);

% Helper function to get field value or 'n/a'
function value = getfield_or_na(struct, fieldname)
if isfield(struct, fieldname) && ~isempty(struct.(fieldname))
    value = struct.(fieldname);
    % Convert numeric to string
    if isnumeric(value)
        value = num2str(value);
    end
else
    value = 'n/a';
end
