function [ pattern_in_class_string_struct ] = fn_extract_switches_from_classifier_string( classifier_string, search_pattern_list )
%FN_EXTRACT_SWITCHES_FROM_CLASSIFIER_STRING Summary of this function goes here
%   find the indices of all pattern in search_pattern_list in
%   classifier_string and return the index

pattern_in_class_string_struct = struct();

if ~exist('search_pattern_list', 'var') || isempty(search_pattern_list)
	search_pattern_list = [];
	% find all possible combinations
	unique_chars = unique(classifier_string);
	if length(unique_chars <= 15)
		sorted_unique_combinations = combnk(unique_chars, 2); % switches/protoswitches are always pattern of two
		n_combinations = size(sorted_unique_combinations, 1);
		
		for i_combination = 1 : n_combinations
			tmp_permutations = perms(sorted_unique_combinations(i_combination, :));
			search_pattern_list{end+1} = tmp_permutations(1, :);
			search_pattern_list{end+1} = tmp_permutations(2, :);
		end
		
	else
		error(['Too many elements in classifier_string to enumerate all combinations: ', unique_chars]);
	end
	
end


% now extract the pattern indices
for i_pattern = 1 : length(search_pattern_list)
	cur_pattern = search_pattern_list{i_pattern};
	if size(classifier_string, 1) == 1
		pattern_in_class_string_struct.(cur_pattern) = strfind(classifier_string, cur_pattern);
	else
		pattern_in_class_string_struct.(cur_pattern) = strfind(classifier_string', cur_pattern);
	end
end

return
end

