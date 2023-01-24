function [ ] = fn_update_session_info_table(existing_session_info_table_FQN, new_data_struct_array, sort_by_field_name)
%FN_UPDATE_SESSION_INFO_TABLE Summary of this function goes here
%   Detailed explanation goes here


if ~isempty(dir(existing_session_info_table_FQN))
	% load and concatenate the structure arrays
	existing_data_struct_array = load(existing_session_info_table_FQN);
	existing_data_struct_array = existing_data_struct_array.output_data_struct_array;
	data_struct_array = [existing_data_struct_array, new_data_struct_array];
	
else
	% existing_session_info_table_FQN does not yet exist, simply sort and
	% save the data
	data_struct_array = new_data_struct_array;
end

% sort the data, and return only unique instances
sort_key_list = {data_struct_array(:).(sort_by_field_name)};
[unique_key_list, unique_record_idx] = unique(sort_key_list);
output_data_struct_array = data_struct_array(unique_record_idx);

% save as mat file:
disp(['Saving session info data as: ' existing_session_info_table_FQN]);

save(existing_session_info_table_FQN, 'output_data_struct_array');

% now save as xlsx and csv
output_data_table = struct2table(output_data_struct_array);

[out_dir, out_name, out_ext] = fileparts(existing_session_info_table_FQN);


% save as excel file
writetable(output_data_table, fullfile(out_dir, [out_name, '.xlsx']));
% save as TXT
writetable(output_data_table, fullfile(out_dir, [out_name, '.txt']), 'Delimiter', ';');
% save as CSV
writetable(output_data_table, fullfile(out_dir, [out_name, '.csv']), 'Delimiter', ',');

return
end

