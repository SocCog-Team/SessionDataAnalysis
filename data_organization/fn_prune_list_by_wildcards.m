function [ pruned_list, valid_entries_in_original_list_ldx, valid_entries_in_original_list_idx ] = fn_prune_list_by_wildcards( original_list, prune_type_string, wildcard_list, match_mode )
pruned_list = [];
valid_entries_in_original_list_ldx = logical(zeros(size(original_list)));
valid_entries_in_original_list_idx = [];

if nargin < 4 || isempty(match_mode)
	match_mode = 'strfind';
end

switch prune_type_string
	case 'exclude'
		% remove all strings that match the wildcard
		keep_matches = 0;
		disp([mfilename, ': INFO: excluding all list entries that match the wildcard_list']);
	case 'include'
		% keep only strings that match the wildcard
		keep_matches = 1;
		disp([mfilename, ': INFO: including only list entries that match the wildcard_list']);
	otherwise
		error([mfilename, ': Invalid prune operation requested: ', prune_type_string]);
end


% use wild card search strings to exclude session log files from further
% processing
% if ~isempty(wildcard_list)
% 	for iFile = 1 : length(original_list)
% 		TmpIdx = [];
% 		for i_WildCard = 1 : length(wildcard_list)
% 			% we do not care about the exact way a match is reported, only whether TmpIdx is empty or not...
% 			TmpIdx = [TmpIdx, strfind(original_list{iFile}, wildcard_list{i_WildCard})]; 
% 		end
% 
% 		if (keep_matches)
% 			if ~isempty(TmpIdx)
% 				valid_entries_in_original_list_idx(end+1) = iFile;
% 			end
% 		else
% 			if isempty(TmpIdx)
% 				valid_entries_in_original_list_idx(end+1) = iFile;
% 			end
% 		end
% 	end
% 	pruned_list = original_list(valid_entries_in_original_list_idx);
% end

if ~isempty(wildcard_list)
	for iFile = 1 : length(original_list)
		is_match = false;
		for i_WildCard = 1 : length(wildcard_list)
			cur_pat = wildcard_list{i_WildCard};
			switch lower(match_mode)
				case 'strfind'
					is_match = ~isempty(strfind(original_list{iFile}, cur_pat)); %#ok<STREMP>
				case 'regexp'
					is_match = ~isempty(regexp(original_list{iFile}, cur_pat, 'once'));
				otherwise
					error([mfilename, ': match_mode must be ''strfind'' or ''regexp''']);
			end
			if is_match, break; end
		end

		if (keep_matches && is_match) || (~keep_matches && ~is_match)
			valid_entries_in_original_list_idx(end+1) = iFile; %#ok<AGROW>
		end
	end
	pruned_list = original_list(valid_entries_in_original_list_idx);
end

valid_entries_in_original_list_ldx(valid_entries_in_original_list_idx) = 1;
end

