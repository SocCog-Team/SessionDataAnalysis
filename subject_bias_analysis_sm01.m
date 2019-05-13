function [] = subject_bias_analysis_sm01()
clear variables;

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);

copy_triallogs_to_outputdir = 0;


ProcessNewestFirst = 1;
ProcessFirstOnly = 1;
RunSingleSessionAnalysis = 1;


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
override_directive = 'local_code';
override_directive = 'local';

SCPDirs = GetDirectoriesByHostName(override_directive);
LogFileWildCardString2018 = '*.triallog.txt';   % new file extension to allow better wildcarding and better typing

switch CurrentAnalysisSetName
	
	case {'PrimateNeurobiology2018DPZ'}
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP_DATA');
		% to speed things up collect the selected sessuins triallog files
		experimentFolder = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'Projects', 'ProgressReportsAndPresentations', 'PrimateNeurobiology2018_TUE', 'ANALYSES', 'UsedTriallogFiles');
		LogFileWildCardString = '*.triallog.txt';
		
	case {'SCP_DATA', 'SCP_DATA_SFN2018'}
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS');
		experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP_DATA');
		LogFileWildCardString = '*.triallog.txt';
		
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
	otherwise
		% the default...
		SCPDirs.OutputDir = fullfile(experimentFolder, 'ANALYSES', SCPDirs.CurrentShortHostName);
end

% no time information
TmpOutBaseDir = [];
% full time resolution
TmpOutBaseDir = fullfile(SCPDirs.OutputDir, datestr(now, 'yyyymmddTHHMMSS'));
% by day
TmpOutBaseDir = fullfile(SCPDirs.OutputDir, datestr(now, 'yyyymmdd'));
% by year
TmpOutBaseDir = fullfile(SCPDirs.OutputDir, datestr(now, 'yyyy'));
% for DPZEvaluation2017
%TmpOutBaseDir = SCPDirs.OutputDir;




Options.OutFormat = '.pdf';

% examples for development
% DAG_VERTICALCHOICE DirectFreeGazeReaches, no dual target trials
ExperimentFileFQN_list = {fullfile(experimentFolder, '20170531/20170531T145722.A_Magnus.B_None.SCP_01/20170531T145722.A_Magnus.B_None.SCP_01.log')};
% DAG_VERTICALCHOICE DirectFreeGazeFreeChoice
ExperimentFileFQN_list = {fullfile(experimentFolder, '20170602/20170602T151337.A_Magnus.B_None.SCP_01/20170602T151337.A_Magnus.B_None.SCP_01.log')};

ExperimentFileFQN_list = {fullfile(experimentFolder, '20171019/20171019T132932.A_Flaffus.B_Curius.SCP_01/20171019T132932.A_Flaffus.B_Curius.SCP_01.log')};

ExperimentFileFQN_list = {...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171215/20171215T122633.A_SM.B_Curius.SCP_01.sessiondir/20171215T122633.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171221/20171221T135010.A_SM.B_Curius.SCP_01.sessiondir/20171221T135010.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171222/20171222T104137.A_SM.B_Curius.SCP_01.sessiondir/20171222T104137.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	};

ExperimentFileFQN_list = {...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171215/20171215T122633.A_SM.B_Curius.SCP_01.sessiondir/20180420T142213.A_TN.B_SM.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180420/20180420T142213.A_TN.B_SM.SCP_01.sessiondir/20180420T142213.A_TN.B_SM.SCP_01.triallog.txt'), ...
	};

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


% testing for visibility block data:
ExperimentFileFQN_list = {fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180309/20180309T110024.A_SM.B_Flaffus.SCP_01.sessiondir/20180309T110024.A_SM.B_Flaffus.SCP_01.triallog.txt')};

% the best joint session
ExperimentFileFQN_list = {fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180419/20180419T141311.A_Flaffus.B_Curius.SCP_01.sessiondir/20180419T141311.A_Flaffus.B_Curius.SCP_01.triallog.txt')};

ExperimentFileFQN_list = {fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171121/20171121T162619.A_10018.B_20017.SCP_01.sessiondir/20171121T162619.A_10018.B_20017.SCP_01.triallog.txt')};


ExperimentFileFQN_list = [];
%ExperimentFileFQN_list = {'/space/data_local/moeller/DPZ/taskcontroller/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2018/180420/20180420T192826.A_SM.B_52005.SCP_01.sessiondir/20180420T192826.A_SM.B_52005.SCP_01.triallog.txt'};

if isempty(ExperimentFileFQN_list)
	disp(['Trying to find all logfiles in ', experimentFolder]);
	experimentFile = find_all_files(experimentFolder, LogFileWildCardString, 0);
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
ExcludeWildCardList = {'_TESTVERSIONS', '20170106', '201701', '201702', '201703', 'A_SM-InactiveVirusScanner', 'A_Test', 'TestA', 'TestB', 'B_Test'};
ExcludeWildCardList = {'ANALYSES', '201701', '201702', '201703', '20170403', '20170404', '20170405', '20170406', 'A_SM-InactiveVirusScanner', 'A_Test', 'TestA', 'TestB', 'B_Test', '_PARKING', '_TESTVERSIONS'};
ExcludeWildCardList = {'ANALYSES', '201701', '201702', '2017030', '2017031', '20170404T163523', 'A_SM-InactiveVirusScanner', 'A_Test', 'TestA', 'TestB', 'B_Test', '_PARKING', '_TESTVERSIONS'};

ExcludeWildCardList = {'Exclude.', '201701', '201702', '2017030', '2017031', '20170404T163523', 'A_SM-InactiveVirusScanner', 'A_Test', 'TestA', 'TestB', 'B_Test', '_PARKING', '_TESTVERSIONS'};

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
delete(CoordinationSummaryFQN);

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
	disp(['The experimentFile list contained ', num2str(length(experimentFile)-length(unique_experimentFile)), ' duplicates, which we will ignore']);
	experimentFile = unique_experimentFile;
end


if (RunSingleSessionAnalysis)
	for iSession = 1 : length(experimentFile)
		CurentSessionLogFQN = experimentFile{iSession};
		
		if (copy_triallogs_to_outputdir)
			[~, current_name, current_ext] = fileparts(CurentSessionLogFQN);
			tmp_out_path = fullfile(TmpOutBaseDir, 'triallogs');
			if isempty(dir(tmp_out_path)),
				mkdir(tmp_out_path);
			end
			copyfile(CurentSessionLogFQN, fullfile(tmp_out_path, [current_name, current_ext]));
		end
		
		out = fnAnalyseIndividualSCPSession(CurentSessionLogFQN, TmpOutBaseDir);
		if ~isempty(out)
			out_list{end+1} = out;
		end
	end
end

% collect the output from
% loop over all cells of out and create meaningful performance plots (show perf in %)
disp(['Saving summary as ', fullfile(SCPDirs.OutputDir, [CurrentAnalysisSetName, '.Summary.mat'])]);
save(fullfile(SCPDirs.OutputDir, [CurrentAnalysisSetName, '.Summary.mat']), 'out_list');



% how long did it take?
timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);


return
end

