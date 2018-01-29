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
%   AR plot: add individual rewards
%   SoC: also create plot for Share of left/ Share of bottom (subjective and objective)
%   Magnifications of switch events to show which actor initiated a
%       reversel (smoothed/non-smoothed)
%
% Quick Hack: return the percent choice for a given trial type
% TODO note that from 20170701 until 20170926 the rewarder was broken and
% did not dispende according tp the BoS schedule, but always just two
% pulses for all combinations

output = [];

% this allows the caller to specify the Output directory
if ~exist('OutputBasePath', 'var')
   OutputBasePath = []; 
end

ProcessReactionTimes = 1; % needs work...
ForceParsingOfExperimentLog = 0; % rewrite the logfiles anyway
CLoseFiguresOnReturn = 1;
CleanOutputDir = 0;
TitleSeparator = '_';
ProcessJointTrialsOnly = 0;

[PathStr, FileName, SessionLogExt] = fileparts(SessionLogFQN);
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
    tmpDataStruct = load(MatFilename);
    DataStruct = tmpDataStruct.report_struct;
    clear tmpDataStruct;
else
    DataStruct = fnParseEventIDEReportSCPv06(fullfile(PathStr, [FileName, SessionLogExt]));
    %save(matFilename, 'DataStruct'); % fnParseEventIDEReportSCPv06 saves by default
end

disp(['Processing: ', SessionLogFQN]);

% now do something

% generate indices for trialtype, effector, targetposition, choice
% position, rewards-payout (target preference) dualNHP trials
TrialSets = fnCollectTrialSets(DataStruct);
if isempty(TrialSets)
    disp(['Found zero trial records in ', SessionLogFQN, ' bailing out...']);
    return
end

% save some output
output.sessionID = unique(DataStruct.data(:, DataStruct.cn.SessionID));
output.FQN = SessionLogFQN;
output.TrialSets = TrialSets;


TitleSetDescriptorString = [];


% now perform simple per session analyses
% plot relative choice left right, relative choice high low for free choice
% and informed choice, perform fisher's exact test between the different
% groups and show significance as symbols. Save plots per Session


% look at all trial types separately...

% only look at successfull choice trials
GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);
ExcludeTrialIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);




% joint trial data!
if ~isempty(TrialSets.ByJointness.DualSubjectJointTrials) 
    % here we only have the actually cooperation trials (for BvS)
    % do some timecourse analysis and imaging
    [tmp_output] = fnAnalyzeJointTrials(SessionLogFQN, OutputBasePath, DataStruct, TrialSets);
    output.joint = tmp_output;
    if (ProcessJointTrialsOnly)
        %disp([]);
        return
    end
elseif ~isempty(TrialSets.ByActivity.SingleSubjectTrials) || ~isempty(TrialSets.ByJointness.DualSubjectSoloTrials)
    [tmp_output] = fnAnalyzeJointTrials(SessionLogFQN, OutputBasePath, DataStruct, TrialSets);
    output.single = tmp_output;
    if (ProcessJointTrialsOnly)
        disp(['Found zero joint trial records in ', SessionLogFQN, ' bailing out...']);        
        return
    end
end



% for starters only analyse single subject sessions?
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
        
        
        
        % this will fail with
        % TODO loop over Sides (to allow sme subject on both sides)
        % TODO turn into proper loop
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
        
        
        
        
        % loop over effector
        NumEffectors = length(fieldnames(TrialSets.ByEffector)) - 2;
        EffectorNames = fieldnames(TrialSets.ByEffector);
        EffectorNames = EffectorNames(3:end);
        for iEffector = 1 : NumEffectors
            CurrentEffector = EffectorNames{iEffector};
            IncludeTrialsIdx = intersect(IncludeNameTrialsIdx, TrialSets.ByEffector.(ActiveSideName).(CurrentEffector));
            ExcludeTrialsIdx = intersect(ExcludeNameTrialsIdx, TrialSets.ByEffector.(ActiveSideName).(CurrentEffector));
            
            if isempty(IncludeTrialsIdx)
                disp(['No trials found for effector name ', CurrentEffector]);
                continue;
            end
            CurrentTitleSetDescriptorString = [TitleSetDescriptorStringPositioningMethod, TitleSeparator, ActiveSideName, TitleSeparator, CurrentEffector];
            
            if strcmp(CurrentSubject, 'Curius') && strcmp(CurrentEffector, 'right')
                tmp = 0;
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
                    MovementTime = DataStruct.data(:, DataStruct.cn.([SideShortHand, '_TargetTouchTime_ms'])) - DataStruct.data(:, DataStruct.cn.([SideShortHand, '_TargetOnsetTime_ms']));
                    ReactionTime = DataStruct.data(:, DataStruct.cn.([SideShortHand, '_InitialFixationReleaseTime_ms'])) - DataStruct.data(:, DataStruct.cn.([SideShortHand, '_TargetOnsetTime_ms']));
                    
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
                % FIXME export the per session data to a population collector,
                % this is a Q'n'D proof of concept
                output.(CurrentSubject).(CurrentPositioningMethod).(ActiveSideName).(CurrentEffector).ContingencyTable = ContingencyTable;
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
			% we add one superfluous replacement string at the end, so
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
