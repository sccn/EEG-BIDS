function EEG = readBidsAnno(EEG, annoLoc)
    if ~exist('ve_eegplot')
        error('VisedMarks not found. Unable to ingest annotations');
    end
    annoJsonLoc = strrep(annoLoc,'.tsv','.json');
    if ~exist(annoJsonLoc)
        error('BIDS Annotation JSON not found.');
    end
    disp('Rebuiling marks structure via:');
    disp(annoLoc);
    disp(annoJsonLoc);

    EEG.marks = [];
    if isempty(EEG.icaweights)
        EEG.marks=marks_init(size(EEG.data));
    else
        EEG.marks=marks_init(size(EEG.data),min(size(EEG.icaweights)));
    end

    annoData = tdfread(annoLoc);
    for i=1:length(annoData.onset) % all the same size in rows
        onsetTime = str2num(strtrim(annoData.onset(i,:)));
        durationTime = str2num(strtrim(annoData.duration(i,:)));
        currentLabel = strtrim(annoData.label(i,:));
        % Chan or comp marker
        if isempty(onsetTime) && isempty(durationTime)
            if strncmpi(currentLabel,'chan',4)
                EEG = ingestMark(EEG, 0, currentLabel,'chan_', 'EEG',strtrim(annoData.channels(i,:)));
            elseif strncmpi(currentLabel,'comp',4)
                EEG = ingestMark(EEG, 1, currentLabel,'comp_','ICA',strtrim(annoData.channels(i,:)));
            else
                warning('Mark ingest not defined for mark of this type.');
            end
        else % Time info mark case
            [EEG, markID] = timeMarkExist(EEG, currentLabel);
            startPos = round(onsetTime * EEG.srate);
            endPos = round(durationTime * EEG.srate) + startPos;
            for index=startPos:endPos
                EEG.marks.time_info(markID).flags(index) = 1;
            end
        end
    end

    % Below code block exists as legacy support for ts.gz
    % Was not in a 100% working state prior to move to binary.
%         Test if continuous annotations need to be handled
%         contMarkTsv = strrep(annoLoc,'_annotations.tsv','timeinfo_annotations.tsv');
%         contMarkJson = strrep(contMarkTsv,'.tsv','.json');
%         if exist(contMarkTsv) && exist(contMarkJson)
%             disp('Continuous marks files found at:');
%             disp(contMarkTsv);
%             disp(contMarkJson);
%             
%             % Get headers from json
%             contMarkInfo = loadjson(contMarkJson);
%             contData = dlmread(contMarkTsv, '\t');
%             % For each header in the colums, make a new mark and read from
%             % the data tsv
%             for i=1:length(contMarkInfo.Columns)
%                 [EEG, markID] = timeMarkExist(EEG,contMarkInfo.Columns{i});
%                 EEG.marks.time_info(markID).flags = contData(:,i)';
%             end
%             disp('Continuous marks loaded.');
%         end
    contMarkMat = strrep(annoLoc,'.tsv','.mat');
    if exist(contMarkMat)
        disp('Continuous mark file found. Loading at: ');
        disp(contMarkMat);
        contData = load(contMarkMat);
        for i=1:length(contData.timeAccum)
            EEG.marks.time_info(end+1) = contData.timeAccum{i};
        end
    end
end