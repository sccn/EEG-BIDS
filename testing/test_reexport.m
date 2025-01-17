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
generalInfo.DatasetDOI = 'xxxxx';
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
targetFolder2 =  fullfile(pwd, [dataName '-2']);
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
generatedBy.Name = 'NEMAR-pipeline';
generatedBy.Description = 'A validated EEG pipeline';
generatedBy.Version = '0.1';
generatedBy.CodeURL = 'https://github.com/sccn/NEMAR-pipeline/blob/main/eeg_nemar_preprocess.m';
bids_reexport(EEG2, 'generatedBy', generatedBy, 'targetdir', targetFolder2, 'checkderivative', targetFolder);

