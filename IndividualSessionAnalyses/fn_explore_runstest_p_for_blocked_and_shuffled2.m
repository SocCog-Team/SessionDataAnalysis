function [ ] = fn_explore_runstest_p_for_blocked_and_shuffled( input_table )
%FN_EXPLORE_RUNSTEST_P_FOR_BLOCKED_AND_SHUFFLED Summary of this function goes here
%   Detailed explanation goes here
% Look at the distributions of A/B_nonrandomValue_p, A/B_nonrandomSide_p
% for BLOCKED and SHUFFLED human partners... to find an appropriate
% sequence_is_random_threshold_p value for
% fn_collect_and_store_per_session_information.m
% TODO convert to function to get subsets of sessions based on names, each
% name then goes to one switch case and returns the set of sessions...


input_table_fqn = [];

if ~exist("input_table", 'var') || isempty(input_table)
	input_table_fqn = fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', 'All_session_summary_table.V2.table.mat');
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

table_col_names = fieldnames(output_data_table);


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


% muinimal hit trials
min_HIT_trial_ldx = output_data_table.HitTrials > 200;


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


histogram(log(HP_BLOCKED_nonrandomValue_p), 100);
hold on
histogram(log(HP_SHUFFLED_nonrandomValue_p), 100);
hold off

h1 = histogram((HP_BLOCKED_nonrandomValue_p), (0: 0.0005: 0.2));
hold on
h2 = histogram((HP_SHUFFLED_nonrandomValue_p), (0: 0.005: 0.2));
hold off



% select 10 sessions with BLOCKED and SHUFFLED partner for Elmo and Curius
% with decent following
Curius_ldx = ismember(output_data_table.subject_A, {'Curius'}) | ismember(output_data_table.subject_B, {'Curius'});
Elmo_ldx = ismember(output_data_table.subject_A, {'Elmo'}) | ismember(output_data_table.subject_B, {'Elmo'});
A_Curius_ldx = ismember(output_data_table.subject_A, {'Curius'});
A_Elmo_ldx = ismember(output_data_table.subject_A, {'Elmo'});
EPHYS_ldx = ~ismember(output_data_table.EPhysRecorded, {'0'});
A_predicts_B_ldx = (output_data_table.A_predicts_Bvalue);

% try to find the best 10 prediction and non prediction sessions
Curius_predicts_BLOCKED_CONF_idx = find(A_NHP_B_HP_BLOCKED_ldx & A_Curius_ldx & EPHYS_ldx & A_predicts_B_ldx & min_HIT_trial_ldx);
Curius_ignores_SHUFFLED_CONF_idx = find(A_NHP_B_HP_SHUFFLED_ldx & A_Curius_ldx & EPHYS_ldx & ~A_predicts_B_ldx & min_HIT_trial_ldx);

Elmo_predicts_BLOCKED_CONF_idx = find(A_NHP_B_HP_BLOCKED_ldx & A_Elmo_ldx & EPHYS_ldx & A_predicts_B_ldx & min_HIT_trial_ldx);
Elmo_ignores_SHUFFLED_CONF_idx = find(A_NHP_B_HP_SHUFFLED_ldx & A_Elmo_ldx & EPHYS_ldx & ~A_predicts_B_ldx & min_HIT_trial_ldx);


% sort by prediction % use HitTrials only as cut off (> 200?)


% pick the 10 sessions each with most dyadic trials...
n_sessions_to_pick = 10;

output_data_table.HitTrials(Curius_predicts_BLOCKED_CONF_idx)
output_data_table.B_nonrandomValue_p(Curius_predicts_BLOCKED_CONF_idx)
% sort by prediction precentage
[~, sort_idx] = sort(output_data_table.HitTrials(Curius_predicts_BLOCKED_CONF_idx), 'descend');
[~, sort_idx] = sort(output_data_table.A_prediction_of_lowValue_pct(Curius_predicts_BLOCKED_CONF_idx), 'descend');
Curius_BLOCKED_CONF_top_10 = output_data_table.session_ID(Curius_predicts_BLOCKED_CONF_idx(sort_idx(1:n_sessions_to_pick+0)));
Curius_BLOCKED_CONF_top_10 = unique(Curius_BLOCKED_CONF_top_10);


output_data_table.HitTrials(Curius_ignores_SHUFFLED_CONF_idx)
output_data_table.B_nonrandomValue_p(Curius_ignores_SHUFFLED_CONF_idx)
[~, sort_idx] = sort(output_data_table.HitTrials(Curius_ignores_SHUFFLED_CONF_idx), 'descend');
[~, sort_idx] = sort(output_data_table.A_prediction_of_lowValue_pct(Curius_ignores_SHUFFLED_CONF_idx), 'ascend');
Curius_SHUFFLED_CONF_top_10 = output_data_table.session_ID(Curius_ignores_SHUFFLED_CONF_idx(sort_idx(1:n_sessions_to_pick+0)));
Curius_SHUFFLED_CONF_top_10 = unique(Curius_SHUFFLED_CONF_top_10);

Curius_doubletts = unique([Curius_BLOCKED_CONF_top_10; Curius_SHUFFLED_CONF_top_10]);


output_data_table.HitTrials(Elmo_predicts_BLOCKED_CONF_idx)
output_data_table.B_nonrandomValue_p(Elmo_predicts_BLOCKED_CONF_idx)
[~, sort_idx] = sort(output_data_table.HitTrials(Elmo_predicts_BLOCKED_CONF_idx), 'descend');
[~, sort_idx] = sort(output_data_table.A_prediction_of_lowValue_pct(Elmo_predicts_BLOCKED_CONF_idx), 'descend');

Elmo_BLOCKED_CONF_top_10 = output_data_table.session_ID(Elmo_predicts_BLOCKED_CONF_idx(sort_idx(1:n_sessions_to_pick+3)));
Elmo_BLOCKED_CONF_top_10 = unique(Elmo_BLOCKED_CONF_top_10);


output_data_table.HitTrials(Elmo_ignores_SHUFFLED_CONF_idx)
output_data_table.B_nonrandomValue_p(Elmo_ignores_SHUFFLED_CONF_idx)
[~, sort_idx] = sort(output_data_table.HitTrials(Elmo_ignores_SHUFFLED_CONF_idx), 'descend');
[~, sort_idx] = sort(output_data_table.A_prediction_of_lowValue_pct(Elmo_ignores_SHUFFLED_CONF_idx), 'ascend');
Elmo_SHUFFLED_CONF_top_10 = output_data_table.session_ID(Elmo_ignores_SHUFFLED_CONF_idx(sort_idx(1:n_sessions_to_pick+0)));
Elmo_SHUFFLED_CONF_top_10 = unique(Elmo_SHUFFLED_CONF_top_10);

Elmo_doubletts = unique([Elmo_BLOCKED_CONF_top_10; Elmo_SHUFFLED_CONF_top_10]);





return
end

