function [ TrialSets ] = fnCollectTrialSets( LogStruct )
%FNCOLLECTTRIALSETS Summary of this function goes here
%   Create all interesting subsets of trials
% first collect the basic sets then use set functions to refine to create
% interesting combinations
% it is possible with two actors, that both can cooperate even when one is
% not set for EvaluateTouchPanel, so detect true joint trials by both
% subjects touching the initial target, the main target and getting rewards

TrialSets = [];

if ~isfield(LogStruct, 'data') || isempty(LogStruct.data)
	disp('Encountered trial log file without any logged trials, exiting');
	return;
end

TrialSets.All = (1:1:size(LogStruct.data, 1))';


if (length(TrialSets.All) == 0) || (LogStruct.first_empty_row_idx == 1)
	CurrentSessionFQN = LogStruct.info.logfile_FQN;
	if isfield(LogStruct, 'LoggingInfo')
		if isfield(LogStruct.LoggingInfo, 'SessionFQN')
			CurrentSessionFQN = LogStruct.LoggingInfo.SessionFQN;
		end
	end
	
	disp(['Logfile ', CurrentSessionFQN, ' does not contain any (valid trial) returning...']);
	TrialSets = [];
	return
end

% TrialTypesList = fnUnsortedUnique([LogStruct.unique_lists.A_TrialTypeENUM; LogStruct.unique_lists.B_TrialTypeENUM]);
% for iTrialType = 1 : length(TrialTypesList)
% 	CurrentTrialTypeName = TrialTypesList{iTrialType};
% 	CurrentTrialTypeIdx = iTrialType;
% 	A_TrialsOfCurentTypeIdx = find(LogStruct.data(:, LogStruct.cn.A_TrialTypeENUM_idx) == CurrentTrialTypeIdx);
% 	B_TrialsOfCurentTypeIdx = find(LogStruct.data(:, LogStruct.cn.B_TrialTypeENUM_idx) == CurrentTrialTypeIdx);
% 	TrialSets.ByTrialType.(['A_', CurrentTrialTypeName]) = A_TrialsOfCurentTypeIdx;
% 	TrialSets.ByTrialType.(['B_', CurrentTrialTypeName]) = B_TrialsOfCurentTypeIdx;
% 	TrialSets.ByTrialType.(CurrentTrialTypeName) = union(A_TrialsOfCurentTypeIdx, B_TrialsOfCurentTypeIdx);
% end


% activity (was a side active during a given trial)
% dual subject activity does not necessarily mean joint trials!
TrialSets.ByActivity.SideA.ActiveTrials = find(LogStruct.data(:, LogStruct.cn.A_IsActive));
TrialSets.ByActivity.SideB.ActiveTrials = find(LogStruct.data(:, LogStruct.cn.B_IsActive));

% dual subject trials are always identical for both sides...
TrialSets.ByActivity.DualSubjectTrials = intersect(TrialSets.ByActivity.SideA.ActiveTrials, TrialSets.ByActivity.SideB.ActiveTrials); % these contain trials were only one subject performed the task
TrialSets.ByActivity.SideA.DualSubjectTrials = TrialSets.ByActivity.DualSubjectTrials;
TrialSets.ByActivity.SideB.DualSubjectTrials = TrialSets.ByActivity.DualSubjectTrials;

% SingleSubject trials are different
TrialSets.ByActivity.SingleSubjectTrials = setdiff(TrialSets.All, TrialSets.ByActivity.DualSubjectTrials);
TrialSets.ByActivity.SideA.SingleSubjectTrials = setdiff(TrialSets.ByActivity.SideA.ActiveTrials, TrialSets.ByActivity.SideB.ActiveTrials);
TrialSets.ByActivity.SideB.SingleSubjectTrials = setdiff(TrialSets.ByActivity.SideB.ActiveTrials, TrialSets.ByActivity.SideA.ActiveTrials);

% try to find all trials a subject was active in
TrialSets.ByActivity.SideA.AllTrials = union(TrialSets.ByActivity.SideA.DualSubjectTrials, TrialSets.ByActivity.SideA.SingleSubjectTrials);
TrialSets.ByActivity.SideB.AllTrials = union(TrialSets.ByActivity.SideB.DualSubjectTrials, TrialSets.ByActivity.SideB.SingleSubjectTrials);
TrialSets.ByActivity.AllTrials = union(TrialSets.ByActivity.SideA.AllTrials, TrialSets.ByActivity.SideB.AllTrials);



% these are real joint trials when both subject work together
% test for touching the initial target: (initiated trials)
TmpJointTrialsA = find(LogStruct.data(:, LogStruct.cn.A_InitialFixationTouchTime_ms) > 0);
TmpJointTrialsB = find(LogStruct.data(:, LogStruct.cn.B_InitialFixationTouchTime_ms) > 0);

% restrict this to the initiated trials...
TrialSets.ByActivity.SideA.AllTrials = intersect(TrialSets.ByActivity.SideA.AllTrials, find(LogStruct.data(:, LogStruct.cn.A_InitialFixationTouchTime_ms) > 0));
TrialSets.ByActivity.SideB.AllTrials = intersect(TrialSets.ByActivity.SideB.AllTrials, find(LogStruct.data(:, LogStruct.cn.B_InitialFixationTouchTime_ms) > 0));
TrialSets.ByActivity.AllTrials = union(TrialSets.ByActivity.SideA.AllTrials, TrialSets.ByActivity.SideB.AllTrials);



TrialSets.ByJointness.DualSubjectJointTrials = intersect(TmpJointTrialsA, TmpJointTrialsB);

TrialSets.ByJointness.SideA.SoloSubjectTrials = setdiff(TmpJointTrialsA, TmpJointTrialsB);
TrialSets.ByJointness.SideB.SoloSubjectTrials = setdiff(TmpJointTrialsB, TmpJointTrialsA);

% test for touching the touch target (choice trials)
TmpJointTrialsA = find(LogStruct.data(:, LogStruct.cn.A_TargetTouchTime_ms) > 0);
TrialSets.ByJointness.DualSubjectJointTrials = intersect(TrialSets.ByJointness.DualSubjectJointTrials, TmpJointTrialsA);
TmpJointTrialsB = find(LogStruct.data(:, LogStruct.cn.B_TargetTouchTime_ms) > 0);
TrialSets.ByJointness.DualSubjectJointTrials = intersect(TrialSets.ByJointness.DualSubjectJointTrials, TmpJointTrialsB);

TmpSoloTrialsA = setdiff(TmpJointTrialsA, TmpJointTrialsB);
TmpSoloTrialsB = setdiff(TmpJointTrialsB, TmpJointTrialsA);
TrialSets.ByJointness.SideA.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideA.SoloSubjectTrials, TmpSoloTrialsA);
TrialSets.ByJointness.SideB.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideB.SoloSubjectTrials, TmpSoloTrialsB);

% test for reward, ATTENTION this weeds out SoloARewardAB or SoloBRewardAB
% trials
if (false)
    TmpRewardAOutcomeIdx = find(strcmp('REWARD', LogStruct.unique_lists.A_OutcomeString));
    if ~isempty(TmpRewardAOutcomeIdx)
        TmpJointTrialsA = find(LogStruct.data(:, LogStruct.cn.A_OutcomeString_idx) == TmpRewardAOutcomeIdx);
        TrialSets.ByJointness.DualSubjectJointTrials = intersect(TrialSets.ByJointness.DualSubjectJointTrials, TmpJointTrialsA);
    else
        TmpJointTrialsA = [];
    end
    TmpRewardBOutcomeIdx = find(strcmp('REWARD', LogStruct.unique_lists.B_OutcomeString));
    if ~isempty(TmpRewardBOutcomeIdx)
        TmpJointTrialsB = find(LogStruct.data(:, LogStruct.cn.B_OutcomeString_idx) == TmpRewardBOutcomeIdx);
        TrialSets.ByJointness.DualSubjectJointTrials = intersect(TrialSets.ByJointness.DualSubjectJointTrials, TmpJointTrialsB);
    else
        TmpJointTrialsB = [];
    end
    
    TmpSoloTrialsA = setdiff(TmpJointTrialsA, TmpJointTrialsB);
    TmpSoloTrialsB = setdiff(TmpJointTrialsB, TmpJointTrialsA);
    TrialSets.ByJointness.SideA.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideA.SoloSubjectTrials, TmpSoloTrialsA);
    TrialSets.ByJointness.SideB.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideB.SoloSubjectTrials, TmpSoloTrialsB);
