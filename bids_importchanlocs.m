% eeg_importchanlocs - import channel info from channels.tsv and electrodes.tsv%
% Usage:
%    [EEG, channelData, elecData] = eeg_importchanlocs(EEG, channelFile, elecFile)
%
% Inputs:
%  'EEG'         - [struct] the EEG structure
%
%  'channelFile' - [string] full path to the channels.tsv file
%                   e.g.
%                   ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo_channels.tsv
%  'elecFile'    - [string] full path to the electrodes.tsv file
%                  e.g.
%                  ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo_electrodes.tsv
%
% Outputs:
%
%   EEG         - [struct] the EEG structure with channel info imported
%
%   channelData - [cell array] imported data from channels.tsv
%
%   elecData    - [cell array] imported data from electrodes.tsv
%
% Authors: Dung Truong, Arnaud Delorme, 2022

function [EEG, channelData, elecData] = bids_importchanlocs(EEG, channelFile, elecFile)
    channelData = bids_loadfile(channelFile, '');
    elecData    = bids_loadfile(elecFile, '');
    if isfield(EEG, 'chanlocs')
        chanlocs = EEG.chanlocs;
    else
        chanlocs = [];
    end
    if isempty(channelData) && isempty(elecData)
        return
    end
    % channels.tsv: name, type and units are the first three columns (BIDS);
    % optional columns such as status come in any order, so they are found by
    % their header. Reading status from column 4 put low_cutoff values into
    % chanlocs.status on iEEG datasets (e.g. OpenNeuro ds004696, ds004080).
    colStatus = []; colStatusDesc = [];
    if size(channelData,2) > 1
        colStatus     = find(strcmpi(channelData(1,:), 'status'), 1);
        colStatusDesc = find(strcmpi(channelData(1,:), 'status_description'), 1);
    end
    for iChan = 2:size(channelData,1)
        if size(channelData,2) == 1
            fprintf('Warning: BIDS channel data missing tab characters\n')
            [chanlocs(iChan-1).labels ,toktmp] = strtok(channelData{iChan,1});
            [chanlocs(iChan-1).type   ,toktmp] = strtok(toktmp);
            [chanlocs(iChan-1).unit   ,toktmp] = strtok(toktmp);
        else
            % the fields below are all required
            chanlocs(iChan-1).labels = channelData{iChan,1};
            chanlocs(iChan-1).type   = channelData{iChan,2};
            chanlocs(iChan-1).unit   = channelData{iChan,3};
            if ~isempty(colStatus)
                chanlocs(iChan-1).status = channelData{iChan,colStatus};
            end
            if ~isempty(colStatusDesc)
                chanlocs(iChan-1).status_description = channelData{iChan,colStatusDesc};
            end
        end
    end

    % electrodes.tsv: BIDS does not require it to list the same channels in the
    % same order as channels.tsv (iEEG files often leave out contacts without
    % coordinates). When the names line up row by row, rows are used by position
    % as before (including extra rows, such as an EGI reference). Otherwise they
    % are matched to channels by name: assigning them by position relabelled the
    % data rows, e.g. 27 of 30 contacts of sub-02 on OpenNeuro ds004696.
    if size(elecData,1) > 1
        colCoordSys = find(strcmpi(elecData(1,:), 'coordinate_system'), 1); % EMG
        elecNames = cellfun(@local_str, elecData(2:end,1), 'UniformOutput', false);
        byName = false;
        if size(channelData,1) > 1 && ~isempty(chanlocs)
            chanNames = cellfun(@local_str, {chanlocs.labels}, 'UniformOutput', false);
            nCommon = min(numel(chanNames), numel(elecNames));
            byName = ~isequal(lower(chanNames(1:nCommon)), lower(elecNames(1:nCommon)'));
        end
        nIgnored = 0;
        for iElec = 2:size(elecData,1)
            if byName
                iChan = find(strcmpi(chanNames, elecNames{iElec-1}), 1);
                if isempty(iChan), nIgnored = nIgnored + 1; continue; end
            else
                iChan = iElec - 1;
                chanlocs(iChan).labels = elecData{iElec,1};
            end
            chanlocs(iChan).X = elecData{iElec,2};
            chanlocs(iChan).Y = elecData{iElec,3};
            chanlocs(iChan).Z = elecData{iElec,4};
            if ~isempty(colCoordSys) && ~isempty(elecData{iElec,colCoordSys}) && ~strcmpi(elecData{iElec,colCoordSys}, 'n/a')
                chanlocs(iChan).coordinate_system = elecData{iElec,colCoordSys};
            end
        end
        if byName
            fprintf('Electrode positions matched to channels by name (the electrodes file lists another order or subset)\n');
            if nIgnored > 0
                fprintf('%d electrode(s) in the electrodes file match no channel and were ignored\n', nIgnored);
            end
        end
    end

    if length(chanlocs) == EEG.nbchan+1 && isequal(lower(chanlocs(end).labels), 'cz') % EGI
        chanlocs(end).type = 'FID';
        [chanlocs(1:end-1).type] = deal('EEG');
    end
    [chanlocs,chaninfo] = eeg_checkchanlocs(chanlocs);

    if length(chanlocs) ~= EEG.nbchan
        warning('Different number of channels in channel location file and EEG file');
        % check if the difference is due to non EEG channels
        % list here https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/03-electroencephalography.html
        keep = {'EEG','EOG','HEOG','VEOG'}; % keep all eeg related channels
        tsv_eegchannels  = arrayfun(@(x) sum(strcmpi(x.type,keep)),chanlocs,'UniformOutput',true);
        tmpchanlocs = chanlocs; tmpchanlocs(tsv_eegchannels==0)=[]; % remove non eeg related channels
        chanlocs = tmpchanlocs; clear tmpchanlocs
    end

    if length(chanlocs) ~= EEG.nbchan
        if ~isempty(EEG.chanlocs)
            warning('channel location file and EEG file do not have the same number of channels - ignoring channel location BIDS files');
            chanlocs = EEG.chanlocs;
            chaninfo = EEG.chaninfo;
        else
            error('channel location file and EEG file do not have the same number of channels (and no channel location in the EEG file)');
        end
    end
    EEG.chanlocs = chanlocs;
    EEG.chaninfo = chaninfo;
end

function s = local_str(x)
% channel name as text (bids_loadfile turns numeric-looking names into numbers)
if ischar(x), s = strtrim(x); elseif isstring(x), s = strtrim(char(x)); else, s = num2str(x); end
end
