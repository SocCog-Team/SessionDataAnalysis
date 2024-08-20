function [ ] = fn_characterize_channels( input_table, base_dir )
%fn_characterize_channels try to assess quakity of channels...
% For each animal and array state (to allow for array changes) show:
%	The distribution which channels were clasified as bad channel how often
%	neuronal data per channel? look at significance count for channels
%		AB side compinations @ own OR other's action time

input_table_fqn = [];
ci_alpha = 0.05;


% no GUI means no figure windows possible, so try to work around that
if ~exist('InvisibleFigures', 'var') || isempty(InvisibleFigures)
	InvisibleFigures = 0;
end

if (fnIsMatlabRunningInTextMode())
	InvisibleFigures = 1;
end
if (InvisibleFigures)
	figure_visibility_string = 'off';
	disp('Using invisible figures, for speed.');
else
	figure_visibility_string = 'on';
	disp('Using visible figures, for debugging/formatting.');
end
plotting_options.figure_visibility_string = figure_visibility_string;

output_format_string = '.pdf';
plotting_options.panel_width_cm = 15*3;
plotting_options.panel_height_cm = 12;
plotting_options.margin_cm = 1;
ci_alpha = 0.05;
transparency = 0.1;

n_cols = 1;
n_rows = 1;

plot_width_cm = (plotting_options.panel_width_cm * n_cols);
plot_height_cm = (plotting_options.panel_height_cm * n_rows);


if ~exist("base_dir", 'var') || isempty(base_dir)
	base_dir = fullfile('Y:', 'SCP_DATA');
end


if ~exist("input_table", 'var') || isempty(input_table)
	input_table_fqn = fullfile(base_dir, 'SCP-CTRL-01', 'SESSIONLOGS', 'All_session_summary_table.V2.table.mat');
end

if ~isempty(input_table_fqn) || ischar(input_table)
	if exist('input_table', 'var')
		input_table_fqn = input_table;
	end
	disp([mfilename, ': loading session data table: ', input_table_fqn]);
	load(input_table_fqn, 'output_data_table');
elseif istable(input_table)
	output_data_table = input_table;
end
session_table_col_names = fieldnames(output_data_table);


% TODO load per animal EPHYS tables....
% NOTE this reads only the first sheet
Curius_ephys_table_fqn = fullfile(base_dir, 'EPHYS_per_session_unit_channel_information', 'CURIUS', 'CURIUS_array_TDTchannel_to_FMApin_mapping.current.xlsx');
Ephys_table.Curius.sheetnames = sheetnames(Curius_ephys_table_fqn);
Ephys_table.Curius.opts = detectImportOptions(Curius_ephys_table_fqn);
Ephys_table.Curius.Electrode_to_TDT_Channel_Mapping = readtable(Curius_ephys_table_fqn, 'Sheet', 'Electrode_to_TDT_Channel_Mappin', 'VariableNamesRow', 1, 'VariableDescriptionsRow', 2, "VariableNamingRule","preserve");
Ephys_table.Curius.Channel_Classfication = readtable(Curius_ephys_table_fqn, 'Sheet', 'Channel_Classfication', 'VariableNamesRow', 1, 'VariableDescriptionsRow', 2, "VariableNamingRule","preserve");
Ephys_table.Curius.Impedance_by_session = readtable(Curius_ephys_table_fqn, 'Sheet', 'Impedance_by_session', 'VariableNamesRow', 1, 'VariableDescriptionsRow', 2, "VariableNamingRule","preserve");
Curius_TDT_channel_ldx = ~isnan(Ephys_table.Curius.Electrode_to_TDT_Channel_Mapping.TDT_subchannel(:));
% for Curius array A4 was generally without signal, but not classified -1
exclude_channels_idx.Curius = (1:1:32) + (32 * (4 - 1));
%exclude_channels_idx.Curius = setdiff(exclude_channels_idx.Curius, [105,121, 122]); % for LFP export we need to skip array A4



