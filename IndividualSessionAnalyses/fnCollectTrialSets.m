function [ TrialSets ] = fnCollectTrialSets( LogStruct )
%FNCOLLECTTRIALSETS Summary of this function goes here
%   Create all interesting subsets of trials
% first collect the basic sets then use set functions to refine to create
% interesting combinations
TrialSets = [];
TrialSets.All = (1:1:size(LogStruct.data, 1))';
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


TrialTypesList = fnUnsortedUnique([LogStruct.unique_lists.A_TrialTypeENUM; LogStruct.unique_lists.B_TrialTypeENUM]);
for iTrialType = 1 : length(TrialTypesList)
	CurrentTrialTypeName = TrialTypesList{iTrialType};
	CurrentTrialTypeIdx = iTrialType;
	if ~isempty(CurrentTrialTypeIdx)
		A_TrialsOfCurentTypeIdx = find(LogStruct.data(:, LogStruct.cn.A_TrialTypeENUM_idx) == CurrentTrialTypeIdx);
	else
		A_TrialsOfCurentTypeIdx = [];
	end
	if ~isempty(CurrentTrialTypeIdx)
		B_TrialsOfCurentTypeIdx = find(LogStruct.data(:, LogStruct.cn.B_TrialTypeENUM_idx) == CurrentTrialTypeIdx);
	else
		B_TrialsOfCurentTypeIdx = [];
	end
	TrialSets.ByTrialType.SideA.(CurrentTrialTypeName) = A_TrialsOfCurentTypeIdx;
	TrialSets.ByTrialType.SideB.(CurrentTrialTypeName) = B_TrialsOfCurentTypeIdx;	
	TrialSets.ByTrialType.(CurrentTrialTypeName) = union(A_TrialsOfCurentTypeIdx, B_TrialsOfCurentTypeIdx);
end

% create the list of choice trials
TrialSets.ByChoices.NumChoices01 = union(TrialSets.ByTrialType.DirectFreeGazeFreeChoice, TrialSets.ByTrialType.InformedDirectedReach);
TrialSets.ByChoices.NumChoices02 = union(TrialSets.ByTrialType.DirectFreeGazeFreeChoice, TrialSets.ByTrialType.InformedChoice);



OutcomesList = fnUnsortedUnique([LogStruct.unique_lists.A_OutcomeENUM; LogStruct.unique_lists.B_OutcomeENUM]);
for iOutcome = 1 : length(OutcomesList)
	CurrentOutcomeName = OutcomesList{iOutcome};
	CurrentOutcomeIdx = iOutcome;
	
	if ~isempty(CurrentOutcomeIdx)
		A_TrialsOfCurentOutcomeIdx = find(LogStruct.data(:, LogStruct.cn.A_OutcomeENUM_idx) == CurrentOutcomeIdx);
	else
		A_TrialsOfCurentOutcomeIdx = [];
	end
	if ~isempty(CurrentOutcomeIdx)
		B_TrialsOfCurentOutcomeIdx = find(LogStruct.data(:, LogStruct.cn.B_OutcomeENUM_idx) == CurrentOutcomeIdx);
	else
		B_TrialsOfCurentOutcomeIdx = [];
	end
	TrialSets.ByOutcome.SideA.(CurrentOutcomeName) = A_TrialsOfCurentOutcomeIdx;
	TrialSets.ByOutcome.SideB.(CurrentOutcomeName) = B_TrialsOfCurentOutcomeIdx;	
	TrialSets.ByOutcome.(CurrentOutcomeName) = union(A_TrialsOfCurentOutcomeIdx, A_TrialsOfCurentOutcomeIdx);
end


% A_ReachEffectorENUM: {'none'  'left'  'not_left'  'right'  'not_right'  'both'  'not_both'}
% B_ReachEffectorENUM: {'none'  'left'  'not_left'  'right'  'not_right'  'both'  'not_both'}
ReachEffectorsList = fnUnsortedUnique([LogStruct.unique_lists.A_ReachEffectorENUM; LogStruct.unique_lists.B_ReachEffectorENUM]);
for iEffector = 1 : length(ReachEffectorsList)
	CurrentEffectorName = ReachEffectorsList{iEffector};
	CurrentEffectorIdx = iEffector;
	
	if ~isempty(CurrentEffectorIdx)
		A_TrialsOfCurentEffectorIdx = find(LogStruct.data(:, LogStruct.cn.A_ReachEffectorENUM_idx) == CurrentEffectorIdx);
	else
		A_TrialsOfCurentEffectorIdx = [];
	end
	if ~isempty(CurrentEffectorIdx)
		B_TrialsOfCurentEffectorIdx = find(LogStruct.data(:, LogStruct.cn.B_ReachEffectorENUM_idx) == CurrentEffectorIdx);
	else
		B_TrialsOfCurentEffectorIdx = [];
	end
	TrialSets.ByEffector.SideA.(CurrentEffectorName) = A_TrialsOfCurentEffectorIdx;
	TrialSets.ByEffector.SideB.(CurrentEffectorName) = B_TrialsOfCurentEffectorIdx;	
	TrialSets.ByEffector.(CurrentEffectorName) = union(A_TrialsOfCurentEffectorIdx, B_TrialsOfCurentEffectorIdx);
