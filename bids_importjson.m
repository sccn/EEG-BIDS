
% Import json file following BIDS key-based inheritance rule
function curjsondata = bids_importjson(curFile, ext)
    if isempty(curFile)
        curjsondata = [];
    else
        curjsondata = readjson(curFile);
    end
    if ~isTopLevel(fileparts(curFile))
        upperFile = dir(fullfile(fileparts(fileparts(curFile)), ext));
        if ~isempty(upperFile)
            upperjsondata = importBIDSJson(fullfile(upperFile(1).folder, upperFile(1).name), ext);
            fields = fieldnames(upperjsondata);
            for i=1:numel(fields)
                if ~isfield(curjsondata, fields{i})
                    curjsondata.(fields{i}) = upperjsondata.(fields{i});
                end
            end
        end        
    end

    function res = readjson(file)
        if exist('jsondecode.m','file')
            res = jsondecode( importalltxt( file ));
        else
            res = jsonread(file);
        end
    end
    % Import full text file
    % ---------------------
    function str = importalltxt(fileName)
    
    str = [];
    fid =fopen(fileName, 'r');
    while ~feof(fid)
        str = [str 10 fgetl(fid) ];
    end
    str(1) = [];
    end
    function res = isTopLevel(curpath)
        res = false;
        files = dir(curpath);
        if ~isempty(files)
            for f=1:numel(files)
                if ~files(f).isdir && strcmp(files(f).name, 'README')
                    res = true;
                    return
                end
            end
        end
    end
end
    