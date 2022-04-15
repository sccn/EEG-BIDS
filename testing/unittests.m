function unittests()
    test_import_events_files
    
    
    function test_import_events_files()
        EEG = pop_loadset('./data/sub-044_task-AuditoryVisualShift_run-01_eeg.set');
        [EEG, ~, ~, ~]= import_events_files(EEG, './data/sub-044_task-AuditoryVisualShift_run-01_events.tsv', 'eventDescFile', './data/sub-044_task-AuditoryVisualShift_run-01_events.json');
    end
end