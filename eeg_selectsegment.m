% EEG_SELECTSEGMENT - Select a data segment 
%
% Usage:
%    OUTEEG = eeg_selectsegment(INEEG, 'key', val)
%
% Input:
%   INEEG         - input EEG dataset structure
%
% Optional inputs:
% 'timeoffset' - [2x float array] beginning and end in seconds. For example 
%                'timeoffset' of [0 1800] selects the first 30 minutes of a file.
%                Default 'timeoffset' is [0 0]. 
% 'eventype'   - [cell array of string or integer array] select events of a
%                given type for beginning and end of segment. { 'beg' 'end' } 
%                will select the first 'beg' event for the beginning of the
%                segment and the first 'end' event for the end of the
%                segment (unless 'eventindex' is specified below). Event
%                types may also be numerical (e.g. [1 2]).
% 'eventindex' - [integer array of size 2] event indices for the
%                beginning and end of the segment (see example below).
%
% Outputs:
%   OUTEEG     - EEG dataset structure with the extracted segment
%
% Example:
%   % select the first 30 minutes of an EEG dataset
%   EEG = eeg_selectsegment(EEG, 'timeoffset', [0 1800]);
%
%   % select the segment between the first 'beg' and 'end' event types
%   EEG = eeg_selectsegment(EEG, 'eventype', { 'beg' 'end'});
% 
%   % select the segment between the second 'beg' and 'end' event types
%   EEG = eeg_selectsegment(EEG, 'eventype', { 'beg' 'end'}, 'eventindex', [2 2]);
%
%   % select the segment one second after the 'beg' and 'end' event types
%   EEG = eeg_selectsegment(EEG, 'eventype', { 'beg' 'end'}, 'timeoffset', [1 1]);
%
%   % select the segment from the first 'beg' to 1800 seconds after this event
%   EEG = eeg_selectsegment(EEG, 'eventype', { 'beg' 'beg'}, 'timeoffset', [0 1800]);
%
% Author: Arnaud Delorme, UCSD, 2023
% 
% see also: EEGLAB

% Copyright (C) 2023 Arnaud Delorme, UCSD
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

function EEG = eeg_selectsegment(EEG, varargin)

if nargin < 2
    help eeg_selectsegment;
    return
end

opt = finputcheck(varargin, { 'eventtype'  {'cell' 'integer'}  {{} {}}    [];
                              'eventindex' 'integer'             {}    [];
                              'verbose'    'string'              {'on' 'off'}    'on';
                              'timeoffset' 'real'                {}    [0 0]}, 'eeg_selectsegment');
if ischar(opt), error(opt); end

if isempty(opt.timeoffset)
    opt.timeoffset = [0 0];
end
if length(opt.timeoffset) ~= 2
    error('There must be exactly 2 time offsets, one for the beginning and one for the end')
end

if isequal(opt.timeoffset, [0 0]) && isempty(opt.eventtype) && isempty(opt.eventindex)
    % nothing to do
    return;
end
if strcmpi(opt.verbose, 'on')
    fprintf('xxx Processing file %s\n', EEG.comments);
end

% select event types
% ------------------
if ~isempty(opt.eventtype)
    if length(opt.eventtype) < 2
        error('You need at least 2 event types, one for the onset and one for the offset');
    end
    tmpevents = EEG.event;
    if iscell(opt.eventtype)
        indEvents1 = strmatch(opt.eventtype{1}, {tmpevents.type}, 'exact' );
        indEvents2 = strmatch(opt.eventtype{2}, {tmpevents.type}, 'exact' );
        if strcmpi(opt.verbose, 'on')
            fprintf('xxx %d events of type "%s" found\n', length(indEvents1), opt.eventtype{1});
            fprintf('xxx %d events of type "%s" found\n', length(indEvents2), opt.eventtype{2});
        end
    else
        indEvents1 = find([tmpevents.type] == opt.eventtype(1));
        indEvents2 = find([tmpevents.type] == opt.eventtype(2));
    end
    tmpevents1 = EEG.event(indEvents1);
    tmpevents2 = EEG.event(indEvents2);
else
    tmpevents1 = EEG.event;
    tmpevents2 = EEG.event;
end

% select event indices
% --------------------
if ~isempty(opt.eventindex)
    if length(opt.eventindex) ~= 2
        error('There must be exactly 2 event indices, one for the beginning and one for the end')
    end
    if ~isnan(opt.eventindex(1))
         if strcmpi(opt.verbose, 'on')
             fprintf('xxx Selecting beginning event: the %d type "%s" event at latency %1.0f plus %1.0f seconds\n', opt.eventindex(1), opt.eventtype{1}, tmpevents1(opt.eventindex(1)).latency/EEG.srate, opt.timeoffset(1));
         end
         latency1 = tmpevents1(opt.eventindex(1)).latency + opt.timeoffset(1)*EEG.srate;
    else latency1 = opt.timeoffset(1)*EEG.srate;
    end
    if ~isnan(opt.eventindex(2))
         if strcmpi(opt.verbose, 'on')
             fprintf('xxx Selecting beginning event: the %d type "%s" event at latency %1.0f plus %1.0f seconds\n', opt.eventindex(2), opt.eventtype{2}, tmpevents1(opt.eventindex(2)).latency/EEG.srate, opt.timeoffset(2));
         end
         latency2 = tmpevents2(opt.eventindex(2)).latency + opt.timeoffset(2)*EEG.srate;
    else latency2 = opt.timeoffset(2)*EEG.srate;
    end
else
    latency1 = opt.timeoffset(1)*EEG.srate;
    latency2 = opt.timeoffset(2)*EEG.srate;
end

EEG = pop_select(EEG, 'point', [latency1 latency2]);





