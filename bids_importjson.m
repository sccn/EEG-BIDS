% bids_importjson - Import json file following BIDS key-based inheritance rule
%                   (https://bids-specification.readthedocs.io/en/stable/common-principles.html#the-inheritance-principle)
%
% Usage:
%    curjsondata = bids_importjson(curFile, ext)
%
% Inputs:
%  curFile      - [string] path to the current json file
%  ext          - [string] BIDS post fix extension of the file. 
%                 e.g. _events.tsv
%
% Outputs:
%   curjsondata     - [struct] json data imported as matlab structure
%
% Author: Dung Truong, 2024
function curjsondata = bids_importjson(curFile, ext)
    % resolve wildcard if applicable
    curFileDir = dir(curFile);
    if ~isempty(curFileDir)
        curFile = fullfile(curFileDir(1).folder, curFileDir(1).name);
    end
    if ~exist(curFile, 'file') || isempty(curFile)
        curjsondata = struct([]);
    else
        curjsondata = readjson(curFile);
    end
    if ~isTopLevel(curFile)
        upperFile = fullfile(fileparts(fileparts(curFile)), ['*' ext]);
        upperjsondata = bids_importjson(upperFile, ext);
        
        % mergeStructures credit: https://www.mathworks.com/matlabcentral/fileexchange/131718-mergestructures-merge-or-concatenate-nested-structures?s_tid=mwa_osa_a
        curjsondata = mergeStructures(curjsondata, upperjsondata);
    end

    function res = readjson(file)
        if exist('jsondecode.m','file')
            res = jsondecode( importalltxt( file ));
        else
            res = jsonread(file);
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

    function res = isTopLevel(curfile)
        res = true;
        if ~isempty(curfile)
            curpath = fileparts(curfile);
            files = dir(curpath);
            if ~isempty(files)
                for f=1:numel(files)
                    if ~files(f).isdir && strcmp(files(f).name, 'README')
                        res = true;
                        return
                    end
                end
            end
            res = false;
        end
    end
end
    