% BIDS_WRITEEMGTINFOFILE - write tinfo file for EMG data
%
% Usage:
%    bids_writeemgtinfofile(EEG, tinfo, notes, fileOut)
%
% Inputs:
%  EEG       - [struct] EEGLAB dataset information
%  tinfo     - [struct] structure containing task information
%  notes     - [string] notes to store along with the data info
%  fileOut   - [string] filepath of the desired output location with file basename
%                e.g. ~/BIDS_EXPORT/sub-01/ses-01/emg/sub-01_ses-01_task-holdWeight
%
% Copyright (C) 2025, Seyed Yahya Shirazi, SCCN, INC, UCSD
%
% Authors: Seyed Yahya Shirazi, 2025

function tInfo = bids_writeemgtinfofile(EEG, tInfo, notes, fileOutRed)

[~,channelsCount] = eeg_getchantype(EEG);

nonEmptyChannelTypes = fieldnames(channelsCount);
for i=1:numel(nonEmptyChannelTypes)
    if strcmp(nonEmptyChannelTypes{i}, 'MISC')
        tInfo.('MiscChannelCount') = channelsCount.('MISC');
    else
        tInfo.([nonEmptyChannelTypes{i} 'ChannelCount']) = channelsCount.(nonEmptyChannelTypes{i});
    end
end

if ~isfield(tInfo, 'EMGReference')
    if ~ischar(EEG.ref) && numel(EEG.ref) > 1
        refChanLocs = EEG.chanlocs(EEG.ref);
        ref = join({refChanLocs.labels},',');
        ref = ref{1};
    else
        ref = EEG.ref;
    end
    tInfo.EMGReference = ref;
end

if EEG.trials == 1
    tInfo.RecordingType = 'continuous';
    tInfo.RecordingDuration = EEG.pnts/EEG.srate;
else
    tInfo.RecordingType = 'epoched';
    tInfo.EpochLength = EEG.pnts/EEG.srate;
    tInfo.RecordingDuration = (EEG.pnts/EEG.srate)*EEG.trials;
end

tInfo.SamplingFrequency = EEG.srate;

if ~isempty(notes)
    tInfo.SubjectArtefactDescription = notes;
end

tInfoFields = {...
    'TaskName' 'REQUIRED' 'char' '';
    'TaskDescription' 'RECOMMENDED' 'char' '';
    'Instructions' 'RECOMMENDED' 'char' '';
    'CogAtlasID' 'RECOMMENDED' 'char' '';
    'CogPOID' 'RECOMMENDED' 'char' '';
    'InstitutionName' 'RECOMMENDED' 'char' '';
    'InstitutionAddress' 'RECOMMENDED' 'char' '';
    'InstitutionalDepartmentName' 'RECOMMENDED' 'char' '';
    'DeviceSerialNumber' 'RECOMMENDED' 'char' '';
    'SamplingFrequency' 'REQUIRED' '' '';
    'EMGChannelCount' 'RECOMMENDED' '' '';
    'EOGChannelCount' 'RECOMMENDED' '' 0;
    'ECGChannelCount' 'RECOMMENDED' '' 0;
    'EMGReference' 'REQUIRED' 'char' 'Unknown';
    'EMGGround' 'RECOMMENDED' 'char' '';
    'EMGPlacementScheme' 'REQUIRED' 'char' 'Other';
    'EMGPlacementSchemeDescription' 'RECOMMENDED' 'char' '';
    'PowerLineFrequency' 'REQUIRED' '' 'n/a';
    'MiscChannelCount' 'OPTIONAL' '' '';
    'TriggerChannelCount' 'RECOMMENDED' '' '';
    'Manufacturer' 'RECOMMENDED' 'char' '';
    'ManufacturersModelName' 'OPTIONAL' 'char' '';
    'ElectrodeManufacturer' 'RECOMMENDED' 'char' '';
    'ElectrodeManufacturersModelName' 'RECOMMENDED' 'char' '';
    'ElectrodeType' 'RECOMMENDED' 'char' '';
    'ElectrodeMaterial' 'RECOMMENDED' 'char' '';
    'InterelectrodeDistance' 'RECOMMENDED' '' '';
    'HardwareFilters' 'OPTIONAL' 'struct' 'n/a';
    'SoftwareFilters' 'REQUIRED' 'struct' 'n/a';
    'RecordingDuration' 'RECOMMENDED' '' 'n/a';
    'RecordingType' 'RECOMMENDED' 'char' '';
    'EpochLength' 'RECOMMENDED' '' 'n/a';
    'SoftwareVersions' 'RECOMMENDED' 'char' '';
    'SubjectArtefactDescription' 'OPTIONAL' 'char' '';
    'SkinPreparation' 'OPTIONAL' 'char' ''};

tInfo = bids_checkfields(tInfo, tInfoFields, 'tInfo');

if any(contains(tInfo.TaskName, '_')) || any(contains(tInfo.TaskName, ' '))
    error('Task name cannot contain underscore or space character(s)');
end

jsonwrite([fileOutRed '_emg.json'], tInfo, struct('indent','  '));