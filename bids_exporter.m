function bids_exporter(varargin)
    if nargin == 0
        str = [  'This tool allows you to select binary EEG files' 10 ...
                 'and format them to a BIDS dataset. For more information' 10 ...
                 'see the online help at https://eegbids.org'];

        [res userdata err structout] = inputgui('geometry', { 1 1 }, 'geomvert', [1 3], 'uilist', ...
                                  { { 'style' 'text' 'string' 'Welcome to the EEG-BIDS exporter tool!' 'fontweight' 'bold' }  { 'style' 'text' 'string' str } }, 'okbut', 'continue');
        
        if isempty(err), return; end
        [STUDY, ALLEEG] = pop_studywizard();

        % task Name
        taskName = '';
        if ~isfield(ALLEEG, 'task') || isempty(ALLEEG(1).task)
            res = inputgui('geom', { {2 1 [0 0] [1 1]} {2 1 [1 0] [1 1]} }, 'uilist', ...
                { { 'style' 'text' 'string' 'Enter the task name' } ...
                { 'style' 'edit' 'string' '' } });
            if ~isempty(res) && ~isempty(res{1})
                taskName = res{1};
            else
                errordlg('Operation aborted as a task name is required')
            end
        end
        
        if ~isempty(ALLEEG)
            pop_exportbids(STUDY, ALLEEG, 'taskName', taskName)
        end
    elseif nargin == 1 && exist(varargin{1}, 'file')
        pop_runscript(varargin{1});
    end