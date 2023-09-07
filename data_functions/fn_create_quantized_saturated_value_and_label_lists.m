function [ output_struct ] = fn_create_quantized_saturated_value_and_label_lists( input_array, quantum, quantum_method_string, saturation_min, saturation_max, value_prefix, good_trial_idx )
%FN_CREATE_QUANTIZED_SATURATED_VALUE_AND_LABEL_LISTS Summary of this function goes here
%   Detailed explanation goes here
output_struct = struct();

output_struct.input_array = input_array;

% Note:
%	For saturation values to be precise, first saturate then quantize AND
%	the saturation vlues need to be integer multiples of quantum


% saturate?
output_struct.parameter.saturation_min = saturation_min;
output_struct.parameter.saturation_max = saturation_max;
if (~isempty(saturation_min)) || (~isempty(saturation_max))
	input_array = fn_saturate_by_min_max(input_array, saturation_min, saturation_max);
	output_struct.saturated_data = input_array;
	value_prefix = ['s', value_prefix];
	if (~isempty(saturation_min))
		min_sat_idx = find(input_array == saturation_min);
		% this test is limited by floating point precision, but that should
		% be save to ignore
		if (ceil(saturation_min / quantum) ~= floor(saturation_min / quantum))
			disp(['Selected low saturation (', num2str(saturation_min), ') value not integer multiple of quantum (', num2str(quantum), '), saturation will not be precise...']);
		end
	else
		min_sat_idx = [];
	end
	
	if (~isempty(saturation_max))
		max_sat_idx = find(input_array == saturation_max);
		if (ceil(saturation_max / quantum) ~= floor(saturation_max / quantum))
			disp(['Selected high saturation (', num2str(saturation_max), ') value not integer multiple of quantum (', num2str(quantum), '), saturation will not be precise...']);
		end
	else
		max_sat_idx = [];
	end
	
end


if (quantum > min(abs([saturation_max, saturation_min])))
	error('Absolute saturation values need to be >= quantum...');
end	

% quantize?
output_struct.parameter.quantum = quantum;
output_struct.parameter.quantum_method_string = quantum_method_string;
if (~isempty(quantum) || (quantum ~= 0))
	input_array =  fn_quantize(input_array, quantum, quantum_method_string);
	output_struct.quantized_data = input_array;
	value_prefix = ['q', value_prefix];
end

% % testing
% tmp_ceil = fn_quantize(output_struct.saturated_data, quantum, 'ceil');
% tmp_floor = fn_quantize(output_struct.saturated_data, quantum, 'floor');
% tmp = [output_struct.input_array, output_struct.quantized_data, tmp_ceil, tmp_floor]




% convert to prefixed cell list
% label the signs from the original data, as this will conserve the sign of
% differences close to zero
input_sign_list = sign(output_struct.input_array);
sign_list = cell(size(input_sign_list));
sign_list(find(input_sign_list == -1)) = {'-'};
sign_list(find(input_sign_list == 1)) = {'+'};
sign_list(find(input_sign_list == 0)) = {'_'};
sign_list(isnan(input_sign_list)) = {'N'};
output_struct.labeled_values = cellstr(strcat(value_prefix, sign_list, string(abs(input_array))));

if (~isempty(saturation_min)) || (~isempty(saturation_max)) 
	equality_string_list = cell(size(input_sign_list));
	equality_string_list(:) = {'_eq'};	% equal
	equality_string_list(min_sat_idx) = {'_le'}; % less or equal
	equality_string_list(max_sat_idx) = {'_ge'}; % greater or equal
	
	output_struct.symbolic_sat_labeled_values = cellstr(strcat(value_prefix, equality_string_list, sign_list, string(abs(input_array))));
end

% extract unique value names for all trials
[output_struct.all_unique_labeled_values, ~, output_struct.all_unique_labeled_values_idx_list] = unique(output_struct.labeled_values);
[output_struct.all_unique_symbolic_sat_labeled_values, ~, output_struct.all_unique_symbolic_sat_labeled_values_idx_list] = unique(output_struct.symbolic_sat_labeled_values);

% extract unique value names for good_trials
[output_struct.unique_labeled_values, ~, output_struct.unique_labeled_values_idx_list] = unique(output_struct.labeled_values(good_trial_idx));
[output_struct.unique_symbolic_sat_labeled_values, ~, output_struct.unique_symbolic_sat_labeled_values_idx_list] = unique(output_struct.symbolic_sat_labeled_values(good_trial_idx));


return
end

