function [ output ] = fnAnalyzeJointTrials( SessionLogFQN, OutputBasePath, DataStruct, TrialSets, project_name, override_directive )
%FNANALYZEJOINTTRIALS Summary of this function goes here
%   Detailed explanation goes here
% ATM this is hardcoded for BvS, needs work to generalize
% TODO:
%   add statistics test for average reward lines versus 2.5 (chance)
%   add statistics test for SOCA and SOCB for joint trials
%   create multi plot figure with vertical stacks of plots (so the timeline is aligned in parallel)
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
%	Writeout a file given the APA style results for statistical tests (like RT)

%
% DONE:
%   add grand average lines for SOC and AR plots
%   also execute for non-joint trials (of sessions with joint trials)
%   add indicator which hand was used for the time series plots
%   promote fnPlotBackgroundByCategory into its own file in the
%       AuxiliaryFunctions repository
%   Also calculate the aggregated coordination measures for the first 200
%   trials
%   add plots of reaction times/reaction time differences
%   Create new RT plot, showing the histogramms for the A-B RTs for the
%       four SameDiff/OwnOther combinations


output = [];
ProcessReactionTimes = 1; % needs work...
ForceParsingOfExperimentLog = 1; % rewrite the logfiles anyway, unless the caller passed datastruct
CLoseFiguresOnReturn = 1;
CleanOutputDir = 0;
SaveMat4CoordinationCheck = 1;
SaveCoordinationSummary = 1;
InvisibleFigures = 0;
PruneOldCoordinationSummaryFiles = 0;
write_stats_to_text_file = 1;


process_IC = 1;
process_FC = 0;
process_coordination_metrics = 1;% this roughly doubles the run time



CoordinationSummaryFileName = 'CoordinationSummary.txt';

TitleSeparator = '_';





OutPutType = 'pdf';
%output_rect_fraction = 1/2.54; % matlab's print will interpret values as INCH even for PaperUnit centimeter specified figures...
output_rect_fraction = 1;	%
paper_unit_string = 'inches'; % centimeters (broken) or inches


if ~exist('project_name', 'var') || isempty(project_name)
	project_name = 'PrimateNeurobiology2018DPZ';
	project_name = 'SfN2008';
	project_name = 'BoS_manuscript';
end


%DefaultAxesType = 'PrimateNeurobiology2018DPZ'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
%DefaultPaperSizeType = 'PrimateNeurobiology2018DPZ0.5'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
% these are of the new style with correct sizes
DefaultAxesType = 'SfN2018'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
DefaultPaperSizeType = 'SfN2018.5'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ




[PathStr, FileName, SessionLogExt] = fileparts(SessionLogFQN);
if strcmp(SessionLogExt, '.triallog')
	FileName = [FileName, SessionLogExt];
end

orange = [255 165 0]/256;
green = [0 1 0];

ShowEffectorHandInBackground = 1;
ShowFasterSideInBackground = 1;
ShowSelectedSidePerSubjectInRewardPlotBG = 1;
ShowTargetSideChoiceCombinations = 1;
ShowOnlyTargetChoiceCombinations = 0;

coordination_alpha = 0.05;  % the alpha value for all the tests for coordination
RightEffectorColor = [0.75, 0.75, 0.75];
RightEffectorBGTransparency = 1; % 1 opaque

SideAColor = [1 0 0];
SideBColor = [0 0 1];
SideABColor = [1 0 1];
SideABColorDark = [0.4980 0 0.4980];

SideARTColor = [1 0 0];
SideBRTColor = [0 0 1];
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


% combinations of objective side choices
A_right_B_left_Color = [0 1.0 0]; % green "starboard", both sujective right
A_right_B_right_Color = [0.3 0.6 0];  % dark yellow both right
A_left_B_left_Color = [0.6 0.3 0];    % light yellow both left
A_left_B_right_Color = [1.0 0 0]; % red "port side"/larboard, both subjectve left


% 20180815 new colors..., for joint report the joint color (well blue
% instead of yellow), for both same use magenta, and for both other use
% green
SameOwnAColor = [1 0 0];%[1 0 0];
SameOwnBColor = [0 0 1];%([255 165 0] / 255);
DiffOwnColor = [1 0 1];%[1 0 0];
DiffOtherColor = [0 1 0];%[0 0 1];



% FIXME legend plotting is incomplete as it will also take patch objects
% into account, so best plot the backgrounds last, but that requires the
% ability to send the most recent plot to the back of an axis set
RTCatPlotInvisible = 0; % do not show the per trial faster subject category plots, but still keep plot scaling compatible with

PlotLegend = 0; % add a lengend to the plots?

PlotRTBySameness = 1;
RT_detrend_order = 1;% the order of the polynomial used to detrend the RT data before calculating the correlation between both agents RT

PlotRTHistograms = 1;
PlotRTHistogramsByByPayoffMatrix = 1;
PlotRTHistogramsByByPayoffMatrixPostSwitchOnly = 1;
PlotRTHistogramsBySelectedSideAndEffector = 1;
Plot_RT_difference_histogramBySelectedSideAndEffector = 0;


Plot_RT_differences = 0;
Plot_RT_difference_histogram = 1;
Plot_histogram_as_boxwhisker_plot = 0;	% not too helpful

% generate scatterplots for RT_A over RT_B and color points by choice/side
% use joint choices, as well as choices of each individual
plot_RT_scatter = 1;
plot_RT_scatter_AB_by_choices = 1;
plot_RT_scatter_AB_by_sides = 1;
plot_RT_scatter_by_others_choices = 1;
plot_RT_scatter_by_own_choices = 1;
RT_scatter_showcorrelations = 1;
RT_scatter_type_list = {'TargetAcquisitionRT', 'InitialTargetReleaseRT', 'InitialHoldReleaseRT', 'IniTargRel_05MT_RT'};


histnorm_string = 'count'; % count, probability, pdf, cdf
histdisplaystyle_string = 'stairs';% bar, stairs
%histogram_RT_type_string = 'TargetAcquisitionRT';% InitialHoldReleaseRT, InitialTargetReleaseRT, TargetAcquisitionRT
histogram_RT_type_list = {'TargetAcquisitionRT', 'InitialTargetReleaseRT', 'InitialHoldReleaseRT', 'IniTargRel_05MT_RT'};
histogram_bin_width_ms = 40;
histogram_edges = (0:histogram_bin_width_ms:1500);
histogram_diff_edges = (-750:histogram_bin_width_ms:750);
histogram_show_median = 1;
histogram_use_histogram_func = 0;



calc_solo_metrics = 0;

% set parameters of the methods for checking the coordination metrics
coordination_metrics_cfg.pValueForMI = 0.01;
coordination_metrics_cfg.memoryLength = 1; % number of previous trials that affect the choices on the current trials
coordination_metrics_cfg.minSampleNum = 6*(2.^(coordination_metrics_cfg.memoryLength+1))*(2.^coordination_metrics_cfg.memoryLength);
coordination_metrics_cfg.stationarySegmentLength = 200;  % number of last trials supposedly corresponding to equilibrium state
coordination_metrics_cfg.minStationarySegmentStart = 20; % earliest possible start of equilibrium state
coordination_metrics_cfg.minDRT = 50; %minimal difference of reaction times allowing the slower partner to se the choice of the faster
coordination_metrics_cfg.check_coordination_alpha = 5*10^-5;
coordination_metrics_cfg.proficiencyThreshold = 2.75;
coordination_metrics_cfg.pValueForFisherExactTests = 0.05;  % we use this for testing the ratio of 4 reward unit trials for the slowe and faster agent
coordination_metrics_cfg.version_counter = 3; % use this to enforce recalculation of the coordination_metrics
coordination_metrics_row_header = [];
plot_transferentropy_per_trial = 1;
plot_mutualinformation_per_trial = 1;

plot_psee_antipreferredchoice_correlation_per_trial = 1;
psee_antipreferredchoice_correlation_RT_name_list = {'pSee_iniTargRel', 'pSee_TargAcq', 'pSee_IniTargRel_05MT'}; % pSee_iniTargRel or pSee_TargAcq
PseeColor = [0.9290, 0.6940, 0.1250];


PlotRTbyChoiceCombination = 1;
full_choice_combinaton_pattern_list = {'RM', 'MR', 'BM', 'MB', 'RB', 'BR', 'RG', 'GR', 'BG', 'GB', 'GM', 'MG'};
selected_choice_combinaton_pattern_list = full_choice_combinaton_pattern_list;
pattern_alignment_offset = 1; % the offset to the position
n_pre_bins = 3;
n_post_bins = 3;
strict_pattern_extension = 1;
pad_mismatch_with_nan = 1;
aggregate_type_meta_list = {'nan_padded'}; %  {'nan_padded', 'raw'}, the raw looks like the 1st derivation



PlotChoicebyOthersSwitches = 1;
ChoicebyOthersSwitches.full_TC_choice_combinaton_pattern_list = {'RRRBBB', 'BBBRRR'};
ChoicebyOthersSwitches.selected_TC_switch_pattern_list = {'RRRBBB', 'BBBRRR'};

ChoicebyOthersSwitches.full_OS_choice_combinaton_pattern_list = {'RRRLLL', 'LLLRRR'};
ChoicebyOthersSwitches.selected_OS_switch_pattern_list = {'RRRLLL', 'LLLRRR'};

ChoicebyOthersSwitches.pattern_alignment_offset = 3;
ChoicebyOthersSwitches.n_pre_bins = 3;
ChoicebyOthersSwitches.n_post_bins = 3;


ChoicebyOthersSwitches.pattern_alignment_offset = 3;
ChoicebyOthersSwitches.n_pre_bins = 5;
ChoicebyOthersSwitches.n_post_bins = 5;


ChoicebyOthersSwitches.strict_pattern_extension = 1;
ChoicebyOthersSwitches.pad_mismatch_with_nan = 0;	% 1 replace non match trial data with NaNs, so eg. RXRBBXB is included, as well as RRRBBB
ChoicebyOthersSwitches.aggregate_type_meta_list = {'nan_padded', 'raw'}; %  {'nan_padded', 'raw'}, the raw looks like the 1st derivation




% 20190220: disable hack to use the same trial selection logic for all
% subjects
% the following id a HACK until we have a "proper" stability detector
%if strcmp(SessionLogFQN, fullfile(PathStr, '20171127T164730.A_20021.B_20022.SCP_01.triallog.txt'))
% for human pair number 6 we do only converge on a strategy after ~270
% trials before that each selected their own
%    coordination_metrics_cfg.stationarySegmentLength = 200-70;  % number of last trials supposedly corresponding to equilibrium state
%end

if strcmp(SessionLogFQN, fullfile(PathStr, '20171121T162619.A_20017.B_10018.SCP_01'))
	% we need to debug this session
	disp('Please debug me: 20171121T162619.A_20017.B_10018.SCP_01');
end


show_SOC_percentage = 1;
show_soloSOC_percentage = 1;
save_SOC_percentage = 1;
show_RTdiff_ttests = 1;
title_fontsize = 8;
title_fontweight = 'bold';
StackHeightToInitialPLotHeightRatio = 0.15;

double_row_aspect_ratio = [];

% show the joint choices for all sufficiently different GoSignalTimes
plot_joint_choices_by_diffGoSignal = 1;
GoSignalQuantum_ms = 100;			% how many milliseconds jitter we allow and still consider GoSignalTimes equal, this needs to match the randomizer somewhat
GoSignal_saturation_ms = 200;		% merge groups with a diff GoSignal larger than this
split_diffGoSignal_eq_0_by_RT = 1;	% instead of reporting the 0 difference case as one class, split it into two, depending on the faster actor
diffGoSignal_eq_0_by_RT_RT_type = 'IniTargRel_05MT_RT';

calc_extra_aggregate_measures = 0;
project_line_width = 0.5;


switch project_name
	case 'PrimateNeurobiology2018DPZ'
		ShowSelectedSidePerSubjectInRewardPlotBG = 1;
		ShowEffectorHandInBackground = 0;
		project_line_width = 2;
		show_coordination_results_in_fig_title = 0;
		DefaultAxesType = 'PrimateNeurobiology2018DPZ'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
		DefaultPaperSizeType = 'PrimateNeurobiology2018DPZ0.5'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
	case {'SfN2008', 'ephys'}
		ShowSelectedSidePerSubjectInRewardPlotBG = 1;
		ShowEffectorHandInBackground = 0;
		project_line_width = 0.5;
		show_coordination_results_in_fig_title = 0;
		OutPutType = 'png';
		OutPutType = 'pdf';
		ShowOnlyTargetChoiceCombinations = 0;
		DefaultAxesType = 'SfN2018'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
		DefaultPaperSizeType = 'SfN2018.5'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
		double_row_aspect_ratio = 1/3*2;
		%make the who-was-faster-plots effectively invisible but still
		%scale the plot to accomodate the required space
		%SideARTColor = [1 1 1];
		%SideBRTColor = [1 1 1];
		%SideABEqualRTColor = [1 1 1];
		RTCatPlotInvisible = 1;
		RTCatPlotInvisible = 0;
		histogram_show_median = 0;
		Add_AR_subplot_to_SoC_plot = 1;
		InvisibleFigures = 1;
		show_coordination_results_in_fig_title = 0;

		% 	% PLOS
		% 	case 'BoS_manuscript'
		% 		ShowSelectedSidePerSubjectInRewardPlotBG = 0;
		% 		ShowEffectorHandInBackground = 0;
		% 		project_line_width = 0.5;
		% 		show_coordination_results_in_fig_title = 0;
		% 		OutPutType = 'png';
		% 		OutPutType = 'pdf';
		% 		ShowOnlyTargetChoiceCombinations = 1;
		% 		ShowTargetSideChoiceCombinations = 1;
		% 		StackHeightToInitialPLotHeightRatio = 0.05;
		% 		ShowEffectorHandInBackground = 0;
		% 		ShowFasterSideInBackground = 0;
		% 		calc_extra_aggregate_measures = 1;
		%
		% 		DefaultAxesType = 'BoS_manuscript'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
		% 		DefaultPaperSizeType = 'BoS_manuscript.5'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
		% 		DefaultPaperSizeType = 'Plos'; % Plos_text_col or Plos
		% 		output_rect_fraction = output_rect_fraction * 0.5;	% only take half
		% 		title_fontsize = 7;
		% 		title_fontweight = 'normal';
		% 		show_RTdiff_ttests = 0;
		% 		show_SOC_percentage = 0;
		% 		%make the who-was-faster-plots effectively invisible but still
		% 		%scale the plot to accomodate the required space
		% 		%SideARTColor = [1 1 1];
		% 		%SideBRTColor = [1 1 1];
		% 		%SideABEqualRTColor = [1 1 1];
		% 		selected_choice_combinaton_pattern_list = {'RM', 'MR', 'BM', 'MB', 'RB', 'BR'};
		% 		RTCatPlotInvisible = 0;
		% 		histogram_show_median = 0;
		% 		Add_AR_subplot_to_SoC_plot = 1;
		% 		InvisibleFigures = 1;

	case {'BoS_manuscript', 'SfN2018'}
		ShowSelectedSidePerSubjectInRewardPlotBG = 0;
		ShowEffectorHandInBackground = 0;
		project_line_width = 0.5;
		show_coordination_results_in_fig_title = 0;
		OutPutType = 'png';
		OutPutType = 'pdf';
		ShowOnlyTargetChoiceCombinations = 1;
		ShowTargetSideChoiceCombinations = 1;
		StackHeightToInitialPLotHeightRatio = 0.05;
		ShowEffectorHandInBackground = 0;
		ShowFasterSideInBackground = 0;
		calc_extra_aggregate_measures = 1;
		show_coordination_results_in_fig_title = 0;

		DefaultAxesType = 'BoS_manuscript'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
		DefaultPaperSizeType = 'BoS_manuscript.5'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
		DefaultPaperSizeType = 'SciAdv'; % Plos_text_col or Plos
		output_rect_fraction = output_rect_fraction * 0.5;	% only take half
		title_fontsize = 7;
		title_fontweight = 'normal';
		show_RTdiff_ttests = 0;
		show_SOC_percentage = 0;
		show_soloSOC_percentage = 1;
		save_SOC_percentage = 1;

		%make the who-was-faster-plots effectively invisible but still
		%scale the plot to accomodate the required space
		%SideARTColor = [1 1 1];
		%SideBRTColor = [1 1 1];
		%SideABEqualRTColor = [1 1 1];
		selected_choice_combinaton_pattern_list = {'RM', 'MR', 'BM', 'MB', 'RB', 'BR'};
		RTCatPlotInvisible = 0;
		Add_AR_subplot_to_SoC_plot = 1;
		InvisibleFigures = 1;

		Plot_histogram_as_boxwhisker_plot = 0;	% not too helpful
		%histnorm_string = 'count'; % count, probability, pdf, cdf
		%histnorm_string = 'normalized_count'; % this is spcial to deal with to class histgrams with one inverted/negative class
		histnorm_string = 'percentage_count'; % this is spcial to deal with to class histgrams with one inverted/negative class

		histdisplaystyle_string = 'stairs';% bar, stairs
		%histogram_RT_type_string = 'TargetAcquisitionRT';% InitialHoldReleaseRT, InitialTargetReleaseRT, TargetAcquisitionRT
		histogram_RT_type_list = {'TargetAcquisitionRT', 'InitialTargetReleaseRT', 'InitialHoldReleaseRT', 'IniTargRel_05MT_RT'};
		histogram_bin_width_ms = 50;
		histogram_edges = (0:histogram_bin_width_ms:1500);
		histogram_diff_edges = (-750:histogram_bin_width_ms:750);
		histogram_show_median = 0;
		histogram_use_histogram_func = 0;
		double_row_aspect_ratio = 1/3*2;
end

% manual override
% InvisibleFigures = 0;

% no GUI means no figure windows possible, so try to work around that
if (fnIsMatlabRunningInTextMode())
	InvisibleFigures = 1;
end

if (InvisibleFigures)
	figure_visibility_string = 'off';
else
	figure_visibility_string = 'on';
end


% this allows the caller to specify the Output directory
if ~exist('OutputBasePath', 'var')
	OutputBasePath = [];
end

if ~isdir(OutputBasePath)
	mkdir(OutputBasePath);
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

% write one file per subject
current_stats_to_text_FQN = [];
current_stats_to_text_ext = '.statistics.txt';


% load the data if it does not exist yet
if ~exist('DataStruct', 'var') || isempty(DataStruct)

	% accept .sessiondir inputs
	[tmp_PathStr, tmp_FileName, tmp_SessionLogExt] = fileparts(SessionLogFQN);
	if strcmp(tmp_SessionLogExt, '.sessiondir')
		SessionLogFQN = fullfile(SessionLogFQN, [tmp_FileName, '.triallog']);
		disp(['Submitted .sessiondir, expanded to: ', SessionLogFQN]);
	end

	[PathStr, FileName, SessionLogExt] = fileparts(SessionLogFQN);
	if strcmp(SessionLogExt, '.triallog')
		% use magic .triallog extension to load the freshest version cheaply,
		% the logic moved into fnParseEventIDEReportSCPv06
		DataStruct = fnParseEventIDEReportSCPv06(fullfile(PathStr, [FileName, SessionLogExt]), ';', '|', override_directive);
		disp(['Processing: ', SessionLogFQN]);
		FileName = [FileName, SessionLogExt];
	elseif strcmp(SessionLogExt, '.txt')
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
			DataStruct = fnParseEventIDEReportSCPv06(fullfile(PathStr, [FileName, SessionLogExt]), ';', '|', override_directive);
			%save(matFilename, 'DataStruct'); % fnParseEventIDEReportSCPv06 saves by default
		end
		disp(['Processing: ', SessionLogFQN]);
	end
end

if (SaveCoordinationSummary)
	CoordinationSummaryFQN = fullfile(OutputPath, CoordinationSummaryFileName);
	if (exist(CoordinationSummaryFQN, 'file') == 2)
		% get information about CoordinationSummaryFQN
		CoordinationSummaryFQN_listing = dir(CoordinationSummaryFQN);
		CurrentTime = now;
		% how long do we give each iteration of fnAnalyzeJointTrials give
		% DANGER: this requires that the analysis machines RTC is synched
		% with the file server's RTC, otherwise things go pear-shaped
		FileTooOldThresholdSeconds = 120;

		if (CoordinationSummaryFQN_listing.datenum < (CurrentTime - (FileTooOldThresholdSeconds / (60 * 60 * 24)))) && PruneOldCoordinationSummaryFiles
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
if strcmp(SessionLogExtension, '.triallog')
	SessionLogName = [SessionLogName, SessionLogExtension];
end


