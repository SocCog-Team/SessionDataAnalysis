function [ aggregate_perswitch_struct, pertrial_perswitch_struct ] = fn_build_PSTH_by_switch_trial_struct( trial_idx, choice_combination_color_string, selected_choice_combinaton_pattern_list, data, pattern_alignment_offset, n_pre_bins, n_post_bins, strict_pattern_extension, pad_mismatch_with_nan)
%FN_BUILD_PSTH_BY_SWITCH_TRIAL_STRUCT Summary of this function goes here
%   Detailed explanation goes here
% instead of trying to deal with pre and post bins as explicit corner cases
% we simply extend both the classifier string and the data array/list by
% the approriate pre and postbins (char(0), and NaN respectively)

% to collect the aggregate, nanmean, nanstd, CI per bin and switch
aggregate_perswitch_struct = [];
% to collect the raw per trial data for each event (potentially padded with NaNs)
pertrial_perswitch_struct = [];

choice_combination_color_string = choice_combination_color_string(trial_idx);
data = data(trial_idx);

% the offset of the event in the pattern to properly align the traces 
if ~exist('pattern_alignment_offset', 'var') || isempty(pattern_alignment_offset)
	pattern_alignment_offset = 1;
end
% the extent of the histogramm into the past
if ~exist('n_pre_bins', 'var') || isempty(n_pre_bins)
	n_pre_bins = 5;
end
% the extent of the histogramm into the future
if ~exist('n_post_bins', 'var') || isempty(n_post_bins)
	n_post_bins = 2;
end
% accept all possible values outside the pattern, or require an extension
% of the first elemant into the past and the second into the future
if ~exist('strict_pattern_extension', 'var') || isempty(strict_pattern_extension)
	strict_pattern_extension = 1;
end
% in strict_pattern_extension mode, how to deal with non matching bins,
% exclude the event or map the "offending" bins to NaN
if ~exist('pad_mismatch_with_nan', 'var') || isempty(pad_mismatch_with_nan)
	pad_mismatch_with_nan = 1;
end


% TODO: extend choice_combination_color_string (and data) by n_pre_bins spaces (NaNs) at the beginning and
% n_post_bins spaces (NaNs) at the end to allow to find pre and post bins
choice_pre_bin_array = char(zeros([1, n_pre_bins]));
data_pre_bin_array = NaN * (ones([n_pre_bins, 1]));
choice_post_bin_array = char(zeros([1, n_post_bins]));
data_post_bin_array = NaN * (ones([n_post_bins, 1]));
orig_choice_combination_color_string = choice_combination_color_string;
choice_combination_color_string = [choice_pre_bin_array, orig_choice_combination_color_string, choice_post_bin_array];
data = [data_pre_bin_array; data; data_post_bin_array];


% first collect the actual switch trial indices
% ATTENTION these trial indices are only valid inside the current choice_combination_color_string
% and do not reflect "real" trial numbers valid externally, but since we do
% not return trial numbers at all, this is currently save.
switch_trial_struct = fn_extract_switches_from_classifier_string(choice_combination_color_string, selected_choice_combinaton_pattern_list);



