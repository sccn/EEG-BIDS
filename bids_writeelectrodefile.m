% BIDS_WRITEELECTRODEFILE - write electrodes.tsv and coordsystem.json from single EEG dataset
%
% Usage:
%    bids_writeelectrodefile(EEG, fileOut, flagExport)
%
% Inputs:
%  'EEG'       - [struct] the EEG structure
%  'fileOut'   - [string] filepath of the desired output location with file basename
%                e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo
%
% Optional inputs:
%  'Export'    - ['on'|'off'|'auto']
%
% Authors: Dung Truong, Arnaud Delorme, 2022

function bids_writeelectrodefile(EEG, fileOut, varargin)

if nargin > 2
    flagExport = varargin{2};
else
    flagExport = 'auto';
end

% remove task because a bug in v1.10.0 validator returns an error (MAYBE REMOVE THAT SECTION LATER)
ind = strfind(fileOut, 'task-');
if ~isempty(ind)
    ind_ = find(fileOut(ind:end) == '_');
    if isempty(ind_)
        ind_ = length(fileOut(ind:end))+1;
    end
    fileOut(ind-1:ind+ind_-2) = [];
end

% remove desc as well (MAYBE REMOVE THAT SECTION LATER)
ind = strfind(fileOut, 'desc-');
if ~isempty(ind)
    ind_ = find(fileOut(ind:end) == '_');
    if isempty(ind_)
        ind_ = length(fileOut(ind:end))+1;
    end
    fileOut(ind-1:ind+ind_-2) = [];
end

if isfield(EEG.chaninfo, 'filename') && isequal(flagExport, 'auto')
    templates = {'GSN-HydroCel-32.sfp', 'GSN65v2_0.sfp', 'GSN129.sfp', 'GSN-HydroCel-257.sfp', 'standard-10-5-cap385.elp', 'standard_1005.elc', 'standard_1005.ced'};
    if any(contains(EEG.chaninfo.filename, templates))
        flagExport = 'off';
        disp('Template channel location detected, not exporting electrodes.tsv file');
    end
end

if any(strcmp(flagExport, {'auto', 'on'})) && ~isempty(EEG.chanlocs) && isfield(EEG.chanlocs, 'X') && any(cellfun(@(x)~isempty(x), { EEG.chanlocs.X }))
    fid = fopen( [ fileOut '_electrodes.tsv' ], 'w');
    fprintf(fid, 'name\tx\ty\tz\n');
    
    for iChan = 1:EEG.nbchan
        if isempty(EEG.chanlocs(iChan).X) || isnan(EEG.chanlocs(iChan).X) || contains(fileOut, 'ieeg')
            fprintf(fid, '%s\tn/a\tn/a\tn/a\n', EEG.chanlocs(iChan).labels );
        else
            fprintf(fid, '%s\t%2.6f\t%2.6f\t%2.6f\n', EEG.chanlocs(iChan).labels, EEG.chanlocs(iChan).X, EEG.chanlocs(iChan).Y, EEG.chanlocs(iChan).Z );
        end
    end
    fclose(fid);
    
    % Write coordinate file information (coordsystem.json)
    if isfield(EEG.chaninfo, 'BIDS') && isfield(EEG.chaninfo.BIDS, 'EEGCoordinateUnits')
        coordsystemStruct.EEGCoordinateUnits = EEG.chaninfo.BIDS.EEGCoordinateUnits;
    else
        coordsystemStruct.EEGCoordinateUnits = 'mm';
    end
    if isfield(EEG.chaninfo, 'BIDS') &&isfield(EEG.chaninfo.BIDS, 'EEGCoordinateSystem')
        coordsystemStruct.EEGCoordinateSystem = EEG.chaninfo.BIDS.EEGCoordinateSystem;
    else
        coordsystemStruct.EEGCoordinateSystem = 'CTF';
    end
    if isfield(EEG.chaninfo, 'BIDS') &&isfield(EEG.chaninfo.BIDS, 'EEGCoordinateSystemDescription')
        coordsystemStruct.EEGCoordinateSystemDescription = EEG.chaninfo.BIDS.EEGCoordinateSystemDescription;
    else
        coordsystemStruct.EEGCoordinateSystemDescription = 'EEGLAB';
    end
    jsonwrite( [ fileOut '_coordsystem.json' ], coordsystemStruct);
end
