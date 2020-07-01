function [STUDY, ALLEEG] = pop_checkdatasetinfo(STUDY, ALLEEG)
    datasetinfo = STUDY.datasetinfo;
    different = 0;
    for k = 1:length(ALLEEG)
       if ~strcmpi(datasetinfo(k).filename, ALLEEG(k).filename), different = 1; break; end
       if ~strcmpi(datasetinfo(k).subject,   ALLEEG(k).subject),   different = 1; break; end
       if ~strcmpi(datasetinfo(k).condition, ALLEEG(k).condition), different = 1; break; end
       if ~strcmpi(char(datasetinfo(k).group), char(ALLEEG(k).group)),     different = 1; break; end       
       if ~isequal(datasetinfo(k).session, ALLEEG(k).session),             different = 1; break; end
       if ~isequal(datasetinfo(k).run, ALLEEG(k).run),                     different = 1; break; end
    end
    
    if different
          supergui( 'geomhoriz', { 1 1 1 [1 1] }, 'uilist', { ...
         { 'style', 'text', 'string', 'Information between STUDY and single datasets is inconsistent.', 'HorizontalAlignment','center'},...
         { 'style', 'text', 'string', 'Would you like to overwrite dataset information with STUDY information and use that for BIDS?','HorizontalAlignment', 'center'}, { }, ...
         { 'style', 'pushbutton' , 'string', 'Yes', 'callback', @yesCB}, { 'style', 'pushbutton' , 'string', 'No', 'callback', @noCB } } );
         waitfor(gcf);
    end
    
    function yesCB(src, event)
        [STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'updatedat', 'on');
        supergui( 'geomhoriz', { 1 1 1 }, 'uilist', { ...
        { 'style', 'text', 'string', 'Information updated. Resave dataset(s) if you want to save the information on disk', 'HorizontalAlignment', 'center'}, { }, ...
        { 'style', 'pushbutton', 'string', 'Ok', 'callback', 'close(gcf);'}});
        waitfor(gcf);
        close(gcf); 
    end
    function noCB(src,event)
        close(gcf);
    end
end