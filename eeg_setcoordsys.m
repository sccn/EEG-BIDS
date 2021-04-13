% Set EEG.coordsys to `EEGLAB` or `EEGLAB-HT`, rotating electrode coordinates
% as necessary based on anatomical landmark locations in EEG.chaninfo.nodatchans
%
% Clement Lee, Swartz Center for Computational Neuroscience,
% Institute for Neural Computation, UC San Diego
% April 2021

function EEG = eeg_setcoordsys(EEG, targetCoordSys)
fidChans = EEG.chaninfo.nodatchans;
if isempty(fidChans)
    fprintf('No fiducial channels found in EEG.chaninfo.nodatchans.\n')
else
    noseIdx     = find(contains(lower({fidChans.labels}), {'nz', 'nasion' 'nazion' 'fidnz'}));
    leftEarIdx  = find(contains(lower({fidChans.labels}), {'lpa', 'lhj', 'lht', 'left', 'fdit9'}));
    rightEarIdx = find(contains(lower({fidChans.labels}), {'rpa', 'rhj', 'rht', 'right', 'fidt10'}));
    
    emptyFid = cellfun(@(x) isempty(x), {noseIdx, leftEarIdx, rightEarIdx});
    if any(emptyFid)
        fidName = {'Nose', 'Left Ear', 'Right Ear'};
        s = sprintf(' %s,', fidName{emptyFid});
        fprintf('Could not find a match for the following in EEG.chaninfo.nodatchans: %s. \n', s(1:end-1))
    else
        fidChans = fidChans(1, [noseIdx, leftEarIdx, rightEarIdx]);
        
        nas    = [fidChans(1).X fidChans(1).Y fidChans(1).Z];
        lpa    = [fidChans(2).X fidChans(2).Y fidChans(2).Z];
        rpa    = [fidChans(3).X fidChans(3).Y fidChans(3).Z];
        [h, ~] = ft_headcoordinates(nas, lpa, rpa, targetCoordSys);
        
        if abs(h - eye(4)) > 1e-6 % arbitrary tolerance for comparison
            fprintf('Rotating coordinate system...\n')
            eLocs = [EEG.chanlocs.X; EEG.chanlocs.Y; EEG.chanlocs.Z; ones(1,length(EEG.chanlocs))]';
            rotatedLocs = num2cell(eLocs*h');
            
            [EEG.chanlocs.X] = deal(rotatedLocs{:,1});
            [EEG.chanlocs.Y] = deal(rotatedLocs{:,2});
            [EEG.chanlocs.Z] = deal(rotatedLocs{:,3});
        end
    end
    
    if any(strcmpi(fidChans(2).labels, {'lht','lhj'}))
        EEG.chaninfo.coordsys = 'EEGLAB-HT';
        fprintf('EEG.chaninfo.coordsys set to ''EEGLAB-HT''...\n')    
    else
        EEG.chaninfo.coordsys = 'EEGLAB';
        fprintf('EEG.chaninfo.coordsys set to ''EEGLAB''...\n')
    end
end