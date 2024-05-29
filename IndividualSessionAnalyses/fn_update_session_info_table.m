function [ output_data_table ] = fn_update_session_info_table(existing_session_info_table_FQN, new_data_struct_array, sort_by_field_name)
%FN_UPDATE_SESSION_INFO_TABLE Summary of this function goes here
%   Detailed explanation goes here


if ~isempty(dir(existing_session_info_table_FQN))
	% load and concatenate the structure arrays
	existing_data_struct_array = load(existing_session_info_table_FQN);
	existing_data_struct_array = existing_data_struct_array.output_data_struct_array;	
	% concatenation assures the new modified values are after earlier
	% instances of the same records, which we use later to replace the old
	% with the new
	data_struct_array = [existing_data_struct_array, new_data_struct_array];
else
	% existing_session_info_table_FQN does not yet exist, simply sort and
	% save the data
	data_struct_array = new_data_struct_array;
end

% sort the data, and return only unique instances
sort_key_list = {data_struct_array(:).(sort_by_field_name)};
% using 'last' assures that the newer record versions of existing records
% are kept while the previous once are overwritten...
[unique_key_list, unique_record_idx] = unique(sort_key_list, 'last');
output_data_struct_array = data_struct_array(unique_record_idx);

% save struct array as mat file:
disp(['Saving session info data as: ' existing_session_info_table_FQN]);
save(existing_session_info_table_FQN, 'output_data_struct_array');

% now save as xlsx and csv
output_data_table = struct2table(output_data_struct_array);
[out_dir, out_name, out_ext] = fileparts(existing_session_info_table_FQN);

% save as excel file
disp(['Saving session info data as .xslx: ' fullfile(out_dir, [out_name, '.xlsx'])]);
try
	writetable(output_data_table, fullfile(out_dir, [out_name, '.xlsx']));
catch
	% likely open in blocking mode, save as emergency file with date time
	cur_datetime_string = char(datetime("now", 'Format', 'yyyyMMdd-HHmmss'));
	disp([mfilename, ': Excel table version of session info data, is not writable; saving instead as: ',  [out_name, '.', cur_datetime_string, '.xlsx']])
	writetable(output_data_table, fullfile(out_dir, [out_name, '.', cur_datetime_string, '.xlsx']));
end
	
	% save as TXT
disp(['Saving session info data as .txt: ' fullfile(out_dir, [out_name, '.txt'])]);
writetable(output_data_table, fullfile(out_dir, [out_name, '.txt']), 'Delimiter', ';');
% save as CSV
disp(['Saving session info data as .csv: ' fullfile(out_dir, [out_name, '.csv'])]);
writetable(output_data_table, fullfile(out_dir, [out_name, '.csv']), 'Delimiter', ',');

% save the matlab table as .table.mat file
disp(['Saving session info data as matlab table: ' fullfile(out_dir, [out_name, '.table.mat'])]);
save(fullfile(out_dir, [out_name, '.table.mat']), 'output_data_table');
return
end

