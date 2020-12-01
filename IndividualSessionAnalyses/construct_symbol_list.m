function [ symbol_list, p_list, cols_idx_per_symbol] = construct_symbol_list( fisherexact_pairwaise_P_matrix, row_names, col_names, group_by_dim, match_suffix )
%CONSTRUCT_SYMBOL_LIST Summary of this function goes here
%   Detailed explanation goes here
% NOTE: if match suffix is chance and there is only one chance name pick
% prob diff from chance
% cols_idx_per_symbol: this contains the column indices for each reported significant pair

p_class_upper_bounds_list = [0.05, 0.01, 0.005];
sorted_symbol_list = {'*', '**', '***'};
data_group_names = eval([group_by_dim, '_names']);


% if not set aim for all
if ~exist('match_suffix', 'var') || isempty(match_suffix)
	full_match = 1;
	n_match_suffixes = length(data_group_names);
else
	full_match = 0;
	% make sure this is a cell so we can iterate simpler
	if ~iscell(match_suffix)
		match_suffix = {match_suffix};
	end
	n_match_suffixes = length(match_suffix);	
end


p_list = cell([size(data_group_names, 1), size(data_group_names, 2) * n_match_suffixes]);
symbol_list = cell([size(data_group_names, 1), size(data_group_names, 2) * n_match_suffixes]);
cols_idx_per_symbol = zeros([2, size(data_group_names, 2) * n_match_suffixes]);



% for each name find whether there is a match
for i_group = 1 : length(data_group_names)
	cur_group_name = data_group_names{i_group};
	

	
	for i_match_suffix = 1 : n_match_suffixes
		cur_out_col_idx = (i_group - 1) * n_match_suffixes + i_match_suffix;
		%cur_matched_group_name = [cur_group_name, match_suffix];
		
		if (full_match)
			% just iterate over all columns...
			cur_matched_idx = i_match_suffix;
			cur_match_suffix = '';
		else
			cur_match_suffix = match_suffix{i_match_suffix};
			cur_matched_group_name = construct_match_name(cur_group_name, cur_match_suffix, data_group_names);
			cur_matched_idx = find(strcmp(data_group_names, cur_matched_group_name));
		end
		
		%p_list{cur_out_col_idx} = '';
		if ~isempty(cur_matched_idx)
			p_list{cur_out_col_idx} = fisherexact_pairwaise_P_matrix(i_group, cur_matched_idx);
			cols_idx_per_symbol(:, cur_out_col_idx) = [i_group; cur_matched_idx];
		end
		
		symbol_list{cur_out_col_idx} = '';
		if strcmp(cur_match_suffix, 'chance') && (strcmp('chance', data_group_names(end)) == 1)
			chance_idx = length(data_group_names);	% if there each group was tested against chance this will br in the last field...
			p_list{cur_out_col_idx} = fisherexact_pairwaise_P_matrix(i_group, chance_idx);
		end
	end
end

% now map the extracted probabilities to symbols
for i_out_cols = 1 : length(p_list)
	cur_p = p_list{i_out_cols};
	if ~isempty(cur_p)
		cur_p_class = max(find(p_class_upper_bounds_list >= cur_p));
		if ~isempty(cur_p_class);
			symbol_list{i_out_cols} = sorted_symbol_list{cur_p_class};
		else
			symbol_list{i_out_cols} = '';
		end
	end
end

% clear not assigned output columns...
valid_col_idx = find(cols_idx_per_symbol(1, :) ~= 0);
if ~isempty(valid_col_idx) && sum(strcmp('chance', data_group_names(:))) > 0
	valid_col_idx(end + 1) = valid_col_idx(end)+1;	% but leave a faked chance column...
else
% 	disp('Doh...');
end


% find the inversions, like (1,2) and (2,1)
inverted_col_idx_list = [];
for i_cols = 1 : size(cols_idx_per_symbol, 2)
	cur_col1 = cols_idx_per_symbol(1, i_cols);
	cur_col2 = cols_idx_per_symbol(2, i_cols);
	inverted_col1_idx = find(cols_idx_per_symbol(2, :) == cur_col1);
	inverted_col2_idx = find(cols_idx_per_symbol(1, :) == cur_col2);
	inverted_col_idx = intersect(inverted_col1_idx, inverted_col2_idx);
	if inverted_col_idx >= i_cols
		inverted_col_idx_list(end+1) = inverted_col_idx;
	end
end

valid_col_idx = setdiff(valid_col_idx, inverted_col_idx_list);


% note this is over complete and contains less than usefull doubles like
% (1,2) and (2,1) which have the same symbol and P value
symbol_list = symbol_list(valid_col_idx);
p_list = p_list(valid_col_idx);
cols_idx_per_symbol = cols_idx_per_symbol(:, valid_col_idx);


return
end

function [	cur_matched_group_name, cur_matched_group_idx ] = construct_match_name( cur_group_name, match_fragment, data_group_names )
% try to find the matching group, that just differs by including
% match_fragment somewhere in the name

cur_matched_group_name = '';

% the match needs to be of length length(cur_group_name) + length(match_fragment)
% match_length = length(cur_group_name) + length(match_fragment);
cur_match_fingerprint = sort([cur_group_name, match_fragment]);

% alternatively excise the match_fragment from all data_group_names it is
% found in...
group_fingerprint_list = cell(size(data_group_names));
for i_group = 1 : length(data_group_names)
	group_fingerprint_list{i_group} = sort(data_group_names{i_group});
end

cur_matched_group_idx = find(strcmp(group_fingerprint_list, cur_match_fingerprint));
if ~isempty(cur_matched_group_idx)
	if length(cur_matched_group_idx) == 1
		cur_matched_group_name = data_group_names{cur_matched_group_idx};
	else
		error('match heuistic too weak, implement excision algorithm...');
	end
end

return
end