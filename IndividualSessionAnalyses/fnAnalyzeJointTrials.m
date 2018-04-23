function [ output ] = fnAnalyzeJointTrials( SessionLogFQN, OutputBasePath, DataStruct, TrialSets )
%FNANALYZEJOINTTRIALS Summary of this function goes here
%   Detailed explanation goes here
% ATM this is hardcoded for BvS, needs work to generalize
% TODO:
%   add statistics test for average reward lines versus 2.5 (chance)
%   add statistics test for SOCA and SOCB for joint trials
%   add plots of reaction times/reaction time differences
%   create multi plot figure with vertical stacks of plots (so the timeline is aligned in parallel)
%   Create new RT plot, showing the histogramms for the A-B RTs for the
%       four SameDiff/OwnOther combinations
%   Add correlation analysis comparing:
%       the real choice with synthetic choice vectors for simple strategies
%           (like win stay, loose switch both for position and color)
%       look at windowed correlations with HP stategy blocks

%   Trial based Analysis:
%   Try to predict the current choice, based on:
%       a) stimulus display
%       b) choice of other player
%       c) choice of the actor in last trial(s)
%       d) choice of other actor in last trial(s)
%   ANOVA?
%   Create plot showing categorical information for all trials

%
% DONE:
%   add grand average lines for SOC and AR plots
%   also execute for non-joint trials (of sessions with joint trials)
%   add indicator which hand was used for the time series plots
%   promote fnPlotBackgroundByCategory into its own file in the
%       AuxiliaryFunctions repository


output = [];
ProcessReactionTimes = 1; % needs work...
ForceParsingOfExperimentLog = 1; % rewrite the logfiles anyway
CLoseFiguresOnReturn = 1;
CleanOutputDir = 0;
SaveMat4CoordinationCheck = 1;
SaveCoordinationSummary = 1;
InvisibleFigures = 1;

process_IC = 1;
process_FC = 0;

CoordinationSummaryFileName = 'CoordinationSummary.txt';

TitleSeparator = '_';

OutPutType = 'pdf';
output_rect_fraction = 0.5; % default 0.5

project_name = 'PrimateNeurobiology2018DPZ';

DefaultAxesType = 'PrimateNeurobiology2018DPZ'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
DefaultPaperSizeType = 'PrimateNeurobiology2018DPZ0.5'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ



[PathStr, FileName, ~] = fileparts(SessionLogFQN);

ShowEffectorHandInBackground = 1;
ShowFasterSideInBackground = 1;
ShowSelectedSidePerSubjectInRewardPlotBG = 1;

coordination_alpha = 0.05;  % the alpha value for all the tests for coordination
RightEffectorColor = [0.75, 0.75, 0.75];
RightEffectorBGTransparency = 1; % 1 opaque

SideAColor = [1 0 0];
SideBColor = [0 0 1];
SideABColor = [1 0 1];
SideABEqualRTColor = [1 1 1];

% INVISIBILITY/PARTIAL VIEW BLOCKING
ShowInvisibility = 1;
InvisibilityColor = [0.5 0.5 0.5];
InvisibitiltyTransparency = 0.5;

LeftTargColorA = [1 1 1];
RightTargColorA = ([255 165 0] / 255);
NoTargColorA = [1 0 0]; % these should not exist so make them stick out
LeftTransparencyA = 0.5;

LeftTargColorB = [1 1 1];
RightTargColorB = ([0 128 0] / 255);
NoTargColorB = [1 0 0]; % these should not exist so make them stick out
LeftTransparencyB = 0.5;

SameOwnAColor = [1 0 0];
SameOwnBColor = ([255 165 0] / 255);
DiffOwnColor = [0 1 0];
DiffOtherColor = [0 0 1];



% FIXME legend plotting is incomplete as it will also take patch objects
% into account, so best plot the backgrounds last, but that requires the
% ability to send the most recent plot to the back of an axis set
PlotLegend = 0; % add a lengend to the plots?

PlotRTBySameness = 1;

PlotRTHistograms = 1;
PlotRTHistogramsByByPayoffMatrix = 1;
PlotRTHistogramsBySelectedSideAndEffector = 0;



Plot_RT_differences = 0;
Plot_RT_difference_histogram = 1;
histnorm_string = 'count'; % count, probability, pdf, cdf
histdisplaystyle_string = 'stairs';% bar, stairs
histogram_RT_type_string = 'TargetAcquisitionRT';% InitialHoldReleaseRT, InitialTargetReleaseRT, TargetAcquisitionRT
histogram_bin_width_ms = 40;
histogram_edges = (0:histogram_bin_width_ms:1500);
histogram_diff_edges = (-750:histogram_bin_width_ms:750);
histogram_show_median = 1;
histogram_use_histogram_func = 0;


if (InvisibleFigures)
    figure_visibility_string = 'off';
else
    figure_visibility_string = 'on';
end


switch project_name
    case 'PrimateNeurobiology2018DPZ'
        ShowSelectedSidePerSubjectInRewardPlotBG = 1;
        ShowEffectorHandInBackground = 0;
        project_line_width = 2;
        show_coordination_results_in_fig_title = 0;
end

% this allows the caller to specify the Output directory
if ~exist('OutputBasePath', 'var')
    OutputBasePath = [];
end
if isempty(OutputBasePath)
    OutputPath = fullfile(PathStr, 'Analysis');
else
    OutputPath = fullfile(OutputBasePath);
end
if isdir(OutputPath) && CleanOutputDir
    disp(['Deleting ', OutputPath]);
    rmdir(OutputPath, 's');
end

% load the data if it does not exist yet
if ~exist('DataStruct', 'var')
    % check the current parser version
    [~, CurrentEventIDEReportParserVersionString] = fnParseEventIDEReportSCPv06([]);
    MatFilename = fullfile(PathStr, [FileName CurrentEventIDEReportParserVersionString '.mat']);
    % load if a mat file of the current parsed version exists, otherwise
    % reparse
    if exist(MatFilename, 'file') && ~(ForceParsingOfExperimentLog)
        tmplogData = load(MatFilename);
        DataStruct = tmplogData.report_struct;
        clear tmplogData;
    else
        DataStruct = fnParseEventIDEReportSCPv06(fullfile(PathStr, [FileName '.log']));
        %save(matFilename, 'logData'); % fnParseEventIDEReportSCPv06 saves by default
    end
    disp(['Processing: ', SessionLogFQN]);
end

if (SaveCoordinationSummary)
    CoordinationSummaryFQN = fullfile(OutputPath, CoordinationSummaryFileName);
    if (exist(CoordinationSummaryFQN, 'file') == 2)
        % get information about CoordinationSummaryFQN
        CoordinationSummaryFQN_listing = dir(CoordinationSummaryFQN);
        CurrentTime = now;
        % how long do we give each iteration of fnAnalyzeJointTrials give
        FileTooOldThresholdSeconds = 60;
        
        if (CoordinationSummaryFQN_listing.datenum < (CurrentTime - (FileTooOldThresholdSeconds / (60 * 60 *24))))
            % file too old delete it
            disp(['Found coordination summary file older than ', num2str(FileTooOldThresholdSeconds), ' seconds, deleting: ', CoordinationSummaryFQN]);
            delete(CoordinationSummaryFQN);
        else
            % touch the file, not changing a thing, do this to update the
            % modification date for each fnAnalyzeJointTrials call in a set
            tmp_fid = fopen(CoordinationSummaryFQN, 'r+');
            byte = fread(tmp_fid, 1);
            fseek(tmp_fid, 0, 'bof');
            fwrite(tmp_fid, byte);
            fclose(tmp_fid);
        end
    end
end


[SessionLogPath, SessionLogName, SessionLogExtension] = fileparts(SessionLogFQN);


if ~exist('TrialSets', 'var')
    TrialSets = fnCollectTrialSets(logData);
end
if isempty(TrialSets)
    disp(['Found zero trial records in ', SessionLogFQN, ' bailing out...']);
    return
end


%TODO find better species detection heuristic (use list on known NHP names or add explicit variable to the log file?)
IsHuman = 0;
if 	(strcmp(DataStruct.EventIDEinfo.Computer, 'SCP-CTRL-00'))
    % the test setup will always deliver human data...
    IsHuman = 1;
end



% for joint sessions also report single trials
GroupNameList = {};
GroupTrialIdxList = {};

if (process_IC)
    
    % only look at successfull choice trials
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.DualSubjectJointTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'IC_JointTrials';
    
    % Solo trials are trials with another actor present, but not playing
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.SideA.SoloSubjectTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'IC_SoloTrialsSideA';
    
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.SideB.SoloSubjectTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'IC_SoloTrialsSideB';
    
    % SingleSubject trials are fom single subject sessions
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByActivity.SideA.SingleSubjectTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'IC_SingleSubjectTrialsSideA';
    
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByActivity.SideB.SingleSubjectTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'IC_SingleSubjectTrialsSideB';
end


if (process_FC)
    %%% free choice
    % only look at successfull choice trials
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.DualSubjectJointTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'FC_JointTrials';
    
    % Solo trials are trials with another actor present, but not playing
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.SideA.SoloSubjectTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'FC_SoloTrialsSideA';
    
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.SideB.SoloSubjectTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'FC_SoloTrialsSideB';
    
    % SingleSubject trials are fom single subject sessions
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByActivity.SideA.SingleSubjectTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'FC_SingleSubjectTrialsSideA';
    
    GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);             % exclude free choice
    GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByActivity.SideB.SingleSubjectTrials);     % exclude non-joint trials
    GroupTrialIdxList{end+1} = GoodTrialsIdx;
    GroupNameList{end+1} = 'FC_SingleSubjectTrialsSideB';
