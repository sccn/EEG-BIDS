function export_anno(EEG, file, descLabel)

% For Face13 and lossless debugging:
% timeToAnno = {'in_task_fhbc_onset', 'in_leadup_fhbc_onset', 'out_task','in_task_fhbc_fade','in_leadup_fhbc_fade'};

timeToAnno = {};
for i=1:length(EEG.marks.time_info)
    if length(unique(EEG.marks.time_info(i).flags)) == 2
        timeToAnno = [timeToAnno; EEG.marks.time_info(i).label];
    end
end
timeToAnno = timeToAnno';

annoOut = sprintf('onset\tduration\tlabel\tchannels\n%s',parseMarks(EEG.marks.chan_info,'EEG','chan'));
annoOut = sprintf('%s%s',annoOut,parseMarks(EEG.marks.comp_info,'ICA','comp'));
cellAccum = {};
for i=1:length(timeToAnno)
    index = -1;
    for j=1:length(EEG.marks.time_info)
        if strcmp(timeToAnno{i},EEG.marks.time_info(j).label)
            index = j;
            break;
        end
    end
    cellAccum = [cellAccum; parseBinaryMarks(EEG, index)];
end

try % Matlab
    cellAccum = sortrows(cellAccum,1);
catch ME % Octave
    vector2sort=cell2mat(cellAccum(:,1));
    [~,idx] = sort(vector2sort);
    cellAccum = cellAccum(idx,:);
end

binaryLabelSize = size(cellAccum);
for i=1:binaryLabelSize(1)
    annoOut = sprintf('%s%s\t%s\t%s\tn/a\n',annoOut,num2str(cellAccum{i,1}),num2str(cellAccum{i,2}),num2str(cellAccum{i,3}));
end

s = {};
s.Description = 'Lossless state channel and component annotations.';
s.IntendedFor = file;
s.Sources = 'See BUCANL GitHub';
s.Author = 'Lossless';
s.LabelDescription.chan_manual = 'The interactive label (modified by analysts interactively or by a pipeline decision along with other labels) typically used to indicate which channels are considered artifactual for any reason.';
s.LabelDescription.chan_ch_sd = 'Pipeline decision flag indicating that channels were too often outliers compared to other channels for the measure of standard deviation of voltage within one second epochs.';
s.LabelDescription.chan_low_r = 'Pipeline decision flag indicating that channels were too often outliers compared to other channels for the measure of correlation coefficient to spatially neighbouring channels within one second epochs.';
s.LabelDescription.chan_bridge = 'Pipeline decision flag indicating that channels were outliers for in terms of having high and invariant correlation coefficients to spatially neighbouring channels.';
s.LabelDescription.chan_rank = 'Pipeline decision identifying the channel that has the least amount of unique information (highest average correlation coefficient to spatially neighbouring channels) to be ignored by ICA in order to account for the rank deficiency of the average referenced data.';
s.LabelDescription.comp_manual = 'The interactive label (modified by analysts interactively or by a pipeline decision along with other labels) typically used to indicate which components are considered artifactual for any reason.';
s.LabelDescription.comp_ic_rt = 'Pipeline decision flag indicating that components had a poor dipole fit (typically > %15 residual variance).';
s.LabelDescription.comp_brain = 'ICLabel 0.3 Mark indicating that the compnents have cortical characteristics.';
s.LabelDescription.comp_muscle = 'ICLabel 0.3 Mark indicating that the compnents have EMG characteristics.';
s.LabelDescription.comp_eye = 'ICLabel 0.3 Mark indicating that the compnents have EOG characteristics.';
s.LabelDescription.comp_heart = 'ICLabel 0.3 Mark indicating that the compnents have ECG characteristics.';
s.LabelDescription.comp_line_noise = 'ICLabel 0.3 Mark indicating that the compnents have electrical mains noise characteristics.';
s.LabelDescription.comp_chan_noise = 'ICLabel 0.3 Mark indicating that the compnents have channel independence characteristics.';
s.LabelDescription.comp_other = 'ICLabel 0.3 Mark indicating that the compnents could not be confidently classified within any other ICLabel classification.';
s.LabelDescription.comp_ambig = 'QC procedure rater markup indicating that the compnents are difficult to classify as either artifact or not.';

s.LabelDescription.in_task_fhbc_onset = 'Based on experimental task events indicating time points within the duration of the fhbc_onset tasks (Face House Butterfly Checkerboard typical onset stimulus series).';
s.LabelDescription.in_leadup_fhbc_onset = 'Based on experimental task events indicating time points leading into (a few second before and a few seconds after the first experimental event in a block of trials) the duration of the fhbc_onset tasks (Face House Butterfly Checkerboard typical onset stimulus series).';
s.LabelDescription.out_task = 'Based on experimental task events indicating time points outside the duration of any experimental tasks (e.g. breaks, start up and end off times, etc).';
s.LabelDescription.in_task_fhbc_fade = 'Based on experimental task events indicating time points within the duration of the fhbc_onset tasks (Face House Butterfly Checkerboard typical onset stimulus series).';
s.LabelDescription.in_leadup_fhbc_fade = 'Based on experimental task events indicating time points leading into (a few second before and a few seconds after the first experimental event in a block of trials) the duration of the fhbc_onset tasks (Face House Butterfly Checkerboard typical onset stimulus series).';

s.LabelDescription.ic_hg = 'Pipeline decision flag indicating that time points were too often outliers across initial components compared to other time points for the measure of component spectral High Gama within one second epochs.';
s.LabelDescription.manual = 'The interactive label (modified by analysts interactively or by a pipeline decision along with other labels) typically used to indicate which time points are considered artifactual for any reason.';

