function [ output ] = fnAnalyseIndividualSCPSession( SessionLogFQN )
%I Summary of this function goes here
%   Detailed explanation goes here
output = [];

[PathStr, FileName, ~] = fileparts(SessionLogFQN);
% check the current parser version
[~, CurrentEventIDEReportParserVersionString] = fnParseEventIDEReportSCPv06([]);
MatFilename = fullfile(PathStr, [FileName CurrentEventIDEReportParserVersionString '.mat']);
% load if a mat file of the current parsed version exists, otherwise
% reparse
if exist(MatFilename, 'file')
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


% now perform simple per session analyses
% plot relative choice left right, relative choice high low for free choice
% and informed choice, perform fisher's exact test between the different
% groups and show significance as symbols. Save plots per Session

% only look at successfull choice trials
IncludeTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);

% for starters onlyanalyse single 
if ~isempty(TrialSets.ByActivity.DualSubjectTrials)
	disp('Currently only analyse Single Subject Sessions');
	return
end

% this will fail with 
if ~isempty(TrialSets.ByActivity.SideA) && ~isempty(TrialSets.ByActivity.SideB)
	disp(['Encountered a nominal single subject  session with active trials from both sides, skipping for now']);
	return
end
if ~isempty(TrialSets.ByActivity.SideA)
	ActiveSideName = 'SideA';
end
if ~isempty(TrialSets.ByActivity.SideB)
	ActiveSideName = 'SideB';
end

% TODO handle both effectors 
%	loop over all Names

% create the contingency table: free choice left/right, free choice
% high/low, informed choice left/right, informed choice high/low
ContingencyTable.RowNames = {'Count_left_or_high', 'Count_right_or_low'};	% count, or high low
ContingencyTable.ColNames = {};
ContingencyTable.Data = zeros([2, 1]);


CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
ContingencyTable.ColNames(end+1) = {'FreeChoicePctLeftRight'};
ContingencyTable.Data(1,1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft));
ContingencyTable.Data(2,1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight));

% CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.DirectFreeGazeFreeChoice);
% ContingencyTable.ColNames(end+1) = {'FreeChoicePctHighLow'};
% ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
% ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));
% 
% CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
% ContingencyTable.ColNames(end+1) = {'InformedChoicePctLeftRight'};
% ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft));
% ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight));

CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
ContingencyTable.ColNames(end+1) = {'InformedChoicePctHighLow'};
ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));

CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
CurrentTrialTypeIdx = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceLeft);
ContingencyTable.ColNames(end+1) = {'InformedChoiceLeftPctHighLow'};
ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));

CurrentTrialTypeIdx = intersect(IncludeTrialsIdx, TrialSets.ByTrialType.InformedChoice);
CurrentTrialTypeIdx = intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ChoiceRight);
ContingencyTable.ColNames(end+1) = {'InformedChoiceRightPctHighLow'};
ContingencyTable.Data(1,end+1) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueHigh));
ContingencyTable.Data(2,end) = length(intersect(CurrentTrialTypeIdx, TrialSets.ByChoice.(ActiveSideName).ProtoTargetValueLow));



% the statistics of the different groups using fisher's exact test
[ pairwaise_P_matrix, pairwaise_P_matrix_with_chance, P_data_not_chance_list ] = fnGetPairwiseP4FisherExact( ContingencyTable.Data', []);


%[sym_list, p_list, cols_idx_per_symbol] = construct_symbol_list(contingency_table.fisherexact_pairwaise_P_matrix, row_names, col_names, group_by_dim, {'_MSC02'});
[ P_symbol_list, P_list, cols_idx_per_symbol] = fnConstructP_SymbolList( pairwaise_P_matrix, ContingencyTable.RowNames, ContingencyTable.ColNames, 'col', ContingencyTable.ColNames);

% plot the N result groups
group_by_string = 'column';
[ fh_cur_contingency_table, cur_group_names ] = fnPlotContingencyTable( ContingencyTable.Data, ContingencyTable.RowNames, ContingencyTable.ColNames, group_by_string, 'Performance Left/HighReward [%]', '', P_symbol_list, cols_idx_per_symbol, [] );


% save out per session
outfile_fqn = fullfile(PathStr, 'Analysis', [FileName, '.Performance.pdf']);
write_out_figure(fh_cur_contingency_table, outfile_fqn)


% add reaction time analyses, add timestamp refinement for touch panels as
% well as post-hoc touch and release time determination...


return
end

