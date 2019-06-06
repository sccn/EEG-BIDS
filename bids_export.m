% bids_export - this function allows converting a collection of datasets to
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
%                same index. See example below for a case with 2 subjects with
%                2 sessions and 2 run each:
%                 subject(1).file    = {'subj-1_ss-1-run1' 'subj-1_ss-1-run2' 'subj-1_ss-2-run1' 'subj-1_ss-2-run2'};    
%                 subject(1).session = [ 1 1 2 2 ];
%                 subject(1).run     = [ 1 2 1 2 ];
%                 subject(1).file    = {'subj-2_ss-1-run1' 'subj-2_ss-1-run2' 'subj-2_ss-2-run1' 'subj-2_ss-2-run2'}; 
%                 subject(2).session = [ 1 1 2 2 ];
%                 subject(2).run     = [ 1 2 1 2 ];
%
% Optional inputs:
%  'targetdir' - [string] target directory. Default is 'bidsexport' in the
%                current folder.
%
%  'taskname'  - [string] name of the task. No space are allowed and no
%                special characters. Default is ''.
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
%  'stimuli'   - [cell] cell array of type and corresponding file names.   
%                For example: { 'sound1' '/Users/xxxx/sounds/sound1.mp3';  
%                               'img1'   '/Users/xxxx/sounds/img1.jpg' }   
%                (the semicolumn above is optional)
%
%  'gInfo'     - [struct] general information fields. See BIDS specifications.
%                For example.
%                info.ReferencesAndLinks = { 'Pubmed 122032020' };
%                info.Name = 'This is a custom task';
%                info.License = 'Creative commons';
%
%  'tInfo'     - [struct] task information fields. See BIDS specifications.
%                For example.
%                tInfo.InstitutionAddress = '9500 Gilman Drive, CA92093-0559 La Jolla, USA';
%                tInfo.InstitutionName = 'Univesity of California, San Diego';
%                tInfo.InstitutionalDepartmentName = 'Institute of Neural Computation';
%                tInfo.PowerLineFrequency = 50;
%                tInfo.SoftwareFilters = struct('NotchFilter', struct('cutof', '50 (Hz)'));
%
%  'pInfo'     - [cell] cell array of participant values, with one row
%                per participants. The first row contains columns names.
%                For example for 2 participants:
%                { 'sex'     'age';
%                  'male'    20;
%                  'female'  25 };
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
%                event fields in the EEGLAB event structure. Note that
%                EEGLAB event latency, duration, and type are inserted
%                automatically as columns "onset" (latency in sec), "duration"
%                (duration in sec), "event_sample" (latency), "event_type"
%                (time locking event), "event_value" (type). For example
%                { 'HED' 'reaction_time';
%                  'HED' 'rt' }
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
%  'trialtype' - [cell] 2 column cell table indicating the type of event
%                for each event type. For example { '2'    'stimulus';
%                                                   '4'    'stimulus';
%                                                   '128'  'response' }
%
%  'chanlocs'  - [cell or struct or file name] channel location structure or file 
%                name to use when saving channel information. Note that
%                this assumes that all the files have the same number of
%                channels. If a cell array is given as input, the size
%                must be the same as the one used for files given as input.
%
% 'copydata'   -[0|1] While exporting EEGLAB data to BIDS (.set, .fdt), this flag
%               will enable the copy of all the data files [1], or just create the
%               BIDS files hierarchy without the large data files [0]. This
%               options is aimed to be used to speedup the troubleshooting
%               of bids_export execution. Default: [1]
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
% Authors: Arnaud Delorme, 2019
%          Ramon Martinez-Cancino, 2019

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

