% Helper function for loading ICA into an EEG structure via BIDS files.
function EEG = readBidsICA(EEG, icaSphere, icaWeights)
    disp('Attempting to load ICA decomposition via: ');
    disp(icaSphere);
    disp(icaWeights);
    weightsJson = loadjson(strrep(icaWeights,'.tsv','.json'));
    EEG.icachansind = weightsJson.icachansind;
    EEG.icaweights = dlmread(icaWeights,'\t');
    EEG.icasphere = dlmread(icaSphere,'\t');
    EEG = eeg_checkset(EEG); % Force rebuild now that ICA is back 
end