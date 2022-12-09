function [ ] = fn_simplify_and_store_data_files( input_FQN, base_out_dir, group_name, group_ID, i_session_in_group )
%FN_SIMPLIFY_AND_STORE_DATA_FILES Summary of this function goes here
%   Detailed explanation goes here
% fnAggregateAndPlotCoordinationMetricsByGroup([], [], [], 'BoS_manuscript')

cur_data = load(input_FQN);

% now process the data
data = struct();
good_trial_idx = cur_data.TrialsInCurrentSetIdx; % the dyadic complete trials
cur_FullPerTrialStruct = cur_data.FullPerTrialStruct;
confederate_list = {'SM', 'JK', 'TN', 'RN', 'IK', 'FS', 'DL', 'KN', 'ST', 'AW'};


data.info = fn_split_and_sanitize_session_id_string(cur_data.info.session_id, confederate_list);
%data.info.sessionID = cur_data.info.session_id(1:end-9); % contains
%initials which is problematic
data.info.group_ID = group_ID;
data.info.group_name = group_name;
% add the IDs of the agents?



% which fields to take
selected_input_fieldname_list = {...
	'isTrialInvisible_AB', ...
	...
	'A_InitialTargetReleaseRT', 'B_InitialTargetReleaseRT', ...
	'AB_InitialTargetReleaseRT_diff', ...
	'A_TargetAcquisitionRT', 'B_TargetAcquisitionRT', ...
	'AB_TargetAcquisitionRT_diff', ...
	'A_IniTargRel_05MT_RT', 'B_IniTargRel_05MT_RT', ...
	'AB_IniTargRel_05MT_RT_diff', ...
	...
	'RewardByTrial_A', 'RewardByTrial_B', ...
	...
	'PreferableTargetSelected_A', 'PreferableTargetSelected_B', ...
	'NonPreferableTargetSelected_A', 'NonPreferableTargetSelected_B', ...
	'LeftTargetSelected_A', 'LeftTargetSelected_B', ...
	'RightTargetSelected_A', 'RightTargetSelected_B', ...
	};


% how to call these fields in the output field, keep input name if empty
selected_output_fieldname_list = cell([size(selected_input_fieldname_list)]);
selected_output_fieldname_list = {...
	'AB_trial_opaque_others_hands_invisible', ...
	...
	'A_initial_fixation_target_release_time_ms', 'B_initial_fixation_target_release_time_ms', ...
	'AB_initial_fixation_target_release_time_difference_ms', ...
	'A_target_acquisition_time_ms', 'B_target_acquisition_time_ms', ...
	'AB_target_acquisition_time_difference_ms', ...
	'A_action_time_ms', 'B_action_time_ms', ...
	'AB_action_time_difference_ms', ...
	...
	'A_reward', 'B_reward', ...
	...
	'A_choosing_own', 'B_choosing_own', ...
	'A_choosing_other', 'B_choosing_other', ...
	'A_choosing_left', 'B_choosing_left', ...
	'A_choosing_right', 'B_choosing_right', ...
	};


% loop through the fields
cur_FullPerTrialStruct_fieldname_list = fieldnames(cur_FullPerTrialStruct);
for i_field = 1 : length(cur_FullPerTrialStruct_fieldname_list)
	cur_fieldname = cur_FullPerTrialStruct_fieldname_list{i_field};
	
	% only collect fields that are requested
	if ismember(cur_fieldname, selected_input_fieldname_list)
		cur_selected_fieldname_idx = find(ismember(selected_input_fieldname_list, cur_fieldname));
		if ~isempty(selected_output_fieldname_list{cur_selected_fieldname_idx})
			cur_field_output_name = selected_output_fieldname_list{cur_selected_fieldname_idx};
		else
			cur_field_output_name = selected_input_fieldname_list{cur_selected_fieldname_idx};
		end
		
		data.(cur_field_output_name) = cur_FullPerTrialStruct.(cur_fieldname)(good_trial_idx);
		
	end	
end	


%sanitize group_name, remove initials
sanitized_group_name = fn_sanitize_group_name(group_name, confederate_list);

% create the ouput directory
out_dir = fullfile(base_out_dir, sanitized_group_name);
if ~isfolder(out_dir)
	mkdir(out_dir);
end

% for humans just report the pair number
if ~isempty(str2num(group_ID)) && ~isempty(strfind(sanitized_group_name, 'uman'))
	pair_id_string = ['pairID_', group_ID];
else	
	pair_id_string = ['subjectID_', data.info.A_ID, '_', data.info.B_ID];
end



out_data_FQN = fullfile(out_dir, ['BoS_dyadic_trials', '.', sanitized_group_name, '.', pair_id_string, '.', 'Seq_', num2str(i_session_in_group, '%02d'), '.mat']);

disp(['Saving data to: ', out_data_FQN]);
save(out_data_FQN, 'data');



return
end



function [ info_struct ]  = fn_split_and_sanitize_session_id_string( session_id_string, confederate_list )

[info_struct.date, remaining] = strtok(session_id_string, '.');

[A_id_string, remaining] = strtok(remaining(2:end), '.');
[B_id_string, remaining] = strtok(remaining(2:end), '.');
[info_struct.setup_id, remaining] = strtok(remaining(2:end), '.');

[info_struct.A_ID, info_struct.A_species] = fn_sanitize_subject_id(A_id_string(3:end), confederate_list);
[info_struct.B_ID, info_struct.B_species] = fn_sanitize_subject_id(B_id_string(3:end), confederate_list);



return
end

function [ sanitized_ID_string, species_string ] = fn_sanitize_subject_id( ID_string, confederate_list )

sanitized_string = [];
species_string = [];
%confederate_list = {'SM', 'JK', 'TN', 'RN', 'IK', 'FS', 'DL', 'KN', 'ST'};


% numeric values are OK
if ~isempty(str2num(ID_string))
	sanitized_ID_string = ID_string;
	species_string = 'human';
	return
end	
% later human ID strings are built like '181030ID0061S1'
if (length(ID_string) > 8) && ~isempty(str2num(ID_string(1:6))) && (strcmp(ID_string(7:8), 'ID') || strcmp(ID_string(9:10), 'ID')) && strcmp(ID_string(end-1:end-1), 'S')
	sanitized_ID_string = ID_string;
	species_string = 'human';
	return
end	

switch ID_string
	case {'Curius', 'Flaffus', 'Tesla', 'Magnus', 'Linus', 'Elmo'}
		% for NHP just return the initial, needs t be extended if these
		% start to clash
		sanitized_ID_string = ID_string(1);
		species_string = 'macaque';
	case confederate_list
		cur_conf_num = find(ismember(confederate_list, ID_string));
		sanitized_ID_string = ['Conf', num2str(cur_conf_num, '%02d')];
		% pick the position in the list and create a ConfNN label
		species_string = 'human';
	otherwise
		error(['Unhandled ID_string encountered: ', ID_string]);
end

return
end

function [ sanitized_group_name ] = fn_sanitize_group_name( group_name, confederate_list )

sanitized_group_name = group_name;
for i_confID = 1 : length(confederate_list)
	sanitized_group_name = regexprep(sanitized_group_name, confederate_list{i_confID}, '');
end	


return
end

