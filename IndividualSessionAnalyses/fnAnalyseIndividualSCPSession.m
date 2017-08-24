function [ output ] = fnAnalyseIndividualSCPSession( SessionLogFQN, OutputBasePath )
%fnAnalyseIndividualSCPSession perform the analysis of individual sessions
%   This function is intended to generate the single session analysis and
%   also to accumulate data into a sessions table for inter session
%   analysis...
% TODO:
%   add all effectors ot the plots (repeat for all used effectors)
%   add all target positions
%   also process single target data
%   Save summary log for session database
%   include BvS analysis
%       show moving average of performance per subject (average over 8 to 10 trials)
%       choice left or top, choice high or low, choice common



output = [];

% this allows the caller to specify the Output directory
if ~exist('OutputBasePath', 'var')
   OutputBasePath = []; 
end

ProcessReactionTimes = 1; % needs work...
ForceParsingOfExperimentLog = 1; % rewrite the logfiles anyway
CLoseFiguresOnReturn = 1;
CleanOutputDir = 0;
TitleSeparator = '_';


[PathStr, FileName, ~] = fileparts(SessionLogFQN);
if isempty(OutputBasePath)
    OutputPath = fullfile(PathStr, 'Analysis');
else
    OutputPath = fullfile(OutputBasePath);
end

if isdir(OutputPath) && CleanOutputDir
    disp(['Deleting ', OutputPath]);
    rmdir(OutputPath, 's');
end

% check the current parser version
[~, CurrentEventIDEReportParserVersionString] = fnParseEventIDEReportSCPv06([]);
MatFilename = fullfile(PathStr, [FileName CurrentEventIDEReportParserVersionString '.mat']);
% load if a mat file of the current parsed version exists, otherwise
% reparse
if exist(MatFilename, 'file') && ~(ForceParsingOfExperimentLog)
    tmplogData = load(MatFilename);
    logData = tmplogData.report_struct;
    clear tmplogData;
else
    logData = fnParseEventIDEReportSCPv06(fullfile(PathStr, [FileName '.log']));
    %save(matFilename, 'logData'); % fnParseEventIDEReportSCPv06 saves by default
end

disp(['Processing: ', SessionLogFQN]);

% now do something

% generate indices for trialtype, effector, targetposition, choice
% position, rewards-payout (target preference) dualNHP trials
TrialSets = fnCollectTrialSets(logData);
if isempty(TrialSets)
    disp(['Found zero trial records in ', SessionLogFQN, ' bailing out...']);
    return
end


TitleSetDescriptorString = [];


% now perform simple per session analyses
% plot relative choice left right, relative choice high low for free choice
% and informed choice, perform fisher's exact test between the different
% groups and show significance as symbols. Save plots per Session


% look at all trial types separately...

% only look at successfull choice trials
GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);
ExcludeTrialIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);




% for starters only analyse single subject sessions?
if ~isempty(TrialSets.ByActivity.DualSubjectTrials)
    %disp('Currently only analyze Single Subject Sessions');
    %return
    disp('Dual Subject Session; first process each subject individually')
    
    % extract the name to side mapping (initially assume non changing name 
    % to side mappings during an experiment)
    
    % TODO make this work for arbitrary grouping combinations during each
    % session to allow side changes.
    SubjectA = logData.unique_lists.A_Name(unique(logData.data(:, logData.cn.A_Name_idx)));
    SubjectB = logData.unique_lists.B_Name(unique(logData.data(:, logData.cn.B_Name_idx)));
    %
    SubjectsSideString = ['A.', SubjectA{1}, '.B.', SubjectB{1}];
        
    if isempty(TitleSetDescriptorString)
        SeparatorString = '';
    else
        SeparatorString = TitleSeparator;
    end
        
    TitleSetDescriptorString = [TitleSetDescriptorString, SeparatorString, SubjectsSideString];
end



% loop over subjects, the first two are by side so skip those
NumSubjects = length(fieldnames(TrialSets.ByName)) - 2;
SubjectNames = fieldnames(TrialSets.ByName);
SubjectNames = SubjectNames(3:end);

% add sessionID loop?