if ~exist('TrialSets', 'var') || isempty('SfN2008')
	TrialSets = fnCollectTrialSets(DataStruct);
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


	% additional TruialSubTypes to loop over
	TrialSubType_list = fieldnames(TrialSets.ByTrialSubType);
	selected_TrialSubType_list = TrialSubType_list(~ismember(TrialSubType_list, {'None', 'SideA', 'SideB'}));

	for i_selected_TrialSubType = 1 : length(selected_TrialSubType_list)
		cur_TrialSubType = selected_TrialSubType_list{i_selected_TrialSubType};
		% only look at successfull choice trials
		GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
		GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
		%GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.DualSubjectJointTrials);     % exclude non-joint trials
		GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialSubType.(cur_TrialSubType));             % exclude free choice
		GroupTrialIdxList{end+1} = GoodTrialsIdx;
		GroupNameList{end+1} = ['IC_', cur_TrialSubType];
	end

	if isfield(TrialSets, 'ByConfChoiceCue_RndMethod') && ~isempty(TrialSets.ByConfChoiceCue_RndMethod)
		% be confederate's predictability
		selected_TrialSubType_list = TrialSubType_list(ismember(TrialSubType_list, {'SemiSolo', 'Dyadic', 'DyadicBlockedView'}));
		for i_selected_TrialSubType = 1 : length(selected_TrialSubType_list)
			cur_TrialSubType = selected_TrialSubType_list{i_selected_TrialSubType};
			% only look at successfull choice trials
			GoodTrialsIdx = intersect(TrialSets.ByOutcome.REWARD, TrialSets.ByChoices.NumChoices02);    % exclude trials with only one target (instructed reach, informed reach)
			GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialType.InformedTrials);             % exclude free choice
			%GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByJointness.DualSubjectJointTrials);     % exclude non-joint trials
			GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByTrialSubType.(cur_TrialSubType));             % exclude free choice

			if isfield(TrialSets.ByConfChoiceCue_RndMethod.SideA, 'BLOCKED_GEN_LIST')
				blocked_GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByConfChoiceCue_RndMethod.SideA.BLOCKED_GEN_LIST);
				GroupTrialIdxList{end+1} = blocked_GoodTrialsIdx;
				GroupNameList{end+1} = ['IC_', cur_TrialSubType, '_A_blocked'];
			end

			if isfield(TrialSets.ByConfChoiceCue_RndMethod.SideA, 'RND_GEN_LIST')
				shuffled_GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByConfChoiceCue_RndMethod.SideA.RND_GEN_LIST);
				GroupTrialIdxList{end+1} = shuffled_GoodTrialsIdx;
				GroupNameList{end+1} = ['IC_', cur_TrialSubType, '_A_shuffled'];
			end

			if isfield(TrialSets.ByConfChoiceCue_RndMethod.SideB, 'BLOCKED_GEN_LIST')
				blocked_GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByConfChoiceCue_RndMethod.SideB.BLOCKED_GEN_LIST);
				GroupTrialIdxList{end+1} = blocked_GoodTrialsIdx;
				GroupNameList{end+1} = ['IC_', cur_TrialSubType, '_B_blocked'];
			end

			if isfield(TrialSets.ByConfChoiceCue_RndMethod.SideB, 'RND_GEN_LIST')
				shuffled_GoodTrialsIdx = intersect(GoodTrialsIdx, TrialSets.ByConfChoiceCue_RndMethod.SideB.RND_GEN_LIST);
				GroupTrialIdxList{end+1} = shuffled_GoodTrialsIdx;
				GroupNameList{end+1} = ['IC_', cur_TrialSubType, '_B_shuffled'];
			end
		end
	end

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
	disp(['Processing group: ', CurrentGroup]);
	%TitleSetDescriptorString = CurrentGroup;% [];
	TitleSetDescriptorString = [];
	if ~isempty(strfind(CurrentGroup, 'Solo'))
		IsSoloGroup = 1;
	else
		IsSoloGroup = 0;
	end

	if ~isempty(strfind(CurrentGroup, 'SemiSolo'))
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
		if isempty(strfind(CurrentGroup, 'SideA')) && isempty(strfind(CurrentGroup, 'SoloA'))
			ProcessSideA = 0;
		elseif  isempty(strfind(CurrentGroup, 'SideB')) && isempty(strfind(CurrentGroup, 'SoloB'))
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


	if (write_stats_to_text_file)
		current_stats_to_text_FQN_stem = fullfile(OutputPath, [FileName, '.', TitleSetDescriptorString]);
		current_stats_to_text_ext = '.statistics.txt';
		current_stats_to_text_FQN = [current_stats_to_text_FQN_stem, current_stats_to_text_ext];
		% start from a clean slate
		delete(current_stats_to_text_FQN_stem);
		[current_stats_to_text_fd, errmsg] = fopen(current_stats_to_text_FQN, 'w', 'n', 'UTF-8');
		if (current_stats_to_text_fd == -1)
			error(errmsg);
		end
		fn_save_string_list_to_file(current_stats_to_text_fd, ['SessionID: '], FileName, [], write_stats_to_text_file);
		fn_save_string_list_to_file(current_stats_to_text_fd, ['GroupID: '], TitleSetDescriptorString, [], write_stats_to_text_file);

	end

	% 		if (write_stats_to_text_file)
	% 			fprintf(current_stats_to_text_fd, '%s\n', );
	% 		end

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

	% some
	TrialIsJoint = zeros([NumTrials, 1]);
	TrialIsJoint(TrialSets.ByJointness.DualSubjectJointTrials) = 1;
	TrialIsSolo = ~ TrialIsJoint; % tertium non datur...
	NumChoiceTargetsPerTrial = zeros([NumTrials, 1]);
	NumChoiceTargetsPerTrial(TrialSets.ByChoices.NumChoices01) = 1;
	NumChoiceTargetsPerTrial(TrialSets.ByChoices.NumChoices02) = 2;
	TrialIsRewarded = zeros([NumTrials, 1]);
	TrialIsRewarded(TrialSets.ByOutcome.REWARD) = 1;
	TrialIsAborted = ~TrialIsRewarded;


	% get the share of own choices
	PreferableTargetSelected_A = zeros([NumTrials, 1]);
	PreferableTargetSelected_A(TrialSets.ByChoice.SideA.ProtoTargetValueHigh) = 1;
	PreferableTargetSelected_B = zeros([NumTrials, 1]);
	PreferableTargetSelected_B(TrialSets.ByChoice.SideB.ProtoTargetValueHigh) = 1;


	% get the share of own choices
	NonPreferableTargetSelected_A = zeros([NumTrials, 1]);
	NonPreferableTargetSelected_A(TrialSets.ByChoice.SideA.ProtoTargetValueLow) = 1;
	NonPreferableTargetSelected_B = zeros([NumTrials, 1]);
	NonPreferableTargetSelected_B(TrialSets.ByChoice.SideB.ProtoTargetValueLow) = 1;


	% get vectors for side/value choices
	PreferableNoneNonpreferableSelected_A = zeros([NumTrials, 1]) + PreferableTargetSelected_A - NonPreferableTargetSelected_A;
	PreferableNoneNonpreferableSelected_B = zeros([NumTrials, 1]) + PreferableTargetSelected_B - NonPreferableTargetSelected_B;



	% how about solo trials
	A_selects_A = PreferableTargetSelected_A;
	B_selects_B = PreferableTargetSelected_B;
	A_selects_B = NonPreferableTargetSelected_A;
	B_selects_A = NonPreferableTargetSelected_B;
	SameTargetA = A_selects_A & B_selects_A;
	SameTargetB = A_selects_B & B_selects_B;
	DiffOwnTarget = A_selects_A & B_selects_B;
	DiffOtherTarget = A_selects_B & B_selects_A;


	A_changed_target_ldx = [0; diff(PreferableTargetSelected_A)];
	B_changed_target_ldx = [0; diff(PreferableTargetSelected_B)];
	AorB_changed_target_from_last_trial = abs(A_changed_target_ldx) + abs(B_changed_target_ldx);
	AorB_changed_target_from_last_trial_idx = find(AorB_changed_target_from_last_trial);

	% now create a string with our color representations of the 4 choice
	% combinations

	choice_combination_color_string = char(PreferableTargetSelected_A);
	choice_combination_color_string(SameTargetA) = 'R';
	choice_combination_color_string(SameTargetB) = 'B';
	choice_combination_color_string(DiffOwnTarget) = 'M';
	choice_combination_color_string(DiffOtherTarget) = 'G';
	choice_combination_color_string = choice_combination_color_string';


	% value and side choices per side/agent
	A_target_color_choice_string = char(PreferableTargetSelected_A);
	A_target_color_choice_string(logical(PreferableTargetSelected_A)) = 'R';	% A's preferred color is Red
	A_target_color_choice_string(logical(NonPreferableTargetSelected_A)) = 'B';	% A's non-preferred color is Blue
	A_target_color_choice_string = A_target_color_choice_string';

	B_target_color_choice_string = char(PreferableTargetSelected_A);
	B_target_color_choice_string(logical(NonPreferableTargetSelected_B)) = 'R';	% B's non-preferred color is Red
	B_target_color_choice_string(logical(PreferableTargetSelected_B)) = 'B';	% B's preferred color is Bue/Yellow
	B_target_color_choice_string = B_target_color_choice_string';


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
	SubjectiveRightTargetSelected_A = zeros([NumTrials, 1]);
	SubjectiveRightTargetSelected_A(TrialSets.ByChoice.SideA.ChoiceRight) = 1;
	SubjectiveRightTargetSelected_B = zeros([NumTrials, 1]);
	SubjectiveRightTargetSelected_B(TrialSets.ByChoice.SideB.ChoiceRight) = 1;
	% these are objective sides
	LeftTargetSelected_A = zeros([NumTrials, 1]);
	LeftTargetSelected_A(TrialSets.ByChoice.SideA.ChoiceScreenFromALeft) = 1;
	LeftTargetSelected_B = zeros([NumTrials, 1]);
	LeftTargetSelected_B(TrialSets.ByChoice.SideB.ChoiceScreenFromALeft) = 1;
	RightTargetSelected_A = zeros([NumTrials, 1]);
	RightTargetSelected_A(TrialSets.ByChoice.SideA.ChoiceScreenFromARight) = 1;
	RightTargetSelected_B = zeros([NumTrials, 1]);
	RightTargetSelected_B(TrialSets.ByChoice.SideB.ChoiceScreenFromARight) = 1;


	A_objective_side_choice_string = char(PreferableTargetSelected_A);
	A_objective_side_choice_string(logical(RightTargetSelected_A)) = 'R';	% A's preferred color is Red
	A_objective_side_choice_string(logical(LeftTargetSelected_A)) = 'L';	% A's non-preferred color is Blue
	A_objective_side_choice_string = A_objective_side_choice_string';

	B_objective_side_choice_string = char(PreferableTargetSelected_A);
	B_objective_side_choice_string(logical(RightTargetSelected_B)) = 'R';	% B's non-preferred color is Red
	B_objective_side_choice_string(logical(LeftTargetSelected_B)) = 'L';	% B's preferred color is Bue/Yellow
	B_objective_side_choice_string = B_objective_side_choice_string';





	% get vectors for side/value choices
	%PreferableNoneNonpreferableSelected_A = zeros([NumTrials, 1]) + PreferableTargetSelected_A - NonPreferableTargetSelected_A;
	%PreferableNoneNonpreferableSelected_B = zeros([NumTrials, 1]) + PreferableTargetSelected_B - NonPreferableTargetSelected_B;
	RightNoneLeftSelected_A = zeros([NumTrials, 1]) + RightTargetSelected_A - LeftTargetSelected_A;
	RightNoneLeftSelected_B = zeros([NumTrials, 1]) + RightTargetSelected_B - LeftTargetSelected_B;
	SubjectiveRightNoneLeftSelected_A = zeros([NumTrials, 1]) + SubjectiveRightTargetSelected_A - SubjectiveLeftTargetSelected_A;
	SubjectiveRightNoneLeftSelected_B = zeros([NumTrials, 1]) + SubjectiveRightTargetSelected_B - SubjectiveLeftTargetSelected_B;




	A_left = LeftTargetSelected_A;
	B_left = LeftTargetSelected_B;
	A_right = RightTargetSelected_A;
	B_right = RightTargetSelected_B;
	A_left_B_left = A_left & B_left;
	A_right_B_right = A_right & B_right;
	A_left_B_right = A_left & B_right;
	A_right_B_left = A_right & B_left;




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



	% reaction times shouuld be based on the GoSignal
	% collect the GO signal times relative to the TargetOnsetTime_ms
	if isfield(DataStruct.cn, 'A_GoSignalTime_ms')
		A_GoSignalTime = DataStruct.data(:, DataStruct.cn.A_GoSignalTime_ms);
	else
		A_GoSignalTime = DataStruct.data(:, DataStruct.cn.A_TargetOnsetTime_ms);
	end

	if isfield(DataStruct.cn, 'B_GoSignalTime_ms')
		B_GoSignalTime = DataStruct.data(:, DataStruct.cn.B_GoSignalTime_ms);
	else
		B_GoSignalTime = DataStruct.data(:, DataStruct.cn.B_TargetOnsetTime_ms);
	end

	AB_diffGoSignalTime = A_GoSignalTime - B_GoSignalTime;

	% reaction times
	A_InitialHoldReleaseRT = DataStruct.data(:, DataStruct.cn.A_HoldReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.A_InitialFixationOnsetTime_ms);
	B_InitialHoldReleaseRT = DataStruct.data(:, DataStruct.cn.B_HoldReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.B_InitialFixationOnsetTime_ms);
	AB_InitialHoldReleaseRT_diff = A_InitialHoldReleaseRT - B_InitialHoldReleaseRT;

	%A_InitialTargetNonAdjReleaseRT = DataStruct.data(:, DataStruct.cn.A_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.A_TargetOnsetTime_ms);
	%B_InitialTargetNonAdjReleaseRT = DataStruct.data(:, DataStruct.cn.B_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.B_TargetOnsetTime_ms);

	A_InitialTargetReleaseRT = DataStruct.data(:, DataStruct.cn.A_InitialFixationReleaseTime_ms) - A_GoSignalTime;
	B_InitialTargetReleaseRT = DataStruct.data(:, DataStruct.cn.B_InitialFixationReleaseTime_ms) - B_GoSignalTime;
	AB_InitialTargetReleaseRT_diff = A_InitialTargetReleaseRT - B_InitialTargetReleaseRT;

	A_TargetAcquisitionRT = DataStruct.data(:, DataStruct.cn.A_TargetTouchTime_ms) - A_GoSignalTime;
	B_TargetAcquisitionRT = DataStruct.data(:, DataStruct.cn.B_TargetTouchTime_ms) - B_GoSignalTime;
	AB_TargetAcquisitionRT_diff = A_TargetAcquisitionRT - B_TargetAcquisitionRT;

	% InitialTargetRelease reaction time plus half of the movement time
	A_IniTargRel_05MT_RT = A_InitialTargetReleaseRT + 0.5 * (A_TargetAcquisitionRT - A_InitialTargetReleaseRT);
	B_IniTargRel_05MT_RT = B_InitialTargetReleaseRT + 0.5 * (B_TargetAcquisitionRT - B_InitialTargetReleaseRT);
	AB_IniTargRel_05MT_RT_diff = A_IniTargRel_05MT_RT - B_IniTargRel_05MT_RT;

	AB_TrialStartTimeMS = DataStruct.data(:, DataStruct.cn.Timestamp);





	% collect the final performance of solo/single IC trails
	if (IsSoloGroup) && (calc_solo_metrics)
		% the next we want to use as index/key
		current_file_group_id_string = [FileName, '.', 'Solo'];

		PopulationSoloAggregateName = '';
		population_per_session_solo_aggregates_FQN = fullfile(OutputPath, PopulationSoloAggregateName);
		solo_metrics_table = [];
		if exist(population_per_session_solo_aggregates_FQN, 'file')
			load(population_per_session_solo_aggregates_FQN); % contains solo_metrics_table
		end

		% find the index of the current key
		recalc_solo_metrics = 1;
		exchange_cur_solo_metric = 0;
		tmp_key_idx = [];
		if isfield(solo_metrics_table, 'key') && ~isempty(solo_metrics_table.key)
			%stored_coordination_metrics_cfg = [];
			tmp_key_idx = find(strcmp(solo_metrics_table.key, current_file_group_id_string));
			if ~isempty(tmp_key_idx)
				exchange_cur_solo_metric = 1;
			end
		end


		if (recalc_solo_metrics)
			% these are mutually exclusive, but can all coexist in the same
			% triallog file
			if ismember(CurrentGroup, {'IC_SoloTrialsSideA', 'IC_SoloTrialsSideB', 'IC_SingleSubjectTrialsSideA', 'IC_SingleSubjectTrialsSideB'})
				% now get the average SOC and SLC for all trials as well as the last 25
				% trials
				if ismember(CurrentGroup, {'IC_SoloTrialsSideA', 'IC_SingleSubjectTrialsSideA'})
					cur_solo_SOC_A_avg_all = mean(PreferableTargetSelected_A(GoodTrialsIdx));
					cur_solo_SOC_A_avg_last = mean(PreferableTargetSelected_A(GoodTrialsIdx(max([1 (length(GoodTrialsIdx) - 25)]):end)));
					cur_solo_SOC_B_avg_all = mean(PreferableTargetSelected_B(GoodTrialsIdx));
					cur_solo_SOC_B_avg_last = mean(PreferableTargetSelected_B(GoodTrialsIdx(max([1 (length(GoodTrialsIdx) - 25)]):end)));
				end
				if ismember(CurrentGroup, {'IC_SoloTrialsSideB', 'IC_SingleSubjectTrialsSideB'})
					cur_solo_SLC_A_avg_all = mean(LeftTargetSelected_A(GoodTrialsIdx));
					cur_solo_SLC_A_avg_last = mean(LeftTargetSelected_A(GoodTrialsIdx(max([1 (length(GoodTrialsIdx) - 25)]):end)));
					cur_solo_SLC_B_avg_all = mean(LeftTargetSelected_A(GoodTrialsIdx));
					cur_solo_SLC_B_avg_last = mean(LeftTargetSelected_A(GoodTrialsIdx(max([1 (length(GoodTrialsIdx) - 25)]):end)));
				end


			end
		end
	end

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
		isOwnChoiceFullArray = [PreferableTargetSelected_A(:)'; PreferableTargetSelected_B(:)'];

		switch ChoiceDimension
			case 'mixed'
				sideChoice = [LeftTargetSelected_A(TrialIdx)'; LeftTargetSelected_B(TrialIdx)'];    % this requires the pysical stimulus side (aka objective position)
				sideChoiceObjectiveArray = [LeftTargetSelected_A(GoodTrialsIdx)'; LeftTargetSelected_B(GoodTrialsIdx)'];
				sideChoiceObjectiveFullArray = [LeftTargetSelected_A(:)'; LeftTargetSelected_B(:)'];

				sideChoiceSubjectiveArray = [SubjectiveLeftTargetSelected_A(GoodTrialsIdx)'; SubjectiveLeftTargetSelected_B(GoodTrialsIdx)'];
			case 'left_right'
				sideChoice = [LeftTargetSelected_A(TrialIdx)'; LeftTargetSelected_B(TrialIdx)'];    % this requires the pysical stimulus side (aka objective position)
				sideChoiceObjectiveArray = [LeftTargetSelected_A(GoodTrialsIdx)'; LeftTargetSelected_B(GoodTrialsIdx)'];
				sideChoiceObjectiveFullArray = [LeftTargetSelected_A(:)'; LeftTargetSelected_B(:)'];

				sideChoiceSubjectiveArray = [SubjectiveLeftTargetSelected_A(GoodTrialsIdx)'; SubjectiveLeftTargetSelected_B(GoodTrialsIdx)'];
			case {'bottom_top', 'top_bottom'}
				sideChoice = [BottomTargetSelected_A(TrialIdx)'; BottomTargetSelected_B(TrialIdx)'];    % this requires the pysical stimulus side (aka objective position)
				sideChoiceObjectiveArray = [BottomTargetSelected_A(GoodTrialsIdx)'; BottomTargetSelected_B(GoodTrialsIdx)'];
				sideChoiceObjectiveFullArray = [BottomTargetSelected_A(:)'; BottomTargetSelected_B(:)'];
				sideChoiceSubjectiveArray = [BottomTargetSelected_A(GoodTrialsIdx)'; BottomTargetSelected_B(GoodTrialsIdx)'];  %here subjective and objective are the same
		end
		[partnerInluenceOnSide, partnerInluenceOnTarget] = check_coordination_v1(isOwnChoice, sideChoice);
		coordStruct = check_coordination(isOwnChoice, sideChoice, coordination_alpha);
		[sideChoiceIndependence, targetChoiceIndependence] = check_independence(isOwnChoice, sideChoice);

		CoordinationSummaryString = coordStruct.SummaryString;
		CoordinationSummaryCell = coordStruct.SummaryCell;

		fn_save_string_list_to_file(current_stats_to_text_fd, [], {''; 'CoordinationSummary: '}, [], write_stats_to_text_file);
		fn_save_string_list_to_file(current_stats_to_text_fd, [], CoordinationSummaryString, [], write_stats_to_text_file);



		info.session_id = SessionLogName;
		info.ChoiceDimension = ChoiceDimension;
		info.SessionLogFQN = SessionLogFQN;
		info.CurrentGroup = CurrentGroup;
		info.isOwnChoiceArrayHeader = {'A', 'B'};
		info.sideChoiceObjectiveArrayHeader = {'A', 'B',};
		info.TrialSetsDescription = 'Structure of different sets of trials, where the invidual sets are named';

		% include the exploration trials
		TrialsInCurrentSetIdx = GoodTrialsIdx;

		% additional information for all the trials in the current set
		PerTrialStruct.isTrialInvisible_AB = Invisible_AB(TrialsInCurrentSetIdx);
		PerTrialStruct.A_InitialTargetReleaseRT = A_InitialTargetReleaseRT(TrialsInCurrentSetIdx);
		PerTrialStruct.B_InitialTargetReleaseRT = B_InitialTargetReleaseRT(TrialsInCurrentSetIdx);
		PerTrialStruct.AB_InitialTargetReleaseRT_diff = AB_InitialTargetReleaseRT_diff(TrialsInCurrentSetIdx);
		PerTrialStruct.A_TargetAcquisitionRT = A_TargetAcquisitionRT(TrialsInCurrentSetIdx);
		PerTrialStruct.B_TargetAcquisitionRT = B_TargetAcquisitionRT(TrialsInCurrentSetIdx);
		PerTrialStruct.AB_TargetAcquisitionRT_diff = AB_TargetAcquisitionRT_diff(TrialsInCurrentSetIdx);

		PerTrialStruct.A_IniTargRel_05MT_RT = A_IniTargRel_05MT_RT(TrialsInCurrentSetIdx);
		PerTrialStruct.B_IniTargRel_05MT_RT = B_IniTargRel_05MT_RT(TrialsInCurrentSetIdx);
		PerTrialStruct.AB_IniTargRel_05MT_RT_diff = AB_IniTargRel_05MT_RT_diff(TrialsInCurrentSetIdx);

		PerTrialStruct.A_GoSignalTime = A_GoSignalTime(TrialsInCurrentSetIdx);
		PerTrialStruct.B_GoSignalTime = B_GoSignalTime(TrialsInCurrentSetIdx);
		PerTrialStruct.AB_diffGoSignalTime = AB_diffGoSignalTime(TrialsInCurrentSetIdx);

		PerTrialStruct.AB_TrialStartTimeMS = AB_TrialStartTimeMS(TrialsInCurrentSetIdx);
		PerTrialStruct.RewardByTrial_A = RewardByTrial_A(TrialsInCurrentSetIdx);
		PerTrialStruct.RewardByTrial_B = RewardByTrial_B(TrialsInCurrentSetIdx);

		PerTrialStruct.SameTargetA = SameTargetA(TrialsInCurrentSetIdx);
		PerTrialStruct.SameTargetB = SameTargetB(TrialsInCurrentSetIdx);
		PerTrialStruct.DiffOwnTarget = DiffOwnTarget(TrialsInCurrentSetIdx);
		PerTrialStruct.DiffOtherTarget = DiffOtherTarget(TrialsInCurrentSetIdx);

		PerTrialStruct.A_changed_target_ldx = A_changed_target_ldx(TrialsInCurrentSetIdx);
		PerTrialStruct.B_changed_target_ldx = B_changed_target_ldx(TrialsInCurrentSetIdx);

		PerTrialStruct.AorB_changed_target_from_last_trial = AorB_changed_target_from_last_trial(TrialsInCurrentSetIdx);
		PerTrialStruct.choice_combination_color_string = choice_combination_color_string(TrialsInCurrentSetIdx);




		FullPerTrialStruct.isTrialInvisible_AB = Invisible_AB(:);
		%InitialTargetReleaseRT
		FullPerTrialStruct.A_InitialTargetReleaseRT = A_InitialTargetReleaseRT(:);
		FullPerTrialStruct.B_InitialTargetReleaseRT = B_InitialTargetReleaseRT(:);
		FullPerTrialStruct.AB_InitialTargetReleaseRT_diff = AB_InitialTargetReleaseRT_diff(:);
		%TargetAcquisitionRT
		FullPerTrialStruct.A_TargetAcquisitionRT = A_TargetAcquisitionRT(:);
		FullPerTrialStruct.B_TargetAcquisitionRT = B_TargetAcquisitionRT(:);
		FullPerTrialStruct.AB_TargetAcquisitionRT_diff = AB_TargetAcquisitionRT_diff(:);
		%IniTargRel_05MT_RT
		FullPerTrialStruct.A_IniTargRel_05MT_RT = A_IniTargRel_05MT_RT(:);
		FullPerTrialStruct.B_IniTargRel_05MT_RT = B_IniTargRel_05MT_RT(:);
		FullPerTrialStruct.AB_IniTargRel_05MT_RT_diff = AB_IniTargRel_05MT_RT_diff(:);
		% the differential go signals
		FullPerTrialStruct.A_GoSignalTime = A_GoSignalTime(:);
		FullPerTrialStruct.B_GoSignalTime = B_GoSignalTime(:);
		FullPerTrialStruct.AB_diffGoSignalTime = AB_diffGoSignalTime(:);


		FullPerTrialStruct.AB_TrialStartTimeMS = AB_TrialStartTimeMS(:);
		FullPerTrialStruct.RewardByTrial_A = RewardByTrial_A(:);
		FullPerTrialStruct.RewardByTrial_B = RewardByTrial_B(:);

		FullPerTrialStruct.PreferableTargetSelected_A = PreferableTargetSelected_A(:);
		FullPerTrialStruct.PreferableTargetSelected_B = PreferableTargetSelected_B(:);
		FullPerTrialStruct.NonPreferableTargetSelected_A = NonPreferableTargetSelected_A(:);
		FullPerTrialStruct.NonPreferableTargetSelected_B = NonPreferableTargetSelected_B(:);


		FullPerTrialStruct.SameTargetA = SameTargetA(:);
		FullPerTrialStruct.SameTargetB = SameTargetB(:);
		FullPerTrialStruct.DiffOwnTarget = DiffOwnTarget(:);
		FullPerTrialStruct.DiffOtherTarget = DiffOtherTarget(:);
		FullPerTrialStruct.A_changed_target_ldx = A_changed_target_ldx(:);
		FullPerTrialStruct.B_changed_target_ldx = B_changed_target_ldx(:);
		FullPerTrialStruct.AorB_changed_target_from_last_trial = AorB_changed_target_from_last_trial(:);
		FullPerTrialStruct.choice_combination_color_string = choice_combination_color_string(:);


		FullPerTrialStruct.LeftTargetSelected_A = LeftTargetSelected_A(:);
		FullPerTrialStruct.LeftTargetSelected_B = LeftTargetSelected_B(:);
		FullPerTrialStruct.RightTargetSelected_A = RightTargetSelected_A(:);
		FullPerTrialStruct.RightTargetSelected_B = RightTargetSelected_B(:);

		FullPerTrialStruct.SubjectiveLeftTargetSelected_A = SubjectiveLeftTargetSelected_A(:);
		FullPerTrialStruct.SubjectiveLeftTargetSelected_B = SubjectiveLeftTargetSelected_B(:);
		FullPerTrialStruct.SubjectiveRightTargetSelected_A = SubjectiveRightTargetSelected_A(:);
		FullPerTrialStruct.SubjectiveRightTargetSelected_B = SubjectiveRightTargetSelected_B(:);


		% get vectors for side/value choices
		FullPerTrialStruct.PreferableNoneNonpreferableSelected_A = PreferableNoneNonpreferableSelected_A;
		FullPerTrialStruct.PreferableNoneNonpreferableSelected_B = PreferableNoneNonpreferableSelected_B;
		FullPerTrialStruct.RightNoneLeftSelected_A = RightNoneLeftSelected_A;
		FullPerTrialStruct.RightNoneLeftSelected_B = RightNoneLeftSelected_B;
		FullPerTrialStruct.SubjectiveRightNoneLeftSelected_A = SubjectiveRightNoneLeftSelected_A;
		FullPerTrialStruct.SubjectiveRightNoneLeftSelected_B = SubjectiveRightNoneLeftSelected_B;



		FullPerTrialStruct.TrialIsJoint = TrialIsJoint(:);
		FullPerTrialStruct.TrialIsSolo = TrialIsSolo(:);
		FullPerTrialStruct.NumChoiceTargetsPerTrial = NumChoiceTargetsPerTrial(:);
		FullPerTrialStruct.TrialIsRewarded = TrialIsRewarded(:);
		FullPerTrialStruct.TrialIsAborted = TrialIsAborted(:);

		% to make sure that we recalculte the ccordination metrics if the
		% included trials change store this into the cfg structure
		coordination_metrics_cfg.TrialsInCurrentSetIdx = TrialsInCurrentSetIdx;


		if (process_coordination_metrics)
			% the next is used as session selector currently, so save out as
			% well
			current_file_group_id_string = ['DATA_', FileName, '.', TitleSetDescriptorString, '.isOwnChoice_sideChoice'];
			if ~exist(fullfile(OutputPath, 'CoordinationCheck'), 'dir')
				mkdir(fullfile(OutputPath, 'CoordinationCheck'));
			end

			switch (CurrentGroup)
				case 'IC_JointTrials'
					ALL_SESSSION_METRICS_group_string = '';
				otherwise
					ALL_SESSSION_METRICS_group_string = ['.', CurrentGroup];
			end

			%TODO add this specifically for the visibility trials (do not calculate per_trial values?)
			invisible_other_trial_idx = find(FullPerTrialStruct.isTrialInvisible_AB);
			if ~isempty(invisible_other_trial_idx)
				use_all_trials = 1;
				prefix_string = '';
				% trials woth visibility of the other's action blocked
				CurTrialsInCurrentSetIdx = intersect(TrialsInCurrentSetIdx, invisible_other_trial_idx);
				[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
					OutputPath, ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.invisible.mat'], current_file_group_id_string, info, ...
					isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, '_invisible');
				% if they exist, get visible_pre, visibile_blocked, visible_post
				visibility_changes_lidx = diff(FullPerTrialStruct.isTrialInvisible_AB);
				visibility_changes_idx = find([0; visibility_changes_lidx]); % extend by one to give the index to the first changed item index
				n_visibility_changes = sum(abs(visibility_changes_lidx));
				switch n_visibility_changes
					case 0
						% nothing to do, we saved the vis_blocked already
					case 1
						% 2 blocks, invisible already saved
						CurTrialsInCurrentSetIdx = intersect(TrialsInCurrentSetIdx, find(FullPerTrialStruct.isTrialInvisible_AB == 0));
						if (FullPerTrialStruct.isTrialInvisible_AB(1) == 0)
							suffix_string = 'visible_pre';
						else
							suffix_string = 'visible_post';
						end
						PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.', suffix_string, '.mat'];
						[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
							OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
							isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, ['_', suffix_string]);
					case 2
						% 3 blocks
						CurTrialsInCurrentSetIdx = intersect(TrialsInCurrentSetIdx, find(FullPerTrialStruct.isTrialInvisible_AB == 0));
						if (FullPerTrialStruct.isTrialInvisible_AB(1) == 0) && ~isempty(CurTrialsInCurrentSetIdx)
							% vis pre block
							vis_pre_trials_idx = find(CurTrialsInCurrentSetIdx < visibility_changes_idx(1));
							if ~isempty(vis_pre_trials_idx)
								CurCurTrialsInCurrentSetIdx = CurTrialsInCurrentSetIdx(1:vis_pre_trials_idx(end));
								suffix_string = 'visible_pre';
								PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.', suffix_string, '.mat'];
								[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
									OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
									isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, CurCurTrialsInCurrentSetIdx, use_all_trials, prefix_string, ['_', suffix_string]);
							end
							% vis_post block
							vis_post_trials_idx = find(CurTrialsInCurrentSetIdx >= visibility_changes_idx(2));
							if ~isempty(vis_post_trials_idx)
								CurCurTrialsInCurrentSetIdx = CurTrialsInCurrentSetIdx(vis_post_trials_idx(1):end);
								suffix_string = 'visible_post';
								PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.', suffix_string, '.mat'];
								[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
									OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
									isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, CurCurTrialsInCurrentSetIdx, use_all_trials, prefix_string, ['_', suffix_string]);
							end
						else
							if ~isempty(CurTrialsInCurrentSetIdx)
								error([mfilename, ': found 3 visibility block swith the first invisible, not handled yet.']);
							end
						end
					otherwise
						% assume interleaved
						suffix_string = 'visible';
						CurTrialsInCurrentSetIdx = intersect(TrialsInCurrentSetIdx, find(FullPerTrialStruct.isTrialInvisible_AB == 0));
						PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.', suffix_string, '.mat'];
						[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
							OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
							isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, ['_', suffix_string]);
				end
			else
				% for testing only!
				%return
			end

			% add first100 trials as well (exploratory phase)
			PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.first100.mat'];
			use_all_trials = 1;
			prefix_string = '';
			suffix_string = '';
			n_TrialsInCurrentSetIdx = length(TrialsInCurrentSetIdx);
			CurTrialsInCurrentSetIdx = TrialsInCurrentSetIdx(1:(min([100 n_TrialsInCurrentSetIdx])));
			[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
				OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
				isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, suffix_string);

			if (calc_extra_aggregate_measures)
				% 			% add last250 trials as well (exploratory phase)
				% 			PopulationAggregateName = ['ALL_SESSSION_METRICS.last250.mat'];
				% 			use_all_trials = 1;
				% 			prefix_string = '';
				% 			suffix_string = '';
				% 			n_TrialsInCurrentSetIdx = length(TrialsInCurrentSetIdx);
				% 			CurTrialsInCurrentSetIdx = TrialsInCurrentSetIdx((max([1 (end - 250 + 1)])):end);
				% 			[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
				% 				OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
				% 				isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, suffix_string);

				% add last250 trials as well (exploratory phase)
				PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.last250.mat'];
				use_all_trials = 0;
				prefix_string = '';
				suffix_string = '';
				tmp_coordination_metrics_cfg = coordination_metrics_cfg;
				tmp_coordination_metrics_cfg.stationarySegmentLength = 250;
				CurTrialsInCurrentSetIdx = TrialsInCurrentSetIdx;
				[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
					OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
					isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, tmp_coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, suffix_string);

				% add last250 trials as well (exploratory phase)
				PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.last150.mat'];
				use_all_trials = 0;
				prefix_string = '';
				suffix_string = '';
				tmp_coordination_metrics_cfg = coordination_metrics_cfg;
				tmp_coordination_metrics_cfg.stationarySegmentLength = 150;
				CurTrialsInCurrentSetIdx = TrialsInCurrentSetIdx;
				[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
					OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
					isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, tmp_coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, suffix_string);

				% add last250 trials as well (exploratory phase)
				PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.last100.mat'];
				use_all_trials = 0;
				prefix_string = '';
				suffix_string = '';
				tmp_coordination_metrics_cfg = coordination_metrics_cfg;
				tmp_coordination_metrics_cfg.stationarySegmentLength = 100;
				CurTrialsInCurrentSetIdx = TrialsInCurrentSetIdx;
				[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
					OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
					isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, tmp_coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, suffix_string);
			end

			% the final hopefully steady-state exploitation phase
			PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.last200.mat'];
			use_all_trials = 0;
			prefix_string = '';
			suffix_string = '';
			CurTrialsInCurrentSetIdx = TrialsInCurrentSetIdx;
			[coordination_metrics_table, cur_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
				OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
				isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, suffix_string);

			% the whole enchilada
			PopulationAggregateName = ['ALL_SESSSION_METRICS', ALL_SESSSION_METRICS_group_string, '.all_joint_choice_trials.mat'];
			use_all_trials = 1;
			prefix_string = '';
			suffix_string = '';
			CurTrialsInCurrentSetIdx = TrialsInCurrentSetIdx;
			[full_coordination_metrics_table, cur_full_coordination_metrics_table] = fn_population_per_session_aggregates_per_trialsubset_wrapper(...
				OutputPath, PopulationAggregateName, current_file_group_id_string, info, ...
				isOwnChoiceFullArray, sideChoiceObjectiveFullArray, FullPerTrialStruct, coordination_metrics_cfg, CurTrialsInCurrentSetIdx, use_all_trials, prefix_string, suffix_string);
			% do this for all trials only (for per trial plots)
			cur_coordination_metrics_struct = cur_full_coordination_metrics_table.coordination_metrics_struct;

		end

		%if strcmp(SessionLogFQN, fullfile(PathStr, '20171127T164730.A_20021.B_20022.SCP_01.triallog.txt'))
		% for human pair number 6 we do only converge on a strategy after ~270
		% trials before that each selected their own
		% 		if  ~isempty(cur_coordination_metrics_table) && isfield(cur_coordination_metrics_table, 'row')
		% 			MI_side = cur_coordination_metrics_table.row(coordination_metrics_table.cn.miSide);
		% 			MI_target = cur_coordination_metrics_table.row(coordination_metrics_table.cn.miTarget);
		% 			X = atand(MI_side/MI_target);
		% 			Y = sqrt(MI_side^2 + MI_target^2);
		% 			disp(['stationarySegmentLength: ', num2str(cur_coordination_metrics_table.cfg_struct.stationarySegmentLength)]);
		% 			disp(['MI_side: ', num2str(MI_side, '%0.4f'), '; MI_target: ', num2str(MI_target, '%0.4f')]);
		% 			disp(['atand(MI_side/MI_target): ', num2str(X, '%0.4f'), '; sqrt(MI_side^2 + MI_target^2): ', num2str(Y, '%0.4f')]);
		% 		end



		% now save the data
		if (SaveMat4CoordinationCheck)
			current_outfilename = ['DATA_', FileName, '.', TitleSetDescriptorString, '.isOwnChoice_sideChoice.mat'];
			outfilename = fullfile(OutputPath, 'CoordinationCheck', current_outfilename);
			if ~exist(fullfile(OutputPath, 'CoordinationCheck'), 'dir')
				mkdir(fullfile(OutputPath, 'CoordinationCheck'));
			end

			% ATTENTION this includes the exploration trials!!!
			isOwnChoice = isOwnChoiceArray;
			isBottomChoice = sideChoiceObjectiveArray;

			cur_coordination_metrics_table_row = [];
			cur_coordination_metrics_table_header = [];
			if isfield(cur_coordination_metrics_table, 'row')
				cur_coordination_metrics_table_row = cur_coordination_metrics_table.row;
			end
			if isfield(cur_coordination_metrics_table, 'header')
				cur_coordination_metrics_table_header = cur_coordination_metrics_table.header;
			end
			save(outfilename, 'info', 'isOwnChoiceArray', 'sideChoiceObjectiveArray', 'sideChoiceSubjectiveArray', ...
				'TrialsInCurrentSetIdx', 'TrialSets', 'coordStruct', 'isOwnChoice', 'isBottomChoice', 'PerTrialStruct', 'FullPerTrialStruct', ...
				'cur_coordination_metrics_struct', 'cur_coordination_metrics_table_row', 'cur_coordination_metrics_table_header');
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

	%     % we need to have JointTrialX_Vector available
	%     % Who is faster
	%     StackedXData = {[FasterInititialHoldRelease_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterInititialHoldRelease_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualInititialHoldRelease_AB(GoodTrialsIdx(JointTrialX_Vector)))]; ...
	%         [FasterInititialTargetRelease_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterInititialTargetRelease_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualInititialTargetRelease_AB(GoodTrialsIdx(JointTrialX_Vector)))]; ...
	%         [FasterTargetAcquisition_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterTargetAcquisition_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualTargetAcquisition_AB(GoodTrialsIdx(JointTrialX_Vector)))]};
	%     StackedRightEffectorColor = {[SideARTColor; SideBRTColor; SideABEqualRTColor]; [SideARTColor; SideBRTColor; SideABEqualRTColor]; [SideARTColor; SideBRTColor; SideABEqualRTColor]};
	%     StackedRightEffectorBGTransparency = {[0.33]; [0.66]; [1.0]};


	% exclude the InititialHoldRelease as this is not that interesting
	StackedXData = {[FasterInititialTargetRelease_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterInititialTargetRelease_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualInititialTargetRelease_AB(GoodTrialsIdx(JointTrialX_Vector)))]; ...
		[FasterTargetAcquisition_A(GoodTrialsIdx(JointTrialX_Vector)) + (2 * FasterTargetAcquisition_B(GoodTrialsIdx(JointTrialX_Vector))) + (3 * EqualTargetAcquisition_AB(GoodTrialsIdx(JointTrialX_Vector)))]};
	StackedRightEffectorColor = {[SideARTColor; SideBRTColor; SideABEqualRTColor]; ...
		[SideARTColor; SideBRTColor; SideABEqualRTColor]};
	StackedRightEffectorBGTransparency = {[0.66]; ...
		[1.0]};

	% make these invisible?
	if (RTCatPlotInvisible)
		for iStackedCat = 1 : length(StackedRightEffectorBGTransparency)
			StackedRightEffectorBGTransparency{iStackedCat} = 0.0;
		end
		TitleSetDescriptorString = [TitleSetDescriptorString, SeparatorString, 'invisRTCat'];
	end


	% Show the value and side selection combinations
	if ~(IsSoloGroup)
		StackedTargetSideXData = {[SameTargetA(GoodTrialsIdx(JointTrialX_Vector)) + (2 * SameTargetB(GoodTrialsIdx(JointTrialX_Vector))) + (3 * DiffOwnTarget(GoodTrialsIdx(JointTrialX_Vector))) + + (4 * DiffOtherTarget(GoodTrialsIdx(JointTrialX_Vector)))]; ...
			[A_left_B_left(GoodTrialsIdx(JointTrialX_Vector)) + (2 * A_right_B_right(GoodTrialsIdx(JointTrialX_Vector))) + (3 * A_left_B_right(GoodTrialsIdx(JointTrialX_Vector))) + (4 * A_right_B_left(GoodTrialsIdx(JointTrialX_Vector)))]};
		% 		StackedTargetSideColor = {[SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor]; ...
		% 			[A_left_B_left_Color; A_right_B_right_Color; A_left_B_right_Color; A_right_B_left_Color]};
	else
		% solo
		if (ProcessSideA)
			A_selected = (A_selects_A) >= 1;
			B_selected = (A_selects_B) >= 1;
			left_selected = (SubjectiveLeftTargetSelected_A) >= 1;
			right_selected = (SubjectiveRightTargetSelected_A) >= 1;
		elseif (ProcessSideB)
			A_selected = (B_selects_A) >= 1;
			B_selected = (B_selects_B) >= 1;
			left_selected = (SubjectiveLeftTargetSelected_B) >= 1;
			right_selected = (SubjectiveRightTargetSelected_B) >= 1;
		end

		%         A_selected = (A_selects_A + B_selects_A) >= 1;
		%         B_selected = (A_selects_B + B_selects_B) >= 1;
		%         left_selected = (SubjectiveLeftTargetSelected_A + SubjectiveLeftTargetSelected_B) >= 1;
		%         right_selected = (SubjectiveRightTargetSelected_A + SubjectiveRightTargetSelected_B) >= 1;

		StackedTargetSideXData = {[A_selected(GoodTrialsIdx(JointTrialX_Vector)) + (2 * B_selected(GoodTrialsIdx(JointTrialX_Vector)))]; ...
			[(3 * left_selected(GoodTrialsIdx(JointTrialX_Vector))) + (4 * right_selected(GoodTrialsIdx(JointTrialX_Vector)))]};
		% 		StackedTargetSideColor = {[SameOwnAColor; SameOwnBColor]; ...
		% 			[A_left_B_right_Color; A_right_B_left_Color]};
	end
	StackedTargetSideColor = {[SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor]; ...
		[A_left_B_left_Color; A_right_B_right_Color; A_left_B_right_Color; A_right_B_left_Color]};
	StackedTargetSideBGTransparency = {[1.0], [1.0]};

	if (ShowOnlyTargetChoiceCombinations)
		tmpStackedTargetSideXData{1} = StackedTargetSideXData{1};
		StackedTargetSideXData = tmpStackedTargetSideXData;
		tmpStackedTargetSideColor{1} = StackedTargetSideColor{1};
		StackedTargetSideColor = tmpStackedTargetSideColor;
		tmpStackedTargetSideBGTransparency{1} = StackedTargetSideBGTransparency{1};
		StackedTargetSideBGTransparency = tmpStackedTargetSideBGTransparency;
	end



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
	set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
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
	if (ShowTargetSideChoiceCombinations) %&& ~(IsSoloGroup)
		fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, StackedTargetSideXData, y_lim, StackedTargetSideColor, StackedTargetSideBGTransparency);
		y_lim = get(gca(), 'YLim');
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
	%         title(CoordinationSummaryString, 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);
	%     end
	if ~isempty(CoordinationSummaryCell) && show_coordination_results_in_fig_title
		title(CoordinationSummaryCell, 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);
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
	set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
	legend_list = {};
	hold on

	set(gca(), 'YLim', [0.0, 1.0]);
	y_lim = get(gca(), 'YLim');

	% mark all trials in which the visibility of the two sides was
	% manipulated
	if (ShowInvisibility)
		fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
	end

	if (ShowTargetSideChoiceCombinations) %&& ~(IsSoloGroup)
		fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, StackedTargetSideXData, y_lim, StackedTargetSideColor, StackedTargetSideBGTransparency);
		y_lim = get(gca(), 'YLim');
	end

	fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);




	if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
		fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
	end


	title_textA = '';
	title_textB = '';

	if (ProcessSideA)
		plot(FilteredJointTrialX_Vector, FilteredJointTrials_PreferableTargetSelected_A(FilteredJointTrialX_Vector), 'Color', SideAColor, 'LineWidth', project_line_width);
		legend_list{end + 1} = 'running avg. A';
		TmpMean = mean(PreferableTargetSelected_A(GoodTrialsIdx));
		if ~isempty(FilteredJointTrialX_Vector)
			line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideAColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
			legend_list{end + 1} = 'all trials avg. A';
		end
		if length(GoodTrialsIdx) >= 25
			TmpMean25 = mean(PreferableTargetSelected_A(GoodTrialsIdx(end-24:end)));
		else
			TmpMean25 = mean(PreferableTargetSelected_A(GoodTrialsIdx));
		end
		% 26-50
		if length(GoodTrialsIdx) >= 50
			TmpMean50 = mean(PreferableTargetSelected_A(GoodTrialsIdx(50-24:50)));
		elseif length(GoodTrialsIdx) >= 25
			TmpMean50 = mean(PreferableTargetSelected_A(end-24:end));
		else
			TmpMean50 = mean(PreferableTargetSelected_A(GoodTrialsIdx));
		end
		title_textA = ['A: SOC(all ', num2str(numel(GoodTrialsIdx)),') ', num2str(100 * TmpMean), '%; SOC(last25) ', num2str(100 * TmpMean25),'%; SOC(26-50) ', num2str(100 * TmpMean50), '%; '];
	end
	if (ProcessSideB)
		plot(FilteredJointTrialX_Vector, FilteredJointTrials_PreferableTargetSelected_B(FilteredJointTrialX_Vector), 'Color', SideBColor, 'LineWidth', project_line_width);
		legend_list{end + 1} = 'runing avg. B';
		TmpMean = mean(PreferableTargetSelected_B(GoodTrialsIdx));
		if ~isempty(FilteredJointTrialX_Vector)
			line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideBColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
			legend_list{end + 1} = 'all trials avg. B';
		end
		if length(GoodTrialsIdx) >= 25
			TmpMean25 = mean(PreferableTargetSelected_B(GoodTrialsIdx(end-24:end)));
		else
			TmpMean25 = mean(PreferableTargetSelected_B(GoodTrialsIdx));
		end
		% 26-50
		if length(GoodTrialsIdx) >= 50
			TmpMean50 = mean(PreferableTargetSelected_B(GoodTrialsIdx(50-24:50)));
		elseif length(GoodTrialsIdx) >= 25
			TmpMean50 = mean(PreferableTargetSelected_B(end-24:end));
		else
			TmpMean50 = mean(PreferableTargetSelected_B(GoodTrialsIdx));
		end
		title_textB = ['B: SOC(all ', num2str(numel(GoodTrialsIdx)),') ', num2str(100 * TmpMean), '%; SOC(last25) ', num2str(100 * TmpMean25),'%; SOC(26-50) ', num2str(100 * TmpMean50), '%; '];
	end

	if (show_SOC_percentage) || (show_soloSOC_percentage && IsSoloGroup)
		title({[title_textA, title_textB]}, 'FontSize', title_fontsize, 'Interpreter', 'none', 'FontWeight', title_fontweight);
	end

	if (save_SOC_percentage)
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.percentages.', 'txt']);
		fid = fopen(outfile_fqn, 'w', 'n', 'UTF-8');
		fprintf(fid, 'SideA: %s\n', title_textA);
		fprintf(fid, 'SideB: %s', title_textB);
		fclose(fid);
	end

	hold off
	%
	SoC_axes_h = gca();
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
		title([partnerInluenceOnSideString, '; ', partnerInluenceOnTargetString], 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);
	end

	%write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
	CurrentTitleSetDescriptorString = TitleSetDescriptorString;
	outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.highvalue.', OutPutType]);
	write_out_figure(Cur_fh_ShareOfOwnChoiceOverTrials, outfile_fqn);


	if (exist('Add_AR_subplot_to_SoC_plot', 'var') && Add_AR_subplot_to_SoC_plot)
		Cur_fh_AR_subplot = figure('Name', 'ShareOfOwnChoiceOverTrials.ARsubplot', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		hold on
		%legend_list{end + 1} = 'running avg. AB smoothed';
		if ~isempty(FilteredJointTrialX_Vector)
			TmpMean = mean(AvgRewardByTrial_AB(GoodTrialsIdx));
			line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [3.5, 3.5], 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'LineWidth', project_line_width*0.5);
			%legend_list{end + 1} = 'all trials avg. AB';
		end
		plot(FilteredJointTrialX_Vector, FilteredJointTrials_AvgRewardByTrial_AB(FilteredJointTrialX_Vector), 'Color', SideABColorDark, 'LineWidth', project_line_width);

		hold off
		y_tick_list = [1.0, 3.0];

		set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
		set(gca(), 'YLim', [0.8, 3.7]);
		set(gca(), 'YTick', y_tick_list);
		set(gca(),'TickLabelInterpreter','none');
		xlabel( 'Number of trial');
		ylabel( 'Reward');
		ARsubplot_axes_h = gca();

		Cur_fh_ShareOfOwnChoiceOverTrials_AR = figure('Name', 'ShareOfOwnChoiceOverTrials.AR', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(Cur_fh_ShareOfOwnChoiceOverTrials_AR, 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);

		%hold on
		% copy the SoC plot from its axes handle
		% hFigIAxes = findobj('Parent',fig_i,'Type','axes'); % use this to
		% allow passing in a figure handle
		SoC_ax_h = copyobj(SoC_axes_h, Cur_fh_ShareOfOwnChoiceOverTrials_AR);
		xlabel(SoC_ax_h, '');
		set(SoC_ax_h, 'XTickLabel', []);
		% graft the SoC plot onto the subplot
		masterplot_fh = subplot(4,1,[1,2,3], SoC_ax_h);

		ARsubplot_ax_h = copyobj(ARsubplot_axes_h, Cur_fh_ShareOfOwnChoiceOverTrials_AR);
		ARplot_fh = subplot(4,1,4, ARsubplot_ax_h);

		%hold off
		%write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
		CurrentTitleSetDescriptorString = TitleSetDescriptorString;
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SOC.highvalue.AR.', OutPutType]);
		write_out_figure(Cur_fh_ShareOfOwnChoiceOverTrials_AR, outfile_fqn);

	end



	%%
	% share of bottom choices (for humans)
	if (sum(ismember(DataStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod, {'DAG_VERTICALCHOICE', 'DAG_VERTICALCHOICE_LEFT35MM', 'DAG_VERTICALCHOICERIGHT35mm'})))
		% select the relvant trials:
		FilteredJointTrials_BottomTargetSelected_A = fnFilterByNamedKernel( BottomTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
		FilteredJointTrials_BottomTargetSelected_B = fnFilterByNamedKernel( BottomTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );

		Cur_fh_ShareOfBottomChoiceOverTrials = figure('Name', 'ShareOfBottomChoiceOverTrials', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
		legend_list = {};
		hold on

		set(gca(), 'YLim', [0.0, 1.0]);
		y_lim = get(gca(), 'YLim');


		% mark all trials in which the visibility of the two sides was
		% manipulated
		if (ShowInvisibility)
			fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
		end

		if (ShowTargetSideChoiceCombinations) %&& ~(IsSoloGroup)
			fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, StackedTargetSideXData, y_lim, StackedTargetSideColor, StackedTargetSideBGTransparency);
			y_lim = get(gca(), 'YLim');
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
	if (sum(ismember(DataStruct.SessionByTrial.unique_lists.TouchTargetPositioningMethod, {'DAG_SQUARE', 'CIRCULARCHOICE_VERTICALLY_MIRRORED_NUM_BASEANGLE_EXCENTRICY_ANGLE'})))
		% select the relvant trials:
		FilteredJointTrials_SubjectiveLeftTargetSelected_A = fnFilterByNamedKernel( SubjectiveLeftTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
		FilteredJointTrials_SubjectiveLeftTargetSelected_B = fnFilterByNamedKernel( SubjectiveLeftTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );

		Cur_fh_ShareOfSubjectiveLeftChoiceOverTrials = figure('Name', 'ShareOfSubjectiveLeftChoiceOverTrials', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
		legend_list = {};
		hold on

		set(gca(), 'YLim', [0.0, 1.0]);
		y_lim = get(gca(), 'YLim');


		% mark all trials in which the visibility of the two sides was
		% manipulated
		if (ShowInvisibility)
			fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
		end

		if (ShowTargetSideChoiceCombinations) %&& ~(IsSoloGroup)
			fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, StackedTargetSideXData, y_lim, StackedTargetSideColor, StackedTargetSideBGTransparency);
			y_lim = get(gca(), 'YLim');
		end

		fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);

		if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
			fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
		end

		title_list = {};
		if (ProcessSideA)
			plot(FilteredJointTrialX_Vector, FilteredJointTrials_SubjectiveLeftTargetSelected_A(FilteredJointTrialX_Vector), 'Color', SideAColor, 'LineWidth', project_line_width);
			if ~isempty(FilteredJointTrialX_Vector)
				TmpMean = mean(SubjectiveLeftTargetSelected_A(GoodTrialsIdx));
				line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideAColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
			end
			A_left_high = sum(SubjectiveLeftTargetSelected_A(GoodTrialsIdx) & PreferableTargetSelected_A(GoodTrialsIdx));
			A_left_low = sum(SubjectiveLeftTargetSelected_A(GoodTrialsIdx) & NonPreferableTargetSelected_A(GoodTrialsIdx));
			A_right_high = sum(SubjectiveRightTargetSelected_A(GoodTrialsIdx) & PreferableTargetSelected_A(GoodTrialsIdx));
			A_right_low = sum(SubjectiveRightTargetSelected_A(GoodTrialsIdx) & NonPreferableTargetSelected_A(GoodTrialsIdx));

			[~, p] = fishertest([A_left_high, A_left_low; A_right_high, A_right_low]);

			title_list{end+1} = ['A: LeftHigh: ', num2str(A_left_high), '; LeftLow: ', num2str(A_left_low), '; RightHigh: ', num2str(A_right_high), '; RightLow: ', num2str(A_right_low), '; FET(p): ', num2str(p)];
		end
		if (ProcessSideB)
			plot(FilteredJointTrialX_Vector, FilteredJointTrials_SubjectiveLeftTargetSelected_B(FilteredJointTrialX_Vector), 'Color', SideBColor, 'LineWidth', project_line_width);
			if ~isempty(FilteredJointTrialX_Vector)
				TmpMean = mean(SubjectiveLeftTargetSelected_B(GoodTrialsIdx));
				line([FilteredJointTrialX_Vector(1), FilteredJointTrialX_Vector(end)], [TmpMean, TmpMean], 'Color', (SideBColor * 0.66), 'LineStyle', '--', 'LineWidth', project_line_width);
			end
			B_left_high = sum(SubjectiveLeftTargetSelected_B(GoodTrialsIdx) & PreferableTargetSelected_B(GoodTrialsIdx));
			B_left_low = sum(SubjectiveLeftTargetSelected_B(GoodTrialsIdx) & NonPreferableTargetSelected_B(GoodTrialsIdx));
			B_right_high = sum(SubjectiveRightTargetSelected_B(GoodTrialsIdx) & PreferableTargetSelected_B(GoodTrialsIdx));
			B_right_low = sum(SubjectiveRightTargetSelected_B(GoodTrialsIdx) & NonPreferableTargetSelected_B(GoodTrialsIdx));
			[~, p] = fishertest([B_left_high, B_left_low; B_right_high, B_right_low]);

			title_list{end+1} = ['B: LeftHigh: ', num2str(B_left_high), '; LeftLow: ', num2str(B_left_low), '; RightHigh: ', num2str(B_right_high), '; RightLow: ', num2str(B_right_low), '; FET(p): ', num2str(p)];
		end

		title(title_list, 'FontSize', title_fontsize, 'Interpreter', 'none', 'FontWeight', title_fontweight);


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
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
		legend_list = {};
		hold on

		set(gca(), 'YLim', [0.0, 1.0]);
		y_lim = get(gca(), 'YLim');

		% mark all trials in which the visibility of the two sides
		% wasFyDiffG
		% manipulated
		if (ShowInvisibility)
			fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
		end
		if (ShowTargetSideChoiceCombinations) %&& ~(IsSoloGroup)
			fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, StackedTargetSideXData, y_lim, StackedTargetSideColor, StackedTargetSideBGTransparency);
			y_lim = get(gca(), 'YLim');
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

	if (plot_joint_choices_by_diffGoSignal)
		%GoSignalQuantum_ms = 50;
		%TODO choices of A for each of B's (ans vice versa)
		cur_AB_diffGoSignalTime = fn_saturate_by_min_max(AB_diffGoSignalTime(GoodTrialsIdx), -GoSignal_saturation_ms, GoSignal_saturation_ms);
		unique_cur_AB_diffGoSignalTime = unique(cur_AB_diffGoSignalTime);
		% only look at the selected good trials
		quantized_cur_AB_diffGoSignalTime = fn_saturate_by_min_max((round(cur_AB_diffGoSignalTime/GoSignalQuantum_ms) * GoSignalQuantum_ms), -GoSignal_saturation_ms, GoSignal_saturation_ms);
		% but also calculate stuff for all trials
		quantized_AB_diffGoSignalTime = fn_saturate_by_min_max((round(AB_diffGoSignalTime/GoSignalQuantum_ms) * GoSignalQuantum_ms), -GoSignal_saturation_ms, GoSignal_saturation_ms);
		unique_quantized_cur_ABdiffGoSignalTimes = unique(quantized_cur_AB_diffGoSignalTime);

		% split the equal GO signal cases by who was faster
		if (split_diffGoSignal_eq_0_by_RT)
			zero_diff_idx = find(quantized_AB_diffGoSignalTime == 0);
			RT_diff_list = eval(['AB_', diffGoSignal_eq_0_by_RT_RT_type, '_diff']);
			% find when A was faster
			A_faster_idx = find(RT_diff_list <= 0);
			tmp_A_idx = intersect(zero_diff_idx, A_faster_idx);
			%tmp_A_idx = intersect(GoodTrialsIdx, tmp_A_idx);

			quantized_AB_diffGoSignalTime(tmp_A_idx) = -0.1;

			B_faster_idx = find(RT_diff_list > 0);
			tmp_B_idx = intersect(zero_diff_idx, B_faster_idx);
			%tmp_B_idx = intersect(GoodTrialsIdx, tmp_B_idx);
			quantized_AB_diffGoSignalTime(tmp_B_idx) = +0.1;

			%quantized_AB_diffGoSignalTime = round(AB_diffGoSignalTime/GoSignalQuantum_ms) * GoSignalQuantum_ms;
			unique_quantized_cur_ABdiffGoSignalTimes = unique(quantized_AB_diffGoSignalTime(GoodTrialsIdx));
			% insert the two new categories, even if one is empty
			unique_quantized_cur_ABdiffGoSignalTimes = unique([unique_quantized_cur_ABdiffGoSignalTimes; -0.1; +0.1]);
		end



		% create ordinal vectors of joint choices to build contingency
		% tables from
		if ~(IsSoloGroup)

			input_data_collection.by_AB_value.name = '';

			value_choices = [SameTargetA(:) + (2 * SameTargetB(:)) + ...
				(3 * DiffOwnTarget(:)) + + (4 * DiffOtherTarget(:))];
			value_names = {'A_own_B_other', 'A_other_B_own', 'A_own_B_own', 'A_other_B_other'};
			side_choices = [A_left_B_left(:) + (2 * A_right_B_right(:)) + ...
				(3 * A_left_B_right(:)) + (4 * A_right_B_left(:))];
			side_names = {'A_left_B_left', 'A_right_B_right', 'A_left_B_right', 'A_right_B_left'};

			sameness_choices = [SameTargetA(:) + (1 * SameTargetB(:)) + ...
				(2 * DiffOwnTarget(:)) + + (2 * DiffOtherTarget(:))];
			sameness_names = {'Same', 'Different'};

			%AbyB_value_choices =

		else
			% solo
			A_selected = A_selects_A + B_selects_A;
			B_selected = A_selects_B + B_selects_B;
			left_selected = SubjectiveLeftTargetSelected_A + SubjectiveLeftTargetSelected_B;
			right_selected = SubjectiveRightTargetSelected_A + SubjectiveRightTargetSelected_B;
			value_choices = [A_selected(:) + (2 * B_selected(:))];
			value_names = {'A', 'B'};
			side_choices = [(1 * left_selected(:)) + (2 * right_selected(:))];
			side_names = {'left', 'right'};
			sameness_choices = [];
			sameness_names = {};
		end

		num_joint_choice_combinations = length(value_names);
		num_sameness_combinations = length(sameness_names);
		choice_contingency_table.joint_value = zeros([num_joint_choice_combinations, length(unique_quantized_cur_ABdiffGoSignalTimes)]);
		choice_contingency_table.joint_side = zeros([num_joint_choice_combinations, length(unique_quantized_cur_ABdiffGoSignalTimes)]);
		choice_contingency_table.sameness = zeros([num_sameness_combinations, length(unique_quantized_cur_ABdiffGoSignalTimes)]);

		column_names = cell([1, length(unique_quantized_cur_ABdiffGoSignalTimes)]);

		% collect the choice types, build contingency tables
		for i_quantized_diffGoSignalTimes = 1 : length(unique_quantized_cur_ABdiffGoSignalTimes)
			cur_quantized_diffGoSignalTimes = unique_quantized_cur_ABdiffGoSignalTimes(i_quantized_diffGoSignalTimes);
			column_names{i_quantized_diffGoSignalTimes} = num2str(cur_quantized_diffGoSignalTimes/1000);

			% get the trials with the current diffGoSignalTime
			cur_diffGoSIgnalTime_idx = find(quantized_AB_diffGoSignalTime == cur_quantized_diffGoSignalTimes);
			% only look at the good trials in the current set
			cur_diffGoSIgnalTime_idx = intersect(cur_diffGoSIgnalTime_idx, GoodTrialsIdx);


			% collect the average reward per side for each group
			mean(RewardByTrial_A(cur_diffGoSIgnalTime_idx))
			mean(RewardByTrial_B(cur_diffGoSIgnalTime_idx))

			% collect the joint choices and build contingency table
			for i_joint_choice = 1 : num_joint_choice_combinations
				tmp_value_idx = find(value_choices(cur_diffGoSIgnalTime_idx) == i_joint_choice);
				tmp_side_idx = find(side_choices(cur_diffGoSIgnalTime_idx) == i_joint_choice);
				choice_contingency_table.joint_value(i_joint_choice, i_quantized_diffGoSignalTimes) = length(tmp_value_idx);
				choice_contingency_table.joint_side(i_joint_choice, i_quantized_diffGoSignalTimes) = length(tmp_side_idx);
			end
			if ~isempty(sameness_choices)
				for i_sameness = 1 : num_sameness_combinations
					tmp_sameness_idx = find(sameness_choices(cur_diffGoSIgnalTime_idx) == i_sameness);
					choice_contingency_table.sameness(i_sameness, i_quantized_diffGoSignalTimes) = length(tmp_sameness_idx);
				end
			end
		end


		if ~isempty(sameness_choices)
			[pairwise_P_matrix, pairwise_P_matrix_with_chance, P_data_not_chance_list] = get_pairwise_p_4_fisher_exact(choice_contingency_table.sameness', []);
			[sym_list, p_list, cols_idx_per_symbol] = construct_symbol_list(pairwise_P_matrix, sameness_names, column_names, 'col', []);

			%figure_visibility_string = 'on';
			fh_cur_sameness_contingency_table = figure('Name', 'SamenessContingency by Differential GoSignalTime', 'visible', figure_visibility_string);
			fnFormatDefaultAxes(DefaultAxesType);
			[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction, [], double_row_aspect_ratio);
			set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
			%subplot(2, 1, 1)
			% plot the tables
			row_names = sameness_names;
			title_string = 'sameness';
			[ah_cur_value_contingency_table, cur_group_names] = fnPlotContingencyTable_stacked(choice_contingency_table.sameness, row_names, column_names, 'column', title_string, 'subplot', sym_list, cols_idx_per_symbol, []);

			CurrentTitleSetDescriptorString = TitleSetDescriptorString;
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SamenessContingencyTable.ByDiffGoTime.', OutPutType]);
			write_out_figure(fh_cur_sameness_contingency_table, outfile_fqn);
		end


		%figure_visibility_string = 'on';
		fh_cur_value_contingency_table = figure('Name', 'ValueContingency by Differential GoSignalTime', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction, [], double_row_aspect_ratio);
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
		%subplot(2, 1, 1)
		% plot the tables
		row_names = value_names;
		title_string = 'value';
		[ah_cur_value_contingency_table, cur_group_names] = fnPlotContingencyTable_stacked(choice_contingency_table.joint_value, row_names, column_names, 'column', title_string, 'subplot', [], [], []);

		CurrentTitleSetDescriptorString = TitleSetDescriptorString;
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.ValueContingencyTable.ByDiffGoTime.', OutPutType]);
		write_out_figure(fh_cur_value_contingency_table, outfile_fqn);

		%figure_visibility_string = 'on';
		fh_cur_side_contingency_table = figure('Name', 'SideContingency by Differential GoSignalTime', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction, [], double_row_aspect_ratio);
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
		%subplot(2, 1, 2)
		% plot the tables
		row_names = side_names;
		title_string = 'side';
		[ah_cur_side_contingency_table, cur_group_names] = fnPlotContingencyTable_stacked(choice_contingency_table.joint_side, row_names, column_names, 'column', title_string, 'subplot', [], [], []);

		CurrentTitleSetDescriptorString = TitleSetDescriptorString;
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SideContingencyTable.ByDiffGoTime.', OutPutType]);
		write_out_figure(fh_cur_side_contingency_table, outfile_fqn);

	end


	if (0)
		%GoSignalQuantum_ms = 50;

		cur_AB_diffGoSignalTime = AB_diffGoSignalTime(GoodTrialsIdx);
		unique_cur_AB_diffGoSignalTime = unique(cur_AB_diffGoSignalTime);
		% only look at the sellected good trials
		quantized_cur_AB_diffGoSignalTime = round(cur_AB_diffGoSignalTime/GoSignalQuantum_ms) * GoSignalQuantum_ms;
		% but also calculate stuff for all trials
		quantized_AB_diffGoSignalTime = round(AB_diffGoSignalTime/GoSignalQuantum_ms) * GoSignalQuantum_ms;
		unique_quantized_cur_ABdiffGoSignalTimes = unique(quantized_cur_AB_diffGoSignalTime);

		% split the equal GO signal cases by who was faster
		if (split_diffGoSignal_eq_0_by_RT)
			zero_diff_idx = find(quantized_cur_AB_diffGoSignalTime ==0);
			% 			A_faster_idx =
			% 			B_faster_idx =
			% 			diffGoSignal_eq_0_by_RT_RT_type

			%quantized_AB_diffGoSignalTime = round(AB_diffGoSignalTime/GoSignalQuantum_ms) * GoSignalQuantum_ms;
			unique_quantized_cur_ABdiffGoSignalTimes = unique(quantized_cur_AB_diffGoSignalTime);
		end

		% create ordinal vectors of joint choices to build contingency
		% tables from
		if ~(IsSoloGroup)
			value_choices = [SameTargetA(:) + (2 * SameTargetB(:)) + ...
				(3 * DiffOwnTarget(:)) + + (4 * DiffOtherTarget(:))];
			value_names = {'A_own_B_other', 'A_other_B_own', 'A_own_B_own', 'A_other_B_other'};
			side_choices = [A_left_B_left(:) + (2 * A_right_B_right(:)) + ...
				(3 * A_left_B_right(:)) + (4 * A_right_B_left(:))];
			side_names = {'A_left_B_left', 'A_right_B_right', 'A_left_B_right', 'A_right_B_left'};

			sameness_choices = [SameTargetA(:) + (1 * SameTargetB(:)) + ...
				(2 * DiffOwnTarget(:)) + + (2 * DiffOtherTarget(:))];
			sameness_names = {'Same', 'Different'};
		else
			% solo
			A_selected = A_selects_A + B_selects_A;
			B_selected = A_selects_B + B_selects_B;
			left_selected = SubjectiveLeftTargetSelected_A + SubjectiveLeftTargetSelected_B;
			right_selected = SubjectiveRightTargetSelected_A + SubjectiveRightTargetSelected_B;
			value_choices = [A_selected(:) + (2 * B_selected(:))];
			value_names = {'A', 'B'};
			side_choices = [(1 * left_selected(:)) + (2 * right_selected(:))];
			side_names = {'left', 'right'};
			sameness_choices = [];
			sameness_names = {};
		end

		num_joint_choice_combinations = length(value_names);
		num_sameness_combinations = length(sameness_names);
		choice_contingency_table.joint_value = zeros([num_joint_choice_combinations, length(unique_quantized_cur_ABdiffGoSignalTimes)]);
		choice_contingency_table.joint_side = zeros([num_joint_choice_combinations, length(unique_quantized_cur_ABdiffGoSignalTimes)]);
		choice_contingency_table.sameness = zeros([num_sameness_combinations, length(unique_quantized_cur_ABdiffGoSignalTimes)]);

		column_names = cell([1, length(unique_quantized_cur_ABdiffGoSignalTimes)]);

		% collect the choice types, build contingency tables
		for i_quantized_diffGoSignalTimes = 1 : length(unique_quantized_cur_ABdiffGoSignalTimes)
			cur_quantized_diffGoSignalTimes = unique_quantized_cur_ABdiffGoSignalTimes(i_quantized_diffGoSignalTimes);
			column_names{i_quantized_diffGoSignalTimes} = num2str(cur_quantized_diffGoSignalTimes/1000);

			% get the trials with the current diffGoSignalTime
			cur_diffGoSIgnalTime_idx = find(quantized_AB_diffGoSignalTime == cur_quantized_diffGoSignalTimes);
			% only look at the good trials in the current set
			cur_diffGoSIgnalTime_idx = intersect(cur_diffGoSIgnalTime_idx, GoodTrialsIdx);


			% collect the joint choices and build contingency table
			for i_joint_choice = 1 : num_joint_choice_combinations
				tmp_value_idx = find(value_choices(cur_diffGoSIgnalTime_idx) == i_joint_choice);
				tmp_side_idx = find(side_choices(cur_diffGoSIgnalTime_idx) == i_joint_choice);
				choice_contingency_table.joint_value(i_joint_choice, i_quantized_diffGoSignalTimes) = length(tmp_value_idx);
				choice_contingency_table.joint_side(i_joint_choice, i_quantized_diffGoSignalTimes) = length(tmp_side_idx);
			end
			if ~isempty(sameness_choices)
				for i_sameness = 1 : num_sameness_combinations
					tmp_sameness_idx = find(sameness_choices(cur_diffGoSIgnalTime_idx) == i_sameness);
					choice_contingency_table.sameness(i_sameness, i_quantized_diffGoSignalTimes) = length(tmp_sameness_idx);
				end
			end
		end


		if ~isempty(sameness_choices)
			[pairwise_P_matrix, pairwise_P_matrix_with_chance, P_data_not_chance_list] = get_pairwise_p_4_fisher_exact(choice_contingency_table.sameness', []);
			[sym_list, p_list, cols_idx_per_symbol] = construct_symbol_list(pairwise_P_matrix, sameness_names, column_names, 'col', []);

			%figure_visibility_string = 'on';
			fh_cur_sameness_contingency_table = figure('Name', 'SamenessContingency by Differential GoSignalTime', 'visible', figure_visibility_string);
			fnFormatDefaultAxes(DefaultAxesType);
			[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction, [], double_row_aspect_ratio);
			set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
			%subplot(2, 1, 1)
			% plot the tables
			row_names = sameness_names;
			title_string = 'sameness';
			[ah_cur_value_contingency_table, cur_group_names] = fnPlotContingencyTable_stacked(choice_contingency_table.sameness, row_names, column_names, 'column', title_string, 'subplot', sym_list, cols_idx_per_symbol, []);

			CurrentTitleSetDescriptorString = TitleSetDescriptorString;
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SamenessContingencyTable.ByDiffGoTime.', OutPutType]);
			write_out_figure(fh_cur_sameness_contingency_table, outfile_fqn);
		end


		%figure_visibility_string = 'on';
		fh_cur_value_contingency_table = figure('Name', 'ValueContingency by Differential GoSignalTime', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction, [], double_row_aspect_ratio);
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
		%subplot(2, 1, 1)
		% plot the tables
		row_names = value_names;
		title_string = 'value';
		[ah_cur_value_contingency_table, cur_group_names] = fnPlotContingencyTable_stacked(choice_contingency_table.joint_value, row_names, column_names, 'column', title_string, 'subplot', [], [], []);

		CurrentTitleSetDescriptorString = TitleSetDescriptorString;
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.ValueContingencyTable.ByDiffGoTime.', OutPutType]);
		write_out_figure(fh_cur_value_contingency_table, outfile_fqn);

		%figure_visibility_string = 'on';
		fh_cur_side_contingency_table = figure('Name', 'SideContingency by Differential GoSignalTime', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction, [], double_row_aspect_ratio);
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
		%subplot(2, 1, 2)
		% plot the tables
		row_names = side_names;
		title_string = 'side';
		[ah_cur_side_contingency_table, cur_group_names] = fnPlotContingencyTable_stacked(choice_contingency_table.joint_side, row_names, column_names, 'column', title_string, 'subplot', [], [], []);

		CurrentTitleSetDescriptorString = TitleSetDescriptorString;
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SideContingencyTable.ByDiffGoTime.', OutPutType]);
		write_out_figure(fh_cur_side_contingency_table, outfile_fqn);

	end



	if (plot_psee_antipreferredchoice_correlation_per_trial) && ~(IsSoloGroup) && exist('cur_coordination_metrics_struct', 'var') && isfield(cur_coordination_metrics_struct, 'per_trial')

		for i_item = 1 : length(psee_antipreferredchoice_correlation_RT_name_list)

			psee_antipreferredchoice_correlation_RT_name = psee_antipreferredchoice_correlation_RT_name_list{i_item};

			if (isempty(cur_coordination_metrics_struct.per_trial.(psee_antipreferredchoice_correlation_RT_name)))
				continue
			end

			% prepare the data
			raw_accmodations_array = cur_coordination_metrics_struct.per_trial.full_isOtherChoice(:, CurTrialsInCurrentSetIdx);
			raw_psee_array = cur_coordination_metrics_struct.per_trial.(psee_antipreferredchoice_correlation_RT_name);

			windowSize = 8;
			filtered_psee_array = movmean(raw_psee_array, windowSize, 2);
			filtered_accmodations_array = movmean(raw_accmodations_array, windowSize, 2);

			Cur_fh_PseeSotherCCorOverTrials = figure('Name', 'PseeAntipreferredChoiceCorrelationOverTrials', 'visible', figure_visibility_string);
			fnFormatDefaultAxes(DefaultAxesType);
			[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction, [], double_row_aspect_ratio);
			set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
			legend_list = {};


			subplot(2, 1, 1)
			set(gca(), 'YLim', [0.0, 1.0]);
			y_lim = get(gca(), 'YLim');

			hold on
			% for agent A
			if (ShowInvisibility)
				fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
			end
			if (ShowTargetSideChoiceCombinations) %&& ~(IsSoloGroup)
				fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, StackedTargetSideXData, y_lim, StackedTargetSideColor, StackedTargetSideBGTransparency);
				y_lim = get(gca(), 'YLim');
			end
			fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
			if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
				fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
			end

			if (ProcessSideA)
				h1 = plot(filtered_psee_array(1,:), 'Color', PseeColor, 'linewidth', project_line_width);
				legend_list{end + 1} = 'probability to see partner''s choice';
				h3 = plot(filtered_accmodations_array(1,:), 'Color', SideAColor, 'linewidth', project_line_width);
				legend_list{end + 1} = 'share of Accommodate choices';
			end
			df_corr = size(filtered_psee_array, 2) - 2;
			corrCoefValue = num2str(cur_coordination_metrics_struct.per_trial.([psee_antipreferredchoice_correlation_RT_name, '_Cor']).corrCoefValue(1), '%.4f');
			corrPValue = num2str(cur_coordination_metrics_struct.per_trial.([psee_antipreferredchoice_correlation_RT_name, '_Cor']).corrPValue(1), '%.4f');
			corrCoefAveraged = num2str(cur_coordination_metrics_struct.per_trial.([psee_antipreferredchoice_correlation_RT_name, '_Cor']).corrCoefAveraged(1), '%.4f');
			corrPValueAveraged = num2str(cur_coordination_metrics_struct.per_trial.([psee_antipreferredchoice_correlation_RT_name, '_Cor']).corrPValueAveraged(1), '%.4f');
			titleText_A = ['Agent A: r(', num2str(df_corr), '): ', corrCoefValue,  ', p <= ', corrPValue,  ' / ', corrCoefAveraged, ', p <= ', corrPValueAveraged, ''];
			title(titleText_A, 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);

			set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
			%set(gca(), 'YLim', [0.0, 1.0]);
			set(gca(), 'YTick', [0, 0.5, 1]);
			set(gca(),'TickLabelInterpreter','none');
			xlabel( 'Number of trial');
			ylabel( 'Probability');

			hold off


			subplot(2, 1, 2)
			set(gca(), 'YLim', [0.0, 1.0]);
			y_lim = get(gca(), 'YLim');

			hold on
			% for agent B
			if (ShowInvisibility)
				fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
			end
			if (ShowTargetSideChoiceCombinations) %&& ~(IsSoloGroup)
				fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, StackedTargetSideXData, y_lim, StackedTargetSideColor, StackedTargetSideBGTransparency);
				y_lim = get(gca(), 'YLim');
			end
			fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
			if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
				fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
			end

			if (ProcessSideB)
				h2 = plot(filtered_psee_array(2, :), 'Color', PseeColor, 'linewidth', project_line_width);
				legend_list{end + 1} = 'probability to see partner''s choice';
				h4 = plot(filtered_accmodations_array(2, :), 'Color', SideBColor, 'linewidth', project_line_width);
				legend_list{end + 1} = 'share of Accommodate choices';
			end
			df_corr = size(filtered_psee_array, 2) - 2;
			corrCoefValue = num2str(cur_coordination_metrics_struct.per_trial.([psee_antipreferredchoice_correlation_RT_name, '_Cor']).corrCoefValue(2), '%.4f');
			corrPValue = num2str(cur_coordination_metrics_struct.per_trial.([psee_antipreferredchoice_correlation_RT_name, '_Cor']).corrPValue(2), '%.4f');
			corrCoefAveraged = num2str(cur_coordination_metrics_struct.per_trial.([psee_antipreferredchoice_correlation_RT_name, '_Cor']).corrCoefAveraged(2), '%.4f');
			corrPValueAveraged = num2str(cur_coordination_metrics_struct.per_trial.([psee_antipreferredchoice_correlation_RT_name, '_Cor']).corrPValueAveraged(2), '%.4f');
			titleText_B = ['Agent B: r(', num2str(df_corr), '): ', corrCoefValue,  ', p <= ', corrPValue,  ' / ', corrCoefAveraged, ', p <= ', corrPValueAveraged, ''];
			title(titleText_B, 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);

			set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
			%set(gca(), 'YLim', [0.0, 1.0]);
			set(gca(), 'YTick', [0, 0.5, 1]);
			set(gca(),'TickLabelInterpreter','none');
			xlabel( 'Number of trial');
			ylabel( 'Probability');

			hold off
			%
			if (PlotLegend)
				legend(legend_list, 'Interpreter', 'None');
			end

			CurrentTitleSetDescriptorString = TitleSetDescriptorString;
			outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.PseeSotherCCor.', psee_antipreferredchoice_correlation_RT_name, '.', OutPutType]);
			write_out_figure(Cur_fh_PseeSotherCCorOverTrials, outfile_fqn);
		end
	end



	if (plot_transferentropy_per_trial) && ~(IsSoloGroup) && exist('cur_coordination_metrics_struct', 'var') && isfield(cur_coordination_metrics_struct, 'per_trial') && ~isempty(cur_coordination_metrics_struct.per_trial.targetTE1)
		%plot the transfer entropy
		% select the relevant trials:
		%FilteredJointTrials_PreferableTargetSelected_A = fnFilterByNamedKernel( PreferableTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
		%FilteredJointTrials_PreferableTargetSelected_B = fnFilterByNamedKernel( PreferableTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );


		Cur_fh_ShareOfOwnChoiceOverTrials = figure('Name', 'TransferEntropyOverTrials', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
		legend_list = {};
		hold on

		set(gca(), 'YLim', [-3.0, 3.0]);
		y_lim = get(gca(), 'YLim');

		% mark all trials in which the visibility of the two sides was
		% manipulated
		if (ShowInvisibility)
			fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
		end
		if (ShowTargetSideChoiceCombinations) %&& ~(IsSoloGroup)
			fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, StackedTargetSideXData, y_lim, StackedTargetSideColor, StackedTargetSideBGTransparency);
			y_lim = get(gca(), 'YLim');
		end
		fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);
		if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
			fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
		end

		if (ProcessSideA)
			h1 = plot(cur_coordination_metrics_struct.per_trial.localTargetTE1, 'Color', SideAColor*0.5, 'linewidth', project_line_width*0.5);
			legend_list{end + 1} = 'local transfer entropy A->B';
			h3 = plot(cur_coordination_metrics_struct.per_trial.targetTE1, 'Color', SideAColor, 'linewidth', project_line_width);
			legend_list{end + 1} = 'transfer entropy A->B';
		end
		if (ProcessSideB)
			h2 = plot(cur_coordination_metrics_struct.per_trial.localTargetTE2, 'Color', SideBColor*0.5, 'linewidth', project_line_width*0.5);
			legend_list{end + 1} = 'local transfer entropy B->A';
			h4 = plot(cur_coordination_metrics_struct.per_trial.targetTE2, 'Color', SideBColor, 'linewidth', project_line_width);
			legend_list{end + 1} = 'transfer entropy B->A';
		end

		hold off
		%
		set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
		%set(gca(), 'YLim', [0.0, 1.0]);
		set(gca(), 'YTick', [-3, -2, -1 0, 1, 2, 3]);
		set(gca(),'TickLabelInterpreter','none');
		xlabel( 'Number of trial');
		ylabel( 'Transfer Entropy');
		if (PlotLegend)
			legend(legend_list, 'Interpreter', 'None');
		end
		%         if (~isempty(partnerInluenceOnSide) && ~isempty(partnerInluenceOnTarget)) && show_coordination_results_in_fig_title
		%             partnerInluenceOnSideString = ['Partner effect on side choice of A: ', num2str(partnerInluenceOnSide(1)), '; of B: ', num2str(partnerInluenceOnSide(2))];
		%             partnerInluenceOnTargetString = ['Partner effect on target choice of A: ', num2str(partnerInluenceOnTarget(1)), '; of B: ', num2str(partnerInluenceOnTarget(2))];
		%             title([partnerInluenceOnSideString, '; ', partnerInluenceOnTargetString], 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);
		%         end

		%write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
		CurrentTitleSetDescriptorString = TitleSetDescriptorString;
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.TransferEntropy.', OutPutType]);
		write_out_figure(Cur_fh_ShareOfOwnChoiceOverTrials, outfile_fqn);
	end


	if (plot_mutualinformation_per_trial) && ~(IsSoloGroup) && exist('cur_coordination_metrics_struct', 'var') && isfield(cur_coordination_metrics_struct, 'per_trial') && ~isempty(cur_coordination_metrics_struct.per_trial.mutualInf)
		%plot the mutual information
		% select the relevant trials:
		%FilteredJointTrials_PreferableTargetSelected_A = fnFilterByNamedKernel( PreferableTargetSelected_A(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );
		%FilteredJointTrials_PreferableTargetSelected_B = fnFilterByNamedKernel( PreferableTargetSelected_B(GoodTrialsIdx), FilterKernelName, FilterHalfWidth, FilterShape );


		Cur_fh_ShareOfOwnChoiceOverTrials = figure('Name', 'MutualInformationOverTrials', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect);
		legend_list = {};
		hold on

		set(gca(), 'YLim', [-3.0, 3.0]);
		y_lim = get(gca(), 'YLim');

		% mark all trials in which the visibility of the two sides was
		% manipulated
		if (ShowInvisibility)
			fnPlotBackgroundWrapper(ShowInvisibility, ProcessSideA, ProcessSideB, Invisible_AB(GoodTrialsIdx(JointTrialX_Vector)), Invisible_A(GoodTrialsIdx(JointTrialX_Vector)), Invisible_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, InvisibilityColor, InvisibitiltyTransparency);
		end
		if (ShowTargetSideChoiceCombinations) %&& ~(IsSoloGroup)
			fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, StackedTargetSideXData, y_lim, StackedTargetSideColor, StackedTargetSideBGTransparency);
			y_lim = get(gca(), 'YLim');
		end

		fnPlotBackgroundWrapper(ShowEffectorHandInBackground, ProcessSideA, ProcessSideB, RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_A(GoodTrialsIdx(JointTrialX_Vector)), RightHandUsed_B(GoodTrialsIdx(JointTrialX_Vector)), y_lim, RightEffectorColor, RightEffectorBGTransparency);


		if (ShowFasterSideInBackground) && (ProcessSideA && ProcessSideB)
			fnPlotStackedCategoriesAtPositionWrapper('StackedOnTop', 0.15, StackedXData, y_lim, StackedRightEffectorColor, StackedRightEffectorBGTransparency);
		end


		if (ProcessSideA) && (ProcessSideB)
			h1 = plot(cur_coordination_metrics_struct.per_trial.locMutualInf, 'Color', SideABColor*0.5, 'linewidth', project_line_width*0.5);
			legend_list{end + 1} = 'local mutual information';
			h3 = plot(cur_coordination_metrics_struct.per_trial.mutualInf, 'Color', SideABColor, 'linewidth', project_line_width);
			legend_list{end + 1} = 'mutual information';
			plot([1, length(cur_coordination_metrics_struct.per_trial.mutualInf)], [0 0], 'k--', 'linewidth', 1.2);
			%legend_list{end + 1} = '';
		end


		hold off
		%
		set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
		%set(gca(), 'YLim', [0.0, 1.0]);
		set(gca(), 'YTick', [-3, -2, -1 0, 1, 2, 3]);
		set(gca(),'TickLabelInterpreter','none');
		xlabel( 'Number of trial');
		ylabel( 'Mutual Information');
		if (PlotLegend)
			legend(legend_list, 'Interpreter', 'None');
		end
		%         if (~isempty(partnerInluenceOnSide) && ~isempty(partnerInluenceOnTarget)) && show_coordination_results_in_fig_title
		%             partnerInluenceOnSideString = ['Partner effect on side choice of A: ', num2str(partnerInluenceOnSide(1)), '; of B: ', num2str(partnerInluenceOnSide(2))];
		%             partnerInluenceOnTargetString = ['Partner effect on target choice of A: ', num2str(partnerInluenceOnTarget(1)), '; of B: ', num2str(partnerInluenceOnTarget(2))];
		%             title([partnerInluenceOnSideString, '; ', partnerInluenceOnTargetString], 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);
		%         end

		%write_out_figure(gcf, fullfile(OutputDir, [session.name '_rewards', OuputFormat]));
		CurrentTitleSetDescriptorString = TitleSetDescriptorString;
		outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MutualInformation.', OutPutType]);
		write_out_figure(Cur_fh_ShareOfOwnChoiceOverTrials, outfile_fqn);

	end

	% also plot the reaction time per trial
	if (PlotRTBySameness)

		% select the relvant data points:
		%InitialTargetReleaseRT_A = DataStruct.data(:, DataStruct.cn.A_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.A_TargetOnsetTime_ms);
		%InitialTargetReleaseRT_B = DataStruct.data(:, DataStruct.cn.B_InitialFixationReleaseTime_ms) - DataStruct.data(:, DataStruct.cn.B_TargetOnsetTime_ms);

		%TargetAcquisitionRT_A = DataStruct.data(:, DataStruct.cn.A_TargetTouchTime_ms) - DataStruct.data(:, DataStruct.cn.A_TargetOnsetTime_ms);
		%TargetAcquisitionRT_B = DataStruct.data(:, DataStruct.cn.B_TargetTouchTime_ms) - DataStruct.data(:, DataStruct.cn.B_TargetOnsetTime_ms);

		%figure_visibility_string = 'on';
		Cur_fh_ReactionTimesBySameness = figure('Name', 'ReactionTimesBySameness', 'visible', figure_visibility_string);
		fnFormatDefaultAxes(DefaultAxesType);
		[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
		set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
		legend_list = {};
		hold on

		% create the subsets: same own A, same own B, diff own, diff other
		SameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0);
		SameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1);
		DiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1);
		DiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0);


		if (Plot_RT_differences) && (ProcessSideA) && (ProcessSideB)
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
		if (Plot_RT_differences) && (ProcessSideA) && (ProcessSideB)
			%plot(JointTrialX_Vector, AB_InitialHoldReleaseRT_diff(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideAColor/3 + SideBColor/3), 'LineWidth', 2);
			plot(JointTrialX_Vector, AB_InitialTargetReleaseRT_diff(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (2*SideAColor/3 + 2*SideBColor/3), 'LineWidth', project_line_width*0.66);
			plot(JointTrialX_Vector, AB_TargetAcquisitionRT_diff(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideAColor + SideBColor), 'LineWidth', 2);
		else
			if (ProcessSideA)
				%plot(JointTrialX_Vector, A_InitialHoldReleaseRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideAColor/3), 'LineWidth', 2);
				plot(JointTrialX_Vector, A_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (2*SideAColor/3), 'LineWidth', project_line_width*0.66);
				if (RT_detrend_order > 0)
					[A_InitialTargetReleaseRT_p, A_InitialTargetReleaseRT_s, A_InitialTargetReleaseRT_mu] = polyfit(JointTrialX_Vector, A_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector))', RT_detrend_order);
					detrended_A_InitialTargetReleaseRT = polyval(A_InitialTargetReleaseRT_p, (GoodTrialsIdx(JointTrialX_Vector)), [], A_InitialTargetReleaseRT_mu);
					plot(JointTrialX_Vector, detrended_A_InitialTargetReleaseRT, 'Color', (2*SideAColor/3), 'LineWidth', project_line_width*1.0);
				end
				plot(JointTrialX_Vector, A_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideAColor), 'LineWidth', project_line_width);
			end
			if (RT_detrend_order > 0)
				[A_TargetAcquisitionRT_p, A_TargetAcquisitionRT_s, A_TargetAcquisitionRT_mu] = polyfit(JointTrialX_Vector, A_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector))', RT_detrend_order);
				detrended_A_TargetAcquisitionRT = polyval(A_TargetAcquisitionRT_p, (GoodTrialsIdx(JointTrialX_Vector)), [], A_TargetAcquisitionRT_mu);
				plot(JointTrialX_Vector, detrended_A_TargetAcquisitionRT, 'Color', (SideAColor), 'LineWidth', project_line_width*1.0);
			end
			if (ProcessSideB)
				%plot(JointTrialX_Vector, B_InitialHoldReleaseRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideBColor/3), 'LineWidth', 2);
				plot(JointTrialX_Vector, B_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (2*SideBColor/3), 'LineWidth', project_line_width*0.66);
				if (RT_detrend_order > 0)
					[B_InitialTargetReleaseRT_p, B_InitialTargetReleaseRT_s, B_InitialTargetReleaseRT_mu] = polyfit(JointTrialX_Vector, B_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector))', RT_detrend_order);
					detrended_B_InitialTargetReleaseRT = polyval(B_InitialTargetReleaseRT_p, (GoodTrialsIdx(JointTrialX_Vector)), [], B_InitialTargetReleaseRT_mu);
					plot(JointTrialX_Vector, detrended_B_InitialTargetReleaseRT, 'Color', (2*SideBColor/3), 'LineWidth', project_line_width*1.0);
				end
				plot(JointTrialX_Vector, B_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector)), 'Color', (SideBColor), 'LineWidth', project_line_width);
				if (RT_detrend_order > 0)
					[B_TargetAcquisitionRT_p, B_TargetAcquisitionRT_s, B_TargetAcquisitionRT_mu] = polyfit(JointTrialX_Vector, B_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector))', RT_detrend_order);
					detrended_B_TargetAcquisitionRT = polyval(B_TargetAcquisitionRT_p, (GoodTrialsIdx(JointTrialX_Vector)), [], B_TargetAcquisitionRT_mu);
					plot(JointTrialX_Vector, detrended_B_TargetAcquisitionRT, 'Color', (SideBColor), 'LineWidth', project_line_width*1.0);
				end
			end
		end

		if (ProcessSideA) && (ProcessSideB) && ~(IsSoloGroup)
			% TODO correlation on residuals after detrending?
			% also show the pearson correlations between the matching curves of both agents
			[ITRel_r, ITRel_p, ITRel_r_ci_lower, ITRel_r_ci_upper] = corrcoef(A_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector)), B_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector)));
			[TAcq_r, TAcq_p, TAcq_r_ci_lower, TAcq_r_ci_upper] = corrcoef(A_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector)), B_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector)));
			% add this as title
			df_corr = length(JointTrialX_Vector) - 2;
			titleText_A = {['InitialTargetRelease time correlation: r(', num2str(df_corr), '): ', num2str(ITRel_r(2, 1), '%.4f'),  ', p <= ', num2str(ITRel_p(2, 1)),], ...
				[['TargetAcquisition time correlation: r(', num2str(df_corr), '): ', num2str(TAcq_r(2, 1), '%.4f'),  ', p <= ', num2str(TAcq_p(2, 1)),]]};
			if (RT_detrend_order > 0)
				[ITRel_r_detrended, ITRel_p_detrended] = corrcoef(A_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector))-detrended_A_InitialTargetReleaseRT, B_InitialTargetReleaseRT(GoodTrialsIdx(JointTrialX_Vector))-detrended_B_InitialTargetReleaseRT);
				[TAcq_r_detrended, TAcq_p_detrended] = corrcoef(A_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector))-detrended_A_TargetAcquisitionRT, B_TargetAcquisitionRT(GoodTrialsIdx(JointTrialX_Vector))-detrended_B_TargetAcquisitionRT);
				titleText_A{end+1} = ['detrended (', num2str(RT_detrend_order),') InitialTargetRelease time correlation: r(', num2str(df_corr), '): ', num2str(ITRel_r_detrended(2, 1), '%.4f'),  ', p <= ', num2str(ITRel_p_detrended(2, 1)),];
				titleText_A{end+1} = [['detrended (', num2str(RT_detrend_order),') TargetAcquisition time correlation: r(', num2str(df_corr), '): ', num2str(TAcq_r_detrended(2, 1), '%.4f'),  ', p <= ', num2str(TAcq_p_detrended(2, 1)),]];
			end
			title(titleText_A, 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);
		end


		hold off
		%
		set(gca(), 'XLim', [1, length(GoodTrialsIdx)]);
		%set(gca(), 'YLim', [0.0, 1.0]);
		set(gca(),'TickLabelInterpreter','none');

		set(gca(), 'YTick', [0, 250, 500, 750, 1000, 1250 1500]);
		xlabel( 'Number of trial');

		if (Plot_RT_differences) && (ProcessSideA) && (ProcessSideB)
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
		for i_histogram_RT_type = 1 : length(histogram_RT_type_list)
			histogram_RT_type_string = histogram_RT_type_list{i_histogram_RT_type};
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
				case 'IniTargRel_05MT_RT'
					AB_RT_data_diff = AB_IniTargRel_05MT_RT_diff;
					A_RT_data = A_IniTargRel_05MT_RT;
					B_RT_data = B_IniTargRel_05MT_RT;
				otherwise
					error('Unhandled histogram_RT_type_string: ', histogram_RT_type_string);
			end
			CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.RT.', histogram_RT_type_string];



			%histogram_bin_width_ms = 16;
			switch Plot_RT_difference_histogram
				case 0
					current_histogram_edge_list = histogram_edges;
				case 1
					current_histogram_edge_list =   histogram_diff_edges;
			end


			if (PlotRTHistogramsByByPayoffMatrix)

				CurrentTitleSetDescriptorString = TitleSetDescriptorString;

				% create the subsets: same own A, same own B, diff own, diff other
				SameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0);
				SameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1);
				DiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1);
				DiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0);
				Same_lidx = union(SameOwnA_lidx, SameOwnB_lidx);
				Diff_lidx = union(DiffOwn_lidx, DiffOther_lidx);

				% create a stack of category vectors
				if (find(Invisible_AB(GoodTrialsIdx(JointTrialX_Vector))))
					VisSameOwnA_lidx = SameOwnA_lidx & (Invisible_AB == 0);
					VisSameOwnB_lidx = SameOwnB_lidx & (Invisible_AB == 0);
					VisDiffOwn_lidx = DiffOwn_lidx & (Invisible_AB == 0);
					VisDiffOther_lidx = DiffOther_lidx & (Invisible_AB == 0);
					InvisSameOwnA_lidx = SameOwnA_lidx & (Invisible_AB == 1);
					InvisSameOwnB_lidx = SameOwnB_lidx & (Invisible_AB == 1);
					InvisDiffOwn_lidx = DiffOwn_lidx & (Invisible_AB == 1);
					InvisDiffOther_lidx = DiffOther_lidx & (Invisible_AB == 1);


					legend_list = {'Same_Own_A', 'Same_Own_B', 'Diff_Own', 'Diff_Other', 'Opaque_Same_Own_A', 'Opaque_Same_Own_B', 'Opaque_Diff_Own', 'Opaque_Diff_Other'};

					if (histogram_show_median)
						legend_list = {'Same_Own_A','Median Same_Own_A', 'Same_Own_B', 'Median Same_Own_B', 'Diff_Own', 'Median Diff_Own', 'Diff_Other', 'Median Diff_Other', 'Opaque_Same_Own_A', 'Median Opaque_Same_Own_A', 'Opaque_Same_Own_B', 'Median Opaque_Same_Own_B', 'Opaque_Diff_Own', 'Median Opaque_Diff_Own', 'Opaque_Diff_Other', 'Median Opaque_Diff_Other'};
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
						legend_list = {'Same_Own_A','Median Same_Own_A', 'Same_Own_B', 'Median Same_Own_B', 'Diff_Own', 'Median Diff_Own', 'Diff_Other', 'Median Diff_Other'};
					end

					StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
					StackedCatData.LineStyleList = {'-', '-', '-', '-'};
					StackedCatData.SignFactorList = [1, 1, 1, 1];
				end

				Cur_fh_ReactionTimesBySameness = figure('Name', 'ReactionTimeHistogramBySameness', 'visible', figure_visibility_string);
				fnFormatDefaultAxes(DefaultAxesType);
				[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
				set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
				%legend_list = {};

				CurrentGroupGoodTrialsIdx = GoodTrialsIdx(JointTrialX_Vector);
				plot_differences = Plot_RT_difference_histogram;
				switch plot_differences
					case 0
						current_histogram_edge_list = histogram_edges;
					case 1
						current_histogram_edge_list =   histogram_diff_edges;
				end

				cur_plot_differences = plot_differences;

				if ~(ProcessSideA) || ~(ProcessSideB)
					current_histogram_edge_list = histogram_edges;
					cur_plot_differences = 0;
				end


				fnPlotRTHistogram(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, current_histogram_edge_list, cur_plot_differences, ProcessSideA, ProcessSideB, histnorm_string, histdisplaystyle_string, histogram_use_histogram_func, histogram_show_median, project_line_width);

				%TODO: do this for the invisible trials as well?


				% calculate ttest of RTdiff coordinated versus
				% anti-coordinated only for trials with visible partner
				% choices ((M = 121, SD = 14.2) than did those taking statistics courses in Statistics (M = 117, SD = 10.3), t(44) = 1.23, p = .09.)
				coordinated_trial_lidx = ((SameOwnA_lidx & (Invisible_AB == 0)) + (SameOwnB_lidx & (Invisible_AB == 0)));
				coordinated_trial_idx = find(coordinated_trial_lidx);
				anticoordinated_trial_lidx = ((DiffOwn_lidx & (Invisible_AB == 0)) + (DiffOther_lidx & (Invisible_AB == 0)));
				anticoordinated_trial_idx = find(anticoordinated_trial_lidx);
				cur_AB_RT_data_diff = A_RT_data - B_RT_data;
				[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest2(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, coordinated_trial_idx)), ...
					cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, anticoordinated_trial_idx)),...
					'Tail', 'both', 'Vartype', 'unequal');
				coordinated_vs_anticoordinated.ttest2 = ttest2res;
				% now add the result
				title_text = ['t-Test: Coordination (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, coordinated_trial_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, coordinated_trial_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, coordinated_trial_idx))), ')', ...
					' vs. Anti-Coordination (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, anticoordinated_trial_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, anticoordinated_trial_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, anticoordinated_trial_idx))), ')', ...
					', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];

				% SameA versus SameB
				CurSameA_idx = find(SameOwnA_lidx & (Invisible_AB == 0));
				CurSameB_idx = find(SameOwnB_lidx & (Invisible_AB == 0));
				[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest2(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx)), ...
					cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx)),...
					'Tail', 'both', 'Vartype', 'unequal');
				coordinated_vs_anticoordinated.ttest2 = ttest2res;
				% now add the result
				title_text2 = ['t-Test (hands visible): Coordination on A (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), ')', ...
					' vs. B (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), ')', ...
					', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];

				% SameA versus 0
				if ~isempty(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))

					[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx)), ...
						0,...
						'Tail', 'both');
					coordinated_vs_anticoordinated.ttest2 = ttest2res;
					% now add the result
					title_text2A = ['t-Test (hands visible): A (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), ')', ...
						' vs. 0', ...
						', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];
				else
					title_text2A = '';
				end

				% SameA versus 0
				if ~isempty(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))
					[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx)), ...
						0,...
						'Tail', 'both');
					coordinated_vs_anticoordinated.ttest2 = ttest2res;
					% now add the result
					title_text2B = ['t-Test (hands visible): B (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), ')', ...
						' vs. 0', ...
						', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];
				else
					title_text2B = '';
				end

				if (find(Invisible_AB(GoodTrialsIdx(JointTrialX_Vector))))
					% SameA versus SameB
					CurSameA_idx = find(SameOwnA_lidx & (Invisible_AB == 1));
					CurSameB_idx = find(SameOwnB_lidx & (Invisible_AB == 1));
					[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest2(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx)), ...
						cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx)),...
						'Tail', 'both', 'Vartype', 'unequal');
					coordinated_vs_anticoordinated.ttest2 = ttest2res;
					% now add the result
					title_text3 = ['t-Test (hands invisible): Coordination on A (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), ')', ...
						' vs. B (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), ')', ...
						', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];
					title_text_list = {title_text; title_text2; title_text2A; title_text2B; title_text3};
				else
					title_text_list = {title_text; title_text2; title_text2A; title_text2B};
				end

				if (show_RTdiff_ttests)
					title(title_text_list, 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);
				end
				fn_save_string_list_to_file(current_stats_to_text_fd, [], {''; 'PlotRTHistogramsByByPayoffMatrix'}, [], write_stats_to_text_file);
				fn_save_string_list_to_file(current_stats_to_text_fd, [], title_text_list, [' : ', histogram_RT_type_string], write_stats_to_text_file);


				if (plot_differences) && (ProcessSideA) && (ProcessSideB)
					CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.RTdiff'];
				end

				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySameness.', histogram_RT_type_string, '.', OutPutType]);
				write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);


				legend(legend_list, 'Interpreter', 'None');
				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySameness.legend.', histogram_RT_type_string, '.', OutPutType]);
				write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);

				% also plot the data as matlab box-whisker plot
				if (Plot_histogram_as_boxwhisker_plot)
					% TODO create this function to plot the box whisker
					% plots for the Reaction time
					Cur_fh_ReactionTimesBySameness = figure('Name', 'ReactionTimeBoxWhiskerBySameness', 'visible', figure_visibility_string);
					fnFormatDefaultAxes(DefaultAxesType);
					[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
					set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
					%legend_list = {};

					CurrentGroupGoodTrialsIdx = GoodTrialsIdx(JointTrialX_Vector);
					plot_differences = Plot_RT_difference_histogram;
					switch plot_differences
						case 0
							current_histogram_edge_list = histogram_edges;
						case 1
							current_histogram_edge_list =   histogram_diff_edges;
					end


					% shorten the legend list
					short_legent_list = legend_list;
					for i_cat = 1 : length(legend_list)
						%legend_list = {'Same_Own_A', 'Same_Own_B', 'Diff_Own', 'Diff_Other', 'Opaque_Same_Own_A', 'Opaque_Same_Own_B', 'Opaque_Diff_Own', 'Opaque_Diff_Other'};
						cur_cat_name = legend_list{i_cat};
						cur_cat_name = regexprep(cur_cat_name, 'Opaque_', 'opaq');
						cur_cat_name = regexprep(cur_cat_name, 'Same_Own_A', 'ArBr');
						cur_cat_name = regexprep(cur_cat_name, 'Same_Own_B', 'AbBb');
						cur_cat_name = regexprep(cur_cat_name, 'Diff_Own', 'ArBb');
						cur_cat_name = regexprep(cur_cat_name, 'Diff_Other', 'AbBr');
						short_legent_list{i_cat} = cur_cat_name;
					end

					StackedCatData.CatNameList = short_legent_list;

					% for the scaling...
					fnPlotBoxWhisker(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, plot_differences, ProcessSideA, ProcessSideB, project_line_width);

					set(gca(), 'YLim', [-800 800]);
					x_lim = get(gca(), 'XLim');
					% the zero line
					plot([x_lim], [0 0], 'Color', [0 0 0], 'LineWidth', project_line_width, 'LineStyle', '-');
					hold on
					fnPlotBoxWhisker(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, plot_differences, ProcessSideA, ProcessSideB, project_line_width);
					%set(gca(), 'YLim', [-800 800]);
					y_lim = get(gca(), 'YLim');
					set(gca(), 'YLim', [-(max(abs(y_lim))) max(abs(y_lim))]);

					hold off

					outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.BoxWhiskerBySameness.', histogram_RT_type_string, '.', OutPutType]);
					write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);

					% legend does not make sense for BoxWhisker plots.
					%legend(legend_list, 'Interpreter', 'None');
					%outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.BoxWhiskerBySameness.legend.', histogram_RT_type_string, '.', OutPutType]);
					%write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);
				end
			end


			% only select immediate post-pair-switch trials
			if (PlotRTHistogramsByByPayoffMatrixPostSwitchOnly)
				current_JointTrialX_Vector = JointTrialX_Vector;
				CurrentTitleSetDescriptorString = TitleSetDescriptorString;

				% create the subsets: same own A, same own B, diff own, diff other
				SameOwnA_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 0);
				SameOwnB_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 1);
				DiffOwn_lidx = (PreferableTargetSelected_A == 1) & (PreferableTargetSelected_B == 1);
				DiffOther_lidx = (PreferableTargetSelected_A == 0) & (PreferableTargetSelected_B == 0);
				Same_lidx = union(SameOwnA_lidx, SameOwnB_lidx);
				Diff_lidx = union(DiffOwn_lidx, DiffOther_lidx);

				% create a stack of category vectors
				if (find(Invisible_AB(GoodTrialsIdx(current_JointTrialX_Vector))))
					VisSameOwnA_lidx = SameOwnA_lidx & (Invisible_AB == 0);
					VisSameOwnB_lidx = SameOwnB_lidx & (Invisible_AB == 0);
					VisDiffOwn_lidx = DiffOwn_lidx & (Invisible_AB == 0);
					VisDiffOther_lidx = DiffOther_lidx & (Invisible_AB == 0);
					InvisSameOwnA_lidx = SameOwnA_lidx & (Invisible_AB == 1);
					InvisSameOwnB_lidx = SameOwnB_lidx & (Invisible_AB == 1);
					InvisDiffOwn_lidx = DiffOwn_lidx & (Invisible_AB == 1);
					InvisDiffOther_lidx = DiffOther_lidx & (Invisible_AB == 1);


					legend_list = {'Same_Own_A', 'Same_Own_B', 'Diff_Own', 'Diff_Other', 'Opaque_Same_Own_A', 'Opaque_Same_Own_B', 'Opaque_Diff_Own', 'Opaque_Diff_Other'};

					if (histogram_show_median)
						legend_list = {'Same_Own_A','Median Same_Own_A', 'Same_Own_B', 'Median Same_Own_B', 'Diff_Own', 'Median Diff_Own', 'Diff_Other', 'Median Diff_Other', 'Opaque_Same_Own_A', 'Median Opaque_Same_Own_A', 'Opaque_Same_Own_B', 'Median Opaque_Same_Own_B', 'Opaque_Diff_Own', 'Median Opaque_Diff_Own', 'Opaque_Diff_Other', 'Median Opaque_Diff_Other'};
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
						legend_list = {'Same_Own_A','Median Same_Own_A', 'Same_Own_B', 'Median Same_Own_B', 'Diff_Own', 'Median Diff_Own', 'Diff_Other', 'Median Diff_Other'};
					end

					StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
					StackedCatData.LineStyleList = {'-', '-', '-', '-'};
					StackedCatData.SignFactorList = [1, 1, 1, 1];
				end

				Cur_fh_ReactionTimesBySameness = figure('Name', 'ReactionTimeHistogramBySamenessPostSwitchTrials', 'visible', figure_visibility_string);
				fnFormatDefaultAxes(DefaultAxesType);
				[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
				set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
				%legend_list = {};


				CurrentGroupGoodTrialsIdx = GoodTrialsIdx(JointTrialX_Vector);
				% reduce the set to post switch trials
				% this will get all changes so even informed direct reach trials
				A_changed_target_all = [0; diff(PreferableTargetSelected_A)];
				B_changed_target_all = [0; diff(PreferableTargetSelected_B)];
				AorB_changed_target_from_last_trial_all = abs(A_changed_target_all) + abs(B_changed_target_all);
				AorB_changed_target_from_last_trial_all_idx = find(AorB_changed_target_from_last_trial_all);
				% this will only look a changes between reawarded informed
				% choice trrials
				A_changed_target = [0; diff(PreferableTargetSelected_A(CurrentGroupGoodTrialsIdx))];
				B_changed_target = [0; diff(PreferableTargetSelected_B(CurrentGroupGoodTrialsIdx))];
				AorB_changed_target_from_last_trial = abs(A_changed_target) + abs(B_changed_target);
				AorB_changed_target_from_last_trial_idx = CurrentGroupGoodTrialsIdx(find(AorB_changed_target_from_last_trial));


				CurrentGroupGoodTrialsIdx = intersect(CurrentGroupGoodTrialsIdx, AorB_changed_target_from_last_trial_idx);

				plot_differences = Plot_RT_difference_histogram;
				switch plot_differences
					case 0
						current_histogram_edge_list = histogram_edges;
					case 1
						current_histogram_edge_list =   histogram_diff_edges;
				end
				cur_plot_differences = plot_differences;

				if ~(ProcessSideA) || ~(ProcessSideB)
					current_histogram_edge_list = histogram_edges;
					cur_plot_differences = 0;
				end

				fnPlotRTHistogram(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, current_histogram_edge_list, cur_plot_differences, ProcessSideA, ProcessSideB, histnorm_string, histdisplaystyle_string, histogram_use_histogram_func, histogram_show_median, project_line_width);

				%TODO: do this for the invisible trials as well?


				% calculate ttest of RTdiff coordinated versus
				% anti-coordinated only for trials with visible partner
				% choices ((M = 121, SD = 14.2) than did those taking statistics courses in Statistics (M = 117, SD = 10.3), t(44) = 1.23, p = .09.)
				coordinated_trial_lidx = ((SameOwnA_lidx & (Invisible_AB == 0)) + (SameOwnB_lidx & (Invisible_AB == 0)));
				coordinated_trial_idx = find(coordinated_trial_lidx);
				anticoordinated_trial_lidx = ((DiffOwn_lidx & (Invisible_AB == 0)) + (DiffOther_lidx & (Invisible_AB == 0)));
				anticoordinated_trial_idx = find(anticoordinated_trial_lidx);
				cur_AB_RT_data_diff = A_RT_data - B_RT_data;
				[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest2(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, coordinated_trial_idx)), ...
					cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, anticoordinated_trial_idx)),...
					'Tail', 'both', 'Vartype', 'unequal');
				coordinated_vs_anticoordinated.ttest2 = ttest2res;
				% now add the result
				title_text = ['t-Test: Coordination (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, coordinated_trial_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, coordinated_trial_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, coordinated_trial_idx))), ')', ...
					' vs. Anti-Coordination (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, anticoordinated_trial_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, anticoordinated_trial_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, anticoordinated_trial_idx))), ')', ...
					', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];

				% SameA versus SameB
				CurSameA_idx = find(SameOwnA_lidx & (Invisible_AB == 0));
				CurSameB_idx = find(SameOwnB_lidx & (Invisible_AB == 0));
				[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest2(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx)), ...
					cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx)),...
					'Tail', 'both', 'Vartype', 'unequal');
				coordinated_vs_anticoordinated.ttest2 = ttest2res;
				% now add the result
				title_text2 = ['t-Test (hands visible): Coordination on A (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), ')', ...
					' vs. B (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), ')', ...
					', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];

				% SameA versus 0
				if ~isempty(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))
					[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx)), ...
						0,...
						'Tail', 'both');
					coordinated_vs_anticoordinated.ttest2 = ttest2res;
					% now add the result
					title_text2A = ['t-Test (hands visible): A (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), ')', ...
						' vs. 0', ...
						', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];
				else
					title_text2A = '';
				end
				% SameB versus 0
				if ~isempty(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))
					[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx)), ...
						0,...
						'Tail', 'both');
					coordinated_vs_anticoordinated.ttest2 = ttest2res;
					% now add the result
					title_text2B = ['t-Test (hands visible): B (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), ')', ...
						' vs. 0', ...
						', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];
				else
					title_text2B = '';
				end


				if (find(Invisible_AB(GoodTrialsIdx(JointTrialX_Vector))))
					% SameA versus SameB
					CurSameA_idx = find(SameOwnA_lidx & (Invisible_AB == 1));
					CurSameB_idx = find(SameOwnB_lidx & (Invisible_AB == 1));
					[ttest2res.h, ttest2res.p, ttest2res.ci, ttest2res.stats] = ttest2(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx)), ...
						cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx)),...
						'Tail', 'both', 'Vartype', 'unequal');
					coordinated_vs_anticoordinated.ttest2 = ttest2res;
					% now add the result
					title_text3 = ['t-Test (hands invisible): Coordination on A (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameA_idx))), ')', ...
						' vs. B (M: ', num2str(mean(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', SD: ', num2str(std(cur_AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), '%.2f'), ', N: ', num2str(length(intersect(CurrentGroupGoodTrialsIdx, CurSameB_idx))), ')', ...
						', t(', num2str(ttest2res.stats.df), '): ', num2str(ttest2res.stats.tstat), ', p: ', num2str(ttest2res.p)];
					title_text_list = {title_text; title_text2; title_text2A; title_text2B; title_text3};
				else
					title_text_list = {title_text; title_text2; title_text2A; title_text2B};
				end


				if (show_RTdiff_ttests)
					title(title_text_list, 'FontSize', title_fontsize, 'Interpreter', 'None', 'FontWeight', title_fontweight);
				end
				fn_save_string_list_to_file(current_stats_to_text_fd, [], {''; 'PlotRTHistogramsByByPayoffMatrixPostSwitchOnly'}, [], write_stats_to_text_file);
				fn_save_string_list_to_file(current_stats_to_text_fd, [], title_text_list, [' : ', histogram_RT_type_string], write_stats_to_text_file);


				if (plot_differences) && (ProcessSideA) && (ProcessSideB)
					CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.RTdiff'];
				end

				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySamenessPostSwitchTrials.', histogram_RT_type_string, '.', OutPutType]);
				write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);


				legend(legend_list, 'Interpreter', 'None');
				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySamenessPostSwitchTrials.legend.', histogram_RT_type_string, '.', OutPutType]);
				write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);
			end



			if (PlotRTHistogramsBySelectedSideAndEffector)

				% for selected side and used effector
				%SubjectiveLeftTargetSelected_A
				%SubjectiveLeftTargetSelected_B
				%RightHandUsed_A, RightHandUsed_B
				CurrentTitleSetDescriptorString = TitleSetDescriptorString;

				% create the subsets: same own A, same own B, diff own, diff other
				Same_AleftBright = (SubjectiveLeftTargetSelected_A == 1) & (SubjectiveLeftTargetSelected_B == 0);
				Same_ArightBleft = (SubjectiveLeftTargetSelected_A == 0) & (SubjectiveLeftTargetSelected_B == 1);
				Diff_AleftBleft = (SubjectiveLeftTargetSelected_A == 1) & (SubjectiveLeftTargetSelected_B == 1);
				Diff_ArightBright = (SubjectiveLeftTargetSelected_A == 0) & (SubjectiveLeftTargetSelected_B == 0);

				% create a stack of category vectors
				if (find(Invisible_AB(GoodTrialsIdx(JointTrialX_Vector))))
					VisSame_AleftBright = Same_AleftBright & (Invisible_AB == 0);
					VisSame_ArightBleft = Same_ArightBleft & (Invisible_AB == 0);
					VisDiff_AleftBleft = Diff_AleftBleft & (Invisible_AB == 0);
					VisDiff_ArightBright = Diff_ArightBright & (Invisible_AB == 0);
					InvisSame_AleftBright = Same_AleftBright & (Invisible_AB == 1);
					InvisSame_ArightBleft = Same_ArightBleft & (Invisible_AB == 1);
					InvisDiff_AleftBleft = Diff_AleftBleft & (Invisible_AB == 1);
					InvisDiff_ArightBright = Diff_ArightBright & (Invisible_AB == 1);

					legend_list = {'Same_A_left_B_right', 'Same_A_right_B_left', 'Diff_A_left_B_left', 'Diff_A_right_B_right', 'Opaque_Same_A_left_B_right', 'Opaque_Same_A_right_B_left', 'Opaque_Diff_A_left_B_left', 'Opaque_Diff_A_right_B_right'};

					if (histogram_show_median)
						legend_list = {'Same_A_left_B_right','Median Same_A_left_B_right', 'Diff_A_left_B_left', 'Median Diff_A_left_B_left', 'Diff_A_left_B_left', 'Median Diff_A_left_B_left', 'Diff_A_right_B_right', 'Median Diff_A_right_B_right', 'Opaque_Same_A_left_B_right', 'Median Opaque_Same_A_left_B_right', 'Opaque_Same_A_right_B_left', 'Median Opaque_Same_A_right_B_left', 'Opaque_Diff_A_left_B_left', 'Median Opaque_Diff_A_left_B_left', 'Opaque_Diff_A_right_B_right', 'Median Opaque_Diff_A_right_B_right'};
					end


					StackedCatData.TrialIdxList = {VisSame_AleftBright, VisSame_ArightBleft, VisDiff_AleftBleft, VisDiff_ArightBright, ...
						InvisSame_AleftBright, InvisSame_ArightBleft, InvisDiff_AleftBleft, InvisDiff_ArightBright};
					% half the brightness of the invisible trials
					StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor; SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
					StackedCatLineStyleList = {'-', '-', '-', '-', ':', ':' , ':', ':'};

					StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor; SameOwnAColor*0.66; SameOwnBColor*0.66; DiffOwnColor*0.66; DiffOtherColor*0.66};
					StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor; SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
					StackedCatData.LineStyleList = {'-', '-', '-', '-', '-.', '-.' , '-.', '-.'};
					StackedCatData.SignFactorList = [1, 1, 1, 1, -1, -1, -1, -1];

				else
					% no invisible trials just visible
					StackedCatData.TrialIdxList = {Same_AleftBright, Same_ArightBleft, Diff_AleftBleft, Diff_ArightBright};
					legend_list = {'Same_A_left_B_right', 'Same_A_right_B_left', 'Diff_A_left_B_left', 'Diff_A_right_B_right'};
					if (histogram_show_median)
						legend_list = {'Same_A_left_B_right','Median Same_A_left_B_right', 'Same_A_right_B_left', 'Median Same_A_right_B_left', 'Diff_A_left_B_left', 'Median Diff_A_left_B_left', 'Diff_A_right_B_right', 'Median Diff_A_right_B_right'};
					end

					StackedCatData.ColorList = {SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor};
					StackedCatData.LineStyleList = {'-', '-', '-', '-'};
					StackedCatData.SignFactorList = [1, 1, 1, 1];
				end

				Cur_fh_ReactionTimesBySameness = figure('Name', 'ReactionTimeHistogramBySide', 'visible', figure_visibility_string);
				fnFormatDefaultAxes(DefaultAxesType);
				[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
				set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );
				%legend_list = {};

				CurrentGroupGoodTrialsIdx = GoodTrialsIdx(JointTrialX_Vector);
				plot_differences = Plot_RT_difference_histogramBySelectedSideAndEffector;

				switch plot_differences
					case 0
						current_histogram_edge_list = histogram_edges;
					case 1
						current_histogram_edge_list =   histogram_diff_edges;
				end
				cur_plot_differences = plot_differences;

				if ~(ProcessSideA) || ~(ProcessSideB)
					current_histogram_edge_list = histogram_edges;
					cur_plot_differences = 0;
				end

				fnPlotRTHistogram(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, current_histogram_edge_list, cur_plot_differences, ProcessSideA, ProcessSideB, histnorm_string, histdisplaystyle_string, histogram_use_histogram_func, histogram_show_median, project_line_width);

				if (plot_differences) && (ProcessSideA) && (ProcessSideB)
					CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.RTdiff'];
				end

				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySide.', histogram_RT_type_string, '.', OutPutType]);
				write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);


				legend(legend_list, 'Interpreter', 'None');
				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySide.legend.', histogram_RT_type_string, '.', OutPutType]);
				write_out_figure(Cur_fh_ReactionTimesBySameness, outfile_fqn);


			end

			if (PlotRTbyChoiceCombination)
				% find the trial indices for the selected switch trials
				% for each member in selected_choice_combinaton_pattern_list
				% extract a histogram form a given data list
				CurrentGroupGoodTrialsIdx = GoodTrialsIdx(JointTrialX_Vector);
				% extract and aggregate the data per defined switch
				SideA_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, choice_combination_color_string, full_choice_combinaton_pattern_list, A_RT_data, pattern_alignment_offset, n_pre_bins, n_post_bins, strict_pattern_extension, pad_mismatch_with_nan);
				SideB_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, choice_combination_color_string, full_choice_combinaton_pattern_list, B_RT_data, pattern_alignment_offset, n_pre_bins, n_post_bins, strict_pattern_extension, pad_mismatch_with_nan);

				for i_aggregate_meta_type = 1 : length(aggregate_type_meta_list)
					current_aggregate_type = aggregate_type_meta_list{i_aggregate_meta_type};
					if ~isempty(SideA_pattern_histogram_struct) || ~isempty(SideB_pattern_histogram_struct)
						% now create a plot showing these transitions for both
						% agents
						Cur_fh_RTbyChoiceCombinationSwitches = figure('Name', ['RT histogram over choice combination switches: ', current_aggregate_type], 'visible', figure_visibility_string);
						fnFormatDefaultAxes(DefaultAxesType);
						[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
						set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );

						RT_by_switch_struct_list = {SideA_pattern_histogram_struct, SideB_pattern_histogram_struct};
						RT_by_switch_title_prefix_list = {'A: ', 'B: '};
						RT_by_switch_switch_pre_bins_list = {n_pre_bins, n_pre_bins};
						RT_by_switch_switch_n_bins_list = {(n_pre_bins + 1 + n_post_bins), (n_pre_bins + 1 + n_post_bins)};
						%RT_by_switch_color_list = {orange, green};
						RT_by_switch_color_list = {SideAColor, SideBColor};
						aggregate_type_list = {current_aggregate_type, current_aggregate_type};

						[Cur_fh_RTbyChoiceCombinationSwitches, merged_classifier_char_string] = fn_plot_RT_histogram_by_switches(Cur_fh_RTbyChoiceCombinationSwitches, RT_by_switch_struct_list, selected_choice_combinaton_pattern_list, RT_by_switch_title_prefix_list, RT_by_switch_switch_pre_bins_list, RT_by_switch_switch_n_bins_list, RT_by_switch_color_list, aggregate_type_list);

						if (ShowTargetSideChoiceCombinations)
							trial_outcome_list = zeros(size(merged_classifier_char_string));
							trial_outcome_list(merged_classifier_char_string == 'R') = 1;
							trial_outcome_list(merged_classifier_char_string == 'B') = 2;
							trial_outcome_list(merged_classifier_char_string == 'M') = 3;
							trial_outcome_list(merged_classifier_char_string == 'G') = 4;
							%
							trial_outcome_colors = [SameOwnAColor; SameOwnBColor; DiffOwnColor; DiffOtherColor];
							trial_outcome_BGTransparency = [1.0];

							y_lim = get(gca(), 'YLim');
							fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, {trial_outcome_list}, y_lim, {trial_outcome_colors}, {trial_outcome_BGTransparency});
							y_lim = get(gca(), 'YLim');
						end

						outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySwitches.', current_aggregate_type, '.', histogram_RT_type_string, '.', OutPutType]);
						write_out_figure(Cur_fh_RTbyChoiceCombinationSwitches, outfile_fqn);

						legend(legend_list, 'Interpreter', 'None');
						outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.RT.HistogramBySwitches.legend.', current_aggregate_type, '.', histogram_RT_type_string, '.', OutPutType]);
						write_out_figure(Cur_fh_RTbyChoiceCombinationSwitches, outfile_fqn);
					end
				end
			end
		end
		if (PlotChoicebyOthersSwitches) && ~(IsSoloGroup)

			% find the trial indices for the selected switch trials
			% for each member in selected_choice_combinaton_pattern_list
			% extract a histogram form a given data list
			CurrentGroupGoodTrialsIdx = GoodTrialsIdx(JointTrialX_Vector);
			% extract and aggregate the data per defined switch
			byAs_TC_SideA_TC_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, A_target_color_choice_string, ChoicebyOthersSwitches.full_TC_choice_combinaton_pattern_list, PreferableTargetSelected_A, ChoicebyOthersSwitches.pattern_alignment_offset, ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_post_bins, ChoicebyOthersSwitches.strict_pattern_extension, ChoicebyOthersSwitches.pad_mismatch_with_nan);
			byAs_TC_SideB_TC_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, A_target_color_choice_string, ChoicebyOthersSwitches.full_TC_choice_combinaton_pattern_list, PreferableTargetSelected_B, ChoicebyOthersSwitches.pattern_alignment_offset, ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_post_bins, ChoicebyOthersSwitches.strict_pattern_extension, ChoicebyOthersSwitches.pad_mismatch_with_nan);
			byBs_TC_SideA_TC_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, B_target_color_choice_string, ChoicebyOthersSwitches.full_TC_choice_combinaton_pattern_list, PreferableTargetSelected_A, ChoicebyOthersSwitches.pattern_alignment_offset, ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_post_bins, ChoicebyOthersSwitches.strict_pattern_extension, ChoicebyOthersSwitches.pad_mismatch_with_nan);
			byBs_TC_SideB_TC_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, B_target_color_choice_string, ChoicebyOthersSwitches.full_TC_choice_combinaton_pattern_list, PreferableTargetSelected_B, ChoicebyOthersSwitches.pattern_alignment_offset, ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_post_bins, ChoicebyOthersSwitches.strict_pattern_extension, ChoicebyOthersSwitches.pad_mismatch_with_nan);


			byAs_OS_SideA_OS_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, A_objective_side_choice_string, ChoicebyOthersSwitches.full_OS_choice_combinaton_pattern_list, LeftTargetSelected_A, ChoicebyOthersSwitches.pattern_alignment_offset, ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_post_bins, ChoicebyOthersSwitches.strict_pattern_extension, ChoicebyOthersSwitches.pad_mismatch_with_nan);
			byAs_OS_SideB_OS_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, A_objective_side_choice_string, ChoicebyOthersSwitches.full_OS_choice_combinaton_pattern_list, LeftTargetSelected_B, ChoicebyOthersSwitches.pattern_alignment_offset, ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_post_bins, ChoicebyOthersSwitches.strict_pattern_extension, ChoicebyOthersSwitches.pad_mismatch_with_nan);
			byBs_OS_SideA_OS_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, B_objective_side_choice_string, ChoicebyOthersSwitches.full_OS_choice_combinaton_pattern_list, LeftTargetSelected_A, ChoicebyOthersSwitches.pattern_alignment_offset, ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_post_bins, ChoicebyOthersSwitches.strict_pattern_extension, ChoicebyOthersSwitches.pad_mismatch_with_nan);
			byBs_OS_SideB_OS_pattern_histogram_struct = fn_build_PSTH_by_switch_trial_struct(CurrentGroupGoodTrialsIdx, B_objective_side_choice_string, ChoicebyOthersSwitches.full_OS_choice_combinaton_pattern_list, LeftTargetSelected_B, ChoicebyOthersSwitches.pattern_alignment_offset, ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_post_bins, ChoicebyOthersSwitches.strict_pattern_extension, ChoicebyOthersSwitches.pad_mismatch_with_nan);


			for i_aggregate_meta_type = 1 : length(ChoicebyOthersSwitches.aggregate_type_meta_list)
				current_aggregate_type = ChoicebyOthersSwitches.aggregate_type_meta_list{i_aggregate_meta_type};
				%if ~isempty(byAs_TC_SideA_TC_pattern_histogram_struct) || ~isempty(byBs_TC_SideA_TC_pattern_histogram_struct)
				% now create a plot showing these transitions for both
				% agents
				% 				figure_visibility_string = 'on'; % for debugging

				Cur_fh_SCbyEachAgentsSwitches = figure('Name', ['SOC over one agent''s switches: ', current_aggregate_type], 'visible', figure_visibility_string);
				fnFormatDefaultAxes(DefaultAxesType);
				[output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction, [], double_row_aspect_ratio);
				set(gcf(), 'Units', paper_unit_string, 'Position', output_rect, 'PaperPosition', output_rect, 'PaperPosition', output_rect );

				if ~isempty(byAs_TC_SideA_TC_pattern_histogram_struct) || ~isempty(byAs_TC_SideB_TC_pattern_histogram_struct)
					subplot(2,2,1);
					SC_by_switch_struct_list = {byAs_TC_SideA_TC_pattern_histogram_struct, byAs_TC_SideB_TC_pattern_histogram_struct};
					SC_by_switch_title_prefix_list = {'A: ', 'B: '};
					SC_by_switch_switch_pre_bins_list = {ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_pre_bins};
					SC_by_switch_switch_n_bins_list = {(ChoicebyOthersSwitches.n_pre_bins + 1 + ChoicebyOthersSwitches.n_post_bins), (ChoicebyOthersSwitches.n_pre_bins + 1 + ChoicebyOthersSwitches.n_post_bins)};
					%SC_by_switch_color_list = {orange, green};
					SC_by_switch_color_list = {SideAColor, SideBColor};
					aggregate_type_list = {current_aggregate_type, current_aggregate_type};
					x_label_string = 'A''s target switches';
					y_label_string = 'Own choices';

					[Cur_fh_SCbyEachAgentsSwitches, merged_classifier_char_string] = fn_plot_SOC_histogram_by_switches(Cur_fh_SCbyEachAgentsSwitches, SC_by_switch_struct_list, ChoicebyOthersSwitches.selected_TC_switch_pattern_list, SC_by_switch_title_prefix_list, SC_by_switch_switch_pre_bins_list, SC_by_switch_switch_n_bins_list, SC_by_switch_color_list, aggregate_type_list, x_label_string, y_label_string);
					if (ShowTargetSideChoiceCombinations)
						trial_outcome_list = zeros(size(merged_classifier_char_string));
						trial_outcome_list(merged_classifier_char_string == 'R') = 1;
						trial_outcome_list(merged_classifier_char_string == 'B') = 2;
						trial_outcome_colors = [SameOwnAColor; SameOwnBColor];
						trial_outcome_BGTransparency = [1.0];
						y_lim = get(gca(), 'YLim');
						fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, {trial_outcome_list}, y_lim, {trial_outcome_colors}, {trial_outcome_BGTransparency});
						y_lim = get(gca(), 'YLim');
					end
				end

				if ~isempty(byBs_TC_SideA_TC_pattern_histogram_struct) || ~isempty(byBs_TC_SideB_TC_pattern_histogram_struct)
					subplot(2,2,3);
					SC_by_switch_struct_list = {byBs_TC_SideA_TC_pattern_histogram_struct, byBs_TC_SideB_TC_pattern_histogram_struct};
					SC_by_switch_title_prefix_list = {'A: ', 'B: '};
					SC_by_switch_switch_pre_bins_list = {ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_pre_bins};
					SC_by_switch_switch_n_bins_list = {(ChoicebyOthersSwitches.n_pre_bins + 1 + ChoicebyOthersSwitches.n_post_bins), (ChoicebyOthersSwitches.n_pre_bins + 1 + ChoicebyOthersSwitches.n_post_bins)};
					%SC_by_switch_color_list = {orange, green};
					SC_by_switch_color_list = {SideAColor, SideBColor};
					aggregate_type_list = {current_aggregate_type, current_aggregate_type};
					x_label_string = 'B''s target switches';
					y_label_string = 'Own choices';

					[Cur_fh_SCbyEachAgentsSwitches, merged_classifier_char_string] = fn_plot_SOC_histogram_by_switches(Cur_fh_SCbyEachAgentsSwitches, SC_by_switch_struct_list, ChoicebyOthersSwitches.selected_TC_switch_pattern_list, SC_by_switch_title_prefix_list, SC_by_switch_switch_pre_bins_list, SC_by_switch_switch_n_bins_list, SC_by_switch_color_list, aggregate_type_list, x_label_string, y_label_string);
					if (ShowTargetSideChoiceCombinations)
						trial_outcome_list = zeros(size(merged_classifier_char_string));
						trial_outcome_list(merged_classifier_char_string == 'R') = 1;
						trial_outcome_list(merged_classifier_char_string == 'B') = 2;
						trial_outcome_colors = [SameOwnAColor; SameOwnBColor];
						trial_outcome_BGTransparency = [1.0];
						y_lim = get(gca(), 'YLim');
						fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, {trial_outcome_list}, y_lim, {trial_outcome_colors}, {trial_outcome_BGTransparency});
						y_lim = get(gca(), 'YLim');
					end
				end

				if ~isempty(byAs_OS_SideA_OS_pattern_histogram_struct) || ~isempty(byAs_OS_SideB_OS_pattern_histogram_struct)
					subplot(2,2,2);
					SC_by_switch_struct_list = {byAs_OS_SideA_OS_pattern_histogram_struct, byAs_OS_SideB_OS_pattern_histogram_struct};
					SC_by_switch_title_prefix_list = {'A: ', 'B: '};
					SC_by_switch_switch_pre_bins_list = {ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_pre_bins};
					SC_by_switch_switch_n_bins_list = {(ChoicebyOthersSwitches.n_pre_bins + 1 + ChoicebyOthersSwitches.n_post_bins), (ChoicebyOthersSwitches.n_pre_bins + 1 + ChoicebyOthersSwitches.n_post_bins)};
					%SC_by_switch_color_list = {orange, green};
					SC_by_switch_color_list = {SideAColor, SideBColor};
					aggregate_type_list = {current_aggregate_type, current_aggregate_type};
					x_label_string = 'A''s side switches';
					y_label_string = 'Left choices';

					[Cur_fh_SCbyEachAgentsSwitches, merged_classifier_char_string] = fn_plot_SOC_histogram_by_switches(Cur_fh_SCbyEachAgentsSwitches, SC_by_switch_struct_list, ChoicebyOthersSwitches.selected_OS_switch_pattern_list, SC_by_switch_title_prefix_list, SC_by_switch_switch_pre_bins_list, SC_by_switch_switch_n_bins_list, SC_by_switch_color_list, aggregate_type_list, x_label_string, y_label_string);
					if (ShowTargetSideChoiceCombinations)
						trial_outcome_list = zeros(size(merged_classifier_char_string));
						trial_outcome_list(merged_classifier_char_string == 'R') = 1;
						trial_outcome_list(merged_classifier_char_string == 'L') = 2;
						trial_outcome_colors = [A_right_B_left_Color; A_left_B_right_Color];
						trial_outcome_BGTransparency = [1.0];
						y_lim = get(gca(), 'YLim');
						fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, {trial_outcome_list}, y_lim, {trial_outcome_colors}, {trial_outcome_BGTransparency});
						y_lim = get(gca(), 'YLim');
					end
				end

				if ~isempty(byBs_OS_SideA_OS_pattern_histogram_struct) || ~isempty(byBs_OS_SideB_OS_pattern_histogram_struct)
					subplot(2,2,4);
					SC_by_switch_struct_list = {byBs_OS_SideA_OS_pattern_histogram_struct, byBs_OS_SideB_OS_pattern_histogram_struct};
					SC_by_switch_title_prefix_list = {'A: ', 'B: '};
					SC_by_switch_switch_pre_bins_list = {ChoicebyOthersSwitches.n_pre_bins, ChoicebyOthersSwitches.n_pre_bins};
					SC_by_switch_switch_n_bins_list = {(ChoicebyOthersSwitches.n_pre_bins + 1 + ChoicebyOthersSwitches.n_post_bins), (ChoicebyOthersSwitches.n_pre_bins + 1 + ChoicebyOthersSwitches.n_post_bins)};
					%SC_by_switch_color_list = {orange, green};
					SC_by_switch_color_list = {SideAColor, SideBColor};
					aggregate_type_list = {current_aggregate_type, current_aggregate_type};
					x_label_string = 'B''s side switches';
					y_label_string = 'Left choices';

					[Cur_fh_SCbyEachAgentsSwitches, merged_classifier_char_string] = fn_plot_SOC_histogram_by_switches(Cur_fh_SCbyEachAgentsSwitches, SC_by_switch_struct_list, ChoicebyOthersSwitches.selected_OS_switch_pattern_list, SC_by_switch_title_prefix_list, SC_by_switch_switch_pre_bins_list, SC_by_switch_switch_n_bins_list, SC_by_switch_color_list, aggregate_type_list, x_label_string, y_label_string);
					if (ShowTargetSideChoiceCombinations)
						trial_outcome_list = zeros(size(merged_classifier_char_string));
						trial_outcome_list(merged_classifier_char_string == 'R') = 1;
						trial_outcome_list(merged_classifier_char_string == 'L') = 2;
						trial_outcome_colors = [A_right_B_left_Color; A_left_B_right_Color];
						trial_outcome_BGTransparency = [1.0];
						y_lim = get(gca(), 'YLim');
						fnPlotStackedCategoriesAtPositionWrapper('StackedOnBottom', StackHeightToInitialPLotHeightRatio, {trial_outcome_list}, y_lim, {trial_outcome_colors}, {trial_outcome_BGTransparency});
						y_lim = get(gca(), 'YLim');
					end
				end


				outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SC.ChoicebyOthersSwitches.', current_aggregate_type, '.', OutPutType]);
				write_out_figure(Cur_fh_SCbyEachAgentsSwitches, outfile_fqn);

				%legend(legend_list, 'Interpreter', 'None');
				%outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.SC.ChoicebyOthersSwitches.legend.', current_aggregate_type, '.', OutPutType]);
				%write_out_figure(Cur_fh_SCbyEachAgentsSwitches, outfile_fqn);
				%end
			end
		end
	end





	if (write_stats_to_text_file)
		disp(['Closing current stats to text file: ', current_stats_to_text_FQN]);
		fclose(current_stats_to_text_fd);
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

