function [ output_args ] = RT_to_Psee_mapping_exploration( input_args )
%RT_TO_PSEE_MAPPING_EXPLORATION Summary of this function goes here
%   Detailed explanation goes here
windowSize = 8;
%ispc = 1;
minDRT = 50;
k = 0.04;
OutPutType = 'pdf';

A_color = [1 0 0];
B_color = [0 0 1];

B_color = [0, 0.4470, 0.7410];
A_color = [0.85, 0.325, 0.098];

AB_colors = [A_color; B_color];

if ~exist('project_name', 'var') || isempty(project_name)
	% this requires subject_bias_analysis_sm01 to have run with the same project_name
	% which essentially defines the subset of sessions to include
	project_name = 'BoS_human_monkey_2019';
	project_name = 'BoS_manuscript';
end

if ispc
	folder = 'Z:\taskcontroller\SCP_DATA\ANALYSES\PC1000\2018\CoordinationCheck';
	OutputPath = folder;
else
	
	%folder = fullfile('/', 'Volumes', 'social_neuroscience_data', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2019', 'CoordinationCheck');
	%folder = fullfile('/', 'Users', 'smoeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2019', 'CoordinationCheck');
	InputPath = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2019');
	
	if ~isempty(project_name)
		InputPath = fullfile(InputPath, project_name);
	end
	
	folder =fullfile(InputPath, 'CoordinationCheck');
	
	OutputPath = fullfile(InputPath, '4BoSPaper2019');
end

if ~isdir(OutputPath)
	mkdir(OutputPath);
end


% compute for Flaffus-Curius
flaffusCuriusNaiveFilenames = {...
	'DATA_20171019T132932.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20171020T124628.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20171026T150942.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20171027T145027.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20171031T124333.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20171101T123413.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20171102T102500.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20171103T143324.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	};
flaffusCuriusConfFilenames = {...
	'DATA_20180418T143951.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20180419T141311.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20180424T121937.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20180425T133936.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20180426T171117.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
	'DATA_20180427T142541.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice'
	};


% [pSeeNaiv, pOtherChoiceNaiv, corrCoefValueNaive, corrPValueNaive, ...
%     corrCoefAveragedNaive, corrPValueAveragedNaive] = compute_prob_to_see_for_dataset(folder, flaffusCuriusNaiveFilenames, windowSize, [], minDRT, k);
% df_naive = zeros(size(pSeeNaiv));
% for i_sess = 1 : length(pSeeNaiv)
% 	df_naive(i_sess) = length(pSeeNaiv{i_sess}) - 2;
% end

% for stability control

% [data.minDRT12_k04.pSeeConf, data.minDRT12_k04.pOtherChoiceConf, data.minDRT12_k04.corrCoefValueConf, data.minDRT12_k04.corrPValueConf, ...
%     data.minDRT12_k04.corrCoefAveragedConf, data.minDRT12_k04.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], 12.5, k);
%
%
% [data.minDRT25_k04.pSeeConf, data.minDRT25_k04.pOtherChoiceConf, data.minDRT25_k04.corrCoefValueConf, data.minDRT25_k04.corrPValueConf, ...
%     data.minDRT25_k04.corrCoefAveragedConf, data.minDRT25_k04.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], 25, k);
% [data.minDRT50_k04.pSeeConf, data.minDRT50_k04.pOtherChoiceConf, data.minDRT50_k04.corrCoefValueConf, data.minDRT50_k04.corrPValueConf, ...
%     data.minDRT50_k04.corrCoefAveragedConf, data.minDRT50_k04.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], 50, k);
% [data.minDRT75_k04.pSeeConf, data.minDRT75_k04.pOtherChoiceConf, data.minDRT75_k04.corrCoefValueConf, data.minDRT75_k04.corrPValueConf, ...
%     data.minDRT75_k04.corrCoefAveragedConf, data.minDRT75_k04.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], 75, k);
% [data.minDRT100_k04.pSeeConf, data.minDRT100_k04.pOtherChoiceConf, data.minDRT100_k04.corrCoefValueConf, data.minDRT100_k04.corrPValueConf, ...
%     data.minDRT100_k04.corrCoefAveragedConf, data.minDRT100_k04.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], 100, k);
% [data.minDRT200_k04.pSeeConf, data.minDRT200_k04.pOtherChoiceConf, data.minDRT200_k04.corrCoefValueConf, data.minDRT200_k04.corrPValueConf, ...
%     data.minDRT200_k04.corrCoefAveragedConf, data.minDRT200_k04.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], 200, k);
%
%
%
% % k
% [data.minDRT50_k01.pSeeConf, data.minDRT50_k01.pOtherChoiceConf, data.minDRT50_k01.corrCoefValueConf, data.minDRT50_k01.corrPValueConf, ...
%     data.minDRT50_k01.corrCoefAveragedConf, data.minDRT50_k01.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], minDRT, 0.01);
% [data.minDRT50_k02.pSeeConf, data.minDRT50_k02.pOtherChoiceConf, data.minDRT50_k02.corrCoefValueConf, data.minDRT50_k02.corrPValueConf, ...
%     data.minDRT50_k02.corrCoefAveragedConf, data.minDRT50_k02.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], minDRT, 0.02);
% [data.minDRT50_k04.pSeeConf, data.minDRT50_k04.pOtherChoiceConf, data.minDRT50_k04.corrCoefValueConf, data.minDRT50_k04.corrPValueConf, ...
%     data.minDRT50_k04.corrCoefAveragedConf, data.minDRT50_k04.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], minDRT, 0.04);
% [data.minDRT50_k08.pSeeConf, data.minDRT50_k08.pOtherChoiceConf, data.minDRT50_k08.corrCoefValueConf, data.minDRT50_k08.corrPValueConf, ...
%     data.minDRT50_k08.corrCoefAveragedConf, data.minDRT50_k08.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], minDRT, 0.08);
% [data.minDRT50_k16.pSeeConf, data.minDRT50_k16.pOtherChoiceConf, data.minDRT50_k16.corrCoefValueConf, data.minDRT50_k16.corrPValueConf, ...
%     data.minDRT50_k16.corrCoefAveragedConf, data.minDRT50_k16.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, flaffusCuriusConfFilenames, windowSize, [], minDRT, 0.16);
%

