function [] = subject_bias_analysis_sm01(ProcessFirstOnly)
%clear variables;

timestamps.(mfilename).start = tic;
disp([mfilename, ': Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);


if  ~exist('ProcessFirstOnly', 'var')
	% manual override
	ProcessFirstOnly = 1;
else
	disp([mfilename, ': ProcessFirstOnly from caller: ', num2str(ProcessFirstOnly)]);
end

copy_triallogs_to_outputdir = 0;
ProcessNewestFirst = 1;
RunSingleSessionAnalysis = 1;
ProcessFreshSessionsOnly = 0;	% only process sessions without a *.triallog.vNN.mat file, aka completely fresh sessions
use_named_set = 0;
fresh_definition_string = 'no_statistics_txt';
override_directive = 'local';
%override_directive = 'local_code';
save_plots_to_sessiondir = 0;	% either collect plots in a big output directory or inside each sessiondirectory


project_name = [];
project_name = 'BoS_manuscript';


set_name = '';
project_name = 'SfN2008'; % this loops back to 2019
%%project_name = 'SfN2018'; % this loops back to 2019


use_named_set = 0;
%set_name = 'ConfederateElmoDiffGO';

if strcmp(set_name, 'ConfederateElmoDiffGO')
	use_named_set = 1;
	ProcessNewestFirst = 1;
	ProcessFreshSessionsOnly = 0;	% only process sessions without a *.triallog.vNN.mat file, aka completely fresh sessions
end

% special case for the paper set
if strcmp(project_name, 'BoS_manuscript')
	ProcessFreshSessionsOnly = 0;
	use_named_set = 1;
	set_name = 'BoS_manuscript';
	%fresh_definition_string = 'no_statistics_txt';
	fresh_definition_string = 'no_coordination_check_mat';
end


% from the linux VM
if (fnIsMatlabRunningInTextMode)
	use_named_set = 0;
	set_name = '';
	save_plots_to_sessiondir = 1;
	override_directive = 'local_code';
	project_name = 'SfN2008';
	%project_name = [];
	fresh_definition_string = 'no_statistics_txt';
	ProcessFirstOnly = 0;
	ProcessNewestFirst = 1;
	ProcessFreshSessionsOnly = 1;
end



% human subjects
CurrentAnalysisSetName = 'SCP00';
% NHP subjects
CurrentAnalysisSetName = 'SCP01';

CurrentAnalysisSetName = 'SCP_DATA';

%CurrentAnalysisSetName = 'SCP_DATA_SFN2018';

%CurrentAnalysisSetName = 'PrimateNeurobiology2018DPZ';

% %CurrentAnalysisSetName = 'LabRetreat2017';
% CurrentAnalysisSetName = 'LabRetreat2017FC';    % Free Choice
% CurrentAnalysisSetName = 'LabRetreat2017IC';    % Informed Choice
%
% CurrentAnalysisSetName = 'Evaluation2017FC';    % Free Choice
% CurrentAnalysisSetName = 'Evaluation2017IC';    % Informed Choice


%experimentFolder = '201705ReachBiasData\\SCP-CTRL-01\\SESSIONLOGS\\';
%experimentFolder = fullfile('201705ReachBiasData', 'SCP-CTRL-01', 'SESSIONLOGS');


SCPDirs = GetDirectoriesByHostName(override_directive);
LogFileWildCardString2018 = '*.triallog.txt';   % new file extension to allow better wildcarding and better typing

use_triallog_witout_extension = 0;
switch CurrentAnalysisSetName
	
	case {'PrimateNeurobiology2018DPZ'}
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP_DATA');
		% to speed things up collect the selected sessuins triallog files
		experimentFolder = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'Projects', 'ProgressReportsAndPresentations', 'PrimateNeurobiology2018_TUE', 'ANALYSES', 'UsedTriallogFiles');
		LogFileWildCardString = '*.triallog.txt';
		
	case {'SCP_DATA', 'SCP_DATA_SFN2018'}
		[tmp_dir, tmp_name] = fileparts(SCPDirs.SCP_DATA_BaseDir);
		if strcmp(tmp_name, 'SCP_DATA')
			experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP-CTRL-01'); % avoid the analysis folder with its looped sym links
		else
			experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS');
			experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP_DATA', 'SCP-CTRL-01'); % avoid the analysis folder with its looped sym links
			%experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP_DATA');
		end
		
		LogFileWildCardString = '*.triallog.txt';
		
		LogFileWildCardString = '*.triallog*';	%
		use_triallog_witout_extension = 1;
		
		
	case {'SCP01'}
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS');
		LogFileWildCardString = '*SCP_01.log';
		
	case {'SCP00'}
		% the human data
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP-CTRL-00', 'SCP_DATA', 'SCP-CTRL-00', 'SESSIONLOGS');
		LogFileWildCardString = '*SCP_00.log';
		
	case {'LabRetreat2017'}
		% data for the lab retreat 2017 presentation
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'LabReatreat2017_BvS', 'LogFiles');
		LogFileWildCardString = '*.log';
		
	case {'LabRetreat2017FC'}
		% data for the lab retreat 2017 presentation
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'LabReatreat2017_BvS', 'LogFiles', 'FreeChoiceSessionLogs');
		LogFileWildCardString = '*.log';
		
	case {'LabRetreat2017IC'}
		% data for the lab retreat 2017 presentation
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'LabReatreat2017_BvS', 'LogFiles', 'InformedChoiceSessionLogs');
		LogFileWildCardString = '*.log';
		
	case {'Evaluation2017FC'}
		% data for the lab retreat 2017 presentation
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'CNL_Evaluation_2017', 'LogFiles', 'FreeChoiceSessionLogs');
		LogFileWildCardString = '*.log';
		
	case {'Evaluation2017IC'}
		% data for the lab retreat 2017 presentation
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'CNL_Evaluation_2017', 'LogFiles', 'InformedChoiceSessionLogs');
		LogFileWildCardString = '*.log';
		
	otherwise
		error(['Encountered yet unhandled set up numer ', num2str(CurrentSetUpNum), ' stopping.']);