Elmo_ephys_table_fqn = fullfile(base_dir, 'EPHYS_per_session_unit_channel_information', 'ELMO', 'ELMO_array_TDTchannel_to_FMApin_mapping.current.xlsx');
Ephys_table.Elmo.sheetnames = sheetnames(Elmo_ephys_table_fqn);
Ephys_table.Elmo.opts = detectImportOptions(Elmo_ephys_table_fqn);
Ephys_table.Elmo.Electrode_to_TDT_Channel_Mapping = readtable(Elmo_ephys_table_fqn, 'Sheet', 'Electrode_to_TDT_Channel_Mappin', 'VariableNamesRow', 1, 'VariableDescriptionsRow', 2, "VariableNamingRule","preserve");
Ephys_table.Elmo.Channel_Classfication = readtable(Elmo_ephys_table_fqn, 'Sheet', 'Channel_Classfication', 'VariableNamesRow', 1, 'VariableDescriptionsRow', 2, "VariableNamingRule","preserve");
Ephys_table.Elmo.Impedance_by_session = readtable(Elmo_ephys_table_fqn, 'Sheet', 'Impedance_by_session', 'VariableNamesRow', 1, 'VariableDescriptionsRow', 2, "VariableNamingRule","preserve");
Elmo_TDT_channel_ldx = ~isnan(Ephys_table.Elmo.Electrode_to_TDT_Channel_Mapping.TDT_subchannel(:));
% for Curius array A4 was generally bad
exclude_channels_idx.Elmo = []; %(1:1:32) + (32 * (4 - 1));
exclude_channels_idx.Elmo = setdiff(exclude_channels_idx.Elmo, []);



%Elmo_ephys_table = readtable(Elmo_ephys_table_fqn, ReadRowNames=true);
%Elmo_ephys_table.TDTChannel(Elmo_TDT_channel_ldx);


% get our ducks in a row
Curius_ldx = ismember(output_data_table.subject_A, {'Curius'}) | ismember(output_data_table.subject_B, {'Curius'});
Elmo_ldx = ismember(output_data_table.subject_A, {'Elmo'}) | ismember(output_data_table.subject_B, {'Elmo'});
A_Curius_ldx = ismember(output_data_table.subject_A, {'Curius'});
A_Elmo_ldx = ismember(output_data_table.subject_A, {'Elmo'});
B_Curius_ldx = ismember(output_data_table.subject_B, {'Curius'});
B_Elmo_ldx = ismember(output_data_table.subject_B, {'Elmo'});

EPHYS_ldx = ~ismember(output_data_table.EPhysRecorded, {'0'});

COMBINATION_row_ldx = ismember(output_data_table.record_type, {'COMBINATION'});
TOTAL_row_ldx = ismember(output_data_table.record_type, {'TOTAL'});
Dyadic_ldx = ismember(output_data_table.effective_trial_subtype, {'Dyadic'});

[n_data_rows, n_data_cols] = size(output_data_table);

no_GoodChannel_Map_ldx = ismember(output_data_table.GoodChannelMap, {'', 'N_1'});
GoodChannel_Map_ldx = ~no_GoodChannel_Map_ldx;

subject_name_list = {'Curius', 'Elmo'};
subject_ldx_list = {Curius_ldx, Elmo_ldx};