% function [] = fnPlotStackedCategoriesAtPositionWrapper( PositionLabel, StackHeightToInitialPLotHeightRatio, StackedXData, y_lim, StackedColors, StackedTransparencies )
% y_height = (y_lim(2) - y_lim(1));
% num_stacked_items = size(StackedXData, 1);
% new_y_lim = y_lim;
%
% switch PositionLabel
% 	case 'StackedOnTop'
% 		% make room for the category markers on top of the existing plot
% 		y_increment_per_stack = y_height * StackHeightToInitialPLotHeightRatio / (num_stacked_items + 1);
% 		new_y_lim = [y_lim(1), (y_lim(2) + (StackHeightToInitialPLotHeightRatio) * y_height)];
% 		set(gca(), 'YLim', new_y_lim);
%
% 	case 'StackedOnBottom'
% 		% make room for the category markers below the existing plot
% 		y_increment_per_stack = y_height * StackHeightToInitialPLotHeightRatio / (num_stacked_items + 1);
% 		new_y_lim = [(y_lim(1) - (StackHeightToInitialPLotHeightRatio) * y_height), y_lim(2)];
% 		set(gca(), 'YLim', new_y_lim);
%
% 	case 'StackedBottomToTop'
% 		% just fill the existing plot area
% 		y_increment_per_stack = y_height / (num_stacked_items);
% 		new_y_lim = y_lim;
%
% 	otherwise
% 		disp(['Position label: ', PositionLabel, ' not implemented yet, skipping...'])
% 		return
% end
%
%
% for iStackItem = 1 : num_stacked_items
% 	CurrentCategoryByXVals = StackedXData{iStackItem};
% 	CurrentColorByCategoryList = StackedColors{iStackItem};
% 	CurrentTransparency = StackedTransparencies{iStackItem};
% 	switch PositionLabel
% 		case 'StackedOnTop'
% 			% we want one y_increment as separator from the plots intial YLimits
% 			CurrentLowY = y_lim(2) + ((iStackItem) * y_increment_per_stack);
% 			CurrentHighY = CurrentLowY + y_increment_per_stack;
%
% 		case 'StackedOnBottom'
% 			% we want one y_increment as separator from the plots intial YLimits
% 			CurrentLowY = new_y_lim(1) + ((iStackItem - 1) * y_increment_per_stack);
% 			CurrentHighY = CurrentLowY + y_increment_per_stack;
%
% 		case 'StackedBottomToTop'
% 			% we want one y_increment as separator from the plots intial
% 			% YLimits
% 			CurrentLowY = y_lim(1) + ((iStackItem - 1) * y_increment_per_stack);
% 			CurrentHighY = CurrentLowY + y_increment_per_stack;
% 	end
% 	% now plot
% 	fnPlotBackgroundByCategory(CurrentCategoryByXVals, [CurrentLowY, CurrentHighY], CurrentColorByCategoryList, CurrentTransparency);
% end
%
% return
% end


