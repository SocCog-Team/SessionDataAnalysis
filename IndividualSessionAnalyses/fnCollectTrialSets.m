function [ TrialSets ] = fnCollectTrialSets( LogStruct )
%FNCOLLECTTRIALSETS Summary of this function goes here
%   Create all interesting subsets of trials
% first collect the basic sets then use set functions to refine to create
% interesting combinations
TrialSets = [];
TrialSets.All = (1:1:size(LogStruct.data, 1))';

if (length(TrialSets.All) == 0) || (LogStruct.first_empty_row_idx == 1)
	disp(['Logfile ', LogStruct.LoggingInfo.SessionFQN, ' does not contain any (valid trial) returning...']);
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
	TrialSets.ByTrialType.SideA.(CurrentTrialTypeName) = A_TrialsOfCurrentTypeIdx;
	TrialSets.ByTrialType.SideB.(CurrentTrialTypeName) = B_TrialsOfCurrentTypeIdx;
	TrialSets.ByTrialType.(CurrentTrialTypeName) = union(A_TrialsOfCurrentTypeIdx, B_TrialsOfCurrentTypeIdx);
end

if ~isfield(TrialSets.ByTrialType, 'InformedDirectedReach')
	TrialSets.ByTrialType.InformedDirectedReach = [];
end	
if ~isfield(TrialSets.ByTrialType, 'InformedChoice')
	TrialSets.ByTrialType.InformedChoice = [];
end
	
TrialSets.ByTrialType.InformedTrials = union(TrialSets.ByTrialType.InformedChoice, TrialSets.ByTrialType.InformedDirectedReach);


% create the list of choice trials
TrialSets.ByChoices.NumChoices01 = union(TrialSets.ByTrialType.DirectFreeGazeFreeChoice, TrialSets.ByTrialType.InformedDirectedReach);
TrialSets.ByChoices.NumChoices02 = union(TrialSets.ByTrialType.DirectFreeGazeFreeChoice, TrialSets.ByTrialType.InformedChoice);


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
	TrialSets.ByEffector.SideA.(CurrentEffectorName) = A_TrialsOfCurrentEffectorIdx;
	TrialSets.ByEffector.SideB.(CurrentEffectorName) = B_TrialsOfCurrentEffectorIdx;
	TrialSets.ByEffector.(CurrentEffectorName) = union(A_TrialsOfCurrentEffectorIdx, B_TrialsOfCurrentEffectorIdx);
end

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
		B_TrialsOfCurrentRewardFunctionIdx = find(LogStruct.data(:, LogStruct.cn.A_RewardFunctionENUM_idx) == CurrentRewardFunctionIdx);
	else
		B_TrialsOfCurrentRewardFunctionIdx = [];
	end
	TrialSets.ByRewardFunction.SideA.(CurrentRewardFunctionName) = A_TrialsOfCurrentRewardFunctionIdx;
	TrialSets.ByRewardFunction.SideB.(CurrentRewardFunctionName) = B_TrialsOfCurrentRewardFunctionIdx;
	TrialSets.ByRewardFunction.(CurrentRewardFunctionName) = union(A_TrialsOfCurrentRewardFunctionIdx, B_TrialsOfCurrentRewardFunctionIdx);
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
	TrialSets.ByName.SideA.(CurrentName) = A_TrialsOfCurrentNameIdx;
	TrialSets.ByName.SideB.(CurrentName) = B_TrialsOfCurrentNameIdx;
	TrialSets.ByName.(CurrentName) = union(A_TrialsOfCurrentNameIdx, B_TrialsOfCurrentNameIdx);
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

TrialSets.ByChoice.SideB.ChoiceLeft = B_LeftChoiceIdx;
TrialSets.ByChoice.SideB.ChoiceRight = B_RightChoiceIdx;
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

% note that for the DirectFreeGazeReaches trials we store the randomised
% position as the selected.
A_SelectedTargetEqualsRandomizedTargetTrialIdx = find((abs(LogStruct.data(:, LogStruct.cn.A_RandomizedTargetPosition_Y) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels) & (abs(LogStruct.data(:, LogStruct.cn.A_RandomizedTargetPosition_X) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels));
B_SelectedTargetEqualsRandomizedTargetTrialIdx = find((abs(LogStruct.data(:, LogStruct.cn.B_RandomizedTargetPosition_Y) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels) & (abs(LogStruct.data(:, LogStruct.cn.B_RandomizedTargetPosition_X) - LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_X)) <= EqualPositionSlackPixels));
% now only take those trials in which a subject actually touched the target
A_SelectedTargetEqualsRandomizedTargetTrialIdx = intersect(A_SelectedTargetEqualsRandomizedTargetTrialIdx, find(LogStruct.data(:, LogStruct.cn.A_TargetTouchTime_ms) > 0.0));
B_SelectedTargetEqualsRandomizedTargetTrialIdx = intersect(B_SelectedTargetEqualsRandomizedTargetTrialIdx, find(LogStruct.data(:, LogStruct.cn.B_TargetTouchTime_ms) > 0.0));

% keep the randomisation information, to allow fake by value analysus for
% freecgoice trials to compare agains left right and against informed
% trials
TrialSets.ByChoice.SideA.ProtoTargetValueHigh = A_SelectedTargetEqualsRandomizedTargetTrialIdx; % here the randomized position equals higher payoff
TrialSets.ByChoice.SideA.ProtoTargetValueLow = setdiff(TrialSets.All, A_SelectedTargetEqualsRandomizedTargetTrialIdx);
TrialSets.ByChoice.SideB.ProtoTargetValueHigh = setdiff(TrialSets.All, B_SelectedTargetEqualsRandomizedTargetTrialIdx);
TrialSets.ByChoice.SideB.ProtoTargetValueLow = B_SelectedTargetEqualsRandomizedTargetTrialIdx; % here the randomized position equals lower payoff

% here only add trials that are used a target value indicator
TrialSets.ByChoice.SideA.TargetValueHigh = intersect(TrialSets.ByTrialType.InformedTrials, A_SelectedTargetEqualsRandomizedTargetTrialIdx); % here the randomized position equals higher payoff
TrialSets.ByChoice.SideA.TargetValueLow = intersect(TrialSets.ByTrialType.InformedTrials, setdiff(TrialSets.All, A_SelectedTargetEqualsRandomizedTargetTrialIdx));
TrialSets.ByChoice.SideB.TargetValueHigh = intersect(TrialSets.ByTrialType.InformedTrials, setdiff(TrialSets.All, B_SelectedTargetEqualsRandomizedTargetTrialIdx));
TrialSets.ByChoice.SideB.TargetValueLow = intersect(TrialSets.ByTrialType.InformedTrials, B_SelectedTargetEqualsRandomizedTargetTrialIdx); % here the randomized position equals lower payoff

%TODO make sure that the higher rewarded trials are truely from trials
%using a differential RewardFunction.



return
end