results = struct();
for i_subject = 1 : length(subject_name_list)
	cur_subject_name = subject_name_list{i_subject};
	cur_subject_ldx = subject_ldx_list{i_subject};

	cur_row_ldx = cur_subject_ldx & COMBINATION_row_ldx & GoodChannel_Map_ldx;

	cur_session_ID_set = output_data_table.session_ID(cur_row_ldx);
	% which session contain GoodChannelMaps for the given subject
	unique_ephys_sessions = unique(cur_session_ID_set);
	% construct the key for the first entry for a session, guanteed to be
	% record_type COMBINATION, and all COMBINATIONS of a session inherit
	% the same GoodChannelMap
	unique_ephys_sessions_sort_key_strings = strcat(unique_ephys_sessions, '_001'); % this will only find one per session...
	n_GoodChannelMap_sessions = length(unique_ephys_sessions_sort_key_strings);

	cur_GoodChannelMap_session_idx = [];
	n_channels_in_ChannelMap = 0;
	GoodChannelMap_by_session = [];
	for i_GoodChannelMap_session = 1: n_GoodChannelMap_sessions
		cur_GoodChannelMap_session = unique_ephys_sessions_sort_key_strings{i_GoodChannelMap_session};
		cur_session_sort_key_idx = find(ismember(output_data_table.sort_key_string, {cur_GoodChannelMap_session}));
		cur_GoodChannelMap_session_idx(i_GoodChannelMap_session) = cur_session_sort_key_idx;
		cur_GoodChannelMap_string =  output_data_table.GoodChannelMap{cur_session_sort_key_idx};
		cur_GoodChannelMap = str2num(cur_GoodChannelMap_string);

		if isempty(GoodChannelMap_by_session)
			GoodChannelMap_by_session = nan([n_GoodChannelMap_sessions, length(cur_GoodChannelMap)]);
		end
		GoodChannelMap_by_session(i_GoodChannelMap_session, :) = cur_GoodChannelMap;
	end

	% now calculate the data from the table
	stat_struct.GoodChannelMap_by_session = fn_calc_summary_stats(GoodChannelMap_by_session, ci_alpha);

	% now look at the Ephys_tables
	cur_Channel_Classfication_table = Ephys_table.(cur_subject_name).Channel_Classfication;

	%now dive in and collect information for the sessions, get counts for
	%all of" 5, 4, 3, 2, 1, 0, -1, -2, -9 and the decide which to plot

	cur_Channel_Classfication_col_names = fieldnames(cur_Channel_Classfication_table);	
	%matching_col_ldx = fn_find_regexpmatch_entries_in_cell_list(cur_Channel_Classfication_col_names, ['^[A|B]_', cur_subject_name, '_20*']);
	channel_classification_data_col_ldx = fn_find_regexpmatch_entries_in_cell_list(cur_Channel_Classfication_col_names, ['^[A|B]_', cur_subject_name, '_\d{8}']);

	% we only want to operate on channels
	sorted_ephys_channel_idx = ~isnan(Ephys_table.(cur_subject_name).Electrode_to_TDT_Channel_Mapping.TDT_subchannel(:));



	% TODO extract information about:
	%	units (average of positive integers or Upositive-integer) per channel
	%	exclusions (fraction of -1)
	%	OLED artifacts...

	array_ID_by_channel_list = cur_Channel_Classfication_table.("Array Pos.")(sorted_ephys_channel_idx);
	channel_by_array_ID = {find(ismember(array_ID_by_channel_list, {'A1'}))};
	channel_by_array_ID(end+1) = {find(ismember(array_ID_by_channel_list, {'A2'}))};
	channel_by_array_ID(end+1) = {find(ismember(array_ID_by_channel_list, {'A3'}))};
	channel_by_array_ID(end+1) = {find(ismember(array_ID_by_channel_list, {'A4'}))};
	channel_by_array_ID(end+1) = {find(ismember(array_ID_by_channel_list, {'A5'}))};




	% get the areas PMv, PMd
	PMv_ldx = fn_find_regexpmatch_entries_in_cell_list(cur_Channel_Classfication_table.Area(sorted_ephys_channel_idx), ['PMv$']);
	PMd_ldx = fn_find_regexpmatch_entries_in_cell_list(cur_Channel_Classfication_table.Area(sorted_ephys_channel_idx), ['PMd$']);
	

	legend_objects = [];
	legend_text = {};

	out_name = [cur_subject_name, '_ephys_channel_classfication'];
	cur_fh = figure('Name', out_name, 'Visible', plotting_options.figure_visibility_string);
	output_rect = fn_set_figure_outputpos_and_size(cur_fh, plotting_options.margin_cm, plotting_options.margin_cm, plot_width_cm, plot_height_cm, 1.0, 'portrait', 'inch');
	cur_th = tiledlayout(cur_fh, n_rows, n_cols);
	%cur_fh = figure('Name', [cur_subject_name]);

	legend_objects(end+1) = plot(stat_struct.GoodChannelMap_by_session.mean, 'Marker', '+', 'Color', [0 1 0], 'DisplayName', 'GoodChannelMap');
	yline([0]);
	xline([32, 64, 96, 128]+0.5);
	xticks([1, 32, 64, 96, 128, 160]);
	set(gca, 'YLim', [-0.05 1.05]);
	yticks([0, 0.5, 1.0]);
	xlabel('Channel number');
	ylabel('Fraction over sessions');
	title(cur_subject_name);

	lh = legend(legend_objects, legend_text,'Orientation','horizontal', 'Location', 'EastOutside', 'box', 'off');
	lh.ItemTokenSize=[10,15];

	% return the sets of PMv and PMd chaneels with least rejections for all
	% subjects, ideally these would be sorted by some measure, but lets
	% start with

	PMv_proto_candidate_channel_ldx = (stat_struct.GoodChannelMap_by_session.mean == 1.0) & PMv_ldx;
	PMv_candidate_channel_idx = setdiff(find(PMv_proto_candidate_channel_ldx), exclude_channels_idx.(cur_subject_name));
	PMd_proto_candidate_channel_ldx = (stat_struct.GoodChannelMap_by_session.mean == 1.0) & PMd_ldx;
	PMd_candidate_channel_idx = setdiff(find(PMd_proto_candidate_channel_ldx), exclude_channels_idx.(cur_subject_name));

	out_struct.subject_name = cur_subject_name;
	out_struct.stat_struct = stat_struct;
	out_struct.exclude_channels_idx = exclude_channels_idx;
	out_struct.GoodChannelMap_fraction_good_ldx = (stat_struct.GoodChannelMap_by_session.mean == 1.0);
	% PMv
	out_struct.PMv_ldx = PMv_ldx;
	out_struct.PMv_proto_candidate_channel_ldx = PMv_proto_candidate_channel_ldx;
	out_struct.PMv_candidate_channel_idx = PMv_candidate_channel_idx;
	% PMd
	out_struct.PMd_ldx = PMd_ldx;
	out_struct.PMd_proto_candidate_channel_ldx = PMd_proto_candidate_channel_ldx;
	out_struct.PMd_candidate_channel_idx = PMd_candidate_channel_idx;

	% now we should try to select the "best" channels to get sets of ten,
	% ideally over multiple arrays?

	% we want to mix between arrays but to keep it simple just use
	% randperm, but with a fixed seed
	rng(12345,"twister");
	export_N_channels_pre_area = 10;
	out_struct.export_N_channels_pre_area = export_N_channels_pre_area;
	tmp_shuffled_order = randperm(length(PMv_candidate_channel_idx));
	out_struct.(['PMv_', num2str(export_N_channels_pre_area)]) = PMv_candidate_channel_idx(tmp_shuffled_order(1:export_N_channels_pre_area));

	tmp_shuffled_order = randperm(length(PMd_candidate_channel_idx));
	out_struct.(['PMd_', num2str(export_N_channels_pre_area)]) = PMd_candidate_channel_idx(tmp_shuffled_order(1:export_N_channels_pre_area));

	selected_channels_per_area.PMv = out_struct.(['PMv_', num2str(export_N_channels_pre_area)]);
	selected_channels_per_area.PMd = out_struct.(['PMd_', num2str(export_N_channels_pre_area)]);
	disp([mfilename, ': PMv, ', cur_subject_name, ': ', num2str(selected_channels_per_area.PMv)]);
	disp([mfilename, ': PMd, ', cur_subject_name, ': ', num2str(selected_channels_per_area.PMd)]);



	% save the information to file
	cur_subject_channel_info_FQN = fullfile(base_dir, 'SCP-CTRL-01', 'LFP_export_per_session', [cur_subject_name, '_selected_channels_per_area.mat']);
	if ~isfolder(fileparts(cur_subject_channel_info_FQN))
		mkdir(fileparts(cur_subject_channel_info_FQN));
	end
	disp([mfilename, ': Saving information to ', cur_subject_channel_info_FQN]);
	save(cur_subject_channel_info_FQN, 'out_struct', 'selected_channels_per_area');

