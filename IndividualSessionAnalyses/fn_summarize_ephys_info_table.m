function [ ] = fn_summarize_ephys_info_table( all_session_info_table_FQSTEM, extension_string, ephys_subject_list )
%FN_SUMMARIZE_EPHYS_INFO_TABLE Summary of this function goes here
%   Detailed explanation goes here

% TODO:
% use simulations to set thresholds for predictability and prediction
% classification
%	report A/B merged
% split SoloXRewardAB in NHP pair-NHP-Confederate

if ~exist('all_session_info_table_FQSTEM', 'var') || isempty(all_session_info_table_FQSTEM)
	all_session_info_table_FQSTEM = fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', 'All_session_summary_table.V2');
end

if ~exist('extension_string', 'var') || isempty(extension_string)
	extension_string = '.xlsx';
	extension_string = '.table.mat';
end

if ~exist('ephys_subject_list', 'var') || isempty(ephys_subject_list)
	ephys_subject_list = {'Elmo', 'Curius'};
end
version_number = 4;
output_stem = ['Ephys_summary_table.V', num2str(version_number)];


prediction_measure_string = 'XgoY_SamePCT_AB'; % XgoY_X_depends_on_LastY_pval, XirtY_X_depends_on_LastY_pval, XgoY_SamePCT_AB
predictable_confederate_alpha_threshold_pval = 0.001;
predicting_confederate_alpha_threshold_pval = 1e-05;
predicting_confederate_sameness_threshold_pct = 66;
min_prediction_trials = 20;	% exclude sessions with less then this number of trials in the AgoB category...


% create one line per listed side, or aggregate if AB
side_list = {'A', 'B'};
%side_list = {'AB'};
merge_sides = 1; % report trial types side independent (but special case active and passive conditions...)

[input_dir, tmp_input_name, tmp_input_ext] = fileparts(all_session_info_table_FQSTEM);
input_stem = [tmp_input_name, tmp_input_ext];

table_fqn = fullfile(input_dir, [input_stem, extension_string]);




% load the data
switch extension_string
	case '.xlsx'
		data_sheetnames = sheetnames(table_fqn);
		data = readtable(table_fqn, 'Sheet', 'Sheet1', 'VariableNamesRow', 1, 'VariableDescriptionsRow', 2, "VariableNamingRule","preserve");
	case {'.mat', '.table.mat'}
		load(table_fqn, 'output_data_table');
		data = output_data_table;
	otherwise
		error([mfilename, ': unhandled extension string encountered: ', extension_string]);
end

% remove all TOTAL lines...
combination_ldx = ismember(data.record_type, {'COMBINATION'});

% remove all non-ephys lines
ehpys_ldx = ~ismember(data.EPhysRecorded, {'0'});

ephys_session_data = data(combination_ldx & ehpys_ldx, :);

% find all unique trislsubtypes:
[unique_trial_subtypes, ~, ephys_session_data_to_unique_trialsubtype_mapping] = unique(ephys_session_data.effective_trial_subtype);


% dual recording sessions are split into two virtual sessions one per
% recorded subject, with the subject name appended to the tank ID
NHP_A_ldx = ismember(ephys_session_data.species_A, {'NHP'});
NHP_B_ldx = ismember(ephys_session_data.species_B, {'NHP'});
% for recording sessions all humans were confederates
ConfHP_A_ldx = ismember(ephys_session_data.species_A, {'HP'}) & ~ismember(ephys_session_data.subject_A, {'None', 'NONE', 'none'});
ConfHP_B_ldx = ismember(ephys_session_data.species_B, {'HP'}) & ~ismember(ephys_session_data.subject_B, {'None', 'NONE', 'none'});