end



for iGroup = 1 : length(GroupNameList)
    % get a prefix for the output
    CurrentGroup = GroupNameList{iGroup};
    %TitleSetDescriptorString = CurrentGroup;% [];
    TitleSetDescriptorString = [];
    if ~isempty(strfind(CurrentGroup, 'Solo'))
        IsSoloGroup = 1;
    else
        IsSoloGroup = 0;
    end
    
    % also do this for the single sesssion data
    if ~isempty(strfind(CurrentGroup, 'SingleSubject'))
        IsSoloGroup = IsSoloGroup + 1;
    else
        IsSoloGroup = IsSoloGroup + 0;
    end
    
    
    
    ProcessSideA = 1;
    ProcessSideB = 1;
    
    if (IsSoloGroup)
        if isempty(strfind(CurrentGroup, 'SideA'))
            ProcessSideA = 0;
        elseif  isempty(strfind(CurrentGroup, 'SideB'))
            ProcessSideB = 0;
        else
            
        end
    end
    
    
    GoodTrialsIdx = GroupTrialIdxList{iGroup};
    
    % extract the TouchTargetPositioningMethod, this is a HACK FIXME
    TTPM_idx = unique(DataStruct.SessionByTrial.data(GoodTrialsIdx, DataStruct.SessionByTrial.cn.TouchTargetPositioningMethod_idx));
    if ~isempty(find(TTPM_idx == 0))
        TTPM_idx(find(TTPM_idx == 0)) = [];
    end
    
    if (length(TTPM_idx) ~= 1)
        ChoiceDimension = 'mixed';
    else
        ChoiceDimension = 'left_right';
        CurrentGroup_TTPM = DataStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod{TTPM_idx};
        if ~isempty(strfind(CurrentGroup_TTPM, 'VERTICALCHOICE'))
            ChoiceDimension = 'top_bottom';
        end
        
    end
    
    %ExcludeTrialIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);
    
    % joint trial data!
    if isempty(GoodTrialsIdx)
        % here we only have the actually cooperation trials (for BvS)
        % do some timecourse analysis and imaging
        disp(['Found zero ', CurrentGroup, ' in ', SessionLogFQN, ' bailing out...']);
        continue
    end
    
    if length(GoodTrialsIdx) == 1
        % here we only have the actually cooperation trials (for BvS)
        % do some timecourse analysis and imaging
        disp(['Found a single trial for', CurrentGroup, ' in ', SessionLogFQN, ' skipping out...']);
        continue
    end
    
    
    if ~isempty(TrialSets.ByActivity.DualSubjectTrials)
        %disp('Currently only analyze Single Subject Sessions');
        %return
        disp('Dual Subject Session; first process each subject individually')
        % extract the name to side mapping (initially assume non changing name
        % to side mappings during an experiment)
        % TODO make this work for arbitrary grouping combinations during each
        % session to allow side changes.
        SubjectA = DataStruct.unique_lists.A_Name(unique(DataStruct.data(:, DataStruct.cn.A_Name_idx)));
        SubjectB = DataStruct.unique_lists.B_Name(unique(DataStruct.data(:, DataStruct.cn.B_Name_idx)));
        SubjectsSideString = ['A.', SubjectA{1}, '.B.', SubjectB{1}];
        
        if isempty(TitleSetDescriptorString)
            SeparatorString = '';
        else
            SeparatorString = TitleSeparator;
        end
        
        TitleSetDescriptorString = [TitleSetDescriptorString, SeparatorString, SubjectsSideString];
    end
    
    if isempty(strfind(CurrentGroup, 'Joint')) && ~isempty(strfind(CurrentGroup, 'Solo'))
        if isempty(TitleSetDescriptorString)
            SeparatorString = '';
        else
            SeparatorString = TitleSeparator;
        end
        if ~isempty(strfind(CurrentGroup, 'SideA'))
            SubjectA = DataStruct.unique_lists.A_Name(unique(DataStruct.data(:, DataStruct.cn.A_Name_idx)));
            TitleSetDescriptorString = [TitleSetDescriptorString, SeparatorString, SubjectA{1}];
        end
        if ~isempty(strfind(CurrentGroup, 'SideB'))
            SubjectB = DataStruct.unique_lists.B_Name(unique(DataStruct.data(:, DataStruct.cn.B_Name_idx)));
            TitleSetDescriptorString = [TitleSetDescriptorString, SeparatorString, SubjectB{1}];
        end
        
    end
    
    if isempty(TitleSetDescriptorString)
        SeparatorString = '';
    else
        SeparatorString = TitleSeparator;
    end
    
    TitleSetDescriptorString = [TitleSetDescriptorString, SeparatorString, CurrentGroup];
    
    % calculate a few variables for the further processing
    NumTrials = size(DataStruct.data, 1);
    
    % get the Rewards per Side and trial, as well as the averaged rewards for
    % the "team"
    RewardByTrial_A = DataStruct.data(:, DataStruct.cn.A_NumberRewardPulsesDelivered_HIT);
    RewardByTrial_B = DataStruct.data(:, DataStruct.cn.B_NumberRewardPulsesDelivered_HIT);
    AvgRewardByTrial_AB = (RewardByTrial_A + RewardByTrial_B) * 0.5;
    if (IsSoloGroup)
        if (ProcessSideA)
            AvgRewardByTrial_AB = RewardByTrial_A;
        elseif (ProcessSideB)
            AvgRewardByTrial_AB = RewardByTrial_B;
        end
    end
    
    
    
    % get the share of own choices
    PreferableTargetSelected_A = zeros([NumTrials, 1]);
    PreferableTargetSelected_A(TrialSets.ByChoice.SideA.ProtoTargetValueHigh) = 1;
    PreferableTargetSelected_B = zeros([NumTrials, 1]);
    PreferableTargetSelected_B(TrialSets.ByChoice.SideB.ProtoTargetValueHigh) = 1;
    
    % get the share of location choices (left/right, top/bottom)
    % top/bottom
    BottomTargetSelected_A = zeros([NumTrials, 1]);
    BottomTargetSelected_A(TrialSets.ByChoice.SideA.ChoiceBottom) = 1;
    BottomTargetSelected_B = zeros([NumTrials, 1]);
    BottomTargetSelected_B(TrialSets.ByChoice.SideB.ChoiceBottom) = 1;
    
    % for left/right also give objective and subjective
    SubjectiveLeftTargetSelected_A = zeros([NumTrials, 1]);
    SubjectiveLeftTargetSelected_A(TrialSets.ByChoice.SideA.ChoiceLeft) = 1;
    SubjectiveLeftTargetSelected_B = zeros([NumTrials, 1]);
    SubjectiveLeftTargetSelected_B(TrialSets.ByChoice.SideB.ChoiceLeft) = 1;
    % for left/right also give objective and subjective
    LeftTargetSelected_A = zeros([NumTrials, 1]);
    LeftTargetSelected_A(TrialSets.ByChoice.SideA.ChoiceScreenFromALeft) = 1;
    LeftTargetSelected_B = zeros([NumTrials, 1]);
    LeftTargetSelected_B(TrialSets.ByChoice.SideB.ChoiceScreenFromALeft) = 1;
    
    
    SameTargetSelected_A = zeros([NumTrials, 1]);
    SameTargetSelected_A(TrialSets.ByChoice.SideA.SameTarget) = 1;
    SameTargetSelected_B = zeros([NumTrials, 1]);
    SameTargetSelected_B(TrialSets.ByChoice.SideB.SameTarget) = 1;
    
    % the effector hand per trial
    RightHandUsed_A = zeros([NumTrials, 1]);
    RightHandUsed_A(TrialSets.ByEffector.SideA.right)  = 1;
    RightHandUsed_B = zeros([NumTrials, 1]);
    RightHandUsed_B(TrialSets.ByEffector.SideB.right)  = 1;
    
    % the invisibitity, Invisible_A denotes that B can not see A
    Invisible_A = ismember(TrialSets.All, TrialSets.ByVisibility.SideA.A_invisible);
    Invisible_B = ismember(TrialSets.All, TrialSets.ByVisibility.SideB.B_invisible);
    Invisible_AB = ismember(TrialSets.All, TrialSets.ByVisibility.AB_invisible);
    
    % show who was faster
    % InitialHoldRelease (proximity sensors)
    FasterInititialHoldRelease_A = zeros([NumTrials, 1]);
    FasterInititialHoldRelease_A(TrialSets.ByFirstReaction.SideA.InitialHoldRelease) = 1;
    FasterInititialHoldRelease_B = zeros([NumTrials, 1]);
    FasterInititialHoldRelease_B(TrialSets.ByFirstReaction.SideB.InitialHoldRelease) = 1;
    EqualInititialHoldRelease_AB = zeros([NumTrials, 1]);
    EqualInititialHoldRelease_AB(TrialSets.ByFirstReaction.SideA.InitialHoldReleaseEqual) = 1;
    
    % IntitialTargetRelease
    FasterInititialTargetRelease_A = zeros([NumTrials, 1]);
    FasterInititialTargetRelease_A(TrialSets.ByFirstReaction.SideA.InitialTargetRelease) = 1;
    FasterInititialTargetRelease_B = zeros([NumTrials, 1]);
    FasterInititialTargetRelease_B(TrialSets.ByFirstReaction.SideB.InitialTargetRelease) = 1;
    EqualInititialTargetRelease_AB = zeros([NumTrials, 1]);
    EqualInititialTargetRelease_AB(TrialSets.ByFirstReaction.SideA.InitialTargetReleaseEqual) = 1;
    
    % TargetAcquisition
    FasterTargetAcquisition_A = zeros([NumTrials, 1]);
    FasterTargetAcquisition_A(TrialSets.ByFirstReaction.SideA.TargetAcquisition) = 1;
    FasterTargetAcquisition_B = zeros([NumTrials, 1]);
    FasterTargetAcquisition_B(TrialSets.ByFirstReaction.SideB.TargetAcquisition) = 1;
    EqualTargetAcquisition_AB = zeros([NumTrials, 1]);
    EqualTargetAcquisition_AB(TrialSets.ByFirstReaction.SideA.TargetAcquisitionEqual) = 1;
    
    
    % reaction times
    A_InitialHoldReleaseRT = DataStruct.data(:, DataStruct.cn.A_HoldReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.A_InitialFixationOnsetTime_ms);
    B_InitialHoldReleaseRT = DataStruct.data(:, DataStruct.cn.B_HoldReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.B_InitialFixationOnsetTime_ms);
    AB_InitialHoldReleaseRT_diff = A_InitialHoldReleaseRT - B_InitialHoldReleaseRT;
    
    %A_InitialTargetNonAdjReleaseRT = DataStruct.data(:, DataStruct.cn.A_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.A_TargetOnsetTime_ms);
    %B_InitialTargetNonAdjReleaseRT = DataStruct.data(:, DataStruct.cn.B_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.B_TargetOnsetTime_ms);
    
    A_InitialTargetReleaseRT = DataStruct.data(:, DataStruct.cn.A_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.A_TargetOnsetTime_ms);
    B_InitialTargetReleaseRT = DataStruct.data(:, DataStruct.cn.B_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.B_TargetOnsetTime_ms);
    AB_InitialTargetReleaseRT_diff = A_InitialTargetReleaseRT - B_InitialTargetReleaseRT;
    
    A_TargetAcquisitionRT = DataStruct.data(:, DataStruct.cn.A_TargetTouchTime_ms) - DataStruct.data(:, DataStruct.cn.A_TargetOnsetTime_ms);
    B_TargetAcquisitionRT = DataStruct.data(:, DataStruct.cn.B_TargetTouchTime_ms) - DataStruct.data(:, DataStruct.cn.B_TargetOnsetTime_ms);
    AB_TargetAcquisitionRT_diff = A_TargetAcquisitionRT - B_TargetAcquisitionRT;
    
    % Anton's coordination test
    if ~(IsSoloGroup)
        NumExplorationTrials = 49;
        % human data?
        if (IsHuman)
            NumExplorationTrials = 199;
        end
        
        TrialIdx = GoodTrialsIdx;
        if (length(TrialIdx) > (NumExplorationTrials + 1))
            TrialIdx = TrialIdx(NumExplorationTrials+1:end);
        end
        isOwnChoice = [PreferableTargetSelected_A(TrialIdx)'; PreferableTargetSelected_B(TrialIdx)'];
        
        % for saving
        isOwnChoiceArray = [PreferableTargetSelected_A(GoodTrialsIdx)'; PreferableTargetSelected_B(GoodTrialsIdx)'];
        
        switch ChoiceDimension
            case 'mixed'
                sideChoice = [LeftTargetSelected_A(TrialIdx)'; LeftTargetSelected_B(TrialIdx)'];    % this requires the pysical stimulus side (aka objective position)
                sideChoiceObjectiveArray = [LeftTargetSelected_A(GoodTrialsIdx)'; LeftTargetSelected_B(GoodTrialsIdx)'];
                sideChoiceSubjectiveArray = [SubjectiveLeftTargetSelected_A(GoodTrialsIdx)'; SubjectiveLeftTargetSelected_B(GoodTrialsIdx)'];
            case 'left_right'
                sideChoice = [LeftTargetSelected_A(TrialIdx)'; LeftTargetSelected_B(TrialIdx)'];    % this requires the pysical stimulus side (aka objective position)
                sideChoiceObjectiveArray = [LeftTargetSelected_A(GoodTrialsIdx)'; LeftTargetSelected_B(GoodTrialsIdx)'];
                sideChoiceSubjectiveArray = [SubjectiveLeftTargetSelected_A(GoodTrialsIdx)'; SubjectiveLeftTargetSelected_B(GoodTrialsIdx)'];
            case {'bottom_top', 'top_bottom'}
                sideChoice = [BottomTargetSelected_A(TrialIdx)'; BottomTargetSelected_B(TrialIdx)'];    % this requires the pysical stimulus side (aka objective position)
                sideChoiceObjectiveArray = [BottomTargetSelected_A(GoodTrialsIdx)'; BottomTargetSelected_B(GoodTrialsIdx)'];
                sideChoiceSubjectiveArray = [BottomTargetSelected_A(GoodTrialsIdx)'; BottomTargetSelected_B(GoodTrialsIdx)'];  %here subjective and objective are the same
        end
        [partnerInluenceOnSide, partnerInluenceOnTarget] = check_coordination_v1(isOwnChoice, sideChoice);
        coordStruct = check_coordination(isOwnChoice, sideChoice, coordination_alpha);
        [sideChoiceIndependence, targetChoiceIndependence] = check_independence(isOwnChoice, sideChoice);
        
        CoordinationSummaryString = coordStruct.SummaryString;
        CoordinationSummaryCell = coordStruct.SummaryCell;
        
        % now save the data
        if (SaveMat4CoordinationCheck)
            info.ChoiceDimension = ChoiceDimension;
            info.SessionLogFQN = SessionLogFQN;
            info.CurrentGroup = CurrentGroup;
            info.isOwnChoiceArrayHeader = {'A', 'B'};
            info.sideChoiceObjectiveArrayHeader = {'A', 'B',};
            info.TrialSetsDescription = 'Structure of different sets of trials, wher the invidual sets are named';
            outfilename = fullfile(OutputPath, 'CoordinationCheck', ['DATA_', FileName, '.', TitleSetDescriptorString, '.isOwnChoice_sideChoice.mat']);
            mkdir(fullfile(OutputPath, 'CoordinationCheck'));
            
            % include the edxploration trials
            TrialsInCurrentSetIdx = GoodTrialsIdx;
            
            % additional information for all the trials in the current set
            PerTrialStruct.isTrialInvisible_AB = Invisible_AB(TrialsInCurrentSetIdx);
            
            PerTrialStruct.A_InitialTargetReleaseRT = A_InitialTargetReleaseRT(TrialsInCurrentSetIdx);
            PerTrialStruct.B_InitialTargetReleaseRT = B_InitialTargetReleaseRT(TrialsInCurrentSetIdx);
            PerTrialStruct.AB_InitialTargetReleaseRT_diff = AB_InitialTargetReleaseRT_diff(TrialsInCurrentSetIdx);
            
            PerTrialStruct.A_TargetAcquisitionRT = A_TargetAcquisitionRT(TrialsInCurrentSetIdx);
            PerTrialStruct.B_TargetAcquisitionRT = B_TargetAcquisitionRT(TrialsInCurrentSetIdx);
            PerTrialStruct.AB_TargetAcquisitionRT_diff = AB_TargetAcquisitionRT_diff(TrialsInCurrentSetIdx);
            
            
            % ATTENTION this includes the exploration trials!!!
            isOwnChoice = isOwnChoiceArray;
            isBottomChoice = sideChoiceObjectiveArray;
            save(outfilename, 'info', 'isOwnChoiceArray', 'sideChoiceObjectiveArray', 'sideChoiceSubjectiveArray', 'TrialsInCurrentSetIdx', 'TrialSets', 'coordStruct', 'isOwnChoice', 'isBottomChoice', 'PerTrialStruct');
        end
        
        if (SaveCoordinationSummary)
            CoordinationSummaryFQN_fid = fopen(CoordinationSummaryFQN, 'a+');
            % add some extra information
            OutPutString = ['SessionLogName: ', SessionLogName,' ; Group: ', CurrentGroup, '; ', CoordinationSummaryString, '; SessionLogFQN: ', SessionLogFQN];
            fprintf(CoordinationSummaryFQN_fid, '%s\n', OutPutString);
            fclose(CoordinationSummaryFQN_fid);
        end
        
    else
        CoordinationSummaryString = '';
        CoordinationSummaryCell = [];
        partnerInluenceOnSide = [];
        partnerInluenceOnTarget = [];
    end
    
    %Common filter properties:
    FilterHalfWidth = 4;
    FilterShape = 'same';
    FilterKernelName = 'box'; % 'gaussian'
    
    
    %%
    % plot the RewardPlot
    FilteredJointTrials_AvgRewardByTrial_AB = fnFilterByNamedKernel( AvgRewardByTrial_AB(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
    %FilteredJointTrials_AvgRewardByTrial_AB = fnFilterByNamedKernel( AvgRewardByTrial_AB(GoodTrialsIdx), 'gaussian', FilterHalfWidth, FilterShape );
    FilteredJointTrials_RewardByTrial_A = fnFilterByNamedKernel( RewardByTrial_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
    FilteredJointTrials_RewardByTrial_B = fnFilterByNamedKernel( RewardByTrial_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
    JointTrialX_Vector = (1:1:length(GoodTrialsIdx));
    % remove the filter artifacts?
    FilteredJointTrialX_Vector = ((FilterHalfWidth + 1):1:(length(GoodTrialsIdx) - FilterHalfWidth));
    
    % we need to have JointTrialX_Vector available
    % Who is faster
    StackedXData = {[FasterInititialHoldRelease_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterInititialHoldRelease_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualInititialHoldRelease_AB(GoodTrialsIdx(JointTrialX_Vector)))]; ...
        [FasterInititialTargetRelease_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterInititialTargetRelease_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualInititialTargetRelease_AB(GoodTrialsIdx(JointTrialX_Vector)))]; ...
        [FasterTargetAcquisition_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterTargetAcquisition_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualTargetAcquisition_AB(GoodTrialsIdx(JointTrialX_Vector)))]};
    StackedRightEffectorColor = {[SideAColor; SideBColor; SideABEqualRTColor]; [SideAColor; SideBColor; SideABEqualRTColor]; [SideAColor; SideBColor; SideABEqualRTColor]};
    StackedRightEffectorBGTransparency = {[0.33]; [0.66]; [1.0]};
    
    
    % exclude the InititialHoldRelease as this is not that interesting
    StackedXData = {[FasterInititialTargetRelease_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterInititialTargetRelease_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualInititialTargetRelease_AB(GoodTrialsIdx(JointTrialX_Vector)))]; ...
        [FasterTargetAcquisition_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterTargetAcquisition_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualTargetAcquisition_AB(GoodTrialsIdx(JointTrialX_Vector)))]};
    StackedRightEffectorColor = {[SideAColor; SideBColor; SideABEqualRTColor]; [SideAColor; SideBColor; SideABEqualRTColor]};
    StackedRightEffectorBGTransparency = {[0.66]; [1.0]};
    
    
    
    
    
    % for each trial figure out who selected the right target
    SubjectiveSideStackedXData = {[~SubjectiveLeftTargetSelected_A(GoodTrialsIdx(JointTrialX_Vector)) * 2]; [~SubjectiveLeftTargetSelected_B(GoodTrialsIdx(JointTrialX_Vector)) * 2]};
    SideStackedXData = {[~LeftTargetSelected_A(GoodTrialsIdx(JointTrialX_Vector)) * 2]; [~LeftTargetSelected_B(GoodTrialsIdx(JointTrialX_Vector)) * 2]};
    SideStackedRightEffectorColor = {[LeftTargColorA; RightTargColorA; NoTargColorA]; [LeftTargColorB; RightTargColorB; NoTargColorB]};
    SideStackedRightEffectorBGTransparency = {[LeftTransparencyA]; [LeftTransparencyB]};
    if (ProcessSideA) && ~(ProcessSideB)
        SubjectiveSideStackedXData = SubjectiveSideStackedXData(1);
        SideStackedXData = SideStackedXData(1);
        SideStackedRightEffectorColor = SideStackedRightEffectorColor(1);
        SideStackedRightEffectorBGTransparency = SideStackedRightEffectorBGTransparency(1);
    elseif ~(ProcessSideA) && (ProcessSideB)
        SubjectiveSideStackedXData = SubjectiveSideStackedXData(2);
        SideStackedXData = SideStackedXData(2);
        SideStackedRightEffectorColor = SideStackedRightEffectorColor(2);
        SideStackedRightEffectorBGTransparency = SideStackedRightEffectorBGTransparency(2);
    end
    
    % the sideChoiceSubjectiveArray would deal with non left right
    % postioning methods
    %     % for each trial figure out who selected the right target
    %     SubjectiveSideStackedXData = {[~sideChoiceSubjectiveArray(1, JointTrialX_Vector) * 2]; [~sideChoiceSubjectiveArray(2, JointTrialX_Vector) * 2]};
    %     SideStackedXData = {[~sideChoiceObjectiveArray(1, JointTrialX_Vector) * 2]; [~sideChoiceObjectiveArray(2, JointTrialX_Vector) * 2]};
    %     SideStackedRightEffectorColor = {[LeftTargColorA; RightTargColorA; NoTargColorA]; [LeftTargColorB; RightTargColorB; NoTargColorB]};
    %     SideStackedRightEffectorBGTransparency = {[LeftTransparencyA]; [LeftTransparencyB]};
    %     if (ProcessSideA) && ~(ProcessSideB)
    %         SubjectiveSideStackedXData = SubjectiveSideStackedXData(1);
    %         SideStackedXData = SideStackedXData(1);
    %         SideStackedRightEffectorColor = SideStackedRightEffectorColor(1);
    %         SideStackedRightEffectorBGTransparency = SideStackedRightEffectorBGTransparency(1);
    %     elseif ~(ProcessSideA) && (ProcessSideB)
    %         SubjectiveSideStackedXData = SubjectiveSideStackedXData(2);
    %         SideStackedXData = SideStackedXData(2);
    %         SideStackedRightEffectorColor = SideStackedRightEffectorColor(2);
    %         SideStackedRightEffectorBGTransparency = SideStackedRightEffectorBGTransparency(2);
    %     end
    
    
    Cur_fh_RewardOverTrials = figure('Name', 'RewardOverTrials', 'visible', figure_visibility_string);
    fnFormatDefaultAxes(DefaultAxesType);
    [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
    set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
    legend_list = {};
    hold on
    
    y_margin = 0.1; % how much to extend the plot below and above the true reward limits
    
    % the default ranges
    y_data_bottom = 1;
    y_data_top = 4;
    y_tick_list = [1, 2, 3, 4];
    
    % the following need to be ordered by increasing range so that
    if (isfield(TrialSets.ByRewardFunction, 'BOSMATRIXV01') && ~isempty(TrialSets.ByRewardFunction.BOSMATRIXV01))
        y_data_bottom = min([1, y_data_bottom]);
        y_data_top = max([4, y_data_top]);
    end
    
    if (isfield(TrialSets.ByRewardFunction, 'BOSTEMPCOMPV01') && ~isempty(TrialSets.ByRewardFunction.BOSTEMPCOMPV01))
        y_data_bottom = min([1, y_data_bottom]);
        y_data_top = max([4, y_data_top]);
    end
    
    if (isfield(TrialSets.ByRewardFunction, 'BOSTEMPCOMPV02') && ~isempty(TrialSets.ByRewardFunction.BOSTEMPCOMPV02))
        y_data_bottom = min([1, y_data_bottom]);
        y_data_top = max([5, y_data_top]);
        y_tick_list = [1, 2, 3, 4, 5];
    end
    
    set(gca(), 'YLim', [(y_data_bottom - y_margin), (y_data_top + y_margin)]);
    y_lim = get(gca(), 'YLim');
    
    % mark all trials in which the visibility of the two sides was
    % manipulated
    if (ShowInvisibility)
        fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
    end
    
    if (ShowSelectedSidePerSubjectInRewardPlotBG)
        fnPlotStackedCategoriesAtPositionWrapper('StackedBottomToTop', 0.15, SideStackedXData, y_lim, SideStackedRightEffectorColor, SideStackedRightEffectorBGTransparency);
        % plot a single category vector, attention, right now this is hybrid...
        set(gca(), 'YLim', [0.7, (y_data_top + y_margin)]);
        y_lim = [0.7 (y_data_bottom - y_margin)];
        fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
        y_lim = get(gca(), 'YLim');
    else
        % plot a single category vector, attention, right now this is hybrid...
        fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
    end
    
    % plot multiple category vectors
    if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
        fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
    end
    
    if (ProcessSideA)
        plot(JointTrialX_Vector, RewardByTrial_A(GoodTrialsIdx(JointTrialX_Vector)), 'Color', SideAColor, 'LineWidth', project_line_width*0.33);
        legend_list{end + 1} = 'running avg. A';
        %plot(FilteredJointTrialX_Vector, RewardByTrial_A(GoodTrialsIdx(FilteredJointTrialX_Vector)), 'Color', [1 0 0]);
        % TmpMean = mean(RewardByTrial_A(GoodTrialsIdx));
        % line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0.66 0 0], 'LineStyle', '--', 'LineWidth', 3);
        % legend_list{end + 1} = 'all trials avg. A';
    end
    if (ProcessSideB)
        plot(JointTrialX_Vector, RewardByTrial_B(GoodTrialsIdx(JointTrialX_Vector)), 'Color', SideBColor, 'LineWidth', project_line_width*0.33);
        legend_list{end + 1} = 'running avg. B';
        %plot(FilteredJointTrialX_Vector, RewardByTrial_B(GoodTrialsIdx(FilteredJointTrialX_Vector)), 'Color', [0 0 1]);
        % TmpMean = mean(RewardByTrial_B(GoodTrialsIdx));
        % line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0 0 0.66], 'LineStyle', '--', 'LineWidth', 3);
        % legend_list{end + 1} = 'all trials avg. B';
    end
    
    % plot this after the individual subject data so it lands on top
    plot(FilteredJointTrialX_Vector, FilteredJointTrials_AvgRewardByTrial_AB(FilteredJointTrialX_Vector), 'Color', SideABColor, 'LineWidth', project_line_width);
    legend_list{end + 1} = 'running avg. AB smoothed';
    if ~isempty(FilteredJointTrialX_Vector)
        TmpMean = mean(AvgRewardByTrial_AB(GoodTrialsIdx));
        line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0 0 0], 'LineStyle', '--', 'LineWidth', project_line_width);
        legend_list{end + 1} = 'all trials avg. AB';
    end
    
    % % filtered individual rewards
    % plot(FilteredJointTrialX_Vector, FilteredJointTrials_RewardByTrial_A(FilteredJointTrialX_Vector), 'r', 'LineWidth', 2);
    % legend_list{end + 1} = 'A';
    % plot(FilteredJointTrialX_Vector, FilteredJointTrials_RewardByTrial_B(FilteredJointTrialX_Vector), 'b', 'LineWidth', 2);
    % legend_list{end + 1} = 'B';
    hold off
    
    
    %     if ~ismepty(CoordinationSummaryString)
    %         title(CoordinationSummaryString, 'FontSize', 12, 'Interpreter', 'None');
    %     end
    if ~isempty(CoordinationSummaryCell) && show_coordination_results_in_fig_title
        title(CoordinationSummaryCell, 'FontSize', 12, 'Interpreter', 'None');
    end
    
    
    set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
    %set(gca(), 'YLim', [0.9, 4.1]);
    set(gca(), 'YTick', y_tick_list);
    set(gca(),'TickLabelInterpreter','none');
    xlabel( 'Number of trial');
    ylabel( 'Reward units');
    if (PlotLegend)
        legend(legend_list, 'Interpreter', 'None');
    end
    %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
    CurrentTitleSetDescriptorString = TitleSetDescriptorString;
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.Reward.', OutPutType]);
    write_out_figure(Cur_fh_RewardOverTrials, outfile_fqn);
    
    %%
    %plot own choice rates
    % select the relevant trials:
    FilteredJointTrials_PreferableTargetSelected_A = fnFilterByNamedKernel( PreferableTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
    FilteredJointTrials_PreferableTargetSelected_B = fnFilterByNamedKernel( PreferableTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
    
    
        Cur_fh_ShareOfOwnChoiceOverTrials = figure('Name', 'ShareOfOwnChoiceOverTrials', 'visible', figure_visibility_string);    
    fnFormatDefaultAxes(DefaultAxesType);
    [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
    set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
    legend_list = {};
    hold on
    
    set(gca(), 'YLim', [0.0, 1.0]);
    y_lim = get(gca(), 'YLim');
    
    % mark all trials in which the visibility of the two sides was
    % manipulated
    if (ShowInvisibility)
        fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
    end
    
    fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
    
    
    if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
        fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
    end
    
    
    
    if (ProcessSideA)
        plot(FilteredJointTrialX_Vector, FilteredJointTrials_PreferableTargetSelected_A(FilteredJointTrialX_Vector), 'Color', SideAColor, 'LineWidth', project_line_width);
        legend_list{end + 1} = 'running avg. A';
        if ~isempty(FilteredJointTrialX_Vector)
            TmpMean = mean(PreferableTargetSelected_A(GoodTrialsIdx));
            line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideAColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
            legend_list{end + 1} = 'all trials avg. A';
        end
    end
    if (ProcessSideB)
        plot(FilteredJointTrialX_Vector, FilteredJointTrials_PreferableTargetSelected_B(FilteredJointTrialX_Vector), 'Color', SideBColor, 'LineWidth', project_line_width);
        legend_list{end + 1} = 'runing avg. B';
        if ~isempty(FilteredJointTrialX_Vector)
            TmpMean = mean(PreferableTargetSelected_B(GoodTrialsIdx));
            line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideBColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
            legend_list{end + 1} = 'all trials avg. B';
        end
    end
    hold off
    %
    set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
    %set(gca(), 'YLim', [0.0, 1.0]);
    set(gca(), 'YTick', [0, 0.5, 1]);
    set(gca(),'TickLabelInterpreter','none');
    xlabel( 'Number of trial');
    ylabel( 'Share of own choices');
    if (PlotLegend)
        legend(legend_list, 'Interpreter', 'None');
    end
    if (~isempty(partnerInluenceOnSide) && ~isempty(partnerInluenceOnTarget)) && show_coordination_results_in_fig_title
        partnerInluenceOnSideString = ['Partner effect on side choice of A: ', num2str(partnerInluenceOnSide(1)), '; of B: ', num2str(partnerInluenceOnSide(2))];
        partnerInluenceOnTargetString = ['Partner effect on target choice of A: ', num2str(partnerInluenceOnTarget(1)), '; of B: ', num2str(partnerInluenceOnTarget(2))];
        title([partnerInluenceOnSideString, '; ', partnerInluenceOnTargetString], 'FontSize', 12, 'Interpreter', 'None');
    end
    
    %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
    CurrentTitleSetDescriptorString = TitleSetDescriptorString;
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.highvalue.', OutPutType]);
    write_out_figure(Cur_fh_ShareOfOwnChoiceOverTrials, outfile_fqn);
    
    %%
    % share of bottom choices (for humans)
    if (sum(ismember(DataStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod, {'DAG_VERTICALCHOICE', 'DAG_VERTICALCHOICE_LEFT35MM', 'DAG_VERTICALCHOICERIGHT35mm'})))
        % select the relvant trials:
        FilteredJointTrials_BottomTargetSelected_A = fnFilterByNamedKernel( BottomTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        FilteredJointTrials_BottomTargetSelected_B = fnFilterByNamedKernel( BottomTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        
            Cur_fh_ShareOfBottomChoiceOverTrials = figure('Name', 'ShareOfBottomChoiceOverTrials', 'visible', figure_visibility_string);
        fnFormatDefaultAxes(DefaultAxesType);
        [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
        set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
        legend_list = {};
        hold on
        
        set(gca(), 'YLim', [0.0, 1.0]);
        y_lim = get(gca(), 'YLim');
        
        
        % mark all trials in which the visibility of the two sides was
        % manipulated
        if (ShowInvisibility)
            fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
        end
        
        
        fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
        
        if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
            fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
        end
        
        if (ProcessSideA)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_BottomTargetSelected_A(FilteredJointTrialX_Vector), 'Color', SideAColor, 'LineWidth', project_line_width);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(BottomTargetSelected_A(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideAColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
            end
        end
        if (ProcessSideB)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_BottomTargetSelected_B(FilteredJointTrialX_Vector), 'Color', SideBColor, 'LineWidth', project_line_width);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(BottomTargetSelected_B(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideBColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
            end
        end
        hold off
        %
        set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
        %set(gca(), 'YLim', [0.0, 1.0]);
        set(gca(), 'YTick', [0, 0.5, 1]);
        set(gca(),'TickLabelInterpreter','none');
        xlabel( 'Number of trial');
        ylabel( 'Share of bottom choices');
        if (PlotLegend)
            legend(legend_list, 'Interpreter', 'None');
        end
        %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
        CurrentTitleSetDescriptorString = TitleSetDescriptorString;
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.bottom.', OutPutType]);
        write_out_figure(Cur_fh_ShareOfBottomChoiceOverTrials, outfile_fqn);
    end
    
    %%
    if (sum(ismember(DataStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod, {'DAG_SQUARE'})))
        % select the relvant trials:
        FilteredJointTrials_SubjectiveLeftTargetSelected_A = fnFilterByNamedKernel( SubjectiveLeftTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        FilteredJointTrials_SubjectiveLeftTargetSelected_B = fnFilterByNamedKernel( SubjectiveLeftTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        
            Cur_fh_ShareOfSubjectiveLeftChoiceOverTrials = figure('Name', 'ShareOfSubjectiveLeftChoiceOverTrials', 'visible', figure_visibility_string);
        fnFormatDefaultAxes(DefaultAxesType);
        [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
        set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
        legend_list = {};
        hold on
        
        set(gca(), 'YLim', [0.0, 1.0]);
        y_lim = get(gca(), 'YLim');
        
        
        % mark all trials in which the visibility of the two sides was
        % manipulated
        if (ShowInvisibility)
            fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
        end
        
        
        fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
        
        if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
            fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
        end
        
        
        if (ProcessSideA)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_SubjectiveLeftTargetSelected_A(FilteredJointTrialX_Vector), 'Color', SideAColor, 'LineWidth', project_line_width);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(SubjectiveLeftTargetSelected_A(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideAColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
            end
        end
        if (ProcessSideB)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_SubjectiveLeftTargetSelected_B(FilteredJointTrialX_Vector), 'Color', SideBColor, 'LineWidth', project_line_width);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(SubjectiveLeftTargetSelected_B(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideBColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
            end
        end
        hold off
        %
        set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
        %set(gca(), 'YLim', [0.0, 1.0]);
        set(gca(), 'YTick', [0, 0.5, 1]);
        set(gca(),'TickLabelInterpreter','none');
        xlabel( 'Number of trial');
        ylabel( 'Share of subjective left choices');
        if (PlotLegend)
            legend(legend_list, 'Interpreter', 'None');
        end
        %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
        CurrentTitleSetDescriptorString = TitleSetDescriptorString;
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.subjective.left.', OutPutType]);
        write_out_figure(Cur_fh_ShareOfSubjectiveLeftChoiceOverTrials, outfile_fqn);
    end
    
    %%
    if (sum(ismember(DataStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod, {'DAG_SQUARE'})))
        % select the relvant trials:
        FilteredJointTrials_LeftTargetSelected_A = fnFilterByNamedKernel( LeftTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        FilteredJointTrials_LeftTargetSelected_B = fnFilterByNamedKernel( LeftTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        
            Cur_fh_ShareOfObjectiveLeftChoiceOverTrials = figure('Name', 'ShareOfObjectiveLeftChoiceOverTrials', 'visible', figure_visibility_string);
        fnFormatDefaultAxes(DefaultAxesType);
        [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
        set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
        legend_list = {};
        hold on
        
        set(gca(), 'YLim', [0.0, 1.0]);
        y_lim = get(gca(), 'YLim');
        
        % mark all trials in which the visibility of the two sides was
        % manipulated
        if (ShowInvisibility)
            fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
        end
        
        fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
        
        if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
            fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
        end
        
        
        if (ProcessSideA)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_LeftTargetSelected_A(FilteredJointTrialX_Vector), 'Color', SideAColor, 'LineWidth', project_line_width);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(LeftTargetSelected_A(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideAColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
            end
        end
        if (ProcessSideB)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_LeftTargetSelected_B(FilteredJointTrialX_Vector), 'Color', SideBColor, 'LineWidth', project_line_width);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(LeftTargetSelected_B(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideBColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
            end
        end
        hold off
        %
        set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
        %set(gca(), 'YLim', [0.0, 1.0]);
        set(gca(), 'YTick', [0, 0.5, 1]);
        set(gca(),'TickLabelInterpreter','none');
        xlabel( 'Number of trial');
        ylabel( 'Share of objective left choices');
        if (PlotLegend)
            legend(legend_list, 'Interpreter', 'None');
        end
        %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
        CurrentTitleSetDescriptorString = TitleSetDescriptorString;
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.objective.left.', OutPutType]);
        write_out_figure(Cur_fh_ShareOfObjectiveLeftChoiceOverTrials, outfile_fqn);
    end
    
    % also plot the reaction time per trial
    if (PlotRTBySameness)
        
        % select the relvant data points:
        %InitialTargetReleaseRT_A = DataStruct.data(:, DataStruct.cn.A_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.A_TargetOnsetTime_ms);
        %InitialTargetReleaseRT_B = DataStruct.data(:, DataStruct.cn.B_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.B_TargetOnsetTime_ms);
        
        %TargetAcquisitionRT_A = DataStruct.data(:, DataStruct.cn.A_TargetTouchTime_ms) - DataStruct.data(:, DataStruct.cn.A_TargetOnsetTime_ms);
        %TargetAcquisitionRT_B = DataStruct.data(:, DataStruct.cn.B_TargetTouchTime_ms) - DataStruct.data(:, DataStruct.cn.B_TargetOnsetTime_ms);
        
            Cur_fh_ReactionTimesBySameness = figure('Name', 'ReactionTimesBySameness', 'visible', figure_visibility_string);
        fnFormatDefaultAxes(DefaultAxesType);
        [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
        set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
        legend_list = {};
        hold on
        
        % create the subsets: same own A, same own B, diff own, diff other
        SameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0);
        SameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1);
        DiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1);
        DiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0);
        
        
        if (Plot_RT_differences) && (ProcessSideA) && (ProcessSideA)
            set(gca(), 'YLim', [-650.0, 650.0]);  % let's assume no greater difference than 500ms between acctors?
        else
            set(gca(), 'YLim', [0.0, 1500.0]);  % the timeout is 1500 so this should fit all possible RTs?
        end
        y_lim = get(gca(), 'YLim');
        
        
        % mark all trials in which the visibility of the two sides was
        % manipulated
        if (ShowInvisibility)
            fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
        end
        
        
        % use this as background
        StackedSameDiffCatXData = {[SameOwnA_lidx(GoodTrialsIdx(JointTrialX_Vector))...
            + (2 * SameOwnB_lidx(GoodTrialsIdx(JointTrialX_Vector))) ...
            + (3 * DiffOwn_lidx(GoodTrialsIdx(JointTrialX_Vector))) ...
            + (4 * DiffOther_lidx(GoodTrialsIdx(JointTrialX_Vector)))]};
        
        StackedSameDiffCatColor = {[SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor]};
        StackedSameDiffCatBGTransparency = {[0.33]};
        
        fnPlotStackedCategoriesAtPositionWrapper('StackedBottomToTop', 0.15, StackedSameDiffCatXData, y_lim, StackedSameDiffCatColor, StackedSameDiffCatBGTransparency);
        
        % what to do in solo sessions?
        if (Plot_RT_differences) && (ProcessSideA) && (ProcessSideA)
            %plot(JointTrialX_Vector, AB_InitialHoldReleaseRT_diff(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideAColor/3 + SideBColor/3), 'LineWidth', 2);
            plot(JointTrialX_Vector, AB_InitialTargetReleaseRT_diff(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (2*SideAColor/3 + 2*SideBColor/3), 'LineWidth', project_line_width*0.66);
            plot(JointTrialX_Vector, AB_TargetAcquisitionRT_diff(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideAColor + SideBColor), 'LineWidth', 2);
        else
            if (ProcessSideA)
                %plot(JointTrialX_Vector, A_InitialHoldReleaseRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideAColor/3), 'LineWidth', 2);
                plot(JointTrialX_Vector, A_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (2*SideAColor/3), 'LineWidth', project_line_width*0.66);
                plot(JointTrialX_Vector, A_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideAColor), 'LineWidth', project_line_width);
            end
            if (ProcessSideB)
                %plot(JointTrialX_Vector, B_InitialHoldReleaseRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideBColor/3), 'LineWidth', 2);
                plot(JointTrialX_Vector, B_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (2*SideBColor/3), 'LineWidth', project_line_width*0.66);
                plot(JointTrialX_Vector, B_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideBColor), 'LineWidth', project_line_width);
            end
        end
        
        hold off
        %
        set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
        %set(gca(), 'YLim', [0.0, 1.0]);
        set(gca(),'TickLabelInterpreter','none');
        
        set(gca(), 'YTick', [0, 250, 500, 750, 1000, 1250 1500]);
        xlabel( 'Number of trial');
        
        if (Plot_RT_differences) && (ProcessSideA) && (ProcessSideA)
            set(gca(), 'YTick', [-600, -300, 0, 300, 600]);
            ylabel( 'Reaction time A-B [ms]');
            CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.RTdifferences'];
        else
            set(gca(), 'YTick', [0, 250, 500, 750, 1000, 1250 1500]);
            ylabel( 'Reaction time [ms]');
        end
        
        if (PlotLegend)
            legend(legend_list, 'Interpreter', 'None');
        end
        %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
        CurrentTitleSetDescriptorString = TitleSetDescriptorString;
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.BySameness.', OutPutType]);
        write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);
        
        legend(legend_list, 'Interpreter', 'None');
        
        %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
        CurrentTitleSetDescriptorString = TitleSetDescriptorString;
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.BySameness.legend.', OutPutType]);
        write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);
        
        
    end
    
    % also plot the reaction time per trial
    if (PlotRTHistograms)
        
        % COMMON processing for all RT histograms
        % TODO: always create a distinct category for Invisible trials
        if (strcmp(histnorm_string, 'cdf'))
            histogram_show_median = 0;
        end
        % which reaction time to display
        switch histogram_RT_type_string
            case 'InitialHoldReleaseRT'
                AB_RT_data_diff = AB_InitialHoldReleaseRT_diff;
                A_RT_data = A_InitialHoldReleaseRT;
                B_RT_data = B_InitialHoldReleaseRT;
            case 'InitialTargetReleaseRT'
                AB_RT_data_diff = AB_InitialTargetReleaseRT_diff;
                A_RT_data = A_InitialTargetReleaseRT;
                B_RT_data = B_InitialTargetReleaseRT;
            case 'TargetAcquisitionRT'
                AB_RT_data_diff = AB_TargetAcquisitionRT_diff;
                A_RT_data = A_TargetAcquisitionRT;
                B_RT_data = B_TargetAcquisitionRT;
        end
        CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.RT.', histogram_RT_type_string];
        
        
        
        histogram_bin_width_ms = 16;
        switch Plot_RT_difference_histogram
            case 0
                current_histogram_edge_list = histogram_edges;
            case 1
                current_histogram_edge_list =   histogram_diff_edges;
        end
        histcounts_per_bin = histcounts(AB_RT_data_diff(GoodTrialsIdx), current_histogram_edge_list);
        
        
        
        if (PlotRTHistogramsByByPayoffMatrix)
            
            CurrentTitleSetDescriptorString = TitleSetDescriptorString;
            
            % create the subsets: same own A, same own B, diff own, diff other
            SameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0);
            SameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1);
            DiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1);
            DiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0);
            
            
            % create a stack of category vectors
            if (find(Invisible_AB(GoodTrialsIdx(JointTrialX_Vector))))
                VisSameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0) & (Invisible_AB == 0);
                VisSameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1) & (Invisible_AB == 0);
                VisDiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1) & (Invisible_AB == 0);
                VisDiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0) & (Invisible_AB == 0);
                InvisSameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0) & (Invisible_AB == 1);
                InvisSameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1) & (Invisible_AB == 1);
                InvisDiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1) & (Invisible_AB == 1);
                InvisDiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0) & (Invisible_AB == 1);
                
                legend_list = {'Same_Own_A', 'Same_Own_B', 'Diff_Own', 'Diff_Other', 'Opaque_Same_Own_A', 'Opaque_Same_Own_B', 'Opaque_Diff_Own', 'Opaque_Diff_Other'};
                
                if (histogram_show_median)
                    legend_list = {'Same_Own_A','Same_Own_A', 'Same_Own_B', 'Same_Own_B', 'Diff_Own', 'Diff_Own', 'Diff_Other', 'Diff_Other', 'Opaque_Same_Own_A', 'Opaque_Same_Own_A', 'Opaque_Same_Own_B', 'Opaque_Same_Own_B', 'Opaque_Diff_Own', 'Opaque_Diff_Own', 'Opaque_Diff_Other', 'Opaque_Diff_Other'};
                end
                
                
                StackedCatData.TrialIdxList = {VisSameOwnA_lidx, VisSameOwnB_lidx, VisDiffOwn_lidx, VisDiffOther_lidx, InvisSameOwnA_lidx, InvisSameOwnB_lidx, InvisDiffOwn_lidx, InvisDiffOther_lidx};
                % half the brightness of the invisible trials
                StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor; SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
                StackedCatData.LineStyleList = {'-', '-', '-', '-', ':', ':' , ':', ':'};
                
                StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor; SameOwnAColor*0.66; SameOwnBColor*0.66; DiffOwnColor*0.66; DiffOtherColor*0.66};
                StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor; SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
                StackedCatData.LineStyleList = {'-', '-', '-', '-', '-.', '-.' , '-.', '-.'};
                StackedCatData.SignFactorList = [1, 1, 1, 1, -1, -1, -1, -1];
                
            else
                % no invisible trials just visible
                StackedCatData.TrialIdxList = {SameOwnA_lidx, SameOwnB_lidx, DiffOwn_lidx, DiffOther_lidx};
                legend_list = {'Same_Own_A', 'Same_Own_B', 'Diff_Own', 'Diff_Other'};
                if (histogram_show_median)
                    legend_list = {'Same_Own_A','Same_Own_A', 'Same_Own_B', 'Same_Own_B', 'Diff_Own', 'Diff_Own', 'Diff_Other', 'Diff_Other'};
                end
                
                StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
                StackedCatData.LineStyleList = {'-', '-', '-', '-'};
                StackedCatData.SignFactorList = [1, 1, 1, 1];
            end
            
                Cur_fh_ReactionTimesBySameness = figure('Name', 'ReactionTimeHistogramBySameness', 'visible', figure_visibility_string);
            fnFormatDefaultAxes(DefaultAxesType);
            [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
            set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
            legend_list = {};
            
            CurrentGroupGoodTrialsIdx = GoodTrialsIdx(JointTrialX_Vector);
            plot_differences = Plot_RT_difference_histogram;
            
            fnPlotRTHistogram(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, current_histogram_edge_list, plot_differences, ProcessSideA, ProcessSideB, histcounts_per_bin, histnorm_string, histdisplaystyle_string, histogram_use_histogram_func, histogram_show_median, project_line_width);

            if (plot_differences) && (ProcessSideA) && (ProcessSideA)
                CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.RTdiff'];
            end
            
            outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySameness.', OutPutType]);
            write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);
            
            
            legend(legend_list, 'Interpreter', 'None');            
            outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySameness.legend.', OutPutType]);
            write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);
        end
        if (PlotRTHistogramsBySelectedSideAndEffector)         
            
            % for selected side and used effector
            SubjectiveLeftTargetSelected_A
            SubjectiveLeftTargetSelected_B
            RightHandUsed_A
            RightHandUsed_B
             CurrentTitleSetDescriptorString = TitleSetDescriptorString;
            
            % create the subsets: same own A, same own B, diff own, diff other
            Same_AleftBright = (SubjectiveLeftTargetSelected_A == 1) & (PreferableTargetSelected_B == 0);
            Same_ArightBleft = [];
            Diff_AleftBleft = [];
            Diff_ArightBright = [];
            SameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0);
            SameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1);
            DiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1);
            DiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0);
            
            
            % create a stack of category vectors
            if (find(Invisible_AB(GoodTrialsIdx(JointTrialX_Vector))))
                VisSameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0) & (Invisible_AB == 0);
                VisSameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1) & (Invisible_AB == 0);
                VisDiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1) & (Invisible_AB == 0);
                VisDiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0) & (Invisible_AB == 0);
                InvisSameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0) & (Invisible_AB == 1);
                InvisSameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1) & (Invisible_AB == 1);
                InvisDiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1) & (Invisible_AB == 1);
                InvisDiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0) & (Invisible_AB == 1);
                
                legend_list = {'Same_Own_A', 'Same_Own_B', 'Diff_Own', 'Diff_Other', 'Opaque_Same_Own_A', 'Opaque_Same_Own_B', 'Opaque_Diff_Own', 'Opaque_Diff_Other'};
                
                if (histogram_show_median)
                    legend_list = {'Same_Own_A','Same_Own_A', 'Same_Own_B', 'Same_Own_B', 'Diff_Own', 'Diff_Own', 'Diff_Other', 'Diff_Other', 'Opaque_Same_Own_A', 'Opaque_Same_Own_A', 'Opaque_Same_Own_B', 'Opaque_Same_Own_B', 'Opaque_Diff_Own', 'Opaque_Diff_Own', 'Opaque_Diff_Other', 'Opaque_Diff_Other'};
                end
                
                
                StackedCatData.TrialIdxList = {VisSameOwnA_lidx, VisSameOwnB_lidx, VisDiffOwn_lidx, VisDiffOther_lidx, InvisSameOwnA_lidx, InvisSameOwnB_lidx, InvisDiffOwn_lidx, InvisDiffOther_lidx};
                % half the brightness of the invisible trials
                StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor; SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
                StackedCatLineStyleList = {'-', '-', '-', '-', ':', ':' , ':', ':'};
                
                StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor; SameOwnAColor*0.66; SameOwnBColor*0.66; DiffOwnColor*0.66; DiffOtherColor*0.66};
                StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor; SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
                StackedCatData.LineStyleList.LineStyleList = {'-', '-', '-', '-', '-.', '-.' , '-.', '-.'};
                StackedCatData.SignFactorList = [1, 1, 1, 1, -1, -1, -1, -1];
                
            else
                % no invisible trials just visible
                StackedCatData.TrialIdxList = {SameOwnA_lidx, SameOwnB_lidx, DiffOwn_lidx, DiffOther_lidx};
                legend_list = {'Same_Own_A', 'Same_Own_B', 'Diff_Own', 'Diff_Other'};
                if (histogram_show_median)
                    legend_list = {'Same_Own_A','Same_Own_A', 'Same_Own_B', 'Same_Own_B', 'Diff_Own', 'Diff_Own', 'Diff_Other', 'Diff_Other'};
                end
                
                StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
                StackedCatData.LineStyleList = {'-', '-', '-', '-'};
                StackedCatData.SignFactorList = [1, 1, 1, 1];
            end

                Cur_fh_ReactionTimesBySameness = figure('Name', 'ReactionTimeHistogramBySide', 'visible', figure_visibility_string);
            fnFormatDefaultAxes(DefaultAxesType);
            [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
            set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
            legend_list = {};
            
            CurrentGroupGoodTrialsIdx = GoodTrialsIdx(JointTrialX_Vector);
            plot_differences = Plot_RT_difference_histogram;
            
            fnPlotRTHistogram(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, current_histogram_edge_list, plot_differences, ProcessSideA, ProcessSideB, histcounts_per_bin, histnorm_string, histdisplaystyle_string, histogram_use_histogram_func, histogram_show_median, project_line_width);

            if (plot_differences) && (ProcessSideA) && (ProcessSideA)
                CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.RTdiff'];
            end
            
            outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySide.', OutPutType]);
            write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);
            
            
            legend(legend_list, 'Interpreter', 'None');            
            outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySide.legend.', OutPutType]);
            write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);
            
            
        end
    end
