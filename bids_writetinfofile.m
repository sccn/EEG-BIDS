% BIDS_WRITETINFOFILE - write tinfo file
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
% Authors: Arnaud Delorme, 2023

function tInfo = bids_writetinfofile( EEG, tInfo, notes, fileOutRed)

[~,channelsCount] = eeg_getchantype(EEG);

% Write task information (eeg.json) Note: depends on channels
% requiredChannelTypes: 'EEG', 'EOG', 'ECG', 'EMG', 'MISC'. Other channel
% types are currently not valid output for eeg.json.
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
    tInfo.EEGReference    = ref;
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
    'TaskName' 'REQUIRED' '' '';
    'TaskDescription' 'RECOMMENDED' '' '';
    'Instructions' 'RECOMMENDED' 'char' '';
    'CogAtlasID' 'RECOMMENDED' 'char' '';
    'CogPOID' 'RECOMMENDED' 'char' '';
    'InstitutionName' 'RECOMMENDED' 'char' '';
    'InstitutionAddress' 'RECOMMENDED' 'char' '';
    'InstitutionalDepartmentName' ' RECOMMENDED' 'char' '';
    'DeviceSerialNumber' 'RECOMMENDED' 'char' '';
    'SamplingFrequency' 'REQUIRED' '' '';
    'EEGChannelCount' 'RECOMMENDED' '' '';
    'EOGChannelCount' 'RECOMMENDED' '' 0;
    'ECGChannelCount' 'RECOMMENDED' '' 0;
    'EMGChannelCount' 'RECOMMENDED' '' 0;
    'EEGReference' 'REQUIRED' 'char' 'Unknown';
    'PowerLineFrequency' 'REQUIRED' '' 'n/a';
    'EEGGround' 'RECOMMENDED ' 'char' '';
    'HeadCircumference' 'OPTIONAL ' '' 0;
    'MiscChannelCount' ' OPTIONAL' '' '';
    'TriggerChannelCount' 'RECOMMENDED' '' ''; % double in Bucanl's fork
    'EEGPlacementScheme' 'RECOMMENDED' 'char' '';
    'Manufacturer' 'RECOMMENDED' 'char' '';
    'ManufacturersModelName' 'OPTIONAL' 'char' '';
    'CapManufacturer' 'RECOMMENDED' 'char' 'Unknown';
    'CapManufacturersModelName' 'OPTIONAL' 'char' '';
    'HardwareFilters' 'OPTIONAL' 'struct' 'n/a';
    'SoftwareFilters' 'REQUIRED' 'struct' 'n/a';
    'RecordingDuration' 'RECOMMENDED' '' 'n/a';
    'RecordingType' 'RECOMMENDED' 'char' '';
    'EpochLength' 'RECOMMENDED' '' 'n/a';
    'SoftwareVersions' 'RECOMMENDED' 'char' '';
    'SubjectArtefactDescription' 'OPTIONAL' 'char' '' };
tInfo = bids_checkfields(tInfo, tInfoFields, 'tInfo');
if any(contains(tInfo.TaskName, '_')) || any(contains(tInfo.TaskName, ' '))
    error('Task name cannot contain underscore or space character(s)');
end

jsonwrite([fileOutRed '_eeg.json' ], tInfo,struct('indent','  '));