% the actual cue randomisation methods
% initially confederates used blocking even without the
% CueRandomizationMethod_A and direction cue
A_blocked_confederate_ldx = (ConfHP_A_ldx & ismember(ephys_session_data.CueRandomizationMethod_A, {'BLOCKED', 'NONE'}));
B_blocked_confederate_ldx = (ConfHP_B_ldx & ismember(ephys_session_data.CueRandomizationMethod_B, {'BLOCKED', 'NONE'}));
blocked_confederate_ldx = A_blocked_confederate_ldx | B_blocked_confederate_ldx;
% this is unambiguous, before 
shuffled_confederate_ldx = (ConfHP_A_ldx & ismember(ephys_session_data.CueRandomizationMethod_A, {'SHUFFLED'})) | (ConfHP_B_ldx & ismember(ephys_session_data.CueRandomizationMethod_B, {'SHUFFLED'}));

dyadic_ldx = (ismember(ephys_session_data.effective_trial_subtype, {'Dyadic'}));


% show the 
category_list = cell(size(ephys_session_data.AgoB_A_depends_on_LastB_pval));
category_list(:) = {'NONE'};
category_list(blocked_confederate_ldx) = {'BLOCKED'};
category_list(shuffled_confederate_ldx) = {'SHUFFLED'};
figure('Name', 'AgoB_A_depends_on_LastB_pval');
violinplot(log10(ephys_session_data.AgoB_A_depends_on_LastB_pval(ConfHP_B_ldx & dyadic_ldx)), category_list(ConfHP_B_ldx & dyadic_ldx));
[ aggregate_struct, report_string ] = fn_statistic_test_and_report('blocked', log10(ephys_session_data.AgoB_A_depends_on_LastB_pval(ConfHP_B_ldx & dyadic_ldx & blocked_confederate_ldx)), 'shuffled', log10(ephys_session_data.AgoB_A_depends_on_LastB_pval(ConfHP_B_ldx & dyadic_ldx & shuffled_confederate_ldx)), 'ranksum', 1);
figure('Name', 'scatter AgoB_A_depends_on_LastB_pval vs. AgoB_A_depends_on_LastA_pval');
scatter(log10(ephys_session_data.AgoB_A_depends_on_LastB_pval(ConfHP_B_ldx & dyadic_ldx)), log10(ephys_session_data.AgoB_A_depends_on_LastA_pval(ConfHP_B_ldx & dyadic_ldx)))
xlabel('AgoB_A_depends_on_LastB_pval', 'Interpreter', 'none');
ylabel('AgoB_A_depends_on_LastA_pval', 'Interpreter', 'none');
axis equal
axis square
hold on
x_lim = get(gca(), 'XLim');
y_lim = get(gca(), 'YLim');
plot(x_lim, y_lim);
hold off


figure('Name', 'AirtB_A_depends_on_LastB_pval');
violinplot(log10(ephys_session_data.AirtB_A_depends_on_LastB_pval(ConfHP_B_ldx & dyadic_ldx)), category_list(ConfHP_B_ldx & dyadic_ldx));
[ aggregate_struct, report_string ] = fn_statistic_test_and_report('blocked', log10(ephys_session_data.AirtB_A_depends_on_LastB_pval(ConfHP_B_ldx & dyadic_ldx & blocked_confederate_ldx)), 'shuffled', log10(ephys_session_data.AirtB_A_depends_on_LastB_pval(ConfHP_B_ldx & dyadic_ldx & shuffled_confederate_ldx)), 'ranksum', 1);
figure('Name', 'scatter AirtB_A_depends_on_LastB_pval vs. AirtB_A_depends_on_LastA_pval');
scatter(log10(ephys_session_data.AirtB_A_depends_on_LastB_pval(ConfHP_B_ldx & dyadic_ldx)), log10(ephys_session_data.AirtB_A_depends_on_LastA_pval(ConfHP_B_ldx & dyadic_ldx)))
xlabel('AirtB_A_depends_on_LastB_pval', 'Interpreter', 'none');
ylabel('AirtB_A_depends_on_LastA_pval', 'Interpreter', 'none');
axis equal
axis square
hold on
x_lim = get(gca(), 'XLim');
y_lim = get(gca(), 'YLim');
plot(x_lim, y_lim);
hold off


