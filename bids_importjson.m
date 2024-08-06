% bids_importjson - Import json file following BIDS key-based inheritance rule
%                   (https://bids-specification.readthedocs.io/en/stable/common-principles.html#the-inheritance-principle)
%
% Usage:
%    curjsondata = bids_importjson(curFile, ext)
%
% Inputs:
%  curFile      - [string] full path to the current json file
%  ext          - [string] BIDS post fix extension of the file. 
%                 e.g. _events.json
%
% Outputs:
%   curjsondata     - [struct] json data imported as matlab structure
%
% Author: Dung Truong, 2024
function curjsondata = bids_importjson(curFile, ext, oriFile)
    if nargin < 1
       help bids_importjson
       return
    end
    if nargin < 2
        % no extension is provided. Default to using the filename
        splitted = strsplit(curFile, '_');
        ext = ['_' splitted{end}];
    end
    if nargin < 3
        % no extension is provided. Default to using the filename
        oriFile = curFile;
    end
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
        % resolve wildcard if applicable
        upperFileDir = dir(upperFile);
        if ~isempty(upperFileDir)
            for u=1:numel(upperFileDir)
                % check using rule 2.b and 2.c
                % of https://bids-specification.readthedocs.io/en/stable/common-principles.html#the-inheritance-principle
                upperFileName = upperFileDir(u).name;
                upperFileName_parts = strsplit(upperFileName, '_');
                if contains(oriFile, upperFileName_parts)
                    upperFile = fullfile(upperFileDir(u).folder, upperFileDir(u).name);
                    break
                end
            end
        end
        upperjsondata = bids_importjson(upperFile, ext, oriFile);
        
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
                    if ~files(f).isdir && (strcmp(files(f).name, 'README') || strcmp(files(f).name, 'dataset_description.json'))
                        res = true;
                        return
                    end
                end
            end
            res = false;
        end
    end
end
    