% eeg_writeelectrodesfiles - write electrodes.tsv and coordsystem.json from single EEG dataset
%
% Usage:
%    eeg_writeelectrodesfiles(EEG, fileOut)
%
%
% Inputs:
%  'EEG'       - [struct] the EEG structure
%
%  'fileOut'   - [string] filepath of the desired output location with file basename
%                e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo
%
% Authors: Dung Truong, Arnaud Delorme, 2022
function eeg_writeelectrodesfiles(EEG, fileOut)
isTemplate = false;
if isfield(EEG.chaninfo, 'filename')
    if ~isempty(strfind(EEG.chaninfo.filename, 'standard-10-5-cap385.elp')) || ...
      ~isempty(strfind(EEG.chaninfo.filename, 'standard_1005.elc'))||...
      ~isempty(strfind(EEG.chaninfo.filename, 'standard_1005.ced'))
      isTemplate = true;
      disp('Template channel location detected, not exporting electrodes.tsv file');
    end
end

if ~isTemplate && ~isempty(EEG.chanlocs) && isfield(EEG.chanlocs, 'X') && ~isempty(EEG.chanlocs(2).X)
    fid = fopen( [ fileOut '_electrodes.tsv' ], 'w');
    fprintf(fid, 'name\tx\ty\tz\n');
    
    for iChan = 1:EEG.nbchan
        if isempty(EEG.chanlocs(iChan).X) || isnan(EEG.chanlocs(iChan).X)
            fprintf(fid, '%s\tn/a\tn/a\tn/a\n', EEG.chanlocs(iChan).labels );
        else
            fprintf(fid, '%s\t%2.6f\t%2.6f\t%2.6f\n', EEG.chanlocs(iChan).labels, EEG.chanlocs(iChan).X, EEG.chanlocs(iChan).Y, EEG.chanlocs(iChan).Z );
        end
    end
    fclose(fid);
    
    % Write coordinate file information (coordsystem.json)
    coordsystemStruct.EEGCoordinateUnits = 'mm';
    coordsystemStruct.EEGCoordinateSystem = 'CTF'; % Change as soon as possible to EEGLAB
    coordsystemStruct.EEGCoordinateSystemDescription = 'EEGLAB';
    jsonwrite( [ fileOut '_coordsystem.json' ], coordsystemStruct);
end