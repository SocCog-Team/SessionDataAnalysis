function [ output ] = fnAnalyseIndividualSCPSession( SessionLogFQN, OutputBasePath )
%fnAnalyseIndividualSCPSession perform the analysis of individual sessions
%   This function is intended to generate the single session analysis and
%   also to accumulate data into a sessions table for inter session
%   analysis...
% TODO:
%   add all effectors ot the plots (repeat for all used effectors)
%   add all PositioningMethods
%   add all target positions

output = [];

% this allows the caller to specify the Output directory
if ~exist('OutputBasePath', 'var')
   OutputBasePath = []; 
end

ProcessReactionTimes = 0; % needs work...
ForceParsingOfExperimentLog = 1; % rewrite the logfiles anyway
CLoseFiguresOnReturn = 1;
CleanOutputDir = 0;

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

% only look at successfull choice trials
GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);

% for starters onlyanalyse single
if ~isempty(TrialSets.ByActivity.DualSubjectTrials)
    disp('Currently only analyse Single Subject Sessions');
    return
end



% loop over subjects, the first two are by side so skip those
NumSubjects = length(fieldnames(TrialSets.ByName)) - 2;
SubjectNames = fieldnames(TrialSets.ByName);
SubjectNames = SubjectNames(3:end);

% add sessionID loop?


for iSubject = 1 : NumSubjects
    CurrentSubject = SubjectNames{iSubject};
    IncludeNameTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByName.(CurrentSubject));
    TitleSetDescriptorStringName = [TitleSetDescriptorString, CurrentSubject];
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
        if isempty(IncludePositioningMethodTrialsIdx)
            disp(['No trials found for touch target positioning method name ', CurrentPositioningMethod]);
            continue;
        end
        TitleSetDescriptorStringPositioningMethod = [TitleSetDescriptorStringName, '_', CurrentPositioningMethod];
 
        
        % loop over effector
        NumEffectors = length(fieldnames(TrialSets.ByEffector)) - 2;
        EffectorNames = fieldnames(TrialSets.ByEffector);
        EffectorNames = EffectorNames(3:end);
        for iEffector = 1 : NumEffectors
            CurrentEffector = EffectorNames{iEffector};
            IncludeTrialsIdx = intersect(IncludeNameTrialsIdx, TrialSets.ByEffector.(CurrentEffector));
            if isempty(IncludeTrialsIdx)
                disp(['No trials found for effector name ', CurrentEffector]);
                continue;
            end
            TitleSetDescriptorString = [TitleSetDescriptorStringPositioningMethod, '_', CurrentEffector];
            
            if strcmp(CurrentSubject, 'Magnus') && strcmp(CurrentEffector, 'right')
                tmp = 0;
            end
            
            % this will fail with
            if ~isempty(TrialSets.ByActivity.SideA) && ~isempty(TrialSets.ByActivity.SideB)
                disp(['Encountered a nominal single subject session with active trials from both sides, skipping for now']);
                return
            end
            if ~isempty(TrialSets.ByActivity.SideA)
                ActiveSideName = 'SideA';
                SideShortHand = 'A';
            end
            if ~isempty(TrialSets.ByActivity.SideB)
                ActiveSideName = 'SideB';
                SideShortHand = 'B';
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
            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'FreeChoicePctLeftRight'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight));
            end

            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'FreeChoicePctTopBottom'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceTop));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceBottom));
            end

            
            % CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
            % if ~isempty(CurrentTrialTypeIdx)
            % TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
            % ContingencyTable.ColNames(end+1) = {'FreeChoicePctHighLow'};
            % ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
            % ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));
            % end
            %
            % CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            % if ~isempty(CurrentTrialTypeIdx)
            % TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
            % ContingencyTable.ColNames(end+1) = {'InformedChoicePctLeftRight'};
            % ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft));
            % ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight));
            % end
            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'InformedChoicePctHighLow'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));
            end
            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            CurrentTrialTypeIdx = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'InformedChoiceLeftPctHighLow'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));
            end
            
            CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
            CurrentTrialTypeIdx = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight);
            if ~isempty(CurrentTrialTypeIdx)
                TrialInGroupIdxList{end+1} = CurrentTrialTypeIdx;
                ContingencyTable.ColNames(end+1) = {'InformedChoiceRightPctHighLow'};
                ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
                ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));
            end
            
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
                TitleString = [TitleSetDescriptorString, ': ', 'Performance Left/Top/HighReward [%]'];
                [ fh_cur_contingency_table, cur_group_names ] = fnPlotContingencyTable( ContingencyTable.Data, ContingencyTable.RowNames, ContingencyTable.ColNames, group_by_string, TitleString, 'DPZContTable', P_symbol_list, cols_idx_per_symbol, [] );
                
                set(fh_cur_contingency_table, 'Name', ['Performance ', FileName, ' ', TitleSetDescriptorString]);
                % save out per session
                outfile_fqn = fullfile(OutputPath, [FileName, '.', TitleSetDescriptorString, '.Performance.pdf']);
                write_out_figure(fh_cur_contingency_table, outfile_fqn);
                
                % add reaction time analyses, add timestamp refinement for touch panels as
                % well as post-hoc touch and release time determination...
                % initially just show box whiske plots for the same sets as the performance
                % data
                if (ProcessReactionTimes)
                    fh_RT = figure('Name', [TitleSetDescriptorString, ': Reaction and Movement Times']);
                    MovementTime = logData.data(:, logData.cn.([SideShortHand, '_TargetTouchTime_ms'])) - logData.data(:, logData.cn.([SideShortHand, '_TargetOnsetTime_ms']));
                    ReactionTime = logData.data(:, logData.cn.([SideShortHand, '_InitialFixationReleaseTime_ms'])) - logData.data(:, logData.cn.([SideShortHand, '_TargetOnsetTime_ms']));
                    subplot(2, 1, 1);
                    boxplot(ReactionTime, TrialInGroupIdxList);
                    subplot(2, 1, 2);
                    boxplot(MovementTime, TrialInGroupIdxList);
                    set(fh_cur_contingency_table, 'Name', ['ReactionTime ', FileName, ' ', TitleSetDescriptorString]);
                    % save out per session
                    outfile_fqn = fullfile(OutputPath, [FileName, '.', TitleSetDescriptorString, '.ReactionTimes.pdf']);
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