end
% solo trials: two subjects present, single trials only one subject
% active/present
TrialSets.ByJointness.SideA.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideA.SoloSubjectTrials, TrialSets.ByActivity.SideA.DualSubjectTrials);
TrialSets.ByJointness.SideB.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideB.SoloSubjectTrials, TrialSets.ByActivity.SideB.DualSubjectTrials);

% joint trials are always for both sides
TrialSets.ByJointness.SideA.DualSubjectJointTrials = TrialSets.ByJointness.DualSubjectJointTrials;
TrialSets.ByJointness.SideB.DualSubjectJointTrials = TrialSets.ByJointness.DualSubjectJointTrials;

% what to do about the dual subject non-joint trials, with two subjects present and active, but only one working?
TrialSets.ByJointness.DualSubjectSoloTrials = union(TrialSets.ByJointness.SideA.SoloSubjectTrials, TrialSets.ByJointness.SideB.SoloSubjectTrials);

if isfield(LogStruct.Enums, 'RandomizationMethodCodes') && isfield(LogStruct.Enums.RandomizationMethodCodes.unique_lists, 'RandomizationMethodCodes')
    
    % Conf Cue randomisation
    % create % confederate's predictability
    RandomizationMethodCodes_list = LogStruct.Enums.RandomizationMethodCodes.unique_lists.RandomizationMethodCodes;
    
    if isfield(LogStruct.SessionByTrial.cn, 'ConfederateChoiceCueRandomizer_method_A') && isfield(LogStruct.SessionByTrial.cn, 'ConfederateChoiceCueRandomizer_method_B')
        
        ConfChoiceCueRnd_method_A_RandomizationMethodCodes_idx = LogStruct.SessionByTrial.data(:, LogStruct.SessionByTrial.cn.ConfederateChoiceCueRandomizer_method_A) + 1;
        ConfChoiceCue_A_rnd_method_by_trial_list = RandomizationMethodCodes_list(ConfChoiceCueRnd_method_A_RandomizationMethodCodes_idx);
        ConfChoiceCue_A_invisible_idx = find(LogStruct.data(:, LogStruct.cn.A_ShowChoiceHint) == 0);
        ConfChoiceCue_A_rnd_method_by_trial_list(ConfChoiceCue_A_invisible_idx) = RandomizationMethodCodes_list(1);
        ConfChoiceCueRnd_method_B_RandomizationMethodCodes_idx = LogStruct.SessionByTrial.data(:, LogStruct.SessionByTrial.cn.ConfederateChoiceCueRandomizer_method_B) + 1;
        ConfChoiceCue_B_rnd_method_by_trial_list = RandomizationMethodCodes_list(ConfChoiceCueRnd_method_B_RandomizationMethodCodes_idx);
        ConfChoiceCue_B_invisible_idx = find(LogStruct.data(:, LogStruct.cn.B_ShowChoiceHint) == 0);
        ConfChoiceCue_B_rnd_method_by_trial_list(ConfChoiceCue_B_invisible_idx) = RandomizationMethodCodes_list(1);
        
        for i_RandomizationMethodCode = 1 : length(RandomizationMethodCodes_list)
            cur_rnd_method = RandomizationMethodCodes_list{i_RandomizationMethodCode};
            
            TrialSets.ByConfChoiceCue_RndMethod.SideA.(cur_rnd_method) = find(ismember(ConfChoiceCue_A_rnd_method_by_trial_list, {cur_rnd_method}));
            TrialSets.ByConfChoiceCue_RndMethod.SideB.(cur_rnd_method) = find(ismember(ConfChoiceCue_B_rnd_method_by_trial_list, {cur_rnd_method}));
        end
    else
        TrialSets.ByConfChoiceCue_RndMethod = [];
    end
else
    TrialSets.ByConfChoiceCue_RndMethod = [];
end


% TrialTypes
if isfield(LogStruct.unique_lists, 'A_TrialTypeENUM') && isfield(LogStruct.unique_lists, 'B_TrialTypeENUM')
    TrialTypesList = fnUnsortedUnique([LogStruct.unique_lists.A_TrialTypeENUM; LogStruct.unique_lists.B_TrialTypeENUM]);
    for iTrialType = 1 : length(TrialTypesList)
        CurrentTrialTypeName = TrialTypesList{iTrialType};
        CurrentTrialTypeIdx = iTrialType;
        if ~isempty(CurrentTrialTypeIdx)
			A_TrialsOfCurrentTypeIdx = find(LogStruct.data(:, LogStruct.cn.A_TrialTypeENUM_idx) == CurrentTrialTypeIdx);
		else
			A_TrialsOfCurrentTypeIdx = [];
		end
		if ~isempty(CurrentTrialTypeIdx)
			B_TrialsOfCurrentTypeIdx = find(LogStruct.data(:, LogStruct.cn.B_TrialTypeENUM_idx) == CurrentTrialTypeIdx);
		else
			B_TrialsOfCurrentTypeIdx = [];
		end
		TrialSets.ByTrialType.SideA.(CurrentTrialTypeName) = intersect(TrialSets.ByActivity.SideA.AllTrials, A_TrialsOfCurrentTypeIdx);
		TrialSets.ByTrialType.SideB.(CurrentTrialTypeName) = intersect(TrialSets.ByActivity.SideB.AllTrials, B_TrialsOfCurrentTypeIdx);
		%TrialSets.ByTrialType.(CurrentTrialTypeName) = union(A_TrialsOfCurrentTypeIdx, B_TrialsOfCurrentTypeIdx);
		TrialSets.ByTrialType.(CurrentTrialTypeName) = union(TrialSets.ByTrialType.SideA.(CurrentTrialTypeName), TrialSets.ByTrialType.SideB.(CurrentTrialTypeName));
	end
