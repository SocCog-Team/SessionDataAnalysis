function [ histogram_struct ] = fn_merge_pertrial_structs( input_histogram_struct, new_histogram_struct, switches_list )
%FN_MERGE_PERTRIAL_STRUCTS Summary of this function goes here
%   Detailed explanation goes here
histogram_struct = input_histogram_struct;

%SideA_pattern_histogram_struct = fn_merge_pertrial_structs(SideA_pattern_histogram_struct, current_SideA_pattern_histogram_pertrial_struct);


for i_switch_type = 1 : length(switches_list)
	current_switch_type = switches_list{i_switch_type};
	copy_over.raw = 0;
	copy_over.nan_padded = 0;
	if isempty(histogram_struct)
		copy_over.raw = 1;
		copy_over.nan_padded = 1;
	elseif ~isfield(histogram_struct, current_switch_type)
		copy_over.raw = 1;
		copy_over.nan_padded = 1;
	else
		if (~isfield(histogram_struct.(current_switch_type), 'raw'))
			copy_over.raw = 1;
		end
		if (~isfield(histogram_struct.(current_switch_type), 'nan_padded'))
			copy_over.nan_padded = 1;
		end
	end
	
	if (copy_over.raw) && (copy_over.nan_padded)
		histogram_struct.(current_switch_type) = new_histogram_struct.(current_switch_type);
	else
		if (copy_over.raw)
			if isempty(new_histogram_struct.(current_switch_type))
				histogram_struct.(current_switch_type) = input_histogram_struct.(current_switch_type);
			else
				histogram_struct.(current_switch_type).raw = new_histogram_struct.(current_switch_type).raw;
				histogram_struct.(current_switch_type).raw_pattern = new_histogram_struct.(current_switch_type).raw_pattern;
			end
		else
			if isempty(new_histogram_struct.(current_switch_type))
				histogram_struct.(current_switch_type).raw = input_histogram_struct.(current_switch_type).raw;
				histogram_struct.(current_switch_type).raw_pattern = input_histogram_struct.(current_switch_type).raw_pattern;
			else
				histogram_struct.(current_switch_type).raw = [input_histogram_struct.(current_switch_type).raw; new_histogram_struct.(current_switch_type).raw];
				histogram_struct.(current_switch_type).raw_pattern = new_histogram_struct.(current_switch_type).raw_pattern;
			end
		end
		
		if (copy_over.nan_padded)
			if isempty(new_histogram_struct.(current_switch_type))
				histogram_struct.(current_switch_type) = input_histogram_struct.(current_switch_type);
			else
				histogram_struct.(current_switch_type).nan_padded = new_histogram_struct.(current_switch_type).nan_padded;
				histogram_struct.(current_switch_type).nan_padded_pattern = new_histogram_struct.(current_switch_type).nan_padded_pattern;
			end
		else
			if isempty(new_histogram_struct.(current_switch_type))
				histogram_struct.(current_switch_type).nan_padded = input_histogram_struct.(current_switch_type).nan_padded;
				histogram_struct.(current_switch_type).nan_padded_pattern = input_histogram_struct.(current_switch_type).nan_padded_pattern;
			else
				histogram_struct.(current_switch_type).nan_padded = [input_histogram_struct.(current_switch_type).nan_padded; new_histogram_struct.(current_switch_type).nan_padded];
				histogram_struct.(current_switch_type).nan_padded_pattern = new_histogram_struct.(current_switch_type).nan_padded_pattern;
			end
		end
	end
		
end


return
end

