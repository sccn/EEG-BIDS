% BIDS_WRITEBEHFILE - write behavioral file
%
% Usage:
%    bids_writebehfile(beh, fileOut)
%
%
% Inputs:
%  beh       - [struct] structure containing behavioral data (event
%              structure for example)
%  behinfo   - [struct] column names and description (optional)
%  fileOut   - [string] filepath of the desired output location with file basename
%                e.g. ~/BIDS_EXPORT/sub-01/ses-01/eeg/sub-01_ses-01_task-GoNogo
%
% Authors: Arnaud Delorme, 2022

function bids_writebehfile(beh, behinfo, fileOut)

if isempty(beh)
    return;
end

if ~contains(fileOut, '_beh.tsv')
    fileOut = [ fileOut '_beh.tsv'];
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
        if isempty(beh(iRow).(fields{iField})) || any(isnan(beh(iRow).(fields{iField})))
            fprintf(fid, 'n/a' );
        else
            if ischar(beh(iRow).(fields{iField}))
                fprintf(fid, '%s',    beh(iRow).(fields{iField}) );
            else
                fprintf(fid, '%1.4f', beh(iRow).(fields{iField}) );
            end
        end
        if iField < length(fields), fprintf(fid, '\t'); end
    end
    fprintf(fid, '\n');
end
fclose(fid);

if ~isempty(behinfo)
    jsonwrite([fileOut(1:end-4) '.json'], behinfo, struct('indent','  '));
end

