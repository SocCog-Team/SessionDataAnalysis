function [ pruned_list, valid_entries_in_original_list_ldx, valid_entries_in_original_list_idx ] = fn_prune_list_by_wildcards( original_list, prune_type_string, wildcard_list )
pruned_list = [];
valid_entries_in_original_list_ldx = logical(zeros(size(original_list)));
valid_entries_in_original_list_idx = [];


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
if ~isempty(wildcard_list)
	for iFile = 1 : length(original_list)
		TmpIdx = [];
		for i_WildCard = 1 : length(wildcard_list)
			% we do not care about the exact way a match is reported, only whether TmpIdx is empty or not...
			TmpIdx = [TmpIdx, strfind(original_list{iFile}, wildcard_list{i_WildCard})]; 
		end

		if (keep_matches)
			if ~isempty(TmpIdx)
				valid_entries_in_original_list_idx(end+1) = iFile;
			end
		else
			if isempty(TmpIdx)
				valid_entries_in_original_list_idx(end+1) = iFile;
			end
		end
	end
	pruned_list = original_list(valid_entries_in_original_list_idx);
end

valid_entries_in_original_list_ldx(valid_entries_in_original_list_idx) = 1;
end

