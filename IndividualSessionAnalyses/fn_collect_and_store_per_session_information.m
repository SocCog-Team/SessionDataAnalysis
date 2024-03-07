function [ session_info_struct, session_info_struct_version ] = fn_collect_and_store_per_session_information( cur_session_logfile_fqn,  cur_cur_output_base_dir, config_name )
%FN_COLLECT_AND_STORE_PER_SESSION_INFORMATION extract information for
%individual sessions and store them into a big table
%   Collect information about sessions about number of trials per trial sub
%   type, number of sucessful trials, number aborted trials agent ID
%	save as CSV and as excel table
%
% TODO:
%	add information about value and side biases and prediction for 

% information:

%session ID, trialsubtype, total trials, rewarded trials A, rewarded trials
%B, name A, B, meanRT(A, mean RT(B), Cue type A, B (shuffled/blocked), with
%ephys (ckeck folder), tank id list, is clustered? is analyzed

summary_suffix = 'session_summary';
% to allow automatic updates for newer versions with more fields or error
% corrections add the version number...
session_info_struct_version = '2';

[logfile_path, logfile_name, log_file_ext] = fileparts(cur_session_logfile_fqn);
% find the canonical session ID
processed_session_id = logfile_name;
processed_session_id = regexprep(processed_session_id, '.gz', '');
processed_session_id = regexprep(processed_session_id, '.txt', '');
processed_session_id = regexprep(processed_session_id, '.triallog', '');

session_info = fn_parse_session_id(processed_session_id);


sequence_is_random_threshold_p = 0.05;			% which p-threshold to use to reject the hypothesis that a side or value sequence is random/unpredictable
prediction_is_above_chance_threshold_p = 0.05;	% which p-threshold to use to accept significant prediction

[cur_session_logfile_path, cur_session_logfile_name, cur_session_logfile_ext] = fileparts(cur_session_logfile_fqn);


if ~exist(cur_cur_output_base_dir, 'var') || isempty(cur_cur_output_base_dir)
	cur_cur_output_base_dir = fullfile(cur_session_logfile_path, 'ANALYSIS');
end

% load data and TrialSets
[report_struct, TrialSets] = fn_load_triallog(cur_session_logfile_fqn);

if isempty(report_struct) || isempty(TrialSets)
	session_info_struct = [];
	disp([logfile_name, log_file_ext, ': does not appear to be a valid trialllog file, skipping...']);
	return
end

% we need at least one trial in the logfile
if isempty(fieldnames(report_struct)) || size(report_struct.data, 1) < 1 
	session_info_struct = [];
	disp([processed_session_id, ': no trials found in logfile, skipping...']);
	return
end	

% we also need a filled TrialSet...
if isempty(TrialSets) 
	session_info_struct = [];
	disp([processed_session_id, ': empty TrialSets found for logfile, skipping...']);
	return
end	

n_trials = size(report_struct.data, 1);
action_sequence_list = cell([n_trials, 1]);
if isfield(report_struct.cn, 'A_GoSignalTime_ms') && isfield(report_struct.cn, 'B_GoSignalTime_ms')
	AB_GoSignalTime_diff = report_struct.data(:, report_struct.cn.A_GoSignalTime_ms) - report_struct.data(:, report_struct.cn.B_GoSignalTime_ms);
	action_sequence_list(find(AB_GoSignalTime_diff < 0)) = {'AgoB'};
	action_sequence_list(find(AB_GoSignalTime_diff > 0)) = {'BgoA'};
	action_sequence_list(find(AB_GoSignalTime_diff== 0)) = {'ABgo'};
else
	% old data all ABgo
	action_sequence_list(:) = {'ABgo'};
end

%% the following will not give stable, well sorted results in case any of
%% the timing condition is missing...
%% now we want/need these for all sessions, so create a 
%[action_sequence_name_list, ~, action_sequence_idx_by_trial] = unique(action_sequence_list, 'first');
% this should give us sorted action sequences for a given set...
action_sequence_name_list = {'AgoB', 'ABgo', 'BgoA'};
action_sequence_idx_by_trial = zeros(size(action_sequence_list));
for i_action_sequence = 1 : length(action_sequence_name_list)
	cur_action_sequence_occurence_idx = ismember(action_sequence_list, action_sequence_name_list(i_action_sequence));
	action_sequence_idx_by_trial(cur_action_sequence_occurence_idx) = i_action_sequence;
end


% this is primaryly information about whether a cue was visibe and by which
% rule it was selected, it does not show that a subject actually followed
% the cue signal.
if ~isempty(TrialSets.ByConfChoiceCue_RndMethod) && (isfield(TrialSets.ByConfChoiceCue_RndMethod.SideA, 'BLOCKED_GEN_LIST'))
	%A
	TrialSets.ByConfChoiceCue_RndMethod.SideA.random = TrialSets.ByConfChoiceCue_RndMethod.SideA.RND_EQUAL_MIN_MAX_INC;
	TrialSets.ByConfChoiceCue_RndMethod.SideA.blocked = TrialSets.ByConfChoiceCue_RndMethod.SideA.BLOCKED_GEN_LIST;
	TrialSets.ByConfChoiceCue_RndMethod.SideA.shuffled = TrialSets.ByConfChoiceCue_RndMethod.SideA.RND_GEN_LIST;
	% maybe add this to TrialSet generation code?
	TrialSets.ByConfChoiceCue_RndMethod.SideA.invisible = find(report_struct.data(:, report_struct.cn.A_ShowChoiceHint) == 0);
	A_shuffled_trials_idx = setdiff(TrialSets.ByConfChoiceCue_RndMethod.SideA.shuffled, TrialSets.ByConfChoiceCue_RndMethod.SideA.invisible);
	A_blocked_trials_idx = setdiff(TrialSets.ByConfChoiceCue_RndMethod.SideA.blocked, TrialSets.ByConfChoiceCue_RndMethod.SideA.invisible);
	% B
	TrialSets.ByConfChoiceCue_RndMethod.SideB.random = TrialSets.ByConfChoiceCue_RndMethod.SideB.RND_EQUAL_MIN_MAX_INC;
	TrialSets.ByConfChoiceCue_RndMethod.SideB.blocked = TrialSets.ByConfChoiceCue_RndMethod.SideB.BLOCKED_GEN_LIST;
	TrialSets.ByConfChoiceCue_RndMethod.SideB.shuffled = TrialSets.ByConfChoiceCue_RndMethod.SideB.RND_GEN_LIST;
	% maybe add this to TrialSet generation code?
	TrialSets.ByConfChoiceCue_RndMethod.SideB.invisible = find(report_struct.data(:, report_struct.cn.B_ShowChoiceHint) == 0);
	B_shuffled_trials_idx = setdiff(TrialSets.ByConfChoiceCue_RndMethod.SideB.shuffled, TrialSets.ByConfChoiceCue_RndMethod.SideB.invisible);
	B_blocked_trials_idx = setdiff(TrialSets.ByConfChoiceCue_RndMethod.SideB.blocked, TrialSets.ByConfChoiceCue_RndMethod.SideB.invisible);
else
	A_shuffled_trials_idx = [];
	A_blocked_trials_idx = [];
	B_shuffled_trials_idx = [];
	B_blocked_trials_idx = [];
end

if ~exist(config_name, 'var') || isempty(config_name)
	config_name = 'default';
end


switch lower(config_name)
	case {'default'}
	otherwise
		error(['Unkown config_name requested: ', config_name, ', FIX ME.']);
end



session_info_struct = struct();


% collect information affecting the whole session
session_struct.session_ID = session_info.session_id;
session_struct.sort_key_string = session_info.session_id;
session_struct.version = session_info_struct_version;
session_struct.date = session_info.YYYYMMDD_string;
session_struct.time = session_info.HHmmSS_string;

% total rewarded trials, total aborted trials?

% gaze traces, touch traces?

% ephys, clustered, analyses

session_struct.Analysed = 0;
if isfolder(fullfile(logfile_path, 'ANALYSIS'))
	if ~isempty(dir(fullfile(logfile_path, 'ANALYSIS', '*.pdf')))
		session_struct.Analysed = 1;
	end
end

if isfolder(fullfile(logfile_path, 'TDT'))
	SCP_dir_struct = dir(fullfile(logfile_path, 'TDT', 'SCP_DAG*'));
	%SCP_dir_struct = dir(fullfile(logfile_path, 'TDT'));
	if ~isempty(SCP_dir_struct)
		TankID_list = {SCP_dir_struct(:).name}';
		tmp_TankID_list = [];
		tmp_EPhysRecorded_string = [];
		tmp_EPhysClustered_string = [];
		for i_tankID = 1 : length(TankID_list)
			cur_Tank_ID = TankID_list{i_tankID};
			tmp_TankID_list = [tmp_TankID_list, ';', cur_Tank_ID];
			
			TBK_dir_struct = dir(fullfile(logfile_path, 'TDT', cur_Tank_ID, '*SCP_DAG*.Tbk'));
			SEV_dir_struct = dir(fullfile(logfile_path, 'TDT', cur_Tank_ID, '*SCP_DAG*_RSn*.sev'));
			if ~isempty(TBK_dir_struct) && ~isempty(SEV_dir_struct)
				tmp_EPhysRecorded_string = [tmp_EPhysRecorded_string, ';', '1'];
			else
				tmp_EPhysRecorded_string = [tmp_EPhysRecorded_string, ';', '0'];
			end
			
			cluster_img_dir_struct = dir(fullfile(logfile_path, 'TDT', cur_Tank_ID, 'ch*dataspikes_*thr*.jpg'));
			if ~isempty(TBK_dir_struct) && ~isempty(SEV_dir_struct) && ~isempty(cluster_img_dir_struct)
				tmp_EPhysClustered_string = [tmp_EPhysClustered_string, ';', '1'];
			else
				tmp_EPhysClustered_string = [tmp_EPhysClustered_string, ';', '0'];
			end
		end
		session_struct.TankID_list = tmp_TankID_list(2:end);
		session_struct.EPhysRecorded = tmp_EPhysRecorded_string(2:end);
		session_struct.EPhysClustered = tmp_EPhysClustered_string(2:end);
	else
		session_struct.TankID_list = '';
		session_struct.EPhysRecorded = '0';
		session_struct.EPhysClustered = '0';
	end
else
	session_struct.TankID_list = '';
	session_struct.EPhysRecorded = '0';
	session_struct.EPhysClustered = '0';
end

% get trial numbers
% find the subsets of subject side combination pairs and trial types and shuffled/blocked
subject_side_combination_list = fieldnames(TrialSets.ByName.Combinations);

cue_randomization_combination_list = fieldnames(TrialSets.ByConfChoiceCue_RndMethod.Combinations);

% now find the trial subtypes, but only do this once
proto_trialsubtype_list = fieldnames(TrialSets.ByTrialSubType);
real_trial_subtype_ldx = ~ismember(proto_trialsubtype_list, {'SideA', 'SideB', 'None'});
trialsubtype_list = proto_trialsubtype_list(real_trial_subtype_ldx);

% rewarded trials
rewarded_trial_idx = TrialSets.ByOutcome.REWARD;
aborted_trial_idx = TrialSets.ByOutcome.ABORT;
combination_count = 0;
for i_subject_side_combination = 1 : length(subject_side_combination_list)
	subject_side_combination_struct = session_struct;
	cur_subject_side_combination = subject_side_combination_list{i_subject_side_combination};
	disp(['SubjectA SubjectB: ', cur_subject_side_combination]);
	cur_subject_side_combination_trial_idx = TrialSets.ByName.Combinations.(cur_subject_side_combination);
	[proto_subjectA, proto_subjectB] = strtok(cur_subject_side_combination, '_');
	cur_subjectA = regexprep(proto_subjectA, 'id', '');
	cur_subjectB = regexprep(proto_subjectB(2:end), 'id', '');
	subject_side_combination_struct.subject_A = cur_subjectA;
	subject_side_combination_struct.subject_B = cur_subjectB;
	cur_trial_idx = cur_subject_side_combination_trial_idx;
	
	% now find the trial subtypes for this combination
	for i_trialsubtype = 1 : length(trialsubtype_list)
		cur_trialsubtype = trialsubtype_list{i_trialsubtype};
		disp(['TrialSubType: ', cur_trialsubtype]);
		cur_trialsubtype_trial_idx = TrialSets.ByTrialSubType.(cur_trialsubtype);
		cur_trial_idx = intersect(cur_subject_side_combination_trial_idx, cur_trialsubtype_trial_idx);
		% skip over empty sets
		if isempty(cur_trial_idx)
			disp(['No trials for TrialSubType',cur_subject_side_combination, ' ', cur_trialsubtype]);
			continue
		end
		trialsubtype_struct = subject_side_combination_struct;
		trialsubtype_struct.trial_subtype = cur_trialsubtype;
		
		% shuffled/blocked count per side combinations
		for i_cue_randomization_combination = 1 : length(cue_randomization_combination_list)
			cue_randomization_combination_struct = trialsubtype_struct;
			cur_cue_randomization_combination = cue_randomization_combination_list{i_cue_randomization_combination};
			disp(['cur_cue_randomization_combination: ', cur_cue_randomization_combination]);
			
			[proto_CueRnd_A, proto_CueRnd_B] = strtok(cur_cue_randomization_combination, '_');
			cur_CueRnd_A = regexprep(proto_CueRnd_A, 'cue', '');
			cur_CueRnd_B = regexprep(proto_CueRnd_B(2:end), 'cue', '');
			cue_randomization_combination_struct.CueRandomizationMethod_A = cur_CueRnd_A;
			cue_randomization_combination_struct.CueRandomizationMethod_B = cur_CueRnd_B;
			cur_cue_randomization_combination_trial_idx = TrialSets.ByConfChoiceCue_RndMethod.Combinations.(cur_cue_randomization_combination);
			cur_trial_idx = intersect(intersect(cur_subject_side_combination_trial_idx, cur_trialsubtype_trial_idx), cur_cue_randomization_combination_trial_idx);
			if isempty(cur_trial_idx)
				disp(['No trials for ',cur_subject_side_combination, ' ', cur_trialsubtype, ' ', cur_cue_randomization_combination]);
				continue
			end

			% prediction requires a predictable partner, so is the partner
			% predictable? The runs test is maybe not the best test for
			% randomness in a sequence but it seems the best matlab offers
			% out of the box.
			trial_vector = zeros([n_trials, 1]);
			left_choices_A = trial_vector;
			left_choices_A(TrialSets.ByChoice.SideA.ChoiceScreenFromALeft) = 1;
			[~, cue_randomization_combination_struct.A_nonrandomSide_p, stats] = runstest(left_choices_A(intersect(TrialSets.ByOutcome.SideA.REWARD, cur_trial_idx)));
			high_choices_A = trial_vector;
			high_choices_A(TrialSets.ByChoice.SideA.TargetValueHigh) = 1;
			[~, cue_randomization_combination_struct.A_nonrandomValue_p, stats] = runstest(high_choices_A(intersect(TrialSets.ByOutcome.SideA.REWARD, cur_trial_idx)));

			left_choices_B = trial_vector;
			left_choices_B(TrialSets.ByChoice.SideB.ChoiceScreenFromALeft) = 1;
			[~, cue_randomization_combination_struct.B_nonrandomSide_p, stats] = runstest(left_choices_B(intersect(TrialSets.ByOutcome.SideB.REWARD, cur_trial_idx)));
			high_choices_B = trial_vector;
			high_choices_B(TrialSets.ByChoice.SideB.TargetValueHigh) = 1;
			[~, cue_randomization_combination_struct.B_nonrandomValue_p, stats] = runstest(high_choices_B(intersect(TrialSets.ByOutcome.SideB.REWARD, cur_trial_idx)));



			cue_randomization_combination_struct.record_type = 'COMBINATION';
			
			% outcome (rewarded versus aborted) combined for both sides
			cur_rewarded_trials_idx = intersect(TrialSets.ByOutcome.REWARD, cur_trial_idx);
			cur_aborted_trials_idx = intersect(TrialSets.ByOutcome.ABORT, cur_trial_idx);
			cue_randomization_combination_struct.HitTrials = length(cur_rewarded_trials_idx);
			cue_randomization_combination_struct.AbortedTrials = length(cur_aborted_trials_idx);
			% SideA
			cur_rewarded_trials_A_idx = intersect(TrialSets.ByOutcome.SideA.REWARD, cur_trial_idx);
			cur_aborted_trials_A_idx = intersect(TrialSets.ByOutcome.SideA.ABORT, cur_trial_idx);
			cue_randomization_combination_struct.HitTrials_A = length(cur_rewarded_trials_A_idx);
			cue_randomization_combination_struct.AbortedTrials_A = length(cur_aborted_trials_A_idx);
			% Side B
			cur_rewarded_trials_B_idx = intersect(TrialSets.ByOutcome.SideB.REWARD, cur_trial_idx);
			cur_aborted_trials_B_idx = intersect(TrialSets.ByOutcome.SideB.ABORT, cur_trial_idx);
			cue_randomization_combination_struct.HitTrials_B = length(cur_rewarded_trials_B_idx);
			cue_randomization_combination_struct.AbortedTrials_B = length(cur_aborted_trials_B_idx);
			

			% get the relative timing
			for i_action_sequence = 1 : length(action_sequence_name_list)
				cur_action_sequence_name = action_sequence_name_list{i_action_sequence};
				cur_action_sequence_trial_idx =  find(action_sequence_idx_by_trial == i_action_sequence);
				% here we only look at completed/rewarded trials
				cur_trial_idx_A = intersect(intersect(TrialSets.ByOutcome.SideA.REWARD, cur_trial_idx), cur_action_sequence_trial_idx);
				cur_trial_idx_B = intersect(intersect(TrialSets.ByOutcome.SideB.REWARD, cur_trial_idx), cur_action_sequence_trial_idx);
				cur_trial_idx_AB = intersect(intersect(intersect(TrialSets.ByOutcome.SideA.REWARD, TrialSets.ByOutcome.SideB.REWARD), cur_trial_idx), cur_action_sequence_trial_idx);

				% NOTE: if the indices are empty the fields contain NaNs, which should work out...

				% A's biases
				cue_randomization_combination_struct.([cur_action_sequence_name, '_nTrials_A']) = length(cur_trial_idx_A);
				cue_randomization_combination_struct.([cur_action_sequence_name, '_HighPCT_A']) = 100 * (length(intersect(TrialSets.ByChoice.SideA.TargetValueHigh, cur_trial_idx_A)) / length(cur_trial_idx_A));
				cue_randomization_combination_struct.([cur_action_sequence_name, '_LeftPCT_A']) = 100 * (length(intersect(TrialSets.ByChoice.SideA.ChoiceScreenFromALeft, cur_trial_idx_A)) / length(cur_trial_idx_A));

				% B's biases
				cue_randomization_combination_struct.([cur_action_sequence_name, '_nTrials_B']) = length(cur_trial_idx_B);
				cue_randomization_combination_struct.([cur_action_sequence_name, '_HighPCT_B']) = 100 * (length(intersect(TrialSets.ByChoice.SideB.TargetValueHigh, cur_trial_idx_B)) / length(cur_trial_idx_B));
				cue_randomization_combination_struct.([cur_action_sequence_name, '_LeftPCT_B']) = 100 * (length(intersect(TrialSets.ByChoice.SideB.TargetValueHigh, cur_trial_idx_B)) / length(cur_trial_idx_B));

				% joint choices
				cue_randomization_combination_struct.([cur_action_sequence_name, '_nTrials_AB']) = length(cur_trial_idx_AB);
				cue_randomization_combination_struct.([cur_action_sequence_name, '_SamePCT_AB']) = 100 * (length(intersect(TrialSets.ByChoice.SameTarget, cur_trial_idx_B)) / length(cur_trial_idx_AB));
				
				cue_randomization_combination_struct.([cur_action_sequence_name, '_Ahigh_Blow_RED']) = length(intersect(TrialSets.ByChoice.JointChoices.TargetValue_HighLow, cur_trial_idx_AB));
				cue_randomization_combination_struct.([cur_action_sequence_name, '_Alow_Bhigh_BLUE']) = length(intersect(TrialSets.ByChoice.JointChoices.TargetValue_LowHigh, cur_trial_idx_AB));
				cue_randomization_combination_struct.([cur_action_sequence_name, '_Ahigh_Bhigh_PINK']) = length(intersect(TrialSets.ByChoice.JointChoices.TargetValue_HighHigh, cur_trial_idx_AB));
				cue_randomization_combination_struct.([cur_action_sequence_name, '_Alow_Blow_GREEN']) = length(intersect(TrialSets.ByChoice.JointChoices.TargetValue_LowLow, cur_trial_idx_AB));

				cue_randomization_combination_struct.([cur_action_sequence_name, '_Aleft_Bleft']) = length(intersect(intersect(TrialSets.ByChoice.SideA.ChoiceScreenFromALeft, TrialSets.ByChoice.SideB.ChoiceScreenFromALeft), cur_trial_idx_AB));
				cue_randomization_combination_struct.([cur_action_sequence_name, '_Aright_Bright']) = length(intersect(intersect(TrialSets.ByChoice.SideA.ChoiceScreenFromARight, TrialSets.ByChoice.SideB.ChoiceScreenFromARight), cur_trial_idx_AB));
				cue_randomization_combination_struct.([cur_action_sequence_name, '_Aleft_Bright']) = length(intersect(intersect(TrialSets.ByChoice.SideA.ChoiceScreenFromALeft, TrialSets.ByChoice.SideB.ChoiceScreenFromARight), cur_trial_idx_AB));
				cue_randomization_combination_struct.([cur_action_sequence_name, '_Aright_Bleft']) = length(intersect(intersect(TrialSets.ByChoice.SideA.ChoiceScreenFromARight, TrialSets.ByChoice.SideB.ChoiceScreenFromALeft), cur_trial_idx_AB));


			end


			% get the fraction of correctly selecting the partner"s
			% prefered color
			if ismember('AgoB', action_sequence_name_list)
				cue_randomization_combination_struct.A_prediction_of_anyValue_pct = cue_randomization_combination_struct.(['AgoB', '_SamePCT_AB']);
				cue_randomization_combination_struct.A_prediction_of_lowValue_pct = 100 * cue_randomization_combination_struct.(['AgoB', '_Alow_Bhigh_BLUE']) / (cue_randomization_combination_struct.(['AgoB', '_Alow_Bhigh_BLUE']) + cue_randomization_combination_struct.(['AgoB', '_Ahigh_Bhigh_PINK']));
				[~, cue_randomization_combination_struct.A_prediction_of_lowValue_p, stats] = fishertest(fn_fishertest_ratio_versus_random([cue_randomization_combination_struct.(['AgoB', '_Alow_Bhigh_BLUE']), cue_randomization_combination_struct.(['AgoB', '_Ahigh_Bhigh_PINK'])]));
			else
				cue_randomization_combination_struct.A_prediction_of_anyValue_pct = NaN;
				cue_randomization_combination_struct.A_prediction_of_lowValue_pct = NaN;
				cue_randomization_combination_struct.A_prediction_of_lowValue_p = NaN;
			end
			
			if ismember('BgoA', action_sequence_name_list)
				cue_randomization_combination_struct.B_prediction_of_anyValue_pct = cue_randomization_combination_struct.(['BgoA', '_SamePCT_AB']);
				cue_randomization_combination_struct.B_prediction_of_lowValue_pct = 100 * cue_randomization_combination_struct.(['BgoA', '_Ahigh_Blow_RED']) / (cue_randomization_combination_struct.(['BgoA', '_Ahigh_Blow_RED']) + cue_randomization_combination_struct.(['BgoA', '_Ahigh_Bhigh_PINK']));
				[~, cue_randomization_combination_struct.B_prediction_of_lowValue_p, stats] = fishertest(fn_fishertest_ratio_versus_random([cue_randomization_combination_struct.(['BgoA', '_Ahigh_Blow_RED']), cue_randomization_combination_struct.(['BgoA', '_Ahigh_Bhigh_PINK'])]));
			else
				cue_randomization_combination_struct.B_prediction_of_anyValue_pct = NaN;
				cue_randomization_combination_struct.B_prediction_of_lowValue_pct = NaN;
				cue_randomization_combination_struct.B_prediction_of_lowValue_p = NaN;
			end
			% preferred side, since agents use the left hand and we use
			% ChoiceScreenFromA, left is likely preferred by A and "right"
			% is preferred by B (as that is the subjective left side from B)
			if ismember('AgoB', action_sequence_name_list)
				cue_randomization_combination_struct.A_prediction_of_anySide_pct = cue_randomization_combination_struct.(['AgoB', '_SamePCT_AB']);
				cue_randomization_combination_struct.A_prediction_of_rightSide_pct = 100 * cue_randomization_combination_struct.(['AgoB', '_Aright_Bright']) / (cue_randomization_combination_struct.(['AgoB', '_Aright_Bright']) + cue_randomization_combination_struct.(['AgoB', '_Aleft_Bright']));
				[~, cue_randomization_combination_struct.A_prediction_of_rightSide_p, stats] = fishertest(fn_fishertest_ratio_versus_random([cue_randomization_combination_struct.(['AgoB', '_Aright_Bright']), cue_randomization_combination_struct.(['AgoB', '_Aleft_Bright'])]));
			else
				cue_randomization_combination_struct.A_prediction_of_anySide_pct = NaN;
				cue_randomization_combination_struct.A_prediction_of_rightSide_pct = NaN;
				cue_randomization_combination_struct.A_prediction_of_rightSide_p = NaN;
			end

			if ismember('BgoA', action_sequence_name_list)
				cue_randomization_combination_struct.B_prediction_of_anySide_pct = cue_randomization_combination_struct.(['BgoA', '_SamePCT_AB']);
				cue_randomization_combination_struct.B_prediction_of_leftSide_pct = 100 * cue_randomization_combination_struct.(['BgoA', '_Aleft_Bleft']) / (cue_randomization_combination_struct.(['BgoA', '_Aleft_Bleft']) + cue_randomization_combination_struct.(['BgoA', '_Aleft_Bright']));
				[~, cue_randomization_combination_struct.B_prediction_of_leftSide_p, stats] = fishertest(fn_fishertest_ratio_versus_random([cue_randomization_combination_struct.(['BgoA', '_Aleft_Bleft']), cue_randomization_combination_struct.(['BgoA', '_Aleft_Bright'])]));
			else
				cue_randomization_combination_struct.B_prediction_of_anySide_pct = NaN;
				cue_randomization_combination_struct.B_prediction_of_leftSide_pct = NaN;
				cue_randomization_combination_struct.B_prediction_of_leftSide_p = NaN;
			end

			% for a to predict we expect a non-random partner and a high
			% fraction of also proactively selecting the partner's
			% preferred color...			

			cue_randomization_combination_struct.A_predicts_Bside = 0;
			if (cue_randomization_combination_struct.B_nonrandomSide_p <= sequence_is_random_threshold_p) ...
					&& (cue_randomization_combination_struct.A_prediction_of_rightSide_pct > 50) ...
					&& (cue_randomization_combination_struct.A_prediction_of_rightSide_p <= prediction_is_above_chance_threshold_p)
				cue_randomization_combination_struct.A_predicts_Bside = 1;
			end

			cue_randomization_combination_struct.B_predicts_Aside = 0;
			if (cue_randomization_combination_struct.A_nonrandomSide_p <= sequence_is_random_threshold_p) ...
					&& (cue_randomization_combination_struct.B_prediction_of_leftSide_pct > 50) ...
					&& (cue_randomization_combination_struct.B_prediction_of_leftSide_p <= prediction_is_above_chance_threshold_p)
				cue_randomization_combination_struct.B_predicts_Aside = 1;
			end


			cue_randomization_combination_struct.A_predicts_Bvalue = 0;
			if (cue_randomization_combination_struct.B_nonrandomValue_p <= sequence_is_random_threshold_p) ...
					&& (cue_randomization_combination_struct.A_prediction_of_lowValue_pct > 50) ...
					&& (cue_randomization_combination_struct.A_prediction_of_lowValue_p <= prediction_is_above_chance_threshold_p)
				cue_randomization_combination_struct.A_predicts_Bvalue = 1;
			end

			cue_randomization_combination_struct.B_predicts_Avalue = 0;
			if (cue_randomization_combination_struct.A_nonrandomValue_p <= sequence_is_random_threshold_p) ...
					&& (cue_randomization_combination_struct.B_prediction_of_lowValue_pct > 50) ...
					&& (cue_randomization_combination_struct.B_prediction_of_lowValue_p <= prediction_is_above_chance_threshold_p)
				cue_randomization_combination_struct.B_predicts_Avalue = 1;
			end



			% add final long fields
			cue_randomization_combination_struct.Session_dir = logfile_path;
			
			if (length(fieldnames(session_info_struct)) == 0)
				session_info_struct = cue_randomization_combination_struct;
			else
				session_info_struct(end+1) = cue_randomization_combination_struct;
			end
			combination_count = combination_count + 1;
			session_info_struct(end).sort_key_string = [session_struct.session_ID, '_', num2str(combination_count, '%03d')];
			
		end
	end
end

% TODO add summary giving the number of different values per string field
% and total trials for trial fields

if isempty(fieldnames(session_info_struct))
	session_info_struct = [];
	disp([processed_session_id, ': no rewarded trials found in logfile, skipping...']);
	return
end

% report these veridically
total_string_fields = {'session_ID', 'sort_key_string', 'version', 'date', 'time', 'Analysed', 'TankID_list', 'EPhysRecorded', 'EPhysClustered', 'Session_dir'};
total_aggregate_fields =     {'HitTrials', 'AbortedTrials', 'HitTrials_A', 'AbortedTrials_A', 'HitTrials_B', 'AbortedTrials_B'};

session_info_struct_fieldlist = fieldnames(session_info_struct(end));
total_session_info_struct = struct();
for i_field = 1 : length(session_info_struct_fieldlist)
	cur_field = session_info_struct_fieldlist{i_field};
	if ismember(cur_field, total_string_fields)
		% copy
		total_session_info_struct.(cur_field) = session_info_struct(end).(cur_field);
	else
		if iscell(session_info_struct(end).(cur_field)) || isstring(session_info_struct(end).(cur_field)) || ischar(session_info_struct(end).(cur_field))
			% report the count of unique values per field
			tmp_list = {session_info_struct(:).(cur_field)};
			if ~iscell(tmp_list)
				tmp_list = {tmp_list};
			end
			tmp_unique = unique(tmp_list);
			total_session_info_struct.(cur_field) = ['N_', num2str(length(tmp_unique))];
		end
		if isnumeric(session_info_struct(end).(cur_field))
			%report the sum
			total_session_info_struct.(cur_field) = sum([session_info_struct(:).(cur_field)], 'omitnan');
			
		end
	end
end
% add the total as a tally at the very end
session_info_struct(end+1) = total_session_info_struct;
combination_count = combination_count + 1;
session_info_struct(end).sort_key_string = [session_struct.session_ID, '_', num2str(combination_count, '%03d')];
session_info_struct(end).record_type = 'TOTAL';


% save out the output as semicolon-separated-values and as excel worksheet
% per sessiondir
% save as matlab struct
save(fullfile(logfile_path, [processed_session_id, '.single_', summary_suffix, '.mat']), 'session_info_struct');
% convert to table
single_session_table = struct2table(session_info_struct);
% save as excel file
writetable(single_session_table, fullfile(logfile_path, [processed_session_id, '.single_', summary_suffix, '.xlsx']));
% save as TXT
writetable(single_session_table, fullfile(logfile_path, [processed_session_id, '.single_', summary_suffix, '.txt']), 'Delimiter', ';');
% save as CSV
writetable(single_session_table, fullfile(logfile_path, [processed_session_id, '.single_', summary_suffix, '.csv']), 'Delimiter', ',');


% return the completed struct?

return
end

