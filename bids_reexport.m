% BIDS_REEXPORT - re-export BIDS dataset (dataset which was imported in
%                 EEGLAB) as a BIDS derivative
% Usage:
%   bids_reexport(ALLEEG, key, val);
%
% Input:
%  ALLEEG       - vector of loaded EEG datasets
%
% Optional inputs:
% 'GeneratedBy' - [struct] structure indicating how the data was generated.
%                For example:
%                GeneratedBy.Name = 'NEMAR-pipeline';
%                GeneratedBy.Description = 'A validated EEG pipeline for preprocessing and decomposition of EEG datasets';
%                GeneratedBy.Version = '1.0';
%                GeneratedBy.CodeURL = 'https://github.com/sccn/NEMAR-pipeline/blob/main/eeg_nemar_preprocess.m';
%                GeneratedBy.desc = 'nemar'; % optional description for file naming
%
% 'SourceDatasets' - [struct] structure indicating the source dataset
%                For example:
%                GeneratedBy.URL = 'https://openneuro.org/datasets/ds00xxxx';
%                GeneratedBy.DOI = 'doi:10.18112/openneuro.ds00xxxx';
% 
% 'derivative' - ['on'|'off'] The re-exported dataset may be a derivative
%                dataset ('on') which is the default. Alternatively, you
%                could be working on re-issuing a new snapshot for an
%                existing raw dataset ('off'). This affect the
%                'DatasetType' and 'SourceDataset' field.
%
% 'checkagainstparent' - [string] provide a folder as a string containing 
%                the original BIDS repository and check that the folder
%                names are identical. If not, issue an error.
%
% 'targetdir' - [string] target directory. Default is 'bidsexport' in the
%               current folder. This can be the same as the original BIDS
%               folder.
%
% 'targetdirderiv' - [string] sub-folder for derivative. For example
%               'derivative/eegbids'. Default is empty unless the target
%               folder contains a BIDS dataset that is not a derivative
%               dataset. In that case it is set to 'derivative/eegbids'.
%
% Author: Arnaud Delorme, 2023

% Copyright (C) 2023 Arnaud Delorme
%
% This file is part of EEGLAB, see http://www.eeglab.org
% for the documentation and details.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

function bids_reexport(ALLEEG1, varargin)

if ~isfield(ALLEEG1, 'task') || ~isfield(ALLEEG1, 'BIDS')
    error('Task or BIDS field not found in array of EEG');
end

opt = finputcheck(varargin, { ...
    'generatedBy'     'struct'  {}    struct([]); ...
    'GeneratedBy'     'struct'  {}    struct([]); ...
    'SourceDatasets'  'struct'  {}    struct([]); ...
    'derivative'      'string'  { 'on' 'off' }    'on'; ...
    'checkagainstparent' 'string'  {}    ''; ...
    'checkderivative' 'string'  {}    ''; ...
    'targetdir'       'string'  {}    fullfile(pwd, 'bidsexport'); ...
    'targetdirderiv'  'string'  {}    ''; ...
    }, 'bids_reexport');
if isstr(opt), error(opt); end

if ~isempty(opt.checkderivative)
    opt.checkagainstparent = opt.checkderivative;
end
if ~isempty(opt.generatedBy)
    opt.GeneratedBy = opt.generatedBy;
end

% Set up derivative directory if needed
% This is done when the target directory contains the original dataset
derivativeDir = fullfile(opt.targetdir, opt.targetdirderiv);
if exist(fullfile(opt.targetdir, 'dataset_description.json'))
    jsonText = fileread(fullfile(opt.targetdir, 'dataset_description.json'));
    jsonData = jsondecode(jsonText);
    if ~isfield(jsonData, 'DatasetType') || ~isequal(jsonData.DatasetType, 'derivative')
        derivativeDir = fullfile(opt.targetdir, 'derivatives', 'eegbids');
    end
end

if ~exist(derivativeDir, 'dir')
    mkdir(derivativeDir);
end

% export the data
% ---------------
if isempty(opt.GeneratedBy)
    opt.GeneratedBy(1).Name = 'EEGLAB';
    opt.GeneratedBy(1).Description = 'EEGLAB BIDS derivative processing pipeline';
    opt.GeneratedBy(1).Version = eeg_getversion;
    opt.GeneratedBy(1).CodeURL = 'https://github.com/sccn/eeglab';
end

