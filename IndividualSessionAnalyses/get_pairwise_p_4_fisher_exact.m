function [ pairwise_P_matrix, pairwise_P_matrix_with_chance, P_data_not_chance_list ] = get_pairwise_p_4_fisher_exact( contingency_table, outcomes_by_chance_ratios)
%GET_PAIRWAISE_P_4_FISHER_EXACT calculate the Probability of being wrong
%for assuming any pair of columns in the contingency table are different
%   The contingency table needs to have the different outcomes in dimension
%   2 and the different test variables in dimension 1
% TODO test different less verbose fisher exact or chi square
%		implemetations
%	allow to specify a vector, outcomes_by_chance_ratios that specifies the
%	ratios of all possible outcomes to be expected under chance, used to
%	test each individual test variable against chance (matched in N)
%

debug = 0;

use_matlab_fishertest = 1;

P_data_not_chance_list = [];
pairwise_P_matrix_with_chance = [];

if nargin < 2
	outcomes_by_chance_ratios = [];
end

n_groups = size(contingency_table, 1);
n_rows = size(contingency_table, 2);

if ((n_rows ~= 2) && (use_matlab_fishertest))
	error([mfilename, ' needs to be called with exactly two rows for matlab''s fishertest to be valid.']);
end

pairwise_P_matrix = ones(n_groups);	% the main diagonal should always be one...

if ~isempty(outcomes_by_chance_ratios)
	P_data_not_chance_list = ones([1, n_groups]);
end


% The result marix should be pairwise symmetric, so only calculate unique
% values using the potentially costly fisher exact function
for i_tt_row = 1 : n_groups
	% test for each group whether is is significantly different from chance
	if ~isempty(outcomes_by_chance_ratios)
		n_trials_in_group = sum(contingency_table(i_tt_row,:));
		individual_chance_count_by_outcome = round(outcomes_by_chance_ratios(1:n_rows) * n_trials_in_group); % is rounding really okay here?
		
		if (use_matlab_fishertest) && (n_rows == 2)
			[h, P_of_cur_pair, stats] = fishertest([contingency_table(i_tt_row,:); individual_chance_count_by_outcome]);
		else
			if (n_rows == 2)
				tmp = myfisher([contingency_table(i_tt_row,:); individual_chance_count_by_outcome]);
				P_of_cur_pair = tmp(3);	% take the two-sided results...
			else
				P_of_cur_pair = myfisher([contingency_table(i_tt_row,:); individual_chance_count_by_outcome]);
			end
		end
		P_data_not_chance_list(i_tt_row) = P_of_cur_pair;
	end
	
	for i_tt_col = (i_tt_row + 1) : n_groups
		if (use_matlab_fishertest) && (n_rows == 2)
			[h, P_of_cur_pair, stats] = fishertest(contingency_table([i_tt_row, i_tt_col],:));
		else
			if (n_rows == 2)
				tmp = myfisher(contingency_table([i_tt_row, i_tt_col],:));
				P_of_cur_pair = tmp(3);	% take the two-sided results...
			else
				P_of_cur_pair = myfisher(contingency_table([i_tt_row, i_tt_col],:));
			end
		end
		% the fisher exact test results are symmetric (at least in the two sided test)
		pairwise_P_matrix(i_tt_row, i_tt_col) = P_of_cur_pair;
		pairwise_P_matrix(i_tt_col, i_tt_row) = P_of_cur_pair;
	end
end

if (debug)
	disp(contingency_table);
	disp(pairwise_P_matrix);
end

if ~isempty(outcomes_by_chance_ratios)
	pairwise_P_matrix_with_chance = ones(n_groups + 1);
	pairwise_P_matrix_with_chance(1:n_groups, 1:n_groups) = pairwise_P_matrix;
	pairwise_P_matrix_with_chance(end, 1:n_groups) = P_data_not_chance_list(1:n_groups);
	pairwise_P_matrix_with_chance(1:n_groups, end) = P_data_not_chance_list(1:n_groups);
end

return
end

