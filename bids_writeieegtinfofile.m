% BIDS_WRITETIEEGINFOFILE - write tinfo file for iEEG data
%
% Usage:
%    bids_writetinfofile(EEG, tinfo, fileOut)
%
% Inputs:
%  EEG       - [struct] EEGLAB dataset information
%  tinfo     - [struct] structure containing task information
%  notes     - [string] notes to store along with the data info
%  fileOut   - [string] filepath of the desired output location with file basename
%                e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo
%
% Authors: Arnaud Delorme, 2024

function tInfo = bids_writeieegtinfofile( EEG, tInfo, notes, fileOutRed)

[~,channelsCount] = eeg_getchantype(EEG);

% Write task information (ieeg.json) Note: depends on channels
% requiredChannelTypes: 'EEG', 'EOG', 'ECG', 'EMG', 'MISC'. Other channel
% types are currently not valid output for ieeg.json.
nonEmptyChannelTypes = fieldnames(channelsCount);
for i=1:numel(nonEmptyChannelTypes)
    if strcmp(nonEmptyChannelTypes{i}, 'MISC')
        tInfo.('MiscChannelCount') = channelsCount.('MISC');
    else
        tInfo.([nonEmptyChannelTypes{i} 'ChannelCount']) = channelsCount.(nonEmptyChannelTypes{i});
    end
end

if ~isfield(tInfo, 'EEGReference')
    if ~ischar(EEG.ref) && numel(EEG.ref) > 1 % untested for all cases
        refChanLocs = EEG.chanlocs(EEG.ref);
        ref = join({refChanLocs.labels},',');
        ref = ref{1};
    else
        ref = EEG.ref;
    end
    tInfo.iEEGReference    = ref;
end
if EEG.trials == 1
    tInfo.RecordingType = 'continuous';
else
    tInfo.RecordingType = 'epoched';
    tInfo.EpochLength = EEG.pnts/EEG.srate;
end
tInfo.RecordingDuration = EEG.pnts/EEG.srate;
tInfo.SamplingFrequency = EEG.srate;
if ~isempty(notes)
    tInfo.SubjectArtefactDescription = notes;
end

% https://bids-specification.readthedocs.io/en/stable/modality-specific-files/intracranial-electroencephalography.html
tInfoFields = {...
    'iEEGReference' 'REQUIRED' 'char' 'Unknown';
    'SamplingFrequency' 'REQUIRED' '' '';
    'PowerLineFrequency' 'REQUIRED' '' 'n/a';
    'SoftwareFilters' 'REQUIRED' 'struct' 'n/a';
    ...
    'HardwareFilters' 'RECOMMENDED' 'struct' '';
    'ElectrodeManufacturer' 'RECOMMENDED' 'struct' '';
    'ElectrodeManufacturersModelName' 'RECOMMENDED' 'struct' '';
    'ECOGChannelCount' 'RECOMMENDED' '' '';
    'SEEGChannelCount' 'RECOMMENDED' '' '';
    'EEGChannelCount' 'RECOMMENDED' '' '';
    'EOGChannelCount' 'RECOMMENDED' '' 0;
    'ECGChannelCount' 'RECOMMENDED' '' 0;
    'EMGChannelCount' 'RECOMMENDED' '' 0;
    'MiscChannelCount' ' OPTIONAL' '' '';
    'TriggerChannelCount' 'RECOMMENDED' '' ''; % double in Bucanl's fork
    'RecordingDuration' 'RECOMMENDED' '' 'n/a';
    'RecordingType' 'RECOMMENDED' 'char' '';
    'EpochLength' 'RECOMMENDED' '' 'n/a';
    'iEEGGround'  'RECOMMENDED ' 'char' '';
    'iEEGPlacementScheme' 'RECOMMENDED' 'char' '';
    'iEEGElectrodeGroups' 'RECOMMENDED' 'char' '';
    'SubjectArtefactDescription' 'OPTIONAL' 'char' '';
    ...
    'ElectricalStimulation' 'OPTIONAL' 'char' '';
    'ElectricalStimulationParameters' 'OPTIONAL' 'char' '';
    ...
    'Manufacturer' 'RECOMMENDED' 'char' '';
    'ManufacturersModelName' 'OPTIONAL' 'char' '';
    'SoftwareVersions' 'RECOMMENDED' 'char' '';
    'DeviceSerialNumber' 'RECOMMENDED' 'char' '';
    ...
    'TaskName' 'REQUIRED' '' '';
    'TaskDescription' 'RECOMMENDED' '' '';
    'Instructions' 'RECOMMENDED' 'char' '';
    'CogAtlasID' 'RECOMMENDED' 'char' '';
    'CogPOID' 'RECOMMENDED' 'char' '';
    ...
    'InstitutionName' 'RECOMMENDED' 'char' '';
    'InstitutionAddress' 'RECOMMENDED' 'char' '';
    'InstitutionalDepartmentName' ' RECOMMENDED' 'char' '';
    };
tInfo = bids_checkfields(tInfo, tInfoFields, 'tInfo');

jsonwrite([fileOutRed '_ieeg.json' ], tInfo,struct('indent','  '));