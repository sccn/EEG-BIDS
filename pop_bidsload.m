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
%  'annoLoc'    - [String] location of discrete annotation BIDS tsv. The
%                 paired files will be assumed to be in the same location.
%                 By using this option, EEG.marks will be cleared first.
%                 See other options for continuous marks integration.
%
% Author: Tyler K. Collins, 2019

function EEG = pop_bidsload(fileLocation, varargin)

    if nargin < 1
        help pop_bidsload;
        [fa fb] = uigetfile('*.edf','Select an EDF file');
        fileLocation = [fb fa];
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
        disp ('Generating event structure from events.tsv');
        for i=1:length(eventData.sample)
            EEG.event(i).latency = eventData.sample{i};
        end
        
        for i=1:length(eventData.value)
            try % Octave case
                EEG.event(i).type = strtrim(num2str(eventData.value{i,:}));
            catch % Matlab case
                EEG.event(i).type = strtrim(num2str(eventData.value(i,:)));
            end
        end
        
        EEG = eeg_checkset( EEG , 'makeur'); % Remake urevent

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
        
        % Offloaded function call for getting electrode positions
        EEG = readBidsElec(EEG, parsedElec, elecData);
    end
    
    % ICA Loading
    if ~strcmp(opt.icaSphere,'') && ~strcmp(opt.icaWeights,'')
        EEG = readBidsICA(EEG, opt.icaSphere, opt.icaWeights);
    elseif ~strcmp(opt.icaSphere,'') || ~strcmp(opt.icaSphere,'')
        disp('All ICA files are required.');
    end
    
    % Mark structure ingest
    if ~strcmp(opt.annoLoc,'')
        EEG = readBidsAnno(EEG, opt.annoLoc);
    end
    
    % Draw to main figure
    if opt.gui
        eval('eeglab redraw'); % Double draw for edge case.
        % eval('eeglab redraw');
    end
end