else
	% early data without TrialType records was all DirectFreeGazeReaches
	TrialSets.ByTrialType = [];
	TrialSets.ByTrialType.SideA = [];
	TrialSets.ByTrialType.SideB = [];
	
	% TrialType was introduced on datenum([2017, 3, 15, 0, 0 ,0]
	if (datenum(LogStruct.EventIDEinfo.DateVector) < datenum([2017, 3, 15, 0, 0 ,0]))
		TrialSets.ByTrialType.SideA.DirectFreeGazeReaches = TrialSets.ByActivity.SideA.AllTrials;
		TrialSets.ByTrialType.SideB.DirectFreeGazeReaches = TrialSets.ByActivity.SideB.AllTrials;
		TrialSets.ByTrialType.DirectFreeGazeReaches = union(TrialSets.ByTrialType.SideA.DirectFreeGazeReaches, TrialSets.ByTrialType.SideB.DirectFreeGazeReaches);
	end
end
	
% older log files do not contain the informed choice fields
if ~isfield(TrialSets.ByTrialType, 'DirectFreeGazeReaches')
	TrialSets.ByTrialType.DirectFreeGazeReaches = [];
end
if ~isfield(TrialSets.ByTrialType, 'DirectFreeGazeFreeChoice')
	TrialSets.ByTrialType.DirectFreeGazeFreeChoice = [];
end

% older log files do not contain the informed choice fields
if ~isfield(TrialSets.ByTrialType, 'InformedDirectedReach')
	TrialSets.ByTrialType.InformedDirectedReach = [];
end
if ~isfield(TrialSets.ByTrialType, 'InformedChoice')
	TrialSets.ByTrialType.InformedChoice = [];
end
TrialSets.ByTrialType.InformedTrials = union(TrialSets.ByTrialType.InformedChoice, TrialSets.ByTrialType.InformedDirectedReach);

% TrialSubTypes
%TrialSets.ByTrialSubType.InformedTrials = union(TrialSets.ByTrialType.InformedChoice, TrialSets.ByTrialType.InformedDirectedReach);
if isfield(LogStruct.unique_lists, 'A_TrialSubTypeENUM') || isfield(LogStruct.unique_lists, 'B_TrialSubTypeENUM')
    % ATTENTION the C# ENUM strarts at 0, but the A_TrialSubTypeENUM_idx
    % column already corrected for that by adding 1 to each value to
    % translate into valid matlab indices into 
    
    TrialSubTypesList = fnUnsortedUnique([LogStruct.unique_lists.A_TrialSubTypeENUM; LogStruct.unique_lists.B_TrialSubTypeENUM]);
    for iTrialSubType = 1 : length(TrialSubTypesList)
        CurrentTrialSubTypeName = TrialSubTypesList{iTrialSubType};
        CurrentTrialSubTypeIdx = iTrialSubType;
        if ~isempty(CurrentTrialSubTypeIdx)
            A_TrialsOfCurrentSubTypeIdx = find(LogStruct.data(:, LogStruct.cn.A_TrialSubTypeENUM_idx) == CurrentTrialSubTypeIdx);
        else
            A_TrialsOfCurrentSubTypeIdx = [];
        end
        if ~isempty(CurrentTrialSubTypeIdx)
            B_TrialsOfCurrentSubTypeIdx = find(LogStruct.data(:, LogStruct.cn.B_TrialSubTypeENUM_idx) == CurrentTrialSubTypeIdx);
        else
            B_TrialsOfCurrentSubTypeIdx = [];
        end
        
        %TrialSets.ByTrialSubType.SideA.(CurrentTrialSubTypeName) = A_TrialsOfCurrentTypeIdx;
        %TrialSets.ByTrialSubType.SideB.(CurrentTrialSubTypeName) = B_TrialsOfCurrentTypeIdx;
        %TrialSets.ByTrialSubType.(CurrentTrialSubTypeName) = union(A_TrialsOfCurrentTypeIdx, B_TrialsOfCurrentTypeIdx);
        TrialSets.ByTrialSubType.SideA.(CurrentTrialSubTypeName) = intersect(TrialSets.ByActivity.SideA.AllTrials, A_TrialsOfCurrentSubTypeIdx);
        TrialSets.ByTrialSubType.SideB.(CurrentTrialSubTypeName) = intersect(TrialSets.ByActivity.SideB.AllTrials, B_TrialsOfCurrentSubTypeIdx);
        TrialSets.ByTrialSubType.(CurrentTrialSubTypeName) = union(TrialSets.ByTrialSubType.SideA.(CurrentTrialSubTypeName), TrialSets.ByTrialSubType.SideB.(CurrentTrialSubTypeName));
    end
    
else
    % old style triallog without TrialSubType information, fill in the obvious
    %TmpChoiceTrials = union(TrialSets.ByTrialType.DirectFreeGazeFreeChoice, TrialSets.ByTrialType.InformedChoice);
    TrialSets.ByTrialSubType.None = []; % leave empty
    %Up unitl now all we only used SoloA, SoloB, and Dyadic
    TrialSets.ByTrialSubType.SoloA = setdiff(TrialSets.ByActivity.SideA.AllTrials, TrialSets.ByActivity.SideB.AllTrials);	
    TrialSets.ByTrialSubType.SideA.SoloA = TrialSets.ByTrialSubType.SoloA;	
    TrialSets.ByTrialSubType.SideB.SoloA = [];		
	
    TrialSets.ByTrialSubType.SoloB = setdiff(TrialSets.ByActivity.SideB.AllTrials, TrialSets.ByActivity.SideA.AllTrials);
    TrialSets.ByTrialSubType.SideA.SoloB = [];	
    TrialSets.ByTrialSubType.SideB.SoloB = TrialSets.ByTrialSubType.SoloB;	
	
	TrialSets.ByTrialSubType.SemiSolo = []; % leave empty, does not exist in old pre-TrialSubType data
    TrialSets.ByTrialSubType.Dyadic = intersect(TrialSets.ByActivity.SideB.AllTrials, TrialSets.ByActivity.SideA.AllTrials);
	TrialSets.ByTrialSubType.SideA.Dyadic = TrialSets.ByTrialSubType.Dyadic;
	TrialSets.ByTrialSubType.SideB.Dyadic = TrialSets.ByTrialSubType.Dyadic;
end

% ByName
% get the lists of names per trial, ATTENTION, this requires names to by
% valid matlab parameters, so they can not start with a number, but human
% IDs are numberbased, so prefix by "id"
SideA_agent_list = strcat({'id'}, LogStruct.unique_lists.A_Name(LogStruct.data(:, LogStruct.cn.A_Name_idx)));
if size(SideA_agent_list, 1) < size(SideA_agent_list, 2)
	SideA_agent_list = SideA_agent_list';
end
SideB_agent_list = strcat({'id'}, LogStruct.unique_lists.B_Name(LogStruct.data(:, LogStruct.cn.B_Name_idx)));
if size(SideB_agent_list, 1) < size(SideB_agent_list, 2)
	SideB_agent_list = SideB_agent_list';
end


% remove the agent for single/solo trials (but keep)
proto_solo_trialsubtype_list = fieldnames(TrialSets.ByTrialSubType);
solo_trialsubtype_list = proto_solo_trialsubtype_list(ismember(proto_solo_trialsubtype_list, {'SoloA', 'SoloB', 'SoloAHighReward', 'SoloBHighReward', 'SoloABlockedView', 'SoloBBlockedView'}));
for i_solo_sst = 1 : length(solo_trialsubtype_list)
	cur_solo_trialsubtype = solo_trialsubtype_list{i_solo_sst};
	if ~isempty(strfind(cur_solo_trialsubtype, 'SoloB'))
		SideA_agent_list(TrialSets.ByTrialSubType.(cur_solo_trialsubtype)) = {'None'};
	end
	if ~isempty(strfind(cur_solo_trialsubtype, 'SoloA'))
		SideB_agent_list(TrialSets.ByTrialSubType.(cur_solo_trialsubtype)) = {'None'};
	end
end
SubjectCombination_list = strcat(SideA_agent_list, '_', SideB_agent_list);
[unique_subject_combinations, ~, subject_combination_trial_idx] = unique(SubjectCombination_list);
for i_subject_combination = 1 : length(unique_subject_combinations)
	TrialSets.ByName.Combinations.(unique_subject_combinations{i_subject_combination}) = find(subject_combination_trial_idx == i_subject_combination);
end
[unique_SideA_list, ~, SideA_trial_idx] = unique(SideA_agent_list);
for i_SideA = 1 : length(unique_SideA_list)
	TrialSets.ByName.SideA.(unique_SideA_list{i_SideA}) = find(SideA_trial_idx == i_SideA);
end
[unique_SideB_list, ~, SideB_trial_idx] = unique(SideB_agent_list);
for i_SideB = 1 : length(unique_SideB_list)
	TrialSets.ByName.SideB.(unique_SideB_list{i_SideB}) = find(SideB_trial_idx == i_SideB);
end




% was there a separator between the players
% since the separation might by direction (if using the OLED) A_invisible
% does not require B_invisible at the same time.
% this assumes that without [A|B]_invisible being set, everything was
% visible through the transparent screen.
if (isfield(LogStruct.cn, 'A_invisible'))
	TrialSets.ByVisibility.SideA.A_invisible = find(LogStruct.data(:, LogStruct.cn.A_invisible) == 1);
else
	TrialSets.ByVisibility.SideA.A_invisible = [];
end
if (isfield(LogStruct.cn, 'B_invisible'))
	TrialSets.ByVisibility.SideB.B_invisible = find(LogStruct.data(:, LogStruct.cn.B_invisible) == 1);
else
	TrialSets.ByVisibility.SideB.B_invisible = [];
end
% since A_invisible is not necessarily equal to B_invisible
TrialSets.ByVisibility.AB_invisible = intersect(TrialSets.ByVisibility.SideA.A_invisible, TrialSets.ByVisibility.SideB.B_invisible);

% create BlockedView trialSubTypes
if ~isempty(intersect(TrialSets.ByVisibility.AB_invisible, TrialSets.ByTrialSubType.Dyadic)) ...
	|| ~isempty(intersect(TrialSets.ByVisibility.AB_invisible, TrialSets.ByTrialSubType.SoloA)) ...
	|| ~isempty(intersect(TrialSets.ByVisibility.AB_invisible, TrialSets.ByTrialSubType.SoloB))
	% missing BlockedView tTrialSubType
	
	invisible_Dyadic_idx = intersect(TrialSets.ByVisibility.AB_invisible, TrialSets.ByTrialSubType.Dyadic);
	if ~isempty(invisible_Dyadic_idx)
		TrialSets.ByTrialSubType.Dyadic = setdiff(TrialSets.ByTrialSubType.Dyadic, invisible_Dyadic_idx);
		TrialSets.ByTrialSubType.DyadicBlockedView = invisible_Dyadic_idx;
		TrialSets.ByTrialSubType.SideA.Dyadic	= TrialSets.ByTrialSubType.Dyadic;
		TrialSets.ByTrialSubType.SideA.DyadicBlockedView	= TrialSets.ByTrialSubType.DyadicBlockedView;
		TrialSets.ByTrialSubType.SideB.Dyadic	= TrialSets.ByTrialSubType.Dyadic;		
		TrialSets.ByTrialSubType.SideB.DyadicBlockedView	= TrialSets.ByTrialSubType.DyadicBlockedView;			
	end
	
	invisible_SoloA_idx = intersect(TrialSets.ByVisibility.AB_invisible, TrialSets.ByTrialSubType.SoloA);
	if ~isempty(invisible_SoloA_idx)
		TrialSets.ByTrialSubType.SoloA = setdiff(TrialSets.ByTrialSubType.SoloA, invisible_SoloA_idx);
		TrialSets.ByTrialSubType.SoloABlockedView = invisible_SoloA_idx;	
		TrialSets.ByTrialSubType.SideA.SoloA = TrialSets.ByTrialSubType.SoloA;
		TrialSets.ByTrialSubType.SideA.SoloABlockedView	= TrialSets.ByTrialSubType.SoloABlockedView;
		TrialSets.ByTrialSubType.SideB.SoloA = [];		
		TrialSets.ByTrialSubType.SideB.SoloABlockedView	= [];			
	end	

	invisible_SoloB_idx = intersect(TrialSets.ByVisibility.AB_invisible, TrialSets.ByTrialSubType.SoloB);
	if ~isempty(invisible_SoloA_idx)
		TrialSets.ByTrialSubType.SoloB = setdiff(TrialSets.ByTrialSubType.SoloA, invisible_SoloB_idx);
		TrialSets.ByTrialSubType.SoloBBlockedView = invisible_SoloB_idx;	
		TrialSets.ByTrialSubType.SideA.SoloB = [];		
		TrialSets.ByTrialSubType.SideA.SoloBBlockedView	= [];			
		TrialSets.ByTrialSubType.SideB.SoloB = TrialSets.ByTrialSubType.SoloA;
		TrialSets.ByTrialSubType.SideB.SoloBBlockedView	= TrialSets.ByTrialSubType.SoloBBlockedView;
	end	
end

% 




% create the list of choice trials
% TODO use the information about the stimulus renderer instead to be
% agnostic of TrialType?
TrialSets.ByChoices.NumChoices01 = union(TrialSets.ByTrialType.DirectFreeGazeReaches, TrialSets.ByTrialType.InformedDirectedReach);
TrialSets.ByChoices.NumChoices02 = union(TrialSets.ByTrialType.DirectFreeGazeFreeChoice, TrialSets.ByTrialType.InformedChoice);


% in the simple instructed reach and choice paradigms there is no true
% false response, but trials in which the targets were actually visible
% might be counted as misses
% was the initial fixation target visible:
TrialSets.ByTargetVisibility.SideA.InitialFixationTargetVisible = find(LogStruct.data(:, LogStruct.cn.A_InitialFixationOnsetTime_ms) > 0);
TrialSets.ByTargetVisibility.SideB.InitialFixationTargetVisible = find(LogStruct.data(:, LogStruct.cn.A_InitialFixationOnsetTime_ms) > 0);
TrialSets.ByTargetVisibility.InitialFixationTargetVisible = union(TrialSets.ByTargetVisibility.SideA.InitialFixationTargetVisible, TrialSets.ByTargetVisibility.SideB.InitialFixationTargetVisible);
% was the final touch target visible:
TrialSets.ByTargetVisibility.SideA.TouchTargetVisible = find(LogStruct.data(:, LogStruct.cn.A_TargetOnsetTime_ms) > 0);
TrialSets.ByTargetVisibility.SideB.TouchTargetVisible = find(LogStruct.data(:, LogStruct.cn.A_TargetOnsetTime_ms) > 0);
TrialSets.ByTargetVisibility.TouchTargetVisible = union(TrialSets.ByTargetVisibility.SideA.TouchTargetVisible, TrialSets.ByTargetVisibility.SideB.TouchTargetVisible);



OutcomesList = fnUnsortedUnique([LogStruct.unique_lists.A_OutcomeENUM; LogStruct.unique_lists.B_OutcomeENUM]);
for iOutcome = 1 : length(OutcomesList)
	CurrentOutcomeName = OutcomesList{iOutcome};
	CurrentOutcomeIdx = iOutcome;
	
	if ~isempty(CurrentOutcomeIdx)
		A_TrialsOfCurrentOutcomeIdx = find(LogStruct.data(:, LogStruct.cn.A_OutcomeENUM_idx) == CurrentOutcomeIdx);
	else
		A_TrialsOfCurrentOutcomeIdx = [];
	end
	if ~isempty(CurrentOutcomeIdx)
		B_TrialsOfCurrentOutcomeIdx = find(LogStruct.data(:, LogStruct.cn.B_OutcomeENUM_idx) == CurrentOutcomeIdx);
	else
		B_TrialsOfCurrentOutcomeIdx = [];
	end
	TrialSets.ByOutcome.SideA.(CurrentOutcomeName) = A_TrialsOfCurrentOutcomeIdx;
	TrialSets.ByOutcome.SideB.(CurrentOutcomeName) = B_TrialsOfCurrentOutcomeIdx;
	TrialSets.ByOutcome.(CurrentOutcomeName) = union(A_TrialsOfCurrentOutcomeIdx, B_TrialsOfCurrentOutcomeIdx);
end


% A_ReachEffectorENUM: {'none'  'left'  'not_left'  'right'  'not_right'  'both'  'not_both'}
% B_ReachEffectorENUM: {'none'  'left'  'not_left'  'right'  'not_right'  'both'  'not_both'}
ReachEffectorsList = fnUnsortedUnique([LogStruct.unique_lists.A_ReachEffectorENUM; LogStruct.unique_lists.B_ReachEffectorENUM]);
for iEffector = 1 : length(ReachEffectorsList)
	CurrentEffectorName = ReachEffectorsList{iEffector};
	CurrentEffectorIdx = iEffector;
	
	if ~isempty(CurrentEffectorIdx)
		A_TrialsOfCurrentEffectorIdx = find(LogStruct.data(:, LogStruct.cn.A_ReachEffectorENUM_idx) == CurrentEffectorIdx);
	else
		A_TrialsOfCurrentEffectorIdx = [];
	end
	if ~isempty(CurrentEffectorIdx)
		B_TrialsOfCurrentEffectorIdx = find(LogStruct.data(:, LogStruct.cn.B_ReachEffectorENUM_idx) == CurrentEffectorIdx);
	else
		B_TrialsOfCurrentEffectorIdx = [];
	end
	TrialSets.ByEffector.SideA.(CurrentEffectorName) = intersect(A_TrialsOfCurrentEffectorIdx, TrialSets.ByActivity.SideA.ActiveTrials);
	TrialSets.ByEffector.SideB.(CurrentEffectorName) = intersect(B_TrialsOfCurrentEffectorIdx, TrialSets.ByActivity.SideB.ActiveTrials);
	TrialSets.ByEffector.(CurrentEffectorName) = union(A_TrialsOfCurrentEffectorIdx, B_TrialsOfCurrentEffectorIdx);
end



if isfield(LogStruct.unique_lists, 'A_RewardFunctionENUM') && isfield(LogStruct.unique_lists, 'B_RewardFunctionENUM')
	RewardFunctionsList = fnUnsortedUnique([LogStruct.unique_lists.A_RewardFunctionENUM; LogStruct.unique_lists.B_RewardFunctionENUM]);
	
	for iRewardFunction = 1 : length(RewardFunctionsList)
		CurrentRewardFunctionName = RewardFunctionsList{iRewardFunction};
		CurrentRewardFunctionIdx = iRewardFunction;
		
		if ~isempty(CurrentRewardFunctionIdx)
			A_TrialsOfCurrentRewardFunctionIdx = find(LogStruct.data(:, LogStruct.cn.A_RewardFunctionENUM_idx) == CurrentRewardFunctionIdx);
		else
			A_TrialsOfCurrentRewardFunctionIdx = [];
		end
		if ~isempty(CurrentRewardFunctionIdx)
			B_TrialsOfCurrentRewardFunctionIdx = find(LogStruct.data(:, LogStruct.cn.B_RewardFunctionENUM_idx) == CurrentRewardFunctionIdx);
		else
			B_TrialsOfCurrentRewardFunctionIdx = [];
		end
		TrialSets.ByRewardFunction.SideA.(CurrentRewardFunctionName) = A_TrialsOfCurrentRewardFunctionIdx;
		TrialSets.ByRewardFunction.SideB.(CurrentRewardFunctionName) = B_TrialsOfCurrentRewardFunctionIdx;
		TrialSets.ByRewardFunction.(CurrentRewardFunctionName) = union(A_TrialsOfCurrentRewardFunctionIdx, B_TrialsOfCurrentRewardFunctionIdx);
	end
else
	% old experiments only had reward specification by side in the GUI
	RewardFunctionsList = {'GUI'}';
	TrialSets.ByRewardFunction.SideA.GUI = TrialSets.All;
	TrialSets.ByRewardFunction.SideB.GUI = TrialSets.All;
	TrialSets.ByRewardFunction.GUI = TrialSets.All;
end

if isfield(LogStruct, 'SessionByTrial')
	if isfield(LogStruct.SessionByTrial, 'unique_lists') && isfield(LogStruct.SessionByTrial.unique_lists, 'TouchTargetPositioningMethod')
		ByTouchTargetPositioningMethodList = LogStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod;
		for iTouchTargetPositioningMethod = 1 : length(ByTouchTargetPositioningMethodList)
			CurrentTouchTargetPositioningMethod = ByTouchTargetPositioningMethodList{iTouchTargetPositioningMethod};
			CurrentTouchTargetPositioningMethodIdx = iTouchTargetPositioningMethod;
			
			% currently these are indentical for both sides, if they ever
			% will be different by side, the information needs to be
			% relocated into the per subject part of the report.
			TrialsOfCurrentTouchTargetPositioningMethodIdx = find(LogStruct.SessionByTrial.data(:, LogStruct.SessionByTrial.cn.TouchTargetPositioningMethod_idx) == CurrentTouchTargetPositioningMethodIdx);
			TrialSets.ByTouchTargetPositioningMethod.SideA.(CurrentTouchTargetPositioningMethod) = TrialsOfCurrentTouchTargetPositioningMethodIdx;
			TrialSets.ByTouchTargetPositioningMethod.SideB.(CurrentTouchTargetPositioningMethod) = TrialsOfCurrentTouchTargetPositioningMethodIdx;
			TrialSets.ByTouchTargetPositioningMethod.(CurrentTouchTargetPositioningMethod) = TrialsOfCurrentTouchTargetPositioningMethodIdx;
			
		end
	end
end



% get the active subject(s)
%ActiveSubjectsList = fnGetActiveSubjects(LogStruct);

% get the names, create a subset per name (exclude None)
NamesList = fnUnsortedUnique([LogStruct.unique_lists.A_Name, LogStruct.unique_lists.B_Name]);
for iName = 1: length(NamesList)
	% ignore None
	if (strcmp(NamesList{iName}, 'None'))
		continue
	end
	CurrentName = NamesList{iName};
	StoredName = CurrentName;
	
	% since we want to use the name as a matlab fieldname we need to do
	% some cleanup
	CurrentName  = sanitize_field_name_for_matlab(CurrentName, 'ID');
	
	if (~strcmp(CurrentName, StoredName))
		% we changed the name now fix up the list...
		UniqueA_NameIdx = find(strcmp(NamesList{iName}, LogStruct.unique_lists.A_Name));
		if ~isempty(UniqueA_NameIdx)
			LogStruct.unique_lists.A_Name{UniqueA_NameIdx} = CurrentName;
		end
		UniqueB_NameIdx = find(strcmp(NamesList{iName}, LogStruct.unique_lists.B_Name));
		if ~isempty(UniqueB_NameIdx)
			LogStruct.unique_lists.B_Name{UniqueB_NameIdx} = CurrentName;
		end
	end
	
	
	A_CurrentNameIdx = find(ismember(LogStruct.unique_lists.A_Name, CurrentName));
	B_CurrentNameIdx = find(ismember(LogStruct.unique_lists.B_Name, CurrentName));
	
	if ~isempty(A_CurrentNameIdx)
		A_TrialsOfCurrentNameIdx = find(LogStruct.data(:, LogStruct.cn.A_Name_idx) == A_CurrentNameIdx);
	else
		A_TrialsOfCurrentNameIdx = [];
	end
	if ~isempty(B_CurrentNameIdx)
		B_TrialsOfCurrentNameIdx = find(LogStruct.data(:, LogStruct.cn.B_Name_idx) == B_CurrentNameIdx);
	else
		B_TrialsOfCurrentNameIdx = [];
	end
	% all numeric subject codes will not work as structure fieldnames, so
	% add a prefix so the name
	
	TrialSets.ByName.SideA.(CurrentName) = A_TrialsOfCurrentNameIdx;
	TrialSets.ByName.SideB.(CurrentName) = B_TrialsOfCurrentNameIdx;
	TrialSets.ByName.(CurrentName) = union(A_TrialsOfCurrentNameIdx, B_TrialsOfCurrentNameIdx);
end

% Magnus always uses his right hand independent of the effector code
% so make sure Magnus effector trials with EvaluateProximitySensors = 0 are
% accounted as left.
if isfield(TrialSets.ByName, 'Magnus')
	if isfield(TrialSets.ByName.SideA, 'Magnus')
		MagnusTrialSideAIdx = TrialSets.ByName.SideA.Magnus; % these are all left trials
		TrialSets.ByEffector.SideA.left = union(TrialSets.ByEffector.SideA.left, MagnusTrialSideAIdx);
		TrialSets.ByEffector.SideA.right = setdiff(TrialSets.ByEffector.SideA.right, MagnusTrialSideAIdx);
	end
	if isfield(TrialSets.ByName.SideB, 'Magnus')
		MagnusTrialSideBIdx = TrialSets.ByName.SideB.Magnus; % these are all left trials
		TrialSets.ByEffector.SideB.left = union(TrialSets.ByEffector.SideB.left, MagnusTrialSideBIdx);
		TrialSets.ByEffector.SideB.right = setdiff(TrialSets.ByEffector.SideB.right, MagnusTrialSideBIdx);
	end
	TrialSets.ByEffector.left = union(TrialSets.ByEffector.SideA.left, TrialSets.ByEffector.SideB.left);
	TrialSets.ByEffector.right = union(TrialSets.ByEffector.SideA.right, TrialSets.ByEffector.SideB.right);
	if ~isempty(LogStruct.LoggingInfo) && isfield(LogStruct.LoggingInfo, 'SessionFQN')
		disp([LogStruct.LoggingInfo.SessionFQN, ': fixed up effector hand for Magnus']);
	else
		disp([LogStruct.info.logfile_FQN, ': fixed up effector hand for Magnus']);
	end
end




% generate indices for: targetposition, choice position, rewards-payout (target preference)
% get the choice preference choice is always by side
EqualPositionSlackPixels = 2;	% how many pixels two position are allowed to differ while still accounted as same, this is required as the is some rounding error in earlier code that produces of by one positions

A_LeftChoiceIdx = find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_X) > LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X));
A_RightChoiceIdx = find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_X) < LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X));
% remove trials when the side was not playing
A_LeftChoiceIdx = intersect(A_LeftChoiceIdx, TrialSets.ByActivity.SideA.AllTrials);
A_RightChoiceIdx = intersect(A_RightChoiceIdx, TrialSets.ByActivity.SideA.AllTrials);

