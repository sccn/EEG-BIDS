% pop_taskinfo() - BIDS task information
%
% Usage:
%     STUDY = pop_taskinfo(STUDY);
%
% Inputs:
%   STUDY - EEGLAB study
%
%
% Authors: Arnaud Delorme, Dung Truong SCCN, INC, UCSD, 2020

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

function [STUDY,com] = pop_taskinfo(STUDY)

    bg = [0.65 0.76 1];
    fg = [0 0 0.4];
    f = figure('MenuBar', 'None', 'ToolBar', 'None', 'Name', 'BIDS task information -- pop_taskinfo()', 'Color', bg, 'IntegerHandle','off');
    f.Position(3) = 400;
    f.Position(4) = 650;
    uicontrol('Style', 'text', 'string', 'Add BIDS task information', 'fontweight', 'bold', 'fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.9 1 0.05]);
    uicontrol('Style', 'text', 'string', 'Participant task description (describe experiment):','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.85 1 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'TaskDescription', 'HorizontalAlignment', 'left', 'max', 3,'Units', 'normalized', 'Position', [0.05 0.68 0.9 0.18]);
    uicontrol('Style', 'text', 'string', 'Participant instructions (as exact as possible):','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.62 1 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'Instructions', 'HorizontalAlignment', 'left', 'max', 3,'Units', 'normalized', 'Position', [0.05 0.45 0.9 0.18]);
    cm = uicontextmenu(f);
    m1 = uimenu(cm,'Text','Lookup CognitiveAtlas TermURL','MenuSelectedFcn',{@btnCB,'http://www.cognitiveatlas.org/tasks/a/'});
    tooltip = sprintf('URL of the corresponding Cognitive Atlas term that describes the task.\nRight click to lookup.');
    uicontrol('Style', 'text', 'string', 'Task-relevant Cognitive Atlas term', 'Tooltip',tooltip,'UIContextMenu', cm,'fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.38 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'CogAtlasID','Units', 'normalized', 'Position', [0.6 0.38 0.35 0.05]);
    cm = uicontextmenu(f);
    m1 = uimenu(cm,'Text','Lookup CogPO TermURL','MenuSelectedFcn',{@btnCB,'http://wiki.cogpo.org/index.php?title=Main_Page'});
    tooltip = sprintf('URL of the corresponding CogPO term that describes the task.\nRight click to lookup.');
    uicontrol('Style', 'text', 'string', 'Task-relevant CogPO term', 'Tooltip',tooltip,'UIContextMenu', cm,'fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.32 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'CogPOID','Units', 'normalized', 'Position', [0.6 0.32 0.35 0.05]);
    uicontrol('Style', 'text', 'string', 'Institution','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.26 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'InstitutionName','Units', 'normalized', 'Position', [0.6 0.26 0.35 0.05]);  
    uicontrol('Style', 'text', 'string', 'Department','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.2 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'InstitutionalDepartmentName','Units', 'normalized', 'Position', [0.6 0.2 0.35 0.05]);    
    uicontrol('Style', 'text', 'string', 'Institution address/location','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.14 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'InstitutionAddress','Units', 'normalized', 'Position', [0.6 0.14 0.35 0.05]);        
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Help', 'FontSize',13, 'Units', 'normalized', 'Position', [0.05 0.02 0.2 0.05], 'Callback', @helpCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Ok', 'FontSize',13, 'Units', 'normalized', 'Position', [0.75 0.02 0.2 0.05], 'Callback', @okCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Cancel', 'FontSize',13, 'Units', 'normalized', 'Position', [0.5 0.02 0.2 0.05], 'Callback', @cancelCB); 

% history
com = sprintf('pop_exportbids(STUDY);');

    function btnCB(src,event, url)
       web(url);
    end
    function helpCB(src,event)
        pophelp('pop_taskinfo');
    end
    function okCB(src,event)
        bids = [];
        tInfo = [];
        % preserve current BIDS info if have
        if isfield(STUDY, 'BIDS')
            bids = STUDY.BIDS;
            if isfield(bids, 'tInfo')
                tInfo = bids.tInfo;
            end
        end
        % update tInfo from input fields
        objs = findall(f);
        for i=1:numel(objs)
            if ~isempty(objs(i).Tag)
                if ~isempty(objs(i).String)
                    tInfo.(objs(i).Tag) = objs(i).String;
                end
            end
        end
        % update STUDY BIDS structure
        bids.tInfo = tInfo;
        STUDY.BIDS = bids;
        close(f);
    end
    function cancelCB(src, event)
        close(f);
    end
end