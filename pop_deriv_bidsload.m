function EEG = pop_deriv_bidsload()
    if nargin < 1
        [fa, fb] = uigetfile('*.edf','Select an EDF file');
        fileLocation = [fb fa];
    else
        return; % For now as this is only going to be used from the menu
    end
    
    disp('Loading derivative...');
    filePrefix = fileLocation(1:end-8);
    
    %LOAD BIDS FILES
    sphereLoc = [filePrefix '_icasphere.tsv'];
    weightsLoc = [filePrefix '_icaweights.tsv'];
    annoFile = [filePrefix '_annotations.tsv'];

    % Select paired raw file
    [fa, fb] = uigetfile('*.edf','Select paired raw EDF file');
    rawFileLocation = [fb fa];
    rawFilePrefix = rawFileLocation(1:end-8);
    
    elecFile = [rawFilePrefix '_electrodes.tsv'];
    eventsFile = [rawFilePrefix '_events.tsv'];

    EEG = pop_bidsload(fileLocation,'elecLoc',elecFile,'eventLoc',eventsFile,'icaSphere',sphereLoc,'icaWeights',weightsLoc,'annoLoc',annoFile);

    % Update color and flag information with fix script:
    % Removed for now as this is specific to lossless
    % fixMarks;

    % Load extra ICLabel inforation from via non-bids method
    tmp = load([filePrefix '_iclabel.mat']);
    EEG.etc.ic_classification = tmp.tmp; % Octave makes this a bit strange...
    EEG.etc.ic_classification.ICLabel.classifications = real(EEG.etc.ic_classification.ICLabel.classifications);

end