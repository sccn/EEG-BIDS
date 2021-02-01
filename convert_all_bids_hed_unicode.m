% assuming you run this function in a BIDS dataset
allBidsFiles = dir('*/*/*.set');
if isempty(allBidsFiles)
    allBidsFiles = dir('*/*/*/*.set'); % with sessions
end

for iFile=1:length(allBidsFiles)
    EEG = pop_loadset(fullfile(allBidsFiles(iFile).folder, allBidsFiles(iFile).name));
    EEG = eeg_hedremoveunicode(EEG);
    EEG.saved = 'no';
    pop_saveset(EEG, 'filename', EEG.filename, 'filepath', EEG.filepath);
end
