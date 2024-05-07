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
            if size(channelData,2) > 3
                chanlocs(iChan-1).status = channelData{iChan,4};
            end
        end
    end
    for iChan = 2:size(elecData,1)
        if ~isempty(elecData) && iChan <= size(elecData,1)
            chanlocs(iChan-1).labels = elecData{iChan,1};
            chanlocs(iChan-1).X = elecData{iChan,2};
            chanlocs(iChan-1).Y = elecData{iChan,3};
            chanlocs(iChan-1).Z = elecData{iChan,4};
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
