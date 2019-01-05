% This function provides a comprehensive example of using the bids_export
% function. Note that eventually, you may simply use bids_export({file1.set file2.set}) 
% and that all other parameters are highly recommended but optional.

% You may not run this script because you do not have the associated data.
% It correspond to the actual dataset included in the BIDS EEG publication
% available at https://psyarxiv.com/63a4y.
%
% The data itself is available at https://zenodo.org/record/1490922
%
% A. Delorme - Jan 2019

% raw data files (replace with your own)
% ----------------------------------
files = { 
    {'/Users/arno/temp/BIDS_delorme/sub-Expert01/ses-01/eeg/sub-Expert01_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert01/ses-02/eeg/sub-Expert01_ses-02_task-medprobe_eeg.bdf' }

{'/Users/arno/temp/BIDS_delorme/sub-Expert02/ses-01/eeg/sub-Expert02_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert02/ses-02/eeg/sub-Expert02_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert03/ses-01/eeg/sub-Expert03_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert03/ses-02/eeg/sub-Expert03_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert04/ses-01/eeg/sub-Expert04_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert04/ses-02/eeg/sub-Expert04_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert05/ses-01/eeg/sub-Expert05_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert05/ses-02/eeg/sub-Expert05_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert06/ses-01/eeg/sub-Expert06_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert06/ses-02/eeg/sub-Expert06_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert07/ses-01/eeg/sub-Expert07_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert07/ses-02/eeg/sub-Expert07_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert08/ses-01/eeg/sub-Expert08_ses-01_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert09/ses-01/eeg/sub-Expert09_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert09/ses-02/eeg/sub-Expert09_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert10/ses-01/eeg/sub-Expert10_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert10/ses-02/eeg/sub-Expert10_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert11/ses-01/eeg/sub-Expert11_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Expert11/ses-02/eeg/sub-Expert11_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Expert12/ses-01/eeg/sub-Expert12_ses-01_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice01/ses-01/eeg/sub-Novice01_ses-01_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice02/ses-02/eeg/sub-Novice02_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice03/ses-01/eeg/sub-Novice03_ses-01_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice04/ses-01/eeg/sub-Novice04_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Novice04/ses-02/eeg/sub-Novice04_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice05/ses-01/eeg/sub-Novice05_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Novice05/ses-02/eeg/sub-Novice05_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice06/ses-01/eeg/sub-Novice06_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Novice06/ses-02/eeg/sub-Novice06_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice07/ses-01/eeg/sub-Novice07_ses-01_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice08/ses-01/eeg/sub-Novice08_ses-01_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice09/ses-01/eeg/sub-Novice09_ses-01_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice10/ses-01/eeg/sub-Novice10_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Novice10/ses-02/eeg/sub-Novice10_ses-02_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Novice10/ses-03/eeg/sub-Novice10_ses-03_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice11/ses-01/eeg/sub-Novice11_ses-01_task-medprobe_eeg.bdf'
'/Users/arno/temp/BIDS_delorme/sub-Novice11/ses-02/eeg/sub-Novice11_ses-02_task-medprobe_eeg.bdf'}

{'/Users/arno/temp/BIDS_delorme/sub-Novice12/ses-01/eeg/sub-Novice12_ses-01_task-medprobe_eeg.bdf' } };

% general information for dataset_description.json file
% -----------------------------------------------------
generalInfo.Name = 'Meditation study';
generalInfo.ReferencesAndLinks = { "https://www.ncbi.nlm.nih.gov/pubmed/27815577" };

% participant information for participants.tsv file
% -------------------------------------------------
pInfo = { 'gender'   'age'   'group'; % originally from file mw_expe_may28_2015 and convert_files_to_bids.m
'M'	32 'expert';
'M'	35 'expert';
'F'	41 'expert';
'M'	29 'expert';
'F'	34 'expert';
'M'	32 'expert';
'M'	32 'expert';
'M'	32 'expert';
'M'	43 'expert';
'M'	33 'expert';
'M'	62 'expert';
'M'	65 'expert';
'F'	47 'novice';
'F'	52 'novice';
'F'	78 'novice';
'M'	77 'novice';
'F'	32 'novice';
'F'	'n/a' 'novice';
'F'	42 'novice';
'F'	41 'novice';
'F'	41 'novice';
'F'	31 'novice';
'M'	50 'novice';
'F'	38 'novice' };
       
