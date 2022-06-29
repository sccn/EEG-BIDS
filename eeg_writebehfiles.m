% eeg_writebehfiles - write behavioral file
%
% Usage:
%    eeg_writebehfiles(beh, fileOut)
%
%
% Inputs:
%  beh       - [struct] structure containing behavioral data (event
%              structue for example)
%  fileOut   - [string] filepath of the desired output location with file basename
%                e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo
%
% Authors: Arnaud Delorme, 2022

function eeg_writebehfiles(beh, fileOut)

if isempty(beh)
    return;
end

folder = fileparts(fileOut);
if ~exist(folder)
    mkdir(folder);
end
fid = fopen( fileOut, 'w');
if fid == -1
    error('Cannot open behavioral file');
end

fields = fieldnames(beh);
for iField = 1:length(fields)
    fprintf(fid, '%s', fields{iField} );
    if iField < length(fields), fprintf(fid, '\t'); end
end
fprintf(fid, '\n');

for iRow = 1:length(beh)
    for iField = 1:length(fields)
        if isempty(beh(iRow).(fields{iField}))
            fprintf(fid, 'n/a' );
        else
            fprintf(fid, '%1.4f', beh(iRow).(fields{iField}) );
        end
        if iField < length(fields), fprintf(fid, '\t'); end
    end
    fprintf(fid, '\n');
end
fclose(fid);