for i_switch_type = 1 : length(selected_choice_combinaton_pattern_list)
	current_switch_type_string = selected_choice_combinaton_pattern_list{i_switch_type};
	n_switches = length(switch_trial_struct.(current_switch_type_string));
	pertrial_raw_array = nan([n_switches, (n_pre_bins + 1 + n_post_bins)]);
	pertrial_padded_array = pertrial_raw_array;
	% so we always return at least empty filelds
	pertrial_perswitch_struct.(current_switch_type_string) = [];
	aggregate_perswitch_struct.(current_switch_type_string) = [];

	if (n_switches)
		% to extend the pattern we need to know what to look for
		current_pattern_start_char = current_switch_type_string(1);
		current_pattern_stop_char = current_switch_type_string(end);		
		cur_switchtype_idx_list = switch_trial_struct.(current_switch_type_string);		
		for i_switch = 1 : n_switches
			cur_switch_idx = cur_switchtype_idx_list(i_switch);
			% extract the classifier data
			cur_switch_start_bin_idx = cur_switch_idx +  pattern_alignment_offset - n_pre_bins;
			cur_switch_end_bin_idx = cur_switch_idx +  pattern_alignment_offset + n_post_bins;
			% special case the edges in relation to the peri event
			% window...
			
			cur_switch_start_bin_idx_offset = 0;
			cur_switch_end_bin_idx_offset = 0;
			
			% effectively too short a data set
			if (cur_switch_start_bin_idx < 1) && (cur_switch_end_bin_idx > length(data))
				error('This should not trigger anymore, since we pre extend slassifier string and data array.');
				current_PeriEventTimeData_raw = nan([(n_pre_bins + 1 + n_post_bins), 1]);
				current_PeriEventTimeData_padded = current_PeriEventTimeData_raw;
			else
				if (cur_switch_start_bin_idx < 1)
					error('This should not trigger anymore, since we pre extend slassifier string and data array.');
					n_missing_bins = 1 - cur_switch_start_bin_idx;
					current_PeriEventTimeData_padded = [nan([n_missing_bins, 1]); data(1:cur_switch_end_bin_idx)];
					current_PeriEventTimeData_raw = nan(size(current_PeriEventTimeData_padded)); % mark event as incomplete
					cur_switch_start_bin_idx_offset = n_missing_bins;
				elseif (cur_switch_end_bin_idx > length(data))
					error('This should not trigger anymore, since we pre extend slassifier string and data array.');
					n_missing_bins = cur_switch_end_bin_idx - length(data);
					current_PeriEventTimeData_padded = [data(cur_switch_start_bin_idx:end); nan([n_missing_bins, 1])];
					current_PeriEventTimeData_raw = nan(size(current_PeriEventTimeData_padded)); % mark event as incomplete
					cur_switch_end_bin_idx_offset = n_missing_bins;
				else
					current_PeriEventTimeData_raw = data(cur_switch_start_bin_idx:cur_switch_end_bin_idx);
					current_PeriEventTimeData_padded = current_PeriEventTimeData_raw;
				end
			end
			
			if (strict_pattern_extension) && ~((cur_switch_start_bin_idx < 1) && (cur_switch_end_bin_idx > length(data)))
				% look into the past
				tmp_start_idx = cur_switch_idx - (n_pre_bins - cur_switch_start_bin_idx_offset) + 1;
				tmp_start_idx = max([tmp_start_idx, 1]); % stay inside the arry!
				tmp_end_idx = cur_switch_idx;
				mismatch_char_idx = find(choice_combination_color_string(tmp_start_idx:tmp_end_idx) ~= current_pattern_start_char);
				if ~isempty(mismatch_char_idx)
					adjusted_mismatch_char_idx = mismatch_char_idx + cur_switch_start_bin_idx_offset;	% these are in range of (1:1:n_pre_bins)
					current_PeriEventTimeData_padded(adjusted_mismatch_char_idx) = NaN;
				end
				
				% look into the future
				tmp_start_idx = cur_switch_idx + pattern_alignment_offset;
				tmp_end_idx = tmp_start_idx + (n_post_bins - cur_switch_end_bin_idx_offset);				
				mismatch_char_idx = find(choice_combination_color_string(tmp_start_idx:tmp_end_idx) ~= current_pattern_stop_char);
				if ~isempty(mismatch_char_idx)
					adjusted_mismatch_char_idx = mismatch_char_idx + n_pre_bins;	% these are in range of (1:1:n_pre_bins)
					current_PeriEventTimeData_padded(adjusted_mismatch_char_idx) = NaN;
				end	
			end
			pertrial_raw_array(i_switch, :) = current_PeriEventTimeData_raw';
			pertrial_padded_array(i_switch, :) = current_PeriEventTimeData_padded';
			
		end

		% create a string representation of the outcome sequence
		tmp_string = char(zeros([size(current_PeriEventTimeData_raw')]));
		raw_pattern = tmp_string;
		nan_padded_pattern = tmp_string;
		nan_padded_pattern(1:end) = current_pattern_start_char;
		nan_padded_pattern(n_pre_bins + pattern_alignment_offset:end) = current_pattern_stop_char;
		
		
		%raw_pattern(n_pre_bins: n_pre_bins - pattern_alignment_offset + length(current_switch_type_string)) = current_switch_type_string;
		%nan_padded_pattern(n_pre_bins: n_pre_bins - pattern_alignment_offset + length(current_switch_type_string)) = current_switch_type_string;

		raw_pattern(n_pre_bins - pattern_alignment_offset + 1: n_pre_bins - pattern_alignment_offset + length(current_switch_type_string)) = current_switch_type_string;
		nan_padded_pattern(n_pre_bins - pattern_alignment_offset + 1: n_pre_bins - pattern_alignment_offset + length(current_switch_type_string)) = current_switch_type_string;

		
		%raw_pattern(n_pre_bins + 1: n_pre_bins + 1 + length(current_switch_type_string)) = current_switch_type_string;
		%nan_padded_pattern(n_pre_bins + 1: n_pre_bins + 1 + length(current_switch_type_string)) = current_switch_type_string;
				
		pertrial_perswitch_struct.(current_switch_type_string).raw = pertrial_raw_array;
		pertrial_perswitch_struct.(current_switch_type_string).nan_padded = pertrial_padded_array;
		pertrial_perswitch_struct.(current_switch_type_string).raw_pattern = raw_pattern;
		pertrial_perswitch_struct.(current_switch_type_string).nan_padded_pattern = nan_padded_pattern;
		% create aggregate data
		aggregate_perswitch_struct.(current_switch_type_string).raw = fn_aggregate_event_data(pertrial_raw_array);
		aggregate_perswitch_struct.(current_switch_type_string).nan_padded = fn_aggregate_event_data(pertrial_padded_array);
		aggregate_perswitch_struct.(current_switch_type_string).raw_pattern = raw_pattern;
		aggregate_perswitch_struct.(current_switch_type_string).nan_padded_pattern = nan_padded_pattern;

	end
end

end
