function [] = subject_bias_analysis_sm03(ProcessFirstOnly)
% this is intended to be a cleaned-up version of subject_bias_analysis_sm01
% TODO:
%	export a list of all sessiondirs, export a list of all sessiondirs that
%	contain a TDT folder (proto ephys sessions...)


timestamps.(mfilename).start = tic;
disp([mfilename, ': Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);


% use either local data and code (local) or remote data and local_code (local_code)
override_directive = 'local_code'; % local, local_code, remote

% whether to only only process the first session in the list
if  ~exist('ProcessFirstOnly', 'var')
	% manual override
	ProcessFirstOnly = 1;
	ProcessNewestFirst = 1;	% this way we only process the most recent session
else
	disp([mfilename, ': ProcessFirstOnly from caller: ', num2str(ProcessFirstOnly)]);
end

ProcessNewestFirst = 0;	% sort order, natural order is oldest first
copy_triallogs_to_outputdir = 0;				%
RunSingleSessionAnalysis = 1;					% actually do the work...
ProcessFreshSessionsOnly = 0;					% only process sessions without signs of being already analysed
fresh_definition_string = 'no_statistics_txt';	% which method to use to detect whether a session is already analysed
session_group_name = '';						% a name to be defenied in fn_get_session_group as part of the include list
project_name = [];								% this string will be appended to the OutputDir as subdirectory and passed to group analysis scripts
search_triallog_method = 'use_SCP_structure';	% find_all_files: slow but cpmprehensive will create the full directoty tree, use_SCP_structure: exploit the way SCP01 organizes its data

save_data_to_sessiondir = 0;							% either collect plots in a big output directory or inside each session directory
session_info_name_stem = 'All_session_summary_table';	% how to name the big session information file
session_info_save_table = 1;							% write out a table that collects information about each session
session_info_type = 'default';							% what form to export the per session information into
session_info_incremental_update = 0;					% only extract session_info for unprocessed sessions, otherwise re-extract all sessions.


project_name = [];								%'BoS_manuscript', 'ephys', 'SfN2018'
project_name = 'BoS_manuscript';
project_name = 'ephys'; % this is the default
project_name = 'SfN2018'; % or SfN2008 this loops back to 2019
project_name = 'per_session_information';

% allow to ignore some sessions
%TODO fix up the parser to deal with older well-formed report files, switch
%to selective exclusion of individual days instead of whole months...
% this will operate before IncludeWildcardList
ExcludeWildCardList = {...
	'A_None.B_None', 'A_Test', 'B_Test', 'TestA', 'TestB', ...
	'Exclude.', 'exclude', '_PARKING', '_TESTVERSIONS', '.broken.', 'bak.', '.EXCLUDE', ...
	'isOwnChoice_sideChoice.mat', 'DATA_', '.statistics.txt', '.pdf', '.png', '.fig', '.ProximitySensorChanges.log', ...
	'201701', '20170201', 'A_SM-InactiveVirusScanner', ... % these might be recoverable...
	};

% detect all valid and analysable triallog variants
valid_triallog_suffix_regexp_list = {'.triallog.txt.gz$', '.triallog.txt.Fixed.txt$', '.triallog.txt.orig$', '.triallog.txt$', ...
	'.triallog.v[0-9][0-9][0-9].mat$', '.triallog.txt.v[0-9][0-9][0-9].mat$', '.triallog.fixed.v[0-9][0-9][0-9].mat$', ...
	};
% exclude all proto triallog files that do not match the suffix list above
ignore_invalid_triallog_suffixes = 1;


% allow to restrict to a set of sessions we are currently interested in
% by using wildcard (preferably the unique session IDs)
IncludeWildcardList = {};

% special case for the paper set
if strcmp(project_name, 'BoS_manuscript')
	ProcessFreshSessionsOnly = 0;
	session_group_name = 'BoS_manuscript';
	%fresh_definition_string = 'no_statistics_txt';
	fresh_definition_string = 'no_coordination_check_mat';
end

% special case for exporting per session aggregate information
if strcmp(project_name, 'per_session_information')
	ProcessFirstOnly = 0;
	ProcessFreshSessionsOnly = 0;
	RunSingleSessionAnalysis = 0;
	session_group_name = '';
end



% from the linux VM
test_text_mode = 1;
if (fnIsMatlabRunningInTextMode) || test_text_mode
	session_group_name = '';
	save_data_to_sessiondir = 1;
	override_directive = 'local_code';
	project_name = 'SfN2008';
	%project_name = [];
	fresh_definition_string = 'no_statistics_txt';
	ProcessFirstOnly = 0;
	ProcessNewestFirst = 1;
	ProcessFreshSessionsOnly = 1;
	session_info_save_table = 1;
	RunSingleSessionAnalysis = 1;					% actually do the work...
end


% this allows to select configuration sets
CurrentAnalysisSetName = 'SCP_DATA';

% get the directories for this host
SCPDirs = GetDirectoriesByHostName(override_directive);
% triiallog files exist in multiple variants with this set the code tries
% to automatically pick the most processed version
use_triallog_without_extension = 1;
analysis_instance_id_string = '';% or fullfile(SCPDirs.OutputDir, datestr(now, 'yyyymmddTHHMMSS'))
switch CurrentAnalysisSetName
	case {'SCP_DATA'}
		[tmp_dir, tmp_name] = fileparts(SCPDirs.SCP_DATA_BaseDir);
		if strcmp(tmp_name, 'SCP_DATA')
			experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP-CTRL-01', 'SESSIONLOGS'); % avoid the analysis folder with its looped sym links
		end
		SCPDirs.OutputDir = fullfile(experimentFolder, '..', '..', 'ANALYSES', SCPDirs.CurrentShortHostName);
		analysis_instance_id_string = '';% or fullfile(SCPDirs.OutputDir, datestr(now, 'yyyymmddTHHMMSS'))
		% what wildcard string to search for
		LogFileWildCardString = '*.triallog*';	% '*.triallog.txt'
		use_triallog_without_extension = 1;
	otherwise
		% the default...
		%SCPDirs.OutputDir = fullfile(experimentFolder, 'ANALYSES', SCPDirs.CurrentShortHostName);
		error(['Encountered yet unhandled CurrentAnalysisSetName ', num2str(CurrentAnalysisSetName), ' stopping.']);
end
cur_output_base_dir = SCPDirs.OutputDir;
% make sure to create the folder we want to write to...
if ~isempty(analysis_instance_id_string)
	cur_output_base_dir = fullfile(cur_output_base_dir, analysis_instance_id_string);
end
if ~isempty(project_name)
	cur_output_base_dir = fullfile(cur_output_base_dir, project_name);
end
if isempty(dir(cur_output_base_dir))
	mkdir(cur_output_base_dir);
end

% examples for development
% this is human pair number 6 for retreat2018, oxford 2018, sfn2018
ExperimentFileFQN_list = {...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2017/171127/20171127T164730.A_20021.B_20022.SCP_01.sessiondir/20171127T164730.A_20021.B_20022.SCP_01.triallog.txt'), ...
	};
% these are some  confederate sessions SMCurius, SMCurius,
% CuriusConfFlaffusConf
ExperimentFileFQN_list = {...
	fullfile(experimentFolder, '/2017/171206/20171206T141710.A_SM.B_Curius.SCP_01.sessiondir/20171206T141710.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, '/2017/171208/20171208T140548.A_SM.B_Curius.SCP_01.sessiondir/20171208T140548.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, '/2017/171211/20171211T110911.A_SM.B_Curius.SCP_01.sessiondir/20171211T110911.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, '/2017/171212/20171212T104819.A_SM.B_Curius.SCP_01.sessiondir/20171212T104819.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180111/20180111T130920.A_SM.B_Curius.SCP_01.sessiondir/20180111T130920.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180112/20180112T103626.A_SM.B_Curius.SCP_01.sessiondir/20180112T103626.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180118/20180118T120304.A_SM.B_Curius.SCP_01.sessiondir/20180118T120304.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	fullfile(experimentFolder, 'SCP-CTRL-01/SESSIONLOGS/2018/180423/20180423T162330.A_SM.B_Curius.SCP_01.sessiondir/20180423T162330.A_SM.B_Curius.SCP_01.triallog.txt'), ...
	};
% the best joint session
ExperimentFileFQN_list = {fullfile(experimentFolder, '/2018/180419/20180419T141311.A_Flaffus.B_Curius.SCP_01.sessiondir/20180419T141311.A_Flaffus.B_Curius.SCP_01.triallog.txt')};
ExperimentFileFQN_list = {fullfile(experimentFolder, '/2017/171121/20171121T162619.A_10018.B_20017.SCP_01.sessiondir/20171121T162619.A_10018.B_20017.SCP_01.triallog.txt')};
% Jump over the examples and start clean
ExperimentFileFQN_list = [];

% example with ePhys data
%ExperimentFileFQN_list = {fullfile(experimentFolder, '/2020/201117/20201117T135345.A_Elmo.B_None.SCP_01.sessiondir/20201117T135345.A_Elmo.B_None.SCP_01.triallog.txt')};
%ExperimentFileFQN_list = {'Y:\SCP_DATA\SCP-CTRL-01\SESSIONLOGS\2020\200624\20200624T000001M.A_Elmo.B_None.SCP_01.sessiondir\20200624T000001M.A_Elmo.B_None.SCP_01.triallog'};
%ExperimentFileFQN_list = {'Y:\SCP_DATA\SCP-CTRL-01\SESSIONLOGS\2023\230525\20230525T103049.A_Curius.B_SM.SCP_01.sessiondir\20230525T103049.A_Curius.B_SM.SCP_01.triallog'};
% ExperimentFileFQN_list = {'Y:\SCP_DATA\SCP-CTRL-01\SESSIONLOGS\2023\230707\20230707T102457.A_Curius.B_Elmo.SCP_01.sessiondir\20230707T102457.A_Curius.B_Elmo.SCP_01.triallog'};
%20230707T102457.A_Curius.B_Elmo.SCP_01.triallog


timestamps.search_triallog.start = tic;
tic
if isempty(ExperimentFileFQN_list)
	disp([mfilename, ': Trying to find all logfiles (method ', search_triallog_method,') in ', experimentFolder]);
	switch search_triallog_method
		case 'find_all_files'	
			experimentFile = find_all_files(experimentFolder, LogFileWildCardString, 0);
		case 'use_SCP_structure'

			[experimentFile, sessiondir_fqn_list, sessiondir_has_TDT_data_ldx, session_id_list] = fn_find_all_sessiondirs_from_SESSIONLOGS_dir(experimentFolder, LogFileWildCardString);

			% if ~isempty(regexp(experimentFolder, 'SESSIONLOGS'))
			% 	experimentFile = {};
			% 	year_level_dirstruct = dir(fullfile(experimentFolder, '20??'));
			% 	for i_year = 1 : length(year_level_dirstruct)
				% 	cur_year_name = year_level_dirstruct(i_year).name;
				% 	disp([mfilename, ': Searching year ', cur_year_name]);
				% 	% non numbers convert to NaNs...
				% 	if ~isnan(str2double(cur_year_name)) && year_level_dirstruct(i_year).isdir
					% 	YYMMDD_level_dirstruct = dir(fullfile(experimentFolder, cur_year_name, '??????'));
					% 	for i_YYMMDD = 1 : length(YYMMDD_level_dirstruct)
						% 	cur_YYMMDD = YYMMDD_level_dirstruct(i_YYMMDD).name;
						% 	if ~isnan(str2double(cur_YYMMDD)) && YYMMDD_level_dirstruct(i_YYMMDD).isdir
							% 	sessiondir_level_dirstruct = dir(fullfile(experimentFolder, cur_year_name, cur_YYMMDD, [cur_year_name(1:2), cur_YYMMDD, 'T?????*.A_*.B_*.SCP_??.sessiondir']));
							% 	for i_sessiondir = 1 : length(sessiondir_level_dirstruct)
								% 	cur_sessiondir = sessiondir_level_dirstruct(i_sessiondir).name;
								% 	if (sessiondir_level_dirstruct(i_sessiondir).isdir)
									% 	triallog_dirstruct = dir(fullfile(experimentFolder, cur_year_name, cur_YYMMDD, cur_sessiondir, [cur_year_name(1:2), cur_YYMMDD, 'T?????*.A_*.B_*.SCP_??', LogFileWildCardString]));
									% 	% now convert the dirstruct into a
									% 	% list of triallog names
									% 	for i_triallog = 1 : length(triallog_dirstruct)
										% 	if ~triallog_dirstruct(i_triallog).isdir
											% 	experimentFile(end+1) = {fullfile(triallog_dirstruct(i_triallog).folder, triallog_dirstruct(i_triallog).name)};
										% 	end
									% 	end
								% 	end
							% 	end % i_sessiondir
						% 	end
					% 	end % i_YYMMDD
				% 	end
			% 	end % i_year
			% else
			% 	error([mfilename, ': experimentFolder does not end in SESSIONLOGS, so search_triallog_method use_SCP_structure is not applicable...']);
			% end

		otherwise
			error([mfilename, ': unhandled search_triallog_method encountered, fix invocation or implement...']);
	end % switch search_triallog_method

	if (ignore_invalid_triallog_suffixes) || ( (use_triallog_without_extension) && regexp(LogFileWildCardString, 'triallog\*$'))
		for i_exp_file = 1 : length(experimentFile)
			cur_experimentFile = experimentFile{i_exp_file};
			is_match_counter = 0;
			for i_valid_suffix = 1 : length(valid_triallog_suffix_regexp_list)
				cur_valid_suffix_regexp = valid_triallog_suffix_regexp_list{i_valid_suffix};
				% does the pattern match
				if ~isempty(regexp(cur_experimentFile, cur_valid_suffix_regexp))
					is_match_counter = is_match_counter + 1;

					% only change this if requested
					if  (use_triallog_without_extension) && regexp(LogFileWildCardString, 'triallog\*$')
						experimentFile{i_exp_file} = regexprep(experimentFile{i_exp_file}, cur_valid_suffix_regexp, '.triallog');
					end
				end
			end
			if (is_match_counter == 0)
				% does not match so make sure we exclude this by
				% temporarily giving it the EXCLUDE suffix
				experimentFile{i_exp_file} = [experimentFile{i_exp_file}, '.EXCLUDE'];
			end
		end
		% we likely accumulated duplicates while reducing the extension to
		% .triallog,so get rid of the duplicates, while keeping the order
		% intact
		%experimentFile1 = fnUnsortedUnique(experimentFile);	% to keep temporal ordering intact...
		experimentFile = unique(experimentFile, 'stable');	% to keep temporal ordering intact...
		%isequal(experimentFile1, experimentFile2)
	end
else
	experimentFile = ExperimentFileFQN_list;
end

timestamps.search_triallog.end = toc(timestamps.search_triallog.start);
disp([mfilename, ' finding triallogs took: ', num2str(timestamps.search_triallog.end), ' seconds.']);
disp([mfilename, ' finding triallogs took: ', num2str(timestamps.search_triallog.end / 60), ' minutes. Done...']);toc

% use wild card search strings to exclude session log files from further
% processing
if ~isempty(ExcludeWildCardList)
	experimentFile = fn_prune_list_by_wildcards(experimentFile, 'exclude', ExcludeWildCardList);
end
% if ~isempty(ExcludeWildCardList)
% 	IncludedFilesIdx = [];
% 	for iFile = 1 : length(experimentFile)
% 		TmpIdx = [];
% 		for iExcludeWildCard = 1 : length(ExcludeWildCardList)
% 			TmpIdx = [TmpIdx, strfind(experimentFile{iFile}, ExcludeWildCardList{iExcludeWildCard})];
% 		end
% 		if isempty(TmpIdx)
% 			IncludedFilesIdx(end+1) = iFile;
% 		end
% 	end
% 	experimentFile = experimentFile(IncludedFilesIdx);
% end


% if specified include a named session_group
if ~isempty(session_group_name)
	[~, IncludeWildcardList] = fn_get_session_group(session_group_name);
end
% this will only leave files in experimentFile that contain
% IncludeWildcardList substrings


if ~isempty(IncludeWildcardList)
	experimentFile = fn_prune_list_by_wildcards(experimentFile, 'include', IncludeWildcardList);
end
% if ~isempty(IncludeWildcardList)
% 	IncludedFilesIdx = [];
% 	for iFile = 1 : length(experimentFile)
% 		TmpIdx = [];
% 		for iIncludeWildCard = 1 : length(IncludeWildcardList)
% 			TmpIdx = [TmpIdx, strfind(experimentFile{iFile}, IncludeWildcardList{iIncludeWildCard})];
% 		end
% 
% 		if ~isempty(TmpIdx)
% 			IncludedFilesIdx(end+1) = iFile;
% 		end
% 	end
% 	experimentFile = experimentFile(IncludedFilesIdx);
% end

% the newest sessions might of most interest
if (ProcessNewestFirst)
	experimentFile = experimentFile(end:-1:1);
end
% together with ProcessNewestFirst and ProcessFirstOnly we can initiate a quick
% analysis of the latest session, without needing any marker whether a
% session has been processed already
if (ProcessFirstOnly)
	experimentFile = experimentFile(1);
end

% make sure we always fill a fresh CoordinationSummary
CoordinationSummaryFileName = 'CoordinationSummary.txt';
CoordinationSummaryFQN = fullfile(cur_output_base_dir, CoordinationSummaryFileName);
if ~isempty(dir(CoordinationSummaryFQN))
	delete(CoordinationSummaryFQN);
end

% enforce uniqueness of sessions to avoid busy work
unique_experimentFile = unique(experimentFile);
if length(unique_experimentFile) < length(experimentFile)
	disp([mfilename, ': The experimentFile list contained ', num2str(length(experimentFile)-length(unique_experimentFile)), ' duplicates, which we will ignore']);
	experimentFile = unique_experimentFile;
end

% % testing
% experimentFile = {'Y:\SCP_DATA\SCP-CTRL-01\SESSIONLOGS\2023\230208\20230208T133605.A_Curius.B_SM.SCP_01.sessiondir\ANALYSIS\20230208T133605.A_Curius.B_SM.SCP_01.triallog.A.Curius.B.SM_IC_Dyadic.MutualInformation.pdf'};

% now loop over the sessions/triallogs
out_list = {};
for iSession = 1 : length(experimentFile)
	CurentSessionLogFQN = experimentFile{iSession};
	[current_triallog_path, current_triallog_name, current_triallog_ext] = fileparts(CurentSessionLogFQN);

	% long term we might want to store anlyses always to the sesssiondir
	% and collect relevant files from there...
	if (save_data_to_sessiondir)
		cur_cur_output_base_dir = fullfile(current_triallog_path, 'ANALYSIS');
	else
		cur_cur_output_base_dir = cur_output_base_dir;
	end

	if (copy_triallogs_to_outputdir)
		tmp_out_path = fullfile(cur_cur_output_base_dir, 'triallogs');
		if isempty(dir(tmp_out_path))
			mkdir(tmp_out_path);
		end
		copyfile(CurentSessionLogFQN, fullfile(tmp_out_path, [current_triallog_name, current_triallog_ext]));
	end

	skip_this_session = 0;
	if (ProcessFreshSessionsOnly)
		% look for existence of a parsed triallog mat-file, very coarre

		switch fresh_definition_string
			case 'no_triallog_mat'
				% does not work for merged sessions
				[~, CurrentEventIDEReportParserVersionString] = fnParseEventIDEReportSCPv06([]);
				MatFilename = fullfile(current_triallog_path, [current_triallog_name CurrentEventIDEReportParserVersionString '.mat']);
				if (exist(MatFilename, 'file'))
					skip_this_session = 1;
				end
			case 'no_coordination_check_mat'
				% does not work for single/solo only sessions
				check_dir = fullfile(cur_cur_output_base_dir, 'CoordinationCheck');
				check_prefix = 'DATA_';
				check_suffix = 'isOwnChoice_sideChoice.mat';
				check_dir_stat = dir(fullfile(check_dir, [check_prefix, current_triallog_name, '*', check_suffix]));
				if ~isempty(check_dir_stat)
					skip_this_session = 1;
				end
			case 'no_statistics_txt'
				check_dir = fullfile(cur_cur_output_base_dir);
				check_prefix = '';
				check_suffix = '.statistics.txt';
				check_dir_stat = dir(fullfile(check_dir, [check_prefix, current_triallog_name, '*', check_suffix]));
				if ~isempty(check_dir_stat)
					skip_this_session = 1;
				end
		end
	end
	% only if either session is fresh or ProcessFreshSessionsOnly
	% was set to zero, otherwise we jump over this for existing
	% sessions

	if ((skip_this_session) && ~(session_info_incremental_update)) ...% we do not want to analyse the session, but still re-export the session_info
			|| (~(skip_this_session) && (session_info_incremental_update))

		% store aggregate information into a table/database
		if (session_info_save_table)
			[session_info_struct, session_info_struct_version]  = fn_collect_and_store_per_session_information(CurentSessionLogFQN, cur_cur_output_base_dir, session_info_type);
			if ~isempty(session_info_struct)
				if ~exist('session_info_struct_array', 'var')
					session_info_struct_array = session_info_struct;
				else
					session_info_struct_array = [session_info_struct_array, session_info_struct]; % 74 fields
				end
			end
		end
	end

	if (skip_this_session)
		disp([mfilename, ': Found existing ', check_suffix,' file for ', current_triallog_name, '; assuming already processed session, skipping over.'])
		continue
	else
		disp([mfilename, ': No existing ', check_suffix,' file found for', current_triallog_name, '; assuming fresh session, processing.']);
	end

	% perform actual time consuming analysis
	if (RunSingleSessionAnalysis)
		out = fnAnalyseIndividualSCPSession(CurentSessionLogFQN, cur_cur_output_base_dir, project_name, override_directive);
		if ~isempty(out)
			out_list{end+1} = out;
		end

		% close all figue handles, as they are invisible anyway
		if (fnIsMatlabRunningInTextMode)
			close all
		end
	end
end

% TODO export selected version with ephys results
if exist('session_info_struct_array', 'var')
	% now save the session_info_struct_array out
	all_session_info_table_FQN = fullfile(experimentFolder, [session_info_name_stem, '.V', num2str(session_info_struct_version, '%03d'), '.mat']);
	session_info_data_table = fn_update_session_info_table(all_session_info_table_FQN, session_info_struct_array, 'sort_key_string');
else
	disp('No data extracted in session_info_struct_array, nothing to add to table...');
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
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / (60 * 60)), ' hours. Done...']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / (60 * 60 * 24)), ' days. Done...']);


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
