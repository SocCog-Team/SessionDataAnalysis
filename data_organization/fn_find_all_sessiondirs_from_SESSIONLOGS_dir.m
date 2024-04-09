function [ triallog_fqn_list, sessiondir_fqn_list, sessiondir_has_TDT_data_ldx, session_id_list ] = fn_find_all_sessiondirs_from_SESSIONLOGS_dir( SESSIONLOGS_dir, log_file_wildcard_string, TDT_tankdir_wildcard_string )
%FN_FIND_ALL_SESSIONDIRS_FROM_SESSIONLOGS_DIR Summary of this function goes here
%   Detailed explanation goes here
triallog_fqn_list = {};
sessiondir_has_TDT_data_ldx = [];
sessiondir_fqn_list = {};
session_id_list = {};

sessiondir_has_TDT_data_idx = [];
EPHYS_data_subdir_name = 'TDT';

if ~exist('TDT_tankdir_wildcard_string', 'var') || isempty(TDT_tankdir_wildcard_string)
	TDT_tankdir_wildcard_string = 'SCP_*'; % starting with SCP, will exclude e.g. EXCLUDE>SCP*, exclude.SCP_*, ...
end



[SESSIONLOGS_dir_path, SESSIONLOGS_dir_name, SESSIONLOGS_dir_ext] = fileparts(SESSIONLOGS_dir);


if strcmp(SESSIONLOGS_dir_name, 'SESSIONLOGS')
	year_level_dirstruct = dir(fullfile(SESSIONLOGS_dir, '20??'));
	for i_year = 1 : length(year_level_dirstruct)
		cur_year_name = year_level_dirstruct(i_year).name;
		disp([mfilename, ': Searching year ', cur_year_name]);
		% non numbers convert to NaNs...
		if ~isnan(str2double(cur_year_name)) && year_level_dirstruct(i_year).isdir
			YYMMDD_level_dirstruct = dir(fullfile(SESSIONLOGS_dir, cur_year_name, '??????'));
			for i_YYMMDD = 1 : length(YYMMDD_level_dirstruct)
				cur_YYMMDD = YYMMDD_level_dirstruct(i_YYMMDD).name;
				if ~isnan(str2double(cur_YYMMDD)) && YYMMDD_level_dirstruct(i_YYMMDD).isdir
					sessiondir_level_dirstruct = dir(fullfile(SESSIONLOGS_dir, cur_year_name, cur_YYMMDD, [cur_year_name(1:2), cur_YYMMDD, 'T?????*.A_*.B_*.SCP_??.sessiondir']));
					for i_sessiondir = 1 : length(sessiondir_level_dirstruct)
						cur_sessiondir = sessiondir_level_dirstruct(i_sessiondir).name;
						if (sessiondir_level_dirstruct(i_sessiondir).isdir)
							% check whether TDT data exists
							% if (nargout > 1)
							sessiondir_fqn_list(end+1) = {fullfile(SESSIONLOGS_dir, cur_year_name, cur_YYMMDD, cur_sessiondir)};
							% end
							% if (nargout > 2)
							EPHYSdir_fqn = fullfile(SESSIONLOGS_dir, cur_year_name, cur_YYMMDD, cur_sessiondir, EPHYS_data_subdir_name);
							if isdir(EPHYSdir_fqn)
								% find the tankdirs
								tankdir_dirstruct = dir(fullfile(EPHYSdir_fqn, TDT_tankdir_wildcard_string));
								if length(tankdir_dirstruct) > 1
									disp([mfilename, ': WARN: Found more than one not-excluded tank subdirectory, picking the first...']);
								end
								if ~isempty(tankdir_dirstruct) && tankdir_dirstruct(1).isdir
									%cur_tankdir_fqn = fullfile(EPHYSdir_fqn, tankdir_dirstruct(1).name);
									sessiondir_has_TDT_data_idx = length(sessiondir_fqn_list);
								end
							end
							% end
							% if (nargout > 3)
							[~, cur_session_id, ~] = fileparts(cur_sessiondir);
							session_id_list(end+1) = {cur_session_id};
							% end

							triallog_dirstruct = dir(fullfile(SESSIONLOGS_dir, cur_year_name, cur_YYMMDD, cur_sessiondir, [cur_year_name(1:2), cur_YYMMDD, 'T?????*.A_*.B_*.SCP_??', log_file_wildcard_string]));
							% now convert the dirstruct into a
							% list of triallog names
							for i_triallog = 1 : length(triallog_dirstruct)
								if ~triallog_dirstruct(i_triallog).isdir
									triallog_fqn_list(end+1) = {fullfile(triallog_dirstruct(i_triallog).folder, triallog_dirstruct(i_triallog).name)};
								end
							end
						end
					end % i_sessiondir
				end
			end % i_YYMMDD
		end
	end % i_year

	% if (nargout > 2)
	% convert session_has_TDT_data_idx to session_has_TDT_data_ldx
	sessiondir_has_TDT_data_ldx = logical(zeros(size(sessiondir_fqn_list)));
	sessiondir_has_TDT_data_ldx(sessiondir_has_TDT_data_idx) = 1;
	% end
else
	error([mfilename, ': SESSIONLOGS_dir does not end in SESSIONLOGS, so search_triallog_method use_SCP_structure is not applicable...']);
end

end

