function [] = fn_bos_test_A_RMvsMR_B_BMvsMB()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

data_dir = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2019', 'BoS_manuscript', 'AggregatePlots');
data_file = 'BoS_manuscript..ConfederateTrainedFlaffusCurius.RT.HistogramBySwitches.IniTargRel_05MT_RT.mat';


data_fqn = fullfile(data_dir, data_file);
load(data_fqn); % loads RT_pattern_struct

A_data = RT_pattern_struct.SideA_pattern_histogram_pertrial_struct;
B_data = RT_pattern_struct.SideB_pattern_histogram_pertrial_struct;

% now collect XM(1:3) and MX(5:7), for X in R,B and perform a t-test
% only use those lines with full pattern (so no intersprersed NaNs?)

proto_RM_pre_trials = A_data.RM.nan_padded(:,1:3);
plot_RM_pre_trials = fn_exclude_NaN_from_data(proto_RM_pre_trials, 'all');
denaned_RM_pre_trials = fn_exclude_NaN_from_data(proto_RM_pre_trials, 'row');
proto_MR_post_trials = A_data.MR.nan_padded(:,5:7);
plot_MR_post_trials = fn_exclude_NaN_from_data(proto_MR_post_trials, 'all');
denaned_MR_post_trials = fn_exclude_NaN_from_data(proto_MR_post_trials, 'row');
%[SideA.h, SideA.p, SideA.ci, SideA.stats] = ttest2(denaned_RM_pre_trials(:), denaned_MR_post_trials(:), 'Vartype','unequal');
SideA.denaned = fn_ttest_and_mean('denaned_RM_pre_trials', denaned_RM_pre_trials(:), 'denaned_MR_post_trials', denaned_MR_post_trials(:), 'ttest2_unequalvariance');
SideA.raw = fn_ttest_and_mean('proto_RM_pre_trials', proto_RM_pre_trials(:), 'proto_MR_post_trials', proto_MR_post_trials(:), 'ttest2_unequalvariance');
% SideA.plot = fn_ttest_and_mean('plot_RM_pre_trials', plot_RM_pre_trials(:), 'plot_MR_post_trials', plot_MR_post_trials(:), 'ttest2_unequalvariance');


proto_BM_pre_trials = B_data.BM.nan_padded(:,1:3);
plot_BM_pre_trials = fn_exclude_NaN_from_data(proto_BM_pre_trials, 'all');
denaned_BM_pre_trials = fn_exclude_NaN_from_data(proto_BM_pre_trials, 'row');
proto_MB_post_trials = B_data.MB.nan_padded(:,5:7);
plot_MB_post_trials = fn_exclude_NaN_from_data(proto_MB_post_trials, 'all');
denaned_MB_post_trials = fn_exclude_NaN_from_data(proto_MB_post_trials, 'row');
%[SideB.h, SideB.p, SideB.ci, SideB.stats] = ttest2(denaned_BM_pre_trials(:), denaned_MB_post_trials(:), 'Vartype','unequal');
SideB.denaned = fn_ttest_and_mean('denaned_BM_pre_trials', denaned_BM_pre_trials(:), 'denaned_MB_post_trials', denaned_MB_post_trials(:), 'ttest2_unequalvariance');
SideB.raw = fn_ttest_and_mean('proto_BM_pre_trials', proto_BM_pre_trials(:), 'proto_MB_post_trials', proto_MB_post_trials(:), 'ttest2_unequalvariance');
% SideB.plot = fn_ttest_and_mean('plot_BM_pre_trials', plot_BM_pre_trials(:), 'plot_MB_post_trials', plot_MB_post_trials(:), 'ttest2_unequalvariance');







end


function [ aggregate_struct ] = fn_ttest_and_mean(group_1_name, group_1_data, group_2_name, group_2_data, stat_type)

aggregate_struct.([group_1_name, '_mean']) = mean(group_1_data(:), 'omitnan');
aggregate_struct.([group_2_name, '_mean']) = mean(group_2_data(:), 'omitnan');
aggregate_struct.([group_1_name, '_median']) = median(group_1_data(:), 'omitnan');
aggregate_struct.([group_2_name, '_median']) = median(group_2_data(:), 'omitnan');
aggregate_struct.([group_1_name, '_std']) = std(group_1_data(:), 'omitnan');
aggregate_struct.([group_2_name, '_std']) = std(group_2_data(:), 'omitnan');


switch stat_type
	case 'ttest2'
		[aggregate_struct.h, aggregate_struct.p, aggregate_struct.ci, aggregate_struct.stats] = ttest2(group_1_data(:), group_2_data(:));	
	case 'ttest2_unequalvariance'
		[aggregate_struct.h, aggregate_struct.p, aggregate_struct.ci, aggregate_struct.stats] = ttest2(group_1_data(:), group_2_data(:), 'Vartype','unequal');
	otherwise
		error(['Unhandled statitis requested: ', stat_type]);
end

% the first mean and SD
disp([group_1_name, ': (M: ', num2str(mean(group_1_data(:), 'omitnan'), '%.5f'), '; SD: ', num2str(std(group_1_data(:), 'omitnan'))]); 
disp([group_2_name, ': (M: ', num2str(mean(group_2_data(:), 'omitnan'), '%.5f'), '; SD: ', num2str(std(group_2_data(:), 'omitnan'))]); 
disp(['t(', num2str(aggregate_struct.stats.df, '%.4f'), '): ', num2str(aggregate_struct.stats.tstat, '%.4f'), '; p:< ', num2str(aggregate_struct.p, '%.10f')]);
disp(' ');







return
end


function [ denaned_data ] = fn_exclude_NaN_from_data(data, denan_type)

nan_idx = isnan(data);

switch denan_type
	case 'all'
		% this linearises the data
		tmp = data(:);
		denaned_data = tmp(~nan_idx(:));
	case 'row'
		% this will reject all rows with NaNs in the pattern
		nonnan_row_idx = find(sum(nan_idx, 2) == 0);
		denaned_data = data(nonnan_row_idx, :);
	case 'col'
		nonnan_col_idx = find(sum(nan_idx, 1) == 0);
		denaned_data = data(nonnan_col_idx, :);
	otherwise
		error(['Unhandled denan_type: ', denan_type]);
end

return
end