min_prediction_trials_ldx = (ephys_session_data.AgoB_nTrials_A > min_prediction_trials) & (ephys_session_data.AgoB_nTrials_B > min_prediction_trials);
figure('Name', 'AgoB_SamePCT_AB');
violinplot((ephys_session_data.AgoB_SamePCT_AB(ConfHP_B_ldx & dyadic_ldx & min_prediction_trials_ldx)), category_list(ConfHP_B_ldx & dyadic_ldx & min_prediction_trials_ldx));
[ aggregate_struct, report_string ] = fn_statistic_test_and_report('blocked', (ephys_session_data.AgoB_SamePCT_AB(ConfHP_B_ldx & dyadic_ldx & blocked_confederate_ldx & min_prediction_trials_ldx)), 'shuffled', (ephys_session_data.AgoB_SamePCT_AB(ConfHP_B_ldx & dyadic_ldx & shuffled_confederate_ldx & min_prediction_trials_ldx)), 'ranksum', 1);
figure('Name', 'scatter AgoB_SamePCT_AB vs. BgoA_SamePCT_AB');
scatter((ephys_session_data.AgoB_SamePCT_AB(ConfHP_B_ldx & dyadic_ldx & min_prediction_trials_ldx)), (ephys_session_data.BgoA_SamePCT_AB(ConfHP_B_ldx & dyadic_ldx & min_prediction_trials_ldx)))
xlabel('AgoB_SamePCT_AB', 'Interpreter', 'none');
ylabel('BgoA_SamePCT_AB', 'Interpreter', 'none');
axis equal
axis square
hold on
x_lim = get(gca(), 'XLim');
y_lim = get(gca(), 'YLim');
plot(x_lim, y_lim);
hold off


% % just look at the overal sameness selection (ideally should be redone for AirtB instead of all hits...)
% %AirtB_SamePCT_AB = 100 * ((ephys_session_data.AirtB_Same_A_Low_LastB_High_N + ephys_session_data) / (ephys_session_data.AirtB_Same_A_Low_LastB_High_N + ephys_session_data + ephys_session_data))
% figure('Name', 'SameValHitTrialsPCT');
% violinplot((ephys_session_data.SameValHitTrialsPCT(ConfHP_B_ldx & dyadic_ldx)), category_list(ConfHP_B_ldx & dyadic_ldx));
% [ aggregate_struct, report_string ] = fn_statistic_test_and_report('blocked', (ephys_session_data.SameValHitTrialsPCT(ConfHP_B_ldx & dyadic_ldx & blocked_confederate_ldx)), 'shuffled', (ephys_session_data.SameValHitTrialsPCT(ConfHP_B_ldx & dyadic_ldx & shuffled_confederate_ldx)), 'ranksum', 1);
% figure('Name', 'scatter SameValHitTrialsPCT vs. BgoA_SamePCT_AB');
% scatter((ephys_session_data.SameValHitTrialsPCT(ConfHP_B_ldx & dyadic_ldx)), (ephys_session_data.SameValHitTrialsPCT(ConfHP_B_ldx & dyadic_ldx)))
% xlabel('SameValHitTrialsPCT', 'Interpreter', 'none');
% ylabel('SameValHitTrialsPCT', 'Interpreter', 'none');
% axis equal
% axis square
% hold on
% x_lim = get(gca(), 'XLim');
% y_lim = get(gca(), 'YLim');
% plot(x_lim, y_lim);
% hold off

% AirtB_Same_A_Low_LastB_High_N
% AirtB_Diff_A_High_LastB_High_N
% AirtB_Diff_A_Low_LastB_Low_N
% AirtB_Same_A_High_LastB_Low_N

