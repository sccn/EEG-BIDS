function event_helper(fileOut, EEG, trialtype)
    % Getting events latency
    insertEpoch = false;
    if EEG.trials > 1
        % get TLE events
        insertEpoch = true;
        eventlat = abs(eeg_point2lat( [ EEG.event.latency ], [ EEG.event.epoch ], EEG.srate, [EEG.xmin EEG.xmax]));
        indtle    = find(eventlat == 0);
        if length(indtle) < EEG.trials
            indtle    = find(eventlat < 0.02);
        end
        if length(indtle) ~= EEG.trials
            insertEpoch = false;
        end
    end

    fid = fopen( [ fileOut(1:end-7) 'events.tsv' ], 'w');
    fprintf(fid, 'onset\tduration\ttrial_type\tresponse_time\tsample\tvalue\n');
    for iEvent = 1:length(EEG.event)
        onset = (EEG.event(iEvent).latency-1)/EEG.srate;

        % duration
        if isfield(EEG.event, 'duration') && ~isempty(EEG.event(iEvent).duration)
            duration = num2str(EEG.event(iEvent).duration, '%1.10f') ;
        else
            duration = 'n/a';
        end

        % event value
        if isstr(EEG.event(iEvent).type)
            eventValue = EEG.event(iEvent).type;
        else
            eventValue = num2str(EEG.event(iEvent).type);
        end

        % event type (which is the type of event - not the same as EEGLAB)
        trialType = 'STATUS';
        if isfield(EEG.event, 'trial_type')
            trialType = EEG.event(iEvent).trial_type;
        elseif ~isempty(trialtype)
            indTrial = strmatch(eventValue, trialtype(:,1), 'exact');
            if ~isempty(indTrial)
                trialType = trialtype{indTrial,2};
            end
        end
        if insertEpoch
            if any(indtle == iEvent)
                trialType = 'Epoch';
            end
        end

        fprintf(fid, '%1.10f\t%s\t%s\t%s\t%1.10f\t%s\n', onset, duration, trialType, 'n/a', EEG.event(iEvent).latency-1, eventValue);
    end
    fclose(fid);