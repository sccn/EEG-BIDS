% EEG_GETCHANTYPE - get the count for each channel type. Also assign
%                   automatically channel types if they are not yet present.
%
% Usage:
%   >> [OUTEEG,chancount] = eeg_getchantype(INEEG);
%
% Inputs:
%   INEEG         - input EEG dataset structure
%
% Outputs:
%   OUTEEG        - new EEG dataset structure
%   chancount     - structure containing channel type information
% 
% Author: Arnaud Delorme, SCCN/INC/UCSD, 2023-
% 
% see also: EEGLAB

% Copyright (C) 2023 Arnaud Delorme, SCCN/INC/UCSD
%
% This file is part of EEGLAB, see http://www.eeglab.org
% for the documentation and details.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

function [EEG,channelsCount] = eeg_getchantype(EEG)

template_file = fullfile(fileparts(which('eeglab')),'sample_locs/Standard-10-20-Cap81.locs');
if exist(template_file, 'file')
    locs = readtable(template_file,'Delimiter','\t', 'FileType','text');
    eeg_chans = locs.Var4;
else
    eeg_chans = '';
end

% Assign channel types based on channel name
% types retrived from https://bids-specification.readthedocs.io/en/stable/glossary.html#objects.columns.type__eeg_channels
types = {'EEG', 'MEG', 'MEGREF', 'SEEG', 'EMG', 'EOG', 'ECG', 'EKG', 'EMG', 'TRIG', 'GSR', 'PPG', 'MISC'};

for i = 1:length(EEG.chanlocs)
    label = EEG.chanlocs(i).labels;
    matchIdx = cellfun(@(x) contains(lower(label), lower(x)), types);

    if any(matchIdx)
        EEG.chanlocs(i).type = types{matchIdx};
    elseif any(strcmpi(label, eeg_chans)) && ( ~isfield(EEG.chanlocs, 'type') || isempty(EEG.chanlocs(i).type) || all(isnan(EEG.chanlocs(i).type)) || isequal(lower(EEG.chanlocs(i).type), 'n/a'))
        EEG.chanlocs(i).type = 'EEG';
    end
end
channelsCount = count_channel(EEG);

%% ----------------------------
function channelsCount = count_channel(EEG)

if isempty(EEG.chanlocs)
    channelsCount = struct([]);
else
    acceptedChannelTypes = { 'AUDIO' 'EEG' 'MEG' 'MEGREF' 'SEEG' 'EOG' 'ECG' 'EMG' 'EYEGAZE' 'GSR' 'HEOG' 'MISC' 'PUPIL' 'REF' 'RESP' 'SYSCLOCK' 'TEMP' 'TRIG' 'VEOG' };
    channelsCount = [];
    channelsCount.EEG = 0;
    for iChan = 1:EEG.nbchan
        % Type
        if ~isfield(EEG.chanlocs, 'type') || isempty(EEG.chanlocs(iChan).type) || isnan(EEG.chanlocs(iChan).type(1))
            type = 'n/a';
        elseif ismember(upper(EEG.chanlocs(iChan).type), acceptedChannelTypes)
            type = upper(EEG.chanlocs(iChan).type);
        else
            type = 'MISC';
        end
        % Unit
        if strcmpi(type, 'eeg')
            unit = 'uV';
        else
            unit = 'n/a';
        end

        % Count channels by type (for use later in eeg.json)
        if strcmp(type, 'n/a')
            channelsCount.('EEG') = channelsCount.('EEG') + 1;
        else
            if ~isfield(channelsCount, type), channelsCount.(type) = 0; end
            if strcmp(type, 'HEOG') || strcmp(type,'VEOG')
                if ~isfield(channelsCount, 'EOG')
                    channelsCount.('EOG') = 1;
                else
                    channelsCount.('EOG') = channelsCount.('EOG') + 1;
                end
            else
                channelsCount.(type) = channelsCount.(type) + 1;
            end
        end

    end
end