function [] = fnPlotBoxWhisker(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, plot_differences, ProcessSideA, ProcessSideB, project_line_width)

my_PlotStyle = 'traditional'; % traditional or compact


%TODO:
%	allow empty categories (create single NaN entry in bw_data with the
%	matching cat name
%	clean up function signature
% allow multiple sets of data and suffixes?

% for solo/single data default to non-difference data
if (ProcessSideA) && (ProcessSideB) && (plot_differences)

else
	plot_differences = 0;
end


if (plot_differences)
	AB_RT_data_diff = A_RT_data - B_RT_data;
end

% create the data and label set
n_cats = length(StackedCatData.CatNameList);
% here we construct the data input for box plot, to allow overlapping trial
% sets we will replicate some RT data if need be
bw_data = [];
bw_cat_list = {};
for i_cat = 1 : length(StackedCatData.CatNameList)
	cur_cat_name = StackedCatData.CatNameList{i_cat};
	cur_cat_trial_ldx = StackedCatData.TrialIdxList{i_cat};
	n_cat_trials = sum(cur_cat_trial_ldx);
	% only take good trials
	cur_cat_trial_idx = intersect(find(cur_cat_trial_ldx), CurrentGroupGoodTrialsIdx);

	n_cat_trials = length(cur_cat_trial_idx);

	if (plot_differences)
		if (ProcessSideA) && (ProcessSideB)
			cur_data = A_RT_data - B_RT_data;
		end
		cur_cat_list = cell([1, n_cat_trials]);
		for i_cat_trial = 1 : n_cat_trials
			cur_cat_list{i_cat_trial} = [cur_cat_name, '(A-B)'];
		end
		if (n_cat_trials > 0)
			bw_data = [bw_data, cur_data(cur_cat_trial_idx)'];
			bw_cat_list = [bw_cat_list, cur_cat_list];
		else
			bw_data(end+1) = NaN;
			bw_cat_list{end+1} = [cur_cat_name, '(A-B)'];
		end
	else
		cur_data = [];
		% here we concatenate for the sides and add a suffix to the CatName
		if (ProcessSideA)
			cur_cat_list = cell([1, n_cat_trials]);
			for i_cat_trial = 1 : n_cat_trials
				cur_cat_list{i_cat_trial} = [cur_cat_name, '(A)'];
			end
			if (n_cat_trials > 0)
				%tmp_data = bw_data;
				bw_data = [bw_data, A_RT_data(cur_cat_trial_idx)'];
				tmp_bw_cat_list = bw_cat_list;
				bw_cat_list = [bw_cat_list, cur_cat_list];
			else
				bw_data(end+1) = NaN;
				bw_cat_list{end+1} = [cur_cat_name, '(A)'];
			end

		end
		if (ProcessSideB)
			cur_cat_list = cell([1, n_cat_trials]);
			for i_cat_trial = 1 : n_cat_trials
				cur_cat_list{i_cat_trial} = [cur_cat_name, '(B)'];
			end
			if (n_cat_trials > 0)
				bw_data = [bw_data, B_RT_data(cur_cat_trial_idx)'];
				bw_cat_list = [bw_cat_list, cur_cat_list];
			else
				bw_data(end+1) = NaN;
				bw_cat_list{end+1} = [cur_cat_name, '(B)'];
			end
		end
	end
end

%boxplot(bw_data, bw_cat_list, 'Notch', 'on', 'Labels', StackedCatData.CatNameList);

boxplot(bw_data, bw_cat_list, 'Notch', 'on', 'PlotStyle', my_PlotStyle, 'LabelOrientation', 'horizontal');


return
end


function [] = fnPlotRTHistogram(StackedCatData, CurrentGroupGoodTrialsIdx, A_RT_data, B_RT_data, current_histogram_edge_list, plot_differences, ProcessSideA, ProcessSideB, histnorm_string, histdisplaystyle_string, histogram_use_histogram_func, histogram_show_median, project_line_width)

StackedCatTrialIdxList = StackedCatData.TrialIdxList;
StackedCatColorList = StackedCatData.ColorList;
StackedCatLineStyleList = StackedCatData.LineStyleList;
StackedCatSignFactorList = StackedCatData.SignFactorList;

% gather multiple plots into one figure
hold on

if (plot_differences)
	AB_RT_data_diff = A_RT_data - B_RT_data;
end


neg_hist_histcounts_per_bin = 0;
pos_hist_histcounts_per_bin = 0;

% deal with secondary, "negative" histograms individually
neg_hist_cat_idx = find(StackedCatSignFactorList == -1);
pos_hist_cat_idx = find(StackedCatSignFactorList == 1);

if ~isempty(neg_hist_cat_idx)
	neg_hist_CurrentGroupGoodTrialsIdx = [];
	for i_hist_cat = 1 : length(neg_hist_cat_idx)
		neg_hist_CurrentGroupGoodTrialsIdx = union(neg_hist_CurrentGroupGoodTrialsIdx,  find(StackedCatData.TrialIdxList{neg_hist_cat_idx(i_hist_cat)}));
	end

	if (plot_differences) && (ProcessSideA) && (ProcessSideB)
		neg_hist_histcounts_per_bin = histcounts(AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, neg_hist_CurrentGroupGoodTrialsIdx)), current_histogram_edge_list);
	else
		neg_hist_histcounts_per_bin_A = histcounts(A_RT_data(intersect(CurrentGroupGoodTrialsIdx, neg_hist_CurrentGroupGoodTrialsIdx)), current_histogram_edge_list);
		neg_hist_histcounts_per_bin_B = histcounts(B_RT_data(intersect(CurrentGroupGoodTrialsIdx, neg_hist_CurrentGroupGoodTrialsIdx)), current_histogram_edge_list);
		neg_hist_histcounts_per_bin = max(neg_hist_histcounts_per_bin_A, neg_hist_histcounts_per_bin_B); % required for axis scaling
	end
end

if ~isempty(pos_hist_cat_idx)
	pos_hist_CurrentGroupGoodTrialsIdx = [];
	for i_hist_cat = 1 : length(pos_hist_cat_idx)
		pos_hist_CurrentGroupGoodTrialsIdx = union(pos_hist_CurrentGroupGoodTrialsIdx,  find(StackedCatData.TrialIdxList{pos_hist_cat_idx(i_hist_cat)}));
	end
	%pos_hist_histcounts_per_bin = histcounts(AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, pos_hist_CurrentGroupGoodTrialsIdx)), current_histogram_edge_list);
	if (plot_differences) && (ProcessSideA) && (ProcessSideB)
		pos_hist_histcounts_per_bin = histcounts(AB_RT_data_diff(intersect(CurrentGroupGoodTrialsIdx, pos_hist_CurrentGroupGoodTrialsIdx)), current_histogram_edge_list);
	else
		pos_hist_histcounts_per_bin_A = histcounts(A_RT_data(intersect(CurrentGroupGoodTrialsIdx, pos_hist_CurrentGroupGoodTrialsIdx)), current_histogram_edge_list);
		pos_hist_histcounts_per_bin_B = histcounts(B_RT_data(intersect(CurrentGroupGoodTrialsIdx, pos_hist_CurrentGroupGoodTrialsIdx)), current_histogram_edge_list);
		pos_hist_histcounts_per_bin = max(pos_hist_histcounts_per_bin_A, pos_hist_histcounts_per_bin_B); % required for axis scaling
	end

