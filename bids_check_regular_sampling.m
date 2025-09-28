% BIDS_CHECK_REGULAR_SAMPLING - Check if EEG data has regular sampling
%
% Usage:
%   [isRegular, avgFreq] = bids_check_regular_sampling(EEG)
%   [isRegular, avgFreq] = bids_check_regular_sampling(EEG, tolerance)
%
% Inputs:
%   EEG       - [struct] EEGLAB dataset structure
%   tolerance - [float] acceptable deviation from regular sampling (default: 0.0001 = 0.01%)
%
% Outputs:
%   isRegular - [boolean] true if sampling is regular within tolerance
%   avgFreq   - [float] average sampling frequency in Hz
%
% Note:
%   EDF and BDF formats require perfectly regular sampling. This function
%   checks if data has irregular timestamps and calculates the average
%   frequency for potential resampling.
%
% Authors: Seyed Yahya Shirazi, 2025

function [isRegular, avgFreq] = bids_check_regular_sampling(EEG, tolerance)

if nargin < 1
    help bids_check_regular_sampling;
    return;
end

if nargin < 2
    tolerance = 0.0001;
end

if isempty(EEG.data)
    error('EEG.data is empty');
end

if EEG.trials > 1
    isRegular = true;
    avgFreq = EEG.srate;
    return;
end

if isfield(EEG, 'times') && length(EEG.times) > 1
    intervals = diff(EEG.times);

    if length(unique(intervals)) == 1
        isRegular = true;
        avgFreq = EEG.srate;
        return;
    end

    avgInterval = mean(intervals);
    maxDeviation = max(abs(intervals - avgInterval)) / avgInterval;

    isRegular = maxDeviation < tolerance;
    avgFreq = 1000 / avgInterval;
else
    isRegular = true;
    avgFreq = EEG.srate;
end