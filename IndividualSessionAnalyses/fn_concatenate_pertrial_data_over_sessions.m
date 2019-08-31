function [ concatenated_data_struct ] = fn_concatenate_pertrial_data_over_sessions( existing_struct, new_data_struct, current_trial_idx )
%FN_CONCATENATE_PERTRIAL_DATA_OVER_SESSIONS Summary of this function goes
%here_
%   Detailed explanation goes here
concatenated_data_struct = [];
trial_offset = 0;
fieldname_list = fieldnames(new_data_struct);

if isempty(existing_struct)
	concatenated_data_struct = new_data_struct;
	concatenated_data_struct.selected_trial_idx = current_trial_idx;
	concatenated_data_struct.sessionID = ones(size(new_data_struct.(fieldname_list{1})));
	return
end


concatenated_data_struct = existing_struct;
for i_field = 1 : length(fieldname_list)
	current_field = fieldname_list{i_field};
	concatenated_data_struct.(current_field) = [concatenated_data_struct.(current_field); new_data_struct.(current_field)];
end

trial_offset = size(existing_struct.(fieldname_list{1}), 1);
last_sessionID = existing_struct.sessionID(end);
% adjust the trial idx
concatenated_data_struct.selected_trial_idx = [concatenated_data_struct.selected_trial_idx; (current_trial_idx + trial_offset)];
concatenated_data_struct.sessionID = [concatenated_data_struct.sessionID; (ones(size(new_data_struct.(fieldname_list{1}))) * (last_sessionID + 1))];

return
end

