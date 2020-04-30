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
    fileList = uicontrol(f, 'Style', 'listbox', 'String', listboxString, 'Units', 'normalized', 'Position', [0.03 0.1 0.3 0.8], 'Callback', @listSelectCB);
    uicontrol('Style', 'text', 'string', 'Add BIDS EEG acquisition information', 'Units', 'normalized','FontSize',13,'FontWeight','bold','BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.9 0.4 0.05]);
    uicontrol('Style', 'text', 'string', 'Cap manufacturer', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.83 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'CapManufacturer', 'Units', 'normalized', 'Position', [0.78 0.83 0.2 0.05], 'Callback', @editedCB);
    uicontrol('Style', 'text', 'string', 'Cap model name', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.77 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'CapManufacturersModelName', 'Units', 'normalized', 'Position', [0.78 0.77 0.2 0.05], 'Callback', @editedCB);
    uicontrol('Style', 'text', 'string', 'EEG reference', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.71 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'EEGreference', 'Units', 'normalized', 'Position', [0.78 0.71 0.2 0.05], 'Callback', @editedCB);
    uicontrol('Style', 'text', 'string', 'EEG ground', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.65 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'EEGGround', 'Units', 'normalized', 'Position', [0.78 0.65 0.2 0.05], 'Callback', @editedCB);
    uicontrol('Style', 'text', 'string', 'EEG placement scheme (i.e. 10-20)', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.59 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'EEGEEGPlacementScheme', 'Units', 'normalized', 'Position', [0.78 0.59 0.2 0.05], 'Callback', @editedCB);
    uicontrol('Style', 'text', 'string', 'Amplifier manufacturer', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.53 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'Manufacturer', 'Units', 'normalized', 'Position', [0.78 0.53 0.2 0.05], 'Callback', @editedCB);    
    uicontrol('Style', 'text', 'string', 'Amplifier model', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.47 0.4 0.05], 'Callback', @editedCB);
    uicontrol('Style', 'edit', 'string', '','tag', 'ManufacturersModelName', 'Units', 'normalized', 'Position', [0.78 0.47 0.2 0.05], 'Callback', @editedCB); 
    uicontrol('Style', 'text', 'string', 'Amplifier serial number', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.41 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'DeviceSerialNumber', 'Units', 'normalized', 'Position', [0.78 0.41 0.2 0.05], 'Callback', @editedCB);    
    uicontrol('Style', 'text', 'string', 'Acquisition software version', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.35 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'SoftwareVersions', 'Units', 'normalized', 'Position', [0.78 0.35 0.2 0.05], 'Callback', @editedCB);    
    uicontrol('Style', 'text', 'string', 'Hardware filters', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.29 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'HardwareFilters', 'Units', 'normalized', 'Position', [0.78 0.29 0.2 0.05], 'Callback', @editedCB);   
    uicontrol('Style', 'text', 'string', 'Software filters (freeform explanation)', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.23 0.4 0.05]);
    uicontrol('Style', 'edit', 'string', '','tag', 'SoftwareFilters', 'Units', 'normalized', 'Position', [0.78 0.23 0.2 0.05], 'Callback', @editedCB); 
    uicontrol('Style', 'text', 'string', 'Country power line frequency', 'Units', 'normalized','FontSize',13,'BackgroundColor',bg,'ForegroundColor',fg,'HorizontalAlignment','left', 'Position', [0.38 0.17 0.4 0.05]);
    uicontrol('Style', 'popupmenu', 'string', {'Select','50','60'},'tag', 'PowerLineFrequency', 'Units', 'normalized', 'Position', [0.78 0.17 0.2 0.05], 'Callback', @editedCB); 
    
    % buttons
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Help', 'FontSize',13, 'Units', 'normalized', 'Position', [0.38 0.02 0.12 0.05], 'Callback', @helpCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Ok', 'FontSize',13, 'Units', 'normalized', 'Position', [0.85 0.02 0.12 0.05], 'Callback', @okCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Cancel', 'FontSize',13, 'Units', 'normalized', 'Position', [0.7 0.02 0.12 0.05], 'Callback', @cancelCB); 
    
    eegBIDS = newEEGBIDS();

    % wait
    waitfor(f);
    
    function listSelectCB(src,event) 
       selected = src.String{src.Value};
       % update GUI data
       objs = findall(f);
       for o=1:numel(objs)
            if ~isempty(objs(o).Tag)
                if strcmp(objs(o).Style, 'popupmenu')
                    % if there's saved filter value, set popupmenu to
                    % select it
                    filter = eegBIDS(strcmp({eegBIDS.filename}, selected)).tInfo.(objs(o).Tag);
                    if isempty(filter) || strcmp(filter, 'Select')
                        objs(o).Value = find(strcmp(objs(o).String,'Select'));
                    else
                        objs(o).Value = find(strcmp(objs(o).String,filter));
                    end
                else
                    objs(o).String = eegBIDS(strcmp({eegBIDS.filename}, selected)).tInfo.(objs(o).Tag);
                end
            end
       end
       h = findobj('tag', 'EEGreference');
       h = h(1);
       if ~strcmp(selected, 'All') && isempty(eegBIDS(strcmp({eegBIDS.filename}, selected)).tInfo.EEGreference)
           h.String = ALLEEG(strcmp(sets,selected)).ref;
           tmpsrc = [];
           tmpsrc.Style = 'edit';
           tmpsrc.String = h.String;
           tmpsrc.Tag = 'EEGreference';
           editedCB(tmpsrc,'');
       end
       uicontrol(f, 'Style', 'text', 'String', selected, 'Units', 'normalized', 'Position',[0.02 0 0.34 0.08], 'HorizontalAlignment', 'left', 'FontSize',11,'FontAngle','italic','ForegroundColor', fg,'BackgroundColor', bg);
    end
    function helpCB(src,event)
        pophelp('pop_eegacqinfo()');
    end
    function okCB(src,event)
        filenames = {eegBIDS.filename};
        for i=1:numel(ALLEEG)
            if ~isfield(ALLEEG(i), 'BIDS')
                ALLEEG(i).BIDS = [];
            end
            
            % finalize tInfo information for this set
            objs = findall(f);
            for o=1:numel(objs)
                 tag = objs(o).Tag;
                 if ~isempty(tag)
                     % if individual set doesn't contain value for the tag
                     % then use value of 'All'
                     if isempty(eegBIDS(strcmp(filenames, ALLEEG(i).filename)).tInfo.(tag))
                         eegBIDS(strcmp(filenames, ALLEEG(i).filename)).tInfo.(tag) = eegBIDS(strcmp(filenames,'All')).tInfo.(tag);
                     end   
                 end
            end
            
            ALLEEG(i).BIDS.tInfo = eegBIDS(strcmp(filenames, ALLEEG(i).filename)).tInfo;
        end
        
        close(f);
    end
    function cancelCB(src, event)
        close(f);
    end
    
    function editedCB(src,event)
        selected = fileList.String{fileList.Value};
        bidsFileNames = {eegBIDS.filename};
        if strcmp(src.Style, 'popupmenu')
            input = src.String{src.Value};
        else
            input = src.String;
        end
        eegBIDS(strcmp(bidsFileNames, selected)).tInfo.(src.Tag) = input;
    end

    function bidsArray = newEEGBIDS()
        objs = findall(f);
        bidsArray = [];
        allEEG = [];
        allEEG.filename = 'All'; % same name appeared in listbox
        tInfo = [];
        for o=1:numel(objs)
            if ~isempty(objs(o).Tag)
                tInfo.(objs(o).Tag) = '';
            end
        end
        allEEG.tInfo = tInfo;
        bidsArray = [bidsArray allEEG];
        
        for i=1:numel(ALLEEG)
            bids = [];
            bids.filename = ALLEEG(i).filename;
            tInfo = [];
            if isfield(ALLEEG(i), 'BIDS')
                bids = ALLEEG(i).BIDS;
                if isfield(bids, 'tInfo')
                    tInfo = bids.tInfo;
                end
            end

            for o=1:numel(objs)
                if ~isempty(objs(o).Tag)
                    tInfo.(objs(o).Tag) = '';
                end
            end
            bids.tInfo = tInfo;
            bidsArray = [bidsArray bids];
        end
    end

% history
% -------
% if nargin < 2
%     com = sprintf('pop_exportbids(STUDY, %s);', vararg2str(options));
% end
end