% whether a partner was actually predictable
predictable_confederate_ldx = (ConfHP_A_ldx & (ephys_session_data.A_nonrandomValue_p < predictable_confederate_alpha_threshold_pval)) | (ConfHP_B_ldx & (ephys_session_data.B_nonrandomValue_p < predictable_confederate_alpha_threshold_pval));
%tmp = [blocked_confederate_ldx, shuffled_confederate_ldx, predictable_confederate_ldx]



% allow for different ways to assess prediction
switch prediction_measure_string
	% whether a partner was predicted...
	case 'XgoY_X_depends_on_LastY_pval'
		A_predicted_partner_B_ldx = ephys_session_data.AgoB_A_depends_on_LastB_pval < predicting_confederate_alpha_threshold_pval;
		B_predicted_partner_A_ldx = ephys_session_data.BgoA_B_depends_on_LastA_pval < predicting_confederate_alpha_threshold_pval;
	case 'XirtY_X_depends_on_LastY_pval'
		A_predicted_partner_B_ldx = ephys_session_data.AirtB_A_depends_on_LastB_pval < predicting_confederate_alpha_threshold_pval;
		B_predicted_partner_A_ldx = ephys_session_data.BirtA_B_depends_on_LastA_pval < predicting_confederate_alpha_threshold_pval;
	case 'XgoY_SamePCT_AB'
		A_predicted_partner_B_ldx = ephys_session_data.AgoB_SamePCT_AB > predicting_confederate_sameness_threshold_pct;
		B_predicted_partner_A_ldx = ephys_session_data.BgoA_SamePCT_AB > predicting_confederate_sameness_threshold_pct;
end
AB_predicted_partner_ldx = A_predicted_partner_B_ldx | B_predicted_partner_A_ldx;

% number of trials required to include a session...


% tmp = [blocked_confederate_ldx, shuffled_confederate_ldx, predictable_confederate_ldx, predicted_partner_A_ldx, predicted_partner_B_ldx, predicted_partner_ldx, ephys_session_data.AgoB_A_depends_on_LastB_pval, ephys_session_data.AirtB_A_depends_on_LastB_pval, ephys_session_data.BgoA_B_depends_on_LastA_pval, ephys_session_data.BirtA_B_depends_on_LastA_pval];
% tmp2 = tmp(shuffled_confederate_ldx, :);
% tmp3 = tmp(blocked_confederate_ldx, :);


% proto_dual_ephys_session
dual_NHP_ephys_session_ldx = NHP_A_ldx & NHP_B_ldx;
single_NHP_ephys_session_ldx = ~dual_NHP_ephys_session_ldx;

spike_sorted_combinations_ldx = ismember(ephys_session_data.EPhysSpikeSorted, {'1'});

%[ matching_item_ldx ] = fn_find_regexpmatch_entries_in_cell_list( ephys_session_data.TankID_list, regexp_match_pattern )

ephys_summary_table_struct = [];

