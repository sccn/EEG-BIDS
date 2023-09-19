% Example to export joint EEG and Eye-tracking data (child mind)
% The data is not included here because it is too large, but it 
% can be downloaded from http://fcon_1000.projects.nitrc.org/indi/cmi_healthy_brain_network/sharing_neuro.html
% 
% Arnaud Delorme - May 2023

clear
cd('/System/Volumes/Data/data/matlab/bids_eyetracking')
data = [];
p =fileparts(which('eeglab'));
data(end+1).file     = { 'hbn_files/NDARAA773LUW_SurroundSupp_Block1.set' };
data(end  ).eyefile  = { 'hbn_files/NDARAA773LUW_SurrSupp_Block1.tsv' };
% data(end+1).file     = { 'hbn_files/Video1.set' };
% data(end  ).eyefile  = { 'hbn_files/NDARAA075AMK_Video1_Samples.txt' };

%% participant information for participants.tsv file
% -------------------------------------------------
pInfo = { 'participantID' 'gender' 'age';
          'NDARAA773LUW' 'M' 22 };
%          'NDARAA075AMK' 'M' 22;

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

pInfoDesc.gender.Description = 'Sex of the participant';
pInfoDesc.gender.Levels.M    = 'male';
pInfoDesc.gender.Levels.F    = 'female';

pInfoDesc.age.Description = 'age of the participant';
pInfoDesc.age.Units       = 'years';

% %% event column description for xxx-events.json file (only one such file)
% % ----------------------------------------------------------------------
% eInfo = {'onset'         'latency';
%          'sample'        'latency';
%          'value'         'type' }; % ADD HED HERE
% 
% eInfoDesc.onset.Description = 'Event onset';
% eInfoDesc.onset.Units = 'second';
% 
% eInfoDesc.response_time.Description = 'Latency of button press after auditory stimulus';
% eInfoDesc.response_time.Levels.Units = 'millisecond';

%% Content for README file
% -----------------------
README = [ 'Test text' ];

%% Content for CHANGES file
% ------------------------
CHANGES = sprintf([ 'Version 1.0 - 3 April 2023\n' ...
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
    'taskName', 'HBN-data',...
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
% 
% % copy stimuli and source data folders
% % -----------------------------------
% copyfile('../stimuli', fullfile(targetFolder, 'stimuli'), 'f');
% copyfile('../sourcedata', fullfile(targetFolder, 'sourcedata'), 'f');

fprintf(2, 'WHAT TO DO NEXT?')
fprintf(2, ' -> upload the %s folder to http://openneuro.org to check it is valid\n', targetFolder);

