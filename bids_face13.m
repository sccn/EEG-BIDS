% Global settings
bidsOpt.FileExt = 'edf';
bidsOpt.InteralUse = true;

% Data
data(1).file = {'./sourcedata/merged/sub-s01_task-faceFO_eeg.set'};
data(1).session = 1;
data(1).run = 1;

data(2).file = {'./sourcedata/merged/sub-s02_task-faceFO_eeg.set'};
data(2).session = 1;
data(2).run = 1;

data(3).file = {'./sourcedata/merged/sub-s03_task-faceFO_eeg.set'};
data(3).session = 1;
data(3).run = 1;

data(4).file = {'./sourcedata/merged/sub-s04_task-faceFO_eeg.set'};
data(4).session = 1;
data(4).run = 1;

data(5).file = {'./sourcedata/merged/sub-s05_task-faceFO_eeg.set'};
data(5).session = 1;
data(5).run = 1;

data(6).file = {'./sourcedata/merged/sub-s06_task-faceFO_eeg.set'};
data(6).session = 1;
data(6).run = 1;

data(7).file = {'./sourcedata/merged/sub-s07_task-faceFO_eeg.set'};
data(7).session = 1;
data(7).run = 1;

data(8).file = {'./sourcedata/merged/sub-s08_task-faceFO_eeg.set'};
data(8).session = 1;
data(8).run = 1;

data(9).file = {'./sourcedata/merged/sub-s09_task-faceFO_eeg.set'};
data(9).session = 1;
data(9).run = 1;

data(10).file = {'./sourcedata/merged/sub-s10_task-faceFO_eeg.set'};
data(10).session = 1;
data(10).run = 1;

% general information for dataset_description.json file
% -----------------------------------------------------
generalInfo.Name = 'faceFO';

% Readme and changes
% -----------------------------------------------------
README = sprintf('# Face13 Dataset\n\nData used for JofV Deconstructing the early visual electrocortical response to face and house stimuli:\nhttps://jov.arvojournals.org/article.aspx?articleid=2121634');
% CHANGES = sprintf();

% Task information for xxxx-eeg.json file
% -----------------------------------------------------
% tInfo.TaskName = 'FaceHouseCheck'
% tInfo.TaskDescription = 'Visual presentation of oval cropped face and house images both upright and inverted. Rare left or right half oval checkerboards were presetned as targets for keypress response.';
% tInfo.InstitutionName =  'Brock University';
% tInfo.InstitutionAddress = '500 Glenridge Ave, St.Catharines, Ontario'
% tInfo.EOGChannelCount =  7;
% tInfo.EMGChannelCount =  0;
% tInfo.MiscChannelCount =  0;
% tInfo.TriggerChannelCount = 0;
% tInfo.PowerLineFrequency = 60;
% tInfo.EEGPlacementScheme = 'Custom equidistant 128 channel BioSemi montage established in coordination with Judith Schedden McMaster Univertisy';
% tInfo.Manufacturer = 'BioSemi';
% tInfo.ManufacturersModelName = 'ActiveTwo';
% tInfo.HardwareFilters = 'n/a';
% tInfo.SoftwareFilters = 'n/a';
% tInfo.SoftwareVersions = 'NI ActiView 532-Lores';
% tInfo.CapManufacturer = 'ElectroCap International';
% tInfo.CapManufacturersModelName = '10032';

% channel location file
% ---------------------
chanlocs = 'sourcedata/misc/BioSemi_BUCANL_EEGLAB.sfp';
           
% call to the export function
% ---------------------------
bids_export(data, 'targetdir', uigetdir, 'taskName', ...
    generalInfo.Name, 'gInfo', generalInfo,  ...
    'chanlocs', chanlocs, 'README', README, 'bidsOpt', bidsOpt);

disp('Done');

% bids_export(data, 'targetdir', '/Users/arno/temp/bids_meditation_export', 'taskName', ...
%     'meditation', 'trialtype', trialTypes, 'gInfo', generalInfo, 'pInfo', pInfo, ...
%     'pInfoDesc', pInfoDesc, 'eInfoDesc', eInfoDesc, 'README', README, ...
%     'CHANGES', CHANGES, 'stimuli', stimuli, 'codefiles', code, 'tInfo', tInfo, 'chanlocs', chanlocs);


% init_bids_sub_script('.','',... 'TaskName', 'FaceHouseCheck', ... 'TaskDescription', 'Visual presentation of oval cropped face and house images both upright and inverted. Rare left or right half oval checkerboards were presetned as targets for keypress response.', ... 'InstitutionName', 'Brock University', ... 'InstitutionAddress', '500 Glenridge Ave, St.Catharines, Ontario', ... 'EOGChannelCount', 7, ... 'EMGChannelCount', 0, ... 'MiscChannelCount', 0, ... 'TriggerChannelCount', 0, ... 'PowerLineFrequency', 60, ... 'EEGPlacementScheme', 'Custom equidistant 128 channel BioSemi montage established in coordination with Judith Schedden McMaster Univertisy', ... 'Manufacturer', 'BioSemi', ... 'ManufacturersModelName', 'ActiveTwo', ... 'HardwareFilters', 'n/a', ... 'SoftwareFilters', 'n/a', ... 'SoftwareVersions', 'NI ActiView 532-Lores', ... 'CapManufacturer', 'ElectroCap International', ... 'CapManufacturersModelName', '10032');