tasks = unique({ ALLEEG1.task });
if length(tasks) == 1
    tasks = tasks{1};
else
    tasks = 'Multiple';
end

BIDS = ALLEEG1(1).BIDS;
if strcmpi(opt.derivative, 'on')
    BIDS.gInfo.DatasetType = 'derivative';
end
if ~isfield(BIDS.gInfo, 'README')
    BIDS.gInfo.README = '';
end
if ~isfield(BIDS.gInfo, 'CHANGES')
    BIDS.gInfo.CHANGES = '';
end

% Set up derivative dataset description while preserving existing values
if ~isfield(BIDS.gInfo, 'Name')
    if strcmpi(opt.derivative, 'on')
        BIDS.gInfo.Name = 'EEGLAB derivative';
    end
end
if ~isfield(BIDS.gInfo, 'BIDSVersion')
    BIDS.gInfo.BIDSVersion = '1.8.0';
end
if ~isfield(BIDS.gInfo, 'PipelineDescription')
    BIDS.gInfo.PipelineDescription.Name = opt.GeneratedBy(1).Name;
    BIDS.gInfo.PipelineDescription.Version = opt.GeneratedBy(1).Version;
    BIDS.gInfo.PipelineDescription.Description = opt.GeneratedBy(1).Description;
end
if ~isfield(BIDS.gInfo, 'GeneratedBy')
    BIDS.gInfo.GeneratedBy = opt.GeneratedBy;
end

% Handle source dataset tracking
if strcmpi(opt.derivative, 'on')
    if ~isempty(opt.SourceDatasets)
        BIDS.gInfo.SourceDatasets = opt.SourceDatasets;
    end
    if isfield(BIDS.gInfo, 'DatasetDOI')
        if ~isfield(BIDS.gInfo, 'SourceDatasets')
            BIDS.gInfo.SourceDatasets.DOI = BIDS.gInfo.DatasetDOI;
        end
        BIDS.gInfo = rmfield(BIDS.gInfo, 'DatasetDOI');
    end
end

% Write derivative dataset description
jsonwrite(fullfile(derivativeDir, 'dataset_description.json'), BIDS.gInfo, struct('indent','  '));

% Group files by subject
uniqueSubjects = unique({ALLEEG1.subject});
for i = 1:length(uniqueSubjects)
    % Find all files for this subject
    subjectIndices = find(strcmp({ALLEEG1.subject}, uniqueSubjects{i}));
    
    % Initialize arrays for this subject's files
    data(i).file = cell(1, length(subjectIndices));
    data(i).task = cell(1, length(subjectIndices));
    data(i).run = zeros(1, length(subjectIndices));
    data(i).session = zeros(1, length(subjectIndices));
    
    % Fill in data for each file
    for j = 1:length(subjectIndices)
        idx = subjectIndices(j);
        data(i).file{j} = fullfile(ALLEEG1(idx).filepath, ALLEEG1(idx).filename);
        data(i).task{j} = ALLEEG1(idx).task;
        data(i).run(j) = ALLEEG1(idx).run;
        data(i).session(j) = ALLEEG1(idx).session;
    end
end

% Reconstruct pInfo by aggregating data from all subjects while preserving order
% First, find the first subject that has pInfo to establish initial field order
allFields = {};
for i = 1:length(ALLEEG1)
    if isfield(ALLEEG1(i).BIDS, 'pInfo') && ~isempty(ALLEEG1(i).BIDS.pInfo)
        allFields = ALLEEG1(i).BIDS.pInfo(1,:);
        break;
    end
end

% Then add any additional fields from other subjects while preserving order
for i = 1:length(ALLEEG1)
    if isfield(ALLEEG1(i).BIDS, 'pInfo') && ~isempty(ALLEEG1(i).BIDS.pInfo)
        newFields = ALLEEG1(i).BIDS.pInfo(1,:);
        for j = 1:length(newFields)
            if ~ismember(newFields{j}, allFields)
                allFields{end+1} = newFields{j};
            end
        end
    end
end

