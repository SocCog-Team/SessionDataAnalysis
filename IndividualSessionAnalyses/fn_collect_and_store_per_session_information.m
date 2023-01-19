function [ session_struct ] = fn_collect_and_store_per_session_information( cur_session_logfile_fqn,  cur_cur_output_base_dir, config_name )
%FN_COLLECT_AND_STORE_PER_SESSION_INFORMATION extract information for
%individual sessions and store them into a big table
%   Collect information about sessions about number of trials per trial sub
%   type, number of sucessful trials, number aborted trials agent ID
%	save as CSV and as excel table

% information:

%session ID, trialsubtype, total trials, rewarded trials A, rewarded trials
%B, name A, B, meanRT(A, mean RT(B), Cue type A, B (shuffled/blocked), with
%ephys (ckeck folder), tank id list, is clustered? is analyzed

[logfile_path, logfile_name, log_file_ext] = fileparts(cur_session_logfile_fqn);
session_info = fn_parse_session_id(logfile_name);

[cur_session_logfile_path, cur_session_logfile_name, cur_session_logfile_ext] = fileparts(cur_session_logfile_fqn);


if ~exist(cur_cur_output_base_dir, 'var') || isempty(cur_cur_output_base_dir)
	cur_cur_output_base_dir = fullfile(cur_session_logfile_path, 'ANALYSIS');
end

% load data and TrialSets
[report_struct, TrialSets] = fn_load_triallog(cur_session_logfile_fqn);

% this is primaryly information about whether a cue was visibe and by which
% rule it was selected, it does not show that a subject actually folowed
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
session_struct.date = session_info.YYYYMMDD_string;
session_struct.time = session_info.HHmmSS_string;

% total rewarded trials, total aborted trials?

% gaze traces, touch traces?

% ephys, clustered, analyses

if isfolder(fullfile(logfile_path, 'ANALYSIS'))
	if ~isempty(dir(fullfile(logfile_path, 'ANALYSIS', '*.pdf')))
		session_struct.Analysed = 1;
	end
else
	session_struct.Analysed = 0;
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
			disp(['No trials for ',cur_subject_side_combination, ' ', cur_trialsubtype]);
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
 			
			if (length(fieldnames(session_info_struct)) == 0)
				session_info_struct = cue_randomization_combination_struct;
			else
				session_info_struct(end+1) = cue_randomization_combination_struct;
			end
	
		end
	end
end

% TODO add summary giving the number of different values per string field
% and total trials for trial fields
disp('Doh...');

% save out the output as semicolon-separated-values and as excel worksheet
% per sessiondir


% return the completed struct?

return
end

