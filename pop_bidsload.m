% pop_bidsload - This function allows for the ingesting of a single BIDS
%               file. In the case of EDFs, the directory of the data file
%               is searched for an event tsv and an electrodes tsv. These
%               are then read back into the EEG structure.
%
% Usage:
%    bids_export(fileLocation, varargin)
%
% Input:
%  fileLocation - [String] location of a file. In the case of EDFs, the
%                 directory the file is located in will be searched for an
%                 events/electrodes file.
%
% Optional inputs:
%  'elecLoc'    - [String] explicit location of the electrodes tsv.
%
%  'eventLoc'   - [String] explicit location of the events tsv.
%
%  'gui'        - [logical] toggle for redrawing main eeglab figure. 
%                 Defaults to true.
%
%  'icaSphere'  - [String] location of an ICA sphering matrix. If empty,
%                 nothing will be loaded. Both ICA options must be present
%                 to complete loading.
%
%  'icaWeights' - [String] location of ICA vector matrix. If empty, nothing
%                 will be loaded. Both ICA options must be present to
%                 complete loading. This option will also be used to read a
%                 json which contains the channels that the ICA was run on.
%
%  'annoLoc'    - [String] location of discrete annotation BIDS json. The
%                 paired json will be assumed to be in the same location.
%                 By using this option, EEG.marks will be cleared first.
%                 See other options for continuous marks integration.
%
% Author: Tyler K. Collins, 2019

function EEG = pop_bidsload(fileLocation, varargin)

    if nargin < 1
        help pop_bidsload;
        return;
    end

    % Future proofing against wanting to point a datafile to different
    % locations due to inheritence principle.
    opt = finputcheck(varargin, {'elecLoc' 'string' {} '';
                                 'gui' 'integer' {} 1;
                                 'icaSphere' 'string' {} '';
                                 'icaWeights' 'string' {} '';
                                 'annoLoc' 'string' {} '';
                                 'eventLoc' 'string' {} ''}, 'bids_format_eeglab');

    [fPath,fName,fType] = fileparts(fileLocation);
    fullFile = [fPath '/' fName fType];

    if strcmp(fType,'.set') % Easy case
        disp('Set file detected. Loading as normal.');
        EEG = pop_loadset(fullFile,'');
    elseif strcmp(fType,'.edf') % Requires processing
        disp('BIDS Parsing needed.');
        EEG = pop_biosig(fullFile);

        % Relabel events
        eventData = validateBidsFile(fullFile, opt.eventLoc, 'events');
        for i=1:length(eventData.value)
            try % Octave case
                EEG.event(i).type = strtrim(eventData.value{i,:});
            catch % Matlab case
                EEG.event(i).type = strtrim(eventData.value(i,:));
            end
        end

        % Update channel/electrode locations
        % Accounts for chanlocs and the tsv being out of order
        % Also strips extra whitespace from tsv reading
        % parsedElec structure also keeps track of if it has been used
        elecData = validateBidsFile(fullFile, opt.elecLoc, 'electrodes');
        parsedElec = cell(length(elecData.name),2);
        for i=1:length(parsedElec)
            parsedElec{i,1} = strtrim(elecData.name(i,:));
            parsedElec{i,2} = false;
        end
        
        % Look up loop
        for i=1:length(EEG.chanlocs)
            lookupID = -1;
            for j=1:length(parsedElec)
                if strcmp(EEG.chanlocs(i).labels, parsedElec{j,1})
                    lookupID = j;
                    parsedElec{j,2} = true;
                    break;
                end
            end
            
            if lookupID < 0
                warning([currentLabel ' not found. Adding to nodatchans']);
            else
                % Loss of precision is only a printing error
                % Use "format long" to double check
                EEG.chanlocs(i).X = elecData.x(lookupID);
                EEG.chanlocs(i).Y = elecData.y(lookupID);
                EEG.chanlocs(i).Z = elecData.z(lookupID);
            end
        end
        
        % Any labels that were not used are moved into the fiducial struct
        for i=1:length(parsedElec)
            if ~parsedElec{i,2}
                disp(['Moving ' parsedElec{i,1}  ' to nodatchans']);
                if isempty(EEG.chaninfo.nodatchans) % Initial copy edge case
                    EEG.chaninfo.nodatchans = EEG.chanlocs(1);
                    EEG.chaninfo.nodatchans(1).type = 'FID';
                    EEG.chaninfo.nodatchans(1).datachan = 0;
                else % Just copy from the previous
                    EEG.chaninfo.nodatchans(i) = EEG.chaninfo.nodatchans(1);
                end
                % Read info
                EEG.chaninfo.nodatchans(i).labels = parsedElec{i,1};
                EEG.chaninfo.nodatchans(i).X = elecData.x(i);
                EEG.chaninfo.nodatchans(i).Y = elecData.y(i);
                EEG.chaninfo.nodatchans(i).Z = elecData.z(i);
            end
        end
        
        % Take advantage of eeglab function
        EEG = eeg_checkset(EEG,'chanconsist');
    end
    
    % ICA Loading
    if ~strcmp(opt.icaSphere,'') && ~strcmp(opt.icaSphere,'')
        disp('Attempting to load ICA decomposition via: ');
        disp(opt.icaSphere);
        disp(opt.icaWeights);
        weightsJson = loadjson(strrep(opt.icaWeights,'.tsv','.json'));
        EEG.icachansind = weightsJson.icachansind;
        EEG.icaweights = dlmread(opt.icaWeights,'\t');
        EEG.icasphere = dlmread(opt.icaSphere,'\t');
        EEG = eeg_checkset(EEG); % Force rebuild now that ICA is back
    elseif ~strcmp(opt.icaSphere,'') || ~strcmp(opt.icaSphere,'')
        disp('Only one ICA option given. Both are required.');
    end
    
    % Mark structure ingest
    if ~strcmp(opt.annoLoc,'')
        if ~exist('ve_eegplot')
            error('VisedMarks not found. Unable to ingest annotations');
        end
        annoJsonLoc = strrep(opt.annoLoc,'.tsv','.json');
        if ~exist(annoJsonLoc)
            error('BIDS Annotation JSON not found.');
        end
        disp('Rebuiling marks structure via:');
        disp(opt.annoLoc);
        disp(annoJsonLoc);
        
        EEG.marks = [];
        if isempty(EEG.icaweights)
            EEG.marks=marks_init(size(EEG.data));
        else
            EEG.marks=marks_init(size(EEG.data),min(size(EEG.icaweights)));
        end
        
        annoData = tdfread(opt.annoLoc);
        for i=1:length(annoData.onset) % all the same size in rows
            onsetTime = str2num(strtrim(annoData.onset(i,:)));
            durationTime = str2num(strtrim(annoData.duration(i,:)));
            currentLabel = strtrim(annoData.label(i,:));
            % Chan or comp marker
            if isempty(onsetTime) && isempty(durationTime)
                if strncmpi(currentLabel,'chan',4)
                    EEG = ingestMark(EEG, 0, currentLabel,'chan_', 'EEG',strtrim(annoData.channels(1,:)));
                elseif strncmpi(currentLabel,'comp',4)
                    EEG = ingestMark(EEG, 1, currentLabel,'comp_','ICA',strtrim(annoData.channels(1,:)));
                else
                    warning('Mark ingest not defined for mark of this type.');
                end
            else % Time info mark case
                [EEG, markID] = timeMarkExist(EEG, currentLabel);
                startPos = round(onsetTime * EEG.srate);
                endPos = round(durationTime * EEG.srate) + startPos;
                for index=startPos:endPos
                    EEG.marks.time_info(markID).flags(index) = 1;
                end
            end
        end
    end
    
    % Draw to main figure
    if opt.gui
        eval('eeglab redraw'); % Double draw for edge case.
        % eval('eeglab redraw');
    end
