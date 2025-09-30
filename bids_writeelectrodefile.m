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

    % Determine which RECOMMENDED columns have actual data
    columnsToWrite = {'name', 'x', 'y', 'z'}; % REQUIRED
    if isEMG
        % Check EMG RECOMMENDED columns
        recommendedFields = {
            'coordinate_system', 'coordinate_system';
            'electrode_type', 'type';
            'electrode_material', 'material';
            'impedance', 'impedance';
            'group', 'group'
        };

        availableFields = {};
        missingFields = {};

        for iField = 1:size(recommendedFields, 1)
            fieldName = recommendedFields{iField, 1};
            colName = recommendedFields{iField, 2};
            hasData = false;

            % Check if any electrode has this field with actual data
            for iChan = 1:EEG.nbchan
                if isfield(EEG.chanlocs(iChan), fieldName) && ...
                   ~isempty(EEG.chanlocs(iChan).(fieldName)) && ...
                   ~strcmpi(EEG.chanlocs(iChan).(fieldName), 'n/a')
                    hasData = true;
                    break;
                end
            end

            if hasData
                columnsToWrite{end+1} = colName;
                availableFields{end+1} = colName;
            else
                missingFields{end+1} = colName;
            end
        end

        % Display warning about missing RECOMMENDED columns
        if ~isempty(missingFields)
            fprintf('Note: The following RECOMMENDED EMG electrode columns are not included (no data available): %s\n', ...
                    strjoin(missingFields, ', '));
        end
    end

    % Write TSV file with determined columns
    fid = fopen( [ fileOut '_electrodes.tsv' ], 'w');
    fprintf(fid, '%s\n', strjoin(columnsToWrite, '\t'));

    for iChan = 1:EEG.nbchan
        values = {};

        % Name (always)
        values{end+1} = EEG.chanlocs(iChan).labels;

        % X, Y, Z
        if isempty(EEG.chanlocs(iChan).X) || isnan(EEG.chanlocs(iChan).X) || contains(fileOut, 'ieeg')
            values{end+1} = 'n/a';
            values{end+1} = 'n/a';
            values{end+1} = 'n/a';
        else
            values{end+1} = sprintf('%2.6f', EEG.chanlocs(iChan).X);
            values{end+1} = sprintf('%2.6f', EEG.chanlocs(iChan).Y);
            values{end+1} = sprintf('%2.6f', EEG.chanlocs(iChan).Z);
        end

        % Additional EMG columns (only those with data)
        if isEMG
            for iCol = 5:length(columnsToWrite)
                colName = columnsToWrite{iCol};

                % Map column name to field name
                switch colName
                    case 'coordinate_system'
                        fieldName = 'coordinate_system';
                    case 'type'
                        fieldName = 'electrode_type';
                    case 'material'
                        fieldName = 'electrode_material';
                    case 'impedance'
                        fieldName = 'impedance';
                    case 'group'
                        fieldName = 'group';
                end

                % Get value or 'n/a'
                if isfield(EEG.chanlocs(iChan), fieldName) && ...
                   ~isempty(EEG.chanlocs(iChan).(fieldName))
                    val = EEG.chanlocs(iChan).(fieldName);
                    if isnumeric(val)
                        values{end+1} = num2str(val);
                    else
                        values{end+1} = val;
                    end
                else
                    values{end+1} = 'n/a';
                end
            end
        end

        fprintf(fid, '%s\n', strjoin(values, '\t'));
    end
    fclose(fid);

    % Write coordinate file information (coordsystem.json)
    % Supports both single and multiple coordinate systems
    isEMG = isfield(EEG, 'etc') && isfield(EEG.etc, 'datatype') && strcmpi(EEG.etc.datatype, 'emg');

    % Check for multiple coordinate systems
    if isfield(EEG.chaninfo, 'BIDS') && isfield(EEG.chaninfo.BIDS, 'coordsystems')
        % Multiple coordinate systems (with space entities)
        coordsystems = EEG.chaninfo.BIDS.coordsystems;

        % Validate parent references for nested coordinate systems
        spaceLabels = cellfun(@(x) x.space, coordsystems, 'UniformOutput', false);
        for iCoord = 1:length(coordsystems)
            cs = coordsystems{iCoord};
            if isfield(cs, 'ParentCoordinateSystem') && ~isempty(cs.ParentCoordinateSystem)
                if ~ismember(cs.ParentCoordinateSystem, spaceLabels)
                    error('Invalid parent coordinate system "%s" for space "%s". Parent must exist.', ...
                          cs.ParentCoordinateSystem, cs.space);
                end
            end
        end

        % Write each coordinate system as separate file
        for iCoord = 1:length(coordsystems)
            cs = coordsystems{iCoord};
            coordStruct = struct();

            % Copy all fields except 'space'
            fields = fieldnames(cs);
            for iField = 1:length(fields)
                if ~strcmpi(fields{iField}, 'space')
                    coordStruct.(fields{iField}) = cs.(fields{iField});
                end
            end

            % Write with space entity in filename
            if ~isempty(cs.space)
                filename = sprintf('%s_space-%s_coordsystem.json', fileOut, cs.space);
            else
                filename = sprintf('%s_coordsystem.json', fileOut);
            end
            jsonwrite(filename, coordStruct);
        end
    else
        % Single coordinate system (backward compatibility)
        coordsystemStruct = struct();

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
