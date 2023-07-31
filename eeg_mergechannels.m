% EEG_MERGECHANNELS - merge the channels of two EEG structure based on 
%                     common event types latencies. This is useful for 
%                     aligning the data from 2 subjects recorded
%                     simultaneously or from 2 modalities in the same
%                     subject.
% Usage:
%         >> OUTEEG = eeg_mergechannels(EEG1, EEG2, varargin);
% Inputs:
%       EEG1 - first EEGLAB dataset
%       EEG2 - second EEGLAB dataset
%
% Output:
%  OUTEEG  - output EEG structure with the two datasets merged
%
% Example:
%  EEG1.event = struct('type', {'a' 'b' 'c' 'c' 'd' 'f' });
%  EEG2.event = struct('type', {'a' 'c' 'c' 'e' 'f' });
%  eeg_mergechannels(EEG1, EEG2)
%
% Author: Arnaud Delorme and Deepa Gupta, 2023

% Copyright (C) Arnaud Delorme, arno@ucsd.edu
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

function [MERGEDEEG, TMPEEG2] = eeg_mergechannels(EEG1, EEG2, varargin)

if nargin < 2
    help eeg_mergechannels
    return
end

g = finputcheck( varargin, { ...
    'eventfield1'   'string'    {}   '';
    'eventfield2'   'string'    {}   '';
        } );
if ischar(g)
    error(g)
end

if EEG1.trials > 1 || EEG2.trials > 1
    error('The eeg_mergechannels can only process continuous data')
end

% find matching event types
evenType1 = cellfun(@deblank, { EEG1.event.type }, 'uniformoutput', false);
evenType2 = cellfun(@deblank, { EEG2.event.type }, 'uniformoutput', false);

remainingEvents = true;
counter1 = 1;
counter2 = 1;
matchingEvents1 = [];
matchingEvents2 = [];
while counter1 <= length(EEG1.event) && counter2 <= length(EEG2.event)
    ind1 = strmatch(evenType2{counter2}, evenType1(counter1:end), 'exact');
    ind2 = strmatch(evenType1{counter1}, evenType2(counter2:end), 'exact');
    
    if length(ind1) > 1, ind1 = ind1(1); end
    if length(ind2) > 1, ind2 = ind2(1); end

    bothNonEmpty = ~isempty(ind1) && ~isempty(ind2);
    if bothNonEmpty && ind1 == 1 && ind2 == 1
        matchingEvents1 = [matchingEvents1 counter1];
        matchingEvents2 = [matchingEvents2 counter2];
        counter1 = counter1+1;
        counter2 = counter2+1;
    elseif (isempty(ind1) && ~isempty(ind2)) || (bothNonEmpty && ind2 < ind1)
        matchingEvents1 = [matchingEvents1 counter1];
        matchingEvents2 = [matchingEvents2 ind2+counter2-1];
        counter1 = counter1+1;
        counter2 = ind2+counter2;
    elseif (isempty(ind2) && ~isempty(ind1)) || (bothNonEmpty && ind1 < ind2)
        matchingEvents2 = [matchingEvents2 counter2];
        matchingEvents1 = [matchingEvents1 ind1+counter1-1];
        counter2 = counter2+1;
        counter1 = ind1+counter1;
    elseif bothNonEmpty && ind1 == ind2
        error('Issue in matching event sequences');
    else
        counter1 = counter1+1;
        counter2 = counter2+1;
    end
end        

% search for common events and count them
[commonEvents,ind1,ind2] = intersect(evenType1, evenType2);
if length(evenType1) - length(removeevents(evenType1, commonEvents)) > length(matchingEvents1)
    fprintf(2, 'Some common events were missed, check event structures\n');
elseif length(evenType2) - length(removeevents(evenType2, commonEvents)) > length(matchingEvents2)
    fprintf(2, 'Some common events were missed, check event structures\n');
end

