function [ coordination_metrics_table, tmp_coordination_metrics_table ] = fn_population_per_session_aggregates_per_trialsubset_wrapper( OutputPath, PopulationAggregateName, current_file_group_id_string, info, isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, TrialsInCurrentSetIdx, use_all_trials, prefix_string, suffix_string )
%FN_POPULATION_PER_SESSION_AGGREGATES_PER_TRIALSUBSET_WRAPPER Summary of this function goes here
%   Detailed explanation goes here

% save the per session population results
%population_per_session_aggregates_FQN = fullfile(OutputPath, 'CoordinationCheck', ['ALL_SESSSION_METRICS.mat']);
% since we learned how to update this file, keep it
population_per_session_aggregates_FQN = fullfile(OutputPath, PopulationAggregateName);


% move this into its own function?

coordination_metrics_struct = struct();
coordination_metrics_row = [];
coordination_metrics_row_header = {};



coordination_metrics_table = [];
if exist(population_per_session_aggregates_FQN, 'file')
    load(population_per_session_aggregates_FQN); % contains coordination_metrics_table
else
    coordination_metrics_table = [];
end
tmp_coordination_metrics_table = struct();

% now only (re-)calculate the coordination_metrics if the
% current coordination_metrics_cfg does not match the existing
% one, as the caculation is costly.

% find the index of the current key
recalc_coordination_metrics = 1;
tmp_key_idx = [];
if isfield(coordination_metrics_table, 'key') && ~isempty(coordination_metrics_table.key)
    %stored_coordination_metrics_cfg = [];
    tmp_key_idx = find(strcmp(coordination_metrics_table.key, current_file_group_id_string));
    if ~isempty(tmp_key_idx)
        stored_coordination_metrics_cfg = coordination_metrics_table.cfg_struct(tmp_key_idx);
        cfg_is_equal = isequaln(stored_coordination_metrics_cfg, coordination_metrics_cfg);
        recalc_coordination_metrics = ~(cfg_is_equal);
        if (cfg_is_equal)
            disp(['Keeping already computed coordination_metrics for ', coordination_metrics_table.key{tmp_key_idx}]);
        end
    end
end
%recalc_coordination_metrics = 1;
if isempty(coordination_metrics_table) || (recalc_coordination_metrics)
    if ~isempty(tmp_key_idx)
        disp(['Recalculating coordination_metrics for ', coordination_metrics_table.key{tmp_key_idx}]);
    else
        disp(['Calculating coordination_metrics for ', current_file_group_id_string]);
    end
    %[coordination_metrics_struct, coordination_metrics_row, coordination_metrics_row_header] = fn_compute_coordination_metrics_session(isOwnChoiceArray, sideChoiceObjectiveArray, PerTrialStruct, coordination_metrics_cfg);
    
    [coordination_metrics_struct, coordination_metrics_row, coordination_metrics_row_header] = fn_compute_coordination_metrics_session_by_indexedtrials(...
        isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, TrialsInCurrentSetIdx, use_all_trials, prefix_string, suffix_string);
    
    if ~isempty(coordination_metrics_row_header)
        tmp_coordination_metrics_table.key = current_file_group_id_string;
        tmp_coordination_metrics_table.info_struct = info;
        tmp_coordination_metrics_table.row = coordination_metrics_row;
        tmp_coordination_metrics_table.header = coordination_metrics_row_header;
        tmp_coordination_metrics_table.cfg_struct = coordination_metrics_cfg;
        tmp_coordination_metrics_table.coordination_metrics_struct = coordination_metrics_struct;
    end
    
    
    % now store the tmp_coordination_metrics_table into the coordination_metrics_table
    if isempty(coordination_metrics_table)
        coordination_metrics_table.key = {current_file_group_id_string};
        coordination_metrics_table.info_struct = info;
        coordination_metrics_table.data = tmp_coordination_metrics_table.row;
        coordination_metrics_table.header = tmp_coordination_metrics_table.header;
        coordination_metrics_table.cn = local_get_column_name_indices(tmp_coordination_metrics_table.header);
        coordination_metrics_table.cfg_struct = tmp_coordination_metrics_table.cfg_struct;
        coordination_metrics_table.coordination_metrics_struct = tmp_coordination_metrics_table.coordination_metrics_struct;
    else
        % only add data if we actually calculated data
        if ~isempty(coordination_metrics_row) && ~isempty(coordination_metrics_row_header)
            coordination_metrics_table = fn_add_entry_to_table_by_key(coordination_metrics_table, tmp_coordination_metrics_table);
        end
    end
    % now save out the modified data
    save(population_per_session_aggregates_FQN, 'coordination_metrics_table');
