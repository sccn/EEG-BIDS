% BIDS_REEXPORT - re-export BIDS dataset (dataset which was imported in
%                 EEGLAB)
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
%                generatedBy.Description = 'A validated EEG pipeline';
%                generatedBy.Version = '0.1';
%                generatedBy.CodeURL = 'https://github.com/sccn/NEMAR-pipeline/blob/main/eeg_nemar_preprocess.m';
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
    'checkderivative' 'string'  {}    '';
    'targetdir'    'string'  {}    fullfile(pwd, 'bidsexport');;
    }, 'bids_reexport');
if isstr(opt), error(opt); end

% export the data
% ---------------
if isempty(opt.generatedBy)
    opt.generatedBy(1).Name = 'NEMAR-pipeline';
    opt.generatedBy.Description = 'A validated EEG pipeline';
    opt.generatedBy.Version = '0.1';
    opt.generatedBy.CodeURL = 'https://github.com/sccn/NEMAR-pipeline/blob/main/eeg_nemar_preprocess.m';
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

BIDS.gInfo.generatedBy = opt.generatedBy;
BIDS.gInfo.sourceDatasets.DOI = BIDS.gInfo.DatasetDOI;
BIDS.gInfo = rmfield(BIDS.gInfo, 'DatasetDOI');
BIDS.gInfo.CHANGES = [ BIDS.gInfo.CHANGES 10 10 'Processed using the NEMAR pipeline (see README file)' ];
BIDS.gInfo.README = [ BIDS.gInfo.README 10 10 ...
    'The original dataset was processed using the NEMAR EEG processing ' 10 ... 
    'pipeline (see nemar.org). This is the derivative EEG dataset where' 10 ...
    'the data has been automatically cleaned.' ];

options = { 'targetdir', opt.targetdir, ...
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
    'forcerun', 'on' };

if BIDS.scannedElectrodes
    options = [ options { 'elecexport' 'on' } ];
end

data.file = { fullfile(ALLEEG1(1).filepath, ALLEEG1(1).filename) ...
              fullfile(ALLEEG1(2).filepath, ALLEEG1(2).filename) };
data.run     = [ ALLEEG1.run ];
data.session = [ ALLEEG1.session ];
data.task    = { ALLEEG1.task };
bids_export(data, options{:});

% import data
% -------------
[~, ALLEEG2] = pop_importbids(opt.targetdir, 'subjects', 1);
rmdir(fullfile(opt.targetdir, 'derivatives'), 's');

fprintf('************************\n');
fprintf('COMPARING first dataset\n')
fprintf('************************\n');
eeg_compare(ALLEEG1(1), ALLEEG2(1));

% compare BIDS datasets
if ~isempty(opt.checkderivative)
    fprintf('Comparing BIDS folders %s vs %s\n', opt.checkderivative, opt.targetdir)
    bids_compare(opt.checkderivative, opt.targetdir, false);
end