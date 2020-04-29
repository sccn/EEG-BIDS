% pop_eegacqinfo() - BIDS EEG system information
%
% Usage:
%     EEG = pop_eegacqinfo(EEG, 'key', val);
%
% Inputs:
%   EEG - EEGLAB dataset or group of dataset
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

function [ALLEEG,com] = pop_eegacqinfo(ALLEEG, varargin)

    bg = [0.65 0.76 1];
    fg = [0 0 0.4];
    f = figure('MenuBar', 'None', 'ToolBar', 'None', 'Name', 'BIDS EEG data acquisition information -- pop_eegacqinfo()', 'Color', bg, 'IntegerHandle','off');
    f.Position(3) = 600;
    f.Position(4) = 500;
    sets = {ALLEEG.filename}; %arrayfun(@(x) fullfile(x.filepath, x.filename),ALLEEG, 'UniformOutput', 'false');
    if numel(sets) == 1
        listboxString = sets;
    else
        listboxString = ['All' sets];
    end
    uicontrol('Style', 'text', 'string', 'Select set', 'Units', 'normalized','FontSize',13,'FontWeight','bold','BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.03 0.9 0.4 0.05]);
    list = uicontrol(f, 'Style', 'listbox', 'String', listboxString, 'Units', 'normalized', 'Position', [0.03 0.1 0.3 0.8], 'Callback', @listSelectCB);
    uicontrol('Style', 'text', 'string', 'Add BIDS EEG acquisition information', 'Units', 'normalized','FontSize',13,'FontWeight','bold','BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.9 0.4 0.05]);
    uicontrol('Style', 'text', 'string', 'Cap manufacturer', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.83 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'CapManufacturer', 'Units', 'normalized', 'Position', [0.78 0.83 0.2 0.05]);
    uicontrol('Style', 'text', 'string', 'Cap model name', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.77 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'CapManufacturersModelName', 'Units', 'normalized', 'Position', [0.78 0.77 0.2 0.05]);
    uicontrol('Style', 'text', 'string', 'EEG reference', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.71 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'EEGreference', 'Units', 'normalized', 'Position', [0.78 0.71 0.2 0.05]);
    uicontrol('Style', 'text', 'string', 'EEG ground', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.65 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'EEGGround', 'Units', 'normalized', 'Position', [0.78 0.65 0.2 0.05]);
    uicontrol('Style', 'text', 'string', 'EEG placement scheme (i.e. 10-20)', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.59 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'EEGEEGPlacementScheme', 'Units', 'normalized', 'Position', [0.78 0.59 0.2 0.05]);
    uicontrol('Style', 'text', 'string', 'Amplifier manufacturer', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.53 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'Manufacturer', 'Units', 'normalized', 'Position', [0.78 0.53 0.2 0.05]);    
    uicontrol('Style', 'text', 'string', 'Amplifier model', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.47 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'ManufacturersModelName', 'Units', 'normalized', 'Position', [0.78 0.47 0.2 0.05]); 
    uicontrol('Style', 'text', 'string', 'Amplifier serial number', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.41 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'DeviceSerialNumber', 'Units', 'normalized', 'Position', [0.78 0.41 0.2 0.05]);    
    uicontrol('Style', 'text', 'string', 'Acquisition software version', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.35 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'SoftwareVersions', 'Units', 'normalized', 'Position', [0.78 0.35 0.2 0.05]);    
    uicontrol('Style', 'text', 'string', 'Hardware filters', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.29 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', 'n/a','tag', 'HardwareFilters', 'Units', 'normalized', 'Position', [0.78 0.29 0.2 0.05]);   
    uicontrol('Style', 'text', 'string', 'Software filters (freeform explanation)', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.23 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', 'n/a','tag', 'SoftwareFilters', 'Units', 'normalized', 'Position', [0.78 0.23 0.2 0.05]); 
    uicontrol('Style', 'text', 'string', 'Country power line frequency', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.17 0.4 0.05]);
    uicontrol('Style', 'popupmenu', 'string', '50|60','tag', 'PowerLineFrequency', 'Units', 'normalized', 'Position', [0.78 0.17 0.2 0.05]); 
    
    % buttons
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Help', 'FontSize',13, 'Units', 'normalized', 'Position', [0.38 0.02 0.12 0.05], 'Callback', @helpCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Ok', 'FontSize',13, 'Units', 'normalized', 'Position', [0.85 0.02 0.12 0.05], 'Callback', @okCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Cancel', 'FontSize',13, 'Units', 'normalized', 'Position', [0.7 0.02 0.12 0.05], 'Callback', @cancelCB); 
%         { 'Style', 'edit', 'string', '' 'tag' 'CapManufacturer' }, ...
    function listSelectCB(src,event) 
       h = findobj('tag', 'EEGreference');
       h = h(1);
       selected = src.String{src.Value};
       if ~strcmp(selected, 'All')
           h.String = ALLEEG(strcmp(sets,selected)).ref;
       end
       uicontrol(f, 'Style', 'text', 'String', src.String{src.Value}, 'Units', 'normalized', 'Position',[0.02 0 0.34 0.08], 'HorizontalAlignment', 'left', 'FontSize',11,'FontAngle','italic','ForegroundColor', fg,'BackgroundColor', bg);
    end
    function helpCB(src,event)
        pophelp('pop_eegacqinfo()');
    end
    function okCB(src,event)
%         bids = [];
%         tInfo = [];
%         % preserve current BIDS info if have
%         if isfield(STUDY, 'BIDS')
%             bids = STUDY.BIDS;
%             if isfield(bids, 'tInfo')
%                 tInfo = bids.tInfo;
%             end
%         end
%         % update tInfo from input fields
%         objs = findall(f);
%         for i=1:numel(objs)
%             if ~isempty(objs(i).Tag)
%                 if ~isempty(objs(i).String)
%                     tInfo.(objs(i).Tag) = objs(i).String;
%                 end
%             end
%         end
%         % update STUDY BIDS structure
%         bids.tInfo = tInfo;
%         STUDY.BIDS = bids;
        close(f);
    end
    function cancelCB(src, event)
        close(f);
    end
% if nargin < 2
%     uilist = { ...
%         { 'Style', 'text', 'string', 'BIDS EEG acquisition information', 'fontweight', 'bold'  }, ...
%         {} ...
%         {} {} ...
%         { 'Style', 'text', 'string', 'Cap manufacturer:' }, ...
%         { 'Style', 'edit', 'string', '' 'tag' 'CapManufacturer' }, ...
%         { 'Style', 'text', 'string', 'Cap model name:' }, ...
%         { 'Style', 'edit', 'string', '' 'tag' 'CapManufacturersModelName' }, ...
%         { 'Style', 'text', 'string', 'EEG reference:' }, ...
%         { 'Style', 'edit', 'string', EEG(1).ref 'tag' 'EEGreference' }, ...
%         { 'Style', 'text', 'string', 'EEG ground:' }, ...
%         { 'Style', 'edit', 'string', '' 'tag' 'EEGGround' }, ...
%         { 'Style', 'text', 'string', 'EEG placement scheme (i.e. 10-20):' }, ...
%         { 'Style', 'edit', 'string', '' 'tag' 'EEGPlacementScheme' }, ...
%         { 'Style', 'text', 'string', 'Amplifier manufacturer:' }, ...
%         { 'Style', 'edit', 'string', '' 'tag' 'Manufacturer' }, ...
%         { 'Style', 'text', 'string', 'Amplifier model:' }, ...
%         { 'Style', 'edit', 'string', '' 'tag' 'ManufacturersModelName' }, ...
%         { 'Style', 'text', 'string', 'Amplifier serial number:' }, ...
%         { 'Style', 'edit', 'string', '' 'tag' 'DeviceSerialNumber' }, ...
%         { 'Style', 'text', 'string', 'Acquisition software version:' }, ...
%         { 'Style', 'edit', 'string', '' 'tag' 'SoftwareVersions' }, ...
%         { 'Style', 'text', 'string', 'Hardware filters:' }, ...
%         { 'Style', 'edit', 'string', 'n/a' 'tag' 'SoftwareFilters' }, ...
%         { 'Style', 'text', 'string', 'Software filters (freeform explanation):' }, ...
%         { 'Style', 'edit', 'string', 'n/a' 'tag' 'SoftwareFilters' }, ...
%         { 'Style', 'text', 'string', 'Country power line frequency:' }, ...
%         { 'Style', 'popupmenu', 'string', '50|60' 'tag' 'PowerLineFrequency' }, ...
%         };
%     geometry = cell(1, length(uilist)/2);
%     geometry(:) = { [1 0.6] };
%     geomvert = ones(1, length(geometry));
%     geomvert(2) = 0.2;
%     [results,userdata,~,restag] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', uilist, 'helpcom', 'pophelp(''pop_eegacqinfo'');', 'title', 'BIDS EEG data acquisition information -- pop_eegacqinfo()');
%     if length(results) == 0, return; end
% 
% else
%     options = varargin;
% end

% history
% -------
% if nargin < 2
%     com = sprintf('pop_exportbids(STUDY, %s);', vararg2str(options));
% end
end