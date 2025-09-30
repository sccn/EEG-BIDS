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
    if isiEEG
        fprintf(fid, 'name\ttype\tunits\tlow_cutoff\thigh_cutoff\n');
    elseif isEMG
        % EMG with all RECOMMENDED columns
        fprintf(fid, 'name\ttype\tunits\tsignal_electrode\treference\tgroup\ttarget_muscle\tplacement_scheme\tplacement_description\tinterelectrode_distance\tlow_cutoff\thigh_cutoff\tsampling_frequency\n');
    else
        fprintf(fid, 'name\ttype\tunits\n');
    end
    acceptedChannelTypes = { 'AUDIO' 'EEG' 'EOG' 'ECG' 'EMG' 'EYEGAZE' 'GSR' 'HEOG' 'MISC' 'PUPIL' 'REF' 'RESP' 'SYSCLOCK' 'TEMP' 'TRIG' 'VEOG' };
    for iChan = 1:EEG.nbchan
        % Type
        if ~isfield(EEG.chanlocs, 'type') || isempty(EEG.chanlocs(iChan).type)
            type = 'n/a';
        elseif ismember(upper(EEG.chanlocs(iChan).type), acceptedChannelTypes)
            type = upper(EEG.chanlocs(iChan).type);
        else
            type = 'MISC';
        end
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

        %Write
        if isiEEG
            fprintf(fid, '%s\t%s\t%s\tn/a\tn/a\n', EEG.chanlocs(iChan).labels, type, unit);
        elseif isEMG
            % Extract EMG-specific fields (RECOMMENDED columns)
            signal_electrode = getfield_or_na(EEG.chanlocs(iChan), 'signal_electrode');
            reference = getfield_or_na(EEG.chanlocs(iChan), 'reference');
            group = getfield_or_na(EEG.chanlocs(iChan), 'group');
            target_muscle = getfield_or_na(EEG.chanlocs(iChan), 'target_muscle');
            placement_scheme = getfield_or_na(EEG.chanlocs(iChan), 'placement_scheme');
            placement_description = getfield_or_na(EEG.chanlocs(iChan), 'placement_description');
            interelectrode_distance = getfield_or_na(EEG.chanlocs(iChan), 'interelectrode_distance');
            low_cutoff = getfield_or_na(EEG.chanlocs(iChan), 'low_cutoff');
            high_cutoff = getfield_or_na(EEG.chanlocs(iChan), 'high_cutoff');
            sampling_frequency = getfield_or_na(EEG.chanlocs(iChan), 'sampling_frequency');

            fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
                EEG.chanlocs(iChan).labels, type, unit, signal_electrode, reference, ...
                group, target_muscle, placement_scheme, placement_description, ...
                interelectrode_distance, low_cutoff, high_cutoff, sampling_frequency);
        else
            fprintf(fid, '%s\t%s\t%s\n', EEG.chanlocs(iChan).labels, type, unit);
        end
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
