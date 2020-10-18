% pop_participantinfo() - GUI for BIDS participant info editing
%
% Usage:
%   >> [EEG, pInfoDesc, pInfo] = pop_participantinfo( EEG );
%                                              
% Inputs:
%   EEG        - EEG dataset structure. May only contain one dataset.
%
%   STUDY      - (optional) If provided, subject and group information in
%                the STUDY will be used to auto-populate participant id and group info.
% Optional input:
%  'default'   - generate BIDS participant info using default values without
%                popping up the GUI
% Outputs:
%  'EEG'       - [struct] Updated EEG structure containing event BIDS information
%                in each EEG structure at EEG.BIDS
%
%  'pInfoDesc' - [struct] structure describing BIDS participant fields as you specified.
%                See BIDS specification for all suggested fields.
%
%  'pInfo'     - [cell] BIDS participant information.
%
% Author: Dung Truong, Arnaud Delorme
function [EEG, command] = pop_participantinfo(EEG,STUDY, varargin)
    command = '[EEG, command] = pop_participantinfo(EEG);';
    
    %% check if there's already an opened window
    if ~isempty(findobj('Tag','pInfoTable'))
        error('A window is already openened for pop_participantinfo');
    end
    
    %% if STUDY is provided, check for consistency
    if exist('STUDY','var') && ~isempty(STUDY)
        [STUDY, EEG] = pop_checkdatasetinfo(STUDY, EEG);
        command = '[EEG, command] = pop_participantinfo(EEG, STUDY);';
    end
    
    %% default settings
    appWidth = 1300;
    appHeight = 600;
    bg = [0.65 0.76 1];
    fg = [0 0 0.4];
    levelThreshold = 20;
    fontSize = 12;
    [pInfoBIDS, pFields] = newpInfoBIDS();    