end

% Helper function for adding a mark if it does not exist yet
function [EEG, outID] = timeMarkExist(EEG, labelQuery)
    found = false;
    outID = -1;
    markSize = length(EEG.marks.time_info);
    for i=1:markSize
        if strcmp(EEG.marks.time_info(i).label,labelQuery)
            found = true;
            outID = i;
        end
    end
    if ~found
        disp(['Creating new mark with label: ' labelQuery]);
        outID = markSize + 1;
        EEG.marks = marks_add_label(EEG.marks,'time_info', {labelQuery,[0,0,1],zeros(1,length(EEG.marks.time_info(1).flags))});
    end
end

% Helper function for ingesting chan or comp marks
% Second parameter: chan -> 0, comp -> 1
function EEG = ingestMark(EEG, chanOrComp, label,labelPrefix, signalPrefix, dataList)
    markName = strrep(label,labelPrefix,'');
    dataList = strrep(dataList,signalPrefix,'');
    dataList = strrep(dataList,'"',' '); % Trying to make this backwards compatable...
    dataList = strrep(dataList,',',' ');
    dataList = str2num(dataList);
    if chanOrComp % Comp
        allFlags = zeros(1,length(EEG.icachansind));
        allFlags(dataList) = 1;
        EEG.marks = marks_add_label(EEG.marks,'comp_info', {markName,[.7,.7,1],[.2,.2,1],-1,allFlags'});
    else % Chan
        allFlags = zeros(1,EEG.nbchan);
        allFlags(dataList) = 1;
        EEG.marks = marks_add_label(EEG.marks,'chan_info', {markName,[.7,.7,1],[.2,.2,1],-1,allFlags'});
    end
end

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