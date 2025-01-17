% BIDS_COMPARE - compare two BIDS folders.
%
% Usage:
%   eeg_compare(folder1, folder2, errorFlag);
%
% Input:
%  folder1   - [string] first BIDS folder
%  folder2   - [string] second BIDS folder
%  errorFlag - [true|false] generate error if true (warning if false)
%
% Author: Arnaud Delorme, 2023

% Copyright (C) 2023 Arnaud Delorme
%
% This file is part of EEGLAB, see http://www.eeglab.org
% for the documentation and details.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.


function bids_compare(oridir, targetdir, errorFlag)

if nargin < 2
    help bids_compare
    return
end
if nargin < 3
    errorFlag = false;
end

dir1 = dir(oridir);
if isempty(dir1)
    fprintf(2, 'BIDS compare, directory empty %s\n', oridir)
    return
end
dir2 = dir(targetdir);
if isempty(dir1)
    fprintf(2, 'BIDS compare, directory empty %s\n', targetdir)
end

allDir2Folder = { dir2.folder };
allDir2Name   = { dir2.name };
[allDir2Name,dir2]   = generate_variation(allDir2Name, dir2);
listNotFound  = {};
for iDir = 1:length(dir1)
    if ~isequal(dir1(iDir).name(1), '.')
        indMatch = strmatch(dir1(iDir).name, allDir2Name, 'exact');
        relfolder1 = relativeFolder(dir1(iDir    ).folder, oridir);
        fullFileName1 = fullfile(relfolder1, dir1(iDir).name);
        if length(indMatch) ~= 1
            if ~contains(oridir, 'code') && ~contains(oridir, 'derivatives') && ~contains(fullFileName1, '.fdt') && ~contains(fullFileName1, 'derivatives')
                listNotFound{end+1} = fullfile(oridir, fullFileName1);
            end
        else
            relfolder2 = relativeFolder(dir2(indMatch).folder, targetdir);
            if ~isequal(relfolder1, relfolder2)
                listNotFound{end+1} = fullfile(oridir, fullFileName1);
            else
                if dir1(iDir).isdir
                    fullFileName2 = fullfile(relfolder2, dir2(indMatch).name);
                    bids_compare(fullfile(oridir, fullFileName1), fullfile(targetdir, fullFileName2));
                end
            end
        end
    end
end

if ~isempty(listNotFound)
    %for iFile = 1:min(length(listNotFound),10)
    for iFile = 1:length(listNotFound)
        fprintf('File/folder %s not found in second folder\n', listNotFound{iFile});
    end
    if length(listNotFound) > 10
        fprintf('... and more\n');
    end
    if errorFlag
        error('BIDS folder do not match')
    end
else
    fprintf('   Files found to match\n')
end

function outstr = relativeFolder( folder, parentFolder )

strPos = strfind(folder, parentFolder);
if isempty(strPos)
    error('Issue with string searching')
end
outstr = folder(strPos+length(parentFolder):end);

% generate variation to account for different runs and session formating
% -------
function [dirstr,dirs] = generate_variation(dirstr, dirs)

for iDir = 1:length(dirstr)
    if length(dirstr{iDir}) > 4
        ind = strfind(dirstr{iDir}, 'ses-');
        if ~isempty(ind)
            endstr = dirstr{iDir}(ind(1)+4:end);
            dirstr{end+1} = [ dirstr{iDir}(1:ind(1)+3) '0' endstr ];
            dirstr{end+1} = [ dirstr{iDir}(1:ind(1)+3) '00' endstr ];
            dirs(end+1) = dirs(iDir);
            dirs(end+1) = dirs(iDir);
        end
    end
end
for iDir = 1:length(dirstr)
    if length(dirstr{iDir}) > 4
        ind = strfind(dirstr{iDir}, 'run-');
        if ~isempty(ind)
            endstr = dirstr{iDir}(ind(1)+4:end);
            dirstr{end+1} = [ dirstr{iDir}(1:ind(1)+3) '0' endstr ];
            dirstr{end+1} = [ dirstr{iDir}(1:ind(1)+3) '00' endstr ];
            dirs(end+1) = dirs(iDir);
            dirs(end+1) = dirs(iDir);
        end
    end
end


