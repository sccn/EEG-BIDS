% Helper function for ingesting chan or comp marks
% Second parameter: chan -> 0, comp -> 1
function EEG = ingestMark(EEG, chanOrComp, label,labelPrefix, signalPrefix, dataList)
    markName = strrep(label,labelPrefix,'');
    dataList = strrep(dataList,signalPrefix,'');
    dataList = strrep(dataList,'"',' '); % Trying to make this backwards compatable...
    dataList = strrep(dataList,',',' ');
    dataList = str2num(dataList);
    if chanOrComp % Comp
        allFlags = zeros(1,length(EEG.icachansind));
        allFlags(dataList) = 1;
        EEG.marks = marks_add_label(EEG.marks,'comp_info', {markName,[.7,.7,1],[.2,.2,1],-1,allFlags'});
    else % Chan
        allFlags = zeros(1,EEG.nbchan);
        allFlags(dataList) = 1;
        EEG.marks = marks_add_label(EEG.marks,'chan_info', {markName,[.7,.7,1],[.2,.2,1],-1,allFlags'});
    end
end