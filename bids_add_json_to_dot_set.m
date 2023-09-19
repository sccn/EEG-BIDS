function bids_add_json_to_dot_set(folder)

fcontent = dir(folder);

for iFile = 1:length(fcontent)
    if ~isequal(fcontent(iFile).name(1), '.')
        if fcontent(iFile).isdir
            bids_add_json_to_dot_set(fullfile(folder, fcontent(iFile).name))
        elseif length(fcontent(iFile).name) > 4 && isequal(fcontent(iFile).name(end-3:end), '.set')
            filename = fullfile(folder, fcontent(iFile).name);
            fprintf('%s\n', filename);
            % EEG = pop_loadset(filename);
            fid = fopen(filename, 'w');
            fprintf(fid, 'xxx');
            fclose(fid);

            % fid = fopen([ filename(1:end-4) '.json' ], 'w');
            % if fid == -1
            %     error('Cannot open file')
            % end

            % eegChans = sum(cellfun(@(x)isequal(x, 'EEG'), { EEG.chanlocs.type}));
            % noneegChans = EEG.nbchan - eegChans;
            % 
            % fprintf(fid, '{\n');
            % fprintf(fid, '    "TaskName": "WorkingMemory",\n');
            % fprintf(fid, '    "EEGReference": "common",\n');
            % fprintf(fid, '    "RecordingType": "continuous",\n');
            % fprintf(fid, '    "RecordingDuration": %1.3f,\n', EEG.xmax);
            % fprintf(fid, '    "SamplingFrequency": %1.1f,\n', EEG.srate);
            % fprintf(fid, '    "EEGChannelCount": %d,\n', eegChans);
            % fprintf(fid, '    "EOGChannelCount": %d,\n', noneegChans);
            % fprintf(fid, '    "PowerLineFrequency": 60,\n');
            % fprintf(fid, '    "SoftwareFilters": "n/a"\n');
            % fprintf(fid, '}\n');

        end
    end
end
