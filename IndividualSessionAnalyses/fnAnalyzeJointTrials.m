function [ output ] = fnAnalyzeJointTrials( SessionLogFQN, OutputBasePath, DataStruct, TrialSets )
%FNANALYZEJOINTTRIALS Summary of this function goes here
%   Detailed explanation goes here
% ATM this is hardcoded for BvS, needs work to generalize
% TODO:
%   add statistics test for average reward lines versus 2.5 (chance)
%   add statistics test for SOCA and SOCB for joint trials
%   add indicator which hand was used for the time series plots
%   add plots of reaction times/reaction time differences
%   create multi plot figure with vertical stacks of plots (so the timeline is aligned in parallel)
%
% DONE:
%   add grand average lines for SOC and AR plots
%   also execute for non-joint trials (of sessions with joint trials)

output = [];
ProcessReactionTimes = 1; % needs work...
ForceParsingOfExperimentLog = 1; % rewrite the logfiles anyway
CLoseFiguresOnReturn = 1;
CleanOutputDir = 0;
TitleSeparator = '_';

OutPutType = 'pdf';

[PathStr, FileName, ~] = fileparts(SessionLogFQN);

coordination_alpha = 0.05;  % the alpha value for all the tests for coordination
ShowEffectorHandInBackground = 1;
RightEffectorColor = [0.75, 0.75, 0.75];
RightEffectorBGTransparency = 1; % 1 opaque

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

% only look at successfull choice trials
GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.DualSubjectJointTrials);     % exclude non-joint trials
GroupTrialIdxList{end+1} = GoodTrialsIdx;
GroupNameList{end+1} = 'JointTrials';

% Solo trials are trials with another actor present, but not playing
GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.SideA.SoloSubjectTrials);     % exclude non-joint trials
GroupTrialIdxList{end+1} = GoodTrialsIdx;
GroupNameList{end+1} = 'SoloTrialsSideA';

GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.SideB.SoloSubjectTrials);     % exclude non-joint trials
GroupTrialIdxList{end+1} = GoodTrialsIdx;
GroupNameList{end+1} = 'SoloTrialsSideB';

% SingleSubject trials are fom single subject sessions
GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByActivity.SideA.SingleSubjectTrials);     % exclude non-joint trials
GroupTrialIdxList{end+1} = GoodTrialsIdx;
GroupNameList{end+1} = 'SingleSubjectTrialsSideA';

GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByActivity.SideB.SingleSubjectTrials);     % exclude non-joint trials
GroupTrialIdxList{end+1} = GoodTrialsIdx;
GroupNameList{end+1} = 'SingleSubjectTrialsSideB';



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
        switch ChoiceDimension
            case 'mixed'
                sideChoice = [LeftTargetSelected_A(TrialIdx)'; LeftTargetSelected_B(TrialIdx)'];    % this requires the pysical stimulus side (aka objective position)
            case 'left_right'
                sideChoice = [LeftTargetSelected_A(TrialIdx)'; LeftTargetSelected_B(TrialIdx)'];    % this requires the pysical stimulus side (aka objective position)
            case 'top_bottom'
                sideChoice = [BottomTargetSelected_A(TrialIdx)'; BottomTargetSelected_B(TrialIdx)'];    % this requires the pysical stimulus side (aka objective position)
        end
        [partnerInluenceOnSide, partnerInluenceOnTarget] = check_coordination_v1(isOwnChoice, sideChoice);
        coordStruct = check_coordination(isOwnChoice, isBottomChoice, coordination_alpha);
        [sideChoiceIndependence, targetChoiceIndependence] = check_independence(isOwnChoice, isBottomChoice);      
        
        
    else
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
    
    Cur_fh = figure('Name', 'RewardOverTrials');
    fnFormatDefaultAxes('DPZ2017Evaluation');
    [output_rect] = fnFormatPaperSize('DPZ2017Evaluation', gcf, 0.5);
    set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
    hold on
    
    
    set(gca(), 'YLim', [0.9, 4.1]);
    y_lim = get(gca(), 'YLim');
    if (ShowEffectorHandInBackground)
        if (ProcessSideA && ~ProcessSideB)
            fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
        end
        if (~ProcessSideA && ProcessSideB)
            fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
        end
        % split screen SideA on top, side B on bottom
        if (ProcessSideA && ProcessSideB)
            if isequal(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)))
                fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
            else
                y_half_height = (y_lim(2) - y_lim(1)) * 0.5;
                fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), [(y_lim(1) + y_half_height), y_lim(2)], [1 0 0], 0.33);
                fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), [y_lim(1), (y_lim(1) + y_half_height)], [0 0 1], 0.33);
            end
        end
    end
    
    plot(FilteredJointTrialX_Vector, FilteredJointTrials_AvgRewardByTrial_AB(FilteredJointTrialX_Vector), 'Color', [1 0 1], 'LineWidth', 3);
    if ~isempty(FilteredJointTrialX_Vector)
        TmpMean = mean(AvgRewardByTrial_AB(GoodTrialsIdx));
        line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0 0 0], 'LineStyle', '--', 'LineWidth', 3);
    end
    if (ProcessSideA)
        plot(JointTrialX_Vector, RewardByTrial_A(GoodTrialsIdx(JointTrialX_Vector)), 'Color', [1 0 0]);
        
        %plot(FilteredJointTrialX_Vector, RewardByTrial_A(GoodTrialsIdx(FilteredJointTrialX_Vector)), 'Color', [1 0 0]);
        % TmpMean = mean(RewardByTrial_A(GoodTrialsIdx));
        % line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0.66 0 0], 'LineStyle', '--', 'LineWidth', 3);
    end
    if (ProcessSideB)
        plot(JointTrialX_Vector, RewardByTrial_B(GoodTrialsIdx(JointTrialX_Vector)), 'Color', [0 0 1]);
        
        %plot(FilteredJointTrialX_Vector, RewardByTrial_B(GoodTrialsIdx(FilteredJointTrialX_Vector)), 'Color', [0 0 1]);
        % TmpMean = mean(RewardByTrial_B(GoodTrialsIdx));
        % line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0 0 0.66], 'LineStyle', '--', 'LineWidth', 3);
    end
    % % filtered individual rewards
    % plot(FilteredJointTrialX_Vector, FilteredJointTrials_RewardByTrial_A(FilteredJointTrialX_Vector), 'r', 'LineWidth', 2);
    % plot(FilteredJointTrialX_Vector, FilteredJointTrials_RewardByTrial_B(FilteredJointTrialX_Vector), 'b', 'LineWidth', 2);
    hold off
    %
    set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
    set(gca(), 'YLim', [0.9, 4.1]);
    set(gca(), 'YTick', [1, 2, 3, 4]);
    set(gca(),'TickLabelInterpreter','none');
    xlabel( 'Number of trial');
    ylabel( 'Reward units');
    %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
    CurrentTitleSetDescriptorString = TitleSetDescriptorString;
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.Reward.', OutPutType]);
    write_out_figure(Cur_fh, outfile_fqn);
    
    %%
    %plot own choice rates
    % select the relvant trials:
    FilteredJointTrials_PreferableTargetSelected_A = fnFilterByNamedKernel( PreferableTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
    FilteredJointTrials_PreferableTargetSelected_B = fnFilterByNamedKernel( PreferableTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
    
    Cur_fh = figure('Name', 'ShareOfOwnChoiceOverTrials');
    fnFormatDefaultAxes('DPZ2017Evaluation');
    [output_rect] = fnFormatPaperSize('DPZ2017Evaluation', gcf, 0.5);
    set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
    hold on
    
    set(gca(), 'YLim', [0.0, 1.0]);
    y_lim = get(gca(), 'YLim');
    if (ShowEffectorHandInBackground)
        if (ProcessSideA && ~ProcessSideB)
            fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
        end
        if (~ProcessSideA && ProcessSideB)
            fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
        end
        % split screen SideA on top, side B on bottom
        if (ProcessSideA && ProcessSideB)
            if isequal(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)))
                fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
            else
                y_half_height = (y_lim(2) - y_lim(1)) * 0.5;
                fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), [(y_lim(1) + y_half_height), y_lim(2)], [1 0 0], 0.33);
                fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), [y_lim(1), (y_lim(1) + y_half_height)], [0 0 1], 0.33);
            end
        end
    end
    if (ProcessSideA)
        plot(FilteredJointTrialX_Vector, FilteredJointTrials_PreferableTargetSelected_A(FilteredJointTrialX_Vector), 'Color', [1 0 0], 'LineWidth', 3);
        if ~isempty(FilteredJointTrialX_Vector)
            TmpMean = mean(PreferableTargetSelected_A(GoodTrialsIdx));
            line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0.66 0 0], 'LineStyle', '--', 'LineWidth', 3);
        end
    end
    if (ProcessSideB)
        plot(FilteredJointTrialX_Vector, FilteredJointTrials_PreferableTargetSelected_B(FilteredJointTrialX_Vector), 'Color', [0 0 1], 'LineWidth', 3);
        if ~isempty(FilteredJointTrialX_Vector)
            TmpMean = mean(PreferableTargetSelected_B(GoodTrialsIdx));
            line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0 0 0.66], 'LineStyle', '--', 'LineWidth', 3);
        end
    end
    hold off
    %
    set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
    set(gca(), 'YLim', [0.0, 1.0]);
    set(gca(), 'YTick', [0, 0.25, 0.5, 0.75, 1]);
    set(gca(),'TickLabelInterpreter','none');
    xlabel( 'Number of trial');
    ylabel( 'Share of own choices');
    
    if (~isempty(partnerInluenceOnSide) && ~isempty(partnerInluenceOnTarget))
        partnerInluenceOnSideString = ['Partner effect on side choice of A: ', num2str(partnerInluenceOnSide(1)), '; of B: ', num2str(partnerInluenceOnSide(2))];
        partnerInluenceOnTargetString = ['Partner effect on target choice of A: ', num2str(partnerInluenceOnTarget(1)), '; of B: ', num2str(partnerInluenceOnTarget(2))];
        title([partnerInluenceOnSideString, '; ', partnerInluenceOnTargetString], 'Interpreter','none');
    end
    
    %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
    CurrentTitleSetDescriptorString = TitleSetDescriptorString;
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.highvalue.', OutPutType]);
    write_out_figure(Cur_fh, outfile_fqn);
    
    %%
    % share of bottom choices (for humans)
    if (sum(ismember(DataStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod, {'DAG_VERTICALCHOICE', 'DAG_VERTICALCHOICE_LEFT35MM', 'DAG_VERTICALCHOICERIGHT35mm'})))
        % select the relvant trials:
        FilteredJointTrials_BottomTargetSelected_A = fnFilterByNamedKernel( BottomTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        FilteredJointTrials_BottomTargetSelected_B = fnFilterByNamedKernel( BottomTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        
        Cur_fh = figure('Name', 'ShareOfBottomChoiceOverTrials');
        fnFormatDefaultAxes('DPZ2017Evaluation');
        [output_rect] = fnFormatPaperSize('DPZ2017Evaluation', gcf, 0.5);
        set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
        hold on
        
        set(gca(), 'YLim', [0.0, 1.0]);
        y_lim = get(gca(), 'YLim');
        if (ShowEffectorHandInBackground)
            if (ProcessSideA && ~ProcessSideB)
                fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
            end
            if (~ProcessSideA && ProcessSideB)
                fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
            end
            % split screen SideA on top, side B on bottom
            if (ProcessSideA && ProcessSideB)
                if isequal(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)))
                    fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
                else
                    y_half_height = (y_lim(2) - y_lim(1)) * 0.5;
                    fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), [(y_lim(1) + y_half_height), y_lim(2)], [1 0 0], 0.33);
                    fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), [y_lim(1), (y_lim(1) + y_half_height)], [0 0 1], 0.33);
                end
            end
        end
        
        if (ProcessSideA)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_BottomTargetSelected_A(FilteredJointTrialX_Vector), 'Color', [1 0 0], 'LineWidth', 3);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(BottomTargetSelected_A(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0.66 0 0], 'LineStyle', '--', 'LineWidth', 3);
            end
        end
        if (ProcessSideB)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_BottomTargetSelected_B(FilteredJointTrialX_Vector), 'Color', [0 0 1], 'LineWidth', 3);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(BottomTargetSelected_B(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0 0 0.66], 'LineStyle', '--', 'LineWidth', 3);
            end
        end
        hold off
        %
        set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
        set(gca(), 'YLim', [0.0, 1.0]);
        set(gca(), 'YTick', [0, 0.25, 0.5, 0.75, 1]);
        set(gca(),'TickLabelInterpreter','none');
        xlabel( 'Number of trial');
        ylabel( 'Share of bottom choices');
        %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
        CurrentTitleSetDescriptorString = TitleSetDescriptorString;
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.bottom.', OutPutType]);
        write_out_figure(Cur_fh, outfile_fqn);
    end
    
    %%
    if (sum(ismember(DataStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod, {'DAG_SQUARE'})))
        % select the relvant trials:
        FilteredJointTrials_SubjectiveLeftTargetSelected_A = fnFilterByNamedKernel( SubjectiveLeftTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        FilteredJointTrials_SubjectiveLeftTargetSelected_B = fnFilterByNamedKernel( SubjectiveLeftTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        
        Cur_fh = figure('Name', 'ShareOfSubjectiveLeftChoiceOverTrials');
        fnFormatDefaultAxes('DPZ2017Evaluation');
        [output_rect] = fnFormatPaperSize('DPZ2017Evaluation', gcf, 0.5);
        set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
        hold on
        
        set(gca(), 'YLim', [0.0, 1.0]);
        y_lim = get(gca(), 'YLim');
        if (ShowEffectorHandInBackground)
            if (ProcessSideA && ~ProcessSideB)
                fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
            end
            if (~ProcessSideA && ProcessSideB)
                fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
            end
            % split screen SideA on top, side B on bottom
            if (ProcessSideA && ProcessSideB)
                if isequal(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)))
                    fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
                else
                    y_half_height = (y_lim(2) - y_lim(1)) * 0.5;
                    fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), [(y_lim(1) + y_half_height), y_lim(2)], [1 0 0], 0.33);
                    fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), [y_lim(1), (y_lim(1) + y_half_height)], [0 0 1], 0.33);
                end
            end
        end
        
        
        if (ProcessSideA)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_SubjectiveLeftTargetSelected_A(FilteredJointTrialX_Vector), 'Color', [1 0 0], 'LineWidth', 3);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(SubjectiveLeftTargetSelected_A(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0.66 0 0], 'LineStyle', '--', 'LineWidth', 3);
            end
        end
        if (ProcessSideB)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_SubjectiveLeftTargetSelected_B(FilteredJointTrialX_Vector), 'Color', [0 0 1], 'LineWidth', 3);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(SubjectiveLeftTargetSelected_B(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0 0 0.66], 'LineStyle', '--', 'LineWidth', 3);
            end
        end
        hold off
        %
        set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
        set(gca(), 'YLim', [0.0, 1.0]);
        set(gca(), 'YTick', [0, 0.25, 0.5, 0.75, 1]);
        set(gca(),'TickLabelInterpreter','none');
        xlabel( 'Number of trial');
        ylabel( 'Share of subjective left choices');
        %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
        CurrentTitleSetDescriptorString = TitleSetDescriptorString;
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.subjective.left.', OutPutType]);
        write_out_figure(Cur_fh, outfile_fqn);
    end
    
    %%
    if (sum(ismember(DataStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod, {'DAG_SQUARE'})))
        % select the relvant trials:
        FilteredJointTrials_LeftTargetSelected_A = fnFilterByNamedKernel( LeftTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        FilteredJointTrials_LeftTargetSelected_B = fnFilterByNamedKernel( LeftTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
        
        Cur_fh = figure('Name', 'ShateOfObjectiveLeftChoiceOverTrials');
        fnFormatDefaultAxes('DPZ2017Evaluation');
        [output_rect] = fnFormatPaperSize('DPZ2017Evaluation', gcf, 0.5);
        set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
        hold on
        
        set(gca(), 'YLim', [0.0, 1.0]);
        y_lim = get(gca(), 'YLim');
        if (ShowEffectorHandInBackground)
            if (ProcessSideA && ~ProcessSideB)
                fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
            end
            if (~ProcessSideA && ProcessSideB)
                fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
            end
            % split screen SideA on top, side B on bottom
            if (ProcessSideA && ProcessSideB)
                if isequal(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)))
                    fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
                else
                    y_half_height = (y_lim(2) - y_lim(1)) * 0.5;
                    fnPlotBackgroundByCategory(RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), [(y_lim(1) + y_half_height), y_lim(2)], [1 0 0], 0.33);
                    fnPlotBackgroundByCategory(RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), [y_lim(1), (y_lim(1) + y_half_height)], [0 0 1], 0.33);
                end
            end
        end
        
        if (ProcessSideA)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_LeftTargetSelected_A(FilteredJointTrialX_Vector), 'Color', [1 0 0], 'LineWidth', 3);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(LeftTargetSelected_A(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0.66 0 0], 'LineStyle', '--', 'LineWidth', 3);
            end
        end
        if (ProcessSideB)
            plot(FilteredJointTrialX_Vector, FilteredJointTrials_LeftTargetSelected_B(FilteredJointTrialX_Vector), 'Color', [0 0 1], 'LineWidth', 3);
            if ~isempty(FilteredJointTrialX_Vector)
                TmpMean = mean(LeftTargetSelected_B(GoodTrialsIdx));
                line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', [0 0 0.66], 'LineStyle', '--', 'LineWidth', 3);
            end
        end
        hold off
        %
        set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
        set(gca(), 'YLim', [0.0, 1.0]);
        set(gca(), 'YTick', [0, 0.25, 0.5, 0.75, 1]);
        set(gca(),'TickLabelInterpreter','none');
        xlabel( 'Number of trial');
        ylabel( 'Share of objective left choices');
        %write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
        CurrentTitleSetDescriptorString = TitleSetDescriptorString;
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.objective.left.', OutPutType]);
        write_out_figure(Cur_fh, outfile_fqn);
    end