filename_list = flaffusCuriusConfFilenames;
filename_list = flaffusCuriusNaiveFilenames;
filename_list = flaffusCuriusConfFilenames;
n_sessions = length(filename_list);
session_set_name = 'flaffusCuriusConfFilenames';
y_limits = [-1 1];



value_source_string_list = {'corrCoefValueConf', 'corrCoefAveragedConf', 'corrPValueConf', 'corrPValueAveragedConf'};

for i_val_src = 1 : length(value_source_string_list)
	value_source_string = value_source_string_list{i_val_src}; % corrCoefValueConf or corrCoefAveragedConf
	
	y_label_string = 'Pearson correlation coefficient r';
	
	
	use_fixed_y_limits = 1;
	use_semilogy = 0;
	if regexp(value_source_string, '^corrPValue');
		use_fixed_y_limits = 0;
		use_semilogy = 0;
		y_label_string = 'Probability p';
	end
	
	
	cur_fh = figure('Name', 'Stability analysis for RT to P(see) mapping');
	
	minDRT_list = {'minDRT12_k04', 'minDRT25_k04', 'minDRT50_k04', 'minDRT75_k04', 'minDRT100_k04', 'minDRT100_k04'};
	minDRT_value_list = [12.5, 25, 50, 75, 100, 200];
	default_value_pos = 3;
	k_value_list = [0.04, 0.04, 0.04, 0.04, 0.04, 0.04];
	n_values = length(minDRT_value_list);
	
	cur_A_list = zeros([n_sessions, n_values]);
	cur_B_list = zeros(size(cur_A_list));
	x_val_array = zeros(size(cur_A_list));
	x_pos_array = zeros(size(cur_A_list));
	value_list = {};
	for i_value = 1 : n_values
		x_pos_array(i_value, :) = (1:1:n_values);
		x_val_array(i_value, :) = minDRT_value_list;
		cur_minDRT = minDRT_value_list(i_value);
		value_list{end+1} = num2str(cur_minDRT);
		cur_k = k_value_list(i_value);
		[data.pSeeConf, data.pOtherChoiceConf, data.corrCoefValueConf, data.corrPValueConf, ...
			data.corrCoefAveragedConf, data.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, filename_list, windowSize, [], cur_minDRT, cur_k);
		cur_A_list(:, i_value) = data.(value_source_string)(1, :);
		cur_B_list(:, i_value) = data.(value_source_string)(2, :);
	end
	
	x_array = x_pos_array;
	%x_array = x_val_array;
	x_ticks = x_array(1, :);
	
	
	subplot(2, 2, 1);
	hold on
	if (use_semilogy)
		semilogy(x_array', cur_A_list');
	else
		plot(x_array', cur_A_list');
	end
	%set(gca, 'XLim', [-1 1]);
	set(gca, 'XTick', x_ticks);
	if (use_fixed_y_limits)
		set(gca(), 'YLim', y_limits);
	end
	plot([x_ticks(default_value_pos) x_ticks(default_value_pos)], get(gca(), 'YLim'), 'k');
	set(gca(), 'XLim', [x_ticks(1), x_ticks(end)]);
	title([value_source_string, ' for agent A for k: 0.04']);
	xlabel('minDRT');
	ylabel(y_label_string);
	set(gca(), 'XTickLabel', value_list);
	hold off
	
	subplot(2, 2, 2);
	hold on
	if (use_semilogy)
		semilogy(x_array', cur_B_list');
	else
		plot(x_array', cur_B_list');
	end
	%set(gca, 'XLim', [-1 1]);
	set(gca, 'XTick', x_ticks);
	if (use_fixed_y_limits)
		set(gca(), 'YLim', y_limits);
	end
	plot([x_ticks(default_value_pos) x_ticks(default_value_pos)], get(gca(), 'YLim'), 'k');
	set(gca(), 'XLim', [x_ticks(1), x_ticks(end)]);
	%set(gca(), 'YTick', [1 1.5 2 2.5 3 3.5 4]);
	title([value_source_string, ' for agent B for k: 0.04']);
	xlabel('minDRT');
	ylabel(y_label_string);
	set(gca(), 'XTickLabel', value_list);
	hold off
	
	
	k_list = {'minDRT50_k01', 'minDRT50_k02', 'minDRT50_k04', 'minDRT50_k08', 'minDRT50_k16'};
	
	minDRT_value_list = [50, 50, 50, 50, 50];
	k_value_list = [0.01, 0.02, 0.04, 0.08, 0.16];
	default_value_pos = 3;
	
	n_values = length(minDRT_value_list);
	
	cur_A_list = zeros([n_sessions, n_values]);
	cur_B_list = zeros(size(cur_A_list));
	x_val_array = zeros(size(cur_A_list));
	x_pos_array = zeros(size(cur_A_list));
	value_list = {};
	for i_value = 1 : n_values
		x_pos_array(i_value, :) = (1:1:n_values);
		x_val_array(i_value, :) = k_value_list;
		cur_minDRT = minDRT_value_list(i_value);
		cur_k = k_value_list(i_value);
		value_list{end+1} = num2str(cur_k);
		[data.pSeeConf, data.pOtherChoiceConf, data.corrCoefValueConf, data.corrPValueConf, ...
			data.corrCoefAveragedConf, data.corrPValueAveragedConf] = compute_prob_to_see_for_dataset(folder, filename_list, windowSize, [], cur_minDRT, cur_k);
		
		cur_A_list(:, i_value) = data.(value_source_string)(1, :);
		cur_B_list(:, i_value) = data.(value_source_string)(2, :);
	end
	
	x_array = x_pos_array;
	x_ticks = x_array(1, :);
	
	
	subplot(2, 2, 3);
	hold on
	if (use_semilogy)
		semilogy(x_array', cur_A_list');
	else
		plot(x_array', cur_A_list');
	end
	%set(gca, 'XLim', [-1 1]);
	set(gca, 'XTick', x_ticks);
	if (use_fixed_y_limits)
		set(gca(), 'YLim', y_limits);
	end
	plot([x_ticks(default_value_pos) x_ticks(default_value_pos)], get(gca(), 'YLim'), 'k');
	set(gca(), 'XLim', [x_ticks(1), x_ticks(end)]);
	%set(gca(), 'YTick', [1 1.5 2 2.5 3 3.5 4]);
	title([value_source_string, ' for agent A for minDRT: 50']);
	xlabel('k');
	ylabel(y_label_string);
	set(gca(), 'XTickLabel', value_list);
	hold off
	
	
	subplot(2, 2, 4);
	hold on
	if (use_semilogy)
		semilogy(x_array', cur_B_list');
	else
		plot(x_array', cur_B_list');
	end
	%set(gca, 'XLim', [-1 1]);
	set(gca, 'XTick', x_ticks);
	if (use_fixed_y_limits)
		set(gca(), 'YLim', y_limits);
	end
	plot([x_ticks(default_value_pos) x_ticks(default_value_pos)], get(gca(), 'YLim'), 'k');
	set(gca(), 'XLim', [x_ticks(1), x_ticks(end)]);
	%set(gca(), 'YTick', [1 1.5 2 2.5 3 3.5 4]);
	title([value_source_string, ' for agent B for minDRT: 50']);
	xlabel('k');
	ylabel(y_label_string);
	set(gca(), 'XTickLabel', value_list);
	hold off
	
	
	%set(gcf, 'PaperSize', [ xSize ySize ], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
	%set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ],  'Position',  [ xLeft yTop xSize ySize ]);
	outfile_fqn = fullfile(OutputPath, ['RT2Psee_mapping_stability', '.', value_source_string, '.', session_set_name, '.', OutPutType]);
	write_out_figure(cur_fh, outfile_fqn);
	
