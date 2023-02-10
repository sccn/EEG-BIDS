% eeg_importcoordsystemfiles - import coordinate information
%
% Usage:
%    [EEG, bids] = eeg_importcoordsystemfiles(EEG, coordfile, 'key', value)
%
% Inputs:
%  'EEG'        - [struct] the EEG structure to which event information will be imported
%  coordfile    - [string] path to the coordsystem.json file. 
%                 e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo_coordsystem.json
%
% Optional inputs:
%  'bids'          - [struct] structure that saves imported BIDS information. Default is []
%
% Outputs:
%   EEG     - [struct] the EEG structure with event info imported
%   bids    - [struct] structure that saves BIDS information with event information
%
% Authors: Arnaud Delorme, 2022

function [EEG, bids] = eeg_importcoordsystemfiles(EEG, coordfile, varargin)

if nargin < 2
    help eeg_importcoordsystemfiles;
    return;
end

g = finputcheck(varargin,  {'bids' 'struct' [] struct([]) }, 'eeg_importcoordsystemfiles', 'ignore');
if isstr(g), error(g); end

bids = g.bids;
                        
% coordinate information
bids(1).coordsystem = loadfile( coordfile, '');
if ~isfield(EEG.chaninfo, 'nodatchans')
    EEG.chaninfo.nodatchans = [];
end
EEG.chaninfo.bids = bids(1).coordsystem;

% import anatomical landmark
% --------------------------
if isfield(bids.coordsystem, 'AnatomicalLandmarkCoordinates') && ~isempty(bids.coordsystem.AnatomicalLandmarkCoordinates)
    factor = checkunit(EEG.chaninfo, 'AnatomicalLandmarkCoordinateUnits');
    fieldNames = fieldnames(bids.coordsystem.AnatomicalLandmarkCoordinates);
    for iField = 1:length(fieldNames)
        EEG.chaninfo.nodatchans(end+1).labels = fieldNames{iField};
        EEG.chaninfo.nodatchans(end).type   = 'FID';
        EEG.chaninfo.nodatchans(end).X = bids.coordsystem.AnatomicalLandmarkCoordinates.(fieldNames{iField})(1)*factor;
        EEG.chaninfo.nodatchans(end).Y = bids.coordsystem.AnatomicalLandmarkCoordinates.(fieldNames{iField})(2)*factor;
        EEG.chaninfo.nodatchans(end).Z = bids.coordsystem.AnatomicalLandmarkCoordinates.(fieldNames{iField})(3)*factor;
    end
    EEG.chaninfo.nodatchans = convertlocs(EEG.chaninfo.nodatchans);
end

% import head position
% --------------------
if isfield(bids.coordsystem, 'DigitizedHeadPoints') && ~isempty(bids.coordsystem.DigitizedHeadPoints)
    factor = checkunit(EEG.chaninfo, 'DigitizedHeadPointsCoordinateUnits');
    try
        headpos = readlocs(bids.coordsystem.DigitizedHeadPoints, 'filetype', 'sfp');
        for iPoint = 1:length(headpos)
            EEG.chaninfo.nodatchans(end+1).labels = headpos{iField};
            EEG.chaninfo.nodatchans(end).type   = 'HeadPoint';
            EEG.chaninfo.nodatchans(end).X = headpos(iPoint).X*factor;
            EEG.chaninfo.nodatchans(end).Y = headpos(iPoint).Y*factor;
            EEG.chaninfo.nodatchans(end).Z = headpos(iPoint).Z*factor;
        end
        EEG.chaninfo.nodatchans = convertlocs(EEG.chaninfo.nodatchans);
    catch 
        if ischar(bids.coordsystem.DigitizedHeadPoints)
           fprintf('Could not read head points file %s\n', bids.coordsystem.DigitizedHeadPoints);
        end
    end
end

% coordinate transform factor
% ---------------------------
function factor = checkunit(chaninfo, field)
    if isfield(chaninfo.bids, field) && isfield(chaninfo, 'unit')
        if isequal(chaninfo.bids.(field), 'mm') && isequal(chaninfo.unit, 'cm')
            factor = 1/10;
        elseif isequal(chaninfo.bids.(field), 'cm') && isequal(chaninfo.unit, 'mm')
            factor = 10;
        elseif isequal(chaninfo.bids.(field), chaninfo.unit)
            factor = 1;
        else
            error('Unit not supported')
        end
    end

% import JSON or TSV file
% -----------------------
function data = loadfile(localFile, globalFile)
[~,~,ext] = fileparts(localFile);
data = [];
localFile = dir(localFile);
if ~isempty(localFile)
    if strcmpi(ext, '.tsv')
        data = importtsv( fullfile(localFile(1).folder, localFile(1).name));
    else
        if exist('jsondecode.m','file')
            data = jsondecode( importalltxt( fullfile(localFile(1).folder, localFile(1).name) ));
        else
            data = jsonread(fullfile(localFile(1).folder, localFile(1).name));
        end
    end        
elseif ~isempty(globalFile)
    if strcmpi(ext, '.tsv')
        data = importtsv( fullfile(globalFile(1).folder, globalFile(1).name));
    else
        if exist('jsondecode.m','file')
            data = jsondecode( importalltxt( fullfile(globalFile(1).folder, globalFile(1).name) ));
        else
            data = jsonread(fullfile(globalFile(1).folder, globalFile(1).name));
        end
    end
end

% Import full text file
% ---------------------
function str = importalltxt(fileName)

str = [];
fid =fopen(fileName, 'r');
while ~feof(fid)
    str = [str 10 fgetl(fid) ];
end
str(1) = [];

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