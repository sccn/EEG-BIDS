% pop_eventinfo() - GUI for BIDS event info editing, generated based on
%                   fields of EEG.event
%
% Usage:
%   >> [EEG, eInfoDesc, eInfo] = pop_eventinfo( EEG );
%                                              
% Inputs:
%   EEG        - EEG dataset structure. May only contain one dataset.
%
% Optional input:
%  'default'   - generate BIDS event info using default values without
%                popping up the GUI
% Outputs:
%  'EEG'       - [struct] Updated EEG structure containing event BIDS information
%                in each EEG structure at EEG.BIDS.eInfoDesc and EEG.BIDS.eInfo
%
%  'eInfoDesc' - [struct] structure describing BIDS event fields as you specified.
%                See BIDS specification for all suggested fields.
%
%  'eInfo'     - [cell] BIDS event fields and their corresponding
%                event fields in the EEGLAB event structure. Note that
%                EEGLAB event latency, duration, and type are inserted
%                automatically as columns "onset" (latency in sec), "duration"
%                (duration in sec), "value" (EEGLAB event type)
%
% Author: Dung Truong, Arnaud Delorme
function [EEG, command] = pop_eventinfo(EEG, varargin)
    %% check if there's already an opened window
    if ~isempty(findobj('Tag','eventBidsTable'))
        errordlg2('A window is already openened for pop_eventinfo');
        return
    end
    
    command = '[EEG, command] = pop_eventinfo(EEG)';
    % perform check to make sure EEG.event is consistent across EEG
    if isempty(EEG(1).event)
        errordlg2('EEG.event is empty for first dataset');
        return
        
    end
    try
       eventFields = fieldnames([EEG.event]);
    catch ME
        if (strcmp(ME.identifier, 'MATLAB:catenate:structFieldBad'))
            numFields = cellfun(@(x) numel(fieldnames(x)), {EEG.event});
            [num, index] = max(numFields);
            eventFields = fieldnames(EEG(index).event);
            warning('There is mismatch in number of fields in EEG.event structures. Using fields of EEG(%d) which has the highest number of fields (%d).', index, num);
        end
    end
    bidsFields = {'onset', 'duration', 'trial_type','value','stim_file','sample','response_time','HED'};    
    eventFields = setdiff(eventFields, 'latency');
    % define global variables
    % -----------------------
    % main data structure containing event info to be updated by events in GUI
    eventBIDS = newEventBIDS(EEG, eventFields, bidsFields); 
    % default GUI settings
    appWidth = 800;
    appHeight = 500;
    bg = [0.65 0.76 1];
    fg = [0 0 0.4];
    levelThreshold = 20;
    fontSize = 12;
        
    % Use GUI
    if nargin < 2
        % create UI
        f = figure('MenuBar', 'None', 'ToolBar', 'None', 'Name', 'Edit BIDS event info - pop_eventinfo', 'Color', bg);
        f.Position(3) = appWidth;
        f.Position(4) = appHeight;
        uicontrol(f, 'Style', 'text', 'String', 'BIDS information for EEG.event fields', 'Units', 'normalized','FontWeight','bold','ForegroundColor', fg,'BackgroundColor', bg, 'Position', [0 0.9 1 0.1]);
        tbl = uitable(f, 'RowName',[],'ColumnName', { 'BIDS Field' 'EEGLAB Field' 'Levels' 'LongName' 'Description' 'Unit Name' 'Unit Prefix' 'TermURL' }, 'Units', 'normalized', 'FontSize', fontSize, 'Tag', 'eventBidsTable');
        tbl.Position = [0.01 0.54 0.98 0.41];
        tbl.CellSelectionCallback = {@cellSelectedCB, eventFields};
        tbl.CellEditCallback = @cellEditCB;
        tbl.ColumnEditable = [false false false true true true true true];
        tbl.ColumnWidth = {appWidth/9, appWidth/9,appWidth/9,appWidth*2/9,appWidth*2/9,appWidth/9,appWidth/9,appWidth/9};
        units = {' ','ampere','becquerel','candela','coulomb','degree Celsius','farad','gray','henry','hertz','joule','katal','kelvin','kilogram','lumen','lux','metre','mole','newton','ohm','pascal','radian','second','siemens','sievert','steradian','tesla','volt','watt','weber'};
        unitPrefixes = {' ','deci','centi','milli','micro','nano','pico','femto','atto','zepto','yocto','deca','hecto','kilo','mega','giga','tera','peta','exa','zetta','yotta'};
        tbl.ColumnFormat = {[] [] [] [] [] units unitPrefixes []};
        uicontrol(f, 'Style', 'pushbutton', 'String', 'Add BIDS field', 'Units', 'normalized', 'Position', [0.01 0.49 0.22 0.05], 'Callback', {@addFieldCB, tbl});
        uicontrol(f, 'Style', 'pushbutton', 'String', 'Remove BIDS field', 'Units', 'normalized', 'Position', [0.24 0.49 0.22 0.05], 'Callback', {@removeFieldCB, tbl, bidsFields});
        uicontrol(f, 'Style', 'pushbutton', 'String', 'Ok', 'Units', 'normalized', 'Position', [0.85 0 0.1 0.05], 'Callback', @okCB); 
        uicontrol(f, 'Style', 'pushbutton', 'String', 'Cancel', 'Units', 'normalized', 'Position', [0.7 0 0.1 0.05], 'Callback', @cancelCB); 

        % pre-populate table
        bidsFields = fieldnames(eventBIDS);
        data = cell(length(bidsFields),length(tbl.ColumnName));
        for i=1:length(bidsFields)
            % pre-populate description
            field = bidsFields{i};
            data{i, strcmp(tbl.ColumnName,'BIDS Field')} = field;
            
            if isfield(eventBIDS, field)    
                if isfield(eventBIDS.(field), 'EEGField')
                    data{i,strcmp(tbl.ColumnName, 'EEGLAB Field')} = eventBIDS.(field).EEGField;
                end
                if isfield(eventBIDS.(field), 'LongName')
                    data{i,strcmp(tbl.ColumnName, 'LongName')} = eventBIDS.(field).LongName;
                end
                if isfield(eventBIDS.(field), 'Description')
                    data{i,strcmp(tbl.ColumnName, 'Description')} = eventBIDS.(field).Description;
                end
                if isfield(eventBIDS.(field), 'Units')
                    data{i,strcmp(tbl.ColumnName, 'Unit Name')} = eventBIDS.(field).Units;
                end
                if isfield(eventBIDS.(field), 'TermURL')
                    data{i,strcmp(tbl.ColumnName, 'TermURL')} = eventBIDS.(field).TermURL;
                end
                if isfield(eventBIDS.(field), 'Levels') && ~isempty(eventBIDS.(field).Levels)
                    data{i,strcmp(tbl.ColumnName, 'Levels')} = strjoin(fieldnames(eventBIDS.(field).Levels),',');
                else
                    if strcmp(field, 'onset') || strcmp(field, "sample") || strcmp(field, "duration") || strcmp(field, "HED")
                        data{i,strcmp(tbl.ColumnName, 'Levels')} = 'n/a';
                    else
                        data{i,strcmp(tbl.ColumnName, 'Levels')} = 'Click to specify below';
                    end
                end
            end
            clear('field');
        end
        tbl.Data = data;
        waitfor(f);
    % Use default value - pop_eventinfo(EEG,'default') called
    elseif nargin < 3 && ischar(varargin{1}) && strcmp(varargin{1}, 'default')
        done();
    end
    
    
    %% --Helper functions---
    %---------------------
    function cancelCB(~, ~)
        clear('eventBIDS');
        close(f);
    end
    function okCB(~, ~)
        done();
        close(f);
    end
    % Callback for Add BIDS field button
    function addFieldCB(~, ~, bidsTable)
        [~, ~, ~, structout] = inputgui('geometry', {[1 1]}, 'geomvert', 1, 'uilist', {...
                {'Style', 'text', 'string', 'New field name (no space):'} ...
                {'Style', 'edit', 'Tag', 'new_name'} ...
                });
            if ~isempty(structout)
                if ~isempty(structout.new_name)
                    % add to gui table
                    currData = bidsTable.Data;
                    newData = [currData; {structout.new_name '' '' '' '' '' '' ''}];
                    bidsTable.Data = newData;
                    
                    % add to data structure
                    eventBIDS.(structout.new_name) = [];
                    eventBIDS.(structout.new_name).EEGField = '';
                    eventBIDS.(structout.new_name).LongName = '';
                    eventBIDS.(structout.new_name).Description = '';
                    eventBIDS.(structout.new_name).Levels = [];
                    eventBIDS.(structout.new_name).Units = '';
                    eventBIDS.(structout.new_name).TermURL = '';
                end
            end
    end
    % Callback for Remove BIDS field button
    function removeFieldCB(~, ~, bidsTable, bidsFields)
        fieldsToRemove = ['(none)' setdiff(bidsTable.Data(:, strcmp(bidsTable.ColumnName,'BIDS Field'))', bidsFields)]; % only allow removing added custom fields
        [~, ~, ~, structout] = inputgui('geometry', {[1 1]}, 'geomvert', 1, 'uilist', {...
                {'Style', 'text', 'string', 'Custom field to remove:'} ...
                {'Style', 'popupmenu', 'string', fieldsToRemove, 'Tag', 'removed_field'} ...
                });
            if ~isempty(structout)
                if ~isempty(structout.removed_field) && structout.removed_field > 1
                    selectedField = fieldsToRemove{structout.removed_field};
                    if ~strcmp(selectedField, '(none)')
                        currBidsFields = bidsTable.Data(:, strcmp(bidsTable.ColumnName, 'BIDS Field'));
                        rowIdx = strcmp(currBidsFields, selectedField);
                        bidsTable.Data(rowIdx,:) = [];
                        if isfield(eventBIDS, selectedField)
                            eventBIDS = rmfield(eventBIDS, selectedField);
                        end
                    end
                end
            end
    end
    function done()
        eInfoDesc = [];
        eInfo = {};
        % default fields automatically generated by EEGLAB in bids_export
        eInfoDesc.duration.LongName = 'Event duration';
        eInfoDesc.duration.Description = 'Duration of the event (measured from onset) in seconds';
        eInfoDesc.duration.Units = 'second';
        eInfoDesc.sample.LongName = 'Sample';
        eInfoDesc.sample.Description = 'Onset of the event according to the sampling scheme of the recorded modality (i.e., referring to the raw data file that the events.tsv file accompanies).';
        eInfoDesc.trial_type.LongName = 'Event categorization';
        eInfoDesc.trial_type.Description = 'Primary categorisation of each trial to identify them as instances of the experimental conditions.';
        eInfoDesc.response_time.LongName = 'Response time';
        eInfoDesc.response_time.Description = 'Response time measued in seconds.';
        eInfoDesc.response_time.Units = 'second';
        eInfoDesc.stim_file.LongName = 'Stimulus file location';
        eInfoDesc.stim_file.Description = 'Represents the location of the stimulus file (image, video, sound etc.) presented at the given onset time. They should be stored in the /stimuli folder (under the root folder of the dataset; with optional subfolders). The values under the stim_file column correspond to a path relative to "/stimuli".';
                
        % prepare return struct
        fields = fieldnames(eventBIDS);
        for k=1:length(fields)
            bidsField = fields{k};
            if ~isfield(eventBIDS.(bidsField), 'EEGField')
                eegField = [];
            else
                eegField = eventBIDS.(bidsField).EEGField;
            end
            if ~isempty(eegField)
                if ~strcmp(bidsField, 'onset') && ~strcmp(bidsField, 'sample') % calculated by default using latency
                    eInfo = [eInfo; {bidsField eegField}]; 
                end

                if ~isempty(eventBIDS.(bidsField).LongName)
                    eInfoDesc.(bidsField).LongName = eventBIDS.(bidsField).LongName;
                end
                if ~isempty(eventBIDS.(bidsField).Description)
                    eInfoDesc.(bidsField).Description = eventBIDS.(bidsField).Description;
                end
                if ~isempty(eventBIDS.(bidsField).Units)
                    eInfoDesc.(bidsField).Units = eventBIDS.(bidsField).Units;
                end
                if isfield(eventBIDS.(bidsField),'Levels') && ~isempty(eventBIDS.(bidsField).Levels) && ~strcmp(eventBIDS.(bidsField).Levels,'n/a')
                    eInfoDesc.(bidsField).Levels = eventBIDS.(bidsField).Levels;
                end
                if isfield(eventBIDS.(bidsField), 'TermURL') && ~isempty(eventBIDS.(bidsField).TermURL)
                    eInfoDesc.(bidsField).TermURL = eventBIDS.(bidsField).TermURL;
                end
            end
        end
        if numel(EEG) == 1
            command = '[EEG, eInfoDesc, eInfo] = pop_eventinfo(EEG);';
        else
            command = '[EEG, eInfoDesc, eInfo] = pop_eventinfo(EEG);';
        end
        
        % add info to EEG structs
        for e=1:numel(EEG)
            EEG(e).BIDS.eInfoDesc = eInfoDesc;
            EEG(e).BIDS.eInfo = eInfo;
            EEG(e).saved = 'no';
            EEG(e).history = [EEG(e).history command];
        end
        
        clear('eventBIDS');
    end

    % Callback for when a cell in event BIDS table is selected
    function cellSelectedCB(~, obj, eventFields) 
        if size(obj.Indices,1) == 1
            removeLevelUI();
            row = obj.Indices(1);
            col = obj.Indices(2);
            field = obj.Source.Data{row, strcmp(obj.Source.ColumnName, 'BIDS Field')};
            eegfield = obj.Source.Data{row, strcmp(obj.Source.ColumnName, 'EEGLAB Field')};
            columnName = obj.Source.ColumnName{col};
            if ~strcmp(columnName,'EEGLAB Field') && isempty(eegfield)
                    c6 = uicontrol(f, 'Style', 'text', 'String', sprintf('Please select matching EEGLAB field first'), 'Units', 'normalized', 'FontWeight', 'bold', 'FontAngle','italic','ForegroundColor', [0.9 0 0],'BackgroundColor', bg, 'Tag', 'noBidsMsg');
                    c6.Position = [0.01 0.44 0.5 0.05];
                    c6.HorizontalAlignment = 'Left';
            else
                if strcmp(columnName, 'EEGLAB Field')
                    if ~strcmp(field, 'onset') && ~strcmp(field, 'sample') % calculated automatically, can't be changed
                        c6 = uicontrol(f, 'Style', 'text', 'String', sprintf('Choose the matching EEGLAB field:'), 'Units', 'normalized', 'FontAngle','italic','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'selectBIDSMsg');
                        c6.Position = [0.01 0.44 1 0.05];
                        c6.HorizontalAlignment = 'left';
                        c = uicontrol(f,'Style','popupmenu', 'Units', 'normalized', 'Tag', 'selectBIDSDD');
                        c.Position = [0.01 0.34 0.3 0.1];
                        curEEGFields = obj.Source.Data(:,col);
                        unset_eventFields = setdiff(eventFields, curEEGFields(~cellfun(@isempty, curEEGFields)));
                        c.String = ['None' unset_eventFields'];
                        % display existing selection
                        if ~isempty(eegfield)
                            c.String = [eegfield c.String'];
                        end
                        c.Callback = {@eegFieldSelected, obj.Source, row, col};
                    end
                else % any other column selected
                    columnDefinition.LongName = 'Long, unabbreviated name of the field';
                    columnDefinition.Description = 'Description of the field';
                    columnDefinition.Levels = 'For categorical variables: possible values and their descriptions';
                    columnDefinition.Units = 'Measurement units - format [<prefix>]<name>';
                    columnDefinition.TermURL = 'URL pointing to a formal definition of this type of data in an ontology available on the web';

                    if strcmp(columnName, 'Levels')
                        createLevelUI('','',obj,field);
                    elseif strcmp(columnName, 'Description')
                        uicontrol(f, 'Style', 'text', 'String', sprintf('%s (%s):',columnName, columnDefinition.(columnName)), 'Units', 'normalized', 'Position',[0.01 0.44 0.98 0.05], 'HorizontalAlignment', 'left','FontAngle','italic','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'cellContentHeader');
                        uicontrol(f, 'Style', 'edit', 'String', obj.Source.Data{row,col}, 'Units', 'normalized', 'Max',2,'Min',0,'Position',[0.01 0.24 0.7 0.2], 'HorizontalAlignment', 'left', 'Callback', {@descriptionCB, obj,field}, 'Tag', 'cellContentMsg');
                    elseif ~strcmp(columnName, 'BIDS Field')
                        if strcmp(columnName, 'Unit Name') || strcmp(columnName, 'Unit Prefix')
                            columnName = 'Units';
                            content = [obj.Source.Data{row,strcmp(obj.Source.ColumnName, 'Unit Prefix')} obj.Source.Data{row,strcmp(obj.Source.ColumnName, 'Unit Name')}];
                        else
                            content = obj.Source.Data{row,col};
                        end
                        % display cell content in lower panel
                        uicontrol(f, 'Style', 'text', 'String', sprintf('%s (%s):',columnName, columnDefinition.(columnName)), 'Units', 'normalized', 'Position',[0.01 0.44 0.98 0.05], 'HorizontalAlignment', 'left','FontAngle','italic','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'cellContentHeader');
                        uicontrol(f, 'Style', 'text', 'String', sprintf('%s',content), 'Units', 'normalized', 'Position',[0.01 0.39 0.98 0.05], 'HorizontalAlignment', 'left','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'cellContentMsg');
                    end
                end
            end
        end
    end

    % Callback for when a field is selected from the EEGLAB fields dropdown
    function eegFieldSelected(src, ~, table, row, col) 
        val = src.Value;
        str = src.String;
        selected = str{val};
        if strcmp('None', selected)
            selected = '';
        end
        table.Data{row,col} = selected;
        field = table.Data{row, strcmp(table.ColumnName, 'BIDS Field')};
        eventBIDS.(field).EEGField = selected;
    end

    % Callback for when a cell in Description column is selected
    function descriptionCB(src,~,obj,field) 
        obj.Source.Data{obj.Indices(1),obj.Indices(2)} = src.String; % reset if found
        eventBIDS.(field).Description = src.String;
    end

    % Callback for when a cell in event BIDS table is edited
    function cellEditCB(~, obj)
        field = obj.Source.Data{obj.Indices(1), strcmp(obj.Source.ColumnName, 'BIDS Field')};
        column = obj.Source.ColumnName{obj.Indices(2)};
        eegField = obj.Source.Data{obj.Indices(1),strcmp(obj.Source.ColumnName, 'EEGLAB Field')};
        if ~strcmp(column, 'EEGLAB Field') && isempty(eegField)
            obj.Source.Data{obj.Indices(1),obj.Indices(2)} = obj.PreviousData;
        else
            if ~strcmp(column, 'Levels')
                if strcmp(column, 'EEGLAB Field')
                    if strcmp(field, 'onset') || strcmp(field, 'sample') % default EEGLAB calculation, can't be changed
                        obj.Source.Data{obj.Indices(1),obj.Indices(2)} = obj.PreviousData;
                    else
                        indicesOfOtherFields = setdiff(1:size(obj.Source.Data,1),obj.Indices(1));
                        otherFields = obj.Source.Data(indicesOfOtherFields,obj.Indices(2));
                        if ~isempty(obj.EditData) && any(strcmp(obj.EditData, otherFields)) % check for duplication of field name, ignoring empty name. BIDS <-> EEGLAB field mapping is one-to-one
                            obj.Source.Data{obj.Indices(1),obj.Indices(2)} = obj.PreviousData; % reset if found
                        else
                            eventBIDS.(field).EEGField = obj.EditData;
                        end
                    end
                elseif strcmp(column, 'Unit Name') || strcmp(column, 'Unit Prefix')
                    unit = [obj.Source.Data{obj.Indices(1),strcmp(obj.Source.ColumnName, 'Unit Prefix')} obj.Source.Data{obj.Indices(1),strcmp(obj.Source.ColumnName, 'Unit Name')}];
                    eventBIDS.(field).Units = unit;
                else
                    eventBIDS.(field).(column) = obj.EditData;
                end
            end
        end
    end
    
    % Create levels editing panel
    function createLevelUI(~,~,table,field)
        removeLevelUI();
        matchedRow = strcmp(table.Source.Data(:, strcmp(table.Source.ColumnName, 'BIDS Field')), field);
        levelCellText = table.Source.Data{matchedRow, strcmp(table.Source.ColumnName, 'Levels')}; % text @ (field, Levels) cell. if 'n/a' then no action, 'Click to..' then conditional action, '<value>,...' then get levels
        if strcmp(field, 'HED')
            uicontrol(f, 'Style', 'text', 'String', 'Levels editing not applied for HED. Use ''pop_tageeg(EEG)'' of HEDTools plug-in to edit event HED tags', 'Units', 'normalized', 'Position', [0.01 0.45 1 0.05],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
        elseif strcmp(field, 'onset') || strcmp(field, 'sample') || strcmp(field, 'duration')
            uicontrol(f, 'Style', 'text', 'String', 'Levels editing not applied for field with continuous values.', 'Units', 'normalized', 'Position', [0.01 0.45 1 0.05],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
        else
            % retrieve all unique values from EEG.event.(field). 
            eegField = eventBIDS.(field).EEGField;
            levels = getAllUniqueFieldValues(EEG, eegField)';
            if strcmp(levelCellText,'Click to specify below') && length(levels) > levelThreshold 
                msg = sprintf('\tThere are more than %d unique levels for field %s.\nAre you sure you want to specify levels for it?', levelThreshold, eegField);
                c4 = uicontrol(f, 'Style', 'text', 'String', msg, 'Units', 'normalized', 'FontWeight', 'bold', 'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'confirmMsg');
                c4.Position = [0 0.38 1 0.1];
                c5 = uicontrol(f, 'Style', 'pushbutton', 'String', 'Yes', 'Units', 'normalized','Tag', 'confirmBtn', 'Callback', {@ignoreThresholdCB,table,field});
                c5.Position = [0.5-c5.Extent(3)/2 0.33 0.1 0.05];
            else
                % build table data
                t = cell(length(levels),2);
                for lvl=1:length(levels)
                    formattedLevel = checkFormat(levels{lvl}); % put level in the right format for indexing. Number is prepended by 'x'
                    t{lvl,1} = formattedLevel;
                    if ~isempty(eventBIDS.(field).Levels) && isfield(eventBIDS.(field).Levels, formattedLevel)
                        t{lvl,2} = eventBIDS.(field).Levels.(formattedLevel);
                    end
                end
                % create UI
                uicontrol(f, 'Style', 'text', 'String', ['Describing levels of ' field], 'Units', 'normalized', 'HorizontalAlignment', 'left', 'Position', [0.31 0.45 0.7 0.05],'FontWeight', 'bold','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
                msg = 'BIDS allow you to describe the level for each of your categorical field. Describing levels help other researchers understand your experiment better';
                uicontrol(f, 'Style', 'text', 'String', msg, 'Units', 'normalized', 'HorizontalAlignment', 'Left','Position', [0.01 0 0.3 0.4],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelMsg');
                h = uitable(f, 'Data', t(:,2), 'ColumnName', {'Description'}, 'RowName', t(:,1), 'Units', 'normalized', 'Position', [0.31 0.07 0.68 0.38], 'FontSize', fontSize, 'Tag', 'levelEditTbl', 'CellEditCallback',{@levelEditCB,field},'ColumnEditable',true); 
                h.ColumnWidth = {appWidth*0.68*0.8};
            end
        end
    end
    
    % Callback for when user chose to ignore threshold of maximum number of
    % unique values when specifying categorical levels
    function ignoreThresholdCB(~,~,table, bidsField)
        matchedRow = strcmp(table.Source.Data(:, strcmp(table.Source.ColumnName, 'BIDS Field')), field);
        table.Source.Data{matchedRow, strcmp(table.Source.ColumnName, 'Levels')} = 'Click to specify below (ignore max number of levels threshold)';
        createLevelUI('','',table,bidsField);
    end
    
    % Callback for when a cell in the level specification table is edited
    function levelEditCB(~, obj, field)
        level = checkFormat(obj.Source.RowName{obj.Indices(1)});
        description = obj.EditData;
        % update eventBIDS structure
        eventBIDS.(field).Levels.(level) = description;
        specified_levels = fieldnames(eventBIDS.(field).Levels);
        % Update main table
        mainTable = findobj('Tag','eventBidsTable');
        mainTable.Data{strcmp(mainTable.Data(:, strcmp(mainTable.ColumnName, 'BIDS Field')), field), strcmp('Levels',mainTable.ColumnName)} = strjoin(specified_levels, ',');
    end
    
    function formatted = checkFormat(str)
        if ~isempty(str2num(str))
            formatted = ['x' str];
        else
            formatted = strrep(str,' ','_'); %replace space with _
        end
    end
    
    % Remove any existing old ui items of level specification panel
    function removeLevelUI()
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
        h = findobj('Tag', 'noLevelBtn');
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

    % get unique event value for all EEG.event.eegField
    function uniqueValues = getAllUniqueFieldValues(EEG, eegField)
        if isnumeric(EEG(1).event(1).(eegField))
        uniqueValues = [];
        elseif ischar(EEG(1).event(1).(eegField))
            uniqueValues = {};
        end
        for e=1:numel(EEG)
            if ischar(EEG(e).event(1).(eegField))
                uniqueValues = [uniqueValues{:} {EEG(e).event.(eegField)}];
            else
                uniqueValues = [uniqueValues EEG(e).event.(eegField)];
            end
            uniqueValues = unique(uniqueValues);
        end 
        if isnumeric(uniqueValues(1))
            uniqueValues = arrayfun(@num2str,uniqueValues,'UniformOutput',false);
        end
    end

    % generate main event data structure that holds information
    % to be updated through GUI events
    % event structure:
    % event.(bidsField).EEGField
    %                  .LongName
    %                  .Description
    %                  .Units
    %                  .Levels
    %                  .TermURL
    function event = newEventBIDS(EEG, eventFields, bidsFields)
        event = [];
        bidsEEG = [];
        if isfield(EEG,'BIDS') % return true if any of EEG structure has BIDS
            bidsIdx = find(~cellfun(@isempty,{EEG.BIDS}));
            if ~isempty(bidsIdx)
                if numel(EEG) ~= numel(bidsIdx)
                    fprintf(['EEG.BIDS is found in ' num2str(numel(bidsIdx)) ' out of ' num2str(numel(EEG)) ' EEG structure(s). ']);
                end
                if bidsIdx(1) == 1
                    fprintf('Using BIDS info of first dataset...\n');
                else % user-friendly message
                    fprintf(['Using BIDS info of EEG(' num2str(bidsIdx(1)) ')...\n']);
                end
                bidsEEG = EEG(bidsIdx(1));
            end
        end
        
        % if resume editing
        if ~isempty(bidsEEG) && isfield(bidsEEG.BIDS,'eInfoDesc') && isfield(bidsEEG.BIDS,'eInfo')
            prev_bids_fields = fieldnames(bidsEEG.BIDS.eInfoDesc);
            for idx=1:numel(prev_bids_fields)
                bids_field = prev_bids_fields{idx}; % to be keys of event struct
                
                % add matching EEGLAB field
                % eInfo: bidsField | eeglabField
                hasMatchingEEGField = strcmp(bidsEEG.BIDS.eInfo(:,1),bids_field);
                if any(hasMatchingEEGField)
                    eeg_field = bidsEEG.BIDS.eInfo{hasMatchingEEGField,2};
                else
                    eeg_field = '';
                end             
                if strcmp(bids_field, 'onset')
                    event.(bids_field).EEGField = 'From sample';
                elseif strcmp(bids_field, 'sample')
                    event.(bids_field).EEGField = 'latency';
                else
                    event.(bids_field).EEGField = eeg_field;
                end
                
                % copy BIDS info
                if isfield(bidsEEG.BIDS.eInfoDesc,bids_field) && isfield(bidsEEG.BIDS.eInfoDesc.(bids_field), 'LongName')
                    event.(bids_field).LongName = bidsEEG.BIDS.eInfoDesc.(bids_field).LongName;
                else
                    event.(bids_field).LongName = '';
                end
                if isfield(bidsEEG.BIDS.eInfoDesc,bids_field) && isfield(bidsEEG.BIDS.eInfoDesc.(bids_field), 'Description')
                    event.(bids_field).Description = bidsEEG.BIDS.eInfoDesc.(bids_field).Description;
                else
                    event.(bids_field).Description = '';
                end
                if isfield(bidsEEG.BIDS.eInfoDesc,bids_field) && isfield(bidsEEG.BIDS.eInfoDesc.(bids_field), 'Units')
                    event.(bids_field).Units = bidsEEG.BIDS.eInfoDesc.(bids_field).Units;
                else
                    event.(bids_field).Units = '';
                end
                if isfield(bidsEEG.BIDS.eInfoDesc,bids_field) && isfield(bidsEEG.BIDS.eInfoDesc.(bids_field), 'Levels')
                    event.(bids_field).Levels = bidsEEG.BIDS.eInfoDesc.(bids_field).Levels;
                else
                    event.(bids_field).Levels = [];
                end
                if isfield(bidsEEG.BIDS.eInfoDesc,bids_field) && isfield(bidsEEG.BIDS.eInfoDesc.(bids_field), 'TermURL')
                    event.(bids_field).TermURL = bidsEEG.BIDS.eInfoDesc.(bids_field).TermURL;
                else
                    event.(bids_field).TermURL = '';
                end
            end
            fields = setdiff(bidsFields, fieldnames(bidsEEG.BIDS.eInfoDesc)); % add any unset default bids fields to the structure (in case prev session forgot to add these)
            for idx=1:length(fields)
                event.(fields{idx}).EEGField = '';
                event.(fields{idx}).LongName = '';
                event.(fields{idx}).Description = '';
                event.(fields{idx}).Units = '';
                event.(fields{idx}).Levels = [];
                event.(fields{idx}).TermURL = '';
            end
        else % start fresh
            fields = bidsFields; 
            for idx=1:length(fields)
                if strcmp(fields{idx}, 'onset')
                    event.onset.EEGField = 'From sample';
                    event.onset.LongName = 'Event onset';
                    event.onset.Description = 'Onset (in seconds) of the event measured from the beginning of the acquisition of the first volume in the corresponding task imaging data file';
                    event.onset.Units = 'second';
                    event.onset.Levels = [];
                    event.onset.TermURL = '';
                elseif strcmp(fields{idx}, 'sample')
                    event.sample.EEGField = 'latency';
                    event.sample.LongName = 'Sample';
                    event.sample.Description = 'Onset of the event according to the sampling scheme of the recorded modality';
                    event.sample.Units = '';
                    event.sample.Levels = [];
                    event.sample.TermURL = '';
                elseif strcmp(fields{idx}, 'value')
                    event.value.EEGField = 'type';
                    event.value.LongName = 'Event marker';
                    event.value.Description = 'Marker value associated with the event';
                    event.value.Units = '';
                    event.value.Levels = [];
                    event.value.TermURL = '';
                elseif strcmp(fields{idx}, 'HED') && any(strcmp(eventFields, 'usertags'))
                    if isfield(EEG(1).event, 'usertags')
                        event.HED.EEGField = 'usertags';
                    else
                        event.HED.EEGField = '';
                    end
                    event.HED.LongName = 'Hierarchical Event Descriptor';
                    event.HED.Description = 'Tags describing the nature of the event';      
                    event.HED.Levels = [];
                    event.HED.Units = '';
                    event.HED.TermURL = '';
                elseif strcmp(fields{idx}, 'duration')
                    if isfield(EEG(1).event, 'duration')
                        event.HED.EEGField = 'duration';
                    else
                        event.HED.EEGField = '';
                    end
                    event.duration.LongName = 'Event duration';
                    event.duration.Description = 'Duration of the event (measured from onset) in seconds. Must always be either zero or positive. A "duration" value of zero implies that the delta function or event is so short as to be effectively modeled as an impulse.';
                    event.duration.Units = 'second';
                    event.duration.Levels = [];
                    event.duration.TermURL = '';
                else
                    event.(fields{idx}).EEGField = '';
                    event.(fields{idx}).LongName = '';
                    event.(fields{idx}).Description = '';
                    event.(fields{idx}).Units = '';
                    event.(fields{idx}).Levels = [];
                    event.(fields{idx}).TermURL = '';
                end
            end
        end
    end
end