% participant column description for participants.json file
% ---------------------------------------------------------
pInfoDesc.gender.Description = 'gender, classified as male or female';
pInfoDesc.gender.Levels.M = 'male';
pInfoDesc.gender.Levels.F = 'female';
pInfoDesc.participant_id.Description = 'unique participant identifier';
pInfoDesc.age.Description = 'age in years';
pInfoDesc.group.Description = 'group, expert or novice meditators';
pInfoDesc.group.Levels.expert = 'expert meditator';
pInfoDesc.group.Levels.novice = 'novice meditator';

% event column description for xxx-events.json file (only one such file)
% ----------------------------------------------------------------------
eInfoDesc.onset.Description = 'Event onset';
eInfoDesc.onset.Units = 'second';
eInfoDesc.duration.Description = 'Event duration';
eInfoDesc.duration.Units = 'second';
eInfoDesc.trial_type.Description = 'Type of event (different from EEGLAB convention)';
eInfoDesc.trial_type.Levels.stimulus = 'Onset of first question';
eInfoDesc.trial_type.Levels.response = 'Response to question 1, 2 or 3';
eInfoDesc.response_time.Description = 'Response time column not use for this data';
eInfoDesc.sample.Description = 'Event sample starting at 0 (Matlab convention starting at 1)';
eInfoDesc.value.Description = 'Value of event (numerical)';
eInfoDesc.value.Levels.x2   = 'Response 1 (this may be a response to question 1, 2 or 3)';
eInfoDesc.value.Levels.x4   = 'Response 2 (this may be a response to question 1, 2 or 3)';
eInfoDesc.value.Levels.x8   = 'Response 3 (this may be a response to question 1, 2 or 3)';
eInfoDesc.value.Levels.x16   = 'Indicate involuntary response';
eInfoDesc.value.Levels.x128 = 'First question onset (most important marker)';

% Content for README file
% -----------------------
README = sprintf( [ 'This meditation experiment contains 24 subjects. Subjects were\n' ...
                    'meditating and were interupted about every 2 minutes to indicate\n' ...
                    'their level of concentration and mind wandering. The scientific\n' ...
                    'article (see Reference) contains all methodological details\n\n' ...
                    '- Arnaud Delorme (October 17, 2018)' ]);
                
% Content for CHANGES file
% ------------------------
CHANGES = sprintf([ 'Revision history for meditation dataset\n\n' ...
                    'version 0.1 beta - 2018-10-17\n' ...
                    ' - Initial release\n' ...
                    '\n' ...
                    'version 1.0 - 4 Jan 2019\n' ...
                    ' - Fixing event field names and various minor issues\n' ]);                    
                
% List of stimuli to be copied to the stimuli folder
% --------------------------------------------------
stimuli = {'/data/matlab/tracy_mw/rate_mw.wav' 
    '/data/matlab/tracy_mw/rate_meditation.wav'
    '/data/matlab/tracy_mw/rate_tired.wav'
    '/data/matlab/tracy_mw/expe_over.wav'
    '/data/matlab/tracy_mw/mind_wandering.wav'
    '/data/matlab/tracy_mw/self.wav'
    '/data/matlab/tracy_mw/time.wav'
    '/data/matlab/tracy_mw/valence.wav'
    '/data/matlab/tracy_mw/depth.wav'
    '/data/matlab/tracy_mw/resume.wav'
    '/data/matlab/tracy_mw/resumed.wav'
    '/data/matlab/tracy_mw/resumemed.wav'
    '/data/matlab/tracy_mw/cancel.wav'
    '/data/matlab/tracy_mw/starting.wav' };

% List of script to run the experiment
% ------------------------------------
code = { '/data/matlab/tracy_mw/run_mw_experiment6.m' mfilename('fullpath') };

% Task information for xxxx-eeg.json file
% ---------------------------------------
tInfo.InstitutionAddress = 'Centre de Recherche Cerveau et Cognition, Place du Docteur Baylac, Pavillon Baudot, 31059 Toulouse, France';
tInfo.InstitutionName = 'Paul Sabatier University';
tInfo.InstitutionalDepartmentName = 'Centre de Recherche Cerveau et Cognition';
tInfo.PowerLineFrequency = 50;
tInfo.ManufacturersModelName = 'ActiveTwo';

% Trial types correspondance with event types/values
% BIDS allows for both trial types and event values
% --------------------------------------------------
trialTypes = { '2' 'response';
               '4' 'response';
               '8' 'response';
               '16' 'n/a';
               '128' 'stimulus' };
           
% call to the export function
% ---------------------------
bids_export(files, 'targetdir', '/Users/arno/temp/bidsexport', 'taskName', 'meditation', 'trialtype', trialTypes, 'gInfo', generalInfo, 'pInfo', pInfo, 'pInfoDesc', pInfoDesc, 'eInfoDesc', eInfoDesc, 'README', README, 'CHANGES', CHANGES, 'stimuli', stimuli, 'codefiles', code, 'tInfo', tInfo);