% File IO
savejson('',s,strrep(file,'eeg.edf',['desc-' descLabel '_annotations.json']));
fID = fopen(strrep(file,'eeg.edf',['desc-' descLabel '_annotations.tsv']),'w');
fprintf(fID,annoOut);
fclose(fID);

columnList = {};
for i=1:length(EEG.marks.time_info)
    if ~sum(ismember(timeToAnno,EEG.marks.time_info(i).label))
        columnList = [columnList; EEG.marks.time_info(i).label];
    end
end

s = {};
s.SamplingFrequency = EEG.srate;
s.StartTime = 0.0;
s.Columns = columnList';
s.ColumnDescription.init_ind = 'Continuous variable indicating the initial time point index within the session.';
s.ColumnDescription.mark_gap = 'Pipeline decision flag indicating that time points are within a short gap between other annotations.';
s.ColumnDescription.ch_sd = 'Pipeline decision flag indicating that time points were too often outliers across channels compared to other time points for the measure of standard deviation of voltage within one second epochs.';
s.ColumnDescription.low_r = 'Pipeline decision flag indicating that time points were too often outliers across channels compared to other time points for the measure of correlation coefficient to spatially neighbouring channels within one second epochs.';
s.ColumnDescription.logl_init = 'Log likelihood of initial AMICA decomposition.';
s.ColumnDescription.ic_sd1 = 'Pipeline decision flag indicating that time points were too often outliers across initial components compared to other time points for the measure of component standard deviation of voltage within one second epochs.';
s.ColumnDescription.logl_A = 'Log likelihood of final AMICA decomposition (replication A).';
s.ColumnDescription.logl_B = 'Log likelihood of final AMICA decomposition (replication B).';
s.ColumnDescription.logl_C = 'Log likelihood of final AMICA decomposition (replication C).';
s.ColumnDescription.ic_sd2 = 'Pipeline decision flag indicating that time points were too often outliers across final components compared to other time points for the measure of component standard deviation of voltage within one second epochs.';
s.ColumnDescription.ic_dt = 'Pipeline decision flag indicating that time points were too often outliers across initial components compared to other time points for the measure of component spectral Theta within one second epochs.';
s.ColumnDescription.ic_a = 'Pipeline decision flag indicating that time points were too often outliers across initial components compared to other time points for the measure of component spectral Alpha within one second epochs.';
s.ColumnDescription.ic_b = 'Pipeline decision flag indicating that time points were too often outliers across initial components compared to other time points for the measure of component spectral Beta within one second epochs.';
s.ColumnDescription.ic_lg = 'Pipeline decision flag indicating that time points were too often outliers across initial components compared to other time points for the measure of component spectral Low Gama within one second epochs.';

% Time info json io 
savejson('',s,strrep(file,'eeg.edf',['desc-' descLabel 'mat_annotations.json']));

disp('Starting continuous mark export');

% % Time info gz output
% % Legacy export:
% tFileName = strrep(file,'eeg.edf',['desc-' descLabel 'timeinfo_annotations.tsv']);
% fID = fopen(tFileName,'Wb');
% for i=1:length(EEG.marks.time_info(1).flags)
%     rowOut = '';
%     for j=1:length(EEG.marks.time_info)
%         if ~sum(ismember(timeToAnno,EEG.marks.time_info(j).label))
%             rowOut = sprintf('%s%d\t',rowOut,EEG.marks.time_info(j).flags(i));
%         end
%     end
%     fprintf(fID,'%s\n',rowOut);
% end
% fclose(fID);
% 
% % Zip and delete for storage - be careful with this
% %gzip(tFileName);
% %system(['rm ' tFileName]);

tFileName = strrep(file,'eeg.edf',['desc-' descLabel '_annotations.mat']);
timeAccum = {};
for i=1:length(EEG.marks.time_info)
    if ~ismember(EEG.marks.time_info(i).label,timeToAnno)
        timeAccum = [timeAccum EEG.marks.time_info(i)];
    end
end
save(tFileName, 'timeAccum');

disp([file ' COMPLETE']);

end

function outStr = parseMarks(markStruct, labelPrefix, chanLabel)
    outStr = '';
    for i=1:length(markStruct)
        enabledList = '[';
        enabled = find(markStruct(i).flags);
        if length(enabled) < 1
            continue
        end
        for j=1:length(enabled)
            enabledList = sprintf('%s"%s%03d",',enabledList,labelPrefix,enabled(j));
        end
        enabledList(end) = ']';
        outStr = sprintf('%sn/a\tn/a\t%s\t%s\n',outStr,[chanLabel '_' markStruct(i).label],enabledList);
    end
end

function outCell = parseBinaryMarks(EEG, index)
    A = EEG.marks.time_info(index).flags;
    try % Matlab case
        out = zeros(size(A));
        ii = strfind([0,A(:)'],[0 1]);
        out(ii) = strfind([A(:)',0],[1 0]) - ii + 1;
        onsetTimes = find(out);
        durations = out(onsetTimes);
    catch ME % Octave case
        tempHold = find(diff([0,A,0]==1));
        onsetTimes = tempHold(1:2:end-1);  % Start indices
        durations = tempHold(2:2:end)-onsetTimes;  % Consecutive ones’ counts
    end
    
    outCell = {};
    for i=1:length(onsetTimes)
        singleCell = {onsetTimes(i) / EEG.srate, durations(i) / EEG.srate, EEG.marks.time_info(index).label};
        outCell = [outCell; singleCell];
    end
end