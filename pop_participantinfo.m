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
%
% This function use sort_nat by Douglas Schwartz with the following
% copyright
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.
function [EEG, command] = pop_participantinfo(EEG,STUDY, varargin)
    command = '[EEG, command] = pop_participantinfo(EEG);';
    
    %% check if there's already an opened window
    if ~isempty(findobj('Tag','pInfoTable'))
        errordlg2('A window is already openened for pop_participantinfo');
        return
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
    if isfield(EEG(1), 'subject') && ~isempty(EEG(1).subject)
        allSubjects = { EEG.subject };
    elseif isfield(STUDY,'datasetinfo') && isfield(STUDY.datasetinfo(1), 'subject') && ~isempty(STUDY.datasetinfo(1).subject)
        allSubjects = { STUDY.datasetinfo.subject };
    else
        if numel(EEG) == 1
            errordlg2('No subject ID found. Please fill in "Subject code" in the next window, then resume.');
            EEG = pop_editset(EEG);
        else
            errordlg2('No subject info found in STUDY. Please add using "Study > Edit study info", then resume.');
        end
        return
    end
    emptySubjs = cellfun(@isempty, allSubjects);
    if any(emptySubjs)
        errordlg2(sprintf('No subject ID found for dataset at index: %s. Please add and resume.', mat2str(find(emptySubjs))));
        return
    else
        uniqueSubjects = sort_nat(unique(allSubjects));
    end
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

    defaultFields = {'participant_id' 'Gender' 'Age' 'Group' 'HeadCircumference' 'SubjectArtefactDescription'};
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Remove column', 'Units', 'normalized', 'Position', [0.4-0.1 0.074 0.1 0.05], 'Callback', {@removeColumnCB, pInfoTbl, defaultFields}, 'Tag', 'removeColumnBtn');
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Add/Edit column', 'Units', 'normalized', 'Position', [0.4-0.2 0.074 0.1 0.05], 'Callback', {@editColumnCB, pInfoTbl, defaultFields}, 'Tag', 'addColumnBtn');
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Import column(s)', 'Units', 'normalized', 'Position', [0.4-0.3 0.074 0.1 0.05], 'Callback', {@importSpreadsheet}, 'Tag', 'importSpreadsheetBtn');
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Ok', 'Units', 'normalized', 'Position', [0.85 0.02 0.1 0.05], 'Callback', @okCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Cancel', 'Units', 'normalized', 'Position', [0.7 0.02 0.1 0.05], 'Callback', @cancelCB); 
    
    % pre-populate BIDS table
    data = cell(length(pFields),length(bidsTbl.ColumnName));
    for i=1:length(pFields)
        % pre-populate description
        field = pFields{i};
        if numel(EEG) == 1 || ~isfield(pInfoBIDS.(field),'Levels') % if previous specification of this field didn't include Levels
            data{i,strcmp(bidsTbl.ColumnName, 'Levels')} = 'n/a';
        elseif isstruct(pInfoBIDS.(field).Levels) && (isempty(pInfoBIDS.(field).Levels) || isempty(fieldnames(pInfoBIDS.(field).Levels)))
            data{i,strcmp(bidsTbl.ColumnName, 'Levels')} = 'Click to specify';
        else
            levelTxt = pInfoBIDS.(field).Levels;
            if isstruct(levelTxt)
                levelTxt = strjoin(fieldnames(pInfoBIDS.(field).Levels),',');
            end
            data{i,strcmp(bidsTbl.ColumnName, 'Levels')} = levelTxt;
        end
        if isfield(pInfoBIDS.(field),'Description')
            data{i,strcmp(bidsTbl.ColumnName, 'Description')} = pInfoBIDS.(field).Description;
        end
        if isfield(pInfoBIDS.(field),'Units')
            data{i,strcmp(bidsTbl.ColumnName, 'Units')} = pInfoBIDS.(field).Units;
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
         supergui( 'geomhoriz', { 1 1 1 [1 1] }, 'uilist', { ...
         { 'style', 'text', 'string', 'Warning: First row must contains column headers!', 'fontweight', 'bold' },...
         { 'style', 'text', 'string', 'Supported file formats: .txt, .csv, .tsv, .xlsx, .xls' }, { }, ...
         { 'style', 'pushbutton' , 'string', 'Cancel', 'callback', 'close(gcbf)'  } ...
         { 'style', 'pushbutton' , 'string', 'OK', 'callback', @proceed } } );
        function proceed(~,~)
            close(gcbf); % close column header warning dialog
            [name, path] = uigetfile2({'*'}, 'Choose spreadsheet file');
            filepath = '';
            allowedFormats = {'.txt', '.csv', '.tsv', '.xlsx', '.xls'};
            if ~isequal(name, 0)
               filepath = fullfile(path, name);
               if ~any(endsWith(filepath, allowedFormats))
                   supergui( 'geomhoriz', { 1 1 1 1 }, 'uilist', { ...
                         { 'style', 'text', 'string', 'Selected file format is NOT among those supported'},... 
                         { 'style', 'text', 'string', '(.txt, .csv, .tsv, .xlsx, .xls)' }, { }, ...
                         { 'style', 'pushbutton' , 'string', 'Ok', 'callback', 'close(gcbf)'  } ...
                         } );
                   filepath = '';
               end
            else
                close(gcbf);
            end
            clear tmpfolder;
            
            % Load spreadsheet
            if ~isempty(filepath)
                try
                    warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames')
                    if endsWith(filepath,'.tsv')
                        T = readtable(filepath, 'filetype', 'text');
                    else
                        T = readtable(filepath);
                    end
                catch
                    errordlg2('Error importing data.');
                    return
                end

                columns = T.Properties.VariableNames;
                columns = ["(none)" columns];
                pTable = findobj('Tag', 'pInfoTable');
                columnMap = containers.Map('KeyType','char','ValueType','char');
                idColumn = '';

                % Match spreadsheet columns with GUI columns
                [~, ~, ~, structout] = inputgui('geometry', {[1 1] [1 1] [1 1] [1 1] [1 1] [1 1] 1 1 1 1}, 'geomvert', [1 1 1 1 1 1 1 1 1 5], 'uilist', {...
                    {'Style', 'text', 'string', 'Participant ID column* (required)', 'fontweight', 'bold', 'fontsize', 14} ...
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
                    {'Style', 'checkbox', 'string', 'Choose additional spreadsheet columns to import', 'Tag', 'HasAdditionalCols', 'fontweight', 'bold', 'callback', @chooseColumnSelected} ...
                    {'Style', 'text', 'string', '(Hold Ctrl or Shift for multi-select)'} ...
                    {'Style', 'listbox', 'string', columns(2:end), 'Tag', 'SpreadsheetColumns', 'max', 2, 'Enable', 'off'} ...
                    });
                if ~isempty(structout)
                    if isempty(idColumn) || strcmp(idColumn, '(none)')
                        supergui( 'geomhoriz', { 1 1 1 }, 'uilist', { ...
                         { 'style', 'text', 'string', 'Participant ID column was not set. Abort.' }, { }, ...
                         { 'style', 'pushbutton' , 'string', 'Ok', 'callback', 'close(gcbf)'  } ...
                         } );
                    else
                        listboxCols = columns(2:end);
                        if structout.HasAdditionalCols == 1
                            importData(listboxCols(structout.SpreadsheetColumns)); 
                        else
                            importData([]);
                        end
                    end
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
            function chooseColumnSelected(src,~)
                if src.Value == 1
                    set(findobj('Tag', 'SpreadsheetColumns'), 'Enable', 'on');
                else
                    set(findobj('Tag', 'SpreadsheetColumns'), 'Enable', 'off');
                end
            end
            % import subject data from spreadsheet to GUI
            function importData(additionalCols)
                pIDColIndex = strcmp(pTable.ColumnName, "participant_id");

                % participant ids
                allGUIRows = pTable.Data(:, pIDColIndex); % all participants in GUI
                matchedGUIRows = []; % 
                matchedSpreadsheetRows = zeros(numel(allGUIRows),1); % index of row in spreadsheet that matches GUI row
                for r=1:numel(allGUIRows)
                    matchedIdx = find(strcmp(allGUIRows{r}, T.(idColumn)));
                    if ~isempty(matchedIdx)
                        matchedGUIRows = [matchedGUIRows r];
                        matchedSpreadsheetRows(r) = matchedIdx;
                    end
                end
                if numel(matchedGUIRows) < numel(allGUIRows)
                    unmatchedSubjs = setdiff(1:numel(allGUIRows),matchedGUIRows);
                    if numel(unmatchedSubjs) == numel(allGUIRows)
                        errordlg2('No matched subject between dataset and spreadsheet found.');
                        return
                    else
                        errordlg2(sprintf('%d subjects (%s) not found in spreadsheet.', numel(unmatchedSubjs), strjoin(allGUIRows(unmatchedSubjs), ',')));
                        return
                    end
                end
                
                matchedSpreadsheetRows = matchedSpreadsheetRows(matchedSpreadsheetRows > 0); % only keep those that match
                if numel(matchedSpreadsheetRows) < numel(T.(idColumn))
                    warndlg2('There are more subjects in spreadsheet than in the dataset. Importing data only for those in dataset...');
                end
                
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
                    for r=1:numel(matchedGUIRows)
                        if isnumeric(spreadsheetColData(1))
                            pTable.Data{matchedGUIRows(r), strcmp(pTable.ColumnName, keySet{k})} = spreadsheetColData(matchedSpreadsheetRows(r));
                        elseif iscell(spreadsheetColData(1))
                           pTable.Data{matchedGUIRows(r), strcmp(pTable.ColumnName, keySet{k})} = spreadsheetColData{matchedSpreadsheetRows(r)};
                        end
                    end
                end
            end
        end 
    end

    
    %% callback handle for cancel button
    function cancelCB(~, ~)
        clear('eventBIDS');
        close(f);
    end

    %% callback handle for ok button
    function okCB(~, ~)        
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
            elseif ~isempty(STUDY.datasetinfo(1).subject) % assuming order of STUDY.datasetinfo matches with order of EEG in the EEG array
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
                    tInfo.HeadCircumference = pTable.Data{rowIdx,strcmp('HeadCircumference',pTable.ColumnName)};
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

    %% add new column to pInfo GUI table
    % used by both import and editColumn button
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
        pInfoTbl.ColumnEditable = [pInfoTbl.ColumnEditable true];

        bidsTbl.RowName = [bidsTbl.RowName;newField];
        temp = bidsTbl.Data;
        bidsTbl.Data = cell(size(bidsTbl.Data,1)+1, size(bidsTbl.Data,2));
        bidsTbl.Data(1:size(temp,1),:) = temp;
        bidsTbl.Data{end,strcmp(bidsTbl.ColumnName, 'Levels')} = 'Click to specify'; 
    end

    %% callback handle for Add/Edit Column button
    function editColumnCB(~, ~, table, defaultBIDSFields)
        allowedFields = ['(none)' setdiff(table.ColumnName', defaultBIDSFields)];
        [~, ~, ~, structout] = inputgui('geometry', {[1 1] 1 [1 1 1 1]}, 'geomvert', [1 1 1], 'uilist', {...
                {'Style', 'text', 'string', 'New column name (no space):'} ...
                {'Style', 'edit', 'Tag', 'new_name'} ...
                {} ...
                {'Style', 'text', 'string', 'Rename column'} ...
                {'Style', 'popupmenu', 'string', allowedFields, 'Tag', 'renamed_column_target'} ...
                {'Style', 'text', 'string', 'to:'} ...
                {'Style', 'edit', 'Tag', 'renamed_column_dest'} ...
                });
        if ~isempty(structout)
            if ~isempty(structout.new_name)
                addNewColumn(structout.new_name);
            end
            if ~isempty(structout.renamed_column_target) && structout.renamed_column_target > 1
                targetColumn = allowedFields{structout.renamed_column_target};
                if ~isempty(structout.renamed_column_dest)
                    renameColumn(targetColumn, structout.renamed_column_dest);
                end
            end            
        end
        function renameColumn(target, destination)
            % input validation
            colName = checkFormat(destination);
            
            pFields = strrep(pFields, target, colName);
            % update pInfoBIDS structure
            if isfield(pInfoBIDS, target)
                pInfoBIDS.(colName) = pInfoBIDS.(target);
                pInfoBIDS = rmfield(pInfoBIDS, target);
            end
            % update Tables
            colIdx = strcmp(pInfoTbl.ColumnName,target);
            if any(colIdx)
                pInfoTbl.ColumnName{colIdx} = colName;
            end
            rowIdx = strcmp(bidsTbl.RowName, target);
            if any(rowIdx)
                bidsTbl.RowName{rowIdx} = colName;
            end  
        end
    end

    %% callback handle for Add/Edit Column button
    function removeColumnCB(~, ~, table, defaultBIDSFields)
        allowedFields = ['(none)' setdiff(table.ColumnName', defaultBIDSFields)];
        [~, ~, ~, structout] = inputgui('geometry', {[1 1]}, 'geomvert', 1, 'uilist', {...
                {'Style', 'text', 'string', 'Column to remove (*cannot be undone):'} ...
                {'Style', 'popupmenu', 'string', allowedFields, 'Tag', 'removed_column'} ...
                });
        if ~isempty(structout)
            if ~isempty(structout.removed_column) && structout.removed_column > 1
                removedColumn = allowedFields{structout.removed_column};
                removeColumn(removedColumn);
            end
        end
        function removeColumn(colName)
            pFields(strcmp(pFields, colName)) = [];

            % remove from pInfoBIDS structure
            if isfield(pInfoBIDS, colName)
                pInfoBIDS = rmfield(pInfoBIDS, colName);
            end
            % update Tables
            colIdx = strcmp(pInfoTbl.ColumnName,colName);
            if any(colIdx)
                pInfoTbl.Data(:, colIdx) = [];
                pInfoTbl.ColumnName(colIdx) = [];
            end
            rowIdx = strcmp(bidsTbl.RowName, colName);
            if any(rowIdx)
                bidsTbl.Data(rowIdx,:) = [];
                bidsTbl.RowName(rowIdx) = [];
            end
        end
    end

    %% callback handle for cell selection in the participant info table
    function pInfoCellSelectedCB(~, obj)
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
    function pInfoCellEditCB(~, obj, input)
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
    function bidsCellSelectedCB(~, obj) 
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
    function bidsCellEditCB(~, obj)
        field = obj.Source.RowName{obj.Indices(1)};
        column = obj.Source.ColumnName{obj.Indices(2)};
        if ~strcmp(column, 'Levels')
            pInfoBIDS.(field).(column) = obj.EditData;
        end
    end
    
    function descriptionCB(src,~,obj,field) 
        obj.Source.Data{obj.Indices(1),obj.Indices(2)} = src.String;
        pInfoBIDS.(field).Description = src.String;
    end

    function artefactCB(src,~,obj) 
        obj.Source.Data{obj.Indices(1),obj.Indices(2)} = src.String;
        pInfoCellEditCB(src, obj, src.String);
    end

    function createLevelUI(~,~,table,field)
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
            colIdx = strcmp(pTable.ColumnName, field);
            levelCellText = table.Source.Data{strcmp(table.Source.RowName, field), strcmp(table.Source.ColumnName, 'Levels')}; % text (fieldName-Levels) cell. if 'n/a' then no action, 'Click to..' then conditional action, '<value>,...' then get levels
            % retrieve all unique values
            values = pTable.Data(:,colIdx);
            idx = cellfun(@isempty, values);
            levels = unique(values(~idx))';
            
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
    function ignoreThresholdCB(~,~,table, field)
        table.Source.Data{strcmp(table.Source.RowName, field), strcmp(table.Source.ColumnName, 'Levels')} = 'Click to specify below (ignore max number of levels threshold)';
        createLevelUI('','',table,field);
    end
    function levelEditCB(~, obj, field)
        level = checkFormat(obj.Source.RowName{obj.Indices(1)});
        description = obj.EditData;
        if isempty(pInfoBIDS.(field).Levels)
            temp = [];
            temp.(level) = description;
            pInfoBIDS.(field).Levels = temp;
        else
            pInfoBIDS.(field).Levels.(level) = description;
        end
        specified_levels = fieldnames(pInfoBIDS.(field).Levels);
        % Update main table
        mainTable = findobj('Tag','bidsTable');
        mainTable.Data{strcmp(field,mainTable.RowName),strcmp('Levels',mainTable.ColumnName)} = strjoin(specified_levels, ',');
    end
    
    function bidsFieldSelected(src, ~, table, row, col) 
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
