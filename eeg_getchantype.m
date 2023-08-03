function EEG = eeg_getchantype(EEG)

template_file = fullfile(fileparts(which('eeglab')),'sample_locs/Standard-10-20-Cap81.locs');
if exist(template_file, 'file')
    locs = readtable(template_file,'Delimiter','\t', 'FileType','text');
    eeg_chans = locs.Var4;
else
    eeg_chans = '';
end

% Assign channel types based on channel name
% types retrived from https://bids-specification.readthedocs.io/en/stable/glossary.html#objects.columns.type__eeg_channels
types = {'EEG', 'EMG', 'EOG', 'ECG', 'EKG', 'TRIG', 'GSR', 'PPG', 'MISC'};
for i = 1:length(EEG.chanlocs)
    label = EEG.chanlocs(i).labels;
    matchIdx = cellfun(@(x) contains(lower(label), lower(x)), types);

    if any(matchIdx)
        EEG.chanlocs(i).type = types{matchIdx};
    elseif any(strcmpi(label, eeg_chans))
        EEG.chanlocs(i).type = 'EEG';
    end
end