opt = finputcheck(varargin, {'ReferencesAndLinks' 'cell'   {}   { 'n/a' };
                            'Name'      'string'  {}    'n/a';
                            'License'   'string'  {}    'n/a';
                            'targetdir' 'string'  {}    fullfile(pwd, 'bidsexport');
                            'taskName'  'string'  {}    'Experiment';
                            'codefiles' 'cell'    {}    {};
                            'stimuli'   'cell'    {}    {};
                            'pInfo'     'cell'    {}    {};
                            'eInfo'     'cell'    {}    {};
                            'cInfo'     'cell'    {}    {};
                            'gInfo'     'struct'  {}    struct([]);
                            'tInfo'     'struct'  {}    struct([]);
                            'pInfoDesc' 'struct'  {}    struct([]);
                            'eInfoDesc' 'struct'  {}    struct([]);
                            'cInfoDesc' 'struct'  {}    struct([]);
                            'trialtype' 'cell'    {}    {};
                            'chanlocs'  ''        {}    '';
                            'README'    'string'  {}    '';
                            'CHANGES'   'string'  {}    '' ;
                            'copydata'   'real'   [0 1] 1 }, 'bids_format_eeglab');
if isstr(opt), error(opt); end
if size(opt.stimuli,1) == 1 || size(opt.stimuli,1) == 1
    opt.stimuli = reshape(opt.stimuli, [2 length(opt.stimuli)/2])';
end

% deleting folder
fprintf('Exporting data to %s...\n', opt.targetdir);
if exist(opt.targetdir,'dir')
    disp('Deleting folder...')
    rmdir(opt.targetdir, 's');
end

disp('Creating sub-directories...')
mkdir( fullfile(opt.targetdir, 'code'));
mkdir( fullfile(opt.targetdir, 'stimuli'));

% write dataset info (dataset_description.json)
% ---------------------------------------------
gInfoFields = { 'ReferencesAndLinks' 'required' 'cell' { 'n/a' };
                'Name'               'required' 'char' '';
                'License'            'required' 'char' 'CC0';
                'BIDSVersion'        'required' 'char' '1.1.1' ;
                'Authors'            'optional' 'cell' { 'n/a' };
                'Acknowledgements'   'optional' 'char' '';
                'HowToAcknowledge'   'optional' 'char' '';
                'Funding'            'optional' 'cell' { 'n/a' };
                'DatasetDOI'         'optional' 'char' { 'n/a' }};
            
opt.gInfo = checkfields(opt.gInfo, gInfoFields, 'gInfo');
jsonwrite(fullfile(opt.targetdir, 'dataset_description.json'), opt.gInfo, struct('indent','  '));

% write participant information (participants.tsv)
% -----------------------------------------------
if ~isempty(opt.pInfo)
    participants = { 'participant_id' };
    for iSubj=1:length(files)
        participants{iSubj+1, 1} = sprintf('sub-%3.3d', iSubj);
    end
    if ~isempty(opt.pInfo)
        if size(opt.pInfo,1) ~= length(participants)
            error(sprintf('Wrong number of participant (%d) in tInfo structure, should be %d based on the number of files', size(opt.pInfo,1)-1, length(files)));
        end
        participants(:,2:size(opt.pInfo,2)+1) = opt.pInfo;
    end
    writetsv(fullfile(opt.targetdir, 'participants.tsv'), participants);
end

