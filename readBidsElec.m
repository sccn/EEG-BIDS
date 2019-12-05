% This is an offloaded helper function that takes an EEG structure and a
% cell array of the form {channel_label, false}. This is used to perform
% lookups in the EEG.chaninfo structure of an ingested EDF. The boolean
% portion of this cell array is used to keep track of which labels have
% been used. The remaining unused labels after lookup are moved to the
% EEG.chaninfo.nodatchans structure. Additionally, this function has a
% strong reliance on the function validateBidsFile, as parsedElec is
% created by it.
function EEG = readBidsElec(EEG, parsedElec, elecData)
        % Look up loop
        for i=1:length(EEG.chanlocs)
            lookupID = -1;
            for j=1:length(parsedElec)
                if strcmpi(strrep(EEG.chanlocs(i).labels,' ',''), parsedElec{j,1})
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
                    EEG.chaninfo.nodatchans(end+1) = EEG.chaninfo.nodatchans(1);
                end
                % Read info
                EEG.chaninfo.nodatchans(end).labels = parsedElec{i,1};
                EEG.chaninfo.nodatchans(end).X = elecData.x(i);
                EEG.chaninfo.nodatchans(end).Y = elecData.y(i);
                EEG.chaninfo.nodatchans(end).Z = elecData.z(i);
            end
        end
        
        % Take advantage of eeglab function
        EEG = eeg_checkset(EEG,'chanconsist');     
end