end


return



dyadic_ldx = ismember(output_data_table.effective_trial_subtype, {'Dyadic'});

% find the samples for human confederate on side A in mixed pairs
A_HP_ldx = ismember(output_data_table.species_A, {'HP'});
B_HP_ldx = ismember(output_data_table.species_B, {'HP'});
A_NHP_ldx = ismember(output_data_table.species_A, {'NHP'});
B_NHP_ldx = ismember(output_data_table.species_B, {'NHP'});
A_HP_B_NHP_ldx = A_HP_ldx & B_NHP_ldx;
A_NHP_B_HP_ldx = A_NHP_ldx & B_HP_ldx;
mixed_species_trial_ldx = (A_HP_ldx & B_NHP_ldx)  | (A_NHP_ldx & B_HP_ldx);
A_BLOCKED_ldx = ismember(output_data_table.CueRandomizationMethod_A, {'BLOCKED'});
A_SHUFFLED_ldx = ismember(output_data_table.CueRandomizationMethod_A, {'SHUFFLED'});
B_BLOCKED_ldx = ismember(output_data_table.CueRandomizationMethod_B, {'BLOCKED'});
B_SHUFFLED_ldx = ismember(output_data_table.CueRandomizationMethod_B, {'SHUFFLED'});



% now split for A_HP_B_NHP_ldx and A_NHP_B_HP_ldx and collect the data
A_HP_B_NHP_BLOCKED_ldx = A_HP_B_NHP_ldx & dyadic_ldx & A_BLOCKED_ldx;
A_HP_B_NHP_SHUFFLED_ldx = A_HP_B_NHP_ldx & dyadic_ldx & A_SHUFFLED_ldx;

