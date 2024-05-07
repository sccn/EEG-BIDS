% eeg_writechanfile - write channels.tsv from single EEG dataset. The
%                     function also outputs channels count
%
% Usage:
%    channelsCount = eeg_writechanfile(EEG, fileOut)
%
%  
%
% Inputs:
%  'EEG'       - [struct] the EEG structure
%
%  'fileOut'   - [string] filepath of the desired output location with file basename
%                e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo
%
% Outputs:
%
%   channelsCount - [struct] count of different types of channels
%
% Authors: Dung Truong, Arnaud Delorme, 2022

function bids_writechanfile(EEG, fileOut)

fid = fopen( [ fileOut '_channels.tsv' ], 'w');
if isempty(EEG.chanlocs)
    if contains(fileOut, 'ieeg')
        fprintf(fid, 'name\ttype\tunits\tlow_cutoff\thigh_cutoff\n');
        for iChan = 1:EEG.nbchan
            fprintf(fid, 'E%d\tiEEG\tmicroV\tn/a\tn/a\n', iChan); 
        end
    else
        fprintf(fid, 'name\ttype\tunits\n');
        for iChan = 1:EEG.nbchan
            fprintf(fid, 'E%d\tEEG\tmicroV\n', iChan); 
        end
    end
    channelsCount = struct([]);
else
    if contains(fileOut, 'ieeg')
        fprintf(fid, 'name\ttype\tunits\tlow_cutoff\thigh_cutoff\n');
    else
        fprintf(fid, 'name\ttype\tunits\n');
    end
    acceptedChannelTypes = { 'AUDIO' 'EEG' 'EOG' 'ECG' 'EMG' 'EYEGAZE' 'GSR' 'HEOG' 'MISC' 'PUPIL' 'REF' 'RESP' 'SYSCLOCK' 'TEMP' 'TRIG' 'VEOG' };
    for iChan = 1:EEG.nbchan
        % Type
        if ~isfield(EEG.chanlocs, 'type') || isempty(EEG.chanlocs(iChan).type)
            type = 'n/a';
        elseif ismember(upper(EEG.chanlocs(iChan).type), acceptedChannelTypes)
            type = upper(EEG.chanlocs(iChan).type);
        else
            type = 'MISC';
        end
        % Unit
        if isfield(EEG.chanlocs(iChan), 'unit')
            unit = EEG.chanlocs(iChan).unit;
        else
            if strcmpi(type, 'eeg')
                unit = 'uV';
            else
                unit = 'n/a';
            end
        end

        %Write
        if contains(fileOut, 'ieeg')
            fprintf(fid, '%s\t%s\t%s\tn/a\tn/a\n', EEG.chanlocs(iChan).labels, type, unit);
        else
            fprintf(fid, '%s\t%s\t%s\n', EEG.chanlocs(iChan).labels, type, unit);
        end
    end
end
fclose(fid);
