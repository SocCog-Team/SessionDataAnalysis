function [] = fn_collect_and_store_per_session_information( cur_session_logfile_fqn,  cur_cur_output_base_dir, config_name )
%FN_COLLECT_AND_STORE_PER_SESSION_INFORMATION extract information for
%individual sessions and store them into a big table
%   Collect information about sessions about number of trials per trial sub
%   type, number of sucessful trials, number aborted trials agent ID
%	save as CSV and as excel table



[cur_session_logfile_path, cur_session_logfile_name, cur_session_logfile_ext] = fileparts(cur_session_logfile_fqn);


if ~exist(cur_cur_output_base_dir, 'var') || isempty(cur_cur_output_base_dir)
	cur_cur_output_base_dir = fullfile(cur_session_logfile_path, 'ANALYSIS');
end

if ~exist(config_name, 'var') || isempty(config_name)
	config_name = 'default';
end

switch lower(config_name)
	case {'default'}

	otherwise
		error(['Unkown config_name requested: ', config_name, ', FIX ME.']);
end



% save out the output as semicolon=separated-values and as excel worksheet

return
end