event1str = evenType1(matchingEvents1);
event2str = evenType2(matchingEvents2);
fprintf('Matching events structure 1 are %s -> {%s}\n', int2str(matchingEvents1), sprintf('''%s'' ', event1str{:}));
fprintf('Matching events structure 2 are %s -> {%s}\n', int2str(matchingEvents2), sprintf('''%s'' ', event2str{:}));
% now align the two structures

% find matching fields (assuming correct orders)
% eventstruct = importevent(EEG1.event, EEG2.event, EEG1.srate)

% first change sampling rate of second input

latency1 = [EEG1.event(matchingEvents1).latency];
latency2 = [EEG2.event(matchingEvents2).latency];

ratio = EEG2.srate/EEG1.srate;

initcond = [ratio latency2(1)-latency1(1)*ratio]; % srate_ratio then offset
func = @(x)mean(abs(x(1)*latency1-latency2+x(2)));

try
    newfactor = fminsearch(@(x)func(x), initcond, optimset('MaxIter',10000));
 catch
    error('Missing function fminsearch.m - Octave users, run "pkg install -forge optim" to install missing package and try again');
end
%newfactor(2) = latency2(1)-latency1(1);

fprintf('Ratio of sampling rate is %1.5f (%1.0f vs %1.0f) optimized to %1.5f\n', EEG2.srate/EEG1.srate, EEG1.srate, EEG2.srate, newfactor(1))
fprintf('Event offset is %1.1f samples or %1.1f seconds\n', newfactor(2), newfactor(2)/EEG2.srate)
fprintf('Event offset (compare row 1 and 2): ');


latency1corrected = (latency2 - newfactor(2))/newfactor(1);
for iEvent = 1:min(10, length(latency1))
    fprintf('%8s                   ', sprintf('%1.1f', latency1(iEvent)));
end
fprintf('\n                                    ');
for iEvent = 1:min(10, length(latency2))
    fprintf('%8s (off by %2d ms)    ', sprintf('%1.1f', latency1corrected(iEvent)), round(abs(latency1corrected(iEvent)-latency1(iEvent))));
end
fprintf('\n');

% modify EEG2 to match EEG1
newsrate = round(100*EEG2.srate/newfactor(1))/100;
fprintf('Resampling second dataset to %1.2f (to best match first dataset %1.1% sampling rate\n', newsrate, EEG1.srate)
TMPEEG2 = pop_resample(EEG2, newsrate);

% shift data
originalOffset = round(newfactor(2)/newfactor(1));
fprintf('Shift origin of second dataset by %d samples to match first dataset\n', originalOffset)
if originalOffset > 0
    TMPEEG2.data(:,1:originalOffset) = [];
elseif originalOffset < 0
    TMPEEG2.data = [ zeros(TMPEEG2.nbchan, -originalOffset) TMPEEG2.data ];
end
for iEvent = 1:length(TMPEEG2.event)
    TMPEEG2.event(iEvent).latency = TMPEEG2.event(iEvent).latency - originalOffset;
end

if size(TMPEEG2.data,2) < size(EEG1.data,2)
    fprintf('Padding second dataset with %d samples so it matches the length of the first one\n', size(EEG1.data,2)-size(TMPEEG2.data,2))
    TMPEEG2.data(:,end+1:size(EEG1.data,2)) = 0;
elseif size(TMPEEG2.data,2) > size(EEG1.data,2)
    fprintf('Removing second dataset %d trailing samples so it matches the length of the first one\n', size(EEG1.data,2)-size(TMPEEG2.data,2))
    TMPEEG2.data(:,size(EEG1.data,2)+1:end) = [];
end

% merge datasets
MERGEDEEG = EEG1;
TMPEEG2.event(matchingEvents2) = [];
MERGEDEEG.data(end+1:end+TMPEEG2.nbchan,:) = TMPEEG2.data;

fields = fieldnames(TMPEEG2.chanlocs);
inds = length(MERGEDEEG.chanlocs)+1:length(MERGEDEEG.chanlocs)+1+TMPEEG2.nbchan-1;
if ~isempty(TMPEEG2.chanlocs)
    for iField = 1:length(fields)
        [MERGEDEEG.chanlocs(inds).(fields{iField})] = deal(TMPEEG2.chanlocs.(fields{iField}));
    end
elseif ~isempty(EEG1.chanlocs)
    MERGEDEEG.chanlocs(end+length(TMPEEG2.chanlocs)).labels = '';
end

fields = fieldnames(TMPEEG2.event);
inds = length(MERGEDEEG.event)+1:length(MERGEDEEG.event)+1+length(TMPEEG2.event)-1;
if ~isempty(TMPEEG2.event)
    for iField = 1:length(fields)
        [MERGEDEEG.event(inds).(fields{iField})] = deal(TMPEEG2.event.(fields{iField}));
    end
end
MERGEDEEG = eeg_checkset(MERGEDEEG, 'eventconsistency');

% remove event types from list
function allevents = removeevents(allevents, rmlist)

for iEvent = 1:length(rmlist)
    inds = strmatch(allevents, rmlist{iEvent}, 'exact');
    allevents(inds) = [];
end