end


% also create a joined sub plot version of the relevant data plots (by copying objects, let's see how this will work)


if (CLoseFiguresOnReturn)
    close all
end
return
end





function [] = fnPlotBackgroundWrapper( PlotBackgroundCategory, ProcessSideA, ProcessSideB, CategoryByXValList, CategoryByXValList_A, CategoryByXValList_B, y_lim, RightEffectorColor, RightEffectorBGTransparency )

if (PlotBackgroundCategory)
    if (ProcessSideA && ~ProcessSideB)
        fnPlotBackgroundByCategory(CategoryByXValList, y_lim, RightEffectorColor, RightEffectorBGTransparency);
    end
    if (~ProcessSideA && ProcessSideB)
        fnPlotBackgroundByCategory(CategoryByXValList, y_lim, RightEffectorColor, RightEffectorBGTransparency);
    end
    % split screen SideA on top, side B on bottom
    if (ProcessSideA && ProcessSideB)
        if isequal(CategoryByXValList_A, CategoryByXValList_B)
            fnPlotBackgroundByCategory(CategoryByXValList_B, y_lim, RightEffectorColor, RightEffectorBGTransparency);
        else
            y_half_height = (y_lim(2) - y_lim(1)) * 0.5;
            fnPlotBackgroundByCategory(CategoryByXValList_A, [(y_lim(1) + y_half_height), y_lim(2)], [1 0 0], 0.33);
            fnPlotBackgroundByCategory(CategoryByXValList_B, [y_lim(1), (y_lim(1) + y_half_height)], [0 0 1], 0.33);
        end
    end
end

return
end

function [] = fnPlotStackedCategoriesAtPositionWrapper( PositionLabel, StackHeightToInitialPLotHeightRatio, StackedXData, y_lim, StackedColors, StackedTransparencies )
y_height = (y_lim(2) - y_lim(1));
num_stacked_items = size(StackedXData, 1);
new_y_lim = y_lim;

switch PositionLabel
    case 'StackedOnTop'
        % make room for the category markers on top of the existing plot
        y_increment_per_stack = y_height * StackHeightToInitialPLotHeightRatio / (num_stacked_items + 1);
        new_y_lim = [y_lim(1), (y_lim(2) + (StackHeightToInitialPLotHeightRatio) * y_height)];
        set(gca(), 'YLim', new_y_lim);
        
    case 'StackedOnBottom'
        % make room for the category markers below the existing plot
        y_increment_per_stack = y_height * StackHeightToInitialPLotHeightRatio / (num_stacked_items + 1);
        new_y_lim = [(y_lim(1) - (StackHeightToInitialPLotHeightRatio) * y_height), y_lim(2)];
        set(gca(), 'YLim', new_y_lim);
        
    case 'StackedBottomToTop'
        % just fill the existing plot area
        y_increment_per_stack = y_height / (num_stacked_items);
        new_y_lim = y_lim;
        
    otherwise
        disp(['Position label: ', PositionLabel, ' not implemented yet, skipping...'])
        return
end


for iStackItem = 1 : num_stacked_items
    CurrentCategoryByXVals = StackedXData{iStackItem};
    CurrentColorByCategoryList = StackedColors{iStackItem};
    CurrentTransparency = StackedTransparencies{iStackItem};
    switch PositionLabel
        case 'StackedOnTop'
            % we want one y_increment as separator from the plots intial YLimits
            CurrentLowY = y_lim(2) + ((iStackItem) * y_increment_per_stack);
            CurrentHighY = CurrentLowY + y_increment_per_stack;
            
        case 'StackedOnBottom'
            % we want one y_increment as separator from the plots intial YLimits
            CurrentLowY = new_y_lim(1) + ((iStackItem - 1) * y_increment_per_stack);
            CurrentHighY = CurrentLowY + y_increment_per_stack;
            
        case 'StackedBottomToTop'
            % we want one y_increment as separator from the plots intial
            % YLimits
            CurrentLowY = y_lim(1) + ((iStackItem - 1) * y_increment_per_stack);
            CurrentHighY = CurrentLowY + y_increment_per_stack;
    end
    % now plot
    fnPlotBackgroundByCategory(CurrentCategoryByXVals, [CurrentLowY, CurrentHighY], CurrentColorByCategoryList, CurrentTransparency);
end

return
end



function [] = fnPlotRTHistogram(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, current_histogram_edge_list, plot_differences, ProcessSideA, ProcessSideB, histcounts_per_bin, histnorm_string, histdisplaystyle_string, histogram_use_histogram_func, histogram_show_median, project_line_width)

StackedCatTrialIdxList = StackedCatData.TrialIdxList;
StackedCatColorList = StackedCatData.ColorList;
StackedCatLineStyleList = StackedCatData.LineStyleList;
StackedCatSignFactorList = StackedCatData.SignFactorList;

% gather multiple plots into one figure
hold on

if (plot_differences)
    AB_RT_data_diff = A_RT_data - B_RT_data;
end

% try to scale the axis
axis_limit = 5 * ceil(max(histcounts_per_bin) / 5) * 5;
if ismember(histnorm_string, {'probability', 'cdf'})
    axis_limit = 1;
end

lower_y = 0;
if ~isempty(find(StackedCatSignFactorList == -1))
    lower_y = -1 * axis_limit;
end
upper_y = 0;
if ~isempty(find(StackedCatSignFactorList == 1))
    upper_y = 1 * axis_limit;
end

if (axis_limit ~= 0)
    set(gca, 'YLim', [lower_y, upper_y]);
end


max_bin_val = 0;
min_bin_val = 0;

hist_AB_struct = struct();
hist_A_struct = struct();
hist_B_struct = struct();




for i_cat = 1 : length(StackedCatTrialIdxList)
    current_CatTrial_Lidx =  StackedCatTrialIdxList{i_cat};
    current_CatColor = StackedCatColorList{i_cat};
    current_CatLineStyle = StackedCatLineStyleList{i_cat};
    current_CatSignFactor = StackedCatSignFactorList(i_cat);
    
    % those are the trial indices in the current category
    current_CatTrial_idx = intersect(find(current_CatTrial_Lidx), CurrentGroupGoodTrialsIdx);
    
    switch histdisplaystyle_string
        case 'bar'
            current_CatFaceColor = current_CatColor;
        case 'stairs'
            current_CatFaceColor = 'none';
    end
    
    if (plot_differences) && (ProcessSideA) && (ProcessSideB)
        if (histogram_use_histogram_func)
            hist_AB_struct.(['h', num2str(i_cat, '%03d')]) = histogram(AB_RT_data_diff(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_string, 'FaceColor', current_CatFaceColor, 'EdgeColor', current_CatColor, 'DisplayStyle', histdisplaystyle_string, 'LineWidth', project_line_width, 'LineStyle', current_CatLineStyle);
            if (histogram_show_median)
                line([median(AB_RT_data_diff(current_CatTrial_idx)), median(AB_RT_data_diff(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.6, 'LineStyle', current_CatLineStyle);
            end
        else
            [N, edges, bin] = histcounts(AB_RT_data_diff(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_string);
            
            if (current_CatSignFactor > 0)
                max_bin_val = max([max_bin_val, (N * current_CatSignFactor)]);
            end
            if (current_CatSignFactor < 0)
                min_bin_val = min([min_bin_val, (N * current_CatSignFactor)]);
            end
            
            plot(diff(edges)*0.5 + edges(1:end-1), N * current_CatSignFactor, 'Color', current_CatColor, 'LineWidth', project_line_width, 'LineStyle', current_CatLineStyle);
            if (histogram_show_median)
                line([median(AB_RT_data_diff(current_CatTrial_idx)), median(AB_RT_data_diff(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.6, 'LineStyle', current_CatLineStyle);
            end
        end
    else
        if (ProcessSideA)
            if (histogram_use_histogram_func)
                hist_A_struct.(['h', num2str(i_cat, '%03d')]) = histogram(A_RT_data(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_string, 'FaceColor', current_CatFaceColor, 'EdgeColor', current_CatColor, 'DisplayStyle', histdisplaystyle_string, 'LineWidth', project_line_width, 'LineStyle', '-');
                if (histogram_show_median)
                    line([median(A_RT_data(current_CatTrial_idx)), median(A_RT_data(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.5, 'LineStyle', '--');
                end
            else
                [N, edges, bin] = histcounts(A_RT_data(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_string);
                plot(diff(edges)*0.5 + edges(1:end-1), N * current_CatSignFactor, 'Color', current_CatColor, 'LineWidth', project_line_width, 'LineStyle', current_CatLineStyle);
                if (histogram_show_median)
                    line([median(A_RT_data(current_CatTrial_idx)), median(A_RT_data(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.6, 'LineStyle', current_CatLineStyle);
                end
            end
        end
        if (ProcessSideB)
            if (histogram_use_histogram_func)
                hist_B_struct.(['h', num2str(i_cat, '%03d')]) = histogram(B_RT_data(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_string, 'FaceColor', current_CatFaceColor, 'EdgeColor', current_CatColor, 'DisplayStyle', histdisplaystyle_string, 'LineWidth', project_line_width, 'LineStyle', ':');
                if (histogram_show_median)
                    line([median(B_RT_data(current_CatTrial_idx)), median(B_RT_data(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.5, 'LineStyle', '-.');
                end
            else
                [N, edges, bin] = histcounts(B_RT_data(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_string);
                plot(diff(edges)*0.5 + edges(1:end-1), N * current_CatSignFactor, 'Color', current_CatColor, 'LineWidth', project_line_width, 'LineStyle', current_CatLineStyle);
                if (histogram_show_median)
                    line([median(B_RT_data(current_CatTrial_idx)), median(B_RT_data(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.6, 'LineStyle', current_CatLineStyle);
                end
            end
        end
    end
end
if (plot_differences)
    % this defines whether A was faster or B
    line([0, 0], get(gca(), 'YLim'), 'Color', [0 0 0], 'LineWidth', project_line_width*0.5, 'LineStyle', '-');
end


hold off
if (axis_limit ~= 0) && (axis_limit ~= 1)
    tmp_upper_y = ceil(max_bin_val / 5) * 5;
    tmp_lower_y = floor(min_bin_val /5) * 5;
    if (tmp_lower_y < 0)
        lower_y = min([tmp_lower_y, -1*tmp_upper_y]);
    end
    if (tmp_upper_y > 0)
        upper_y = max([tmp_lower_y*-1, tmp_upper_y]);
    end
    
    set(gca, 'YLim', [lower_y, upper_y]);
end        %
%set(gca(), 'YLim', [0.0, 1.0]);
set(gca(),'TickLabelInterpreter','none');

switch histnorm_string
    case 'count'
        ylabel( 'Number of trials per bin');
        %set(gca(), 'YTick', [0, 100]);
    case {'probability', 'cdf'}
        ylabel( 'Probability');
        set(gca(), 'YTick', [0, 1]);
end

if (plot_differences) && (ProcessSideA) && (ProcessSideA)
    set(gca(), 'XLim', [-750, 750]);
    set(gca(), 'XTick', [-700, -350, 0, 350, 700]);
    xlabel( 'Reaction time A-B [ms]');
    %CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.RTdiff'];
else
    set(gca(), 'XLim', [0, 1500]);
    set(gca(), 'XTick', [0, 250, 500, 750, 1000, 1250, 1500]);
    xlabel( 'Reaction time [ms]');
end
return
end