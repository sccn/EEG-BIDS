% eegplugin_bids() - EEGLAB plugin for importing data saved
%             by the finders course (Matlab converted)
%
% Usage:
%   >> eegplugin_bids(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.

function vers = eegplugin_bids(fig, trystrs, catchstrs)

    vers = '2.0';
    if nargin < 3
        error('eegplugin_bids requires 3 arguments');
    end
    
    % add folder to path
    % ------------------
    p = which('pop_importbids.m');
    p = p(1:findstr(p,'pop_importbids.m')-1);
    if ~exist('pop_importbids')
        addpath( p );
    end
    
    % find import data menu
    % ---------------------
    menui1 = findobj(fig, 'tag', 'import data');
    menui2 = findobj(fig, 'tag', 'export');
    
    % menu callbacks
    % --------------
    comcnt1 = [ trystrs.no_check '[STUDYTMP, ALLEEGTMP, ~, LASTCOM] = pop_importbids; '  catchstrs.load_study ];
    comcnt2 = [ trystrs.no_check 'pop_exportbids(STUDY);' catchstrs.add_to_hist ];
                
    % create menus
    % ------------
    uimenu( menui1, 'label', 'From BIDS folder structure', 'separator', 'on', 'callback', comcnt1);
    uimenu( menui2, 'label', 'To BIDS folder structure', 'separator', 'on', 'callback', comcnt2, 'userdata', 'startup:off;study:on');
    set(menui2, 'userdata', 'startup:off;study:on');