TrialSets.ByChoice.SideA.ChoiceLeft = A_LeftChoiceIdx;
TrialSets.ByChoice.SideA.ChoiceRight = A_RightChoiceIdx;
% allow some slack for improper rounding errors
TrialSets.ByChoice.SideA.ChoiceCenterX = find(abs(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_X) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels);
TrialSets.ByChoice.SideA.ChoiceCenterX = intersect(TrialSets.ByChoice.SideA.ChoiceCenterX, TrialSets.ByActivity.SideA.AllTrials);
TrialSets.ByChoice.SideA.ChoiceScreenFromALeft = A_LeftChoiceIdx;
TrialSets.ByChoice.SideA.ChoiceScreenFromARight = A_RightChoiceIdx;

B_LeftChoiceIdx = find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_X) < LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X));
B_RightChoiceIdx = find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_X) > LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X));

B_LeftChoiceIdx = intersect(B_LeftChoiceIdx, TrialSets.ByActivity.SideB.AllTrials);
B_RightChoiceIdx = intersect(B_RightChoiceIdx, TrialSets.ByActivity.SideB.AllTrials);


TrialSets.ByChoice.SideB.ChoiceLeft = B_LeftChoiceIdx;
TrialSets.ByChoice.SideB.ChoiceRight = B_RightChoiceIdx;
% allow some slack for improper rounding errors
TrialSets.ByChoice.SideB.ChoiceCenterX = find(abs(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_X) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels);
TrialSets.ByChoice.SideB.ChoiceCenterX = intersect(TrialSets.ByChoice.SideB.ChoiceCenterX, TrialSets.ByActivity.SideB.AllTrials);
% for Side B the subjective choice sides are flipped as seen from side A in
% eventide screen coordinates
TrialSets.ByChoice.SideB.ChoiceScreenFromALeft = B_RightChoiceIdx;
TrialSets.ByChoice.SideB.ChoiceScreenFromARight = B_LeftChoiceIdx;

