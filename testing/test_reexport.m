clear
 
type = 'Task'; 
dataName = [ 'BIDS_' type 'test' ];
 
data.file = { 'test.set' };
if 0
    EEG1 = pop_loadset(data.file{1});
    EEG1 = eeg_checkset(EEG1, 'eventconsistency');
    EEG1 = pop_chanedit(EEG1, 'lookup','Standard-10-5-Cap385.sfp');
    pop_saveset(EEG1, 'test.set' );
end

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
targetFolder =  fullfile(pwd,  [dataName '_export']);
targetFolder2 =  fullfile(pwd, [dataName '_re-export']);
options = { 'targetdir', targetFolder, ...
    'gInfo', generalInfo, ...
    'pInfo', pInfo, ...
    'README', '', ...
    'CHANGES', '', ...
    'renametype', {}, ...
    'tInfo', tInfo, ...
    'eInfo', eInfo, ...
    'elecexport', 'on', ...
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
% generatedBy.desc = 'eegprep';
% bids_reexport(EEG2, 'generatedBy', generatedBy, 'targetdir', targetFolder, 'checkagainstparent', targetFolder);
bids_reexport(EEG2, 'generatedBy', generatedBy, 'targetdir', targetFolder2, 'checkagainstparent', targetFolder);