end

% % these are only used for scaling
% if (plot_differences) && (ProcessSideA) && (ProcessSideB)
% 	pos_histcounts_per_bin = histcounts(AB_RT_data_diff(CurrentGroupGoodTrialsIdx), current_histogram_edge_list);
% else
% 	histcounts_per_bin_A = histcounts(A_RT_data(CurrentGroupGoodTrialsIdx), current_histogram_edge_list);
% 	histcounts_per_bin_B = histcounts(B_RT_data(CurrentGroupGoodTrialsIdx), current_histogram_edge_list);
% 	histcounts_per_bin = max(histcounts_per_bin_A, histcounts_per_bin_B); % required for axis scaling
% end



axis_quantum = 5;

% allow manual normalisation
pos_man_normalisation_factor = 1;
neg_man_normalisation_factor = 1;
histnorm_method_string = histnorm_string;
if strcmp(histnorm_string, 'normalized_count')
	% force manual normalization to allow normalization across groups
	histnorm_method_string = 'count';
	histogram_use_histogram_func = 0;
	axis_quantum = 0.05;
	if (sum(pos_hist_histcounts_per_bin) ~= 0)
		pos_man_normalisation_factor = 1 / sum(pos_hist_histcounts_per_bin);
	end
	if (sum(neg_hist_histcounts_per_bin) ~= 0)
		neg_man_normalisation_factor = 1 / sum(neg_hist_histcounts_per_bin);
	end
	% 	axis_limit = 1;
	% 	pos_axis_limit = axis_quantum * ceil(max(pos_hist_histcounts_per_bin) / axis_quantum) * pos_man_normalisation_factor;
	% 	neg_axis_limit = axis_quantum * ceil(max(neg_hist_histcounts_per_bin) / axis_quantum) * neg_man_normalisation_factor;