% create indices for up down positions as well, note top left corner is
% 0,0, bottom right is 1920,1080
TrialSets.ByChoice.SideA.ChoiceTop = intersect(find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_Y) > LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y)), TrialSets.ByActivity.SideA.AllTrials);
TrialSets.ByChoice.SideA.ChoiceBottom = intersect(find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_Y) < LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y)), TrialSets.ByActivity.SideA.AllTrials);
TrialSets.ByChoice.SideA.ChoiceCenterY = intersect(find(abs(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_Y) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels), TrialSets.ByActivity.SideA.AllTrials);
TrialSets.ByChoice.SideB.ChoiceTop = intersect(find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_Y) > LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y)), TrialSets.ByActivity.SideB.AllTrials);
TrialSets.ByChoice.SideB.ChoiceBottom = intersect(find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_Y) < LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y)), TrialSets.ByActivity.SideB.AllTrials);
TrialSets.ByChoice.SideB.ChoiceCenterY = intersect(find(abs(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_Y) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels), TrialSets.ByActivity.SideB.AllTrials);
%TODO prune to TrialSets.ByActivity.SideA.AllTrials TrialSets.ByActivity.SideB.AllTrial



% Extract information about the selected target reward value (assume only two values for now)
if (isfield(TrialSets.ByRewardFunction, 'BOSMATRIXV01'))
	DifferentialRewardedTrialsIdx = TrialSets.ByRewardFunction.BOSMATRIXV01;
