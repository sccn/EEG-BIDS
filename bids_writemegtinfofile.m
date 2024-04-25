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

function tInfo = bids_writemegtinfofile( EEG, tInfo, notes, fileOutRed)

[~,channelsCount] = eeg_getchantype(EEG);

% Write task information (meg.json) Note: depends on channels
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

tInfoFields = {...
    'iEEGReference' 'REQUIRED' 'char' 'Unknown';
    'SamplingFrequency' 'REQUIRED' '' '';
    'PowerLineFrequency' 'REQUIRED' '' 'n/a';
    'DewarPosition' 'REQUIRED' '' '';
    'SoftwareFilters' 'REQUIRED' 'struct' 'n/a';
    'DigitizedLandmarks', 'REQUIRED', '' '';
    'DigitizedHeadPoints', 'REQUIRED', '' '';
    ...    
    'MEGChannelCount' 'RECOMMENDED' '' '';
    'MEGREFChannelCount' 'RECOMMENDED' '' '';
    'EEGChannelCount' 'RECOMMENDED' '' '';
    'ECOGChannelCount' 'RECOMMENDED' '' '';
    'SEEGChannelCount' 'RECOMMENDED' '' '';
    'EOGChannelCount' 'RECOMMENDED' '' 0;
    'ECGChannelCount' 'RECOMMENDED' '' 0;
    'EMGChannelCount' 'RECOMMENDED' '' 0;
    'MiscChannelCount' ' OPTIONAL' '' '';
    'TriggerChannelCount' 'RECOMMENDED' '' ''; % double in Bucanl's fork
    'RecordingDuration' 'RECOMMENDED' '' 'n/a';
    'RecordingType' 'RECOMMENDED' 'char' '';
    'EpochLength' 'RECOMMENDED' '' 'n/a';
    'ContinuousHeadLocalization' 'RECOMMENDED' '' '';
    'HeadCoilFrequency' 'RECOMMENDED' '' '';
    'MaxMovement' 'RECOMMENDED' '' '';
    'SubjectArtefactDescription' 'RECOMMENDED' 'char' '';
    'AssociatedEmptyRoom' 'RECOMMENDED' '' '';
    'HardwareFilters' 'RECOMMENDED' 'struct' '';    
    ...
    'ElectricalStimulation' 'OPTIONAL' '' '';
    'ElectricalStimulationParameters' 'OPTIONAL' 'char' '';
    ...
    'Manufacturer' 'RECOMMENDED' 'char' '';
    'ManufacturersModelName' 'RECOMMENDED' 'char' '';
    'SoftwareVersions' 'RECOMMENDED' 'char' '';
    'DeviceSerialNumber' 'RECOMMENDED' 'char' '';
    ...
    'TaskName' 'REQUIRED' 'char' '';
    'TaskDescription' 'RECOMMENDED' 'char' '';
    'Instructions' 'RECOMMENDED' 'char' '';
    'CogAtlasID' 'RECOMMENDED' 'char' '';
    'CogPOID' 'RECOMMENDED' 'char' '';
    ...
    'InstitutionName' 'RECOMMENDED' 'char' '';
    'InstitutionAddress' 'RECOMMENDED' 'char' '';
    'InstitutionalDepartmentName' 'RECOMMENDED' 'char' '';
    ...
    'EEGPlacementScheme' 'OPTIONAL' 'char' '';
    'CapManufacturer' ' OPTIONAL' 'char' '';
    'CapManufacturersModelName' ' OPTIONAL' 'char' '';
    'EEGReference' ' OPTIONAL' 'char' '';
    };
tInfo = bids_checkfields(tInfo, tInfoFields, 'tInfo');

jsonwrite([fileOutRed '_meg.json' ], tInfo,struct('indent','  '));