end


if strcmp(histnorm_string, 'percentage_count')
	% force manual normalization to allow normalization across groups
	histnorm_method_string = 'count';
	histogram_use_histogram_func = 0;
	axis_quantum = 5;
	if (sum(pos_hist_histcounts_per_bin) ~= 0)
		pos_man_normalisation_factor = 100 / sum(pos_hist_histcounts_per_bin);
	end
	if (sum(neg_hist_histcounts_per_bin) ~= 0)
		neg_man_normalisation_factor = 100 / sum(neg_hist_histcounts_per_bin);
	end
end



% try to scale the axis
pos_axis_limit = axis_quantum * ceil(max(pos_hist_histcounts_per_bin) / axis_quantum) * pos_man_normalisation_factor;
neg_axis_limit = axis_quantum * ceil(max(neg_hist_histcounts_per_bin) / axis_quantum) * neg_man_normalisation_factor;
axis_limit = max([pos_axis_limit, neg_axis_limit]);

if ismember(histnorm_string, {'probability', 'cdf'})
	axis_limit = 1;
	pos_axis_limit = 1;
	neg_axis_limit = 1;
end


lower_y = 0;
if ~isempty(find(StackedCatSignFactorList == -1))
	lower_y = -1 * neg_axis_limit;
end

upper_y = 0;
if ~isempty(find(StackedCatSignFactorList == 1))
	upper_y = 1 * pos_axis_limit;
