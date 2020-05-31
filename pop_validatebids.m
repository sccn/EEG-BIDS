function pop_validatebids()
    if ismac
        validator = 'bids-validator-macos';   
    elseif isunix
        validator = 'bids-validator-linux';
    elseif ispc
        validator = 'bids-validator-win.exe';
    end
    filepath = fullfile(fileparts(which('pop_exportbids')), validator);
    checkValidator();
    if ~isfile(filepath)
        supergui('geomhoriz', {[1] [1] [1]}, 'geomvert', [1 1 1], 'uilist', {{'Style','text','string','No validator found. Abort'},...
                                                                              {}, ...
                                                                              { 'Style', 'pushbutton', 'string', 'Ok' 'callback' 'close(gcf)' }}, 'title','Error -- pop_validatebids()');
        waitfor(gcf);
    else
        com = [ 'bidsFolderxx = uigetdir(''Pick a BIDS output folder'');' ...
            'if ~isequal(bidsFolderxx, 0), set(findobj(gcbf, ''tag'', ''outputfolder''), ''string'', bidsFolderxx); end;' ...
            'clear bidsFolderxx;' ];
        uilist = { ...
        { 'Style', 'text', 'string', 'Validate BIDS dataset', 'fontweight', 'bold'  }, ...
        {} ...
        { 'Style', 'text', 'string', 'BIDS folder:' }, ...
        { 'Style', 'edit', 'string',   fullfile('.', 'BIDS_EXPORT') 'tag' 'outputfolder' }, ...
        { 'Style', 'pushbutton', 'string', '...' 'callback' com }, ...
        { 'Style', 'text', 'string', '' }, ...
        { 'Style', 'pushbutton', 'string', 'Validate' 'tag' 'validateBtn' 'callback' @validateCB }, ...
        { 'Style', 'text', 'string', ''}, ...
        };
        geometry = { [1] [1] [0.2 0.7 0.1] [1 1 1] };
        geomvert =   [1  1 1  1];
        [results,userdata,~,restag] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', uilist, 'helpcom', 'pophelp(''pop_validatebids'');', 'title', 'Validate BIDS dataset-- pop_validatebids()');
    end
    function validateCB(src, event)
        obj = findobj('Tag','outputfolder');
        dir = obj.String;
        system([filepath ' ' dir]); edit eegplugin_bids.m
    end

    function checkValidator()
        if ~isfile(filepath)
            gitpath = ['https://raw.githubusercontent.com/sccn/bids-matlab-tools/validator/' validator];
            [status,fileSize] = system(['curl -sI ' gitpath ' | grep -i Content-Length | cut -d'' '' -f2 | tr -d ''\r''']);
            if status == 0
                fileSize = round(str2double(fileSize)/1024/1024);
                downloadcom = sprintf('system(''curl -o %s %s''); system(''chmod u+x %s'');close(gcf);',filepath, gitpath); 
                cancelcom = 'close(gcf);';
                supergui('geomhoriz', {[1] [1] [1 1]}, 'geomvert', [1 1 1], 'uilist', {{'Style','text','string',['The validator needs to be downloaded, which will consume ' num2str(fileSize) ' MB of disk space. Would you like to continue?']},...
                                                                              {}, ...
                                                                              { 'Style', 'pushbutton', 'string', 'Cancel' 'callback' cancelcom },...
                                                                              { 'Style', 'pushbutton', 'string', 'Yes' 'callback' downloadcom }}, 'title','Download validator -- pop_validatebids()');
                waitfor(gcf);
            else
                errordlg('Unable to download validator using curl');
            end
        end 
    end
end