end
% note that for the DirectFreeGazeReaches trials we store the randomised
% position as the selected.
if isfield(LogStruct.cn, 'A_RandomizedTargetPosition_Y') && isfield(LogStruct.cn, 'A_RandomizedTargetPosition_X')
	A_SelectedTargetEqualsRandomizedTargetTrialIdx = find((abs(LogStruct.data(:, LogStruct.cn.A_RandomizedTargetPosition_Y) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels) & (abs(LogStruct.data(:, LogStruct.cn.A_RandomizedTargetPosition_X) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels));
else
	A_SelectedTargetEqualsRandomizedTargetTrialIdx = [];
end
if isfield(LogStruct.cn, 'B_RandomizedTargetPosition_Y') && isfield(LogStruct.cn, 'B_RandomizedTargetPosition_X')
	B_SelectedTargetEqualsRandomizedTargetTrialIdx = find((abs(LogStruct.data(:, LogStruct.cn.B_RandomizedTargetPosition_Y) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels) & (abs(LogStruct.data(:, LogStruct.cn.B_RandomizedTargetPosition_X) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels));
else
	B_SelectedTargetEqualsRandomizedTargetTrialIdx = [];
end

% now only take those trials in which a subject actually touched the target
A_SelectedTargetEqualsRandomizedTargetTrialIdx = intersect(A_SelectedTargetEqualsRandomizedTargetTrialIdx, find(LogStruct.data(:, LogStruct.cn.A_TargetTouchTime_ms) > 0.0));
B_SelectedTargetEqualsRandomizedTargetTrialIdx = intersect(B_SelectedTargetEqualsRandomizedTargetTrialIdx, find(LogStruct.data(:, LogStruct.cn.B_TargetTouchTime_ms) > 0.0));

A_SelectedTargetEqualsRandomizedTargetTrialIdx = intersect(A_SelectedTargetEqualsRandomizedTargetTrialIdx, TrialSets.ByActivity.SideA.AllTrials);
B_SelectedTargetEqualsRandomizedTargetTrialIdx = intersect(B_SelectedTargetEqualsRandomizedTargetTrialIdx, TrialSets.ByActivity.SideB.AllTrials);


% keep the randomisation information, to allow fake by value analysis for
% freechoice trials to compare against left right and against informed
% trials
TrialSets.ByChoice.SideA.ProtoTargetValueHigh = A_SelectedTargetEqualsRandomizedTargetTrialIdx; % here the randomized position equals higher payoff
TrialSets.ByChoice.SideA.ProtoTargetValueLow = intersect(setdiff(TrialSets.All, A_SelectedTargetEqualsRandomizedTargetTrialIdx), TrialSets.ByActivity.SideA.AllTrials);
TrialSets.ByChoice.SideB.ProtoTargetValueHigh = intersect(setdiff(TrialSets.All, B_SelectedTargetEqualsRandomizedTargetTrialIdx), TrialSets.ByActivity.SideB.AllTrials);
TrialSets.ByChoice.SideB.ProtoTargetValueLow = B_SelectedTargetEqualsRandomizedTargetTrialIdx; % here the randomized position equals lower payoff

% here only add trials that are used a target value indicator
TrialSets.ByChoice.SideA.TargetValueHigh = intersect(TrialSets.ByTrialType.InformedTrials, A_SelectedTargetEqualsRandomizedTargetTrialIdx); % here the randomized position equals higher payoff
TrialSets.ByChoice.SideA.TargetValueLow = intersect(intersect(TrialSets.ByTrialType.InformedTrials, setdiff(TrialSets.All, A_SelectedTargetEqualsRandomizedTargetTrialIdx)), TrialSets.ByActivity.SideA.AllTrials);
TrialSets.ByChoice.SideB.TargetValueHigh = intersect(intersect(TrialSets.ByTrialType.InformedTrials, setdiff(TrialSets.All, B_SelectedTargetEqualsRandomizedTargetTrialIdx)), TrialSets.ByActivity.SideB.AllTrials);
TrialSets.ByChoice.SideB.TargetValueLow = intersect(TrialSets.ByTrialType.InformedTrials, B_SelectedTargetEqualsRandomizedTargetTrialIdx); % here the randomized position equals lower payoff

%TODO make sure that the higher rewarded trials are truely from trials
%using a differential RewardFunction.

% the combined value choices of the current trial
TrialSets.ByChoice.JointChoices.TargetValue_HighLow = intersect(TrialSets.ByChoice.SideA.TargetValueHigh, TrialSets.ByChoice.SideB.TargetValueLow);
TrialSets.ByChoice.JointChoices.TargetValue_HighHigh = intersect(TrialSets.ByChoice.SideA.TargetValueHigh, TrialSets.ByChoice.SideB.TargetValueHigh);
TrialSets.ByChoice.JointChoices.TargetValue_LowLow = intersect(TrialSets.ByChoice.SideA.TargetValueLow, TrialSets.ByChoice.SideB.TargetValueLow);
TrialSets.ByChoice.JointChoices.TargetValue_LowHigh = intersect(TrialSets.ByChoice.SideA.TargetValueLow, TrialSets.ByChoice.SideB.TargetValueHigh);

% the combined value choices of the last choice trial (coded for BoS reward value as seen from A)
%tmp_joint_selection_code_list = zeros(length(TrialSets.ByTrialType.InformedTrials)); % zero means not assigned and we ignore it later

tmp_joint_selection_code_list = zeros(size(TrialSets.All)); % remaining zeros denote trials to be ignored
tmp_joint_selection_code_list(TrialSets.ByChoice.JointChoices.TargetValue_LowLow) = 1;
tmp_joint_selection_code_list(TrialSets.ByChoice.JointChoices.TargetValue_HighHigh) = 2;
tmp_joint_selection_code_list(TrialSets.ByChoice.JointChoices.TargetValue_LowHigh) = 3;
tmp_joint_selection_code_list(TrialSets.ByChoice.JointChoices.TargetValue_HighLow) = 4;
% the last trial will not have a successor
tmp_joint_selection_code_list(end) = [];
for i_joint_selection_code = 1 : 4
	
	% these are InformedTrials as JointChoices are restricted to
	% InformedTrials
	proto_tmp_idx = find(tmp_joint_selection_code_list == i_joint_selection_code);
	
	% for each indexed trial we need to find the following InformedTrials
	% trial index
	trial_following_joint_selection_code_idx = [];
	for i_proto_tmp_idx = 1: length(proto_tmp_idx)
		current_proto_idx = proto_tmp_idx(i_proto_tmp_idx);
		% find the current trial
		current_trial_InformedTrials_idx = find(TrialSets.ByTrialType.InformedTrials == current_proto_idx);
		if ~isempty(current_trial_InformedTrials_idx) && (length(TrialSets.ByTrialType.InformedTrials) >= (current_trial_InformedTrials_idx + 1))
			trial_following_joint_selection_code_idx(end+1) = TrialSets.ByTrialType.InformedTrials(current_trial_InformedTrials_idx + 1);
		end
	end
	% re
	tmp_idx = intersect(proto_tmp_idx, TrialSets.ByTrialType.InformedTrials);
	
	switch i_joint_selection_code
		case 1
			TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_LowLow = trial_following_joint_selection_code_idx';
		case 2
			TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_HighHigh = trial_following_joint_selection_code_idx';
		case 3
			TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_LowHigh = trial_following_joint_selection_code_idx';
		case 4
			TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_HighLow = trial_following_joint_selection_code_idx';
	end
end

% find instances when individual agents changed their value choice
tmp_same_LL_idx = intersect(TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_LowLow, TrialSets.ByChoice.JointChoices.TargetValue_LowLow);
tmp_same_HH_idx = intersect(TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_HighHigh, TrialSets.ByChoice.JointChoices.TargetValue_HighHigh);
tmp_same_LH_idx = intersect(TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_LowHigh, TrialSets.ByChoice.JointChoices.TargetValue_LowHigh);
tmp_same_HL_idx = intersect(TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_HighLow, TrialSets.ByChoice.JointChoices.TargetValue_HighLow);
% these are the trials with =exact same joint choces as the last informed trial
TrialSets.ByChoice.JointChoices.LastTrial_SameValue = sort([tmp_same_LL_idx; tmp_same_HH_idx; tmp_same_LH_idx; tmp_same_HL_idx]);
% find instances when individual agents changed their value choice
tmp_diff_LL_idx = setdiff(TrialSets.ByChoice.JointChoices.TargetValue_LowLow, TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_LowLow);
tmp_diff_HH_idx = setdiff(TrialSets.ByChoice.JointChoices.TargetValue_HighHigh, TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_HighHigh);
tmp_diff_LH_idx = setdiff(TrialSets.ByChoice.JointChoices.TargetValue_LowHigh, TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_LowHigh);
tmp_diff_HL_idx = setdiff(TrialSets.ByChoice.JointChoices.TargetValue_HighLow, TrialSets.ByChoice.JointChoices.LastTrial_TargetValue_HighLow);
% these are the trials with =exact same joint choces as the last informed trial
TrialSets.ByChoice.JointChoices.LastTrial_DifferentValue = sort([tmp_diff_LL_idx; tmp_diff_HH_idx; tmp_diff_LH_idx; tmp_diff_HL_idx]);

% the first trial does not have one earlier so remove from set, note both
% are sorted already
if length(TrialSets.ByChoice.JointChoices.LastTrial_DifferentValue) > 0 && length(TrialSets.ByChoice.JointChoices.LastTrial_SameValue) > 0
	if TrialSets.ByChoice.JointChoices.LastTrial_DifferentValue(1) < TrialSets.ByChoice.JointChoices.LastTrial_SameValue(1)
		TrialSets.ByChoice.JointChoices.LastTrial_DifferentValue(1) = [];
	else
		TrialSets.ByChoice.JointChoices.LastTrial_SameValue(1) = [];
	end	
end


% TrialSets.ByChoice.JointChoices.SideA.LastTrial_DifferentValue
% TrialSets.ByChoice.JointChoices.SideB.LastTrial_DifferentValue
% TrialSets.ByChoice.JointChoices.LastTrial_DifferentValue


% whether the same target position was touched
TmpSameYIdx = find(LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y) == LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y));
TmpSameXIdX = find(LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X) == LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X));
TmpSameIdx = intersect(TmpSameXIdX, TmpSameYIdx);
% target was actually shown?
TmpSameIdx = intersect(TmpSameIdx, TrialSets.ByTargetVisibility.SideA.TouchTargetVisible);
TmpSameIdx = intersect(TmpSameIdx, TrialSets.ByTargetVisibility.SideB.TouchTargetVisible);

