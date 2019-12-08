function [ output_args ] = fnAggregateAndPlotCoordinationMetricsByGroup( session_metrics_datafile_fqn, group_struct_list, metrics_to_extract_list, project_name )
%FNAGGREGATEANDPLOTCOORDINATIONMETRICSBYGROUP Summary of this function goes here
%   Detailed explanation goes here

% TODO:
%   add scatter plot of the AR faster vs AR slower for all groups
%       add statistical test
%   plots comparing the different phases in blocked experiements for NHP
%   and humans
%   add test for temporal following
%   add sorting to the groups (intra-group sorting by say AR)
%   change labels to identifiers, for MI plot and scatter plots



if ~exist('project_name', 'var') || isempty(project_name)
	% this requires subject_bias_analysis_sm01 to have run with the same project_name
	% which essentially defines the subset of sessions to include
	project_name = [];
	project_set = 'BoS_human_monkey_2019';
	project_name = 'BoS_manuscript';
else
	project_set = project_name;
end


timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);



output_args = [];

if ~exist('session_metrics_datafile_fqn', 'var') || isempty(session_metrics_datafile_fqn)
	%InputPath = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2018');
	InputPath = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2019');
	InputPath = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2019');
	
	if ~isempty(project_name)
		InputPath = fullfile(InputPath, project_name);
	end
	
	session_metrics_datafile_fqn = fullfile(InputPath, ['ALL_SESSSION_METRICS.late200.mat']);
	session_metrics_datafile_fqn = fullfile(InputPath, ['ALL_SESSSION_METRICS.last200.mat']);
	
	session_metrics_datafile_fqn_list = {...
		fullfile(InputPath, ['ALL_SESSSION_METRICS.last200.mat']), ...
		fullfile(InputPath, ['ALL_SESSSION_METRICS.last250.mat']), ...
		fullfile(InputPath, ['ALL_SESSSION_METRICS.last150.mat']), ...
		fullfile(InputPath, ['ALL_SESSSION_METRICS.last100.mat']), ...
		fullfile(InputPath, ['ALL_SESSSION_METRICS.all_joint_choice_trials.mat']), ...
		fullfile(InputPath, ['ALL_SESSSION_METRICS.first100.mat']),...
		fullfile(InputPath, ['ALL_SESSSION_METRICS.visible_pre.mat']),...
		fullfile(InputPath, ['ALL_SESSSION_METRICS.invisible.mat']),...
		fullfile(InputPath, ['ALL_SESSSION_METRICS.visible_post.mat']),...
		};
	session_metrics_datafile_IDtag_list = {...
		'last200', ...
		'last250', ...
		'last150', ...
		'last100', ...
		'all_joint_choice_trials', ...
		'first100', ...
		'visible_pre', ...
		'invisible', ...
		'visible_post', ...
		};
end

[OutputPath, FileName, FileExt] = fileparts(session_metrics_datafile_fqn);

OutputPath = fullfile(InputPath, 'AggregatePlots');

if ~isdir(OutputPath)
	mkdir(OutputPath);
end


if ~exist('metrics_to_extract_list', 'var') || isempty(metrics_to_extract_list)
	metrics_to_extract_list = {'AR'};
end

if ~exist('group_struct_list', 'var') || isempty(group_struct_list)
	group_struct_list = fn_get_session_group(project_set);
end
group_struct_setlabel_list = cell(size(group_struct_list));
for i_group = 1 : length(group_struct_list)
	group_struct_setlabel_list{i_group} = group_struct_list{i_group}.setLabel;
end



copy_plots_to_outdir_by_group = 1;
copy_plots_to_outdir_by_group_only = 0;
copy_is_move = 0;

if strcmp(project_name, 'BoS_manuscript')
	copy_is_move = 1;
end

generate_session_reports = 1;

% control variables
plot_avererage_reward_by_group = 1;
AR_by_group_setlabel_list = {'HumansTransparent', 'Macaques_early', 'Macaques_late', 'ConfederateTrainedMacaques'};