end

RewardFunctionsList = fnUnsortedUnique([LogStruct.unique_lists.A_RewardFunctionENUM; LogStruct.unique_lists.B_RewardFunctionENUM]);
for iRewardFunction = 1 : length(RewardFunctionsList)
	CurrentRewardFunctionName = RewardFunctionsList{iRewardFunction};
	CurrentRewardFunctionIdx = iRewardFunction;
	
	if ~isempty(CurrentRewardFunctionIdx)
		A_TrialsOfCurentRewardFunctionIdx = find(LogStruct.data(:, LogStruct.cn.A_RewardFunctionENUM_idx) == CurrentRewardFunctionIdx);
	else
		A_TrialsOfCurentRewardFunctionIdx = [];
	end
	if ~isempty(CurrentRewardFunctionIdx)
		B_TrialsOfCurentRewardFunctionIdx = find(LogStruct.data(:, LogStruct.cn.A_RewardFunctionENUM_idx) == CurrentRewardFunctionIdx);
	else
		B_TrialsOfCurentRewardFunctionIdx = [];
	end
	TrialSets.ByRewardFunction.SideA.(CurrentRewardFunctionName) = A_TrialsOfCurentRewardFunctionIdx;
	TrialSets.ByRewardFunction.SideB.(CurrentRewardFunctionName) = B_TrialsOfCurentRewardFunctionIdx;	
	TrialSets.ByRewardFunction.(CurrentRewardFunctionName) = union(A_TrialsOfCurentRewardFunctionIdx, B_TrialsOfCurentRewardFunctionIdx);
end


% get the active subject(s)
%ActiveSubjectsList = fnGetActiveSubjects(LogStruct);

% get the names, create a subset per name (exclude None)
NamesList = fnUnsortedUnique([LogStruct.unique_lists.A_Name; LogStruct.unique_lists.B_Name]);
for iName = 1: length(NamesList)
	% ignore None
	if (strcmp(NamesList{iName}, 'None'))
		continue
	end
	CurrentName = NamesList{iName};
	A_CurrentNameIdx = find(ismember(LogStruct.unique_lists.A_Name, CurrentName));
	B_CurrentNameIdx = find(ismember(LogStruct.unique_lists.B_Name, CurrentName));
	
	if ~isempty(A_CurrentNameIdx)
		A_TrialsOfCurentNameIdx = find(LogStruct.data(:, LogStruct.cn.A_Name_idx) == A_CurrentNameIdx);
	else
		A_TrialsOfCurentNameIdx = [];
	end
	if ~isempty(B_CurrentNameIdx)
		B_TrialsOfCurentNameIdx = find(LogStruct.data(:, LogStruct.cn.B_Name_idx) == B_CurrentNameIdx);
	else
		B_TrialsOfCurentNameIdx = [];
	end
	TrialSets.ByName.SideA.(CurrentName) = A_TrialsOfCurentNameIdx;
	TrialSets.ByName.SideB.(CurrentName) = B_TrialsOfCurentNameIdx;
	TrialSets.ByName.(CurrentName) = union(A_TrialsOfCurentNameIdx, B_TrialsOfCurentNameIdx);
end

% activity (was a side active during a given trial)
TrialSets.ByActivity.SideA = find(LogStruct.data(:, LogStruct.cn.A_IsActive));
TrialSets.ByActivity.SideB = find(LogStruct.data(:, LogStruct.cn.B_IsActive));
TrialSets.ByActivity.DualSubjectTrials = intersect(TrialSets.ByActivity.SideA, TrialSets.ByActivity.SideB);
TrialSets.ByActivity.SingleSubjectTrials = setdiff(TrialSets.All, TrialSets.ByActivity.DualSubjectTrials);