A_NHP_B_HP_BLOCKED_ldx = A_NHP_B_HP_ldx & dyadic_ldx & B_BLOCKED_ldx;
A_NHP_B_HP_SHUFFLED_ldx = A_NHP_B_HP_ldx & dyadic_ldx & B_SHUFFLED_ldx;

% {'A_nonrandomSide_p', 'A_nonrandomValue_p', 'B_nonrandomSide_p', 'B_nonrandomValue_p'}
% side choices
HP_BLOCKED_nonrandomSide_p = [output_data_table.A_nonrandomSide_p(A_HP_B_NHP_BLOCKED_ldx); output_data_table.B_nonrandomSide_p(A_NHP_B_HP_BLOCKED_ldx)];
HP_SHUFFLED_nonrandomSide_p = [output_data_table.A_nonrandomSide_p(A_HP_B_NHP_SHUFFLED_ldx); output_data_table.B_nonrandomSide_p(A_NHP_B_HP_SHUFFLED_ldx)];

% value choices...
HP_BLOCKED_nonrandomValue_p = [output_data_table.A_nonrandomSide_p(A_HP_B_NHP_BLOCKED_ldx); output_data_table.B_nonrandomValue_p(A_NHP_B_HP_BLOCKED_ldx)];
HP_SHUFFLED_nonrandomValue_p = [output_data_table.A_nonrandomSide_p(A_HP_B_NHP_SHUFFLED_ldx); output_data_table.B_nonrandomValue_p(A_NHP_B_HP_SHUFFLED_ldx)];


% histogram(log(HP_BLOCKED_nonrandomValue_p), 100);
% hold on
% histogram(log(HP_SHUFFLED_nonrandomValue_p), 100);
% hold off
% 
% h1 = histogram((HP_BLOCKED_nonrandomValue_p), (0: 0.0005: 0.2));
% hold on
% h2 = histogram((HP_SHUFFLED_nonrandomValue_p), (0: 0.005: 0.2));
% hold off



