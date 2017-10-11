function [ TrialSets ] = fnCollectTrialSets( LogStruct )
%FNCOLLECTTRIALSETS Summary of this function goes here
%   Create all interesting subsets of trials
% first collect the basic sets then use set functions to refine to create
% interesting combinations
% it is possible with two actors, that both can cooperate even when one is
% not set for EvaluateTouchPanel, so detect true joint trials by both
% subjects touching the initial target, the main target and getting rewards

TrialSets = [];
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

% these are real joint trials when both subject work together
% test for touching the initial target:
TmpJointTrialsA = find(LogStruct.data(:, LogStruct.cn.A_InitialFixationTouchTime_ms) > 0);
TmpJointTrialsB = find(LogStruct.data(:, LogStruct.cn.B_InitialFixationTouchTime_ms) > 0);
TrialSets.ByJointness.DualSubjectJointTrials = intersect(TmpJointTrialsA, TmpJointTrialsB);

TrialSets.ByJointness.SideA.SoloSubjectTrials = setdiff(TmpJointTrialsA, TmpJointTrialsB);
TrialSets.ByJointness.SideB.SoloSubjectTrials = setdiff(TmpJointTrialsB, TmpJointTrialsA);

% test for touching the touch target
TmpJointTrialsA = find(LogStruct.data(:, LogStruct.cn.A_TargetTouchTime_ms) > 0);
TrialSets.ByJointness.DualSubjectJointTrials = intersect(TrialSets.ByJointness.DualSubjectJointTrials, TmpJointTrialsA);
TmpJointTrialsB = find(LogStruct.data(:, LogStruct.cn.B_TargetTouchTime_ms) > 0);
TrialSets.ByJointness.DualSubjectJointTrials = intersect(TrialSets.ByJointness.DualSubjectJointTrials, TmpJointTrialsB);

TmpSoloTrialsA = setdiff(TmpJointTrialsA, TmpJointTrialsB);
TmpSoloTrialsB = setdiff(TmpJointTrialsB, TmpJointTrialsA);
TrialSets.ByJointness.SideA.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideA.SoloSubjectTrials, TmpSoloTrialsA);
TrialSets.ByJointness.SideB.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideB.SoloSubjectTrials, TmpSoloTrialsB);

% test for reward
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
% solo trials: two subjects present, single troials only one subject
% active/present
TrialSets.ByJointness.SideA.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideA.SoloSubjectTrials, TrialSets.ByActivity.SideA.DualSubjectTrials);
TrialSets.ByJointness.SideB.SoloSubjectTrials = intersect(TrialSets.ByJointness.SideB.SoloSubjectTrials, TrialSets.ByActivity.SideB.DualSubjectTrials);

% joint trials are always for both sides
TrialSets.ByJointness.SideA.DualSubjectJointTrials = TrialSets.ByJointness.DualSubjectJointTrials;
TrialSets.ByJointness.SideB.DualSubjectJointTrials = TrialSets.ByJointness.DualSubjectJointTrials;

% what to do about the dual subject non-joint trials, with two subjects present and active, but only one working?
TrialSets.ByJointness.DualSubjectSoloTrials = union(TrialSets.ByJointness.SideA.SoloSubjectTrials, TrialSets.ByJointness.SideB.SoloSubjectTrials);



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

% older log files do not contain the informed choice fields
if ~isfield(TrialSets.ByTrialType, 'InformedDirectedReach')
	TrialSets.ByTrialType.InformedDirectedReach = [];
end	
if ~isfield(TrialSets.ByTrialType, 'InformedChoice')
	TrialSets.ByTrialType.InformedChoice = [];
end
	
TrialSets.ByTrialType.InformedTrials = union(TrialSets.ByTrialType.InformedChoice, TrialSets.ByTrialType.InformedDirectedReach);


% create the list of choice trials
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


if isfield(LogStruct, 'SessionByTrial')
    if isfield(LogStruct.SessionByTrial.unique_lists, 'TouchTargetPositioningMethod')
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
    disp([LogStruct.LoggingInfo.SessionFQN, ': fixed up effector hand for Magnus']);
end




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

% create indices for up down positions as well, note top left corner is
% 0,0, bottom right is 1920,1080
TrialSets.ByChoice.SideA.ChoiceTop = find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_Y) > LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y));
TrialSets.ByChoice.SideA.ChoiceBottom = find(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_Y) < LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y));
TrialSets.ByChoice.SideA.ChoiceCenterY = find(abs(LogStruct.data(:, LogStruct.cn.A_TouchInitialFixationPosition_Y) - LogStruct.data(:, LogStruct.cn.A_TouchSelectedTargetPosition_Y)) <= EqualPositionSlackPixels);
TrialSets.ByChoice.SideB.ChoiceTop = find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_Y) > LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y));
TrialSets.ByChoice.SideB.ChoiceBottom = find(LogStruct.data(:, LogStruct.cn.B_TouchInitialFixationPosition_Y) < LogStruct.data(:, LogStruct.cn.B_TouchSelectedTargetPosition_Y));
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

% numeric names are not allowed, so 
if ~isnan(str2double(sanitized_field_name))
    sanitized_field_name = [PrefixForNumbers, sanitized_field_name];
end


return
end