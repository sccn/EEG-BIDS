clear
 
type = 'Task'; 
dataName = [ 'BIDS_' type 'test' ];
 
data.file = { 'test.set' };
EEG1 = pop_loadset(data.file{1});
EEG1 = eeg_checkset(EEG1, 'eventconsistency');

pInfo = { 'participant_id' ; '01' };
 
%% general information for dataset_description.json file
% -----------------------------------------------------
generalInfo.Name = dataName;
generalInfo.ReferencesAndLinks = { 'No bibliographic reference other than the DOI for this dataset' };
generalInfo.BIDSVersion = 'v1.2.1';
generalInfo.License = 'CC0';
tInfo.PowerLineFrequency = 60;
tInfo.TaskName = type;
eInfo = { 'sample'   'latency';
          'value'    'type';
          'stimulus' 'Stimulus';
          'text'     'Text';
          'load'     'Load';
          'stimtype' 'Condition'
          'description' 'Description' };
      
% call to the export function
% ---------------------------
targetFolder =  fullfile(pwd, dataName);
options = { 'targetdir', targetFolder, ...
    'gInfo', generalInfo, ...
    'pInfo', pInfo, ...
    'README', '', ...
    'CHANGES', '', ...
    'renametype', {}, ...
    'tInfo', tInfo, ...
    'eInfo', eInfo, ...
    'copydata', 1 };
    % 'taskName', type,...

bids_export(data, options{:});
 
% import data
% -------------
[STUDY, EEG2] = pop_importbids(targetFolder,'bidschanloc','off');

% reexport
% --------
EEG2 = pop_saveset(EEG2, 'test2.set');
data.file = { 'test2.set' };
eInfo = { 'sample'   'latency';
          'value'    'type';
          'stimulus' 'stimulus';
          'text'     'text';
          'load'     'load';
          'stimtype' 'stimtype'
          'description' 'description' };
targetFolder2 =  fullfile(pwd, [dataName '2' ]);
options = { 'targetdir', targetFolder2, ...
    'taskName', type,...
    'gInfo', generalInfo, ...
    'pInfo', pInfo, ...
    'README', '', ...
    'CHANGES', '', ...
    'renametype', {}, ...
    'tInfo', tInfo, ...
    'eInfo', eInfo, ...
    'copydata', 1 };
bids_export(data, options{:});

% import data
% -------------
[STUDY, EEG3] = pop_importbids(targetFolder2,'bidschanloc','off');

disp(' ')
disp('COMPARING EEG1 (orginal) and EEG2 (BIDS exported, reimported)')
eeg_compare(EEG1, EEG2);

disp(' ')
disp('COMPARING EEG2 (BIDS exported, reimported) and EEG3 (BIDS exported, reimported, a second time)')
eeg_compare(EEG2, EEG3);
disp(' ')
disp('Datasets available on command line (EEG1, EEG2, EEG3)')

