% pop_taskinfo() - BIDS task information
%
% Usage:
%     STUDY = pop_taskinfo(STUDY, 'key', val);
%
% Inputs:
%   STUDY - EEGLAB study
%
% Note: 'key', val arguments are the same as the one in bids_export()
%
% Authors: Arnaud Delorme, SCCN, INC, UCSD, 2020

% Copyright (C) Arnaud Delorme, 2020
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [STUDY,com] = pop_taskinfo(STUDY, varargin)

if nargin < 2
    uilist = { ...
        { 'Style', 'text', 'string', 'BIDS task information', 'fontweight', 'bold'  }, ...
        {} ...
        { 'Style', 'text', 'string', 'Task description (describe experiment):' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'readme' 'HorizontalAlignment' 'left' 'max' 3 }, ...
        { 'Style', 'text', 'string', 'Instruction given to participants:' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'readme' 'HorizontalAlignment' 'left' 'max' 3 }, ...
        { 'Style', 'text', 'string', 'Task relevant Cognitive Atlas:' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'CogAtlasID' }, ...
        { 'Style', 'text', 'string', 'Task relevant CogPO term:' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'CogPOID' }, ...
        { 'Style', 'text', 'string', 'Institution name:' }, ...
        { 'Style', 'edit', 'string',  '' 'tag' 'InstitutionName' }, ...
        { 'Style', 'text', 'string', 'Institution department name:' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'InstitutionalDepartmentName' }, ...
        { 'Style', 'text', 'string', 'Institution address:' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'InstitutionAddress' }, ...
        };
    relSize = 0.7;
    geometry = { [1] [1] 1 1 1 1 [1 relSize] [1 relSize] [1 relSize] [1 relSize] [1 relSize] };
    geomvert =   [1  0.2 1 3 1 3 1           1           1           1           1           ];
    
    [results,~,~,restag] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', uilist, 'helpcom', 'pophelp(''pop_taskinfo'');', 'title', 'BIDS task information -- pop_taskinfo()');
    if length(results) == 0, return; end
    
    fields = fieldnames(restag);
    for iField = 1:length(fields)
        STUDY.BIDS.(fields{iField}) = restag.BIDS.(fields{iField});
    end
else
    options = varargin;
end

% history
% -------
if nargin < 2
    com = sprintf('pop_exportbids(STUDY, %s);', vararg2str(options));
end