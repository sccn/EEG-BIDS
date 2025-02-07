% BIDS_EXPORTER - BIDS export wizard, from raw EEG to BIDS
%
% Usage:  
%  >> bids_exporter; % create new study interactively
%
% Authors: Dung Truong and Arnaud Delorme, SCCN, INC, UCSD, July 22, 2024

% Copyright (C) Arnaud Delorme, 2024
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

function bids_exporter(varargin)
    if ~exist('pop_studywizard')
        error('This tool is not available in this EEGLAB version. Use the latest EEGLAB version.')
    end
    
    if nargin == 0
        str = [  'This tool allows you to select binary EEG files' 10 ...
            'and format them to a BIDS dataset. For more information' 10 ...
            'see the online help at https://eegbids.org'];

        [~, ~, err, ~] = inputgui('geometry', { 1 1 }, 'geomvert', [1 3], 'uilist', ...
            { { 'style' 'text' 'string' 'Welcome to the EEG-BIDS exporter tool!' 'fontweight' 'bold' }  { 'style' 'text' 'string' str } }, 'okbut', 'continue');

        if isempty(err), return; end % not ideal but no better solution now
        [STUDY, ALLEEG] = pop_studywizard();
        if isempty(ALLEEG), return; end

        % task Name
        taskName = '';
        if ~isfield(ALLEEG, 'task') || isempty(ALLEEG(1).task)
            res = inputgui('geom', { {2 1 [0 0] [1 1]} {2 1 [1 0] [1 1]} }, 'uilist', ...
                { { 'style' 'text' 'string' 'Enter the task name' } ...
                { 'style' 'edit' 'string' '' } });
            if ~isempty(res) && ~isempty(res{1})
                taskName = res{1};
            else
                errordlg('Operation aborted as a task name is required')
            end
        end
        
        STUDY.task = taskName;
        pop_exportbids(STUDY, ALLEEG);
    elseif nargin == 1 && exist(varargin{1}, 'file')
        pop_runscript(varargin{1});
    end
