% BIDS_IMPORTCOORDSYSTEMFILE - import coordinate information
%
% Usage:
%    [EEG, bids] = bids_importcoordsystemfile(EEG, coordfile, 'key', value)
%
% Inputs:
%  'EEG'        - [struct] the EEG structure to which event information will be imported
%  coordfile    - [string or cell array] path(s) to coordsystem.json file(s)
%                 Single: ~/BIDS/sub-01/emg/sub-01_coordsystem.json
%                 Multiple: {~/BIDS/sub-01/emg/sub-01_space-hand_coordsystem.json, ...}
%
% Optional inputs:
%  'bids'          - [struct] structure that saves imported BIDS information. Default is []
%
% Outputs:
%   EEG     - [struct] the EEG structure with coordinate info imported
%   bids    - [struct] structure that saves BIDS information with coordinate information
%
% Authors: Arnaud Delorme, 2022
%          Yahya Alwabari, 2025 (multiple coordinate systems support)

function [EEG, bids] = bids_importcoordsystemfile(EEG, coordfile, varargin)

if nargin < 2
    help bids_importcoordsystemfile;
    return;
end

g = finputcheck(varargin,  {'bids' 'struct' [] struct([]) }, 'eeg_importcoordsystemfiles', 'ignore');
if isstr(g), error(g); end

bids = g.bids;

% Handle empty coordfile
if isempty(coordfile)
    return;
end

% Convert single file to cell array for uniform processing
if ischar(coordfile)
    coordfile = {coordfile};
end

% Initialize coordsystems storage
if ~isfield(EEG.chaninfo, 'nodatchans')
    EEG.chaninfo.nodatchans = [];
end

% Process all coordsystem files
coordsystems = {};
for iCoord = 1:length(coordfile)
    if isempty(coordfile{iCoord})
        continue;
    end

    % Load coordsystem JSON
    coordData = bids_importjson(coordfile{iCoord}, '_coordsystem.json');

    % Parse space entity from filename
    % Handles both subject-level and root-level (inheritance) patterns:
    %   - Subject: sub-01_space-hand_coordsystem.json
    %   - Root: space-leftForearm_coordsystem.json
    [~, filename, ~] = fileparts(coordfile{iCoord});
    spaceLabel = '';

    % Try with prefix underscore first (subject-level)
    spaceMatch = regexp(filename, '_space-([a-zA-Z0-9]+)_', 'tokens');
    if ~isempty(spaceMatch)
        spaceLabel = spaceMatch{1}{1};
    else
        % Try without prefix underscore (root-level, BIDS inheritance)
        spaceMatch = regexp(filename, '^space-([a-zA-Z0-9]+)_', 'tokens');
        if ~isempty(spaceMatch)
            spaceLabel = spaceMatch{1}{1};
        end
    end

    % Add space label to coordData
    coordData.space = spaceLabel;

    % Store in coordsystems cell array
    coordsystems{end+1} = coordData;

    % Import anatomical landmarks (only for first coordsystem to avoid duplicates)
    if iCoord == 1 && isfield(coordData, 'AnatomicalLandmarkCoordinates') && ~isempty(coordData.AnatomicalLandmarkCoordinates)
        factor = checkunit(EEG.chaninfo, coordData, 'AnatomicalLandmarkCoordinateUnits');
        fieldNames = fieldnames(coordData.AnatomicalLandmarkCoordinates);
        for iField = 1:length(fieldNames)
            EEG.chaninfo.nodatchans(end+1).labels = fieldNames{iField};
            EEG.chaninfo.nodatchans(end).type   = 'FID';
            EEG.chaninfo.nodatchans(end).X = coordData.AnatomicalLandmarkCoordinates.(fieldNames{iField})(1)*factor;
            EEG.chaninfo.nodatchans(end).Y = coordData.AnatomicalLandmarkCoordinates.(fieldNames{iField})(2)*factor;
            EEG.chaninfo.nodatchans(end).Z = coordData.AnatomicalLandmarkCoordinates.(fieldNames{iField})(3)*factor;
        end
        EEG.chaninfo.nodatchans = convertlocs(EEG.chaninfo.nodatchans);
    end

    % Import head position (only for first coordsystem)
    if iCoord == 1 && isfield(coordData, 'DigitizedHeadPoints') && ~isempty(coordData.DigitizedHeadPoints)
        factor = checkunit(EEG.chaninfo, coordData, 'DigitizedHeadPointsCoordinateUnits');
        try
            headpos = readlocs(coordData.DigitizedHeadPoints, 'filetype', 'sfp');
            for iPoint = 1:length(headpos)
                EEG.chaninfo.nodatchans(end+1).labels = headpos(iPoint).labels;
                EEG.chaninfo.nodatchans(end).type   = 'HeadPoint';
                EEG.chaninfo.nodatchans(end).X = headpos(iPoint).X*factor;
                EEG.chaninfo.nodatchans(end).Y = headpos(iPoint).Y*factor;
                EEG.chaninfo.nodatchans(end).Z = headpos(iPoint).Z*factor;
            end
            EEG.chaninfo.nodatchans = convertlocs(EEG.chaninfo.nodatchans);
        catch
            if ischar(coordData.DigitizedHeadPoints)
               fprintf('Could not read head points file %s\n', coordData.DigitizedHeadPoints);
            end
        end
    end