% find the records per ephys_subject
for i_ephys_subject = 1 : length(ephys_subject_list)
	cur_ephys_subject = ephys_subject_list{i_ephys_subject};
	disp([mfilename, ': ', cur_ephys_subject]);
	cur_ephys_subject_on_A_ldx = ismember(ephys_session_data.subject_A, cur_ephys_subject);
	cur_ephys_subject_on_B_ldx = ismember(ephys_session_data.subject_B, cur_ephys_subject);
	dual_NHP_session_with_cur_subject_ephys = dual_NHP_ephys_session_ldx & (fn_find_regexpmatch_entries_in_cell_list(ephys_session_data.TankID_list, ['_', cur_ephys_subject,'$'])');
	dual_NHP_session_without_cur_subject_ephys = dual_NHP_ephys_session_ldx & ~dual_NHP_session_with_cur_subject_ephys;
	% get all combination lines for the current subject
	cur_ephys_subject_combination_ldx = ((cur_ephys_subject_on_A_ldx | cur_ephys_subject_on_B_ldx) & single_NHP_ephys_session_ldx) | dual_NHP_session_with_cur_subject_ephys;


	for i_trialsubtype = 1 : length(unique_trial_subtypes)
		cur_trial_subtype = unique_trial_subtypes{i_trialsubtype};
		disp([mfilename, ': ', cur_ephys_subject, '; ', cur_trial_subtype]);
		cur_trial_subtype_ldx = ephys_session_data_to_unique_trialsubtype_mapping == i_trialsubtype;

		cur_selected_combinations_ldx = cur_trial_subtype_ldx & cur_ephys_subject_combination_ldx;


		for i_subject_on_side = 1 : length(side_list)
			cur_side = side_list{i_subject_on_side};
			disp([mfilename, ': ', cur_ephys_subject, '; ', cur_trial_subtype, '; ', cur_side]);
			cur_selected_combinations_A_ldx = cur_selected_combinations_ldx & cur_ephys_subject_on_A_ldx;
			cur_selected_combinations_B_ldx = cur_selected_combinations_ldx & cur_ephys_subject_on_B_ldx;

			switch cur_side
				case 'AB'
					min_prediction_trials_ldx = (ephys_session_data.AgoB_nTrials_A > min_prediction_trials) & (ephys_session_data.BgoA_nTrials_B > min_prediction_trials);
					cur_ephys_subject_on_X_ldx = cur_trial_subtype_ldx & (cur_selected_combinations_A_ldx | cur_selected_combinations_B_ldx);
					cur_ephys_session_data_MUA_X_exported = ephys_session_data.MUA_A_exported | ephys_session_data.MUA_B_exported;
					cur_ephys_session_data_LFP_X_exported = ephys_session_data.LFP_A_exported | ephys_session_data.LFP_B_exported;

				case {'A', 'B'}
					cur_ephys_subject_on_X_ldx = cur_trial_subtype_ldx & ismember(ephys_session_data.(['subject_', cur_side]), cur_ephys_subject);
					cur_ephys_session_data_MUA_X_exported = ephys_session_data.(['MUA_', cur_side, '_exported']);
					cur_ephys_session_data_LFP_X_exported = ephys_session_data.(['LFP_', cur_side, '_exported']);
			end

			switch cur_side
				case {'A'}
					cur_predicted_partner_ldx = A_predicted_partner_B_ldx;
					min_prediction_trials_ldx = (ephys_session_data.AgoB_nTrials_A > min_prediction_trials);
				case {'B'}
					cur_predicted_partner_ldx = B_predicted_partner_A_ldx;
					min_prediction_trials_ldx = (ephys_session_data.BgoA_nTrials_B > min_prediction_trials);
			end


			cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
			cur_ephys_summary_table_struct.Side = cur_side;
			cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
			cur_ephys_summary_table_struct.Comment = ''; % fill in later
			cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx);
			cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx);
			cur_ephys_summary_table_struct.N_MUA = sum(cur_ephys_subject_on_X_ldx & cur_ephys_session_data_MUA_X_exported);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
			cur_ephys_summary_table_struct.N_LFP = sum(cur_ephys_subject_on_X_ldx & cur_ephys_session_data_LFP_X_exported);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);

			if isempty(ephys_summary_table_struct)
				ephys_summary_table_struct = cur_ephys_summary_table_struct;
			else
				ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;
			end

			switch cur_trial_subtype
				case 'SoloARewardAB' %{'SoloARewardAB', 'SoloA', 'SoloA_PresentB', 'SoloABlockedView', 'SoloAHighReward'}
					switch cur_side
						case 'A'
							ephys_summary_table_struct(end).Comment = 'active'; % fill in now
						case 'B'
							ephys_summary_table_struct(end).Comment = 'passive'; % fill in now
					end
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = ['dual NHP ', ephys_summary_table_struct(end).Comment]; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & dual_NHP_session_with_cur_subject_ephys);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & dual_NHP_session_with_cur_subject_ephys);
					cur_ephys_summary_table_struct.N_MUA = sum(dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_MUA_X_exported);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_LFP_X_exported);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;

				case 'SoloBRewardAB' %{'SoloBRewardAB', 'SoloB', 'SoloB_PresentA', 'SoloBBlockedView', 'SoloBHighReward'}
					switch cur_side
						case 'A'
							ephys_summary_table_struct(end).Comment = 'passive'; % fill in now
						case 'B'
							ephys_summary_table_struct(end).Comment = 'active'; % fill in now
					end
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = ['dual NHP ', ephys_summary_table_struct(end).Comment]; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & dual_NHP_session_with_cur_subject_ephys);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & dual_NHP_session_with_cur_subject_ephys);
					cur_ephys_summary_table_struct.N_MUA = sum(dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_MUA_X_exported);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_LFP_X_exported);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;

				case {'Dyadic', 'DyadicBlockedView', 'SemiSolo'}
					% create subreports by confederate's
					% predictability/prediction
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'dual NHP'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & dual_NHP_session_with_cur_subject_ephys);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & dual_NHP_session_with_cur_subject_ephys);
					cur_ephys_summary_table_struct.N_MUA = sum(dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_MUA_X_exported);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_LFP_X_exported);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;

					%predictable confederate - predicted
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'PC predicted'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & ~dual_NHP_session_with_cur_subject_ephys & predictable_confederate_ldx & cur_predicted_partner_ldx & blocked_confederate_ldx & min_prediction_trials_ldx);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & ~dual_NHP_session_with_cur_subject_ephys & predictable_confederate_ldx & cur_predicted_partner_ldx & blocked_confederate_ldx & min_prediction_trials_ldx);
					cur_ephys_summary_table_struct.N_MUA = sum(~dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_MUA_X_exported & predictable_confederate_ldx & cur_predicted_partner_ldx & blocked_confederate_ldx & min_prediction_trials_ldx);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(~dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_LFP_X_exported & predictable_confederate_ldx & cur_predicted_partner_ldx & blocked_confederate_ldx & min_prediction_trials_ldx);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;

					%predictable confederate - not predicted
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'PC not predicted'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & ~dual_NHP_session_with_cur_subject_ephys & predictable_confederate_ldx & ~cur_predicted_partner_ldx & blocked_confederate_ldx & min_prediction_trials_ldx);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & ~dual_NHP_session_with_cur_subject_ephys & predictable_confederate_ldx & ~cur_predicted_partner_ldx & blocked_confederate_ldx & min_prediction_trials_ldx);
					cur_ephys_summary_table_struct.N_MUA = sum(~dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_MUA_X_exported & predictable_confederate_ldx & ~cur_predicted_partner_ldx & blocked_confederate_ldx & min_prediction_trials_ldx);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(~dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_LFP_X_exported & predictable_confederate_ldx & ~cur_predicted_partner_ldx & blocked_confederate_ldx & min_prediction_trials_ldx);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;

					%unpredictable confederate - not predicted
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'UC not predicted'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & ~dual_NHP_session_with_cur_subject_ephys & ~predictable_confederate_ldx & ~cur_predicted_partner_ldx & shuffled_confederate_ldx & min_prediction_trials_ldx);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & ~dual_NHP_session_with_cur_subject_ephys & ~predictable_confederate_ldx & ~cur_predicted_partner_ldx & shuffled_confederate_ldx & min_prediction_trials_ldx);
					cur_ephys_summary_table_struct.N_MUA = sum(~dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_MUA_X_exported & ~predictable_confederate_ldx & ~cur_predicted_partner_ldx & shuffled_confederate_ldx & min_prediction_trials_ldx);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(~dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_LFP_X_exported & ~predictable_confederate_ldx & ~cur_predicted_partner_ldx & shuffled_confederate_ldx & min_prediction_trials_ldx);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;

					%unpredictable confederate - predicted
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'UC predicted'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & ~dual_NHP_session_with_cur_subject_ephys & ~predictable_confederate_ldx & cur_predicted_partner_ldx & shuffled_confederate_ldx & min_prediction_trials_ldx);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & ~dual_NHP_session_with_cur_subject_ephys & ~predictable_confederate_ldx & cur_predicted_partner_ldx & shuffled_confederate_ldx & min_prediction_trials_ldx);
					cur_ephys_summary_table_struct.N_MUA = sum(~dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_MUA_X_exported & ~predictable_confederate_ldx & cur_predicted_partner_ldx & shuffled_confederate_ldx & min_prediction_trials_ldx);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(~dual_NHP_session_with_cur_subject_ephys & cur_ephys_subject_on_X_ldx & cur_ephys_session_data_LFP_X_exported & ~predictable_confederate_ldx & cur_predicted_partner_ldx & shuffled_confederate_ldx & min_prediction_trials_ldx);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;
			end


		end
	end

