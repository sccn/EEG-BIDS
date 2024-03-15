% BIDS_LOADFILE - import JSON or TSV file
%
% Usage:
%    bids_loadfile(localFile, globalFile)
%
% Input:
%   localFile      - Name of the localfile
%   globalFile     - Name of the global file if the local file cannot be
%                    found

function data = bids_loadfile(localFile, globalFile, rawFlag)
[~,~,ext] = fileparts(localFile);
data = [];
localFile = dir(localFile);
if nargin > 2
    if ischar(localFile)
        data = importalltxt( localFile );        
    else
        data = importalltxt( fullfile(localFile(1).folder, localFile(1).name) );
    end
    return
end

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
elseif nargin > 1 && ~isempty(globalFile)
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
end

% Import tsv file
% ---------------
function res = importtsv( fileName)

res = loadtxt( fileName, 'verbose', 'off', 'delim', [ 9 ]);

for iCol = 1:size(res,2)
    % search for NaNs in numerical array
    indNaNs = cellfun(@(x)strcmpi('n/a', x), res(:,iCol));
    if ~isempty(indNaNs)
        allNonNaNVals = res(find(~indNaNs),iCol);
        allNonNaNVals(1) = []; % header
        testNumeric   = cellfun(@isnumeric, allNonNaNVals);
        if all(testNumeric)
            res(find(indNaNs),iCol) = { NaN };
        elseif ~all(~testNumeric)
            % Convert numerical value back to string
            res(:,iCol) = cellfun(@num2str, res(:,iCol), 'uniformoutput', false);
        end
    end
end
end
end