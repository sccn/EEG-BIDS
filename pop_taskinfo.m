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

function [STUDY,com] = pop_taskinfo(STUDY)

    bg = [0.65 0.76 1];
    fg = [0 0 0.4];
    f = figure('MenuBar', 'None', 'ToolBar', 'None', 'Name', 'BIDS task information -- pop_taskinfo()', 'Color', bg, 'IntegerHandle','off');
    f.Position(3) = 400;
    f.Position(4) = 600;
    uicontrol('Style', 'text', 'string', 'Add BIDS task information', 'fontweight', 'bold', 'fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.9 1 0.05]);
    uicontrol('Style', 'text', 'string', 'Task description (describe experiment):','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.83 1 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'readme', 'HorizontalAlignment', 'left', 'max', 3,'Units', 'normalized', 'Position', [0.05 0.63 0.9 0.2]);
    uicontrol('Style', 'text', 'string', 'Participant instructions (exact as possible):','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.57 1 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'instruction', 'HorizontalAlignment', 'left', 'max', 3,'Units', 'normalized', 'Position', [0.05 0.38 0.9 0.2]);
    cm = uicontextmenu(f);
    m1 = uimenu(cm,'Text','Lookup CognitiveAtlas TermURL','MenuSelectedFcn',{@btnCB,'http://www.cognitiveatlas.org/tasks/a/'});
    tooltip = sprintf('URL of the corresponding Cognitive Atlas term that describes the task.\nRight click to lookup.');
    uicontrol('Style', 'text', 'string', 'Task-relevant Cognitive Atlas term', 'Tooltip',tooltip,'UIContextMenu', cm,'fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.32 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'CogAtlasID','Units', 'normalized', 'Position', [0.6 0.32 0.35 0.05]);
    cm = uicontextmenu(f);
    m1 = uimenu(cm,'Text','Lookup CogPO TermURL','MenuSelectedFcn',{@btnCB,'http://wiki.cogpo.org/index.php?title=Main_Page'});
    tooltip = sprintf('URL of the corresponding CogPO term that describes the task.\nRight click to lookup.');
    uicontrol('Style', 'text', 'string', 'Task-relevant CogPO term', 'Tooltip',tooltip,'UIContextMenu', cm,'fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.27 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'CogPOID','Units', 'normalized', 'Position', [0.6 0.27 0.35 0.05]);
    uicontrol('Style', 'text', 'string', 'Institution','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.22 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'InstitutionName','Units', 'normalized', 'Position', [0.6 0.22 0.35 0.05]);  
    uicontrol('Style', 'text', 'string', 'Department','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.17 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'InstitutionalDepartmentName','Units', 'normalized', 'Position', [0.6 0.17 0.35 0.05]);    
    uicontrol('Style', 'text', 'string', 'Institution address','fontsize',13,'BackgroundColor',bg,'ForegroundColor',fg, 'HorizontalAlignment','left','Units', 'normalized', 'Position', [0.05 0.12 0.55 0.05]);
    uicontrol('Style', 'edit', 'string', '', 'tag', 'InstitutionAddress','Units', 'normalized', 'Position', [0.6 0.12 0.35 0.05]);        
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Help', 'Units', 'normalized', 'Position', [0.05 0.02 0.2 0.05], 'Callback', @helpCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Ok', 'Units', 'normalized', 'Position', [0.75 0.02 0.2 0.05], 'Callback', @okCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Cancel', 'Units', 'normalized', 'Position', [0.5 0.02 0.2 0.05], 'Callback', @cancelCB); 

% history
com = sprintf('pop_exportbids(STUDY);');

    function btnCB(src,event, url)
       web(url);
    end
    function helpCB(src,event)
        close(f);
    end
    function okCB(src,event)
        close(f);
    end
    function cancelCB(src, event)
        close(f);
    end
end