for iSubject = 1 : NumSubjects
    CurrentSubject = SubjectNames{iSubject};
    
    IncludeNameTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByName.(CurrentSubject));
    ExcludeNameTrialsIdx = intersect(ExcludeTrialIdx, TrialSets.ByName.(CurrentSubject));
    
    if isempty(TitleSetDescriptorString)
        SeparatorString = '';
    else
        SeparatorString = TitleSeparator;
    end
    TitleSetDescriptorStringName = [TitleSetDescriptorString, SeparatorString, CurrentSubject];
    %TitleSetDescriptorStringName = [TitleSetDescriptorString, CurrentSubject];
    if isempty(IncludeNameTrialsIdx)
        disp(['No trials found for subject name ', CurrentSubject]);
        continue;
    end
    
    
    % loop over positioning methods
    NumPositioningMethods = length(fieldnames(TrialSets.ByTouchTargetPositioningMethod)) - 2;
    PositioningMethodNames = fieldnames(TrialSets.ByTouchTargetPositioningMethod);
    PositioningMethodNames = PositioningMethodNames(3:end);   
    for iPositioningMethod = 1 : NumPositioningMethods
        CurrentPositioningMethod = PositioningMethodNames{iPositioningMethod};
        IncludePositioningMethodTrialsIdx = intersect(IncludeNameTrialsIdx, TrialSets.ByTouchTargetPositioningMethod.(CurrentPositioningMethod));
        ExcludePositioningMethodTrialsIdx = intersect(ExcludeNameTrialsIdx, TrialSets.ByTouchTargetPositioningMethod.(CurrentPositioningMethod));
        if isempty(IncludePositioningMethodTrialsIdx)
            disp(['No good trials found for touch target positioning method name ', CurrentPositioningMethod]);
            continue;
        end
        TitleSetDescriptorStringPositioningMethod = [TitleSetDescriptorStringName, TitleSeparator, CurrentPositioningMethod];
 
        
        % loop over effector
        NumEffectors = length(fieldnames(TrialSets.ByEffector)) - 2;
        EffectorNames = fieldnames(TrialSets.ByEffector);
        EffectorNames = EffectorNames(3:end);
        for iEffector = 1 : NumEffectors
            CurrentEffector = EffectorNames{iEffector};
            IncludeTrialsIdx = intersect(IncludeNameTrialsIdx, TrialSets.ByEffector.(CurrentEffector));
            ExcludeTrialsIdx = intersect(ExcludeNameTrialsIdx, TrialSets.ByEffector.(CurrentEffector));
            
            if isempty(IncludeTrialsIdx)
                disp(['No trials found for effector name ', CurrentEffector]);
                continue;
            end
            CurrentTitleSetDescriptorString = [TitleSetDescriptorStringPositioningMethod, TitleSeparator, CurrentEffector];
            
            if strcmp(CurrentSubject, 'Curius') && strcmp(CurrentEffector, 'right')
                tmp = 0;
            end
            
            % this will fail with
            % TODO loop over Sides (to allow sme subject on both sides)
            if ~isempty(TrialSets.ByActivity.SideA) && ~isempty(TrialSets.ByActivity.SideB)
                disp(['Encountered a nominal single subject session with active trials from both sides, fixing for now']);
                if ~isempty(TrialSets.ByName.SideA.(CurrentSubject))
                   ActiveSideName = 'SideA';
                    SideShortHand = 'A';
                end
                if ~isempty(TrialSets.ByName.SideB.(CurrentSubject))
                   ActiveSideName = 'SideB';
                    SideShortHand = 'B';
                end
                %return
            else
            if ~isempty(TrialSets.ByActivity.SideA)
                ActiveSideName = 'SideA';
                SideShortHand = 'A';
            end
            if ~isempty(TrialSets.ByActivity.SideB)
                ActiveSideName = 'SideB';
                SideShortHand = 'B';
            end
            end
            
            % individual subject analysis
            % loop over all subjects and over all effector (sides) and
            % TouchTargetPositioningMethod (from session header)
            
            % create the contingency table: free choice left/right, free choice
            % high/low, informed choice left/right, informed choice high/low
            ContingencyTable.RowNames = {'Count_left_or_top', 'Count_right_or_low'};	% count, or high low
            ContingencyTable.ColNames = {};
            ContingencyTable.Data = zeros([2, 1]) - 1;
            TrialInGroupIdxList = {};
            TrialInSubGroupIdxList = {};
            RT_SubGroupNamesList = {};
            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
            CurrentExcludeTrialTypeIdx = intersect(ExcludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
            % only include if left right is a trial-variant property (in the current trial subset, but include also non rewarded trials)
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'FC_PctLeftRight'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight));
                RT_SubGroupNamesList{end + 1} = 'FC_Left';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft);
                RT_SubGroupNamesList{end + 1} = 'FC_Right';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight);                
            end

            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
            CurrentExcludeTrialTypeIdx = intersect(ExcludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'FC_PctTopBottom'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceTop));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceBottom));
                RT_SubGroupNamesList{end + 1} = 'FC_Top';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceTop);
                RT_SubGroupNamesList{end + 1} = 'FC_Bottom';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceBottom);
            end

            
            % CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
            % CurrentExcludeTrialTypeIdx = intersect(ExcludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
            % if ~isempty(CurrentTrialTypeIdx)
            %   TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
            %   ContingencyTable.ColNames(end+1) = {'FC_PctHighLow'};
            %   ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
            %   ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));
            %   RT_SubGroupNamesList{end + 1} = 'FC_HighValue';
            %   TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh);
            %   RT_SubGroupNamesList{end + 1} = 'FC_LowValue';
            %   TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow);
            % end
            %
            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            CurrentExcludeTrialTypeIdx = intersect(ExcludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            if ~isempty(CurrentTrialTypeIdx)
              TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
              ContingencyTable.ColNames(end+1) = {'IC_PctLeftRight'};
              ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft));
              ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight));
              RT_SubGroupNamesList{end + 1} = 'IC_Left';
              TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft);
              RT_SubGroupNamesList{end + 1} = 'IC_Right';
              TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft);
            end
            
            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            CurrentExcludeTrialTypeIdx = intersect(ExcludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'IC_PctTopBottom'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceTop));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceBottom));
                RT_SubGroupNamesList{end + 1} = 'IC_Top';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceTop);
                RT_SubGroupNamesList{end + 1} = 'IC_Bottom';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceBottom);
            end

            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            CurrentExcludeTrialTypeIdx = intersect(ExcludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'IC_PctHighLow'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));
                RT_SubGroupNamesList{end + 1} = 'IC_HighValue';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh);
                RT_SubGroupNamesList{end + 1} = 'IC_LowValue';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow);
            end
 
            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            CurrentExcludeTrialTypeIdx = intersect(ExcludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            CurrentTrialTypeIdx = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft);
            CurrentExcludeTrialTypeIdx = intersect(CurrentExcludeTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'IC_LeftPctHighLow'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));
                RT_SubGroupNamesList{end + 1} = 'IC_LeftValueHigh';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh);
                RT_SubGroupNamesList{end + 1} = 'IC_LeftValueLow';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow);
            end
            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            CurrentExcludeTrialTypeIdx = intersect(ExcludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            CurrentTrialTypeIdx = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight);
            CurrentExcludeTrialTypeIdx = intersect(CurrentExcludeTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'IC_RightPctHighLow'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));
                RT_SubGroupNamesList{end + 1} = 'IC_RightValueHigh';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh);
                RT_SubGroupNamesList{end + 1} = 'IC_RightValueLow';
                TrialInSubGroupIdxList{end+1} = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow);
            end
            
            %add simply by position (clean up the positions to deal with the rounding errors)
            % potentially use a plot that shows the magnitudes as circles
            % at the corresponding positiond of a screen-aspect-ratio
            % matched plot?
            
            
            % remove the all -1 column at the beginning
            if isequal(ContingencyTable.Data(:,1), -1 * ones([size(ContingencyTable.Data, 1), 1]))
                ContingencyTable.Data = ContingencyTable.Data(:, 2:end);
            end
            
            %     if size(ContingencyTable.Data, 2) == 1
            %         tmp = 0;
            %     end
            
            if ~(sum(ContingencyTable.Data(:)) == 0)
                % the statistics of the different groups using fisher's exact test
                [ pairwaise_P_matrix, pairwaise_P_matrix_with_chance, P_data_not_chance_list ] = fnGetPairwiseP4FisherExact( ContingencyTable.Data', []);
                
                %[sym_list, p_list, cols_idx_per_symbol] = construct_symbol_list(contingency_table.fisherexact_pairwaise_P_matrix, row_names, col_names, group_by_dim, {'_MSC02'});
                [ P_symbol_list, P_list, cols_idx_per_symbol] = fnConstructP_SymbolList( pairwaise_P_matrix, ContingencyTable.RowNames, ContingencyTable.ColNames, 'col', ContingencyTable.ColNames);
                
                % plot the N result groups
                group_by_string = 'column';
                TitleString = [CurrentTitleSetDescriptorString, ': ', 'Performance Left/Top/HighReward [%]'];
                [ fh_cur_contingency_table, cur_group_names ] = fnPlotContingencyTable( ContingencyTable.Data, ContingencyTable.RowNames, ContingencyTable.ColNames, group_by_string, TitleString, 'DPZContTable', P_symbol_list, cols_idx_per_symbol, [] );
                
                set(fh_cur_contingency_table, 'Name', ['Performance ', FileName, ' ', TitleSetDescriptorString]);
                % save out per session
                outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.Performance.pdf']);
                write_out_figure(fh_cur_contingency_table, outfile_fqn);
                
                % add reaction time analyses, add timestamp refinement for touch panels as
                % well as post-hoc touch and release time determination...
                % initially just show box whiske plots for the same sets as the performance
                % data
                if (ProcessReactionTimes)
                    % TODO split by the two/many different entities per
                    % group, for this also create the two 
                    fh_RT = figure('Name', [CurrentTitleSetDescriptorString, ': Reaction and Movement Times']);
                    % calculate the times for all trials...
                    MovementTime = logData.data(:, logData.cn.([SideShortHand, '_TargetTouchTime_ms'])) - logData.data(:, logData.cn.([SideShortHand, '_TargetOnsetTime_ms']));
                    ReactionTime = logData.data(:, logData.cn.([SideShortHand, '_InitialFixationReleaseTime_ms'])) - logData.data(:, logData.cn.([SideShortHand, '_TargetOnsetTime_ms']));
                    
                    % since our groups are not guaranteed to contain
                    % different trials we need to create artificially
                    % expanded data vectors to allow for the multiple
                    % potentially overlapping sub-groups
                    TmpTrialIdxIdx = [];
                    GroupNameByTrialList = {};
                    NumEmptyGroups = 0;
                    GroupNameList = RT_SubGroupNamesList; % replace by separated by left right
                    for iGroup = 1 : length(TrialInSubGroupIdxList)
                        if ~isempty(TrialInSubGroupIdxList{iGroup})
                            TmpTrialIdxIdx = [TmpTrialIdxIdx; TrialInSubGroupIdxList{iGroup}];
                            TmpGroupNameIdxVector = ones([1, size(TrialInSubGroupIdxList{iGroup}, 1)]) * iGroup;
                            GroupNameByTrialList = [GroupNameByTrialList, GroupNameList(TmpGroupNameIdxVector)];
                        else
                            % found an empty group, try to remap to NaN at
                            NumEmptyGroups = NumEmptyGroups + 1;
                            TmpTrialIdxIdx = [TmpTrialIdxIdx; 0];
                            GroupNameByTrialList = [GroupNameByTrialList, GroupNameList(iGroup)];
                        end
                    end
                    % if we found empty groups try to replace by NaNs just
                    % to get a plot slot filled?
                    if (NumEmptyGroups > 0)
                        ReactionTime(end+1) = NaN;
                        MovementTime(end+1) = NaN;
                        NaNPositionIdx = length(MovementTime);
                        EmptyGroupTrialIdx = find(TmpTrialIdxIdx == 0);
                        TmpTrialIdxIdx(EmptyGroupTrialIdx) = NaNPositionIdx;
                    end
                    
                    ExpandedReactionTime = ReactionTime(TmpTrialIdxIdx);
                    ExpandedMovementTime = MovementTime(TmpTrialIdxIdx);
                    
                    subplot(2, 1, 1);
                    boxplot(ExpandedReactionTime, GroupNameByTrialList);
                    xlabel('ReactionTime [ms]: Target Onset Time to Target Touch Acquisition');
                    subplot(2, 1, 2);
                    boxplot(ExpandedMovementTime, GroupNameByTrialList);
                    xlabel('MovementTime [ms]: Target Onset Time to Intitial Fixation Release');
                    set(fh_cur_contingency_table, 'Name', ['ReactionTime ', FileName, ' ', TitleSetDescriptorString]);
                    % save out per session
                    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.ReactionTimes.pdf']);
                    write_out_figure(fh_RT, outfile_fqn);
                end
            else
                disp([FileName, ': no trials found in the requested subsets, skipping...']);
            end
            
        end % effectors
    end % PositioningMethods
end % subjects

if (CLoseFiguresOnReturn)
    close all;
end

return
end

