function [ quantized_array ] = fn_quantize(input_array, quantum, quantization_method_string)
%FN_QUANTIZE Summary of this function goes here
%   Detailed explanation goes here
quantized_array = input_array;

if isempty(quantum) || (quantum == 0)
	% we take this as signal to not quantize at all
	return
end

if ~exist('quantization_method_string', 'var') || isempty(quantization_method_string)
   quantization_method_string = 'round'; 
end    

switch quantization_method_string
	case 'round'
		quantized_array = round(input_array / quantum) * quantum;
	case 'ceil'
		quantized_array = ceil(input_array / quantum) * quantum;
	case 'floor'
		quantized_array = floor(input_array / quantum) * quantum;
	otherwise
		error(['Unknown quantization_method_string: ', quantization_method_string]);
end

return
end

