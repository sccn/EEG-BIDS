% bids_checkfields() - Check BIDS fields
%
% Usage:
%   >> struct = bids_checkfields(struct, fielddefs, fieldname);
%
% Inputs:
%   struct    - [struct] structure with defined fields
%   fielddefs - [fielddefs] field definition
%   fieldname - [string] structure name
%
% Outputs:
%   struct   - checked structure
%
% Authors: Arnaud Delorme, SCCN, INC, UCSD, January, 2023

% Copyright (C) Arnaud Delorme, 2023
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
% along with this program; if not, to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% check the fields for the structures
% -----------------------------------
function s = bids_checkfields(s, f, structName)

fields = fieldnames(s);
diffFields = setdiff(fields, f(:,1)');
if ~isempty(diffFields)
    fprintf('Warning: Ignoring invalid field name(s) "%s" for structure %s\n', sprintf('%s ',diffFields{:}), structName);
    s = rmfield(s, diffFields);
end
for iRow = 1:size(f,1)
    if strcmp(structName,'tInfo') && strcmp(f{iRow,1}, 'EEGReference') && ~isa(s.(f{iRow,1}), 'char')
        s.(f{iRow,1}) = char(s.(f{iRow,1}));
    end
    if isempty(s) || ~isfield(s, f{iRow,1})
        if strcmpi(f{iRow,2}, 'required') % required or optional
            if ~iscell(f{iRow,4}) && ~isstruct(f{iRow,4})
                fprintf('Warning: "%s" set to %s\n', f{iRow,1}, num2str(f{iRow,4}));
            end
            s = setfield(s, {1}, f{iRow,1}, f{iRow,4});
        end
    elseif ~isempty(f{iRow,3}) && ~isa(s.(f{iRow,1}), f{iRow,3}) && ~strcmpi(s.(f{iRow,1}), 'n/a')
        % if it's HED in eInfoDesc, allow string also
        if strcmp(structName,'eInfoDesc') && strcmp(f{iRow,1}, 'HED') && isa(s.(f{iRow,1}), 'char')
            return
        end
        error(sprintf('Parameter %s.%s must be a %s', structName, f{iRow,1}, f{iRow,3}));
    end
end
