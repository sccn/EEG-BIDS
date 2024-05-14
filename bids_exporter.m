function bids_exporter()
[res userdata err structout] = inputgui('geometry', { 1 }, 'uilist', ...
                          { { 'style' 'text' 'string' 'BIDS exporter tool' }});

if isempty(err), return; end
[STUDY, ALLEEG] = pop_studywizard();

if ~isempty(ALLEEG)
    pop_exportbids(STUDY, ALLEEG)
end
