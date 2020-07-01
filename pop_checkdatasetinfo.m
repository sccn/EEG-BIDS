function pop_checkdatasetinfo(STUDY, ALLEEG)
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
          supergui( 'geomhoriz', { 1 1 [1 1] }, 'uilist', { ...
         { 'style', 'text', 'string', 'Information between STUDY and single datasets is inconsistent. Would you like to overwrite dataset information with STUDY information and use that for BIDS?' }, { }, ...
         { 'style', 'pushbutton' , 'string', 'Yes', 'callback', @yesCB}, { 'style', 'pushbutton' , 'string', 'No', 'callback', @noCB } } );
    end
    
    function yesCB(src, event)
        close(gcf); 
    end
    function noCB(src,event)
        close(gcf);
    end
end