end

% report AB merged
if (merge_sides)
	ephys_summary_table_struct_col_names = fieldnames(ephys_summary_table_struct);

	% generate a key

	% we leave the sides out so we can aggregate over sides, IFF the
	% comments do not differ
	trial_type_list = {ephys_summary_table_struct.TrialType};

	mod_trial_type_list = regexprep(trial_type_list, '^SoloA', 'Solo');
	mod_trial_type_list = regexprep(mod_trial_type_list, '^SoloB', 'Solo');

	key_list = strcat({ephys_summary_table_struct.Subject}, '_', mod_trial_type_list, '_', {ephys_summary_table_struct.Comment});

	[unique_merged_records, ~, unique_merged_records_combination_idx] = unique(key_list, 'stable');

	for i_key = 1 : length(unique_merged_records)
		cur_key = unique_merged_records{i_key};
		cur_key_ephys_summary_table_struct_row_idx = find(unique_merged_records_combination_idx == i_key);

		cur_ephys_summary_subtable = ephys_summary_table_struct(cur_key_ephys_summary_table_struct_row_idx);
		cur_trialtype_table = mod_trial_type_list(cur_key_ephys_summary_table_struct_row_idx);

		for i_col_name = 1 : length(ephys_summary_table_struct_col_names)
			cur_col_name = ephys_summary_table_struct_col_names{i_col_name};

			unique_col_value = [];
			summed_value = [];
			if ischar(cur_ephys_summary_subtable(1).(cur_col_name))
				unique_col_value = unique({cur_ephys_summary_subtable(:).(cur_col_name)});
			elseif isnumeric(cur_ephys_summary_subtable(1).(cur_col_name))
				summed_value = sum([cur_ephys_summary_subtable(:).(cur_col_name)]);
			end


			switch cur_col_name
				case {'Subject', 'Comment'}
					if (length(unique_col_value))
						cur_merged_ephys_summary_table_struct.(cur_col_name) = unique_col_value{1};
					else
						error('too many unique values, expected only one');
					end
				case 'Side'
					cur_merged_ephys_summary_table_struct.(cur_col_name) = 'mAB';
				case 'TrialType'
					unique_col_value = unique(cur_trialtype_table);
					if (length(unique_col_value))
						cur_merged_ephys_summary_table_struct.(cur_col_name) = unique_col_value{1};
					else
						error('too many unique values, expected only one');
					end
				otherwise
					if ~isempty(summed_value)
						cur_merged_ephys_summary_table_struct.(cur_col_name) = summed_value;
					end
			end
		end

		cur_TrialType_Comment = [cur_merged_ephys_summary_table_struct.TrialType, '_', cur_merged_ephys_summary_table_struct.Comment];

		cur_TrialType_Comment_string = '';
		switch cur_TrialType_Comment
			case 'Solo_'
				cur_TrialType_Comment_string = 'Solo';
			case 'SoloRewardAB_dual NHP active'
				cur_TrialType_Comment_string = 'SoloActiveRewardBoth';
			case 'SoloRewardAB_dual NHP passive'
				cur_TrialType_Comment_string = 'SoloObservedRewardBoth';
			case 'SoloRewardAB_active'
				cur_TrialType_Comment_string = '';
			case 'SoloRewardAB_passive'
				cur_TrialType_Comment_string = 'ObserveConfederateRewarded'; % SoloObserveConfederateRewarded
			case 'Dyadic_dual NHP'
				cur_TrialType_Comment_string = 'Dyadic monkeys';
			case 'Dyadic_PC predicted'
				cur_TrialType_Comment_string = 'Dyadic with predictable confederate (PC) trusts/predicts';
			case 'Dyadic_PC not predicted'
				cur_TrialType_Comment_string = 'Dyadic with predictable confederate (PC) does not predict';
			case 'Dyadic_UC not predicted'
				cur_TrialType_Comment_string = 'Dyadic with unpredictable confederate (UC) does not predict';
			case 'Dyadic_UC predicted'
				cur_TrialType_Comment_string = 'Dyadic with unpredictable confederate (UC) trusts/predicts';
			case 'SemiSolo_dual NHP'
				cur_TrialType_Comment_string = 'SemiSolo monkeys';
			case 'SemiSolo_PC predicted'
				cur_TrialType_Comment_string = 'SemiSolo with predictable confederate (PC) trusts/predicts';
			case 'SemiSolo_PC not predicted'
				cur_TrialType_Comment_string = 'SemiSolo with predictable confederate (PC) does not predict';
			case 'SemiSolo_UC not predicted'
				cur_TrialType_Comment_string = 'SemiSolo with unpredictable confederate (UC) does not predict';
			case 'SemiSolo_UC predicted'
				cur_TrialType_Comment_string = 'SemiSolo with unpredictable confederate (UC) trusts/predicts';
			case 'DyadicBlockedView_dual NHP'
				cur_TrialType_Comment_string = 'Dyadic blocked monkeys';
			case 'DyadicBlockedView_PC predicted'
				cur_TrialType_Comment_string = 'Dyadic blocked with predictable confederate (PC) trusts/predicts';
			case 'DyadicBlockedView_PC not predicted'
				cur_TrialType_Comment_string = 'Dyadic blocked with predictable confederate (PC) does not predict';
			case 'DyadiBlockedViewc_UC not predicted'
				cur_TrialType_Comment_string = 'Dyadic blocked with unpredictable confederate (UC) does not predict';
			case 'DyadicBlockedView_UC predicted'
				cur_TrialType_Comment_string = 'Dyadic blocked with unpredictable confederate (UC) trusts/predicts';
			case {'Solo_PresentA_', 'Solo_PresentB_'}
				cur_TrialType_Comment_string = 'SoloConfederatePresent';
		end

		cur_merged_ephys_summary_table_struct.verbose_TrialType = cur_TrialType_Comment_string;

		if (i_key == 1)
			merged_ephys_summary_table_struct = cur_merged_ephys_summary_table_struct;
		else
			merged_ephys_summary_table_struct(end+1) = cur_merged_ephys_summary_table_struct;
		end

	end
end


fn_save_struct_array_as_tables(fullfile(input_dir, [output_stem, '.mat']), ephys_summary_table_struct);
fn_save_struct_array_as_tables(fullfile(input_dir, [output_stem, '.ABmerged', '.mat']), merged_ephys_summary_table_struct);

end



function [] = fn_save_struct_array_as_tables(out_FQN, ephys_summary_table_struct)

%out_FQN = fullfile(input_dir, [output_stem, '.mat']);

% save struct array as mat file:
disp(['Saving session info data as: ' out_FQN]);
save(out_FQN, 'ephys_summary_table_struct');

% now save as xlsx and csv
output_data_table = struct2table(ephys_summary_table_struct);
[out_dir, out_name, out_ext] = fileparts(out_FQN);

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
