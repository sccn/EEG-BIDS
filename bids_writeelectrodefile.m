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
    % Check if EMG for extended columns
    isEMG = isfield(EEG, 'etc') && isfield(EEG.etc, 'datatype') && strcmpi(EEG.etc.datatype, 'emg');

    fid = fopen( [ fileOut '_electrodes.tsv' ], 'w');
    if isEMG
        % EMG: name, x, y, z, coordinate_system (5th), type, material, impedance, group
        fprintf(fid, 'name\tx\ty\tz\tcoordinate_system\ttype\tmaterial\timpedance\tgroup\n');
    else
        fprintf(fid, 'name\tx\ty\tz\n');
    end

    for iChan = 1:EEG.nbchan
        if isempty(EEG.chanlocs(iChan).X) || isnan(EEG.chanlocs(iChan).X) || contains(fileOut, 'ieeg')
            if isEMG
                fprintf(fid, '%s\tn/a\tn/a\tn/a\tn/a\tn/a\tn/a\tn/a\tn/a\n', EEG.chanlocs(iChan).labels );
            else
                fprintf(fid, '%s\tn/a\tn/a\tn/a\n', EEG.chanlocs(iChan).labels );
            end
        else
            if isEMG
                % Extract EMG-specific electrode fields
                coord_system = getfield_or_na_elec(EEG.chanlocs(iChan), 'coordinate_system');
                elec_type = getfield_or_na_elec(EEG.chanlocs(iChan), 'electrode_type');
                material = getfield_or_na_elec(EEG.chanlocs(iChan), 'electrode_material');
                impedance = getfield_or_na_elec(EEG.chanlocs(iChan), 'impedance');
                group = getfield_or_na_elec(EEG.chanlocs(iChan), 'group');

                fprintf(fid, '%s\t%2.6f\t%2.6f\t%2.6f\t%s\t%s\t%s\t%s\t%s\n', ...
                    EEG.chanlocs(iChan).labels, EEG.chanlocs(iChan).X, EEG.chanlocs(iChan).Y, EEG.chanlocs(iChan).Z, ...
                    coord_system, elec_type, material, impedance, group);
            else
                fprintf(fid, '%s\t%2.6f\t%2.6f\t%2.6f\n', EEG.chanlocs(iChan).labels, EEG.chanlocs(iChan).X, EEG.chanlocs(iChan).Y, EEG.chanlocs(iChan).Z );
            end
        end
    end
    fclose(fid);

    % Write coordinate file information (coordsystem.json)
    isEMG = isfield(EEG, 'etc') && isfield(EEG.etc, 'datatype') && strcmpi(EEG.etc.datatype, 'emg');

    if isEMG
        if isfield(EEG.chaninfo, 'BIDS') && isfield(EEG.chaninfo.BIDS, 'EMGCoordinateUnits')
            coordsystemStruct.EMGCoordinateUnits = EEG.chaninfo.BIDS.EMGCoordinateUnits;
        else
            coordsystemStruct.EMGCoordinateUnits = 'mm';
        end
        if isfield(EEG.chaninfo, 'BIDS') && isfield(EEG.chaninfo.BIDS, 'EMGCoordinateSystem')
            coordsystemStruct.EMGCoordinateSystem = EEG.chaninfo.BIDS.EMGCoordinateSystem;
        else
            coordsystemStruct.EMGCoordinateSystem = 'Other';
        end
        if isfield(EEG.chaninfo, 'BIDS') && isfield(EEG.chaninfo.BIDS, 'EMGCoordinateSystemDescription')
            coordsystemStruct.EMGCoordinateSystemDescription = EEG.chaninfo.BIDS.EMGCoordinateSystemDescription;
        else
            coordsystemStruct.EMGCoordinateSystemDescription = 'Electrode locations in mm';
        end
    else
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
    end
    jsonwrite( [ fileOut '_coordsystem.json' ], coordsystemStruct);
end

% Helper function to get field value or 'n/a' for electrode fields
function value = getfield_or_na_elec(struct, fieldname)
if isfield(struct, fieldname) && ~isempty(struct.(fieldname))
    value = struct.(fieldname);
    % Convert numeric to string
    if isnumeric(value)
        value = num2str(value);
    end
else
    value = 'n/a';
end
