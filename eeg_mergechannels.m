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

function [EEG, EYE] = eeg_mergechannels(EEG1, EEG2, varargin)

g = finputcheck( varargin, { ...
    'eventfield1'   'string'    {}   '';
    'eventfield2'   'string'    {}   '';
        } );
if ischar(g)
    error(g)
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
if length(evenType1) - length(setdiff(evenType1, commonEvents)) > length(matchingEvents1)
    fprintf(2, 'Some common events were missed, check event structures\n');
elseif length(evenType2) - length(setdiff(evenType2, commonEvents)) > length(matchingEvents2)
    fprintf(2, 'Some common events were missed, check event structures\n');
end

event1str = evenType1(matchingEvents1);
event2str = evenType2(matchingEvents2);
fprintf('Matching events structure 1 are %s -> {%s}\n', int2str(matchingEvents1), sprintf('''%s'' ', event1str{:}));
fprintf('Matching events structure 2 are %s -> {%s}\n', int2str(matchingEvents2), sprintf('''%s'' ', event2str{:}));
% now align the two structures

% find matching fields (assuming correct orders)
% eventstruct = importevent(EEG1.event, EEG2.event, EEG1.srate)

% sdafdsa