end

switch CurrentAnalysisSetName
	case {'PrimateNeurobiology2018DPZ'}
		% for PrimNeuro2018, /space/data_local/moeller/DPZ/Projects/ProgressReportsAndPresentations/PrimateNeurobiology2018_TUE/
		SCPDirs.OutputDir = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'Projects', 'ProgressReportsAndPresentations', 'PrimateNeurobiology2018_TUE', 'ANALYSES');
	case {'SCP_DATA_SFN2018'}
		% for PrimNeuro2018, /space/data_local/moeller/DPZ/Projects/ProgressReportsAndPresentations/PrimateNeurobiology2018_TUE/
		SCPDirs.OutputDir = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'Projects', 'ProgressReportsAndPresentations', '20181103_SfN-Meeting_San_Diego', 'ANALYSES');
	case {'SCP_DATA'}
		% for PrimNeuro2018, /space/data_local/moeller/DPZ/Projects/ProgressReportsAndPresentations/PrimateNeurobiology2018_TUE/
		SCPDirs.OutputDir = fullfile(experimentFolder, '..', 'ANALYSES', SCPDirs.CurrentShortHostName);
	otherwise
		% the default...
		SCPDirs.OutputDir = fullfile(experimentFolder, 'ANALYSES', SCPDirs.CurrentShortHostName);
end

if isempty(dir(SCPDirs.OutputDir))
	mkdir(SCPDirs.OutputDir);
end


% no time information
TmpOutBaseDir = [];
% full time resolution
TmpOutBaseDir = fullfile(SCPDirs.OutputDir, datestr(now, 'yyyymmddTHHMMSS'));
% by day
TmpOutBaseDir = fullfile(SCPDirs.OutputDir, datestr(now, 'yyyymmdd'));
% by year
TmpOutBaseDir = fullfile(SCPDirs.OutputDir, datestr(now, 'yyyy'));

