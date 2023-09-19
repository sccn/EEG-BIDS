% STD_TOBIDS - From a STUDY rename files if needed, sort folders, and export metadata
%              following the BIDS specification
%
% FORMAT STUDY = std_tobids(STUDY,options)
%        options are: 'export_dir' followed by the path
%                     'keep_files' being 'yes' (default) or 'no'
%                     'update_study' being 'yes' or 'no'
%
% Author: Cyril Pernet - LIMO Team, University of Edinurgh
%         Arnaud Delorme, EEGLAB, SCCN, 2018

function STUDY = std_tobids(varargin)

%% options
if nargin == 1
    export_dir   = STUDY.filepath; % where to make the bids directory
    keep_files   = 'no';          % copy files to move and rename
    update_study = 'yes';          % return study with updated names and paths
else
    for in = 2:nargin
        if strcmpi(varargin{in},'export_dir') || strcmpi(varargin{in},'exportdir')
            export_dir = varargin{in+1};
        elseif strcmpi(varargin{in},'keep_files') || strcmpi(varargin{in},'keepfiles')
            keep_files =  varargin{in+1};
        elseif strcmpi(varargin{in},'update_study') || strcmpi(varargin{in},'updatestudy')
            update_study = varargin{in+1};
        end
    end
end

%% get subjects info
N = length(STUDY.subject);
if isempty(STUDY.task)
    STUDY.task = inputdlg2('input task name','task info missing'); % @Arno inputdlg2 fails
end
% task name with no space
task = lower(STUDY.task);
task(1) = upper(task(1));
task(find(isspace(STUDY.task))+1) = upper(task(find(isspace(STUDY.task))+1));
task(isspace(task)) = [];


% let's get the index of which files belong to the same subject
datasetindex = cell(N,length(STUDY.session));
if length(STUDY.session) > 1
    for subject =1:N
        file_index = 1;
        for files = 1:length(STUDY.datasetinfo)
            if strcmp(STUDY.subject{subject},STUDY.datasetinfo(files).subject)
                datasetindex{subject,file_index} = files;
                file_index = file_index+1;
            end
        end
    end
else
    for subject =1:N
        datasetindex{subject} = STUDY.subject{subject};
    end
end


% % check if subjects are all together or in different folders
% for files = 1:length(STUDY.datasetinfo)
%     paths{files} = STUDY.datasetinfo(files).filepath;
% end

