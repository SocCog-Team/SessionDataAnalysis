function [ aggregate_struct ] = fn_aggregate_event_data_by_switches( per_trial_struct )
%FN_AGGREGATE_EVENT_DATA_BY_SWITCHES Summary of this function goes here
%   Detailed explanation goes here

current_fieldnames = fieldnames(per_trial_struct);

for i_switch = 1 : length(current_fieldnames)
	current_switch_type = current_fieldnames{i_switch};
	if isempty(per_trial_struct.(current_switch_type))
		aggregate_struct.(current_switch_type) = [];
	else
		aggregate_struct.(current_switch_type).raw = fn_aggregate_event_data(per_trial_struct.(current_switch_type).raw);
		aggregate_struct.(current_switch_type).nan_padded = fn_aggregate_event_data(per_trial_struct.(current_switch_type).nan_padded);
		aggregate_struct.(current_switch_type).raw_pattern = per_trial_struct.(current_switch_type).raw_pattern;
		aggregate_struct.(current_switch_type).nan_padded_pattern = per_trial_struct.(current_switch_type).nan_padded_pattern;
	end
end

end