end

if (CLoseFiguresOnReturn)
    close all
end
return
end



function [] = fnPlotBackgroundByCategory( CategoryByXValList, YLimits, ColorByCategoryList, Transparency )
% use patch to plot a color overlay on the current axes.
% CategoryByTrialList gives the category index for each X value
% YLimits gives the lower and upper value for the background plot
% ColorByCategoryList gives the colorspec for each category
% a category index of 0 denotes skip this x value

%TODO:
%   test with multiple categories


% default to full opaqueness (the Variable has a teerible name im matlab)
if ~exist('Transparency', 'var') || isempty(Transparency)
    Transparency = 1;
end

unique_categories_list = unique(CategoryByXValList);

if unique_categories_list(1) == 0
    num_categories = length(unique_categories_list) - 1;
    cat_start_idx = 2;
else
    num_categories = length(unique_categories_list);
    cat_start_idx = 1;
end


if unique_categories_list(1) == 0 && length(unique_categories_list) == 1
    disp('All X values belong to category zero, nothing to do...');
    return
end

if size(ColorByCategoryList, 1) ~= num_categories
    error('Fewer colors than categories defined, no clue what to do...');
end

for i_category = cat_start_idx : length(unique_categories_list)
    CurrentCategory = unique_categories_list(i_category);
    CurrentCatXVals = (CategoryByXValList == CurrentCategory);
    CurrentCatColor = ColorByCategoryList((i_category - cat_start_idx + 1), :);
    
    % collect all XValues as rectangles
    patch_x_array = [];
    patch_y_array = [];
    for i_current_cat_xval = 1 : length(CurrentCatXVals)
        if (CurrentCatXVals(i_current_cat_xval) == 1)
            current_x_list = [ i_current_cat_xval - 0.5; i_current_cat_xval - 0.5; i_current_cat_xval + 0.5; i_current_cat_xval + 0.5];
            current_y_list = [ YLimits(1); YLimits(2); YLimits(2); YLimits(1)];
            if ~isempty(patch_x_array) && isequal(current_x_list(1:2), patch_x_array(3:4, end))
                % this is an extension of the last patch, just extend its
                % end
                patch_x_array(3:4, end) = current_x_list(3:4);
            else
                % add a new patchlet
                patch_x_array = [patch_x_array, current_x_list];
                patch_y_array = [patch_y_array, current_y_list];
            end
        end
    end
    % and now actually display the patch on the plot
    patch('XData', patch_x_array, 'YData', patch_y_array, 'FaceColor', CurrentCatColor, 'EdgeColor', CurrentCatColor, 'EdgeAlpha', Transparency, 'FaceAlpha', Transparency);
end



return
end