end

if (lower_y == 0) && (upper_y == 0)
	set(gca, 'YLim', [0, 1]);
else
	if (axis_limit ~= 0)
		set(gca, 'YLim', [lower_y, upper_y]);
	end
end

max_bin_val = 0;
min_bin_val = 0;
max_bin_val_A = 0;
min_bin_val_A = 0;
max_bin_val_B = 0;
min_bin_val_B = 0;



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
			hist_AB_struct.(['h', num2str(i_cat, '%03d')]) = histogram(AB_RT_data_diff(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_method_string, 'FaceColor', current_CatFaceColor, 'EdgeColor', current_CatColor, 'DisplayStyle', histdisplaystyle_string, 'LineWidth', project_line_width, 'LineStyle', current_CatLineStyle);
			if (histogram_show_median)
				line([median(AB_RT_data_diff(current_CatTrial_idx)), median(AB_RT_data_diff(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.6, 'LineStyle', current_CatLineStyle);
			end
		else
			[N, edges, bin] = histcounts(AB_RT_data_diff(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_method_string);
			if (current_CatSignFactor > 0)
				N = N * pos_man_normalisation_factor;
				max_bin_val = max([max_bin_val, (N * current_CatSignFactor)]);
			end
			if (current_CatSignFactor < 0)
				N = N * neg_man_normalisation_factor;
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
				hist_A_struct.(['h', num2str(i_cat, '%03d')]) = histogram(A_RT_data(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_method_string, 'FaceColor', current_CatFaceColor, 'EdgeColor', current_CatColor, 'DisplayStyle', histdisplaystyle_string, 'LineWidth', project_line_width, 'LineStyle', '-');
				if (histogram_show_median)
					line([median(A_RT_data(current_CatTrial_idx)), median(A_RT_data(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.5, 'LineStyle', '-');
				end
			else
				[N, edges, bin] = histcounts(A_RT_data(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_method_string);
				if (current_CatSignFactor > 0)
					N = N * pos_man_normalisation_factor;
					max_bin_val_A = max([max_bin_val_A, (N * current_CatSignFactor)]);
				end
				if (current_CatSignFactor < 0)
					N = N * neg_man_normalisation_factor;
					min_bin_val_A = min([min_bin_val_A, (N * current_CatSignFactor)]);
				end

				plot(diff(edges)*0.5 + edges(1:end-1), N * current_CatSignFactor, 'Color', current_CatColor, 'LineWidth', project_line_width, 'LineStyle', '-');
				if (histogram_show_median)
					line([median(A_RT_data(current_CatTrial_idx)), median(A_RT_data(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.6, 'LineStyle', '-');
				end
			end
		end
		if (ProcessSideB)
			if (histogram_use_histogram_func)
				hist_B_struct.(['h', num2str(i_cat, '%03d')]) = histogram(B_RT_data(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_method_string, 'FaceColor', current_CatFaceColor, 'EdgeColor', current_CatColor, 'DisplayStyle', histdisplaystyle_string, 'LineWidth', project_line_width, 'LineStyle', ':');
				if (histogram_show_median)
					line([median(B_RT_data(current_CatTrial_idx)), median(B_RT_data(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.5, 'LineStyle', ':');
				end
			else
				[N, edges, bin] = histcounts(B_RT_data(current_CatTrial_idx), current_histogram_edge_list, 'Normalization', histnorm_method_string);
				if (current_CatSignFactor > 0)
					N = N * pos_man_normalisation_factor;
					max_bin_val_B = max([max_bin_val_B, (N * current_CatSignFactor)]);
				end
				if (current_CatSignFactor < 0)
					N = N * neg_man_normalisation_factor;
					min_bin_val_B = min([min_bin_val_B, (N * current_CatSignFactor)]);
				end

				plot(diff(edges)*0.5 + edges(1:end-1), N * current_CatSignFactor, 'Color', current_CatColor, 'LineWidth', project_line_width, 'LineStyle', ':');
				if (histogram_show_median)
					line([median(B_RT_data(current_CatTrial_idx)), median(B_RT_data(current_CatTrial_idx))], get(gca(), 'YLim'), 'Color', current_CatColor, 'LineWidth', project_line_width*0.6, 'LineStyle', ':');
				end
			end
		end
	end
end

if ~(plot_differences)
	max_bin_val = max(max_bin_val_A, max_bin_val_B);
	min_bin_val = min(min_bin_val_A, min_bin_val_B);
end


hold off
if (axis_limit ~= 0) && (axis_limit ~= 1)
	tmp_upper_y = ceil(max_bin_val / axis_quantum) * axis_quantum;
	tmp_lower_y = floor(min_bin_val /axis_quantum) * axis_quantum;
	if (tmp_lower_y < 0)
		lower_y = min([tmp_lower_y, -1*tmp_upper_y]);
	end
	if (tmp_upper_y > 0)
		upper_y = max([tmp_lower_y*-1, tmp_upper_y]);
	end

	set(gca, 'YLim', [lower_y, upper_y]);
end

if (plot_differences)
	% this defines whether A was faster or B
	line([0, 0], get(gca(), 'YLim'), 'Color', [0 0 0], 'LineWidth', project_line_width*0.5, 'LineStyle', '-');
end


%set(gca(), 'YLim', [0.0, 1.0]);
set(gca(),'TickLabelInterpreter','none');

switch histnorm_string
	case 'count'
		ylabel( 'Number of trials per bin');
		%set(gca(), 'YTick', [0, 100]);
	case {'probability', 'cdf'}
		ylabel( 'Probability');
		set(gca(), 'YTick', [0, 1]);
	case 'normalized_count'
		ylabel( 'Fraction of trials');
	case 'percentage_count'
		ylabel( 'Percent of trials');

end

if (plot_differences) && (ProcessSideA) && (ProcessSideB)
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




function [columnnames_struct, n_fields] = local_get_column_name_indices(name_list, start_val)
% return a structure with each field for each member if the name_list cell
% array, giving the position in the name_list, then the columnnames_struct
% can serve as to address the columns, so the functions assigning values
% to the columns do not have to care too much about the positions, and it
% becomes easy to add fields.
% name_list: cell array of string names for the fields to be added
% start_val: numerical value to start the field values with (if empty start
%            with 1 so the results are valid indices into name_list)

if nargin < 2
	start_val = 1;  % value of the first field
end
n_fields = length(name_list);
for i_col = 1 : length(name_list)
	cur_name = name_list{i_col};
	% skip empty names, this allows non consequtive numberings
	if ~isempty(cur_name)
		columnnames_struct.(cur_name) = i_col + (start_val - 1);
	end
end
return
end