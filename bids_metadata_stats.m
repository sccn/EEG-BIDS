% BIDS_METADATA_STATS - Check the BIDS metadata content
%
% Usage:
%   >> stats = bids_metadata_stats(bids);
%
% Inputs:
%   bids - [struct] BIDS structure (for example ALLEEG(1).BIDS)
%
% Outputs:
%   stats   - BIDS metadata statistics structure
%
% Authors: Arnaud Delorme and Dung Truong, SCCN, INC, UCSD, February, 2024

% Copyright (C) Arnaud Delorme, 2024
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
% along with this program; if not, to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function stats = bids_metadata_stats(bids, inconsistentChannels)

if nargin < 2
    help bids_metadata_stats;
end
inconsistentEvents = 0;
if nargin < 3
    inconsistentChannels = 0;
end

% compute basic statistics
stats.README             = 0;
stats.EthicsApprovals    = 0;
stats.TaskDescription    = 0;
stats.Instructions       = 0;
stats.EEGReference       = 0;
stats.PowerLineFrequency = 0;
stats.ChannelTypes       = 0;
stats.ElectrodePositions = 0;
stats.ParticipantsAgeAndGender = 0;
stats.SubjectArtefactDescription = 0;
stats.EventConsistency   = 0;
stats.ChannelConsistency = 0;
stats.EventDescription   = 0;
stats.StandardChannelLabels = 0;
if ~isempty(bids.README), stats.README = 1; end
if isfield(bids.dataset_description, 'EthicsApprovals') stats.EthicsApprovals = 1; end
if ismember('age', lower(bids.participants(1,:)))
    if ismember('gender', lower(bids.participants(1,:))) || ismember('sex', lower(bids.participants(1,:)))
        stats.ParticipantsAgeAndGender = 1; 
    end
end
if checkBIDSfield(bids, 'TaskDescription'),            stats.TaskDescription = 1; end
if checkBIDSfield(bids, 'Instructions'),               stats.Instructions = 1; end
if checkBIDSfield(bids, 'EEGReference'),               stats.EEGReference = 1; end
if checkBIDSfield(bids, 'PowerLineFrequency'),         stats.PowerLineFrequency = 1; end
if isfield(bids.data, 'chaninfo') && ~isempty(bids.data(1).chaninfo) && ~isempty(strmatch('type', lower(bids.data(1).chaninfo(1,:)), 'exact'))
    stats.ChannelTypes = 1;
end
if checkBIDSfield(bids, 'elecinfo'),                   stats.ElectrodePositions = 1; end
if checkBIDSfield(bids, 'eventdesc'),                  stats.EventDescription   = 1; end
if checkBIDSfield(bids, 'SubjectArtefactDescription'), stats.SubjectArtefactDescription   = 1; end