% only report if both subjects made a choice
TmpSameIdx = intersect(TmpSameIdx, find(LogStruct.data(:, LogStruct.cn.A_TargetTouchTime_ms) > 0.0));
TmpSameIdx = intersect(TmpSameIdx, find(LogStruct.data(:, LogStruct.cn.B_TargetTouchTime_ms) > 0.0));

% only report real joint trials
% note all three should be identical...
TrialSets.ByChoice.SideA.SameTarget = intersect(TmpSameIdx, TrialSets.ByJointness.SideA.DualSubjectJointTrials);
TrialSets.ByChoice.SideB.SameTarget = intersect(TmpSameIdx, TrialSets.ByJointness.SideB.DualSubjectJointTrials);
TrialSets.ByChoice.SameTarget = intersect(TrialSets.ByChoice.SideA.SameTarget, TrialSets.ByChoice.SideB.SameTarget);





% Reaction Times:
% InitialHoldRelease
TmpInititalHoldReleased_A = find(LogStruct.data(:, LogStruct.cn.A_HoldReleaseTime_ms) > 0.0);
TmpInititalHoldReleased_B = find(LogStruct.data(:, LogStruct.cn.B_HoldReleaseTime_ms) > 0.0);
% if the other side had a time of 0.0 no touch or release happened and the
% current side, if > 0.0 is trivially faster
TmpOnly_A = setdiff(TmpInititalHoldReleased_A, TmpInititalHoldReleased_B);
TmpOnly_B = setdiff(TmpInititalHoldReleased_B, TmpInititalHoldReleased_A);
% the joint trials with InitialTargetRekeases for both sides
TmpJointTrials = intersect(TmpInititalHoldReleased_A, TmpInititalHoldReleased_B);
TmpDeltaT = LogStruct.data(TmpJointTrials, LogStruct.cn.A_HoldReleaseTime_ms) - LogStruct.data(TmpJointTrials, LogStruct.cn.B_HoldReleaseTime_ms);
TmpSideA_faster_idx = find(TmpDeltaT < 0);
TmpSideB_faster_idx = find(TmpDeltaT > 0);
TmpBothSidesEquallyFast_idx = find(TmpDeltaT == 0);