% select 10 sessions with BLOCKED and SHUFFLED partner for Elmo and Curius
% with decent following
Curius_ldx = ismember(output_data_table.subject_A, {'Curius'}) | ismember(output_data_table.subject_B, {'Curius'});
A_Elmo_ldx = ismember(output_data_table.subject_A, {'Elmo'}) | ismember(output_data_table.subject_B, {'Elmo'});
EPHYS_ldx = ~ismember(output_data_table.EPhysRecorded, {'0'});
A_predicts_B_ldx = (output_data_table.A_predicts_Bvalue);

% try to find the best 10 prediction and non prediction sessions
Curius_predicts_BLOCKED_CONF_idx = find(A_NHP_B_HP_BLOCKED_ldx & Curius_ldx & EPHYS_ldx & A_predicts_B_ldx);
Curius_ignores_SHUFFLED_CONF_idx = find(A_NHP_B_HP_SHUFFLED_ldx & Curius_ldx & EPHYS_ldx & ~A_predicts_B_ldx);

Elmo_predicts_BLOCKED_CONF_idx = find(A_NHP_B_HP_BLOCKED_ldx & A_Elmo_ldx & EPHYS_ldx & A_predicts_B_ldx);
Elmo_ignores_SHUFFLED_CONF_idx = find(A_NHP_B_HP_SHUFFLED_ldx & A_Elmo_ldx & EPHYS_ldx & ~A_predicts_B_ldx);


% sort by prediction % use HitTrials only as cut off (> 200?)


% pick the 10 sessions each with most dyadic trials...
n_sessions_to_pick = 10;

output_data_table.HitTrials(Curius_predicts_BLOCKED_CONF_idx)
output_data_table.B_nonrandomValue_p(Curius_predicts_BLOCKED_CONF_idx)
[~, sort_idx] = sort(output_data_table.HitTrials(Curius_predicts_BLOCKED_CONF_idx));
Curius_BLOCKED_CONF_top_10 = output_data_table.session_ID(Curius_predicts_BLOCKED_CONF_idx(sort_idx(1:n_sessions_to_pick+0)));
Curius_BLOCKED_CONF_top_10 = unique(Curius_BLOCKED_CONF_top_10);


output_data_table.HitTrials(Curius_ignores_SHUFFLED_CONF_idx)
output_data_table.B_nonrandomValue_p(Curius_ignores_SHUFFLED_CONF_idx)
[~, sort_idx] = sort(output_data_table.HitTrials(Curius_ignores_SHUFFLED_CONF_idx));
Curius_SHUFFLED_CONF_top_10 = output_data_table.session_ID(Curius_ignores_SHUFFLED_CONF_idx(sort_idx(1:n_sessions_to_pick+1)));
Curius_SHUFFLED_CONF_top_10 = unique(Curius_SHUFFLED_CONF_top_10);


output_data_table.HitTrials(Elmo_predicts_BLOCKED_CONF_idx)
output_data_table.B_nonrandomValue_p(Elmo_predicts_BLOCKED_CONF_idx)
[~, sort_idx] = sort(output_data_table.HitTrials(Elmo_predicts_BLOCKED_CONF_idx));
Elmo_BLOCKED_CONF_top_10 = output_data_table.session_ID(Elmo_predicts_BLOCKED_CONF_idx(sort_idx(1:n_sessions_to_pick+3)));
Elmo_BLOCKED_CONF_top_10 = unique(Elmo_BLOCKED_CONF_top_10);


output_data_table.HitTrials(Elmo_ignores_SHUFFLED_CONF_idx)
output_data_table.B_nonrandomValue_p(Elmo_ignores_SHUFFLED_CONF_idx)
[~, sort_idx] = sort(output_data_table.HitTrials(Elmo_ignores_SHUFFLED_CONF_idx));
Elmo_SHUFFLED_CONF_top_10 = output_data_table.session_ID(Elmo_ignores_SHUFFLED_CONF_idx(sort_idx(1:n_sessions_to_pick)));
Elmo_SHUFFLED_CONF_top_10 = unique(Elmo_SHUFFLED_CONF_top_10);



return
end

