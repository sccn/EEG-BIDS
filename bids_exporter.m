function bids_exporter(varargin)
    if nargin == 0
        [res userdata err structout] = inputgui('geometry', { 1 }, 'uilist', ...
                                  { { 'style' 'text' 'string' 'BIDS exporter tool' }});
        
        if isempty(err), return; end
        [STUDY, ALLEEG] = pop_studywizard();
        
        if ~isempty(ALLEEG)
            pop_exportbids(STUDY, ALLEEG)
        end
    elseif nargin == 1 && exist(varargin{1}, 'file')
        pop_runscript(varargin{1});
    end