stats.ChannelConsistency = fastif(inconsistentChannels > 0, 0, 1);
stats.EventConsistency   = fastif(inconsistentEvents   > 0, 0, 1);
if isfield(bids.data, 'chaninfo') && size(bids.data(1).chaninfo, 1) > 1
    chanLabels = bids.data(1).chaninfo(2:end,1);
    standardLabels = { 'Fp1' 'Fpz' 'Fp2' 'AF9' 'AF7' 'AF5' 'AF3' 'AF1' 'AFz' 'AF2' 'AF4' 'AF6' 'AF8' 'AF10' 'F9' 'F7' 'F5' 'F3' 'F1' 'Fz' 'F2' 'F4' 'F6' 'F8' 'F10' 'FT9' 'FT7' 'FC5' 'FC3' 'FC1' 'FCz' 'FC2' 'FC4' 'FC6' 'FT8' 'FT10' 'T9' 'T7' 'C5' 'C3' 'C1' 'Cz' 'C2' 'C4' 'C6' 'T8' 'T10' 'TP9' 'TP7' 'CP5' 'CP3' 'CP1' 'CPz' 'CP2' 'CP4' 'CP6' 'TP8' 'TP10' 'P9' 'P7' 'P5' 'P3' 'P1' 'Pz' 'P2' 'P4' 'P6' 'P8' 'P10' 'PO9' 'PO7' 'PO5' 'PO3' 'PO1' 'POz' 'PO2' 'PO4' 'PO6' 'PO8' 'PO10' 'O1' 'Oz' 'O2' 'I1' 'Iz' 'I2' 'AFp9h' 'AFp7h' 'AFp5h' 'AFp3h' 'AFp1h' 'AFp2h' 'AFp4h' 'AFp6h' 'AFp8h' 'AFp10h' 'AFF9h' 'AFF7h' 'AFF5h' 'AFF3h' 'AFF1h' 'AFF2h' 'AFF4h' 'AFF6h' 'AFF8h' 'AFF10h' 'FFT9h' 'FFT7h' 'FFC5h' 'FFC3h' 'FFC1h' 'FFC2h' 'FFC4h' 'FFC6h' 'FFT8h' 'FFT10h' 'FTT9h' 'FTT7h' 'FCC5h' 'FCC3h' 'FCC1h' 'FCC2h' 'FCC4h' 'FCC6h' 'FTT8h' 'FTT10h' 'TTP9h' 'TTP7h' 'CCP5h' 'CCP3h' 'CCP1h' 'CCP2h' 'CCP4h' 'CCP6h' 'TTP8h' 'TTP10h' 'TPP9h' 'TPP7h' 'CPP5h' 'CPP3h' 'CPP1h' 'CPP2h' 'CPP4h' 'CPP6h' 'TPP8h' 'TPP10h' 'PPO9h' 'PPO7h' 'PPO5h' 'PPO3h' 'PPO1h' 'PPO2h' 'PPO4h' 'PPO6h' 'PPO8h' 'PPO10h' 'POO9h' 'POO7h' 'POO5h' 'POO3h' 'POO1h' 'POO2h' 'POO4h' 'POO6h' 'POO8h' 'POO10h' 'OI1h' 'OI2h' 'Fp1h' 'Fp2h' 'AF9h' 'AF7h' 'AF5h' 'AF3h' 'AF1h' 'AF2h' 'AF4h' 'AF6h' 'AF8h' 'AF10h' 'F9h' 'F7h' 'F5h' 'F3h' 'F1h' 'F2h' 'F4h' 'F6h' 'F8h' 'F10h' 'FT9h' 'FT7h' 'FC5h' 'FC3h' 'FC1h' 'FC2h' 'FC4h' 'FC6h' 'FT8h' 'FT10h' 'T9h' 'T7h' 'C5h' 'C3h' 'C1h' 'C2h' 'C4h' 'C6h' 'T8h' 'T10h' 'TP9h' 'TP7h' 'CP5h' 'CP3h' 'CP1h' 'CP2h' 'CP4h' 'CP6h' 'TP8h' 'TP10h' 'P9h' 'P7h' 'P5h' 'P3h' 'P1h' 'P2h' 'P4h' 'P6h' 'P8h' 'P10h' 'PO9h' 'PO7h' 'PO5h' 'PO3h' 'PO1h' 'PO2h' 'PO4h' 'PO6h' 'PO8h' 'PO10h' 'O1h' 'O2h' 'I1h' 'I2h' 'AFp9' 'AFp7' 'AFp5' 'AFp3' 'AFp1' 'AFpz' 'AFp2' 'AFp4' 'AFp6' 'AFp8' 'AFp10' 'AFF9' 'AFF7' 'AFF5' 'AFF3' 'AFF1' 'AFFz' 'AFF2' 'AFF4' 'AFF6' 'AFF8' 'AFF10' 'FFT9' 'FFT7' 'FFC5' 'FFC3' 'FFC1' 'FFCz' 'FFC2' 'FFC4' 'FFC6' 'FFT8' 'FFT10' 'FTT9' 'FTT7' 'FCC5' 'FCC3' 'FCC1' 'FCCz' 'FCC2' 'FCC4' 'FCC6' 'FTT8' 'FTT10' 'TTP9' 'TTP7' 'CCP5' 'CCP3' 'CCP1' 'CCPz' 'CCP2' 'CCP4' 'CCP6' 'TTP8' 'TTP10' 'TPP9' 'TPP7' 'CPP5' 'CPP3' 'CPP1' 'CPPz' 'CPP2' 'CPP4' 'CPP6' 'TPP8' 'TPP10' 'PPO9' 'PPO7' 'PPO5' 'PPO3' 'PPO1' 'PPOz' 'PPO2' 'PPO4' 'PPO6' 'PPO8' 'PPO10' 'POO9' 'POO7' 'POO5' 'POO3' 'POO1' 'POOz' 'POO2' 'POO4' 'POO6' 'POO8' 'POO10' 'OI1' 'OIz' 'OI2' 'T3' 'T5' 'T4' 'T6' 'M1' 'M2' 'A1' 'A2' 'O9' 'O10' };
    if ischar(chanLabels{1}) && length(intersect(lower(chanLabels), lower(standardLabels))) > length(chanLabels)/2
        stats.StandardChannelLabels = 1;
    end
end

% check BIDS data field present
% -----------------------------
function res = checkBIDSfield(bids, fieldName)
res = false;
if isfield(bids.data, fieldName)
    fieldContent = { bids.data.(fieldName) };
    fieldContent(cellfun(@isempty, fieldContent)) = [];
    if ~isempty(fieldContent), res = true; end
end
