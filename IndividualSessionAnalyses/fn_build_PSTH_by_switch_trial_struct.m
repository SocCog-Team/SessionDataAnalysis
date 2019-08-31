function [ aggregate_perswitch_struct, pertrial_perswitch_struct ] = fn_build_PSTH_by_switch_trial_struct( trial_idx, choice_combination_color_string, selected_choice_combinaton_pattern_list, data, pattern_alignment_offset, n_pre_bins, n_post_bins, strict_pattern_extension, pad_mismatch_with_nan)
%FN_BUILD_PSTH_BY_SWITCH_TRIAL_STRUCT Summary of this function goes here
%   Detailed explanation goes here

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

% first collect the actual switch trial indices
switch_trial_struct = fn_extract_switches_from_classifier_string(choice_combination_color_string, selected_choice_combinaton_pattern_list);



for i_switch_type = 1 : length(selected_choice_combinaton_pattern_list)
	current_switch_type_string = selected_choice_combinaton_pattern_list{i_switch_type};
	n_switches = length(switch_trial_struct.(current_switch_type_string));
	pertrial_raw_array = nan([n_switches, (n_pre_bins + 1 + n_post_bins)]);
	pertrial_padded_array = pertrial_raw_array;
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
			if (cur_switch_start_bin_idx < 1)
				n_missing_bins = 1 - cur_switch_start_bin_idx;
				current_PeriEventTimeData_padded = [nan([n_missing_bins, 1]); data(1:cur_switch_end_bin_idx)];
				current_PeriEventTimeData_raw = nan(size(current_PeriEventTimeData_padded)); % mark event as incomplete	
				cur_switch_start_bin_idx_offset = n_missing_bins;
			elseif (cur_switch_end_bin_idx > length(data))
				n_missing_bins = cur_switch_end_bin_idx - length(data);
				current_PeriEventTimeData_padded = [data(cur_switch_start_bin_idx:end); nan([n_missing_bins, 1])];
				if (length(current_PeriEventTimeData_padded) ~= 8)
					disp('Doh...');
				end
				current_PeriEventTimeData_raw = nan(size(current_PeriEventTimeData_padded)); % mark event as incomplete	
				cur_switch_end_bin_idx_offset = n_missing_bins;
			else
				current_PeriEventTimeData_raw = data(cur_switch_start_bin_idx:cur_switch_end_bin_idx);
				current_PeriEventTimeData_padded = current_PeriEventTimeData_raw;
			end			
			
			if (strict_pattern_extension)
				% look into the past
				tmp_start_idx = cur_switch_idx - (n_pre_bins - cur_switch_start_bin_idx_offset) + 1;	
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
		
		pertrial_perswitch_struct.(current_switch_type_string).raw = pertrial_raw_array;
		pertrial_perswitch_struct.(current_switch_type_string).nan_padded = pertrial_padded_array;
		% create aggregate data
		aggregate_perswitch_struct.(current_switch_type_string).raw = fn_aggregate_event_data(pertrial_raw_array);
		aggregate_perswitch_struct.(current_switch_type_string).nan_padded = fn_aggregate_event_data(pertrial_padded_array);

	end
end

end

function [ aggregate_peri_event_data_struct ] = fn_aggregate_event_data( data_table )
% 
nan_handling = 'omitnan';%5 includenan or omitnan
processing_dim = 1;
std_weight = 0;
alpha = 0.05; % for confidence interval halfwidth

% now just aggregate over the data
aggregate_peri_event_data_struct.median = median(data_table, processing_dim, nan_handling);
aggregate_peri_event_data_struct.max = max(data_table, [], processing_dim, nan_handling);
aggregate_peri_event_data_struct.min = min(data_table, [], processing_dim, nan_handling);
aggregate_peri_event_data_struct.mean = mean(data_table, processing_dim, nan_handling);
aggregate_peri_event_data_struct.std = std(data_table, std_weight, processing_dim, nan_handling);
aggregate_peri_event_data_struct.n = sum(~isnan(data_table), processing_dim);
aggregate_peri_event_data_struct.cihw = calc_cihw(aggregate_peri_event_data_struct.std, aggregate_peri_event_data_struct.n, alpha);


return
end
