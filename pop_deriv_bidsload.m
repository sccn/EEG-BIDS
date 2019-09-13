% Function in development. Eventually meant to auto-detect parent files for
% derivatives.

function EEG = pop_deriv_bidsload(fileLocation,varargin)
    [fPath,fName,fType] = fileparts(fileLocation);
    localFiles = dir(fPath);
    
    disp('Checking derivative for events and electrodes file');
    eventID = 0;
    elecID = 0;
    for i=1:length(localFiles)
        if strfind(localFiles(i).name,'events.tsv')
            eventID = i;
        elseif strfind(localFiles(i).name,'electrodes.tsv')
            elecID = i;
        end
    end
    eventID
    elecID
end