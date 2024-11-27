% BIDS_REEXPORT - re-export BIDS dataset (dataset which was imported in
%                 EEGLAB) as a BIDS derivative
% Usage:
%   bids_reexport(ALLEEG, key, val);
%
% Input:
%  ALLEEG       - vector of loaded EEG datasets
%
% Optional inputs:
% 'generatedBy' - [struct] structure indicating how the data was generated.
%                For example:
%                generatedBy.Name = 'NEMAR-pipeline';
%                generatedBy.Description = 'A validated EEG pipeline for preprocessing and decomposition of EEG datasets';
%                generatedBy.Version = '1.0';
%                generatedBy.CodeURL = 'https://github.com/sccn/NEMAR-pipeline/blob/main/eeg_nemar_preprocess.m';
%                generatedBy.desc = 'nemar'; % optional description for file naming
%
%  'checkderivative' - [string] provide a folder as a string containing 
%                the original BIDS repository and check that the folder
%                names are identical. If not, issue an error.
%
%  'targetdir' - [string] target directory. Default is 'bidsexport' in the
%                current folder.
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
    error('Task or BIDS field not found in array of EEG')
end

opt = finputcheck(varargin, { ...
    'generatedBy'     'struct'  {}    struct([]); ...
    'checkderivative' 'string'  {}    ''; ...
    'targetdir'       'string'  {}    fullfile(pwd, 'bidsexport'); ...
    }, 'bids_reexport');
if isstr(opt), error(opt); end

% Set up derivative directory
derivativeDir = fullfile(opt.targetdir, 'derivatives', 'eeglab');
if ~exist(derivativeDir, 'dir')
    mkdir(derivativeDir);
end

% export the data
% ---------------
if isempty(opt.generatedBy)
    opt.generatedBy(1).Name = 'EEGLAB';
    opt.generatedBy(1).Description = 'EEGLAB BIDS derivative processing pipeline';
    opt.generatedBy(1).Version = eeg_getversion;
    opt.generatedBy(1).CodeURL = 'https://github.com/sccn/eeglab';
end

tasks = unique({ ALLEEG1.task });
if length(tasks) == 1
    tasks = tasks{1};
else
    tasks = 'Multiple';
end

BIDS = ALLEEG1(1).BIDS;
if ~isfield(BIDS.gInfo, 'README')
    BIDS.gInfo.README = '';
end
if ~isfield(BIDS.gInfo, 'CHANGES')
    BIDS.gInfo.CHANGES = '';
end

% Set up derivative dataset description while preserving existing values
if ~isfield(BIDS.gInfo, 'Name')
    BIDS.gInfo.Name = 'EEGLAB derivatives';
end
if ~isfield(BIDS.gInfo, 'BIDSVersion')
    BIDS.gInfo.BIDSVersion = '1.8.0';
end
if ~isfield(BIDS.gInfo, 'PipelineDescription')
    BIDS.gInfo.PipelineDescription.Name = opt.generatedBy(1).Name;
    BIDS.gInfo.PipelineDescription.Version = opt.generatedBy(1).Version;
    BIDS.gInfo.PipelineDescription.Description = opt.generatedBy(1).Description;
end
if ~isfield(BIDS.gInfo, 'GeneratedBy')
    BIDS.gInfo.GeneratedBy = opt.generatedBy;
end

% Handle source dataset tracking
if isfield(BIDS.gInfo, 'DatasetDOI')
    if ~isfield(BIDS.gInfo, 'SourceDatasets')
        BIDS.gInfo.SourceDatasets.DOI = BIDS.gInfo.DatasetDOI;
    end
    BIDS.gInfo = rmfield(BIDS.gInfo, 'DatasetDOI');
end

% Write derivative dataset description
jsonwrite(fullfile(derivativeDir, 'dataset_description.json'), BIDS.gInfo, struct('indent','  '));

% Prepare data structure for export
data.file = cell(1, length(ALLEEG1));
for i = 1:length(ALLEEG1)
    data.file{i} = fullfile(ALLEEG1(i).filepath, ALLEEG1(i).filename);
end
data.run     = [ ALLEEG1.run ];
data.session = [ ALLEEG1.session ];
data.task    = { ALLEEG1.task };

% Compare with original data if available
if ~isempty(opt.checkderivative)
    try
        % Import original BIDS dataset
        [~, ALLEEG2] = pop_importbids(opt.checkderivative, 'subjects', 1, 'bidschanloc','on','bidsevent', 'on');
        
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
                
                % Set desc in generatedBy
                if isfield(opt.generatedBy, 'desc')
                    desc = [opt.generatedBy.desc desc];
                end
                opt.generatedBy.desc = desc;
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
            warning('BIDS structure is missing required field %s, borrowing from original dataset', required_fields{i});
        else
            warning('BIDS structure is missing required field %s, the program may likely crash', required_fields{i});
        end
    end
end

BIDS.gInfo.GeneratedBy = struct2cell(BIDS.gInfo.GeneratedBy);

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
    'eInfo', BIDS.eInfo, ...
    'forcesession', 'on', ...
    'forcerun', 'on', ...
    'generatedBy', opt.generatedBy };

if BIDS.scannedElectrodes
    options = [ options { 'elecexport' 'on' } ];
end

% Export the data
bids_export(data, options{:});

% Compare with original if requested
if ~isempty(opt.checkderivative)
    fprintf('Comparing BIDS folders %s vs %s\n', opt.checkderivative, derivativeDir);
    bids_compare(opt.checkderivative, derivativeDir, false);
end