% write participants field description (participants.json)
% --------------------------------------------------------
descFields = { 'LongName'     'optional' 'char'   '';
               'Levels'       'optional' 'struct' {};
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
        opt.pInfoDesc.(fields{iField}) = checkfields(opt.pInfoDesc.(fields{iField}), descFields, 'pInfoDesc');
    end
    jsonwrite(fullfile(opt.targetdir, 'participants.json'), opt.pInfoDesc,struct('indent','  '));
end

% write event file information (task-xxxxx_events.json)
% ----------------------------
events = { 'onset' 'duration' };
fields = fieldnames(opt.eInfoDesc);
% if ~ismember('onset', fields)
%     disp('"onset" event field names in the eInfoDesc structure is missing, creating one');
%     eInfoDesc.onset.Description = 'Event onset';
%     eInfoDesc.onset.Units = 'second';
% end
% if ~ismember('onset', fields)
%     disp('"duration" event field names in the eInfoDesc structure is missing, creating one');
%     eInfoDesc.duration.Description = 'Event duration';
%     eInfoDesc.duration.Units = 'second';
% end
for iField = 1:length(fields)
    descFields{1,4} = fields{iField};
    if ~isfield(opt.eInfoDesc, fields{iField}), opt.eInfoDesc(1).(fields{iField}) = struct([]); end
    opt.eInfoDesc.(fields{iField}) = checkfields(opt.eInfoDesc.(fields{iField}), descFields, 'eInfoDesc');
end
jsonwrite(fullfile(opt.targetdir, [ 'task-' opt.taskName '_events.json' ]), opt.eInfoDesc,struct('indent','  '));

% Write README files (README)
% ---------------------------
if ~isempty(opt.README)
    if ~exist(opt.README)
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
    if size(opt.stimuli,1) == 1, opt.stimuli = opt.stimuli'; end
    for iStim = 1:size(opt.stimuli,1)
        [~,fileName,Ext] = fileparts(opt.stimuli{iStim,1});
        if ~isempty(dir(opt.stimuli{iStim,1}))
            copyfile(opt.stimuli{iStim,1}, fullfile(opt.targetdir, 'stimuli', [ fileName Ext ]));
        else
            fprintf('Warning: cannot find stimulus file %s\n', opt.codefiles{iFile});
        end
    end
end

% check task info
% ---------------
opt.tInfo(1).TaskName = opt.taskName;

% load channel information
% ------------------------
chanlocs = {};
if ~isempty(opt.chanlocs) && isstr(opt.chanlocs)
    opt.chanlocs = readlocs(opt.chanlocs);
end
if iscell(opt.chanlocs)
    chanlocs = opt.chanlocs;
else
    chanlocs = {};
    for iSubj = 1:length(files)
        nsessions = length(unique(files(iSubj).session));
        if nsessions > 1 %iscell(files{iSubj})
            for iSess = 1:nsessions %length(files{iSubj})
                chanlocs{iSubj}{iSess} = opt.chanlocs;
            end
        else
            chanlocs{iSubj} = opt.chanlocs;
        end
    end
end

% Heuristic for identifying multiple/single-run/sessions
%--------------------------------------------------------------------------
for iSubj = 1:length(files)
    allsubjnruns(iSubj)    = length(unique(files(iSubj).run)); 
   allsubjnsessions(iSubj) = length(unique(files(iSubj).session)); 
end
tmpuniqueruns = unique(allsubjnruns);
tmpuniquesessions = unique(allsubjnsessions);

multsessionflag = 1;
if length(tmpuniquesessions) == 1 && tmpuniquesessions == 1
        multsessionflag = 0;
end

multrunflag = 1;
if length(tmpuniqueruns) == 1 && tmpuniqueruns == 1
        multrunflag = 0;
end

tmpsessrun = [multsessionflag multrunflag];
if tmpsessrun == [0 0]    % Single-Session Single-Run
    bidscase = 1';
elseif tmpsessrun == [0 1]% Single-Session Mult-Run
    bidscase = 2';
elseif tmpsessrun == [1 0] % Mult-Session Single-Run
    bidscase = 3;
elseif tmpsessrun == [1 1] % Mult-Session Mult-Run
    bidscase = 4;
end
%--------------------------------------------------------------------------
% copy EEG files
% --------------
disp('Copying EEG files...')
for iSubj = 1:length(files)
    subjectStr    = sprintf('sub-%3.3d', iSubj);
    
    switch bidscase
        case 1 % Single-Session Single-Run
            
            fileOut = fullfile(opt.targetdir, subjectStr, 'eeg', [ subjectStr '_task-' opt.taskName '_eeg' files(iSubj).file{1}(end-3:end)]);
            copy_data_bids( files(iSubj).file{1}, fileOut, opt.tInfo, opt.trialtype, chanlocs{iSubj}, opt.copydata);
            
        case 2 % Single-Session Mult-Run
            
            for iRun = 1:length(files(iSubj).run)
                fileOut = fullfile(opt.targetdir, subjectStr, 'eeg', [ subjectStr  '_task-' opt.taskName sprintf('_run-%2.2d', iRun) '_eeg' files(iSubj).file{iRun}(end-3:end) ]);
                copy_data_bids( files(iSubj).file{iRun}, fileOut, opt.tInfo, opt.trialtype, chanlocs{iSubj}, opt.copydata);
            end
            
        case 3 % Mult-Session Single-Run
            
            for iSess = 1:length(unique(files(iSubj).session))
                fileOut = fullfile(opt.targetdir, subjectStr, sprintf('ses-%2.2d', iSess), 'eeg', [ subjectStr sprintf('_ses-%2.2d', iSess) '_task-' opt.taskName '_eeg' files(iSubj).file{iSess}(end-3:end)]);
                copy_data_bids( files(iSubj).file{iSess}, fileOut, opt.tInfo, opt.trialtype, chanlocs{iSubj}{iSess}, opt.copydata);
            end           
            
        case 4 % Mult-Session Mult-Run
            
            for iSess = 1:length(unique(files(iSubj).session))
                runindx = find(files(iSubj).session == iSess);
                for iSet = runindx
                    iRun = files(iSubj).run(iSet);
                    fileOut = fullfile(opt.targetdir, subjectStr, sprintf('ses-%2.2d', iSess), 'eeg', [ subjectStr sprintf('_ses-%2.2d', iSess) '_task-' opt.taskName  sprintf('_run-%2.2d', iRun) '_eeg' files(iSubj).file{iSet}(end-3:end)]);
                    copy_data_bids(files(iSubj).file{iSet}, fileOut, opt.tInfo, opt.trialtype, chanlocs{iSubj}{iSess}, opt.copydata);
                end
            end      
    end
end

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function copy_data_bids(fileIn, fileOut, tInfo, trialtype, chanlocs, copydata)
    folderOut = fileparts(fileOut);
    if ~exist(folderOut)
        mkdir(folderOut);
    end
    if ~exist(fileOut)
    end
    % if BDF file anonymize records
    [~,~,ext] = fileparts(fileOut);
    if strcmpi(ext, '.bdf')
        fileIDIn  = fopen(fileIn,'rb','ieee-le');  % see sopen
        fileIDOut = fopen(fileOut,'wb','ieee-le');  % see sopen
        data = fread(fileIDIn, Inf);
        data(9:9+160-1) = ' ';
        fwrite(fileIDOut, data);
        fclose(fileIDIn);
        fclose(fileIDOut);
        tInfo.EEGReference = 'CMS/DRL';
        tInfo.Manufacturer = 'BIOSEMI';
        EEG = pop_biosig(fileOut);
    elseif strcmpi(ext, '.set')
        [outfilepath, outfilename,outfileext] = fileparts(fileOut);
        if copydata      
            EEGin = pop_loadset(fileIn);
            EEG   = pop_saveset(EEGin, 'filename',[outfilename outfileext], 'filepath', outfilepath);
        else
            copyfile(fileIn, fileOut);
           EEG = pop_loadset([outfilename outfileext],outfilepath, 'loadmode', 'info');
        end
    else
        error('Data format not supported');
    end
    
    % Getting events latency
    insertEpoch = false;
    if EEG.trials > 1
        % get TLE events
        insertEpoch = true;
        eventlat = abs(eeg_point2lat( [ EEG.event.latency ], [ EEG.event.epoch ], EEG.srate, [EEG.xmin EEG.xmax]));
        indtle    = find(eventlat == 0);
        if length(indtle) < EEG.trials
            indtle    = find(eventlat < 0.02);
        end
        if length(indtle) ~= EEG.trials
            insertEpoch = false;
        end
    end

    % write event file information
    fid = fopen( [ fileOut(1:end-7) 'events.tsv' ], 'w');
    fprintf(fid, 'onset\tduration\ttrial_type\tresponse_time\tsample\tvalue\n');
    for iEvent = 1:length(EEG.event)
        onset = (EEG.event(iEvent).latency-1)/EEG.srate;

        % duration
        if isfield(EEG.event, 'duration') && ~isempty(EEG.event(iEvent).duration)
            duration = num2str(EEG.event(iEvent).duration, '%1.10f') ;
        else
            duration = 'n/a';
        end

        % event value
        if isstr(EEG.event(iEvent).type)
            eventValue = EEG.event(iEvent).type;
        else
            eventValue = num2str(EEG.event(iEvent).type);
        end

        % event type (which is the type of event - not the same as EEGLAB)
        trialType = 'STATUS';
        if isfield(EEG.event, 'trial_type')
            trialType = EEG.event(iEvent).trial_type;
        elseif ~isempty(trialtype)
            indTrial = strmatch(eventValue, trialtype(:,1), 'exact');
            if ~isempty(indTrial)
                trialType = trialtype{indTrial,2};
            end
        end
        if insertEpoch
            if any(indtle == iEvent)
                trialType = 'Epoch';
            end
        end

        fprintf(fid, '%1.10f\t%s\t%s\t%s\t%1.10f\t%s\n', onset, duration, trialType, 'n/a', EEG.event(iEvent).latency-1, eventValue);
    end
    fclose(fid);

    % Write channel file information (channels.tsv)
    % Note: Consider using here electrodes_to_tsv.m
    fid = fopen( [ fileOut(1:end-7) 'channels.tsv' ], 'w');
    miscChannels = 0;
    
    if ~isempty(chanlocs)
        EEG.chanlocs = chanlocs;
    end
    
    if isempty(EEG.chanlocs)
        fprintf(fid, 'name\n');
        for iChan = 1:EEG.nbchan, printf(fid, 'E%d\n', iChan); end
    else
        fprintf(fid, 'name\ttype\tunits\n');

        for iChan = 1:EEG.nbchan
            if ~isfield(EEG.chanlocs, 'type') || isempty(EEG.chanlocs(iChan).type)
                type = 'n/a';
            else
                type = EEG.chanlocs(iChan).type;
            end
            if strcmpi(type, 'eeg')
                unit = 'microV';
            else
                unit = 'n/a';
                miscChannels = miscChannels+1;
            end

            fprintf(fid, '%s\t%s\t%s\n', EEG.chanlocs(iChan).labels, type, unit);
        end
    end
    fclose(fid);
    
    % Write electrode file information (electrodes.tsv)
    if ~isempty(EEG.chanlocs) && isfield(EEG.chanlocs, 'X') && ~isempty(EEG.chanlocs(1).X)
        fid = fopen( [ fileOut(1:end-7) 'electrodes.tsv' ], 'w');
        fprintf(fid, 'name\tx\ty\tz\n');

        for iChan = 1:EEG.nbchan
            if isempty(EEG.chanlocs(iChan).X)
                fprintf(fid, '%s\tn/a\tn/a\tn/a\n', EEG.chanlocs(iChan).labels );
            else
                fprintf(fid, '%s\t%2.2f\t%2.2f\t%2.2f\n', EEG.chanlocs(iChan).labels, EEG.chanlocs(iChan).X, EEG.chanlocs(iChan).Y, EEG.chanlocs(iChan).Z );
            end
        end
        fclose(fid);
        
        % Write coordinate file information (coordsystem.json)
        coordsystemStruct.EEGCoordinateUnits = 'mm';
        coordsystemStruct.EEGCoordinateSystem = 'ARS'; % X=Anterior Y=Right Z=Superior
        writejson( [ fileOut(1:end-7) 'coordsystem.json' ], coordsystemStruct);
    end

    % Write task information (eeg.json) Note: depends on channels
    tInfo.EEGChannelCount = EEG.nbchan-miscChannels;
    if miscChannels > 0
        tInfo.MiscChannelCount  = miscChannels;
    end
    if ~isfield(tInfo, 'EEGReference')
        tInfo.EEGReference    = EEG.ref;
    end
    if EEG.trials == 1
        tInfo.RecordingType = 'continuous';
    else
        tInfo.RecordingType = 'epoched';
        tInfo.EpochLength = EEG.pnts/EEG.srate;
    end
    tInfo.RecordingDuration = EEG.pnts/EEG.srate;
    tInfo.SamplingFrequency = EEG.srate;
%     jsonStr = jsonencode(tInfo);
%     fid = fopen( [fileOut(1:end-7) 'eeg.json' ], 'w');
%     fprintf(fid, '%s', jsonStr);
%     fclose(fid);

    tInfoFields = {...
        'TaskName' 'REQUIRED' '' '';
        'TaskDescription' 'RECOMMENDED' '' '';
        'Instructions' 'RECOMMENDED' 'char' '';
        'CogAtlasID' 'RECOMMENDED' 'char' '';
        'CogPOID' 'RECOMMENDED' 'char' '';
        'InstitutionName' 'RECOMMENDED' 'char' '';
        'InstitutionAddress' 'RECOMMENDED' 'char' '';
        'InstitutionalDepartmentName' ' RECOMMENDED' 'char' '';
        'DeviceSerialNumber' 'RECOMMENDED' 'char' '';
        'SamplingFrequency' 'REQUIRED' '' '';
        'EEGChannelCount' 'REQUIRED' '' '';
        'EOGChannelCount' 'REQUIRED' '' 0;
        'ECGChannelCount' 'REQUIRED' '' 0;
        'EMGChannelCount' 'REQUIRED' '' 0;
        'EEGReference' 'REQUIRED' 'char' 'Unknown';
        'PowerLineFrequency' 'REQUIRED' '' 0;
        'EEGGround' 'RECOMMENDED ' 'char' '';
        'MiscChannelCount' ' OPTIONAL' '' '';
        'TriggerChannelCount' 'RECOMMENDED' 'char' '';
        'EEGPlacementScheme' 'RECOMMENDED' 'char' '';
        'Manufacturer' 'RECOMMENDED' 'char' '';
        'ManufacturersModelName' 'OPTIONAL' 'char' '';
        'CapManufacturer' 'RECOMMENDED' 'char' 'Unknown';
        'CapManufacturersModelName' 'OPTIONAL' 'char' '';
        'HardwareFilters' 'OPTIONAL' 'char' '';
        'SoftwareFilters' 'REQUIRED' 'struct' 'n/a';
        'RecordingDuration' 'RECOMMENDED' '' 'n/a';
        'RecordingType' 'RECOMMENDED' 'char' '';
        'EpochLength' 'RECOMMENDED' '' 'n/a';
        'SoftwareVersions' 'RECOMMENDED' 'char' '';
        'SubjectArtefactDescription' 'OPTIONAL' 'char' '' };
    tInfo = checkfields(tInfo, tInfoFields, 'tInfo');

    jsonwrite([fileOut(1:end-7) 'eeg.json' ], tInfo,struct('indent','  '));

    % write channel information
%     cInfo.name.LongName = 'Channel name';
%     cInfo.name.Description = 'Channel name';
%     cInfo.type.LongName = 'Channel type';
%     cInfo.type.Description = 'Channel type';
%     cInfo.units.LongName = 'Channel unit';
%     cInfo.units.Description = 'Channel unit';
%     jsonStr = jsonencode(cInfo);
%     fid = fopen( [fileOut(1:end-7) 'channels.json' ], 'w');
%     fprintf(fid, '%s', jsonStr);
%     fclose(fid);

% check the fields for the structures
% -----------------------------------
function s = checkfields(s, f, structName)

    fields = fieldnames(s);
    diffFields = setdiff(fields, f(:,1)');
    if ~isempty(diffFields)
        error(sprintf('Invalid field name(s) %sfor structure %s', sprintf('%s ',diffFields{:}), structName));
    end
    for iRow = 1:size(f,1)
        if isempty(s) || ~isfield(s, f{iRow,1})
            if strcmpi(f{iRow,2}, 'required') % required or optional
                if ~iscell(f{iRow,4})
                    fprintf('Warning: "%s" set to %s\n', f{iRow,1}, num2str(f{iRow,4}));
                end
                s = setfield(s, {1}, f{iRow,1}, f{iRow,4});
            end
        elseif ~isempty(f{iRow,3}) && ~isa(s.(f{iRow,1}), f{iRow,3})
            error(sprintf('Parameter %s.%s must be a %s', structName, f{iRow,1}, f{iRow,3}));
        end
    end

% write JSON file
% ---------------
function writejson(fileName, matlabStruct)
    jsonStr = jsonencode(matlabStruct);

    fid = fopen(fileName, 'w');
    if fid == -1, error('Cannot write file - make sure you have writing permission'); end
    fprintf(fid, '%s', jsonStr);
    fclose(fid);

% write TSV file
% --------------
function writetsv(fileName, matlabArray)
    fid = fopen(fileName, 'w');
    if fid == -1, error('Cannot write file - make sure you have writing permission'); end
    for iRow=1:size(matlabArray,1)
        for iCol=1:size(matlabArray,2)
            if isempty(matlabArray{iRow,iCol})
                disp('Empty value detected, replacing by n/a');
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