TmpOutBaseDir = fullfile(SCPDirs.OutputDir, '2019');
% for DPZEvaluation2017
%TmpOutBaseDir = SCPDirs.OutputDir;


if ~isempty(project_name)
	TmpOutBaseDir = fullfile(TmpOutBaseDir, project_name);
end


Options.OutFormat = '.pdf';

% examples for development

% this is human pair number 6 for retreat2018, oxfoed 2018, sfn2018
ExperimentFileFQN_list = {...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171127/20171127T164730.A_20021.B_20022.SCP_01.sessiondir/20171127T164730.A_20021.B_20022.SCP_01.triallog.txt'), ...
	};
% these are the confederate sessions SMCurius, SMCurius,
% CuriusConfFlaffusConf
ExperimentFileFQN_list = {...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171206/20171206T141710.A_SM.B_Curius.SCP_01.sessiondir/20171206T141710.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171208/20171208T140548.A_SM.B_Curius.SCP_01.sessiondir/20171208T140548.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171211/20171211T110911.A_SM.B_Curius.SCP_01.sessiondir/20171211T110911.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171212/20171212T104819.A_SM.B_Curius.SCP_01.sessiondir/20171212T104819.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180111/20180111T130920.A_SM.B_Curius.SCP_01.sessiondir/20180111T130920.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180112/20180112T103626.A_SM.B_Curius.SCP_01.sessiondir/20180112T103626.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180118/20180118T120304.A_SM.B_Curius.SCP_01.sessiondir/20180118T120304.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180423/20180423T162330.A_SM.B_Curius.SCP_01.sessiondir/20180423T162330.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180131/20180131T155005.A_SM.B_Flaffus.SCP_01.sessiondir/20180131T155005.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180201/20180201T162341.A_SM.B_Flaffus.SCP_01.sessiondir/20180201T162341.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180202/20180202T144348.A_SM.B_Flaffus.SCP_01.sessiondir/20180202T144348.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180205/20180205T122214.A_SM.B_Flaffus.SCP_01.sessiondir/20180205T122214.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180209/20180209T145624.A_SM.B_Flaffus.SCP_01.sessiondir/20180209T145624.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180213/20180213T133932.A_SM.B_Flaffus.SCP_01.sessiondir/20180213T133932.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180214/20180214T141456.A_SM.B_Flaffus.SCP_01.sessiondir/20180214T141456.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180215/20180215T131327.A_SM.B_Flaffus.SCP_01.sessiondir/20180215T131327.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180216/20180216T140913.A_SM.B_Flaffus.SCP_01.sessiondir/20180216T140913.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180220/20180220T133215.A_SM.B_Flaffus.SCP_01.sessiondir/20180220T133215.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180221/20180221T133419.A_SM.B_Flaffus.SCP_01.sessiondir/20180221T133419.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180222/20180222T121106.A_SM.B_Flaffus.SCP_01.sessiondir/20180222T121106.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180223/20180223T143339.A_SM.B_Flaffus.SCP_01.sessiondir/20180223T143339.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180227/20180227T151756.A_SM.B_Flaffus.SCP_01.sessiondir/20180227T151756.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180228/20180228T132647.A_SM.B_Flaffus.SCP_01.sessiondir/20180228T132647.A_SM.B_Flaffus.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180418/20180418T143951.A_Flaffus.B_Curius.SCP_01.sessiondir/20180418T143951.A_Flaffus.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180419/20180419T141311.A_Flaffus.B_Curius.SCP_01.sessiondir/20180419T141311.A_Flaffus.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180424/20180424T121937.A_Flaffus.B_Curius.SCP_01.sessiondir/20180424T121937.A_Flaffus.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180425/20180425T133936.A_Flaffus.B_Curius.SCP_01.sessiondir/20180425T133936.A_Flaffus.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180426/20180426T171117.A_Flaffus.B_Curius.SCP_01.sessiondir/20180426T171117.A_Flaffus.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180427/20180427T142541.A_Flaffus.B_Curius.SCP_01.sessiondir/20180427T142541.A_Flaffus.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180427/20180427T153406.A_Flaffus.B_Curius.SCP_01.sessiondir/20180427T153406.A_Flaffus.B_Curius.SCP_01.triallog.txt'), ...
	};