else
    tmp_coordination_metrics_table.key = coordination_metrics_table.key{tmp_key_idx};
    tmp_coordination_metrics_table.info_struct = coordination_metrics_table.info_struct(tmp_key_idx);
    tmp_coordination_metrics_table.row = coordination_metrics_table.data(tmp_key_idx, :);
    tmp_coordination_metrics_table.header = coordination_metrics_table.header;
    tmp_coordination_metrics_table.cfg_struct = coordination_metrics_table.cfg_struct(tmp_key_idx);
    tmp_coordination_metrics_table.coordination_metrics_struct = coordination_metrics_table.coordination_metrics_struct(tmp_key_idx);
    tmp_coordination_metrics_table.cn = coordination_metrics_table.cn;
end


return
end


function [ coordination_metrics_table ] = fn_add_entry_to_table_by_key( coordination_metrics_table, tmp_coordination_metrics_table )

% get the column name structure
if ~isfield(coordination_metrics_table, 'cn') || (isfield(coordination_metrics_table, 'cn') && isempty(coordination_metrics_table.cn))
    coordination_metrics_table.cn = local_get_column_name_indices(coordination_metrics_table.header);
end

% only add data if the header match
if ~isequal(coordination_metrics_table.header, tmp_coordination_metrics_table.header)
    error('The existing data table and the to be added row data, have different columns/column order, which is not handled yet');
end

% find whether tmp_coordination_metrics_table.key is already in
% coordination_metrics_table.key
tmp_key_idx = find(strcmp(tmp_coordination_metrics_table.key, coordination_metrics_table.key));

if isempty(tmp_key_idx)
    % new data, just add at the end
    coordination_metrics_table.info_struct(end+1) = tmp_coordination_metrics_table.info_struct;
    coordination_metrics_table.key(end+1) = {tmp_coordination_metrics_table.key};
    coordination_metrics_table.data(end+1, :) = tmp_coordination_metrics_table.row;
    coordination_metrics_table.cfg_struct(end+1) = tmp_coordination_metrics_table.cfg_struct;
    coordination_metrics_table.coordination_metrics_struct(end+1) = tmp_coordination_metrics_table.coordination_metrics_struct;
else
    % we have seen this before so update
    coordination_metrics_table.info_struct(tmp_key_idx) = tmp_coordination_metrics_table.info_struct;
    coordination_metrics_table.key(tmp_key_idx) = {tmp_coordination_metrics_table.key};
    coordination_metrics_table.data(tmp_key_idx, :) = tmp_coordination_metrics_table.row;
    coordination_metrics_table.cfg_struct(tmp_key_idx) = tmp_coordination_metrics_table.cfg_struct;
    coordination_metrics_table.coordination_metrics_struct(tmp_key_idx) = tmp_coordination_metrics_table.coordination_metrics_struct;
end

return
end


function [columnnames_struct, n_fields] = local_get_column_name_indices(name_list, start_val)
% return a structure with each field for each member if the name_list cell
% array, giving the position in the name_list, then the columnnames_struct
% can serve as to address the columns, so the functions assigning values
% to the columns do not have to care too much about the positions, and it
% becomes easy to add fields.
% name_list: cell array of string names for the fields to be added
% start_val: numerical value to start the field values with (if empty start
%            with 1 so the results are valid indices into name_list)

if nargin < 2
    start_val = 1;  % value of the first field
end
n_fields = length(name_list);
for i_col = 1 : length(name_list)
    cur_name = name_list{i_col};
    % skip empty names, this allows non consequtive numberings
    if ~isempty(cur_name)
        columnnames_struct.(cur_name) = i_col + (start_val - 1);
    end
end
return
end
