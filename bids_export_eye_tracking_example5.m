% Example to export joint EEG and Eye-tracking data (child mind)
% The data is included in this repository (on Github, maybe not on the 
% plugin downloaded from EEGLAB).
%
% THIS PLUGIN REQUIRES THE INSTALLATION OF THE GAZEPOINT AND SMI EEGLAB PLUGINS
% 
% Arnaud Delorme - December 2023

clear
data = [];
p =fileparts(which('bids_export_example5_eye'));
data(end+1).file     = { fullfile(p,'testing','hbn_eye_tracking_data','NDARAA773LUW_SurroundSupp_Block1.set') };
data(end  ).eyefile  = { fullfile(p,'testing','hbn_eye_tracking_data','NDARAA773LUW_SurrSupp_Block1.tsv') }; % Gazepoint eye tracking format 
data(end+1).file     = { fullfile(p,'testing','hbn_eye_tracking_data','NDARAA075AMK_Video1.set') };
data(end  ).eyefile  = { fullfile(p,'testing','hbn_eye_tracking_data','NDARAA075AMK_Video1_Samples.txt') }; % SMI eye tracking format

%% participant information for participants.tsv file
% -------------------------------------------------
pInfo = { 'participantID';
          'NDARAA773LUW';
          'NDARAA075AMK' }

%% Code Files used to preprocess and import to BIDS
% -----------------------------------------------------|
codefiles = { fullfile(pwd, mfilename) };

%% general information for dataset_description.json file
% -----------------------------------------------------
generalInfo.Name = 'Test';
generalInfo.ReferencesAndLinks = { 'No bibliographic reference other than the DOI for this dataset' };
generalInfo.BIDSVersion = 'v1.2.1';
generalInfo.License = 'CC0';
generalInfo.Authors = { 'Arnaud Delorme' 'Deepa Gupta' };

%% participant column description for participants.json file
% ---------------------------------------------------------
pInfoDesc.participant_id.LongName    = 'Participant identifier';
pInfoDesc.participant_id.Description = 'Unique participant identifier';

%% Content for README file
% -----------------------
README = [ 'This is a test export containing joint eye tracking and EEG data' ];

%% Content for CHANGES file
% ------------------------
CHANGES = sprintf([ 'Version 1.0 - 12 December 2023\n' ...
                    ' - Initial release\n' ]);

%% Task information for xxxx-eeg.json file
% ---------------------------------------
tInfo.InstitutionAddress = '9500 Gilman Drive, La Jolla CA 92093, USA';
tInfo.InstitutionName = 'University of California, San Diego';
tInfo.InstitutionalDepartmentName = 'Institute of Neural Computation';
tInfo.PowerLineFrequency = 60;
tInfo.ManufacturersModelName = 'Snapmaster';

eInfo = { 
    'onset'       'latency';
    'sample'      'latency';
    'value'       'type';
    'description' 'description' };

% call to the export function
% ---------------------------
targetFolder =  'BIDS_eye';
bids_export(data, ...
    'targetdir', targetFolder, ...
    'taskName', 'HBNdata',...
    'gInfo', generalInfo, ...
    'pInfo', pInfo, ...
    'pInfoDesc', pInfoDesc, ...
    'eInfo', eInfo, ...
    'README', README, ...
    'CHANGES', CHANGES, ...
    'codefiles', codefiles, ...
    'trialtype', {}, ...
    'renametype', {}, ...
    'tInfo', tInfo, ...
    'copydata', 1);