end

return
end



function [pSee, probOtherChoice, corrCoefValue, corrPValue, ...
	corrCoefAveraged, corrPValueAveraged] = compute_prob_to_see_for_dataset(folder, fileArray, windowSize, sessionIndex, minDRT, k )

if (~exist('minDRT', 'var') || isempty(minDRT) )
	minDRT = 50;
end

if (~exist('sessionIndex', 'var') || isempty(sessionIndex) )
	sessionIndex = 1:length(fileArray);
end





nFile = length(unique(sessionIndex));
pSee = cell(1, nFile);
probOtherChoice = cell(1, nFile);
corrCoefValue = zeros(2,nFile);
corrPValue = zeros(2,nFile);
corrCoefAveraged = zeros(2,nFile);
corrPValueAveraged = zeros(2,nFile);

indexLast = 0;
for i = 1:length(fileArray)
	fullname = fullfile(folder, [fileArray{i} '.mat']);
	load(fullname, 'isOwnChoice', 'PerTrialStruct');
	if sessionIndex(i) ~= indexLast
		initialFixationTime = [];
		targetAcquisitionTime = [];
		IniTargRel_05MT_Time = [];
		isOtherChoice = [];
	end
	isOtherChoice = [isOtherChoice, 1 - isOwnChoice];
	initialFixationTime = [initialFixationTime, [PerTrialStruct.A_InitialTargetReleaseRT'; PerTrialStruct.B_InitialTargetReleaseRT']];
	targetAcquisitionTime = [targetAcquisitionTime, [PerTrialStruct.A_TargetAcquisitionRT'; PerTrialStruct.B_TargetAcquisitionRT']];
	IniTargRel_05MT_Time = [IniTargRel_05MT_Time, [PerTrialStruct.A_IniTargRel_05MT_RT'; PerTrialStruct.B_IniTargRel_05MT_RT']];
	
	current_reference_Time = IniTargRel_05MT_Time;
	
	if sessionIndex(i) ~= indexLast
		iSession = sessionIndex(i);
		isOwnChoice = 1 - isOtherChoice; % recompute back to  ensure merging of several files
		% copy the rest to the processing function
		pSeeRaw = calc_probabilities_to_see(current_reference_Time, minDRT, k);
		[corrCoefValue(:,iSession), corrPValue(:,iSession), ...
			corrCoefAveraged(:,iSession), corrPValueAveraged(:,iSession)] ...
			= calc_prob_to_see_correlation(pSeeRaw, isOwnChoice, windowSize);
		
		pSee{iSession} = movmean(pSeeRaw, windowSize, 2);
		probOtherChoice{iSession} = movmean(isOtherChoice, windowSize, 2);
	end
	indexLast = sessionIndex(i);
end
end
