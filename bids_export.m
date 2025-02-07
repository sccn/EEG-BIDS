% BIDS_EXPORT - this function allows converting a collection of datasets to
%               BIDS formated folders and files.
%
% Usage:
%    bids_export(files, varargin)
%
% Input:
%   files      - Structure with the fields 'file','session' and 'run'.
%                The field 'file' should be a cell array of strings
%                with the path to the data files. The fields 'session'
%                and 'run' will contain the session index and the run index
%                within the session for the corresponding data file in the
%                same index. 'notes' can contain notes about the recording.
%                The optional 'eventtype', 'eventindex' 'timeoffset' allow
%                selecting portions of files. For example 'timeoffset' of
%                [0 1800] selects the first 30 minutes of a file. Default 
%                'timeoffset' is 0. Add 'eventype' equals to { 'beg' 'end' } 
%                and 'eventindex' of [1 1] and the portion of data between the 
%                first 'beg' event and 1800 seconds after the first 'end' event
%                is selected. If 'eventtype' is not specified, then events of
%                all types are considered.
%
%                See example below for a case with 2 subjects with
%                2 sessions and 2 run each:
%                 subject(1).file     = 'subj1.set';
%                 subject(1).chanlocs = 'subj1.elp';  % optional
%                 subject(1).notes    = 'Good recording';  % optional
%                 subject(2).file     = 'subj2.set';
%                 subject(2).chanlocs = 'subj2.elp';  % optional
%                 subject(2).notes    = 'Bad recoding';  % optional
%
%                See example below for a case with 2 subjects with
%                2 sessions and 2 runs each:
%                 subject(1).file       = {'subj-1_ss-1-run1'   'subj-1_ss-1-run2' 'subj-1_ss-2-run1' 'subj-1_ss-2-run2'};
%                 subject(1).eventtype  = { {'beg' 'end'}       {'beg' 'end'}      {'beg' 'end'}      {'beg' 'end'}    };
%                 subject(1).eventindex = { [1 1]               [1 1]              [1 1]              [1 1]             };
%                 subject(1).timeoffset = { [0 1000]            [0 1000]           [0 1000]           [0 1000] };
%                 subject(1).session    = [ 1 1 2 2 ];
%                 subject(1).run        = [ 1 2 1 2 ];
%                 subject(1).task       = { 'go-nogo' 'control' 'go-nogo' 'control' };
%                 subject(1).instructions = { 'Press button when you see an animal' 'Look passively at the images' 'Press button when you see an animal' 'Look passively at the images'  };
%                 subject(1).chanlocs = {'subj-1_ss-1-run1.elp' 'subj-1_ss-1-run2.elp' 'subj-1_ss-2-run1.elp' 'subj-1_ss-2-run2.elp'};
%                 subject(2).file       = {'subj-2_ss-1-run1' 'subj-2_ss-1-run2' 'subj-2_ss-2-run1' 'subj-2_ss-2-run2'};
%                 subject(2).eventtype  = { {'beg' 'end'}       {'beg' 'end'}      {'beg' 'end'}      {'beg' 'end'}    };
%                 subject(2).eventrange = { [1 1]               [1 1]              [1 1]              [1 1]             };
%                 subject(2).timerange  = { [0 1000]            [0 1000]           [0 1000]           [0 1000] };
%                 subject(2).session    = [ 1 1 2 2 ];
%                 subject(2).run        = [ 1 2 1 2 ];
%                 subject(2).task       = { 'go-nogo' 'control' 'go-nogo' 'control' };
%                 subject(2).instructions = { 'Press button when you see an animal' 'Look passively at the images' 'Press button when you see an animal' 'Look passively at the images'  };
%                 subject(2).chanlocs = {'subj-2_ss-1-run1.elp' 'subj-2_ss-1-run2.elp' 'subj-2_ss-2-run1.elp' 'subj-2_ss-2-run2.elp'};
%
%                Alternate representation that is also functional:
%                 subject(1).file(1).file = 'subj-1_ss-1-run1';
%                 subject(1).file(1).session = 1;
%                 subject(1).file(1).run     = 1;
%                 subject(1).file(1).task    = 'go-nogo';
%                 subject(1).file(1).instructions = 'Press button when you see an animal';
%                 subject(1).file(1).chanlocs = 'subj-1_ss-1-run1.elp';
%                 subject(1).file(2).file = 'subj-1_ss-1-run2';
%                 subject(1).file(2).session = 1;
%                 subject(1).file(2).run     = 2;
%                 subject(1).file(2).task    = 'control';
%                 subject(1).file(2).instructions = 'Look passively at the images';
%                 subject(1).file(2).chanlocs = 'subj-1_ss-1-run2.elp';
%                 ...
%
% Optional inputs:
%  'targetdir' - [string] target directory. Default is 'bidsexport' in the
%                current folder.
%
%  'taskName'  - [string] name of the task for all datasets. No spaces and
%                special characters are allowed. Default is 'Experiment'
%                if no tasks are detected, '<taskname>' when single task detected,
%				 and 'mixed' when multiple tasks detected. Individual file
%			     task can be specified using files.task
%
%  'README'    - [string] content of the README file. If the string points
%                to a file that exists on the path, the file is copied.
%                Otherwise a new README file is created and the content of
%                this variable is copied to the new file.
%
%  'CHANGES'   - [string] content of the README file. If the string points
%                to a file that exists on the path, the file is copied.
%
%  'codefiles' - [cell] cell array of file names containing code related
%                to importing or processing the data.
%
%  'stimuli'   - [cell] cell array of EEGLAB event type and corresponding file
%                names for the stimulus on your computer.
%                For example: { 'sound1' '/Users/xxxx/sounds/sound1.mp3';
%                               'img1'   '/Users/xxxx/sounds/img1.jpg' }
%                (the semicolumn above is optional). Alternatively, after
%                exporting to BIDS, create a stimuli folder and place your
%                stimuli in that folder with a README file describing them.
%
%  'gInfo'     - [struct] general information fields. See BIDS specifications.
%                For example.
%                info.ReferencesAndLinks = { 'Pubmed 122032020' };
%                info.Name = 'This is a custom task';
%                info.License = 'Creative commons';
%                info.GeneratedBy.Name = {'bids-matlab-tools'};
%                info.SourceDatasets.DOI = 'xxx';
%
%  'tInfo'     - [struct] task information fields. See BIDS specifications.
%                For example.
%                tInfo.InstitutionAddress = '9500 Gilman Drive, CA92093-0559 La Jolla, USA';
%                tInfo.InstitutionName = 'Univesity of California, San Diego';
%                tInfo.InstitutionalDepartmentName = 'Institute of Neural Computation';
%                tInfo.PowerLineFrequency = 50;
%                tInfo.SoftwareFilters = struct('NotchFilter', struct('cutof', '50 (Hz)'));
%                tInfo.HardwareFilters = struct('HighpassRCFilter',struct('HalfAmplitudeCutoff', '0.0159 Hz', 'RollOff','6dB/Octave'))
%                Notice that SoftwareFilters and HardwareFilters take struct.
%
%  'tInfoeye'  - [struct] task information fields for eye tracking. See BIDS specifications.
%                For example.
%
%  'pInfo'     - [cell] cell array of participant values, with one row
%                per participants. The first row contains columns names.
%                For example for 2 participants:
%                { 'participant_id' 'sex'     'age';
%                  'control01'      'male'     20;
%                  'control02'      'female'   25 };
%                The columns above are optional and an arbitrary number of custom columns may
%                also be specified. When 'participant_id' is specified, it will be used for
%                naming subject folders (folders names and file prefix will be sub-<label>,
%                <label> being the participant ID).
%
%  'pInfoDesc' - [struct] structure describing participant file columns.
%                The fields are described in the BIDS format.
%                For example
%                pInfo.participant_id.LongName = 'Participant ID';
%                pInfo.participant_id.Description = 'Event onset';
%                pInfo.sex.LongName = 'Gender';
%                pInfo.sex.Description = 'Gender';
%                pInfo.age.LongName = 'Age';
%                pInfo.age.Description = 'Age in years';
%
%  'eInfo'     - [cell] additional event information columns and their corresponding
%                event fields in the EEGLAB event structure in format
%                { '<BIDS field1>' '<EEG field1>';
%                  '<BIDS field2>' '<EEG field2>'}
%                Note that EEGLAB event latency, duration, and type are inserted
%                automatically as columns "sample" (latency), "onset" (latency in sec), "duration"
%                (duration in sec), and "value" (EEGLAB event type). For example
%                { 'sample' 'latency';
%                  'value' 'type' }
%                See also trial_type parameter.
%
%  'eInfoDesc' - [struct] structure describing additional or/and original
%                event fields if you wish to redefine these.
%                These are EEGLAB event fields listed above.
%                See the BIDS format for more information
%                eInfo.onset.LongName = 'Event onset'; % change default value
%                eInfo.onset.Description = 'Event onset';
%                eInfo.onset.Units = 'seconds';
%                eInfo.HED.LongName = 'Hierarchival Event Descriptors';
%                eInfo.reaction_time.LongName = 'Reaction time';
%                eInfo.reaction_time.Units = 'seconds';
%
%  'cInfo'     - [cell] cell array containing the field names for the
%                channel file in addition to the channel "name", "type" and
%                "unit" which are extracted from the channel location
%                structure. For example, to add the reference as an
%                additional column:
%                {'reference';
%                 'ref' }
%
%  'cInfoDesc' - [struct] structure describing additional or/and original
%                channel fields if you wish to redefine these.
%                cInfo.name.LongName = 'Channel name'; % change default description
%                cInfo.name.Description = 'Channel name';
%                cInfo.reference.LongName = 'Channel reference';
%                cInfo.reference.Description = 'Channel reference montage 10/20';
%
%  'renametype' - [cell] 2 column cell table for renaming type.
%                                     For example { '2'    'standard';
%                                                   '4'    'oddball';
%                                                   '128'  'response' }
%
%  'trialtype' - [cell] 2 column cell table indicating the type of event
%                for each event type. For example { '2'    'stimulus';
%                                                   '4'    'stimulus';
%                                                   '128'  'response' }
%
%  'elecexport' - ['on'|'off'|'auto'] export electrode file. Default is
%                'auto'.
%
%  'eventexport' - ['on'|'off'|'auto'] export event file. Default is 'auto'.
%
%  'eventfieldignore' - ['on'|'off'] ignore event field defined in eInfo if
%                 it not present in the dataset. Setting to 'off' fills a
%                 column with 'n/a' for that field. Default is 'on'.
%
%  'chanlookup' - [file] look up channel locations based on file. Default
%                 not to look up channel location.
%
%  'anattype'  - [string] type of anatomical MRI image ('T1w', 'T2w', etc...)
%                see BIDS specification for more information.
%
%  'defaced'   - ['on'|'off'] indicate if the MRI image is defaced or not.
%                Default is 'on'.
%
%  'createids' - ['on'|'off'] do not use Participant IDs and create new
%                anonymized IDs instead. Default is 'off'.
%
%  'noevents' - ['on'|'off'] do not save event files. Default is 'off'.
%
%  'forcesession' - ['on'|'off'] force to export sessions even if there is 
%               only one. Default is 'off'.
%
%  'forcerun'     - ['on'|'off'] force to export runs even if there is 
%               only one. Default is 'off'.
%
% 'rmtempfiles' - ['on'|'off'] remove temporary EEGLAB set files created by
%               pop_studywizard. Default 'on'.
%
%  'chanlocs'  - [struct or file name] channel location structure or file
%                name to use when saving channel information. Note that
%                this assumes that all the files have the same number of
%                channels.
%
% 'importfunc' - [function handle or string] function to import raw data to
%              EEG format. Default: auto.
%
% 'exportformat' - ['same'|'eeglab'|'edf'|'bdf'] export files in the 'same' format
%              as given as input or export in 'eeglab' .set, 'edf', or 'bdf' format. 
%              Default is 'eeglab'. If you use 'eventtype', 'eventindex' or 'timeoffset'
%              and the export format is set to 'same', files will be automatically
%              exported in the 'eeglab' format.
%
% 'modality' - ['eeg'|'ieeg'|'meg'|'auto'] type of data. 'auto' means the
%              format is determined from the file extension. Default is
%              'auto'.
%
% 'ctffunc' - ['fileio'|'ctfimport'] function to use to import CTF data
%             Default 'fileio'.
%
% 'deleteExportDir' - ['on'|'off'] remove the target BIDS directory if previously 
%                     present. This should be almost always 'on'. The
%                     exception is having multi-task sessions in which each
%                     task has specific eInfo and/or tInfo inputs. Default is 'on'.
%
% 'writePInfoOnly' - ['on'|'off'] bids_export ends after exporting
%                    participants.tsv file. This should be almost always
%                    'off'. Use case is when 'deleteExportDir' is 'off',
%                    the participants.tsv will be potentially incomplete,
%                    as it was overwritten. The solution is to regenerate
%                    the file, but without touching the other contents of
%                    the directory. Default is 'off'.
% 'GeneratedBy' - [struct] structure indicating how the data was generated. NOTE: Adding the fileds below is done in 
%                bids_reexport.m, only GeneratedBy.desc is implemented here.
%                For example:
%                GeneratedBy.Name = 'NEMAR-pipeline';
%                GeneratedBy.Description = 'A validated EEG pipeline';
%                GeneratedBy.Version = '0.1';
%                GeneratedBy.CodeURL = 'https://github.com/sccn/NEMAR-pipeline/blob/main/eeg_nemar_preprocess.m';
%                GeneratedBy.desc = 'filtered'; % optional description for file naming
%
% Validation:
%  If the BIDS data created with this function fails to pass the BIDS
%  validator (npm install -g https://github.com/bids-standard/bids-validator.git
%  Usage bids-validator/bin/bids-validator --bep006 bidsfolder), please
%  email eeglab@sccn.ucsd.edu
%
% Example: The following examples will pass the bids validator.
% data(1).file = 'subject1.set'; data(1).run  = 1; data(1).session = 1;
% data(2).file = 'subject2.set'; data(2).run  = 1; data(2).session = 1;
% bids_export(data);
%
% Note that important information might be missing. For example, line noise
% is set to 0. Use input 'tInfo' to set the line noise as below.
%
% bids_export( data, 'tInfo', struct('PowerLineFrequency', 50 );
%
% In general, you will want to describe your events and include as much
% information as possible. A detailed and comprehensive example is provided
% in bids_export_example.m
%
%
% Authors: Arnaud Delorme, 2019-
%          Ramon Martinez-Cancino, 2019-2020
%          Dung Truong 2021

%  The following are automatically
%                populated using channel structure info ('eeg', 'ecg', 'emg', 'eog', 'trigger')
%                tInfo.ECGChannelCount = xxx;
%                tInfo.EEGChannelCount = xxx;
%                tInfo.EMGChannelCount = xxx;
%                tInfo.EOGChannelCount = xxx;
%                tInfo.MiscChannelCount = xxx;
%                tInfo.TriggerChannelCount = xxx;
%                tInfo.EEGReference = xxx;
%                tInfo.EpochLength = xxx;
%                tInfo.RecordingDuration = xxx;
%                tInfo.SamplingFrequency = xxx;
%                tInfo.TaskName = 'meditation';
%                However, they may be overwritten man.

function bids_export(files, varargin)

if nargin < 1
    help bids_format_eeglab;
    return
end
if ~exist('jsonwrite')
    addpath(fullfile(fileparts(which(mfilename)), 'JSONio'));
end

opt = finputcheck(varargin, {
    'Name'         'string'  {}    '';
    'License'      'string'  {}    '';
    'Authors'      'cell'    {}    {''};
    'ReferencesAndLinks' 'cell' {}    {''};
    'targetdir'    'string'  {}    fullfile(pwd, 'bidsexport');
    'taskName'     'string'  {}    '';
    'codefiles'    'cell'    {}    {};
    'stimuli'      'cell'    {}    {};
    'pInfo'        'cell'    {}    {};
    'eInfo'        'cell'    {}    {};
    'cInfo'        'cell'    {}    {};
    'gInfo'        'struct'  {}    struct([]);
    'tInfo'        'struct'  {}    struct([]);
    'tInfoeye'     'struct'  {}    struct([]);
    'pInfoDesc'    'struct'  {}    struct([]);
    'eInfoDesc'    'struct'  {}    struct([]);
    'cInfoDesc'    'struct'  {}    struct([]);
    'behInfo'      'struct'  {}    struct([]);
    'generatedBy'  'struct'  {}    struct([]);
    'GeneratedBy'  'struct'  {}    struct([]);
    'sourceDatasets' 'struct'  {}    struct([]);
    'SourceDatasets' 'struct'  {}    struct([]);
    'trialtype'    'cell'    {}    {};
    'renametype'   'cell'   {}    {};
    'checkresponse' 'string'   {}    '';
    'anattype'     ''        {}    'T1w';
    'chanlocs'     ''        {}    '';
    'chanlookup'   'string' {}    '';
    'elecexport'   'string'   {'on' 'off' 'auto'}    'auto';
    'eventexport'  'string'  {'on' 'off' 'auto'}    'auto';
    'eventfieldignore' 'string'  {'on' 'off'}    'on';
    'interactive'  'string'  {'on' 'off'}    'off';
    'defaced'      'string'  {'on' 'off'}    'on';
    'createids'    'string'  {'on' 'off'}    'off';
    'noevents'     'string'  {'on' 'off'}    'off';
    'forcesession' 'string'  {'on' 'off'}    'off';
    'forcerun'     'string'  {'on' 'off'}    'off';
    'rmtempfiles'  'string'  {'on' 'off'}    'on';
    'exportformat' 'string'  {'same' 'eeglab' 'edf' 'bdf'}    'eeglab';
    'individualEventsJson' 'string'  {'on' 'off'}    'off';
    'modality'     'string'  {'ieeg' 'meg' 'eeg' 'auto'}       'auto';
    'README'       'string'  {}    '';
    'CHANGES'      'string'  {}    '' ;
    'copydata'     'integer' {}    [0 1]; % legacy, does nothing now
    'ctffunc'      'string'    { 'fileio' 'ctfimport' }    'fileio'; ...
    'importfunc'   ''  {}    '';
    'deleteExportDir' 'string' {'on' 'off'} 'on' ;
    'writePInfoOnly' 'string' {'on' 'off'} 'off'}, 'bids_export');
if isstr(opt), error(opt); end
if ~isempty(opt.taskName)
    fprintf(2, 'Task name input is deprecated and not used, use tInfo.TaskName instead\n');
    opt.tInfo(1).TaskName = opt.taskName;
end
if size(opt.stimuli,1) == 1 || size(opt.stimuli,2) == 1
    opt.stimuli = reshape(opt.stimuli, [2 length(opt.stimuli)/2])';
end
if ~isempty(opt.generatedBy)
    opt.GeneratedBy = opt.generatedBy;
end
if ~isempty(opt.sourceDatasets)
    opt.SourceDatasets = opt.sourceDatasets;
end

% deleting folder
% ---------------
fprintf('Exporting data to %s...\n', opt.targetdir);
if exist(opt.targetdir,'dir') 
    if strcmpi(opt.interactive, 'on')
        uilist = { ...
            { 'Style', 'text', 'string', 'Output directory exists and all current files will be deleted if continue', 'fontweight', 'bold'  }, ...
            { 'Style', 'text', 'string', 'Would you want to proceed?'}, ...
            };
        geometry = { [1] [1]};
        geomvert =   [1  1 ];
        [results,userdata,isOk,restag] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', uilist, 'title', 'Warning');
        if isempty(isOk)
            disp('BIDS export cancelled...')
            return
        end
    end
    if strcmpi(opt.deleteExportDir, 'on')
        disp('Folder exists. Deleting folder...')
        rmdir(opt.targetdir, 's');
    else
        warning('Folder exists. You chose not to delete the folder. Results may not be satisfactory.')
    end
end

disp('Creating sub-directories...')
mkdir( fullfile(opt.targetdir, 'code'));
mkdir( fullfile(opt.targetdir, 'stimuli'));

% write dataset info (dataset_description.json)
% ---------------------------------------------
gInfoFields = { 'ReferencesAndLinks' 'required' 'cell' { 'n/a' };
    'Name'               'required' 'char' '';
    'License'            'required' 'char' 'CC0';
    'BIDSVersion'        'required' 'char' '1.8.0' ;
    'HEDVersion'         'required' 'char' '8.1.0' ;
    'DatasetType'        'optional' 'char' { 'derivative' 'raw' };
    'Authors'            'optional' 'cell' { 'n/a' };
    'Acknowledgements'   'optional' 'char' '';
    'HowToAcknowledge'   'optional' 'char' '';
    'SourceDatasets'     'optional' 'struct' struct([]);
    'Funding'            'optional' 'cell' { 'n/a' };
    'GeneratedBy'        'required' 'struct' struct('Name', 'bids-matlab-tools', 'Version', bids_matlab_tools_ver);
    'DatasetDOI'         'optional' 'char' { 'n/a' }};

if ~isfield(opt.gInfo, 'Name'), opt.gInfo(1).Name = opt.Name; end
if ~isfield(opt.gInfo, 'License'), opt.gInfo.License = opt.License; end
if ~isfield(opt.gInfo, 'Authors'), opt.gInfo.Authors = opt.Authors; end
if ~isfield(opt.gInfo, 'ReferencesAndLinks'), opt.gInfo.ReferencesAndLinks = opt.ReferencesAndLinks; end
if ~isfield(opt.gInfo, 'GeneratedBy') && ~isempty(opt.GeneratedBy), opt.gInfo.GeneratedBy = opt.GeneratedBy; end
if ~isfield(opt.gInfo, 'SourceDatasets') && ~isempty(opt.SourceDatasets), opt.gInfo.SourceDatasets = opt.SourceDatasets; end

% write dataset_description.json removing double lists
opt.gInfo = bids_checkfields(opt.gInfo, gInfoFields, 'gInfo');
datasetDescriptionFile = fullfile(opt.targetdir, 'dataset_description.json');
gInfo = opt.gInfo;
if isfield(gInfo, 'GeneratedBy')
    gInfo.GeneratedBy = { gInfo.GeneratedBy };
end
if isfield(gInfo, 'SourceDatasets')
    gInfo.SourceDatasets = { gInfo.SourceDatasets };
end
try
    jsonStr = jsonencode(gInfo,'PrettyPrint', true);
catch
    jsonStr = jsonwrite(opt.gInfo, struct('indent','  '));
    indDoubleList = strfind(jsonStr, '[['); jsonStr(indDoubleList) = [];
    indDoubleList = strfind(jsonStr, '[ ['); jsonStr(indDoubleList) = [];
    indDoubleList = strfind(jsonStr, ']]'); jsonStr(indDoubleList) = [];
end
fid = fopen(datasetDescriptionFile, 'w');
fprintf(fid, jsonStr);
fclose(fid);

% make cell out of file names if necessary
% ----------------------------------------
for iSubj = 1:length(files)
    if ~isfield(files, 'file')
        if isfield(files, 'eyefile')
            files(iSubj).file = cell(1,length(files(iSubj).eyefile));
            files(iSubj).file(:) = {''};
        else
            error('A field named "file" or "eyefile" must be present in the data structure')
        end
    end

    if isfield(files, 'file') && ~iscell(files(iSubj).file)
        if isstruct(files(iSubj).file)
            if isfield(files(iSubj).file, 'session')
                files(iSubj).session  = [ files(iSubj).file.session  ];
            end
            if isfield(files(iSubj).file, 'run')
                files(iSubj).run      = [ files(iSubj).file.run  ];
            end
            if isfield(files(iSubj).file, 'task')
                files(iSubj).task      = { files(iSubj).file.task  };
            end
            if isfield(files(iSubj).file, 'instructions')
                files(iSubj).task      = { files(iSubj).file.instructions };
            end
            files(iSubj).file     = { files(iSubj).file.file };
        else
            files(iSubj).file = { files(iSubj).file };
        end
    end

    % channel location
    if isfield(files(iSubj), 'chanlocs')
        if ~iscell(files(iSubj).chanlocs)
            files(iSubj).chanlocs = { files(iSubj).chanlocs };
        end
        if length(files(iSubj).chanlocs) ~= length(files(iSubj).file)
            if length(files(iSubj).chanlocs) == 1
                files(iSubj).chanlocs(1:length(files(iSubj).file)) = files(iSubj).chanlocs(1);
            else
                error('Length of channel list must be the same size as the number of file for each participant');
            end
        end
    end
    
    % behavioral data
    if isfield(files(iSubj), 'beh')
        if ~iscell(files(iSubj).beh)
            files(iSubj).beh = { files(iSubj).beh };
        end
    end
    
    % run and sessions and tasks
    if ~isfield(files(iSubj), 'run') || isempty(files(iSubj).run)
        files(iSubj).run = ones(1, length(files(iSubj).file));
    end
    if ~isfield(files(iSubj), 'session') || isempty(files(iSubj).session)
        files(iSubj).session = ones(1, length(files(iSubj).file));
    end
    if ~isfield(files(iSubj), 'task') || isempty(files(iSubj).task)
        if isfield(opt.tInfo, 'TaskName')
            [files(iSubj).task{1:length(files(iSubj).file)}] = deal(opt.tInfo.TaskName);
        else
            error('''TaskName'' is a required field for tInfo input; alternatively you can assign a task to each input dataset');
        end
    end
    
    % notes
    if ~isfield(files(iSubj), 'notes') || isempty(files(iSubj).notes)
        files(iSubj).notes = cell(1,length(files(iSubj).file));
    else
        if ischar(files(iSubj).notes)
            files(iSubj).notes = { files(iSubj).notes };
        end
        if length(files(iSubj).notes) == 1
            tmpNote = files(iSubj).notes{1};
            files(iSubj).notes = cell(1,length(files(iSubj).file));
            files(iSubj).notes(:) = { tmpNote };
        end
        if length(files(iSubj).notes) < length(files(iSubj).file)
            files(iSubj).notes{length(files(iSubj).file)} = [];
        end
    end

    % event and time range extraction
    if ~isfield(files(iSubj), 'timeoffset') || isempty(files(iSubj).timeoffset)
        files(iSubj).timeoffset = cell(1,length(files(iSubj).file));
    end
    if ~isfield(files(iSubj), 'eventtype') || isempty(files(iSubj).eventtype)
        files(iSubj).eventtype = cell(1,length(files(iSubj).file));
    end
    if ~isfield(files(iSubj), 'eventindex') || isempty(files(iSubj).eventindex)
        files(iSubj).eventindex = cell(1,length(files(iSubj).file));
    end

    % check that no two files have the same session/run and task
    if length(files(iSubj).run) ~= length(files(iSubj).session)
        error(sprintf('Length of session and run differ for subject %s', iSubj));
    else
        if length(files(iSubj).task) ~= length(files(iSubj).session)
            error(sprintf('Length of session and task differ for subject %s', iSubj));
        end
        if length(files(iSubj).notes) ~= length(files(iSubj).session)
            error(sprintf('Length of session and notes differ for subject %s', iSubj));
        end

        % convert all runs and session to cell array of string
        if ~iscell(files(iSubj).run)     files(iSubj).run = mattocell(files(iSubj).run); end
        if ~iscell(files(iSubj).session) files(iSubj).session = mattocell(files(iSubj).session); end
        strs = {};
        for iVal = 1:length(files(iSubj).task)
            files(iSubj).run{    iVal} = num2str(files(iSubj).run{    iVal});
            files(iSubj).session{iVal} = num2str(files(iSubj).session{iVal});
            strs{iVal} = strcat(files(iSubj).task{iVal}, files(iSubj).run{iVal}, files(iSubj).session{iVal});
        end
        if length(strs) ~= length(unique(strs))
            error(sprintf('Subject %d does not have unique task, session and runs for each file', iSubj));
        end
    end
end

% write participant information (participants.tsv)
% -----------------------------------------------
if isempty(opt.pInfo)
    opt.pInfo{1} = 'participant_id';
    if isfield(files, 'subject')
        opt.pInfo = [opt.pInfo; { files.subject }' ];
    else
        for iFile = 1:length(files)
            opt.pInfo{iFile+1,1} = sprintf('%3.3d', iFile);
        end
    end
end
if isfield(files, 'subject')
    uniqueSubject = unique( { files.subject } );
    if size(opt.pInfo,1)-1 ~= length( uniqueSubject )
        error(sprintf('Wrong number of participant (%d) in pInfo structure, should be %d based on the number of files', size(opt.pInfo,1)-1, length( uniqueSubject )));
    end
elseif ~isstruct(files(1).file)
    if size(opt.pInfo,1)-1 ~= length( files )
        error(sprintf('Wrong number of participant (%d) in pInfo structure, should be %d based on the number of files', size(opt.pInfo,1)-1, length( files )));
    end
end
participants = { 'participant_id' };
for iSubj=2:size(opt.pInfo,1)
    if strcmp('participant_id', opt.pInfo{1,1})
        opt.pInfo{iSubj,1} = removeInvalidChar(opt.pInfo{iSubj,1});
        if length(opt.pInfo{iSubj,1}) > 3 && isequal('sub-', opt.pInfo{iSubj,1}(1:4))
            participants{iSubj, 1} = opt.pInfo{iSubj,1};
        elseif strcmpi(opt.createids, 'off')
            participants{iSubj, 1} = sprintf('sub-%s', opt.pInfo{iSubj,1});
        else
            participants{iSubj, 1} = sprintf('sub-%3.3d', iSubj-1);
        end
    else
        participants{iSubj, 1} = sprintf('sub-%3.3d', iSubj-1);
    end
end
if size(opt.pInfo,1) > 1
    if strcmp('participant_id', opt.pInfo{1,1})
        participants(:,2:size(opt.pInfo,2)) = opt.pInfo(:,2:end);
    else
        participants(:,2:size(opt.pInfo,2)+1) = opt.pInfo;
    end
end

% remove empty columns
for iInfo = size(participants,2):-1:1
    if all(cellfun(@isempty, participants(2:end,iInfo)))
        if isfield(opt.pInfoDesc, participants{1,iInfo})
            opt.pInfoDesc = rmfield(opt.pInfoDesc, participants{1,iInfo});
        end
        participants(:,iInfo) = [];
    end
end
writetsv(fullfile(opt.targetdir, 'participants.tsv'), participants);

% write participants field description (participants.json)
% --------------------------------------------------------
descFields = { 'LongName'     'optional' 'char'   '';
    'Levels'       'optional' 'struct' struct([]);
    'Description'  'optional' 'char'   '';
    'Units'        'optional' 'char'   '';
    'TermURL'      'optional' 'char'   '' };
if ~isempty(opt.pInfo)
    fields = fieldnames(opt.pInfoDesc);
    if ~isempty(setdiff(fields, participants(1,:)))
        error('Some field names in the pInfoDec structure do not have a corresponding column name in pInfo');
    end
    fields = participants(1,:);
    for iField = 1:length(fields)
        descFields{1,4} = fields{iField};
        if ~isfield(opt.pInfoDesc, fields{iField}), opt.pInfoDesc(1).(fields{iField}) = struct([]); end
        opt.pInfoDesc.(fields{iField}) = bids_checkfields(opt.pInfoDesc.(fields{iField}), descFields, 'pInfoDesc');
    end
    % remove empty fields for BIDS compliance
    for iField = 1:length(fields)
        if isempty(opt.pInfoDesc.(fields{iField}))
            opt.pInfoDesc = rmfield(opt.pInfoDesc, fields{iField});
        end
    end
    if ~isempty(fieldnames(opt.pInfoDesc))
        jsonwrite(fullfile(opt.targetdir, 'participants.json'), opt.pInfoDesc, struct('indent','  '));
    end
end
if strcmpi(opt.writePInfoOnly, 'on'), return; end % for a rare case that the particiapnts.tsv table needs to be re-created.

% prepare event file information (_events.json)
% ----------------------------
eInfoDescFields = { 'LongName'     'optional' 'char'   '';
    'Levels'       'optional' 'struct' struct([]);
    'Description'  'optional' 'char'   '';
    'Units'        'optional' 'char'   '';
    'TermURL'      'optional' 'char'   '';
    'HED'          'optional' 'struct'   struct([])};
fields = fieldnames(opt.eInfoDesc);
for iField = 1:length(fields)
    descFields{1,4} = fields{iField};
    if ~isfield(opt.eInfoDesc, fields{iField}), opt.eInfoDesc(1).(fields{iField}) = struct([]); end
    opt.eInfoDesc.(fields{iField}) = bids_checkfields(opt.eInfoDesc.(fields{iField}), eInfoDescFields, 'eInfoDesc');
end

% Write README files (README)
% ---------------------------
if isempty(opt.README)
    opt.README = bids_template_README();
end
if ~isempty(opt.README)
    if exist(opt.README) ~= 2
        fid = fopen(fullfile(opt.targetdir, 'README'), 'w');
        if fid == -1, error('Cannot write README file'); end
        fprintf(fid, '%s', opt.README);
        fclose(fid);
    else
        copyfile(opt.README, fullfile(opt.targetdir, 'README'));
    end
end

% Write CHANGES files (CHANGES)
% -----------------------------
if ~isempty(opt.CHANGES)
    if ~exist(opt.CHANGES)
        fid = fopen(fullfile(opt.targetdir, 'CHANGES'), 'w');
        if fid == -1, error('Cannot write README file'); end
        fprintf(fid, '%s', opt.CHANGES);
        fclose(fid);
    else
        copyfile(opt.CHANGES, fullfile(opt.targetdir, 'CHANGES'));
    end
end

% Write code files (code)
% -----------------------
if ~isempty(opt.codefiles)
    for iFile = 1:length(opt.codefiles)
        [~,fileName,Ext] = fileparts(opt.codefiles{iFile});
        if ~isempty(dir(opt.codefiles{iFile}))
            copyfile(opt.codefiles{iFile}, fullfile(opt.targetdir, 'code', [ fileName Ext ]));
        else
            fprintf('Warning: cannot find code file %s\n', opt.codefiles{iFile})
        end
    end
end

% Write stimulus files
% --------------------
if ~isempty(opt.stimuli)
    disp('Copying stimuli...');
    for iStim = 1:size(opt.stimuli,1)
        [~,fileName,Ext] = fileparts(opt.stimuli{iStim,2});
        if ~isempty(dir(opt.stimuli{iStim,2}))
            copyfile(opt.stimuli{iStim,2}, fullfile(opt.targetdir, 'stimuli', [ fileName Ext ]));
        else
            fprintf('Warning: cannot find stimulus file %s\n', opt.stimuli{iStim,2});
        end
        opt.stimuli{iStim,2} = [ fileName,Ext ];
    end
end

% set beh info (behavioral)
% ------------
if ~isfield(files(1), 'beh')
    for iSubj = 1:length(files)
        files(iSubj).beh = cell(1,length(files(iSubj).file));
    end
end

% load channel information
% ------------------------
chanlocs = {};
if ~isempty(opt.chanlocs) && isstr(opt.chanlocs)
    opt.chanlocs = readlocs(opt.chanlocs);    
end
if ~isfield(files(1), 'chanlocs')
    for iSubj = 1:length(files)
        for iFile = 1:length(files(iSubj).file)
            files(iSubj).chanlocs{iFile} = opt.chanlocs;
        end
    end
end

% Heuristic for identifying multiple/single-run/sessions
%--------------------------------------------------------------------------
for iSubj = 1:length(files)
    allsubjnruns(iSubj)     = length(unique(files(iSubj).run));
    allsubjnsessions(iSubj) = length(unique(files(iSubj).session));
    allsubjntasks(iSubj)    = length(unique(files(iSubj).task));
end

multSessionFlag = 1;
if all(allsubjnsessions == 1) && ~strcmpi(opt.forcesession, 'on')
    multSessionFlag = 0;
end

multRunFlag = 1;
if all(allsubjnruns == 1) && ~strcmpi(opt.forcerun, 'on')
    multRunFlag = 0;
end

hasTaskFlag = 0;
if all(allsubjntasks >= 1)
    hasTaskFlag = 1;
end

% tmpsessrun = [multsessionflag multrunflag];
% if all(tmpsessrun == [0 0])    % Single-Session Single-Run 
%     bidscase = 1;
% elseif all(tmpsessrun == [0 1]) % Single-Session Mult-Run 
%     bidscase = 2;
% elseif all(tmpsessrun == [1 0]) % Mult-Session Single-Run
%     bidscase = 3;
% elseif all(tmpsessrun == [1 1]) % Mult-Session Mult-Run
%     bidscase = 4;
% end
% if bidscase == 5
%     bidscase = 1; % Mult Task: Single-Session Single-Run
% end
% if bidscase == 6
%     bidscase = 3; % Mult Task: Mult-Session Single-Run
% end

%---------------
% copy EEG files
% --------------
disp('Copying EEG files...')
for iSubj = 1:length(files)
    if ~isempty(opt.pInfo)
        subjectStr = participants{iSubj+1,1}; % first row of participants contains header
    else
        subjectStr    = sprintf('sub-%3.3d', iSubj);
    end
    
    % copy anatomical file if any
    if isfield(files(iSubj), 'anat') && ~isempty(files(iSubj).anat)
        mkdir(fullfile(opt.targetdir, subjectStr, 'anat'));
        
        % Currently supporting Single-Session Single-Run of MRI anat only.
        % If interested in other combinations of run/sessions please contact the authors.
        fileOut = fullfile(opt.targetdir, subjectStr, 'anat', [ subjectStr '_mod-' opt.anattype ]);
        
        if strcmpi(opt.defaced, 'on')
            fileOut = [ fileOut '_defacemask' ];
        end
        if files(iSubj).anat(end) == 'z'
            fileOut = [ fileOut '.nii.gz' ];
        else
            fileOut = [ fileOut '.nii' ];
        end
        copyfile(files(iSubj).anat, fileOut);
    end
    
    for iItem = 1:length(files(iSubj).file) % scan files for subject
        structOut = getElement(files(iSubj), iItem);

        sessFolder  = '';
        fileStr     = subjectStr;
        if multSessionFlag
            fileStr    = [ fileStr '_ses-' files(iSubj).session{iItem} ];
            sessFolder = [ 'ses-' files(iSubj).session{iItem} ];
        end
        if hasTaskFlag
            fileStr    = [ fileStr  '_task-' char(files(iSubj).task(iItem)) ];
            opt.tInfo(1).TaskName = char(files(iSubj).task(iItem)); % will be written below
        end
        if strcmpi(opt.individualEventsJson, 'off') % top level file overwriten every iteration but that's OK
            jsonwrite(fullfile(opt.targetdir, ['task-' opt.tInfo.TaskName '_events.json' ]), opt.eInfoDesc, struct('indent','  '));
        end
        if multRunFlag
            if ~strcmp(files(iSubj).run{iItem}, 'NaN')
                fileStr    = [ fileStr  '_run-' files(iSubj).run{iItem} ];
            end
        end        

        fileOutBeh = fullfile(opt.targetdir, subjectStr, sessFolder, 'beh', [fileStr '_beh.tsv' ]);
        copy_data_bids_eeg( structOut, subjectStr, sessFolder, fileStr, opt);
        bids_writebehfile(files(iSubj).beh{iItem}, opt.behInfo, fileOutBeh);
    end

end

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function copy_data_bids_eeg(sIn, subjectStr, sess, fileStr, opt)

fileIn   = sIn.file;
notes    = sIn.notes;
chanlocs = sIn.chanlocs;
timeoffset = sIn.timeoffset;
eventtype  = sIn.eventtype;
eventindex = sIn.eventindex;

if isempty(fileIn)
    return
end

% force EEGLAB export if anything is done on the file
if ~isempty(eventtype) || ~isempty(eventindex) || ~isempty(timeoffset)
    fprintf('File will be exported in EEGLAB formet because of segment selection\n')
    opt.exportformat = 'eeglab';
end

% import data
tInfo = opt.tInfo;
[pathIn,fileInNoExt,ext] = fileparts(fileIn);
fprintf('Processing file %s\n', fileIn);
[EEG,opt.modality] = eeg_import(fileIn, 'modality', opt.modality, 'noevents', opt.noevents, 'importfunc', opt.importfunc);
if contains(fileIn, '_bids_tmp_') && strcmpi(opt.rmtempfiles, 'on')
    fprintf('Deleting temporary file %s\n', fileIn);
    delete(fileIn);
end

% Add desc to fileStr if provided in generatedBy
if isempty(opt.GeneratedBy) && isfield(opt.gInfo, 'GeneratedBy') % look at the casing
    opt.GeneratedBy = opt.gInfo.GeneratedBy;
end
if isfield(opt, 'GeneratedBy') && isfield(opt.GeneratedBy, 'desc') && ~isempty(opt.GeneratedBy.desc)
    fileStr = [fileStr '_desc-' opt.GeneratedBy.desc];
end


% output folder creation
fileBase = fullfile(opt.targetdir, subjectStr, sess, opt.modality, fileStr);
folderOut = fileparts(fileBase);
if ~exist(folderOut)
    mkdir(folderOut);
end
fileOut = [fileBase '_' opt.modality ext];

% select data subset
EEG = eeg_selectsegment(EEG, 'eventtype', eventtype, 'eventindex', eventindex, 'timeoffset', timeoffset );        

if ~isequal(opt.exportformat, 'same') || isequal(ext, '.set')
    % export data if necessary
    [filePathTmp,fileOutNoExt,~] = fileparts(fileOut);
    if isequal(opt.exportformat, 'eeglab')
        pop_saveset(EEG, 'filename', [ fileOutNoExt '.set' ], 'filepath', filePathTmp);
    else
        pop_writeeeg(EEG, fullfile(filePathTmp, [ fileOutNoExt '.' opt.exportformat]), 'TYPE',upper(opt.exportformat));
    end
else
    % copy the file
    if ~strcmpi(ext, { '.bdf', '.edf', '.set', '.vhdr', '.ds', '.fiff', '.mefd', '.nwb', '.gz' })
        error('''exportformat'' set to copy the file to the BIDS output folder but the file is not BIDS compliant')
    else
        if isequal(ext, '.bdf') || isequal(ext, '.edf')
            % anonymize file
            fprintf('EDF or BDF file detected, anonymizing the file...\n');
            fileIDIn  = fopen(fileIn,'rb','ieee-le');  % see sopen
            fileIDOut = fopen(fileOut,'wb','ieee-le');  % see sopen
            if fileIDIn  == -1, error('Cannot read file %s', fileIn); end
            if fileIDOut == -1, error('Cannot write file %s', fileOut); end
            data = fread(fileIDIn, Inf);
            data(9:9+160-1) = ' '; % remove potential identity
            fwrite(fileIDOut, data);
            fclose(fileIDIn);
            fclose(fileIDOut);
            if strcmpi(ext, '.bdf')
                tInfo.EEGReference = 'CMS/DRL';
                tInfo.Manufacturer = 'BIOSEMI';
            end
        elseif isequal(ext, '.vhdr') ||  isequal(ext, '.eeg')
            rename_brainvision_files(fileIn, fileOut, 'rmf', 'off');
        else
            copyfile(fileIn, fileOut);
        end
    end
end

% export eye-tracking data
eyeWritenStatus = save_bids_eye_tracking(sIn, fileBase, EEG, opt);

% write events
indExt = find(fileOut == '_');
fileOutRed = fileOut(1:indExt(end)-1);
if ~strcmpi(opt.eventexport, 'off')
    if strcmpi(opt.eventexport, 'on') || ~isempty(EEG.event)
        bids_writeeventfile(EEG, fileOutRed, 'eInfo', opt.eInfo, 'eInfoDesc', opt.eInfoDesc, 'individualEventsJson', opt.individualEventsJson, ...
            'ignoreemptyfields', opt.eventfieldignore, 'renametype', opt.renametype, 'stimuli', opt.stimuli, 'checkresponse', opt.checkresponse, 'omitsample', fastif(eyeWritenStatus, 'on', 'off'));
    end
end

% Write channel file information (channels.tsv)
% Note: Consider using here electrodes_to_tsv.m
% fid = fopen( [ fileOutRed 'channels.tsv' ], 'w');
% miscChannels = 0;
if ~isempty(chanlocs)
    EEG.chanlocs = chanlocs;
    if ischar(EEG.chanlocs)
        EEG.chanlocs = readlocs(EEG.chanlocs);
    end
    EEG = eeg_checkchanlocs(EEG);
    if length(EEG.chanlocs) == EEG.nbchan+1
        for iChan = 1:length(EEG.chanlocs)
            EEG.chanlocs(iChan).ref = EEG.chanlocs(end).labels;
        end
    elseif length(EEG.chanlocs) ~= EEG.nbchan
        error(sprintf('Number of channels in channel location inconsistent with data for file %s', fileIn));
    end
end
if ischar(opt.chanlookup) && ~isempty(opt.chanlookup)
    EEG=pop_chanedit(EEG, 'lookup', opt.chanlookup);
end

% Write electrode file information (electrodes.tsv and coordsystem.json)
bids_writechanfile(EEG, fileOutRed);
bids_writeelectrodefile(EEG, fileOutRed, 'export', opt.elecexport);
if strcmpi(opt.modality, 'eeg')
    bids_writetinfofile(EEG, tInfo, notes, fileOutRed);
    EEG.etc.datatype = 'eeg';
elseif strcmpi(opt.modality, 'ieeg')
    bids_writeieegtinfofile(EEG, tInfo, notes, fileOutRed);
    EEG.etc.datatype = 'ieeg';
elseif strcmpi(opt.modality, 'meg')
    bids_writemegtinfofile(EEG, tInfo, notes, fileOutRed);
    EEG.etc.datatype = 'meg';
end

% write channel information
%     cInfo.name.LongName = 'Channel name';
%     cInfo.name.Description = 'Channel name';
%     cInfo.type.LongName = 'Channel type';
%     cInfo.type.Description = 'Channel type';
%     cInfo.units.LongName = 'Channel unit';
%     cInfo.units.Description = 'Channel unit';
%     jsonStr = jsonencode(cInfo);
%     fid = fopen( [fileOut(1:end-3) 'channels.json' ], 'w');
%     fprintf(fid, '%s', jsonStr);
%     fclose(fid);


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function eyeWritenStatus = save_bids_eye_tracking(sIn, fileBase, EEG, opt)

eyeWritenStatus = false;
if ~isfield(sIn, 'eyefile')
    return
end
fileIn   = sIn.eyefile;
timeoffset = sIn.timeoffset;
eventtype  = sIn.eventtype;
eventindex = sIn.eventindex;

if ~isempty(timeoffset) || ~isempty(eventtype) || ~isempty(eventindex)
    error('Feature not implemented')
end

folderOut = fileparts(fileBase);

if isempty(fileIn)
    return
end
eyeWritenStatus = true;

if ~exist(folderOut)
    mkdir(folderOut);
end

eyeTrackingColumns = {...
'eye_timestamp'	    'REQUIRED'	'integer'	'Eye-tracker timestamp of the sampled recorded eye(s) gaze position coordinates and/or pupil size.';
'eye1_x_coordinate'	'REQUIRED'	'integer'	'Gaze position x-coordinate of the first recorded eye. If the two eyes are recorded, it MUST be the left eye x-coordinate.';
'eye1_y_coordinate'	'REQUIRED'	'integer'	'Gaze position y-coordinate of the first recorded eye. If the two eyes are recorded, it MUST be the left eye y-coordinate.';
'eye1_pupil_size'	'OPTIONAL'	'integer'	'Pupil size of the first recorded eye. If the two eyes are recorded, it MUST be the left eye pupil size.';
'eye2_x_coordinate'	'OPTIONAL'	'integer'	'Gaze position x-coordinate of the second recorded eye. If the two eyes are recorded, it MUST be the right eye x-coordinate.';
'eye2_y_coordinate'	'OPTIONAL'	'integer'	'Gaze position y-coordinate of the second recorded eye. If the two eyes are recorded, it MUST be the right eye y-coordinate.';
'eye2_pupil_size'	'OPTIONAL'	'integer'	'Pupil size of the second recorded eye. If the two eyes are recorded, it MUST be the right eye pupil size.'
};

tInfo = opt.tInfoeye;
[~,~,ext] = fileparts(fileIn);
fileOut = [fileBase '_eyetrack.tsv' ];
fprintf('Processing file %s\n', fileOut);
if strcmpi(ext, '.txt')
    EYE = pop_read_smi(fileIn, []);

    % columns to match 
    cols = eyeTrackingColumns(:,1);
    cols{2,2} = 'L EPOS X';
    cols{3,2} = 'L EPOS Y';
    cols{4,2} = 'L Mapped Diameter [mm]';
    cols{5,2} = 'R EPOS X';
    cols{6,2} = 'R EPOS Y';
    cols{7,2} = 'R Mapped Diameter [mm]';

    colNames = { EYE.chanlocs.labels };
    for iCol = size(cols,1):-1:1
        ind = strmatch(cols{iCol,2}, colNames, 'exact');
        if ~isempty(ind)
            EYE.chanlocs(2:end+1) = EYE.chanlocs;
            EYE.chanlocs(1).labels = cols{iCol,1};
            EYE.data = [ EYE.data(ind,:); EYE.data];
        end
    end
                
    % adding time stamp in samples
    EYE.chanlocs(2:end+1) = EYE.chanlocs;
    EYE.chanlocs(1).labels = cols{1,1};
    EYE.data = [ [1:EYE.pnts]; EYE.data];
elseif strcmpi(ext, '.tsv')
    EYE = pop_read_gazepoint(fileIn);

    % columns to match 
    cols = eyeTrackingColumns(:,1);
    cols{1,2} = 'TIME';  
    cols{2,2} = 'LPOGX'; % LEYEX ?
    cols{2,2} = 'LPOGX';
    cols{3,2} = 'LPOGY';
    cols{4,2} = 'LPUPILD';
    cols{5,2} = 'RPOGX';
    cols{6,2} = 'RPOGY';
    cols{7,2} = 'RPUPILD';

    colNames = { EYE.chanlocs.labels };
    for iCol = size(cols,1):-1:1
        ind = strmatch(cols{iCol,2}, colNames, 'exact');
        if ~isempty(ind)
            EYE.chanlocs(2:end+1) = EYE.chanlocs;
            EYE.chanlocs(1).labels = cols{iCol,1};
            EYE.data = [ EYE.data(ind,:); EYE.data];
        end
    end

else
    error('Data format not supported');
end
if strcmpi(opt.noevents, 'on')
    EYE.event = [];
end

% select data subset
%EYE = eeg_selectsegment(EYE, 'eventtype', eventtype, 'eventindex', eventindex, 'timeoffset', timeoffset );        

if isfield(EYE.event, 'description') % use for type
    fprintf('Warning: using description field in eye-tracking channel for event type\n')
    for iEvent = 1:length(EYE.event)
        if ~isempty(EYE.event(iEvent).description)
            EYE.event(iEvent).type = deblank(EYE.event(iEvent).description);
        end
    end
end
EYE = eeg_checkset(EYE, 'eventconsistency');
MERGEDEEG = eeg_mergechannels(EEG, EYE);

EYEPRIME      = MERGEDEEG;
EYEPRIME.data     = EYEPRIME.data(EEG.nbchan+1:end,:);
EYEPRIME.chanlocs = EYEPRIME.chanlocs(EEG.nbchan+1:end);

indExt = find(fileOut == '_');
fileOutRed = fileOut(1:indExt(end)-1);
bids_writeeventfile(MERGEDEEG, fileOutRed, 'eInfo', opt.eInfo, 'eInfoDesc', opt.eInfoDesc, 'individualEventsJson', opt.individualEventsJson, ...
    'renametype', opt.renametype, 'stimuli', opt.stimuli, 'checkresponse', opt.checkresponse, 'omitsample', 'on');

% export the data
tmpTable = array2table(EYEPRIME.data', 'VariableNames', { EYEPRIME.chanlocs.labels });
writetable(tmpTable, fileOut, 'FileType', 'text', 'delimiter', '\t');

tInfoFields = {...
    'SamplingFrequency'	        'REQUIRED'	''	    'n/a' 'Sampling frequency (in Hz) of all the data in the recording, regardless of their type (for example, 2400).';
    'SampleCoordinateUnit'	    'REQUIRED'	'char'	'n/a' 'string	Unit of individual samples ("pixel", "mm" or "cm") . Must be one of: "pixel", "mm", "cm".'
    'SampleCoordinateSystem'	'REQUIRED'	'char'	'n/a' 'string	Coordinate system of the sampled gaze position data. Generally eye-tracker are set to use "gaze-on-screen" coordinate system but you may use "eye-in-head" or "gaze-in-world" or other alternatives of your choice. If you use the standard "gaze-on-screen", it is RECOMMENDED to use this exact label.';
    'EnvironmentCoordinates'	'REQUIRED'	'char'	'n/a' 'string	Coordinates origin (or zero), for gaze-on-screen coordinates, this can be for example: "top-left" or "center". For virtual reality this could be, amongst others, spherical coordinates.';
    'ScreenSize'	            'REQUIRED'	''    	'n/a' 'Screen size in m, excluding potential screen borders (for example [0.472, 0.295] for a screen of 47.2-width by 29.5-height cm), if no screen use n/a.';
    'ScreenResolution'	        'REQUIRED'	''   	'n/a' 'Screen resolution in pixel (for example [1920, 1200] for a screen of 1920-width by 1080-height pixels), if no screen use n/a.';
    'ScreenDistance'	        'REQUIRED'	''  	'n/a' 'Distance between the participant''s eye and the screen. If no screen was used, use n/a.'
    };

tInfo(1).SamplingFrequency = EYE.srate;
tInfo = bids_checkfields(tInfo, tInfoFields, 'tInfo');

jsonwrite([fileBase '_eyetrack.json' ], tInfo, struct('indent','  '));

% write channel information
%     cInfo.name.LongName = 'Channel name';
%     cInfo.name.Description = 'Channel name';
%     cInfo.type.LongName = 'Channel type';
%     cInfo.type.Description = 'Channel type';
%     cInfo.units.LongName = 'Channel unit';
%     cInfo.units.Description = 'Channel unit';
%     jsonStr = jsonencode(cInfo);
%     fid = fopen( [fileOut(1:end-3) 'channels.json' ], 'w');
%     fprintf(fid, '%s', jsonStr);
%     fclose(fid);

function printEventHeader(eInfo)
fields = eInfo{:,1};


% write JSON file
% ---------------
function writejson(fileName, matlabStruct)
jsonStr = jsonencode(matlabStruct);

fid = fopen(fileName, 'w', 'n', 'UTF-8');
if fid == -1, error('Cannot write file - make sure you have writing permission'); end
fprintf(fid, '%s', jsonStr);
fclose(fid);

% write TSV file
% --------------
function writetsv(fileName, matlabArray)
fid = fopen(fileName, 'w', 'n', 'UTF-8');
if fid == -1, error('Cannot write file - make sure you have writing permission'); end
for iRow=1:size(matlabArray,1)
    for iCol=1:size(matlabArray,2)
        if isempty(matlabArray{iRow,iCol}) || all(isnan(matlabArray{iRow,iCol}))
            %disp('Empty value detected, replacing by n/a');
            fprintf(fid, 'n/a');
        elseif ischar(matlabArray{iRow,iCol})
            fprintf(fid, '%s', matlabArray{iRow,iCol});
        elseif isnumeric(matlabArray{iRow,iCol}) && rem(matlabArray{iRow,iCol},1) == 0
            fprintf(fid, '%d', matlabArray{iRow,iCol});
        elseif isnumeric(matlabArray{iRow,iCol})
            fprintf(fid, '%1.10f', matlabArray{iRow,iCol});
        else
            error('Table values can only be string or numerical values');
        end
        if iCol ~= size(matlabArray,2)
            fprintf(fid, '\t');
        end
    end
    fprintf(fid, '\n');
end
fclose(fid);

% remove invalid Chars
% -------------------- 
function structOut = getElement(bidsStructItem, ind)
    structOut = [];
    fields = fieldnames(bidsStructItem);
    for iField = 1:length(fields)
        if ~iscell(getfield(bidsStructItem, fields{iField}))
            tmp = getfield(bidsStructItem, fields{iField});
            structOut.(fields{iField}) = tmp;
        else
            tmp = getfield(bidsStructItem, fields{iField}, { ind });
            structOut.(fields{iField}) = tmp{1};
        end
    end

% remove invalid Chars
% --------------------       
function strout = removeInvalidChar(str)
    strout = str;
    %if any(strout == '-'), strout(strout == '-') = []; end
    if any(strout == '_'), strout(strout == '_') = []; end
    if ~isequal(str, strout)
        disp('Removing invalid characters in subject ID');
    end