end

% Store coordsystems in EEG structure
if length(coordsystems) == 1 && isempty(coordsystems{1}.space)
    % Single coordsystem without space - backward compatibility
    % Store directly in EEG.chaninfo.BIDS
    coordsystems{1} = rmfield(coordsystems{1}, 'space');
    EEG.chaninfo.BIDS = coordsystems{1};
    bids(1).coordsystem = coordsystems{1};
elseif length(coordsystems) >= 1
    % Multiple coordsystems or single with space entity
    % Store as cell array
    EEG.chaninfo.BIDS.coordsystems = coordsystems;
    bids(1).coordsystems = coordsystems;

    % Also store first one directly for backward compat
    if ~isempty(coordsystems)
        bids(1).coordsystem = coordsystems{1};
    end
end

% coordinate transform factor
% ---------------------------
function factor = checkunit(chaninfo, coordData, field)
    factor = 1;
    if isfield(coordData, field) && isfield(chaninfo, 'unit')
        if isequal(coordData.(field), 'mm') && isequal(chaninfo.unit, 'cm')
            factor = 1/10;
        elseif isequal(coordData.(field), 'mm') && isequal(chaninfo.unit, 'm')
            factor = 1/1000;
        elseif isequal(coordData.(field), 'cm') && isequal(chaninfo.unit, 'mm')
            factor = 10;
        elseif isequal(coordData.(field), 'cm') && isequal(chaninfo.unit, 'm')
            factor = 1/10;
        elseif isequal(coordData.(field), 'm') && isequal(chaninfo.unit, 'cm')
            factor = 100;
        elseif isequal(coordData.(field), 'm') && isequal(chaninfo.unit, 'mm')
            factor = 1000;
        elseif isequal(coordData.(field), chaninfo.unit)
            factor = 1;
        else
            error('Unit not supported')
        end
    end

function nameout = cleanvarname(namein)

% Routine to remove unallowed characters from strings
% nameout can be use as a variable or field in a structure

% custom change
if strcmp(namein,'#')
    namein = 'nb';
end

% 1st char must be a letter
for l=1:length(namein)
    if isletter(namein(l))
        nameout = namein(l:end);
        break % exist for loop
    end
end

% remove usual suspects
stringcheck = [strfind(namein,'('), ...
    strfind(namein,')') ...
    strfind(namein,'[') ...
    strfind(namein,']') ...
    strfind(namein,'{') ...
    strfind(namein,'}') ...
    strfind(namein,'-') ...
    strfind(namein,'+') ...
    strfind(namein,'*') ...
    strfind(namein,'/') ...
    strfind(namein,'#') ...
    strfind(namein,'%') ...
    strfind(namein,'&') ...
    strfind(namein,'@') ...
    ];

if ~isempty(stringcheck)
    nameout(stringcheck) = [];
end

% last check
if ~isvarname(nameout)
    error('the variable name to use is still invalid, check chars to remove')
end