% the best joint session
ExperimentFileFQN_list = {fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180419/20180419T141311.A_Flaffus.B_Curius.SCP_01.sessiondir/20180419T141311.A_Flaffus.B_Curius.SCP_01.triallog.txt')};
ExperimentFileFQN_list = {fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171121/20171121T162619.A_10018.B_20017.SCP_01.sessiondir/20171121T162619.A_10018.B_20017.SCP_01.triallog.txt')};
ExperimentFileFQN_list = [];


if isempty(ExperimentFileFQN_list)
	disp([mfilename, ': Trying to find all logfiles in ', experimentFolder]);
	experimentFile = find_all_files(experimentFolder, LogFileWildCardString, 0);
	
	if (use_triallog_witout_extension) && regexp(LogFileWildCardString, 'triallog\*$')
		% now get all files matching
		for i_exp_file = 1 : length(experimentFile)
			% canonize the extension to .triallog (handle all variations)
			experimentFile{i_exp_file} = regexprep(experimentFile{i_exp_file}, '.triallog.txt.gz$', '.triallog');
			experimentFile{i_exp_file} = regexprep(experimentFile{i_exp_file}, '.triallog.txt.Fixed.txt$', '.triallog');
			experimentFile{i_exp_file} = regexprep(experimentFile{i_exp_file}, '.triallog.txt.orig$', '.triallog');
			experimentFile{i_exp_file} = regexprep(experimentFile{i_exp_file}, '.triallog.txt$', '.triallog');
			experimentFile{i_exp_file} = regexprep(experimentFile{i_exp_file}, '.triallog.v[0-9][0-9][0-9].mat$', '.triallog');
			experimentFile{i_exp_file} = regexprep(experimentFile{i_exp_file}, '.triallog.txt.v[0-9][0-9][0-9].mat$', '.triallog');
			experimentFile{i_exp_file} = regexprep(experimentFile{i_exp_file}, '.triallog.fixed.v[0-9][0-9][0-9].mat$', '.triallog');
			%experimentFile{i_exp_file} = regexprep(experimentFile{i_exp_file}, '.triallog.broken.v013.mat$', '.triallog');
		end
		experimentFile = fnUnsortedUnique(experimentFile);	% to keep temporal ordering intact...
	end
	
	% the merge has happened, so this will just double the number of input
	% files
	%     % merge old with new (remove once all old files have been renamed)
	%     experimentFile2018 = find_all_files(experimentFolder, LogFileWildCardString2018, 0);
	%     experimentFile(end+1:end+length(experimentFile2018)) = experimentFile2018;
else
	experimentFile = ExperimentFileFQN_list;
end


% allow to ignore some sessions
%TODO fix up the parser to deal with older well-formed report files, switch
%to selective exclusion of individual days instead of whole months...

ExcludeWildCardList = {...
	'A_None.B_None', 'A_Test', 'B_Test', 'TestA', 'TestB', ...
	'Exclude.', 'exclude', '_PARKING', '_TESTVERSIONS', '.broken.', ...
	'isOwnChoice_sideChoice.mat', 'DATA_', '.statistics.txt', '.pdf', '.png', '.fig', '.ProximitySensorChanges.log', ...
	'201701', '201702', '2017030', '2017031', '20170404T163523', 'A_SM-InactiveVirusScanner', ...
	};

ExcludeWildCardList = {...
	'A_None.B_None', 'A_Test', 'B_Test', 'TestA', 'TestB', ...
	'Exclude.', 'exclude', '_PARKING', '_TESTVERSIONS', '.broken.', ...
	'isOwnChoice_sideChoice.mat', 'DATA_', '.statistics.txt', '.pdf', '.png', '.fig', '.ProximitySensorChanges.log', ...
	'201701', 'A_SM-InactiveVirusScanner', ...
	};


if ~isempty(ExcludeWildCardList)
	IncludedFilesIdx = [];
	for iFile = 1 : length(experimentFile)
		TmpIdx = [];
		for iExcludeWildCard = 1 : length(ExcludeWildCardList)
			TmpIdx = [TmpIdx, strfind(experimentFile{iFile}, ExcludeWildCardList{iExcludeWildCard})];
		end
		if isempty(TmpIdx)
			IncludedFilesIdx(end+1) = iFile;
		end
	end
	experimentFile = experimentFile(IncludedFilesIdx);
end



% allow to restrict to a set of sessions we are currently interested in
% by using wildcard (preferably the unique session IDs)
IncludeWildcardList = {};

% if strcmp(project_name, 'BoS_manuscript')
% 	% the set for the 2019 paper
% 	[~, IncludeWildcardList] = fn_get_session_group('BoS_manuscript');
% end

if (use_named_set)
	[~, IncludeWildcardList] = fn_get_session_group(set_name);
end

if ~isempty(IncludeWildcardList)
	IncludedFilesIdx = [];
	for iFile = 1 : length(experimentFile)
		TmpIdx = [];
		for iIncludeWildCard = 1 : length(IncludeWildcardList)
			TmpIdx = [TmpIdx, strfind(experimentFile{iFile}, IncludeWildcardList{iIncludeWildCard})];
		end
		
		if ~isempty(TmpIdx)
			IncludedFilesIdx(end+1) = iFile;
		end
	end
	experimentFile = experimentFile(IncludedFilesIdx);
end



nFiles = length(experimentFile);

% the newest sessions might of most interest
if (ProcessNewestFirst)
	experimentFile = experimentFile(end:-1:1);
end

if (ProcessFirstOnly)
	experimentFile = experimentFile(1);
end

out_list = {};

% make sure we always fill a fresh CoordinationSummary
CoordinationSummaryFileName = 'CoordinationSummary.txt';
CoordinationSummaryFQN = fullfile(TmpOutBaseDir, CoordinationSummaryFileName);
if ~isempty(dir(CoordinationSummaryFQN))
	delete(CoordinationSummaryFQN);
end

% test for uniqueness
% tmp2 = cell([size(experimentFile)]);
% for i_file = 1 : length(experimentFile)
%     [~, cur_name, cur_ext] = fileparts(experimentFile{i_file});
%     tmp2{i_file} = [cur_name, '.', cur_ext];
% end
% tmp3 = unique(tmp2);
%
% same_idx = strmatch(tmp3{1}, tmp2);
% tmp4 = experimentFile(same_idx)';

unique_experimentFile = unique(experimentFile);
if length(unique_experimentFile) < length(experimentFile)
	disp([mfilename, ': The experimentFile list contained ', num2str(length(experimentFile)-length(unique_experimentFile)), ' duplicates, which we will ignore']);
	experimentFile = unique_experimentFile;
end


if (RunSingleSessionAnalysis)
	for iSession = 1 : length(experimentFile)
		CurentSessionLogFQN = experimentFile{iSession};
		[current_triallog_path, current_triallog_name, current_triallog_ext] = fileparts(CurentSessionLogFQN);
		
		if (save_plots_to_sessiondir)
			cur_TmpOutBaseDir = fullfile(current_triallog_path, 'ANALYSIS');
		else
			cur_TmpOutBaseDir = TmpOutBaseDir;
		end
		
		if (copy_triallogs_to_outputdir)
			tmp_out_path = fullfile(cur_TmpOutBaseDir, 'triallogs');
			if isempty(dir(tmp_out_path))
				mkdir(tmp_out_path);
			end
			copyfile(CurentSessionLogFQN, fullfile(tmp_out_path, [current_triallog_name, current_triallog_ext]));
		end
		
		if (ProcessFreshSessionsOnly)
			% look for existence of a parsed triallog mat-file, very coarre
			
			switch fresh_definition_string
				case 'no_triallog_mat'
					% does not work for merged sessins
					[~, CurrentEventIDEReportParserVersionString] = fnParseEventIDEReportSCPv06([]);
					MatFilename = fullfile(current_triallog_path, [current_triallog_name CurrentEventIDEReportParserVersionString '.mat']);
					if (exist(MatFilename, 'file'))
						continue
					end
				case 'no_coordination_check_mat'
					% does not work for single/solo only sessions
					check_dir = fullfile(cur_TmpOutBaseDir, 'CoordinationCheck');
					check_prefix = 'DATA_';
					check_suffix = 'isOwnChoice_sideChoice.mat';
					check_dir_stat = dir(fullfile(check_dir, [check_prefix, current_triallog_name, '*', check_suffix]));
					if ~isempty(check_dir_stat)
						disp([mfilename, ': Found existing ', check_suffix,' file for ', current_triallog_name, '; assuming already processed session, skipping over.'])
						continue
					else
						disp([mfilename, ': No existing ', check_suffix,' file found for', current_triallog_name, '; assuming fresh session, processing.']);
					end
				case 'no_statistics_txt'
					check_dir = fullfile(cur_TmpOutBaseDir);
					check_prefix = '';
					check_suffix = '.statistics.txt';
					check_dir_stat = dir(fullfile(check_dir, [check_prefix, current_triallog_name, '*', check_suffix]));
					if ~isempty(check_dir_stat)
						disp([mfilename, ': Found existing ', check_suffix,' file for ', current_triallog_name, '; assuming already processed session, skipping over.'])
						continue
					else
						disp([mfilename, ': No existing ', check_suffix,' file found for', current_triallog_name, '; assuming fresh session, processing.']);
					end
			end
		end
		% only of either session is fresh or ProcessFreshSessionsOnly
		% was set to zero, otherwise we jump over this for existing
		% sessions
		
		
		out = fnAnalyseIndividualSCPSession(CurentSessionLogFQN, cur_TmpOutBaseDir, project_name);
		if ~isempty(out)
			out_list{end+1} = out;
		end
		
		% close all figue handles, as they are invisible anyway
		if (fnIsMatlabRunningInTextMode)
			close all
		end
	end
end


% collect the output from
% loop over all cells of out and create meaningful performance plots (show perf in %)
disp([mfilename, ': Saving summary as ', fullfile(SCPDirs.OutputDir, [CurrentAnalysisSetName, '.Summary.mat'])]);
save(fullfile(SCPDirs.OutputDir, [CurrentAnalysisSetName, '.Summary.mat']), 'out_list');


if strcmp(project_name, 'BoS_manuscript')
	% the set for the 2019 paper
	%fnAggregateAndPlotCoordinationMetricsByGroup([], [], [], 'BoS_manuscript');
	fnAggregateAndPlotCoordinationMetricsByGroup([], [], [], project_name);
	plot_RTdiff_correlation_BoS_hum_mac(project_name);
	run_switches_test_BoS_hum_mac(project_name)
end


% how long did it take?
timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);


return
end



function [out_list, in_list_idx] = local_fnUnsortedUnique(in_list)
% unsorted_unique auto-undo the sorting in the return values of unique
% the outlist gives the unique elements of the in_list at the relative
% position of the last occurrence in the in_list, in_list_idx gives the
% index of that position in the in_list

[sorted_unique_list, sort_idx] = unique(in_list);
[in_list_idx, unsort_idx] = sort(sort_idx);
out_list = sorted_unique_list(unsort_idx);

return
end

function [ running_in_text_mode ] = fnIsMatlabRunningInTextMode( input_args )
%FNISMATLABRUNNINGINTEXTMODE is this matlab instance running as textmode
%application
%   Detailed explanation goes here

running_in_text_mode = 0;

if (~usejava('awt'))
	running_in_text_mode = 1;
end

return
end