% who was faster...
TrialSets.ByFirstReaction.SideA.InitialHoldRelease = union(TmpOnly_A, TmpJointTrials(TmpSideA_faster_idx));
TrialSets.ByFirstReaction.SideB.InitialHoldRelease = union(TmpOnly_B, TmpJointTrials(TmpSideB_faster_idx));
% or equal
TrialSets.ByFirstReaction.SideA.InitialHoldReleaseEqual = TmpJointTrials(TmpBothSidesEquallyFast_idx);
TrialSets.ByFirstReaction.SideB.InitialHoldReleaseEqual = TmpJointTrials(TmpBothSidesEquallyFast_idx);



% InitialFixationRelease
TmpInititalTargetReleased_A = find(LogStruct.data(:, LogStruct.cn.A_InitialFixationReleaseTime_ms) > 0.0);
TmpInititalTargetReleased_B = find(LogStruct.data(:, LogStruct.cn.B_InitialFixationReleaseTime_ms) > 0.0);
% if the other side had a time of 0.0 no touch or release happened and the
% current side, if > 0.0 is trivially faster
TmpOnly_A = setdiff(TmpInititalTargetReleased_A, TmpInititalTargetReleased_B);
TmpOnly_B = setdiff(TmpInititalTargetReleased_B, TmpInititalTargetReleased_A);
% the joint trials with InitialTargetRekeases for both sides
TmpJointTrials = intersect(TmpInititalTargetReleased_A, TmpInititalTargetReleased_B);
TmpDeltaT = LogStruct.data(TmpJointTrials, LogStruct.cn.A_InitialFixationReleaseTime_ms) - LogStruct.data(TmpJointTrials, LogStruct.cn.B_InitialFixationReleaseTime_ms);
TmpSideA_faster_idx = find(TmpDeltaT < 0);
TmpSideB_faster_idx = find(TmpDeltaT > 0);
TmpBothSidesEquallyFast_idx = find(TmpDeltaT == 0);


% who was faster...
TrialSets.ByFirstReaction.SideA.InitialTargetRelease = union(TmpOnly_A, TmpJointTrials(TmpSideA_faster_idx));
TrialSets.ByFirstReaction.SideB.InitialTargetRelease = union(TmpOnly_B, TmpJointTrials(TmpSideB_faster_idx));
% or equal
TrialSets.ByFirstReaction.SideA.InitialTargetReleaseEqual = TmpJointTrials(TmpBothSidesEquallyFast_idx);
TrialSets.ByFirstReaction.SideB.InitialTargetReleaseEqual = TmpJointTrials(TmpBothSidesEquallyFast_idx);




% TargetAcquisition
TmpTargetTouched_A = find(LogStruct.data(:, LogStruct.cn.A_TargetTouchTime_ms) > 0.0);
TmpTargetTouched_B = find(LogStruct.data(:, LogStruct.cn.B_TargetTouchTime_ms) > 0.0);
% if the other side had a time of 0.0 no touch or release happened and the
% current side, if > 0.0 is trivially faster
TmpOnly_A = setdiff(TmpTargetTouched_A, TmpTargetTouched_B);
TmpOnly_B = setdiff(TmpTargetTouched_B, TmpTargetTouched_A);
% the joint trials with InitialTargetRekeases for both sides
TmpJointTrials = intersect(TmpTargetTouched_A, TmpTargetTouched_B);
TmpDeltaT = LogStruct.data(TmpJointTrials, LogStruct.cn.A_TargetTouchTime_ms) - LogStruct.data(TmpJointTrials, LogStruct.cn.B_TargetTouchTime_ms);
TmpSideA_faster_idx = find(TmpDeltaT < 0);
TmpSideB_faster_idx = find(TmpDeltaT > 0);
TmpBothSidesEquallyFast_idx = find(TmpDeltaT == 0);


% who was faster?
TrialSets.ByFirstReaction.SideA.TargetAcquisition = union(TmpOnly_A, TmpJointTrials(TmpSideA_faster_idx));
TrialSets.ByFirstReaction.SideB.TargetAcquisition = union(TmpOnly_B, TmpJointTrials(TmpSideB_faster_idx));
% or equal
TrialSets.ByFirstReaction.SideA.TargetAcquisitionEqual = TmpJointTrials(TmpBothSidesEquallyFast_idx);
TrialSets.ByFirstReaction.SideB.TargetAcquisitionEqual = TmpJointTrials(TmpBothSidesEquallyFast_idx);








return
end



function [ sanitized_field_name ]  = sanitize_field_name_for_matlab( raw_field_name, PrefixForNumbers )
% some characters are not really helpful inside matlab variable names, so
% replace them with something that should not cause problems
taboo_char_list =		{' ', '-', '.', '='};
replacement_char_list = {'_', '_', '_dot_', '_eq_'};

sanitized_field_name = raw_field_name;

for i_taboo_char = 1: length(taboo_char_list)
	current_taboo_string = taboo_char_list{i_taboo_char};
	current_replacement_string = replacement_char_list{i_taboo_char};
	current_taboo_processed = 0;
	remain = sanitized_field_name;
	tmp_string = '';
	while (~current_taboo_processed)
		[token, remain] = strtok(remain, current_taboo_string);
		tmp_string = [tmp_string, token, current_replacement_string];
		if isempty(remain)
			current_taboo_processed = 1;
			% we add one superfluous replaceent string at the end, so
			% remove that
			tmp_string = tmp_string(1:end-length(current_replacement_string));
		end
	end
	sanitized_field_name = tmp_string;
end

if (strcmp(raw_field_name, ' '))
	sanitized_field_name = 'EmptyString';
	disp('Found empty string as field name, replacing with "None"...');
end

% numeric names are not allowed, so prefix a character string if the first
% character can be cas to a non-NaN number
if ~isnan(str2double(sanitized_field_name(1)))
	sanitized_field_name = [PrefixForNumbers, sanitized_field_name];
end


return
end