% Create new pInfo cell array with headers
if ~isempty(allFields)
    BIDS.pInfo = cell(length(uniqueSubjects) + 1, length(allFields));
    BIDS.pInfo(1,:) = allFields;
    
    % Fill in values for each subject
    for i = 1:length(uniqueSubjects)
        subjectIdx = find(strcmp({ALLEEG1.subject}, uniqueSubjects{i}), 1);
        if isfield(ALLEEG1(subjectIdx).BIDS, 'pInfo') && ~isempty(ALLEEG1(subjectIdx).BIDS.pInfo)
            for j = 1:length(allFields)
                fieldIdx = find(strcmp(allFields{j}, ALLEEG1(subjectIdx).BIDS.pInfo(1,:)));
                if ~isempty(fieldIdx)
                    BIDS.pInfo(i+1,j) = ALLEEG1(subjectIdx).BIDS.pInfo(2,fieldIdx);
                end
            end
        end
    end
end

% Compare with original data if available
if ~isempty(opt.checkagainstparent)
    try
        % Import original BIDS dataset
        [~, ALLEEG2] = pop_importbids(opt.checkagainstparent, 'subjects', 1, 'bidschanloc','on','bidsevent', 'on');
        
        % Compare first dataset to determine changes
        ALLEEG1(1) = eeg_compare_bids(ALLEEG1(1), ALLEEG2(1));
        
        % Only add desc if changes were detected
        if ALLEEG1(1).etc.compare.data_changed || ...
           ALLEEG1(1).etc.compare.events_changed || ...
           ALLEEG1(1).etc.compare.chanlocs_changed
            
            % Build desc based on what changed using camelCase
            changes = {};
            if ALLEEG1(1).etc.compare.data_changed
                changes{end+1} = 'data';
            end
            if ALLEEG1(1).etc.compare.events_changed
                changes{end+1} = 'events';
            end
            if ALLEEG1(1).etc.compare.chanlocs_changed
                changes{end+1} = 'electrodes';
            end
            
            % Convert changes to camelCase and combine
            if ~isempty(changes)
                % Capitalize first letter of each word except first
                for i = 1:length(changes)
                    if i > 1
                        changes{i} = [upper(changes{i}(1)) changes{i}(2:end)];
                    end
                end
                desc = strjoin(changes, '');
                
                % Set desc in GeneratedBy
                if isfield(opt.GeneratedBy, 'desc')
                    desc = [opt.GeneratedBy.desc desc];
                end
                opt.GeneratedBy.desc = desc;
            end
        end
    catch
        warning('Could not load or compare with original dataset.');
    end
end

% Check to see if BIDS has all the needed fileds, otherwise borrow from ALLEEG2
required_fields = {'gInfo', 'pInfo', 'pInfoDesc', 'tInfo', 'eInfo', 'scannedElectrodes', 'eInfoDesc'};
for i = 1:length(required_fields)
    if ~isfield(BIDS, required_fields{i}) || isempty(BIDS.(required_fields{i}))
        if exist('ALLEEG2', 'var') && isfield(ALLEEG2(1).BIDS, required_fields{i})
            BIDS.(required_fields{i}) = ALLEEG2(1).BIDS.(required_fields{i});
            warning('bids_reexport, the BIDS structure is missing required field %s, borrowing from original dataset', required_fields{i});
        else
            warning('bids_reexport, the BIDS structure is missing required field %s, the program may likely crash', required_fields{i});
        end
    end
end

if isempty(opt.GeneratedBy)
    BIDS.gInfo.GeneratedBy = BIDS.gInfo.GeneratedBy;
else
    BIDS.gInfo.GeneratedBy = opt.GeneratedBy;
end
if isempty(BIDS.pInfoDesc), BIDS.pInfoDesc = struct([]); end

% Set up export options
options = { 'targetdir', derivativeDir, ...
    'taskName', tasks,...
    'gInfo', BIDS.gInfo, ...
    'pInfo', BIDS.pInfo, ...
    'pInfoDesc', BIDS.pInfoDesc, ...
    'README', BIDS.gInfo.README, ...
    'CHANGES', BIDS.gInfo.CHANGES, ...
    'renametype', {}, ...
    'tInfo', BIDS.tInfo, ...
    'eInfo', BIDS.eInfo };

if isfield(BIDS, 'scannedElectrodes') && BIDS.scannedElectrodes
    options = [ options { 'elecexport' 'on' } ];
end

% Export the data
bids_export(data, options{:});

% Compare with original if requested
if ~isempty(opt.checkagainstparent)
    fprintf('Comparing BIDS folders %s vs %s\n', opt.checkagainstparent, derivativeDir);
    bids_compare(opt.checkagainstparent, derivativeDir, false);
end