%     pInfo = {};
    pInfoDesc = [];
    
    if numel(EEG) == 1
        warning('This function can also be applied to multiple dataset (e.g. EEG structures).');
    end

    % get subjects
    % -------------------------
    if ~isempty(EEG(1).subject)
        allSubjects = { EEG.subject };
    elseif ~isempty(STUDY.datasetinfo(1).subject)
        allSubjects = { STUDY.datasetinfo.subject };
    else
        error('No subject info found in either EEG or STUDY.datasetinfo. Please add using Study > Edit STUDY info');
    end
    uniqueSubjects = unique(allSubjects);
    
    %% create UI
    f = figure('MenuBar', 'None', 'ToolBar', 'None', 'Name', 'Edit BIDS participant info - pop_participantinfo', 'Color', bg);
    f.Position(3) = appWidth;
    f.Position(4) = appHeight;
    uicontrol(f, 'Style', 'text', 'String', 'Participant information', 'Units', 'normalized','FontWeight','bold','ForegroundColor', fg,'BackgroundColor', bg, 'Position', [0 0.86 0.4 0.1]);
    pInfoTbl = uitable(f, 'RowName',[],'ColumnName', [pFields  'HeadCircumference' 'SubjectArtefactDescription'], 'Units', 'normalized', 'FontSize', fontSize, 'Tag', 'pInfoTable', 'ColumnEditable', [false true(1, numel(pFields)) true]);
    pInfoTbl.Data = cell(numel(uniqueSubjects), 2+length(pFields));
    pInfoTbl.Position = [0.02 0.124 0.38 0.786];
    pInfoTbl.CellSelectionCallback = @pInfoCellSelectedCB;
    pInfoTbl.CellEditCallback = @pInfoCellEditCB;
    
    % pre-populate pInfo table
    for iSubj = 1:length(uniqueSubjects)
        indS = strmatch( uniqueSubjects{iSubj}, allSubjects, 'exact' );
        curEEG = EEG(indS(1));
        % if curEEG has BIDS.pInfo
        % pInfo is in format:
        % First row    participant_id  | Gender   |    ...
        % Second row   <value>         | <value>  |
        if isfield(curEEG, 'BIDS') && isfield(curEEG.BIDS,'pInfo')
            fnames = curEEG.BIDS.pInfo(1,:); % fields of EEG.BIDS.pInfo
            for j=1:numel(pFields)
                % if EEG.BIDS.pInfo has pFields{j}
                if any(strcmp(pFields{j}, fnames))
                    pInfoTbl.Data{iSubj,strcmp(pInfoTbl.ColumnName,pFields{j})} = curEEG.BIDS.pInfo{2,strcmp(fnames,pFields{j})};                 
                end
            end
        else
            if isfield(curEEG,'subject')
                pInfoTbl.Data{iSubj,strcmp(pInfoTbl.ColumnName, 'participant_id')} = curEEG.subject;
            end
            if isfield(curEEG,'group') && ~isempty(curEEG.group)
                pInfoTbl.Data{iSubj,strcmp(pInfoTbl.ColumnName, 'Group')} = curEEG.group;
            end
        end
        % update HeadCircumference and SubjectArtefactDescription from tInfo
        if isfield(curEEG, 'BIDS') && isfield(curEEG.BIDS,'tInfo')
            if isfield(curEEG.BIDS.tInfo,'HeadCircumference')
                pInfoTbl.Data{iSubj,strcmp(pInfoTbl.ColumnName,'HeadCircumference')} = curEEG.BIDS.tInfo.HeadCircumference;
            end
            if isfield(curEEG.BIDS.tInfo,'SubjectArtefactDescription')
                pInfoTbl.Data{iSubj,strcmp(pInfoTbl.ColumnName,'SubjectArtefactDescription')} = curEEG.BIDS.tInfo.SubjectArtefactDescription;
            end
        end
    end
    
    uicontrol(f, 'Style', 'text', 'String', 'BIDS metadata for participant fields', 'Units', 'normalized','FontWeight','bold','ForegroundColor', fg,'BackgroundColor', bg, 'Position', [0.42 0.86 1-0.42 0.1]);
    bidsTbl = uitable(f, 'RowName', pFields, 'ColumnName', {'Description' 'Levels' 'Units' }, 'Units', 'normalized', 'FontSize', fontSize, 'Tag', 'bidsTable');
    bidsWidth = (1-0.42-0.02);
    bidsTbl.Position = [0.42 0.5 bidsWidth 0.41];
    bidsTbl.CellSelectionCallback = @bidsCellSelectedCB;
    bidsTbl.CellEditCallback = @bidsCellEditCB;
    bidsTbl.ColumnEditable = [true false true];
    bidsTbl.ColumnWidth = {appWidth*bidsWidth*2/5,appWidth*bidsWidth/5,appWidth*bidsWidth/5};
    units = {' ','ampere','becquerel','candela','coulomb','degree Celsius','farad','gray','henry','hertz','joule','katal','kelvin','kilogram','lumen','lux','metre','mole','newton','ohm','pascal','radian','second','siemens','sievert','steradian','tesla','volt','watt','weber'};
    unitPrefixes = {' ','deci','centi','milli','micro','nano','pico','femto','atto','zepto','yocto','deca','hecto','kilo','mega','giga','tera','peta','exa','zetta','yotta'};
    bidsTbl.ColumnFormat = {[] [] [] [] units unitPrefixes []};

    uicontrol(f, 'Style', 'pushbutton', 'String', 'Add column', 'Units', 'normalized', 'Position', [0.4-0.1 0.074 0.1 0.05], 'Callback', @addColumnCB, 'Tag', 'addColumnBtn');
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Import', 'Units', 'normalized', 'Position', [0.4-0.2 0.074 0.1 0.05], 'Callback', {@importSpreadsheet}, 'Tag', 'importSpreadsheetBtn');
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Ok', 'Units', 'normalized', 'Position', [0.85 0.02 0.1 0.05], 'Callback', @okCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Cancel', 'Units', 'normalized', 'Position', [0.7 0.02 0.1 0.05], 'Callback', @cancelCB); 
    
    % pre-populate BIDS table
    data = cell(length(pFields),length(bidsTbl.ColumnName));
    for i=1:length(pFields)
        % pre-populate description
        field = pFields{i};
        if numel(EEG) == 1 || ~isfield(pInfoBIDS.(field),'Levels') % if previous specification of this field didn't include Levels
            data{i,find(strcmp(bidsTbl.ColumnName, 'Levels'))} = 'n/a';
        elseif isstruct(pInfoBIDS.(field).Levels) && (isempty(pInfoBIDS.(field).Levels) || isempty(fieldnames(pInfoBIDS.(field).Levels)))
            data{i,find(strcmp(bidsTbl.ColumnName, 'Levels'))} = 'Click to specify';
        else
            levelTxt = pInfoBIDS.(field).Levels;
            if isstruct(levelTxt)
                levelTxt = strjoin(fieldnames(pInfoBIDS.(field).Levels),',');
            end
            data{i,find(strcmp(bidsTbl.ColumnName, 'Levels'))} = levelTxt;
        end
        if isfield(pInfoBIDS.(field),'Description')
            data{i,find(strcmp(bidsTbl.ColumnName, 'Description'))} = pInfoBIDS.(field).Description;
        end
        if isfield(pInfoBIDS.(field),'Units')
            data{i,find(strcmp(bidsTbl.ColumnName, 'Units'))} = pInfoBIDS.(field).Units;
        end
        clear('field');
    end
    bidsTbl.Data = data;
    
    if nargin < 3
        %% wait
        waitfor(f);
    elseif nargin < 4 && ischar(varargin{1}) && strcmp(varargin{1}, 'default')
        okCB('','');
    end
    
    
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%----- Helper functions ---------------------------------------------------
    %% import spreadshet
    function importSpreadsheet(~, ~)
        % Get spreadsheet
        [~, ~, ~, structout] = inputgui( { [1 2 0.5] [1]}, {...
                            {'Style', 'text', 'string', 'Spreadsheet to import*'} ...
                            {'Style', 'edit', 'Tag', 'Filepath'} ...
                            {'Style', 'pushbutton', 'string', '...', 'Callback', @browse} ...
                            {'Style', 'text', 'string', '*First row must contain column headers.'}});
        function browse(~,~)
            [name, path] = uigetfile2({'*.xlsx','Excel Files(*.xlsx)'; '*.xls','Excel Files(*.xls)';'*.csv','Comma Separated Value Files(*.csv)';}, 'Choose spreadsheet file');
            if ~isequal(name, 0)
               set(findobj('tag', 'Filepath'), 'string', fullfile(path, name));
            else
                close(gcbf);
            end
            clear tmpfolder;
        end
        
        % Load spreadsheet
        if ~isempty(structout)
            filepath = structout.Filepath;
            T = readtable(filepath);
            columns = T.Properties.VariableNames;
            columns = ["(none)" columns];
            pTable = findobj('Tag', 'pInfoTable');
            columnMap = containers.Map('KeyType','char','ValueType','char');
            idColumn = '';

            % Match spreadsheet columns with GUI columns
            [res userdata err structout] = inputgui('geometry', {[1 1] [1 1] [1 1] [1 1] [1 1] [1 1] [1] [1] [1] [1]}, 'geomvert', [1 1 1 1 1 1 1 1 1 5], 'uilist', {...
                {'Style', 'text', 'string', 'Participant ID column* (required)', 'fontweight', 'bold'} ...
                {'Style', 'popupmenu', 'string', columns, 'Tag', 'ID_Column', 'Callback', @idSelected} ...
                {'Style', 'text', 'string', 'Age column'} ...
                {'Style', 'popupmenu', 'string', columns, 'Tag', 'Age_Column', 'Callback', @fieldSelected} ...
                {'Style', 'text', 'string', 'Gender column'} ...
                {'Style', 'popupmenu', 'string', columns, 'Tag', 'Gender_Column', 'Callback', @fieldSelected} ...
                {'Style', 'text', 'string', 'Group column'} ...
                {'Style', 'popupmenu', 'string', columns, 'Tag', 'Group_Column', 'Callback', @fieldSelected} ...
                {'Style', 'text', 'string', 'Head circumference column'} ...
                {'Style', 'popupmenu', 'string', columns, 'Tag', 'HeadCircumference_Column', 'Callback', @fieldSelected} ...
                {'Style', 'text', 'string', 'Subject artefact column'} ...
                {'Style', 'popupmenu', 'string', columns, 'Tag', 'SubjectArtefactDescription_Column', 'Callback', @fieldSelected} ...
                {} ...
                {'Style', 'text', 'string', 'Choose additional spreadsheet columns to import', 'fontweight', 'bold'} ...
                {'Style', 'text', 'string', '(Hold Ctrl or Shift for multi-select)'} ...
                {'Style', 'listbox', 'string', columns(2:end), 'Tag', 'SpreadsheetColumns', 'max', 2} ...
                });
            if ~isempty(structout)
                listboxCols = columns(2:end);
                importData(listboxCols(structout.SpreadsheetColumns)); 
            end
        end
        
        function idSelected(src,~)
            val = src.Value;
            str = src.String;
            column = str{val};
            if ~strcmp(column, "(none)")
                idColumn = column;
            end
        end
        function fieldSelected(src,~)
            fieldName = split(src.Tag, '_');
            fieldName = fieldName{1};
            val = src.Value;
            str = src.String;
            column = str{val};
            
            if ~strcmp(column, "(none)")
                columnMap(fieldName) = column;
            end
        end
        function importData(additionalCols)
            pIDColIndex = strcmp(pTable.ColumnName, "participant_id");
            
            % participant ids
            rows = pTable.Data(:, pIDColIndex);
            guiRows = [];
            matchedRows = zeros(numel(rows),1);
            for r=1:numel(rows)
                matchedIdx = find(strcmp(rows{r}, T.(idColumn)));
                if ~isempty(matchedIdx)
                    guiRows = [guiRows r];
                    matchedRows(r) = matchedIdx;
                end
            end
            matchedRows = matchedRows(matchedRows > 0);
            
            % process additional columns
            for c=1:numel(additionalCols)
                col = additionalCols{c};
                if ~strcmp(pTable.ColumnName, col), addNewColumn(col); end
                columnMap(col) = col; % same name
            end
            
            % copy data
            keySet = keys(columnMap);
            for k=1:columnMap.Count
                spreadsheetCol = columnMap(keySet{k});
                spreadsheetColData = T.(spreadsheetCol);
                for r=1:numel(guiRows)
                    if isnumeric(spreadsheetColData(1))
                        pTable.Data{guiRows(r), strcmp(pTable.ColumnName, keySet{k})} = spreadsheetColData(matchedRows(r));
                    elseif iscell(spreadsheetColData(1))
                       pTable.Data{guiRows(r), strcmp(pTable.ColumnName, keySet{k})} = spreadsheetColData{matchedRows(r)};
                    end
                end
            end
        end
    end

    
    %% callback handle for cancel button
    function cancelCB(src, event)
        clear('eventBIDS');
        close(f);
    end

    %% callback handle for ok button
    function okCB(src, event)        
        % prepare return struct
        pTable = findobj('Tag', 'pInfoTable');
                
        fields = fieldnames(pInfoBIDS);
        for idx=1:length(fields)
            field = fields{idx};
            pInfoDesc.(field).Description = pInfoBIDS.(field).Description;
            % Only add Units and Levels to pInfoDesc if they have values
            if ~isempty(pInfoBIDS.(field).Units)
                pInfoDesc.(field).Units = pInfoBIDS.(field).Units;
            end
            if (isstruct(pInfoBIDS.(field).Levels) && ~isempty(pInfoBIDS.(field).Levels) && ~isempty(fieldnames(pInfoBIDS.(field).Levels))) || (ischar(pInfoBIDS.(field).Levels) && ~strcmp(pInfoBIDS.(field).Levels, 'n/a'))
                pInfoDesc.(field).Levels = pInfoBIDS.(field).Levels;
            end
        end

        for e=1:numel(EEG)
            if ~isfield(EEG(e),'BIDS')
                EEG(e).BIDS = [];
            end
            tInfo = struct('HeadCircumference', [], 'SubjectArtefactDescription', "");
            if isfield(EEG(e).BIDS,'tInfo')
                tInfo = EEG(e).BIDS.tInfo;
            end
            if ~isempty(EEG(e).subject)
                rowIdx = strcmp(EEG(e).subject, pTable.Data(:, strcmp('participant_id', pTable.ColumnName)));
            elseif ~isempty(STUDY.datasetinfo(1).subject) % assuming order of STUDY.datasetinfo matches with EEG
                rowIdx = strcmp(STUDY.datasetinfo(e).subject, pTable.Data(:, strcmp('participant_id', pTable.ColumnName)));
            end
            if isempty(pTable.Data{rowIdx,strcmp('HeadCircumference',pTable.ColumnName)})
                if isfield(tInfo, 'HeadCircumference')
                    tInfo = rmfield(tInfo, 'HeadCircumference');
                end
            else
                if ~isnumeric(pTable.Data{rowIdx,strcmp('HeadCircumference',pTable.ColumnName)})
                    tInfo.HeadCircumference = str2double(pTable.Data{rowIdx,strcmp('HeadCircumference',pTable.ColumnName)});
                else
                    tInfo.HeadCircumference = pTable.Data{rowIdxstrcmp('HeadCircumference',pTable.ColumnName)};
                end
            end
            if isempty(pTable.Data{rowIdx,strcmp('SubjectArtefactDescription',pTable.ColumnName)})
                if isfield(tInfo, 'SubjectArtefactDescription')
                    tInfo = rmfield(tInfo,'SubjectArtefactDescription');
                end
            else
                if ~ischar(pTable.Data{rowIdx, strcmp('SubjectArtefactDescription',pTable.ColumnName)})
                    tInfo.SubjectArtefactDescription = char(pTable.Data{rowIdx,strcmp('SubjectArtefactDescription',pTable.ColumnName)});
                else
                    tInfo.SubjectArtefactDescription = pTable.Data{rowIdx,strcmp('SubjectArtefactDescription',pTable.ColumnName)};
                end
            end
            EEG(e).BIDS.tInfo = tInfo;
            EEG(e).BIDS.pInfoDesc = pInfoDesc;
            colIdx = 1:numel(pTable.ColumnName);
            colIdx = colIdx(~strcmp('HeadCircumference',pTable.ColumnName) & ~strcmp('SubjectArtefactDescription',pTable.ColumnName)); % these are not pInfo fields
            
            
            EEG(e).BIDS.pInfo = [pFields; pTable.Data(rowIdx,colIdx)];
            EEG(e).saved = 'no';
            EEG(e).history = [EEG(e).history command];
        end       
        
        clear('pInfoBIDS');
        close(f);
    end

    %% callback handle for Add Column button
    function addColumnCB(~,~)
        opts.Interpreter = 'tex';
        answer = inputdlg("\fontsize{13} Enter new column name, no space allowed:", 'New column name',1,{''}, opts);
        
        if ~isempty(answer)
            addNewColumn(answer{1});
        end
    end
    function addNewColumn(newColName)
        % input validation
        newField = checkFormat(newColName);

        pFields = [pFields newField];

        % add to pInfoBIDS structure
        pInfoBIDS.(newField).Description = ''; 
        pInfoBIDS.(newField).Levels = struct([]);
        pInfoBIDS.(newField).Units = '';

        % update Tables
        pInfoTbl.ColumnName = [pInfoTbl.ColumnName;newField];
        temp = pInfoTbl.Data;
        pInfoTbl.Data = cell(size(pInfoTbl.Data,1), size(pInfoTbl.Data,2)+1);
        pInfoTbl.Data(:,1:size(temp,2)) = temp; 

        bidsTbl.RowName = [bidsTbl.RowName;newField];
        temp = bidsTbl.Data;
        bidsTbl.Data = cell(size(bidsTbl.Data,1)+1, size(bidsTbl.Data,2));
        bidsTbl.Data(1:size(temp,1),:) = temp;
        bidsTbl.Data{end,find(strcmp(bidsTbl.ColumnName, 'Levels'))} = 'Click to specify'; 
    end
    %% callback handle for cell selection in the participant info table
    function pInfoCellSelectedCB(arg1, obj)
        removeLevelUI();
        tbl = obj.Source;
        if ~isempty(obj.Indices)
            uicontrol(f, 'Style', 'text', 'String', tbl.Data{obj.Indices(1), 1}, 'Units', 'normalized', 'Position',[0.02 0 0.38 0.08], 'HorizontalAlignment', 'left', 'FontSize',11,'FontAngle','italic','ForegroundColor', fg,'BackgroundColor', bg);
            if strcmp(obj.Source.ColumnName{obj.Indices(2)}, 'SubjectArtefactDescription')
                uicontrol(f, 'Style', 'text', 'String', 'Input for Subject Artefact Description', 'Units', 'normalized', 'Position',[0.42 0.43 0.68 0.05], 'HorizontalAlignment', 'left','FontAngle','italic','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'cellContentHeader');
                uicontrol(f, 'Style', 'edit', 'String', obj.Source.Data{obj.Indices(1),obj.Indices(2)}, 'Units', 'normalized', 'Max',2,'Min',0,'Position',[0.42 0.23 0.5 0.2], 'HorizontalAlignment', 'left', 'Callback', {@artefactCB, obj}, 'Tag', 'cellContentMsg');
            end
        end
    end

    %% callback handle for cell edit in pInfo table
    function pInfoCellEditCB(arg1, obj, input)
        row = obj.Indices(1);
        col = obj.Indices(2);
        pTbl = obj.Source;
        if ~isempty(pTbl.Data{row, strcmp('participant_id', pTbl.ColumnName)})
            if exist('input','var') % called from edit box for artefact description
                entered = input;
            else
                entered = obj.EditData;
            end
            % for each row of the pInfo table
            for r=1:size(pTbl.Data,1)
                % if same subject with celected cell then copy value to that row as well
                participantColIdx = find(strcmp(pTbl.ColumnName,'participant_id'));
                if strcmp(pTbl.Data{r,participantColIdx}, pTbl.Data{row,participantColIdx})
                    pTbl.Data{r,col} = entered;
                end
            end
        end
    end

    %% callback handle for cell selection in the BIDS table
    function bidsCellSelectedCB(arg1, obj) 
        if size(obj.Indices,1) == 1
            removeLevelUI();
            row = obj.Indices(1);
            col = obj.Indices(2);
            field = obj.Source.RowName{row};
            columnName = obj.Source.ColumnName{col};
            
            if strcmp(columnName, 'Levels')
                createLevelUI('','',obj,field);
            elseif strcmp(columnName, 'Description')
                uicontrol(f, 'Style', 'text', 'String', sprintf('%s (%s):',columnName, 'full description of the field'), 'Units', 'normalized', 'Position',[0.42 0.43 0.68 0.05], 'HorizontalAlignment', 'left','FontAngle','italic','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'cellContentHeader');
                uicontrol(f, 'Style', 'edit', 'String', obj.Source.Data{row,col}, 'Units', 'normalized', 'Max',2,'Min',0,'Position',[0.42 0.23 0.5 0.2], 'HorizontalAlignment', 'left', 'Callback', {@descriptionCB, obj,field}, 'Tag', 'cellContentMsg');
            end
        end
    end
    
    
    %% callback handle for cell edit in BIDS table
    function bidsCellEditCB(arg1, obj)
        field = obj.Source.RowName{obj.Indices(1)};
        column = obj.Source.ColumnName{obj.Indices(2)};
        if ~strcmp(column, 'Levels')
            pInfoBIDS.(field).(column) = obj.EditData;
        end
    end
    
    function descriptionCB(src,event,obj,field) 
        obj.Source.Data{obj.Indices(1),obj.Indices(2)} = src.String;
        pInfoBIDS.(field).Description = src.String;
    end

    function artefactCB(src,event,obj) 
        obj.Source.Data{obj.Indices(1),obj.Indices(2)} = src.String;
        pInfoCellEditCB(src, obj, src.String);
    end

    function createLevelUI(src,event,table,field)
        removeLevelUI();
        lvlHeight = 0.43;
        if numel(EEG) == 1
            uicontrol(f, 'Style', 'text', 'String', 'Documentation of levels does not apply to single dataset - edit at the study level.', 'Units', 'normalized', 'Position', [0.42 lvlHeight bidsWidth 0.05],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
        elseif strcmp(field, 'Participant_ID') || strcmp(field, 'Age')
            uicontrol(f, 'Style', 'text', 'String', 'Levels editing does not apply to this field.', 'Units', 'normalized', 'Position', [0.42 lvlHeight bidsWidth 0.05],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
        else
            pTable = findobj('Tag', 'pInfoTable');
            if numel(pTable) > 1
                pTable = pTable(1);
            end
            colIdx = find(strcmp(pTable.ColumnName, field));
            levelCellText = table.Source.Data{find(strcmp(table.Source.RowName, field)), find(strcmp(table.Source.ColumnName, 'Levels'))}; % text (fieldName-Levels) cell. if 'n/a' then no action, 'Click to..' then conditional action, '<value>,...' then get levels
            % retrieve all unique values
%             if isnumeric(pTable.Data{1,colIdx}) % values already in string format
%                 values = arrayfun(@(x) num2str(x), [pTable.Data{:,colIdx}], 'UniformOutput', false);
%                 levels = unique(values)';
%             else
                values = {pTable.Data{:,colIdx}};
                idx = cellfun(@isempty, values);
                levels = unique(values(~idx))';
%             end
            if strcmp(levelCellText,'n/a')
                uicontrol(f, 'Style', 'text', 'String', 'Levels editing does not apply to this field.', 'Units', 'normalized', 'Position', [0.42 lvlHeight bidsWidth 0.05],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
            elseif isempty(levels)
                uicontrol(f, 'Style', 'text', 'String', 'No value found. Please specify values in Participant information table.', 'Units', 'normalized', 'Position', [0.42 lvlHeight 0.58 0.05],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
            elseif strcmp('Click to specify', levelCellText) && length(levels) > levelThreshold 
                msg = sprintf('\tThere are more than %d unique levels for field %s.\nAre you sure you want to specify levels for it?', levelThreshold, field);
                c4 = uicontrol(f, 'Style', 'text', 'String', msg, 'Units', 'normalized', 'FontWeight', 'bold', 'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'confirmMsg');
                c4.Position = [0.42 lvlHeight-0.05 0.58 0.1];
                c5 = uicontrol(f, 'Style', 'pushbutton', 'String', 'Yes', 'Units', 'normalized','Tag', 'confirmBtn', 'Callback', {@ignoreThresholdCB,table,field});
                c5.Position = [0.42+0.58/2-0.1/2 lvlHeight-0.1 0.1 0.05];
            else
                % build table data
                t = cell(length(levels),2);
                for lvl=1:length(levels)
                    formattedLevel = checkFormat(levels{lvl}); % put level in the right format for indexing. Number is prepended by 'x'
                    t{lvl,1} = formattedLevel;
                    if ~isempty(pInfoBIDS.(field).Levels) && isfield(pInfoBIDS.(field).Levels, formattedLevel)
                        t{lvl,2} = pInfoBIDS.(field).Levels.(formattedLevel);
                    end
                end
                % create UI
                uicontrol(f, 'Style', 'text', 'String', ['Describe the categorical values of participant field ' field], 'Units', 'normalized', 'HorizontalAlignment', 'left', 'Position', [0.52 0.45 0.53 0.05],'FontWeight', 'bold','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
                msg = 'BIDS allows you to describe the level for each of your categorical field. Describing levels helps other researchers to understand your experiment better';
                uicontrol(f, 'Style', 'text', 'String', msg, 'Units', 'normalized', 'HorizontalAlignment', 'Left','Position', [0.42 0.02 0.15 0.36],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelMsg');
                h = uitable(f, 'Data', t(:,2), 'ColumnName', {'Description'}, 'RowName', t(:,1), 'Units', 'normalized', 'Position', [0.58 0.08 0.4 0.36], 'FontSize', fontSize, 'Tag', 'levelEditTbl', 'CellEditCallback',{@levelEditCB,field},'ColumnEditable',true); 
                h.ColumnWidth = {appWidth*0.4*0.9};
            end
        end
    end
    function ignoreThresholdCB(src,event,table, field)
        table.Source.Data{find(strcmp(table.Source.RowName, field)), find(strcmp(table.Source.ColumnName, 'Levels'))} = 'Click to specify below (ignore max number of levels threshold)';
        createLevelUI('','',table,field);
    end
    function levelEditCB(arg1, obj, field)
        level = checkFormat(obj.Source.RowName{obj.Indices(1)});
        description = obj.EditData;
        pInfoBIDS.(field).Levels.(level) = description;
        specified_levels = fieldnames(pInfoBIDS.(field).Levels);
        % Update main table
        mainTable = findobj('Tag','bidsTable');
        mainTable.Data{find(strcmp(field,mainTable.RowName)),find(strcmp('Levels',mainTable.ColumnName))} = strjoin(specified_levels, ',');
    end
    
    function bidsFieldSelected(src, event, table, row, col) 
        val = src.Value;
        str = src.String;
        selected = str{val};
        table.Data{row,col} = selected;
        field = table.RowName{row};
        eventBIDS.(field).BIDSField = selected;
    end
    function formatted = checkFormat(str)
        if ~isempty(str2num(str))
            formatted = ['x' str];
        else
            formatted = strrep(str,' ','_'); %replace space with _
        end
    end
    function removeLevelUI()
        % remove old ui items of level section if exist
        h = findobj('Tag', 'levelEditMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'levelEditTbl');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'confirmMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'confirmBtn');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'noBidsMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'cellContentMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'cellContentHeader');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'selectBIDSMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'selectBIDSDD');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'levelMsg');
        if ~isempty(h)
            delete(h);
        end
    end
    function [pBIDS, pFields] = newpInfoBIDS()
        pBIDS = getpInfoDesc();
        if isempty(pBIDS)
            pFields = { 'participant_id' 'Gender' 'Age' 'Group'};
            for idx=1:length(pFields)
                if strcmp(pFields{idx}, 'participant_id')
                    pBIDS.participant_id.Description = 'Unique participant label';
                    pBIDS.participant_id.Units = '';
                    pBIDS.participant_id.Levels = 'n/a';
                elseif strcmp(pFields{idx}, 'Gender')
                    pBIDS.Gender.Description = 'Participant gender';      
                    pBIDS.Gender.Levels = struct;
                    pBIDS.Gender.Units = '';
                elseif strcmp(pFields{idx}, 'Age')
                    pBIDS.Age.Description = 'Participant age (years)';
                    pBIDS.Age.Units = 'years';
                    pBIDS.Age.Levels = 'n/a';
                elseif strcmp(pFields{idx}, 'Group')
                    pBIDS.Group.Description = 'Participant group label';
                    pBIDS.Group.Units = '';
                    pBIDS.Group.Levels = struct;
                end
            end
        else
            pFields = fieldnames(pBIDS)';
            for p=1:numel(pFields)
                if ~isfield(pBIDS.(pFields{p}), 'Units')
                    if strcmp(pFields{p}, 'Age')
                        pBIDS.(pFields{p}).Units = 'years';
                    else
                        pBIDS.(pFields{p}).Units = '';
                    end
                end
                if ~isfield(pBIDS.(pFields{p}), 'Levels')
                    if strcmp(pFields{p}, 'Age') || strcmp(pFields{p}, 'participant_id')
                        pBIDS.(pFields{p}).Levels = 'n/a';
                    else
                        pBIDS.(pFields{p}).Levels = struct;
                    end
                end
            end
        end 
        % Get BIDS information
        function info = getpInfoDesc()
            hasBIDS = arrayfun(@(x) isfield(x,'BIDS') && ~isempty(x.BIDS),EEG);
            if sum(hasBIDS) == 0 %if no BIDS found for any EEG
                info = [];
            else % at least one EEG has BIDS
                if sum(hasBIDS) < numel(EEG) % not all have BIDS
                    warning('Not all EEG contains BIDS information.');
                end
                haspInfoDesc = arrayfun(@(x) isfield(x,'BIDS') && isfield(x.BIDS,'pInfoDesc') && ~isempty(x.BIDS.pInfoDesc),EEG);
                if sum(haspInfoDesc) == 0
                    info = [];
                else % at least one EEG has BIDS.pInfoDesc
                    try
                        bids = [EEG(haspInfoDesc).BIDS];
                        allpInfoDesc = [bids.pInfoDesc];
                        if numel(allpInfoDesc) < numel(EEG)
                            info = EEG(find(haspInfoDesc,1)).BIDS.pInfoDesc;
                            warning('Not all EEG contains BIDS information. Using BIDS information of EEG(%d)...',find(haspInfoDesc,1));
                        else
                            info = allpInfoDesc(1);
                            fprintf('Using BIDS information of the first dataset for all datasets...\n');
                        end
                    catch % field inconsistent
                        info = EEG(find(haspInfoDesc,1)).BIDS.pInfoDesc;
                        warning('Inconsistence found in BIDS information across STUDY datasets. Using BIDS information of EEG(%d)...',find(haspInfoDesc,1));
                    end
                end
            end
        end
    end
end
