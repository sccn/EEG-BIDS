% Matlab script to export to BIDS
% This is a simple example to export the tutorial EEGLAB dataset
% You can run this example and checks that the data passes the BIDS
% validator, then modify it for your own purpose
% 
% Arnaud Delorme - Oct 2021

data = [];
p =fileparts(which('eeglab'));
data(end+1).file = { fullfile(p, 'sample_data', 'eeglab_data.set') };
data(end  ).session = [1];
data(end  ).run     = [1];
data(end  ).task    = { 'p300' };
data(end  ).notes   = { 'No notes' };

%% participant information for participants.tsv file
% -------------------------------------------------
pInfo = { 'gender' 'age';
 'M' 22 };
      
%% Code Files used to preprocess and import to BIDS
% -----------------------------------------------------|
codefiles = { fullfile(pwd, mfilename) };

%% general information for dataset_description.json file
% -----------------------------------------------------
generalInfo.Name = 'P300 visual task';
generalInfo.ReferencesAndLinks = { 'No bibliographic reference other than the DOI for this dataset' };
generalInfo.BIDSVersion = 'v1.2.1';
generalInfo.License = 'CC0';
generalInfo.Authors = { 'Arnaud Delorme' 'Scott Makeig' 'Marissa Westerfield' };

%% participant column description for participants.json file
% ---------------------------------------------------------
pInfoDesc.participant_id.LongName    = 'Participant identifier';
pInfoDesc.participant_id.Description = 'Unique participant identifier';

pInfoDesc.gender.Description = 'Sex of the participant';
pInfoDesc.gender.Levels.M    = 'male';
pInfoDesc.gender.Levels.F    = 'female';

pInfoDesc.age.Description = 'age of the participant';
pInfoDesc.age.Units       = 'years';

%% event column description for xxx-events.json file (only one such file)
% ----------------------------------------------------------------------
eInfo = {'onset'         'latency';
         'sample'        'latency';
         'value'         'type' }; % ADD HED HERE

eInfoDesc.onset.Description = 'Event onset';
eInfoDesc.onset.Units = 'second';

eInfoDesc.response_time.Description = 'Latency of button press after auditory stimulus';
eInfoDesc.response_time.Levels.Units = 'millisecond';

% You do not need to define both trial type and value in this simple
% example, but it is good to know that both exist. There is no definite
% rule regarding the difference between these two fields. As their name
% indicate, "trial_type" contains the type of trial and "value" contains 
% more information about a trial of given type.
eInfoDesc.trial_type.Description = 'Type of event';
eInfoDesc.trial_type.Levels.stimulus = 'Visual stimulus';
eInfoDesc.trial_type.Levels.response = 'Response of participant';

eInfoDesc.value.Description = 'Value of event';
eInfoDesc.value.Levels.square   = 'Square visual stimulus';
eInfoDesc.value.Levels.rt       = 'Behavioral response';

% This allow to define trial types based on EEGLAB type - it is optional
trialTypes = { 'rt'     'response';
               'square' 'stimulus' };

%% Content for README file
% -----------------------
README = [ 'EEGLAB Tutorial Dataset                   ' 10 ...
''                                                      10 ...
'During this selective visual attention experiment,   ' 10 ...
'stimuli appeared briefly in any of five squares      ' 10 ...
'arrayed horizontally above a central fixation cross. ' 10 ...
'In each experimental block, one (target) box was     ' 10 ...
'differently colored from the rest Whenever a square  ' 10 ...
'appeared in the target box the subject was asked to  ' 10 ...
'respond quickly with a right thumb button press. If  ' 10 ...
'the stimulus was a circular disk, he was asked to    ' 10 ...
'ignore it.' 10 ...
'' 10 ...
'These data were constructed by concatenating         ' 10 ...
'three-second epochs from one subject, each containing' 10 ...
'a target square in the attended location (''square''   ' 10 ...
'events, left-hemifield locations 1 or 2 only)        ' 10 ...
'followed by a button response (''rt'' events). The data' 10 ...
'were stored in continuous data format to illustrate  ' 10 ...
'the process of epoch extraction from continuous data.' ];

%% Content for CHANGES file
% ------------------------
CHANGES = sprintf([ 'Version 1.0 - 4 Aug 2020\n' ...
                    ' - Initial release\n' ]);

%% Task information for xxxx-eeg.json file
% ---------------------------------------
tInfo.InstitutionAddress = '9500 Gilman Drive, La Jolla CA 92093, USA';
tInfo.InstitutionName = 'University of California, San Diego';
tInfo.InstitutionalDepartmentName = 'Institute of Neural Computation';
tInfo.PowerLineFrequency = 60;
tInfo.ManufacturersModelName = 'Snapmaster';
%tInfo.Reference = 'Delorme A, Westerfield M, Makeig S. Medial prefrontal theta bursts precede rapid motor responses during visual selective attention. J Neurosci. 2007 Oct 31;27(44):11949-59. doi: 10.1523/JNEUROSCI.3477-07.2007. PMID: 17978035; PMCID: PMC6673364.'
% tInfo.Instructions


% call to the export function
% ---------------------------
targetFolder =  './BIDS_p300';
bids_export(data, ...
    'targetdir', targetFolder, ...
    'taskName', 'P300',...
    'gInfo', generalInfo, ...
    'pInfo', pInfo, ...
    'pInfoDesc', pInfoDesc, ...
    'eInfo', eInfo, ...
    'eInfoDesc', eInfoDesc, ...
    'README', README, ...
    'CHANGES', CHANGES, ...
    'codefiles', codefiles, ...
    'trialtype', trialTypes, ...
    'renametype', {}, ...
    'checkresponse', 'condition 1', ...
    'tInfo', tInfo, ...
    'copydata', 1);
% 
% % copy stimuli and source data folders
% % -----------------------------------
% copyfile('../stimuli', fullfile(targetFolder, 'stimuli'), 'f');
% copyfile('../sourcedata', fullfile(targetFolder, 'sourcedata'), 'f');

fprintf(2, 'WHAT TO DO NEXT?')
fprintf(2, ' -> upload the %s folder to http://openneuro.org to check it is valid\n', targetFolder);

