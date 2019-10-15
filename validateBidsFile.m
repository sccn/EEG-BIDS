% Helper function for grabbing data out of a BIDS tsv given a location
function dataStruct = validateBidsFile(file, fileStruct, fileSuffix)
    if strcmp(fileStruct,'')
        fileStruct = strrep(file,'_eeg.edf',['_' fileSuffix '.tsv']);
        disp(['Assuming local BIDS ' fileSuffix ' file at: ' fileStruct]);
    else
        disp(['Using explicit BIDS ' fileSuffix ' file at: ' fileStruct]);
    end
    
    % BIDS Files not found
    if ~exist(fileStruct)
        error('BIDS Files not found. Try explicitly specifying files.');
    end
    
    try
        dataStruct = tdfread(fileStruct); % Matlab case
    catch ME
        disp('Running in Octave mode...');
        holdMe = csv2cell(fileStruct,'	'); % Octave case
        if strcmp(fileSuffix,'events')
            colID = find(strcmp('value',holdMe(1,:))); % Search for value column
            dataStruct.value = holdMe(2:end,colID);
        elseif strcmp(fileSuffix,'electrodes')
            xID = find(strcmp('x',holdMe(1,:)));
            yID = find(strcmp('y',holdMe(1,:)));
            zID = find(strcmp('z',holdMe(1,:)));
            nameID = find(strcmp('name',holdMe(1,:)));
            dataStruct.x = [holdMe{2:end,xID}];
            dataStruct.y = [holdMe{2:end,yID}];
            dataStruct.z = [holdMe{2:end,zID}];
            dataStruct.name = holdMe(2:end,nameID);
        end
    end
end