confidence_interval_alpha = 0.05;
wilcoxon_signed_rank_alpha = 0.05;
fisher_alpha = 0.05;
plot_MI_space_scatterplot = 1;
MI_space_set_list = {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late', 'HumansOpaque'}; % the set names to display
MI_space_set_list = {'Humans', 'Macaques_late', 'HumansOpaque', 'Humans50_50'}; % the set names to display
MI_space_set_list = {'GoodHumans', 'Macaques_late', 'BadHumans'}; % the set names to display HumansEC:= without the session without solo training
% paper
MI_space_set_list = {'HumansTransparent', 'Macaques_late', 'ConfederateTrainedMacaques'}; % the set names to display


MI_jitter_x_on_collision = 0.05;
MI_jitter_y_on_collision = 0.05;


MI_space_mark_non_significant_sessions = 1;% our MI space x-postion is only reliable if at least one of MIs and MIt are significantly different from zero
mark_flaffus_curius = 0;
MI_mark_all = 1;
XX_marker_ID_use_captions = 1;
MI_normalize_coordination_strength_50_50 = 1;
MI_coordination_strength_method = 'max';% max or vectorlength
MI_threshold = [];
AR_SCATTER_mark_all = 1;

AR_scatter_show_FET = 1;

if strcmp(project_name, 'BoS_manuscript')
	AR_scatter_show_FET = 0;
end

plot_coordination_metrics_for_each_group = 1;
plot_coordination_metrics_for_each_group_graph_type = 'line';% bar or line
coordination_metrics_sort_by_string = 'AVG_rewardAB'; % 'none', 'AVG_rewardAB'


plot_AR_scatter_by_training_state = 1;
plot_AR_scatter_by_session_state_early_late = 1;


plot_blocked_confederate_data = 0;

plot_RT_by_switch_type = 1;
% for each member in selected_choice_combinaton_pattern_list  extract a histogram form a given data list
pattern_alignment_offset = 1; % the offset to the position
n_pre_bins = 3;
n_post_bins = 3;
strict_pattern_extension = 1;
pad_mismatch_with_nan = 1;
full_choice_combinaton_pattern_list = {'RM', 'MR', 'BM', 'MB', 'RB', 'BR', 'RG', 'GR', 'BG', 'GB', 'GM', 'MG'};
selected_choice_combinaton_pattern_list = full_choice_combinaton_pattern_list;
if strcmp(project_name, 'BoS_manuscript')
	selected_choice_combinaton_pattern_list = {'RM', 'MR', 'BM', 'MB', 'RB', 'BR'};
end
orange = [255 165 0]/256;
green = [0 1 0];
SideAColor = [1 0 0];
SideBColor = [0 0 1];
%aggregate_type_meta_list = {'nan_padded', 'raw'};
aggregate_type_meta_list = {'nan_padded'}; % the raw looks like a derivative of the nan_padded
RT_type = 'IniTargRel_05MT_RT';
StackHeightToInitialPLotHeightRatio = 0.1;
% 20180815 new colors..., for joint report the joint color (well blue
% instead of yellow), for both same use magenta, and for both other use
% green
SameOwnAColor = [1 0 0];%[1 0 0];
SameOwnBColor = [0 0 1];%([255 165 0] / 255);
DiffOwnColor = [1 0 1];%[1 0 0];
DiffOtherColor = [0 1 0];%[0 0 1];

bar_edge_color = [0 0 0];
if strcmp(project_name, 'BoS_manuscript')
	bar_edge_color = 'none';
end



XLabelRotation_degree = 90; % rotate the session labels to allow non-numeric labels on denser plots?
close_figures_at_end = 1;

%project_name = 'SfN208';
CollectionName = project_name;
project_line_width = 0.5;
OutPutType = 'pdf'; % this currently also saves pdf and fig
%OutPutType = 'pdf';
DefaultAxesType = 'BoS_manuscript'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
DefaultPaperSizeType = 'Plos'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
%output_rect_fraction = 0.5; % default 0.5
output_rect_fraction = 1/2.54; % matlab's print will interpret values as INCH even for PaperUnit centimeter specified figures...

save_fig = 0;

InvisibleFigures = 0;

if ~exist('fnFormatDefaultAxes')
	set(0, 'DefaultAxesLineWidth', 0.5, 'DefaultAxesFontName', 'Arial', 'DefaultAxesFontSize', 6, 'DefaultAxesFontWeight', 'normal');
end

if (InvisibleFigures)
	figure_visibility_string = 'off';
else
	figure_visibility_string = 'on';
end


% just copy the individual figures for all sessions of a group into a named
% subdirectory, to allow easier selection
if (copy_plots_to_outdir_by_group)
	for i_group = 1 : length(group_struct_list)
		current_group = group_struct_list{i_group};
		current_setname = current_group.setLabel;
		outdir = fullfile(OutputPath, '..', 'SessionSetPlots', current_setname);
		if ~exist(outdir, 'dir')
			mkdir(outdir)
		end
		% loop over all files
		current_session_id_list = current_group.filenames;
		for i_stem = 1 : length(current_session_id_list)
			current_proto_stem = current_session_id_list{i_stem};
			current_proto_stem = regexprep(current_proto_stem, '_IC_JointTrials.isOwnChoice_sideChoice$', '');
			current_stem = regexprep(current_proto_stem, '^DATA_', '');
			disp(['Processing: ', current_stem]);
			
			if (copy_is_move)
				[status, message] = movefile(fullfile(InputPath, [current_stem, '*']), [outdir, filesep]);
			else
				[status, message] = copyfile(fullfile(InputPath, [current_stem, '*']), [outdir, filesep]);
			end
			
			% also copy the isOwnChoice_sideChoice files
			disp(['Processing: ', [current_session_id_list{i_stem}, '.mat']]);
			[status, message] = copyfile(fullfile(InputPath, 'CoordinationCheck', [current_session_id_list{i_stem}, '.mat']), [outdir, filesep]);
			
			%HACK ALARM copy back
			%[status, message] = copyfile(fullfile(outdir, [current_session_id_list{i_stem}, '.mat']), fullfile(InputPath, 'CoordinationCheck', filesep));
		end
	end
	disp('Copied all plots...');
	if (copy_plots_to_outdir_by_group_only)
		return
	end
end


group_concatenated_pertrial_data = [];
bygroup = [];

if (generate_session_reports)
	data_struct_list = cell([length(group_struct_list) 1]);
	for i_group = 1 : length(group_struct_list)
		group_concatenated_pertrial_data = []; % we need this fresh for every group
		current_group = group_struct_list{i_group};
		current_setname = current_group.setLabel;
		indir = fullfile(OutputPath, '..', 'CoordinationCheck');
		outdir = fullfile(OutputPath, '..', 'SessionSetPlots', current_setname);
		if ~exist(outdir, 'dir')
			mkdir(outdir)
		end
		% loop over all files
		current_session_id_list = current_group.filenames;
		n_sessions_in_set = length(current_session_id_list);
		
		
		header = {'ArBr', 'ArBy', 'AyBr', 'AyBy', 'ARBR', 'ARBL', 'ALBR', 'ALBL', 'Coordinated', 'Noncoordinated'};
		data = zeros([n_sessions_in_set, length(header)]);
		cn = local_get_column_name_indices(header);
		
		for i_jointtrialfile = 1 : length(current_session_id_list)
			tmp_struct = [];
			tmp_struct = load(fullfile(indir, [current_session_id_list{i_jointtrialfile}, '.mat']));
			tmp_idx = intersect(tmp_struct.TrialSets.ByChoice.SideA.TargetValueHigh, tmp_struct.TrialSets.ByChoice.SideB.TargetValueLow);
			ArBr = length(intersect(tmp_struct.TrialsInCurrentSetIdx, tmp_idx));
			data(i_jointtrialfile, cn.ArBr) = ArBr;
			tmp_idx = intersect(tmp_struct.TrialSets.ByChoice.SideA.TargetValueHigh, tmp_struct.TrialSets.ByChoice.SideB.TargetValueHigh);
			ArBy = length(intersect(tmp_struct.TrialsInCurrentSetIdx, tmp_idx));
			data(i_jointtrialfile, cn.ArBy) = ArBy;
			tmp_idx = intersect(tmp_struct.TrialSets.ByChoice.SideA.TargetValueLow, tmp_struct.TrialSets.ByChoice.SideB.TargetValueLow);
			AyBr = length(intersect(tmp_struct.TrialsInCurrentSetIdx, tmp_idx));
			data(i_jointtrialfile, cn.AyBr) = AyBr;
			tmp_idx = intersect(tmp_struct.TrialSets.ByChoice.SideA.TargetValueLow, tmp_struct.TrialSets.ByChoice.SideB.TargetValueHigh);
			AyBy = length(intersect(tmp_struct.TrialsInCurrentSetIdx, tmp_idx));
			data(i_jointtrialfile, cn.AyBy) = AyBy;
			
			Coordinated = ArBr + AyBy;
			data(i_jointtrialfile, cn.Coordinated) = Coordinated;
			Noncoordinated = ArBy + AyBr;
			data(i_jointtrialfile, cn.Noncoordinated) = Noncoordinated;
			
			
			tmp_idx = intersect(tmp_struct.TrialSets.ByChoice.SideA.ChoiceRight, tmp_struct.TrialSets.ByChoice.SideB.ChoiceRight);
			ARBR = length(intersect(tmp_struct.TrialsInCurrentSetIdx, tmp_idx));
			data(i_jointtrialfile, cn.ARBR) = ARBR;
			tmp_idx = intersect(tmp_struct.TrialSets.ByChoice.SideA.ChoiceRight, tmp_struct.TrialSets.ByChoice.SideB.ChoiceLeft);
			ARBL = length(intersect(tmp_struct.TrialsInCurrentSetIdx, tmp_idx));
			data(i_jointtrialfile, cn.ARBL) = ARBL;
			tmp_idx = intersect(tmp_struct.TrialSets.ByChoice.SideA.ChoiceLeft, tmp_struct.TrialSets.ByChoice.SideB.ChoiceRight);
			ALBR = length(intersect(tmp_struct.TrialsInCurrentSetIdx, tmp_idx));
			data(i_jointtrialfile, cn.ALBR) = ALBR;
			tmp_idx = intersect(tmp_struct.TrialSets.ByChoice.SideA.ChoiceLeft, tmp_struct.TrialSets.ByChoice.SideB.ChoiceLeft);
			ALBL = length(intersect(tmp_struct.TrialsInCurrentSetIdx, tmp_idx));
			data(i_jointtrialfile, cn.ALBL) = ALBL;
			% collect data over all members of a group.
			group_concatenated_pertrial_data = fn_concatenate_pertrial_data_over_sessions(group_concatenated_pertrial_data, tmp_struct.FullPerTrialStruct, tmp_struct.TrialsInCurrentSetIdx);
		end
		bygroup{end+1} = group_concatenated_pertrial_data;
		data_struct.header = header;
		data_struct.data = data;
		data_struct.cn = cn;
		data_struct.lists.sessionID = current_session_id_list;
		save(fullfile(outdir, ['session_report.mat']), 'data_struct');
		% now save as text file
		Color_ArBr = data(:, cn.ArBr);
		Color_ArBy = data(:, cn.ArBy);
		Color_AyBr = data(:, cn.AyBr);
		Color_AyBy = data(:, cn.AyBy);
		Side_ARBR = data(:, cn.ARBR);
		Side_ARBL = data(:, cn.ARBL);
		Side_ALBR = data(:, cn.ALBR);
		Side_ALBL = data(:, cn.ALBL);
		data_struct_table = table(Color_ArBr, Color_ArBy, Color_AyBr, Color_AyBy, Side_ARBR, Side_ARBL, Side_ALBR, Side_ALBL, current_session_id_list', 'RowNames', current_session_id_list);
		
		data_struct_table = table(Color_ArBr, Color_ArBy, Color_AyBr, Color_AyBy, current_session_id_list', 'RowNames', current_session_id_list);
		
		writetable(data_struct_table, fullfile(outdir, ['session_report_table.txt']), 'WriteVariableNames', true, 'Delimiter', ';');
		data_struct_list{i_group} = data_struct;
	end
	disp('Created all session reports...');
	%return
end


% loop, load, and group-select all defined session_metric_input files
n_groups = length(group_struct_list);
for i_session_metric_file = 1: length(session_metrics_datafile_fqn_list)
	cur_session_metrics_datafile_fqn = session_metrics_datafile_fqn_list{i_session_metric_file};
	cur_session_metrics_datafile_IDtag = session_metrics_datafile_IDtag_list{i_session_metric_file};
	session_metrics.(cur_session_metrics_datafile_IDtag) = load(cur_session_metrics_datafile_fqn);
	cur_coordination_metrics_table = session_metrics.(cur_session_metrics_datafile_IDtag).coordination_metrics_table;
	session_metrics.(cur_session_metrics_datafile_IDtag).metrics_by_group_list = fn_extract_metrics_by_group(group_struct_list, cur_coordination_metrics_table);
end


% TODO, load the ALL_SESSION_METRICS.mat and extract the desired metric
% for each member session of each set, return a list of those for
% further

%% load the coordination_metrics_table
%load(session_metrics_datafile_fqn);
%metrics_by_group_list = fn_extract_metrics_by_group(group_struct_list, coordination_metrics_table);


for i_session_metric_file = 1 : length(session_metrics_datafile_fqn_list)
	cur_session_metrics_datafile_fqn = session_metrics_datafile_fqn_list{i_session_metric_file};
	cur_session_metrics_datafile_IDtag = session_metrics_datafile_IDtag_list{i_session_metric_file};
	
	if (ismember(cur_session_metrics_datafile_IDtag, {'visible_pre', 'invisible', 'visible_post'}))
		disp([cur_session_metrics_datafile_IDtag, ': not handled by generic code']);
		continue
	end
	
	
	coordination_metrics_table = session_metrics.(cur_session_metrics_datafile_IDtag).coordination_metrics_table;
	metrics_by_group_list = session_metrics.(cur_session_metrics_datafile_IDtag).metrics_by_group_list;
	
	OutputPath = fullfile(InputPath, 'AggregatePlots', cur_session_metrics_datafile_IDtag);
	
	% this should be generated fresh for each session_metrics_file
	Macaque_late_early_sort_idx = [];
	
	TitleSetDescriptorString = '';
	
	% create the plot for averaged average reward per group
	if (plot_avererage_reward_by_group)
		% collect the actual data
		if isempty(AR_by_group_setlabel_list)
			AR_by_group_setlabel_list = group_struct_setlabel_list;
		end
		sorted_set_lidx = ismember(group_struct_setlabel_list, AR_by_group_setlabel_list);
		sorted_set_idx = find(sorted_set_lidx);
		
		AvgRewardByGroup_list = cell(size(AR_by_group_setlabel_list)); % the actual reward values
		AvgRewardByGroup.mean = zeros(size(AR_by_group_setlabel_list));
		AvgRewardByGroup.stddev = zeros(size(AR_by_group_setlabel_list));
		AvgRewardByGroup.n = zeros(size(AR_by_group_setlabel_list));
		AvgRewardByGroup.sem = zeros(size(AR_by_group_setlabel_list));
		AvgRewardByGroup.ci_halfwidth = zeros(size(AR_by_group_setlabel_list));
		AvgRewardByGroup.group_names = cell(size(AR_by_group_setlabel_list));
		AvgRewardByGroup.group_labels = cell(size(AR_by_group_setlabel_list));
		
		% now collect the
		for i_AR_set = 1 : length(AR_by_group_setlabel_list)
			%if ~ismember(group_struct_list{i_group}.label, group_struct_label_list;
			i_group = sorted_set_idx(i_AR_set);
			AvgRewardByGroup.group_names{i_AR_set} = group_struct_list{i_group}.setName;
			AvgRewardByGroup.group_labels{i_AR_set} = group_struct_list{i_group}.label;
			current_group_data = metrics_by_group_list{i_group};
			AvgRewardByGroup_list{i_AR_set} = current_group_data(:, coordination_metrics_table.cn.averReward); % the actual reward values
			AvgRewardByGroup.mean(i_AR_set) = mean(current_group_data(:, coordination_metrics_table.cn.averReward));
			AvgRewardByGroup.stddev(i_AR_set) = std(current_group_data(:, coordination_metrics_table.cn.averReward));
			AvgRewardByGroup.n(i_AR_set) = size(current_group_data, 1);
			AvgRewardByGroup.sem(i_AR_set) = AvgRewardByGroup.stddev(i_AR_set)/sqrt(AvgRewardByGroup.n(i_AR_set));
		end
		AvgRewardByGroup.ci_halfwidth = calc_cihw(AvgRewardByGroup.stddev, AvgRewardByGroup.n, confidence_interval_alpha);
		
		FileName = CollectionName;
		Cur_fh_avg_reward_by_group = figure('Name', 'Average reward by group', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
		legend_list = {};
		%hold on
		
		for i_AR_set = 1 : length(AR_by_group_setlabel_list)
			current_group_name = AvgRewardByGroup.group_names{i_AR_set};
			i_group = sorted_set_idx(i_AR_set);
			
			% to display all individial values as scatter plots randomize the
			% positions for each group
			scatter_width = 0.6;
			x_list = ones(size(AvgRewardByGroup_list{i_AR_set})) * i_AR_set;
			scatter_offset_list = (scatter_width * rand(size(AvgRewardByGroup_list{i_AR_set}))) - (scatter_width * 0.5);
			if (length(x_list) > 1)
				x_list = x_list + scatter_offset_list;
			end
			
			hold on
			bar(i_AR_set, AvgRewardByGroup.mean(i_AR_set), 'FaceColor', group_struct_list{i_group}.color, 'EdgeColor', [0.25 0.25 0.25]);
			errorbar(i_AR_set, AvgRewardByGroup.mean(i_AR_set), AvgRewardByGroup.ci_halfwidth(i_AR_set), 'Color', [0.25 0.25 0.25]);
			
			%
			ScatterSymbolSize = 25;
			ScatterLineWidth = 0.75;
			current_scatter_color = group_struct_list{i_group}.color;
			current_scatter_color = [0.5 0.5 0.5];
			
			current_marker = group_struct_list{i_group}.Symbol;
			if strcmp(group_struct_list{i_group}.Symbol, 'none')
				% skip sets no symbol, as scatter does not tolerate
				current_marker = 'p';
			end
			
			if group_struct_list{i_group}.FilledSymbols
				scatter(x_list, AvgRewardByGroup_list{i_AR_set}, ScatterSymbolSize, current_scatter_color, current_marker, 'filled', 'LineWidth', ScatterLineWidth);
			else
				scatter(x_list, AvgRewardByGroup_list{i_AR_set}, ScatterSymbolSize, current_scatter_color, current_marker, 'LineWidth', ScatterLineWidth);
			end
			
			if (mark_flaffus_curius)
				if strcmp(group_struct_list{i_group}.setName, 'Macaques early') || strcmp(group_struct_list{i_group}.setName, 'Macaques late')
					for i_session = 1 : length(group_struct_list{i_group}.filenames)
						if ~isempty(strfind(group_struct_list{i_group}.filenames{i_session}, 'A_Flaffus.B_Curius'))
							dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
							text(x_list(i_session)+dx, AvgRewardByGroup_list{i_AR_set}(i_session)+dy, {num2str(i_session)},'Color', current_scatter_color, 'Fontsize', 8);
						end
					end
				end
			end
			if (MI_mark_all)
				for i_session = 1 : length(group_struct_list{i_group}.filenames)
					dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
					if (XX_marker_ID_use_captions)
						cur_ID_string = group_struct_list{i_group}.Captions{i_session};
					else
						cur_ID_string = num2str(i_session);
					end
					text(x_list(i_session)+dx, AvgRewardByGroup_list{i_AR_set}(i_session)+dy, {cur_ID_string},'Color', current_scatter_color, 'Fontsize', 8);
				end
			end
			
			
			hold off
		end
		
		
		xlabel('Grouping', 'Interpreter', 'none');
		ylabel('Average Reward', 'Interpreter', 'none');
		set(gca, 'XLim', [1-0.8 (length(AR_by_group_setlabel_list))+0.8]);
		set(gca, 'XTick', []);
		%set(gca, 'XTick', (1:1:n_groups));
		%set(gca, 'XTickLabel', AvgRewardByGroup.group_labels, 'TickLabelInterpreter', 'none');
		
		set(gca(), 'YLim', [0.9, 4.1]);
		set(gca(), 'YTick', [1 1.5 2 2.5 3 3.5 4]);
		%     if (PlotLegend)
		%         legend(legend_list, 'Interpreter', 'None');
		%     end
		CurrentTitleSetDescriptorString = TitleSetDescriptorString;
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardByGroup.', OutPutType]);
		write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardByGroup.', 'pdf']);
		write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
		if (save_fig)
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardByGroup.', 'fig']);
			write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
		end
	end
	
	
	if (plot_MI_space_scatterplot)
		% collect the actual data
		MIs_by_group_miside_list = cell(size(group_struct_list)); % the actual MIside values per group
		MIs_by_group_mitarget_list = cell(size(group_struct_list)); % the actual MItarget values per group
		
		MIs_by_group.miTargetSignif = cell(size(group_struct_list));
		MIs_by_group.miSideSignif = cell(size(group_struct_list));
		MIs_by_group.bothMIsNotSignif_idx = cell(size(group_struct_list));
		
		MIs_by_group.group_names = cell(size(group_struct_list));
		MIs_by_group.group_labels = cell(size(group_struct_list));
		MIs_by_group.vectorlength = cell(size(group_struct_list));
		MIs_by_group.atan = cell(size(group_struct_list));
		MIs_by_group.max = cell(size(group_struct_list));
		
		% now collect the
		for i_group = 1 : n_groups
			MIs_by_group.group_names{i_group} = group_struct_list{i_group}.setName;
			MIs_by_group.group_labels{i_group} = group_struct_list{i_group}.label;
			
			current_group_data = metrics_by_group_list{i_group};
			
			MIs_by_group.miTargetSignif{i_group} = current_group_data(:, coordination_metrics_table.cn.miTargetSignif);
			MIs_by_group.miSideSignif{i_group} = current_group_data(:, coordination_metrics_table.cn.miSideSignif);
			MIs_by_group.bothMIsNotSignif_idx{i_group} = find((MIs_by_group.miTargetSignif{i_group} + MIs_by_group.miSideSignif{i_group}) == 0);
			
			MIs_by_group_miside_list{i_group} = current_group_data(:, coordination_metrics_table.cn.miSide);
			MIs_by_group_mitarget_list{i_group} = current_group_data(:, coordination_metrics_table.cn.miTarget);
			MIs_by_group.vectorlength{i_group} = sqrt(MIs_by_group_miside_list{i_group}.^2 + MIs_by_group_mitarget_list{i_group}.^2);
			MIs_by_group.max{i_group} = max([MIs_by_group_miside_list{i_group}, MIs_by_group_mitarget_list{i_group}], [], 2);
			
			tmp = atan(MIs_by_group_miside_list{i_group} ./ MIs_by_group_mitarget_list{i_group});
			% since division by zero is undefined we need to special case of
			% MI target == 0, here we just clamp to the extreme right value
			tmp(MIs_by_group_mitarget_list{i_group} == 0) = pi()/2;
			MIs_by_group.atan{i_group} = tmp;
		end
		
		FileName = CollectionName;
		Cur_fh_avg_reward_by_group = figure('Name', 'mutual information space plot', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
		legend_list = {};
		hold on
		
		for i_group = 1 : n_groups
			
			current_group_label = group_struct_list{i_group}.setLabel;
			if ~ismember(current_group_label, MI_space_set_list)
				continue;
			end
			
			if strcmp(group_struct_list{i_group}.Symbol, 'none')
				% skip sets no symbol, as scatter does not tolerate
				continue
			end
			current_group_name = group_struct_list{i_group}.setName;
			legend_list{end+1} = current_group_name;
			
			ScatterSymbolSize = 25;
			ScatterLineWidth = 0.75;
			current_scatter_color = group_struct_list{i_group}.color;
			%current_scatter_color = [0.5 0.5 0.5];
			x_list = MIs_by_group.atan{i_group};
			y_list = MIs_by_group.(MI_coordination_strength_method){i_group};
			switch MI_coordination_strength_method
				case 'max'
					y_list = MIs_by_group.max{i_group};
				case 'vectorlength'
					y_list = MIs_by_group.vectorlength{i_group};
					error(['Unhandled MI_coordination_strength_method: ', MI_coordination_strength_method]);
			end
			
			
			orig_x_list = x_list;
			if (MI_jitter_x_on_collision ~= 0)
				% to display all individial values as scatter plots randomize the
				% positions for each group
				scatter_width = MI_jitter_x_on_collision;
				scatter_offset_list = (scatter_width * rand(size(x_list))) - (scatter_width * 0.5);
				if (length(x_list) > 1)
					x_list = x_list + scatter_offset_list;
					negative_x_idx = find(x_list < 0);
					x_list(negative_x_idx) = 0;
				end
			end
			
			orig_y_list = y_list;
			if (MI_normalize_coordination_strength_50_50) && ~strcmp(MI_coordination_strength_method, 'max')
				for i_x = 1 : length(orig_x_list)
					cur_orig_x = orig_x_list(i_x);
					%cur_y_adjust_factor = sqrt(tan(min([cur_orig_x, (0.5 * pi - cur_orig_x)])) + 1);
					cur_y_adjust_factor = sqrt(tan(min([cur_orig_x, (0.5 * pi - cur_orig_x)]))^2 + 1);
					y_list(i_x) = orig_y_list(i_x) / cur_y_adjust_factor;
				end
			end
			
			if (MI_jitter_y_on_collision ~= 0)
				% to display all individial values as scatter plots randomize the
				% positions for each group
				scatter_height = MI_jitter_y_on_collision;
				scatter_offset_list = (scatter_height * rand(size(y_list))) - (scatter_height * 0.5);
				if (length(y_list) > 1)
					y_list = y_list + scatter_offset_list;
					negative_y_idx = find(y_list < 0);
					y_list(negative_y_idx) = 0;
				end
			end
			
			if group_struct_list{i_group}.FilledSymbols
				scatter(x_list, y_list, ScatterSymbolSize, current_scatter_color, group_struct_list{i_group}.Symbol, 'filled', 'LineWidth', ScatterLineWidth);
			else
				scatter(x_list, y_list, ScatterSymbolSize, current_scatter_color, group_struct_list{i_group}.Symbol, 'LineWidth', ScatterLineWidth);
			end
			
			% now re-color the non-significant positions
			if (MI_space_mark_non_significant_sessions) && ~isempty( MIs_by_group.bothMIsNotSignif_idx{i_group})
				tmp_current_scatter_color = [1 0 0];
				%tmp_current_scatter_color = current_scatter_color;
				cur_bothMIsNotSignif_idx = MIs_by_group.bothMIsNotSignif_idx{i_group};
				if group_struct_list{i_group}.FilledSymbols
					scatter(x_list(cur_bothMIsNotSignif_idx), y_list(cur_bothMIsNotSignif_idx), ScatterSymbolSize, tmp_current_scatter_color, group_struct_list{i_group}.Symbol, 'filled', 'LineWidth', ScatterLineWidth);
				else
					scatter(x_list(cur_bothMIsNotSignif_idx), y_list(cur_bothMIsNotSignif_idx), ScatterSymbolSize, tmp_current_scatter_color, group_struct_list{i_group}.Symbol, 'LineWidth', ScatterLineWidth);
				end
				legend_list{end+1} = [current_group_name, ' (no strategy)'];
			end
			
			%% test for maximum equivalence to other operation
			%tmp_y_list = max([MIs_by_group_miside_list{i_group}, MIs_by_group_mitarget_list{i_group}], [], 2);
			%scatter(x_list, tmp_y_list, ScatterSymbolSize, [0 1 0], group_struct_list{i_group}.Symbol, 'LineWidth', ScatterLineWidth);
			
			
			
			
			if (mark_flaffus_curius)
				if strcmp(group_struct_list{i_group}.setName, 'Macaques early') || strcmp(group_struct_list{i_group}.setName, 'Macaques late')
					for i_session = 1 : length(group_struct_list{i_group}.filenames)
						if ~isempty(strfind(group_struct_list{i_group}.filenames{i_session}, 'A_Flaffus.B_Curius'))
							dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
							text(x_list(i_session)+dx, y_list(i_session)+dy, {num2str(i_session)},'Color', current_scatter_color, 'Fontsize', 8);
						end
					end
				end
			end
			
			if (MI_mark_all)
				for i_session = 1 : length(group_struct_list{i_group}.filenames)
					dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
					if (XX_marker_ID_use_captions)
						cur_ID_string = group_struct_list{i_group}.Captions{i_session};
					else
						cur_ID_string = num2str(i_session);
					end
					text(x_list(i_session)+dx, y_list(i_session)+dy, {cur_ID_string},'Color', current_scatter_color, 'Fontsize', 8);
				end
			end
			
			
		end
		if ~isempty(MI_threshold)
			plot([-0.05, pi()/2+0.1], [MI_threshold, MI_threshold], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
		end
		
		hold off
		axis([-0.05, pi()/2+0.1, -0.05, 1.4]);
		ylabel('Coordination strength (MI magnitude) [a.u.]', 'Interpreter', 'none');
		if (MI_normalize_coordination_strength_50_50)
			axis([-0.05, pi()/2+0.1, -0.05, 1.05]);
			ylabel('Normalized coordination strength', 'Interpreter', 'none');
		end
		xlabel('Coordination type (angle between MI`s) [degree]', 'Interpreter', 'none');
		set( gca, 'xTick', [0, pi()/4, pi()/2], 'xTickLabel', {'Side-based (0)', 'Trial-by-trial (45)', 'Target-based (90)'});
		
		%     if (PlotLegend)
		%         legend(legend_list, 'Interpreter', 'None');
		%     end
		CurrentTitleSetDescriptorString = TitleSetDescriptorString;
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.', OutPutType]);
		write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.', 'pdf']);
		write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
		if (save_fig)
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.', 'fig']);
			write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
		end
		
		legend(legend_list, 'Interpreter', 'None', 'Location', 'northwest');
		legend('boxoff');
		
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.legend.', OutPutType]);
		write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.legend.', 'pdf']);
		write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
		if (save_fig)
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.legend.', 'fig']);
			write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
		end
	end
	
	if (plot_AR_scatter_by_training_state)
		% for early and late macaques plot AR_late versus AR_early
		
		early_AVG_rewardAB = [];
		late_AVG_rewardAB = [];
		
		for i_group = 1 : n_groups
			current_group_label = group_struct_list{i_group}.setLabel;
			if ~ismember(current_group_label, {'Macaques_early', 'Macaques_late'})
				% nothing to do here
				continue
			end
			
			mac_group_idx = i_group;
			
			% collect the data lines for the current group
			current_group_data = metrics_by_group_list{i_group};
			% now collect the actual data of interest
			% averaged reward
			AVG_rewardA = current_group_data(:, coordination_metrics_table.cn.playerReward_A);
			AVG_rewardB = current_group_data(:, coordination_metrics_table.cn.playerReward_B);
			AVG_rewardAB = current_group_data(:, coordination_metrics_table.cn.averReward);
			nCoordinations = current_group_data(:, coordination_metrics_table.cn.nCoordinated);
			nNoncoordinations = current_group_data(:, coordination_metrics_table.cn.nNoncoordinated);
			
			if strcmp(current_group_label, 'Macaques_early')
				early_AVG_rewardAB = AVG_rewardAB;
				%early_cont_table_struct  = data_struct_list{i_group};
				early_nCoordinations = nCoordinations;
				early_nNoncoordinations = nNoncoordinations;
			end
			if strcmp(current_group_label, 'Macaques_late')
				late_AVG_rewardAB = AVG_rewardAB;
				%late_cont_table_struct  = data_struct_list{i_group};
				late_nCoordinations = nCoordinations;
				late_nNoncoordinations = nNoncoordinations;
			end
		end
		
		%TODO test for each pair whether the ratio of coordination to
		%non-coordination trials increased between early and late
		%TODO move the count of the trials into the ALLSESSIONS METRICS
		%calculation
		p_coordination_change_early_late_list = zeros([1 size(late_nCoordinations, 1)]);
		for i_session = 1 : size(late_nCoordinations, 1)
			cur_cont_table = [early_nCoordinations(i_session), early_nCoordinations(i_session); early_nNoncoordinations(i_session), late_nNoncoordinations(i_session)];
			[h, p_coordination_change_early_late_list(i_session), stats] = fishertest(cur_cont_table, 'Alpha', fisher_alpha, 'Tail', 'both');
		end
		
		% create the plot
		FileName = CollectionName;
		Cur_fh_cAvgRewardScatter_for_naive_macaques = figure('Name', 'AverageReward early/ate scatter-plot', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
		legend_list = {};
		hold on
		
		ScatterSymbolSize = 25;
		ScatterLineWidth = 0.75;
		ScatterMaker = 'o';
		current_scatter_color = group_struct_list{i_group}.color;
		current_scatter_color = [170 0 0] / 255;
		x_list = early_AVG_rewardAB;
		y_list = late_AVG_rewardAB;
		
		
		plot([0.9 3.6], [0.9 3.6], 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
		scatter(x_list, y_list, ScatterSymbolSize, current_scatter_color, ScatterMaker, 'LineWidth', ScatterLineWidth);
		
		% plot significant data points as filled symbols
		significant_data_idx = find(p_coordination_change_early_late_list <= fisher_alpha);
		scatter(x_list(significant_data_idx), y_list(significant_data_idx), ScatterSymbolSize, current_scatter_color, 'filled', ScatterMaker, 'LineWidth', ScatterLineWidth);
		
		axis equal
		xlabel('Average reward early session', 'Interpreter', 'none');
		ylabel('Average reward late session', 'Interpreter', 'none');
		%set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
		set(gca, 'Ylim', [0.9 3.6]);
		set(gca, 'XLim', [0.9 3.6]);
		
		if (AR_SCATTER_mark_all)
			for i_session = 1 : length(group_struct_list{mac_group_idx}.filenames)
				dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
				if (XX_marker_ID_use_captions)
					cur_ID_string = group_struct_list{mac_group_idx}.Captions{i_session};
				else
					cur_ID_string = num2str(i_session);
				end
				text(x_list(i_session)+dx, y_list(i_session)+dy, {cur_ID_string},'Color', current_scatter_color, 'Fontsize', 8);
			end
		end
		[p, h, signrank_stats] = signrank(early_AVG_rewardAB, late_AVG_rewardAB, 'alpha', wilcoxon_signed_rank_alpha, 'method', 'exact', 'tail', 'both');
		% (Mdn = 0.85) than in male faces (Mdn = 0.65), Z = 4.21, p < .001, r = .76.
		% A measure of effect size, r, can be calculated by dividing Z by the square root of N(r = Z / ?N).
		if isfield(signrank_stats, 'zval')
			title_text = ['N: ',num2str(length(late_AVG_rewardAB)) , '; Early (Mdn: ', num2str(median(early_AVG_rewardAB)), '), Late (Mdn: ', num2str(median(late_AVG_rewardAB)),...
				'), Z: ', num2str(signrank_stats.zval), ', p < ', num2str(p), ', r: ', num2str(signrank_stats.zval/sqrt(length(late_AVG_rewardAB)))];
		else
			title_text = ['N: ',num2str(length(late_AVG_rewardAB)) , '; Early (Mdn: ', num2str(median(early_AVG_rewardAB)), '), Late (Mdn: ', num2str(median(late_AVG_rewardAB)),...
				'), SignedRank: ', num2str(signrank_stats.signedrank), ', p < ', num2str(p)];			
		end
		if (AR_scatter_show_FET)
			title(title_text, 'FontSize', 6);
		end
		
		hold off
		% save out the results
		current_group_label = 'naive_macaques';
		CurrentTitleSetDescriptorString = [TitleSetDescriptorString, '.', current_group_label];
		if ~strcmp(OutPutType, 'pdf')
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardScatter.', OutPutType]);
			write_out_figure(Cur_fh_cAvgRewardScatter_for_naive_macaques, outfile_fqn);
		end
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardScatter.', 'pdf']);
		write_out_figure(Cur_fh_cAvgRewardScatter_for_naive_macaques, outfile_fqn);
		if (save_fig)
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardScatter.', 'fig']);
			write_out_figure(Cur_fh_cAvgRewardScatter_for_naive_macaques, outfile_fqn);
		end
	end
	
	
	
	if (plot_blocked_confederate_data)
		for i_group = 1 : n_groups
			current_group_label = group_struct_list{i_group}.setLabel;
			cur_plot_coordination_metrics_for_each_group_graph_type = plot_coordination_metrics_for_each_group_graph_type;
			
			% here we only want to ook at the blocked experiments
			if ~ismember(current_group_label, {'ConfederateSMCuriusBlocked', 'ConfederateSMFlaffusBlocked'})
				continue
			end
			
			
			%if ismember(current_group_label, {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late', 'ConfederateTrainedMacaques'})
			if ismember(current_group_label, {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late', 'HumansOpaque', ...
					'Humans50_55__80_20', 'Humans50_50', 'GoodHumans', 'BadHumans', 'HumansTransparent'})
				cur_plot_coordination_metrics_for_each_group_graph_type = 'bar';
				x_label_string = 'Pair ID';
			else
				disp('Doh...');
				x_label_string = 'Session ID';
			end
			
			
			% collect the data lines for the current group
			current_group_data = metrics_by_group_list{i_group};
			% now collect the actual data of interest
			
			error('Not implemented yet');
			
			
			% Share of Own Choices
			SOC_targetA = current_group_data(:, coordination_metrics_table.cn.shareOwnChoices_A);
			SOC_targetB = current_group_data(:, coordination_metrics_table.cn.shareOwnChoices_B);
			SOC_sideA = current_group_data(:, coordination_metrics_table.cn.shareLeftChoices_A);
			SOC_sideB = current_group_data(:, coordination_metrics_table.cn.shareLeftChoices_B);
			% Mutual Informatin
			MI_side = current_group_data(:, coordination_metrics_table.cn.miSide);
			MI_target = current_group_data(:, coordination_metrics_table.cn.miTarget);
			% averaged reward
			AVG_rewardA = current_group_data(:, coordination_metrics_table.cn.playerReward_A);
			AVG_rewardB = current_group_data(:, coordination_metrics_table.cn.playerReward_B);
			AVG_rewardAB = current_group_data(:, coordination_metrics_table.cn.averReward);
			% non-random reward component
			Non_random_reward = current_group_data(:, coordination_metrics_table.cn.dltReward);
			Non_random_reward_significance = current_group_data(:, coordination_metrics_table.cn.dltSignif);
			Non_random_reward_CI_lower = current_group_data(:, coordination_metrics_table.cn.dltConfInterval_Lower);
			Non_random_reward_CI_upper = current_group_data(:, coordination_metrics_table.cn.dltConfInterval_Upper);
			Non_random_reward_CI_hw = (Non_random_reward_CI_upper - Non_random_reward);
			
			% create the plot
			FileName = CollectionName;
			Cur_fh_coordination_metrics_for_each_group = figure('Name', 'Coordination Metrics plot', 'visible', figure_visibility_string);
			fnFormatDefaultAxes(DefaultAxesType);
			[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
			set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
			legend_list = {};
			%hold on
			
			% SOC target
			current_axis_h = subplot(2, 3, 1);
			x_vec_arr = [(1:1:length(SOC_sideA)); (1:1:length(SOC_sideB))]';
			y_vec_arr = [SOC_targetA, SOC_targetB];
			instance_list = {'SOC_targetA', 'SOC_targetB'};
			color_list = {[1,0,0], [0,0,1]};
			symbol_list = {'o', 's'};
			plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0.5 0.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('Share of own choices', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0 1.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			
			% SOC side
			current_axis_h = subplot(2, 3, 2);
			x_vec_arr = [(1:1:length(SOC_sideA)); (1:1:length(SOC_sideB))]';
			y_vec_arr = [SOC_sideA, SOC_sideB];
			instance_list = {'SOC_sideA', 'SOC_sideB'};
			color_list = {[1,0,0], [0,0,1]};
			symbol_list = {'o', 's'};
			plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0.5 0.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('Share of obj. left choices', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0 1.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			
			
			% AVG reward
			current_axis_h = subplot(2, 3, 3);
			x_vec_arr = [(1:1:length(AVG_rewardA));(1:1:length(AVG_rewardAB)); (1:1:length(AVG_rewardB)); ]';
			y_vec_arr = [AVG_rewardA, AVG_rewardAB, AVG_rewardB];
			instance_list = {'AVG_rewardA', 'AVG_rewardAB', 'AVG_rewardB'};
			color_list = {[1,0,0], [0.5,0,0.5], [0,0,1]};
			symbol_list = {'o', 'none', 's'};
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('Average reward', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0.9 4.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			
			% MI target
			current_axis_h = subplot(2, 3, 4);
			x_vec_arr = [(1:1:length(MI_target))]';
			y_vec_arr = [MI_target];
			instance_list = {'MI_target'};
			color_list = {[0.5,0,0.5]};
			symbol_list = {'d'};
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('MI target', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0 1.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			
			% MI side
			current_axis_h = subplot(2, 3, 5);
			x_vec_arr = [(1:1:length(MI_side))]';
			y_vec_arr = [MI_side];
			instance_list = {'MI_side'};
			color_list = {[0.5,0,0.5]};
			symbol_list = {'d'};
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('MI side', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0 1.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			
			% non-random reward
			current_axis_h = subplot(2, 3, 6);
			x_vec_arr = [(1:1:length(Non_random_reward))]';
			y_vec_arr = [Non_random_reward];
			instance_list = {'Non_random_reward'};
			color_list = {[0.5,0,0.5]};
			symbol_list = {'d'};
			plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0 0], 'Color', [0 0 0], 'Marker', 'none');
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('Non-random reward', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [-0.2 1.2]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			% add the CI
			hold on
			errorbar(x_vec_arr, y_vec_arr, Non_random_reward_CI_hw, 'LineStyle', 'none', 'Color', [0,0,0], 'LineWidth', 1.0);
			hold off
			
			
			% save out the results
			current_group_name = group_struct_list{i_group}.setName;
			CurrentTitleSetDescriptorString = [TitleSetDescriptorString, '.', current_group_label, '.', cur_plot_coordination_metrics_for_each_group_graph_type];
			if ~strcmp(OutPutType, 'pdf')
				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', OutPutType]);
				write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			end
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', 'pdf']);
			write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			if (save_fig)
				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', 'fig']);
				write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			end
			
			%         legend(legend_list, 'Interpreter', 'None');
			%         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', OutPutType]);
			%         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			%         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', 'pdf']);
			%         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			%		  if (save_fig)
			%         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', 'fig']);
			%         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			%		  end
		end
	end
	%
	if (plot_coordination_metrics_for_each_group)
		for i_group = 1 : n_groups
			current_group_label = group_struct_list{i_group}.setLabel;
			cur_plot_coordination_metrics_for_each_group_graph_type = plot_coordination_metrics_for_each_group_graph_type;
			
			% here we only want to ook at the blocked experiments
			if ismember(current_group_label, {'ConfederateSMCuriusBlocked', 'ConfederateSMFlaffusBlocked'})
				continue
			end
			
			%if ismember(current_group_label, {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late', 'ConfederateTrainedMacaques'})
			if ismember(current_group_label, {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late', ...
					'HumansTransparent', 'HumansOpaque', 'Humans50_50', 'Humans50_55__80_20', 'GoodHumans', 'BadHumans', })
				cur_plot_coordination_metrics_for_each_group_graph_type = 'bar';
				cur_plot_coordination_metrics_for_each_group_graph_type_override = [];
				x_label_string = 'Pair ID';
			else
				disp('Doh...');
				cur_plot_coordination_metrics_for_each_group_graph_type_override = 'list_order';
				x_label_string = 'Session ID';
			end
			
			
			% collect the data lines for the current group
			current_group_data = metrics_by_group_list{i_group};
			% now collect the actual data of interest
			% Share of Own Choices
			SOC_targetA = current_group_data(:, coordination_metrics_table.cn.shareOwnChoices_A);
			SOC_targetB = current_group_data(:, coordination_metrics_table.cn.shareOwnChoices_B);
			SOC_sideA = current_group_data(:, coordination_metrics_table.cn.shareLeftChoices_A);
			SOC_sideB = current_group_data(:, coordination_metrics_table.cn.shareLeftChoices_B);
			% Mutual Informatin
			MI_side = current_group_data(:, coordination_metrics_table.cn.miSide);
			MI_target = current_group_data(:, coordination_metrics_table.cn.miTarget);
			% averafed reward
			AVG_rewardA = current_group_data(:, coordination_metrics_table.cn.playerReward_A);
			AVG_rewardB = current_group_data(:, coordination_metrics_table.cn.playerReward_B);
			AVG_rewardAB = current_group_data(:, coordination_metrics_table.cn.averReward);
			% non-random reward component
			Non_random_reward = current_group_data(:, coordination_metrics_table.cn.dltReward);
			Non_random_reward_significance = current_group_data(:, coordination_metrics_table.cn.dltSignif);
			Non_random_reward_CI_lower = current_group_data(:, coordination_metrics_table.cn.dltConfInterval_Upper);
			Non_random_reward_CI_upper = current_group_data(:, coordination_metrics_table.cn.dltConfInterval_Lower);
			Non_random_reward_CI_hw = (Non_random_reward_CI_upper - Non_random_reward);
			
			
			% allow sorting the plots by
			switch coordination_metrics_sort_by_string
				case {'', 'none', 'None'}
					cur_sort_idx = (1:1:size(current_group_data, 1));
				case {'AVG_rewardAB'}
					[~, cur_sort_idx] = sort(AVG_rewardAB, 'ascend');
				otherwise
					error(['coordination_metrics_sort_by_string ', coordination_metrics_sort_by_string, ' not supported, add or correct spelling?']);
			end
			
			if strcmp(cur_plot_coordination_metrics_for_each_group_graph_type_override, 'list_order')
				disp('Overriding sort type request, line plots should reflect session list order');
				cur_sort_idx = (1:1:size(current_group_data, 1));
			end
			
			if isequal(current_group_label, 'Macaques_late')
				Macaque_late_early_sort_idx = cur_sort_idx;
			end
			if isequal(current_group_label, 'Macaques_early')
				if ~isempty(Macaque_late_early_sort_idx)
					cur_sort_idx = Macaque_late_early_sort_idx;
				else
					error('Macaque_late_early_sort_idx not defined yet?');
				end
			end
			
			
			% create the plot
			FileName = CollectionName;
			Cur_fh_coordination_metrics_for_each_group = figure('Name', 'Coordination Metrics plot', 'visible', figure_visibility_string);
			fnFormatDefaultAxes(DefaultAxesType);
			[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
			set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
			legend_list = {};
			%hold on
			
			% SOC target
			current_axis_h = subplot(2, 3, 1);
			box(gca(), 'off');
			x_vec_arr = [(1:1:length(SOC_sideA)); (1:1:length(SOC_sideB))]';
			y_vec_arr = [SOC_targetA(cur_sort_idx), SOC_targetB(cur_sort_idx)];
			instance_list = {'SOC_targetA', 'SOC_targetB'};
			color_list = {[1,0,0], [0,0,1]};
			symbol_list = {'o', 's'};
			plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0.5 0.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('Share of own choices', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions(cur_sort_idx), 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0 1.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			box(gca(), 'off');
			
			
			% SOC side
			current_axis_h = subplot(2, 3, 2);
			box(gca(), 'off');
			x_vec_arr = [(1:1:length(SOC_sideA)); (1:1:length(SOC_sideB))]';
			y_vec_arr = [SOC_sideA(cur_sort_idx), SOC_sideB(cur_sort_idx)];
			instance_list = {'SOC_sideA', 'SOC_sideB'};
			color_list = {[1,0,0], [0,0,1]};
			symbol_list = {'o', 's'};
			plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0.5 0.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('Share of obj. left choices', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions(cur_sort_idx), 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0 1.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			box(gca(), 'off');
			
			
			% AVG reward
			current_axis_h = subplot(2, 3, 3);
			box(gca(), 'off');
			x_vec_arr = [(1:1:length(AVG_rewardA));(1:1:length(AVG_rewardAB)); (1:1:length(AVG_rewardB)); ]';
			y_vec_arr = [AVG_rewardA(cur_sort_idx), AVG_rewardAB(cur_sort_idx), AVG_rewardB(cur_sort_idx)];
			instance_list = {'AVG_rewardA', 'AVG_rewardAB', 'AVG_rewardB'};
			color_list = {[1,0,0], [0.5,0,0.5], [0,0,1]};
			symbol_list = {'o', 'none', 's'};
			hold on
			% the chance reward
			plot([(0.2) (size(x_vec_arr, 1)+0.9)], [2.5 2.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
			% maximum grand average reward
			plot([(0.2) (size(x_vec_arr, 1)+0.9)], [3.5 3.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('Average reward', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions(cur_sort_idx), 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0.9 4.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			hold off
			box(gca(), 'off');
			
			% MI target
			current_axis_h = subplot(2, 3, 4);
			box(gca(), 'off');
			x_vec_arr = [(1:1:length(MI_target))]';
			y_vec_arr = [MI_target(cur_sort_idx)];
			instance_list = {'MI_target'};
			color_list = {[0.5,0,0.5]};
			symbol_list = {'d'};
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('MI target', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions(cur_sort_idx), 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0 1.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			box(gca(), 'off');
			
			% MI side
			current_axis_h = subplot(2, 3, 5);
			box(gca(), 'off');
			x_vec_arr = [(1:1:length(MI_side))]';
			y_vec_arr = [MI_side(cur_sort_idx)];
			instance_list = {'MI_side'};
			color_list = {[0.5,0,0.5]};
			symbol_list = {'d'};
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('MI side', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions(cur_sort_idx), 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [0 1.1]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			box(gca(), 'off');
			
			% non-random reward
			current_axis_h = subplot(2, 3, 6);
			box(gca(), 'off');
			x_vec_arr = [(1:1:length(Non_random_reward))]';
			y_vec_arr = [Non_random_reward(cur_sort_idx)];
			instance_list = {'Non_random_reward'};
			color_list = {[0.5,0,0.5]};
			symbol_list = {'d'};
			plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0 0], 'Color', [0 0 0], 'Marker', 'none');
			[current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list, bar_edge_color);
			% label the axes
			ylabel('Dynamic coordination reward', 'Interpreter', 'none');
			xlabel(x_label_string, 'Interpreter', 'none');
			set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions(cur_sort_idx), 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
			set(gca, 'Ylim', [-0.2 1.2]);
			set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
			% add the CI
			hold on
			errorbar(x_vec_arr, y_vec_arr, Non_random_reward_CI_hw, 'LineStyle', 'none', 'Color', [0,0,0], 'LineWidth', 1.0);
			hold off
			box(gca(), 'off');
			
			
			% save out the results
			current_group_name = group_struct_list{i_group}.setName;
			CurrentTitleSetDescriptorString = [TitleSetDescriptorString, '.', current_group_label, '.', cur_plot_coordination_metrics_for_each_group_graph_type];
			if ~strcmp(OutPutType, 'pdf')
				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', OutPutType]);
				write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			end
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', 'pdf']);
			write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			if (save_fig)
				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', 'fig']);
				write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			end
			
			%         legend(legend_list, 'Interpreter', 'None');
			%         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', OutPutType]);
			%         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			%         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', 'pdf']);
			%         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			%		  if (save_fig)
			%         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', 'fig']);
			%         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
			%		  end
			
		end
	end
	% close all figues?
	if (close_figures_at_end)
		close all;
	end
end

% rest the output path for across metric file plots
OutputPath = fullfile(InputPath, 'AggregatePlots');

% stuff comparing different session metrics files/sets
if (plot_AR_scatter_by_session_state_early_late)
	% for early and late macaques plot AR_late versus AR_early
	
	cur_session_metrics_datafile_IDtag = 'first100';
	early_coordination_metrics_table = session_metrics.(cur_session_metrics_datafile_IDtag).coordination_metrics_table;
	early_metrics_by_group_list = session_metrics.(cur_session_metrics_datafile_IDtag).metrics_by_group_list;
	cur_session_metrics_datafile_IDtag = 'last200';
	late_coordination_metrics_table = session_metrics.(cur_session_metrics_datafile_IDtag).coordination_metrics_table;
	late_metrics_by_group_list = session_metrics.(cur_session_metrics_datafile_IDtag).metrics_by_group_list;
	
	
	for i_group = 1 : n_groups
		if sum(ismember({'last200', 'first100'}, session_metrics_datafile_IDtag_list)) < 2
			disp(['plot_AR_scatter_by_session_state_early_late: could not find both last200 and first100 session_metrics_data']);
			continue
		end
		
		
		metrics_by_group_list = early_metrics_by_group_list;
		current_group_label = group_struct_list{i_group}.setLabel;
		% collect the data lines for the current group
		current_group_data = metrics_by_group_list{i_group};
		disp(['Group: ', current_group_label]);
		
		% now collect the actual data of interest
		% averaged reward
		
		early_AVG_rewardAB = early_metrics_by_group_list{i_group}(:, early_coordination_metrics_table.cn.averReward);
		late_AVG_rewardAB = late_metrics_by_group_list{i_group}(:, late_coordination_metrics_table.cn.averReward);
		
		early_nCoordinations = early_metrics_by_group_list{i_group}(:, early_coordination_metrics_table.cn.nCoordinated);
		early_nNoncoordinations = early_metrics_by_group_list{i_group}(:, early_coordination_metrics_table.cn.nNoncoordinated);
		late_nCoordinations = late_metrics_by_group_list{i_group}(:, late_coordination_metrics_table.cn.nCoordinated);
		late_nNoncoordinations = late_metrics_by_group_list{i_group}(:, late_coordination_metrics_table.cn.nNoncoordinated);
		
		p_coordination_change_early_late_list = zeros([1 size(late_nCoordinations, 1)]);
		for i_session = 1 : size(late_nCoordinations, 1)
			cur_cont_table = [early_nCoordinations(i_session), early_nCoordinations(i_session); early_nNoncoordinations(i_session), late_nNoncoordinations(i_session)];
			[h, p_coordination_change_early_late_list(i_session), stats] = fishertest(cur_cont_table, 'Alpha', fisher_alpha, 'Tail', 'both');
		end
		
		
		% create the plot
		FileName = CollectionName;
		Cur_fh_cAvgRewardScatter_for_naive_macaques = figure('Name', 'AverageReward early/late scatter-plot', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
		legend_list = {};
		hold on
		
		ScatterSymbolSize = 25;
		ScatterLineWidth = 0.75;
		ScatterMaker = 'o';
		current_scatter_color = group_struct_list{i_group}.color;
		%current_scatter_color = [0.5 0.5 0.5];
		x_list = early_AVG_rewardAB;
		y_list = late_AVG_rewardAB;
		
		plot([0.9 3.6], [0.9 3.6], 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
		scatter(x_list, y_list, ScatterSymbolSize, current_scatter_color, ScatterMaker, 'LineWidth', ScatterLineWidth);
		
		% plot significant data points as filled symbols
		significant_data_idx = find(p_coordination_change_early_late_list <= fisher_alpha);
		scatter(x_list(significant_data_idx), y_list(significant_data_idx), ScatterSymbolSize, current_scatter_color, 'filled', ScatterMaker, 'LineWidth', ScatterLineWidth);
		
		axis equal
		xlabel('Average reward first 100 trials', 'Interpreter', 'none');
		ylabel('Average reward late 200 trials', 'Interpreter', 'none');
		%set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
		set(gca, 'Ylim', [0.9 3.6]);
		set(gca, 'XLim', [0.9 3.6]);
		
		
		if (AR_SCATTER_mark_all)
			for i_session = 1 : length(group_struct_list{i_group}.filenames)
				dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
				if (XX_marker_ID_use_captions)
					cur_ID_string = group_struct_list{i_group}.Captions{i_session};
				else
					cur_ID_string = num2str(i_session);
				end
				text(x_list(i_session)+dx, y_list(i_session)+dy, {cur_ID_string},'Color', current_scatter_color, 'Fontsize', 8);
			end
		end
		
		[p, h, signrank_stats] = signrank(early_AVG_rewardAB, late_AVG_rewardAB, 'alpha', wilcoxon_signed_rank_alpha, 'method', 'exact', 'tail', 'both');
		% (Mdn = 0.85) than in male faces (Mdn = 0.65), Z = 4.21, p < .001, r = .76.
		% A measure of effect size, r, can be calculated by dividing Z by the square root of N(r = Z / ?N).
% 		title_text = ['N: ',num2str(length(late_AVG_rewardAB)) , '; Early (Mdn: ', num2str(median(early_AVG_rewardAB)), '), Late (Mdn: ', num2str(median(late_AVG_rewardAB)),...
% 			'), Z: ', num2str(signrank_stats.zval), ', p < ', num2str(p), ', r: ', num2str(signrank_stats.zval/sqrt(length(late_AVG_rewardAB)))];
		
		if isfield(signrank_stats, 'zval')
			title_text = ['N: ',num2str(length(late_AVG_rewardAB)) , '; Early (Mdn: ', num2str(median(early_AVG_rewardAB)), '), Late (Mdn: ', num2str(median(late_AVG_rewardAB)),...
				'), Z: ', num2str(signrank_stats.zval), ', p < ', num2str(p), ', r: ', num2str(signrank_stats.zval/sqrt(length(late_AVG_rewardAB)))];
		else
			title_text = ['N: ',num2str(length(late_AVG_rewardAB)) , '; Early (Mdn: ', num2str(median(early_AVG_rewardAB)), '), Late (Mdn: ', num2str(median(late_AVG_rewardAB)),...
				'), SignedRank: ', num2str(signrank_stats.signedrank), ', p < ', num2str(p)];
		end

		
		title(title_text, 'FontSize', 6);
		
		hold off
		% save out the results
		CurrentTitleSetDescriptorString = [TitleSetDescriptorString, '.', current_group_label];
		if ~strcmp(OutPutType, 'pdf')
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardScatter.', OutPutType]);
			write_out_figure(Cur_fh_cAvgRewardScatter_for_naive_macaques, outfile_fqn);
		end
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardScatter.', 'pdf']);
		write_out_figure(Cur_fh_cAvgRewardScatter_for_naive_macaques, outfile_fqn);
		if (save_fig)
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardScatter.', 'fig']);
			write_out_figure(Cur_fh_cAvgRewardScatter_for_naive_macaques, outfile_fqn);
		end
	end
end

if (plot_RT_by_switch_type)
	
	
	for i_group = 1 : length(bygroup)
		group_concatenated_pertrial_data = bygroup{i_group};
		current_group_label = group_struct_list{i_group}.setLabel;
		SideA_pattern_histogram_pertrial_struct = [];
		SideB_pattern_histogram_pertrial_struct = [];
		SideA_pattern_histogram_struct = [];
		SideB_pattern_histogram_struct = [];
		
		% extract and aggregate the data per defined switch
		cur_trial_idx = group_concatenated_pertrial_data.selected_trial_idx;
		A_RT_data = group_concatenated_pertrial_data.(['A_', RT_type]);
		B_RT_data = group_concatenated_pertrial_data.(['B_', RT_type]);
		
		% display the min and max halfway times	
		selected_trials_ldx = logical(group_concatenated_pertrial_data.TrialIsRewarded);
		IFR_A_RT_data = group_concatenated_pertrial_data.(['A_', 'InitialTargetReleaseRT'])(selected_trials_ldx);
		IFR_B_RT_data = group_concatenated_pertrial_data.(['B_', 'InitialTargetReleaseRT'])(selected_trials_ldx);
		tmp_A_RT_data = A_RT_data(selected_trials_ldx);
		tmp_B_RT_data = B_RT_data(selected_trials_ldx);
		disp([current_group_label, ' ', 'InitialTargetReleaseRT', ' A(min:max): ', num2str(min(IFR_A_RT_data(find(IFR_A_RT_data > 0 & IFR_A_RT_data < 1500)))), ' : ', num2str(max(IFR_A_RT_data(find(IFR_A_RT_data > 0 & IFR_A_RT_data < 1500))))]);
		disp([current_group_label, ' ', 'InitialTargetReleaseRT', ' B(min:max): ', num2str(min(IFR_B_RT_data(find(IFR_B_RT_data > 0 & IFR_B_RT_data < 1500)))), ' : ', num2str(max(IFR_B_RT_data(find(IFR_B_RT_data > 0 & IFR_B_RT_data < 1500))))]);
		disp([current_group_label, ' ', RT_type, ' A(min:max): ', num2str(min(tmp_A_RT_data(find(tmp_A_RT_data > 0 & tmp_A_RT_data < 1500)))), ' : ', num2str(max(tmp_A_RT_data(find(tmp_A_RT_data > 0 & tmp_A_RT_data < 1500))))]);
		disp([current_group_label, ' ', RT_type, ' B(min:max): ', num2str(min(tmp_B_RT_data(find(tmp_B_RT_data > 0 & tmp_B_RT_data < 1500)))), ' : ', num2str(max(tmp_B_RT_data(find(tmp_B_RT_data > 0 & tmp_B_RT_data < 1500))))]);
				
		choice_combination_color_string = group_concatenated_pertrial_data.choice_combination_color_string;
		
		% summarize the average run lengths
		
		
		% loop over the individual sessions to avoid edge effects
		unique_sessionIDs = unique(group_concatenated_pertrial_data.sessionID);
		
		for i_session = 1 : length(unique_sessionIDs)
			cur_sessionID = unique_sessionIDs(i_session);
			current_SideA_pattern_histogram_pertrial_struct = [];
			current_SideB_pattern_histogram_pertrial_struct = [];
			
			current_sessionID_trial_idx = find(group_concatenated_pertrial_data.sessionID == cur_sessionID);
			current_trial_idx = intersect(cur_trial_idx, current_sessionID_trial_idx);
			[~, current_SideA_pattern_histogram_pertrial_struct] = fn_build_PSTH_by_switch_trial_struct(current_trial_idx, choice_combination_color_string', full_choice_combinaton_pattern_list, A_RT_data, pattern_alignment_offset, n_pre_bins, n_post_bins, strict_pattern_extension, pad_mismatch_with_nan);
			[~, current_SideB_pattern_histogram_pertrial_struct] = fn_build_PSTH_by_switch_trial_struct(current_trial_idx, choice_combination_color_string', full_choice_combinaton_pattern_list, B_RT_data, pattern_alignment_offset, n_pre_bins, n_post_bins, strict_pattern_extension, pad_mismatch_with_nan);
			
			SideA_pattern_histogram_pertrial_struct = fn_merge_pertrial_structs(SideA_pattern_histogram_pertrial_struct, current_SideA_pattern_histogram_pertrial_struct, full_choice_combinaton_pattern_list);
			SideB_pattern_histogram_pertrial_struct = fn_merge_pertrial_structs(SideB_pattern_histogram_pertrial_struct, current_SideB_pattern_histogram_pertrial_struct, full_choice_combinaton_pattern_list);
		end
		
		
		
		SideA_pattern_histogram_struct = fn_aggregate_event_data_by_switches(SideA_pattern_histogram_pertrial_struct);
		SideB_pattern_histogram_struct = fn_aggregate_event_data_by_switches(SideB_pattern_histogram_pertrial_struct);
		
		
		% find the trial indices for the selected switch trials
		% for each member in selected_choice_combinaton_pattern_list
		% extract a histogram form a given data list
		
		for i_aggregate_meta_type = 1 : length(aggregate_type_meta_list)
			current_aggregate_type = aggregate_type_meta_list{i_aggregate_meta_type};
			if ~isempty(SideA_pattern_histogram_struct) || ~isempty(SideB_pattern_histogram_struct)
				% now create a plot showing these transitions for both
				% agents
				Cur_fh_RTbyChoiceCombinationSwitches = figure('Name', ['RT histogram over choice combination switches: ', current_aggregate_type], 'visible', figure_visibility_string);
				fnFormatDefaultAxes(DefaultAxesType);
				[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
				set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
				
				RT_by_switch_struct_list = {SideA_pattern_histogram_struct, SideB_pattern_histogram_struct};
				RT_by_switch_title_prefix_list = {'A: ', 'B: '};
				RT_by_switch_switch_pre_bins_list = {n_pre_bins, n_pre_bins};
				RT_by_switch_switch_n_bins_list = {(n_pre_bins + 1 + n_post_bins), (n_pre_bins + 1 + n_post_bins)};
				%RT_by_switch_color_list = {orange, green};
				RT_by_switch_color_list = {SideAColor, SideBColor};
				aggregate_type_list = {current_aggregate_type, current_aggregate_type};
				
				[Cur_fh_RTbyChoiceCombinationSwitches, merged_classifier_char_string] = fn_plot_RT_histogram_by_switches(Cur_fh_RTbyChoiceCombinationSwitches, RT_by_switch_struct_list, selected_choice_combinaton_pattern_list, RT_by_switch_title_prefix_list, RT_by_switch_switch_pre_bins_list, RT_by_switch_switch_n_bins_list, RT_by_switch_color_list, aggregate_type_list);

				trial_outcome_list = zeros(size(merged_classifier_char_string));
				trial_outcome_list(merged_classifier_char_string == 'R') = 1;
				trial_outcome_list(merged_classifier_char_string == 'B') = 2;
				trial_outcome_list(merged_classifier_char_string == 'M') = 3;
				trial_outcome_list(merged_classifier_char_string == 'G') = 4;
				% 
				trial_outcome_colors = [SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor];
				trial_outcome_BGTransparency = [1.0];
				
				y_lim = get(gca(), 'YLim');				
				fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, {trial_outcome_list}, y_lim, {trial_outcome_colors}, {trial_outcome_BGTransparency});
				y_lim = get(gca(), 'YLim');


				
				
				
				CurrentTitleSetDescriptorString = [TitleSetDescriptorString, '.', current_group_label];
				if ~strcmp(OutPutType, 'pdf')
					outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySwitches.', RT_type, '.', current_aggregate_type, OutPutType]);
					write_out_figure(Cur_fh_RTbyChoiceCombinationSwitches, outfile_fqn);
				end
				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySwitches.', RT_type, '.', current_aggregate_type, '.pdf']);
				write_out_figure(Cur_fh_RTbyChoiceCombinationSwitches, outfile_fqn);
				if (save_fig)
					outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySwitches.', RT_type, '.', current_aggregate_type, '.fig']);
					write_out_figure(Cur_fh_RTbyChoiceCombinationSwitches, outfile_fqn);
				end
			end
			
			
		end
	end
end

% close all figues?
if (close_figures_at_end)
	close all;
end

% how long did it take?
timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);

return
end

function [ output_rect ] = fnFormatPaperSizelocal( type, gcf_h, fraction, do_center_in_paper )
%FNFORMATPAPERSIZE Set the paper size for a plot, also return a reasonably
%tight output_rect.
% 20070827sm: changed default output formatting to allow pretty paper output
% Example usage:
%     Cur_fh = figure('Name', 'Test');
%     fnFormatDefaultAxes('16to9slides');
%     [output_rect] = fnFormatPaperSize('16to9landscape', gcf);
%     set(gcf(), 'Units', 'centimeters', 'Position', output_rect);


if nargin < 3
	fraction = 1;	% fractional columns?
end
if nargin < 4
	do_center_in_paper = 0;	% center the rectangle in the page
end


nature_single_col_width_cm = 8.9;
nature_double_col_width_cm = 18.3;
nature_full_page_width_cm = 24.7;

A4_w_cm = 21.0;
A4_h_cm = 29.7;
% defaults
left_edge_cm = 1;
bottom_edge_cm = 2;

switch type
	
	case {'PrimateNeurobiology2018DPZ0.5', 'SfN2018.5'}
		left_edge_cm = 0.05;
		bottom_edge_cm = 0.05;
		dpz_column_width_cm = 38.6 * 0.5 * 0.8;   % the columns are 38.6271mm, but the imported pdf in illustrator are too large (0.395)
		rect_w = (dpz_column_width_cm - 2*left_edge_cm) * fraction;
		rect_h = ((dpz_column_width_cm * 610/987) - 2*bottom_edge_cm) * fraction; % 610/987 approximates the golden ratio
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_w_cm - rect_w) * 0.5;
			bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm*fraction rect_h+2*bottom_edge_cm*fraction], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
		
		
		
	case 'PrimateNeurobiology2018DPZ'
		left_edge_cm = 0.05;
		bottom_edge_cm = 0.05;
		dpz_column_width_cm = 38.6 * 0.8;   % the columns are 38.6271mm, but the imported pdf in illustrator are too large (0.395)
		rect_w = (dpz_column_width_cm - 2*left_edge_cm) * fraction;
		rect_h = ((dpz_column_width_cm * 610/987) - 2*bottom_edge_cm) * fraction; % 610/987 approximates the golden ratio
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_w_cm - rect_w) * 0.5;
			bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm*fraction rect_h+2*bottom_edge_cm*fraction], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
		
	case 'DPZ2017Evaluation'
		left_edge_cm = 0.05;
		bottom_edge_cm = 0.05;
		dpz_column_width_cm = 34.7 * 0.8;   % the columns are 347, 350, 347 mm, but the imported pdf in illustrator are too large (0.395)
		rect_w = (dpz_column_width_cm - 2*left_edge_cm) * fraction;
		rect_h = ((dpz_column_width_cm * 610/987) - 2*bottom_edge_cm) * fraction; % 610/987 approximates the golden ratio
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_w_cm - rect_w) * 0.5;
			bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm*fraction rect_h+2*bottom_edge_cm*fraction], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
		
		
	case '16to9portrait'
		left_edge_cm = 1;
		bottom_edge_cm = 1;
		rect_w = (9 - 2*left_edge_cm) * fraction;
		rect_h = (16 - 2*bottom_edge_cm) * fraction;
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_w_cm - rect_w) * 0.5;
			bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm rect_h+2*bottom_edge_cm], 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters');
		
	case '16to9landscape'
		left_edge_cm = 1;
		bottom_edge_cm = 1;
		rect_w = (16 - 2*left_edge_cm) * fraction;
		rect_h = (9 - 2*bottom_edge_cm) * fraction;
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_w_cm - rect_w) * 0.5;
			bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm rect_h+2*bottom_edge_cm], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
		
	case 'ms13_paper'
		rect_w = nature_single_col_width_cm * fraction;
		rect_h = nature_single_col_width_cm * fraction;
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_w_cm - rect_w) * 0.5;
			bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		%set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		% try to manage plots better
		set(gcf_h, 'PaperSize', [rect_w rect_h], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
		
	case 'ms13_paper_unitdata'
		rect_w = nature_single_col_width_cm * fraction;
		rect_h = nature_single_col_width_cm * fraction;
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_w_cm - rect_w) * 0.5;
			bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		% configure the format PaperPositon [left bottom width height]
		%set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		set(gcf_h, 'PaperSize', [rect_w rect_h], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
		
	case 'ms13_paper_unitdata_halfheight'
		rect_w = nature_single_col_width_cm * fraction;
		rect_h = nature_single_col_width_cm * fraction * 0.5;
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_w_cm - rect_w) * 0.5;
			bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		% configure the format PaperPositon [left bottom width height]
		%set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		set(gcf_h, 'PaperSize', [rect_w rect_h], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
		
		
	case 'fp_paper'
		rect_w = 4.5 * fraction;
		rect_h = 1.835 * fraction;
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_w_cm - rect_w) * 0.5;
			bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		% configure the format PaperPositon [left bottom width height]
		set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		
	case 'sfn_poster'
		rect_w = 27.7 * fraction;
		rect_h = 12.0 * fraction;
		% configure the format PaperPositon [left bottom width height]
		if (do_center_in_paper)
			left_edge_cm = (A4_h_cm - rect_w) * 0.5;	% landscape!
			bottom_edge_cm = (A4_w_cm - rect_h) * 0.5;	% landscape!
		end
		output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
		%output_rect = [1.0 2.0 27.7 12.0];	% full width
		% configure the format PaperPositon [left bottom width height]
		set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		
	case 'sfn_poster_0.5'
		output_rect = [1.0 2.0 (25.9/2) 8.0];	% half width
		output_rect = [1.0 2.0 11.0 10.0];	% height was (25.9/2)
		% configure the format PaperPositon [left bottom width height]
		%set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		
	case 'sfn_poster_0.5_2012'
		output_rect = [1.0 2.0 (25.9/2) 8.0];	% half width
		output_rect = [1.0 2.0 11.0 9.0];	% height was (25.9/2)
		% configure the format PaperPositon [left bottom width height]
		%set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		
	case 'europe'
		output_rect = [1.0 2.0 27.7 12.0];
		set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		
	case 'europe_portrait'
		output_rect = [1.0 2.0 20.0 27.7];
		set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		
	case 'default'
		% letter 8.5 x 11 ", or 215.9 mm ? 279.4 mm
		output_rect = [1.0 2.0 19.59 25.94];
		set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		
	case 'default_portrait'
		output_rect = [1.0 2.0 25.94 19.59];
		set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		
	otherwise
		output_rect = [1.0 2.0 25.9 12.0];
		set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
		
end

return
end




function [current_axis_h] = fn_plot_type_to_axis(current_axis_h, graph_type, x_vec_arr, y_vec_arr, color_list, marker_list, bar_edge_color)

% how many things to loop over
n_instances = size(y_vec_arr, 2);
n_groups = size(y_vec_arr, 1);

if strcmp(graph_type, 'bar')
	hold on
	bh = bar(y_vec_arr, 'grouped', 'EdgeColor', bar_edge_color);
	for i_instance = 1 : n_instances
		if ~isempty(color_list)
			bh(i_instance).FaceColor = color_list{i_instance};
		end
	end
	%set('XLim', [0.1, (n_groups+0.9)]);
	hold off
	return
end

hold on
for i_instance = 1 : n_instances
	cur_x_vec = x_vec_arr(:, i_instance);
	cur_y_vec = y_vec_arr(:, i_instance);
	if ~isempty(color_list)
		cur_color = color_list{i_instance};
	else
		cur_color = [0 0.4470 0.7410];% default
	end
	if ~isempty(marker_list)
		cur_marker = marker_list{i_instance};
	else
		cur_marker = 'none';% default
	end
	switch graph_type
		case 'bar'
			bar(cur_x_vec, cur_y_vec, 'EdgeColor', bar_edge_color);
		case 'line'
			plot(cur_x_vec, cur_y_vec, 'Color', cur_color, 'Marker', cur_marker);
		otherwise
			error(['Unknown graph_type: ', graph_type]);
	end
end
hold off

return
end

function [ metrics_by_group_list ] = fn_extract_metrics_by_group( group_struct_list, cur_coordination_metrics_table )
% this deals with extracting a properly sorted matrics table for each
% group, where each row corresponds to the matching index of the group
% member

% extract the subsets of rows for the sessions in each group
n_groups = length(group_struct_list);
metrics_by_group_list = cell(size(group_struct_list));
for i_group = 1 : n_groups
	current_group = group_struct_list{i_group};
	% find the row indices for the current group members:
	[current_session_in_group_ldx, LocB] = ismember(cur_coordination_metrics_table.key, current_group.filenames);
	% this is unfortunately unsorted, but we want to keep current_group.filenames order...
	current_session_in_group_idx = find(current_session_in_group_ldx);
	%order_idx = LocB(current_session_in_group_idx);
	% this will only work if each session ID is unique...
	[~, sort_key_2_filenames_order_idx] = sort(LocB(current_session_in_group_idx), 'ascend');
	%coordination_metrics_table.key(current_session_in_group_idx(I))'
	%current_group.filenames'
	metrics_by_group_list{i_group} = cur_coordination_metrics_table.data(current_session_in_group_idx(sort_key_2_filenames_order_idx), :);
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