% for each subject, move/rename and export metadata
for subject =1:N
    if strncmp(STUDY.subject{subject},'sub-',4)
        newname = STUDY.subject{subject};
    else
        newname = ['sub-' STUDY.subject{subject}];
    end
    
    % create sub- folder
    if strcmp(export_dir(length(export_dir)),filesep)
        export_dir = export_dir(1:end-1);
    end
    subj_dir             = [export_dir filesep newname filesep 'eeg'];
    subj_derivatives_dir = [export_dir filesep 'derivatives' filesep newname filesep 'eeg'];
    mkdir(subj_dir)
    
    % rename/move files
    for run = 1:length(STUDY.session)
        if ~isempty(datasetindex{subject,run})
            if ischar(datasetindex{subject,run})
                tmp = STUDY.datasetinfo(str2num(datasetindex{subject,run}));
            else
                tmp = STUDY.datasetinfo(datasetindex{subject,run});
            end
            [~,name,ext]=fileparts(tmp.filename);
            
            if strcmpi(keep_files,'no')
                movefile([tmp.filepath filesep tmp.filename],[subj_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_eeg' ext]);
                movefile([tmp.filepath filesep name '.fdt'], [subj_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_eeg.fdt']);
            elseif strcmpi(keep_files,'yes')
                copyfile([tmp.filepath filesep tmp.filename],[subj_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_eeg' ext]);
                copyfile([tmp.filepath filesep name '.fdt'], [subj_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_eeg.fdt']);
            end
            EEG              = pop_loadset([subj_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_eeg' ext]);
            EEG.setname      = [subj_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_eeg'];
            EEG.datfile      = [newname '_task-' task '_sess-1_run-' num2str(run) '_eeg.fdt'];
            % metadata
            SF(subject,run)  = EEG.srate;
            CC(subject,run)  = size(EEG.chanlocs,2);
            Ref{subject,run} = EEG.ref;
            
            % check derivatives and update .set
            if exist([tmp.filepath filesep STUDY.subject{subject} '.daterp'],'file') || ...
                    exist([tmp.filepath filesep STUDY.subject{subject} '.daterpim'],'file') || ...
                    exist([tmp.filepath filesep STUDY.subject{subject} '.datspec'],'file') || ...
                    exist([tmp.filepath filesep STUDY.subject{subject} '.dattimef'],'file') 
                name = STUDY.subject{subject}; % otherwise comes from STUDY.datasetinfo, depends if computed from study or not
            end
            
            if exist([tmp.filepath filesep name '.daterp'],'file')
                if ~exist(subj_derivatives_dir,'dir'); mkdir(subj_derivatives_dir); end
                if strcmpi(keep_files,'no')
                    movefile([tmp.filepath filesep name '.daterp'], [subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-erp_eeg.daterp']);                    
                elseif strcmpi(keep_files,'yes')
                    copyfile([tmp.filepath filesep name '.daterp'], [subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-erp_eeg.daterp']);
                end
                EEG.etc.datafiles.daterp = [subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-erp_eeg.daterp'];
            end
            
            if exist([tmp.filepath filesep name '.daterpim'],'file')
                if ~exist(subj_derivatives_dir,'dir'); mkdir(subj_derivatives_dir); end
                if strcmpi(keep_files,'no')
                    movefile([tmp.filepath filesep name '.daterpim'],[subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-erpimg_eeg.daterpim']);
                elseif strcmpi(keep_files,'yes')
                    copyfile([tmp.filepath filesep name '.daterpim'],[subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-erpimg_eeg.daterpim']);
                end
                EEG.etc.datafiles.daterpim = [subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-erpimg_eeg.daterpim'];
            end
            
            if exist([tmp.filepath filesep name '.datspec'],'file')
                if ~exist(subj_derivatives_dir,'dir'); mkdir(subj_derivatives_dir); end
                if strcmpi(keep_files,'no')
                    movefile([tmp.filepath filesep name '.datspec'],[subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-spectrum_eeg.datspec']);
                elseif strcmpi(keep_files,'yes')
                    copyfile([tmp.filepath filesep name '.datspec'],[subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-spectrum_eeg.datspec']);
                EEG.etc.datafiles.datspec = [subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-spectrum_eeg.datspec'];
                end
            end
            
            if exist([tmp.filepath filesep name '.dattimef'],'file')
                if ~exist(subj_derivatives_dir,'dir'); mkdir(subj_derivatives_dir); end
                if strcmpi(keep_files,'no')
                    movefile([tmp.filepath filesep name '.dattimef'],[subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-timefrequency_eeg.dattimef']);
                elseif strcmpi(keep_files,'yes')
                    copyfile([tmp.filepath filesep name '.dattimef'],[subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-timefrequency_eeg.dattimef']);
                EEG.etc.datafiles.dattimef = [subj_derivatives_dir filesep newname '_task-' task '_sess-1_run-' num2str(run) '_desc-timefrequency_eeg.dattimef'];
                end
            end
            
            % resave the .set with updated info
            pop_saveset(EEG,'savemode','resave');
            
            % export metadata 
            if run == 1
                electrodes_to_tsv(EEG);
            end
           channelloc_to_tsv(EEG);
           events_to_tsv(EEG);
        end
        
        if strcmpi(update_study,'yes')
            STUDY.datasetinfo(subject).filepath = subj_dir;
            STUDY.datasetinfo(subject).filename = [newname '_task-' task '_sess-1_run-' num2str(run) '_eeg' ext];
            STUDY.datasetinfo(subject).subject  = newname;
            STUDY.subject{subject}              = newname;
        end
    end
end

% update task name
if strcmpi(update_study,'yes')
    STUDY.task = task;
    STUDY = pop_savestudy(STUDY,'savemode','resave');
end
        
% finish of with root metadata
% ----------------------------
% make *_eeg.json
PLF = str2num(cell2mat(inputdlg('What was the Power Line Frequency?','BIDS spec requirement')));
if size(unique(Ref),1) > 1
    warning('difference referencing scheme found of this dataset')
    Ref = cell2mat(inputdlg('What was the reference?','BIDS spec requirement'));
end

json = struct('TaskName',task, ...
    'SamplingFrequency', mean(SF(:)), ...
    'EEGChannelCount', max(CC(:)), ...
    'EEGReference', unique(Ref), ...
    'PowerLineFrequency', PLF, ...
    'SoftwareFilters', ' ');
jsonwrite([export_dir filesep task '_eeg.json'],json,struct('indent','  '))

% make a participants table and save 
age = zeros(N,1);
sex = repmat(' ',[N 1]); 
t = table(STUDY.subject',age,sex,'VariableNames',{'participant_id','age','sex'});
writetable(t,[export_dir filesep 'Participants.tsv'],'FileType','text','Delimiter','\t');
warndlg('Job done, but metadata created need editing','BIDS spec','modal')

% From an EEG variable (i.e. EEG=pop_loadset(*.set), export the channel
% location as tsv file following the BIDS specification
%
% FORMAT channelloc_to_tvs(EEG)
%
% Author: Cyril Pernet - LIMO Team, University of Edinurgh

function channelloc_to_tsv(EEG)

% list of labels for which we know it's not an EEG channel
known_labels = {'EXG','TRIG','ECG','EOG','VEOG','HEOG','EMG','MISC'};

% channel.tsv
for electrode = 1:size(EEG.chanlocs,2)
    ename{electrode}     = EEG.chanlocs(electrode).labels; 
    if contains(EEG.chanlocs(electrode).labels,known_labels)
        type{electrode} = EEG.chanlocs(electrode).labels;
        if contains(EEG.chanlocs(electrode).labels,'EOG')
            unit{electrode} = [num2str(char(181)) 'V'];
        elseif contains(EEG.chanlocs(electrode).labels,'ECG')
            unit{electrode} = 'mV';
        else
            unit{electrode} = ' ';
        end
    else
        type{electrode} = 'EEG';
        unit{electrode} = [num2str(char(181)) 'V']; % char(181) is mu in ASCII
    end
    sampling_frequency(electrode)  = EEG.srate;
    reference{electrode} = EEG.ref;
end

t = table(ename',type',unit',sampling_frequency',reference','VariableNames',{'name','type','units','sampling_reference','reference'});
channels_tsv_name = [EEG.filepath filesep EEG.filename(1:end-4) '_channels.tsv'];
writetable(t,channels_tsv_name,'FileType','text','Delimiter','\t');

% electrodes_to_tsv   - From an EEG structure export the EEG.channel
%                       locations as tsv file and initiate the json file  
%                       following the BIDS specification
%
% Usage: 
%             >>  electrodes_to_tsv(EEG)
%             >>  electrodes_to_tsv(EEG,material,{'Ag/AgCl', 'Ag/AgCl', 'Ag/AgCl',...})
%
% Inputs :
%    EEG              -  EEG structure
% 
% Optional inputs:
%   'material'        - Cell array with dimensions of number of channels in
%                       EEG set by one. Material of the electrode, e.g., Tin,
%                        Ag/AgCl, Gold. Default: None
%   'impedance'       - Array or cell array with dimensions of number of channels
%                       in EEG set by one. Impedance for each electrode in
%                       kOhm. Default: None
%   'coordsystem'     - String. Refers to the coordinate system in which the 
%                       EEG electrode positions are to be interpreted 
%                       (EEGCoordinateSystem in BIDS specification). Default: 'RAS'
%   'coordunits'      - String. Units in which the coordinates that are listed
%                       in the field EEGCoordinateSystem are represented 
%                       (e.g., "mm", "cm").(EEGCoordinateUnits in BIDS specification).
%                       Default: 'mm'
%  'coorsystdescript' - String.Free-form text description of the coordinate . 
%                       system. May also include a link to a documentation page
%                       or paper describing the system in greater detail.
%                       Default: 'Right-Anterior-Superior corresponding to X, Y and Z'
%
% Outputs: None
%   
% Authors: Cyril Pernet - LIMO Team, University of Edinburgh
%
function electrodes_to_tsv(EEG,varargin)

% FORMAT electrodes_to_tsv(EEG,varargin)
% electrode.tsv

try
    options = varargin;
    if ~isempty( varargin )
        if ~ischar(options{1}), options = options{1}; end
        for i = 1:2:numel(options)
            g.(options{i}) = options{i+1};
        end
    else, g= []; end
catch
    disp('electrodes_to_tsv() error: calling convention {''key'', value, ... } error'); return;
end
SystDefault = 'Right-Anterior-Superior corresponding to X, Y and Z';

try g.material;              catch, g.material         = '';           end % material
try g.impedance;             catch, g.impedance        = '';           end % impedance
try g.coordsystem;           catch, g.coordsystem      = 'RAS';        end % EEGCoordinateSystem
try g.coordunits;            catch, g.coordunits       = 'mm';         end % EEGCoordinateUnits
try g.coorsystdescript;      catch, g.coorsystdescript = SystDefault;  end % EEGCoordinateSystemDescription

ename = cell(1,size(EEG.chanlocs,2));  ename(:) = {'n/a'};
x = ename; y = ename; z = ename; type = ename; 
for electrode = 1:size(EEG.chanlocs,2)
    if ~isempty(EEG.chanlocs(electrode).labels),ename{electrode} = EEG.chanlocs(electrode).labels;  end
    if ~isempty(EEG.chanlocs(electrode).X),     x{electrode}     = EEG.chanlocs(electrode).X;       end
    if ~isempty(EEG.chanlocs(electrode).Y),     y{electrode}     = EEG.chanlocs(electrode).Y;       end
    if ~isempty(EEG.chanlocs(electrode).Z),     z{electrode}     = EEG.chanlocs(electrode).Z;       end
    if ~isempty(EEG.chanlocs(electrode).type),  type{electrode}  = EEG.chanlocs(electrode).type;    end
end

% Updating with optional fields
optfields = {'material', 'impedance'};
string1   = 't = table(ename'',x'',y'',z'',type''';
for i=1:length(optfields)
    if ~isempty(g.(optfields{i})) && length(g.(optfields{i})) == length(x)
        string1 = [string1 ',g.' optfields{i}];
    end
end

string2    = ',''VariableNames'',{''name'',''x'',''y'',''z'',''type''';
for i=1:length(optfields)
    if ~isempty(g.(optfields{i})) && length(g.(optfields{i})) == length(x)
        string2 = [string2 ',''' optfields{i} ''''];
    end
end

% Creating table and writing files
evalstring = [string1 string2 '});'];
eval(evalstring); % t = table(ename',x',y',z',type','VariableNames',{'name','x','y','z','type'});

electrodes_tsv_name = [EEG.filepath filesep EEG.filename(1:strfind(EEG.filename,'run-')-1) 'electrodes.tsv'];
writetable(t,electrodes_tsv_name,'FileType','text','Delimiter','\t');

% coordsystem.json
json = struct('EEGCoordinateSystem',g.coordsystem, 'EEGCoordinateUnits',g.coordunits, 'EEGCoordinateSystemDescription',g.coorsystdescript);
jsonwrite([EEG.filepath filesep EEG.filename(1:strfind(EEG.filename,'run-')-1) 'electrodes.json'],json,struct('indent','  '));