% generate indices for: targetposition, choice position, rewards-payout (target preference)
% get the choice preference choice is always by side
EqualPositionSlackPixels = 2;	% how many pixels two position are allowed to differ while still accounted as same, this is required as the is some rounding error in earlier code that produces of by one positions

A_LeftChoiceIdx = find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_X) > LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X));
A_RightChoiceIdx = find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_X) < LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X));

TrialSets.ByChoice.SideA.ChoiceLeft = A_LeftChoiceIdx;
TrialSets.ByChoice.SideA.ChoiceRight = A_RightChoiceIdx;
% allow some slack for improper rounding errors
TrialSets.ByChoice.SideA.ChoiceCenterX = find(abs(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_X) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels);
TrialSets.ByChoice.SideA.ChoiceScreenFromALeft = A_LeftChoiceIdx;
TrialSets.ByChoice.SideA.ChoiceScreenFromARight = A_RightChoiceIdx;

B_LeftChoiceIdx = find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_X) < LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X));
B_RightChoiceIdx = find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_X) > LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X));

TrialSets.ByChoice.SideB.SubjectiveLeft = B_LeftChoiceIdx;
TrialSets.ByChoice.SideB.SubjectiveRight = B_RightChoiceIdx;
% allow some slack for improper rounding errors
TrialSets.ByChoice.SideB.ChoiceCenterX = find(abs(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_X) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels);

% for Side B the subjective choice sides are flipped as seen from side A in
% eventide screen coordinates
TrialSets.ByChoice.SideB.ChoiceScreenFromALeft = B_RightChoiceIdx;
TrialSets.ByChoice.SideB.ChoiceScreenFromARight = B_LeftChoiceIdx;

% create indices for up down positions as well
TrialSets.ByChoice.SideA.ChoiceTop = find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_Y) < LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y));
TrialSets.ByChoice.SideA.ChoiceBottom = find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_Y) > LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y));
TrialSets.ByChoice.SideA.ChoiceCenterY = find(abs(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_Y) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels);
TrialSets.ByChoice.SideB.ChoiceTop = find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_Y) < LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y));
TrialSets.ByChoice.SideB.ChoiceBottom = find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_Y) > LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y));
TrialSets.ByChoice.SideB.ChoiceCenterY = find(abs(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_Y) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels);

% Extract information about the selected target reward value (assume only two values for now)

DifferentialRewardedTrialsIdx = TrialSets.ByRewardFunction.BOSMATRIXV01;
InformedTrialsIdx = union(TrialSets.ByTrialType.InformedChoice, TrialSets.ByTrialType.InformedDirectedReach);
% note that for the DirectFreeGazeReaches trials we store the randomised
% position as the selected.
A_SelectedTargetEqualsRandomizedTargetTrialIdx = find((abs(LogStruct.data(:, LogStruct.cn.A_RandomizedTargetPosition_Y) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels) & (abs(LogStruct.data(:, LogStruct.cn.A_RandomizedTargetPosition_X) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels));
B_SelectedTargetEqualsRandomizedTargetTrialIdx = find((abs(LogStruct.data(:, LogStruct.cn.B_RandomizedTargetPosition_Y) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels) & (abs(LogStruct.data(:, LogStruct.cn.B_RandomizedTargetPosition_X) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels));
% now only take those trials in which a subject actually touched the target
A_SelectedTargetEqualsRandomizedTargetTrialIdx = intersect(A_SelectedTargetEqualsRandomizedTargetTrialIdx, find(LogStruct.data(:, LogStruct.cn.A_TargetTouchTime_ms) > 0.0));
B_SelectedTargetEqualsRandomizedTargetTrialIdx = intersect(B_SelectedTargetEqualsRandomizedTargetTrialIdx, find(LogStruct.data(:, LogStruct.cn.B_TargetTouchTime_ms) > 0.0));

TrialSets.ByChoice.SideA.TargetValueHigh = intersect(InformedTrialsIdx, A_SelectedTargetEqualsRandomizedTargetTrialIdx); % here the randomized position equals higher payoff
TrialSets.ByChoice.SideA.TargetValueLow = intersect(InformedTrialsIdx, setdiff(TrialSets.All, A_SelectedTargetEqualsRandomizedTargetTrialIdx));
TrialSets.ByChoice.SideB.TargetValueHigh = intersect(InformedTrialsIdx, setdiff(TrialSets.All, B_SelectedTargetEqualsRandomizedTargetTrialIdx));
TrialSets.ByChoice.SideB.TargetValueLow = intersect(InformedTrialsIdx, B_SelectedTargetEqualsRandomizedTargetTrialIdx); % here the randomized position equals lower payoff





return
end

