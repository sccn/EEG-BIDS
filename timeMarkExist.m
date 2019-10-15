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