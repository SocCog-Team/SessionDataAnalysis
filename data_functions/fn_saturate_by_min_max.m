function [saturated_array] = fn_saturate_by_min_max(input_array, min_saturation_value, max_saturation_value)
%FN_SATURATE_BY_MIN_MAX Summary of this function goes here
%   Detailed explanation goes here
saturated_array = input_array;
 
if ~exist('min_saturation_value', 'var') || isempty(min_saturation_value)
   min_saturation_value = []; 
end    
 
if ~exist('max_saturation_value', 'var') || isempty(max_saturation_value)
   max_saturation_value = []; 
end    
 
 
if ~isempty(min_saturation_value)
    saturated_array(find(input_array <= min_saturation_value)) = min_saturation_value;
end
 
if ~isempty(max_saturation_value)
    saturated_array(find(input_array >= max_saturation_value)) = max_saturation_value;
end
 
return
end

