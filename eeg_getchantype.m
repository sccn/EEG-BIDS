function EEG = eeg_chantype(EEG)
    % Assign channel types based on channel name
    % types retrived from https://bids-specification.readthedocs.io/en/stable/glossary.html#objects.columns.type__eeg_channels
    types = {'EEG', 'EMG', 'EOG', 'ECG', 'EKG', 'TRIG', 'GSR', 'PPG', 'MISC'};
    for i = 1:length(EEG.chanlocs)
        label = EEG.chanlocs(i).labels;
        matchIdx = cellfun(@(x) contains(lower(label), lower(x)), types);

        if any(matchIdx)
            EEG.chanlocs(i).type = types{matchIdx};
        elseif is_eeg_chan(label)
            EEG.chanlocs(i).type = 'EEG';
        end
    end

    function isEEG = is_eeg_chan(chan)
        template_file = fullfile(fileparts(which('eeglab')),'sample_locs/Standard-10-20-Cap81.locs');
        if exist(template_file, 'file')
            locs = readtable(template_file,'Delimiter','\t', 'FileType','text');
            eeg_chans = locs.Var4;
            isEEG = any(strcmpi(chan, eeg_chans));
        else
            warning('Could not find standard 10-20 channel locations file. Failed to determine if channel is EEG using names.')
            isEEG = false;
        end
    end
end