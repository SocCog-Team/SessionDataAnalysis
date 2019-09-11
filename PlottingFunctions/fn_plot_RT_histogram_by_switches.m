function [ out_figure_handle, merged_classifier_char_string ] = fn_plot_RT_histogram_by_switches( in_figure_handle, RT_by_switch_struct_list, selected_switches_list, RT_by_switch_title_prefix_list, RT_by_switch_switch_pre_bins_list, RT_by_switch_switch_n_bins_list, RT_by_switch_color_list, aggregate_type_list)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% TODO:
%	collect true max and min for scaling
%	add color bar on bottom?
%		rather construct a string of the concatenated patterns to allow the
%		construct of a colorbar by the caller

out_figure_handle = in_figure_handle;
n_data_structs = length(RT_by_switch_struct_list);

font_weight = 'normal';
font_size = 8;
min_y_lim = 300;
max_y_lim = 1000;

plot_separately = 0;

max_RT_sample = [];
min_RT_sample = [];
merged_classifier_char_string = '';

for i_switch_struct = 1 : n_data_structs
	current_data_struct = RT_by_switch_struct_list{i_switch_struct};
	current_prefix = RT_by_switch_title_prefix_list{i_switch_struct};
	current_switch_pre_bins = RT_by_switch_switch_pre_bins_list{i_switch_struct};
	current_switch_n_bins = RT_by_switch_switch_n_bins_list{i_switch_struct};
	current_data_color = RT_by_switch_color_list{i_switch_struct};
	current_aggregate_type = aggregate_type_list{i_switch_struct};
	
	
	plot_offset = ceil(current_switch_n_bins * 0.1);
	
	if (plot_separately)
		subplot(n_data_structs, 1, i_switch_struct);
		% for scaling the plors separately
		max_RT_sample = [];
		min_RT_sample = [];
	end
	hold on
	current_xtick_pos = [];
	current_xtick_label = [];
	for i_switch = 1 : length(selected_switches_list)
		current_switch = selected_switches_list{i_switch};
		current_data = current_data_struct.(current_switch);
		current_switch_x_pos = plot_offset + current_switch_pre_bins + 1;
		current_xtick_pos(end+1) = current_switch_x_pos - 1;
		current_xtick_label{end+1} = current_switch;
		
		if isempty(current_data)
			current_classifier_char_string = char(zeros([1 current_switch_n_bins]));
		else
			current_classifier_char_string = current_data.([current_aggregate_type, '_pattern']);
		end
		% just extend the string by grafting current_classifier_char_string
		% at the appropriate position.
		merged_classifier_char_string(plot_offset:plot_offset-1+length(current_classifier_char_string)) = current_classifier_char_string;
		
		plot([current_switch_x_pos - 1, current_switch_x_pos - 1], [min_y_lim, max_y_lim], 'Color', [0 0 0], 'LineWidth', 0.125, 'LineStyle', '--');
		
		% is there something to plot?
		if ~isempty(current_data)
			current_x_vec = (plot_offset:1:(plot_offset + current_switch_n_bins - 1));
			plot(current_x_vec, current_data.(current_aggregate_type).mean, 'Color', current_data_color, 'Marker', '+', 'MarkerSize', 2, 'LineWidth', 0.66);
			
			%plot(current_x_vec, (current_data.(current_aggregate_type).mean - current_data.(current_aggregate_type).cihw), 'Color', current_data_color, 'Marker', '.', 'MarkerSize', 2, 'LineWidth', 0.5);
			%plot(current_x_vec, (current_data.(current_aggregate_type).mean + current_data.(current_aggregate_type).cihw), 'Color', current_data_color, 'Marker', '.', 'MarkerSize', 2, 'LineWidth', 0.5);
			inverse_index = (length(current_x_vec):-1:1);
			current_x_vec_patch = [current_x_vec, current_x_vec(inverse_index)];
			tmp_upper_ci = current_data.(current_aggregate_type).mean + current_data.(current_aggregate_type).cihw;
			tmp_lower_ci = current_data.(current_aggregate_type).mean - current_data.(current_aggregate_type).cihw;
			% the confidence intervals as transparent patch...
			patch('XData', current_x_vec_patch, 'YData', [tmp_upper_ci, tmp_lower_ci(inverse_index)], 'FaceColor', current_data_color, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
			
			max_RT_sample = max([max_RT_sample; current_data.(current_aggregate_type).mean(:)]);
			min_RT_sample = min([min_RT_sample; current_data.(current_aggregate_type).mean(:)]);
			
			
		end
		plot_offset = plot_offset + current_switch_n_bins + ceil(current_switch_n_bins * 0.2);
		
		
	end
	
	set(gca(), 'XLim', [0, (plot_offset + ceil(current_switch_n_bins * 0.1))]);
	set(gca(), 'XTick', current_xtick_pos);
	set(gca(),'TickLabelInterpreter','none');
	set(gca(), 'XTickLabel', current_xtick_label, 'FontWeight', 'bold');
	
	if (plot_separately)
		fn_label_and_scale_plot(min_y_lim, max_y_lim, max_RT_sample, min_RT_sample, font_weight, font_size);
	end
	
	hold off
	
end

if ~(plot_separately)
	fn_label_and_scale_plot(min_y_lim, max_y_lim, max_RT_sample, min_RT_sample, font_weight, font_size);
end

return
end

function [ ] = fn_label_and_scale_plot( min_y_lim, max_y_lim, max_RT_sample, min_RT_sample, font_weight, font_size )
% scale the axis.
y_lim = get(gca(), 'YLim');

overscale_ratio = 0.1;
underscale_ratio = 0.2;
% try to scale to real data first
if ~isempty(min_RT_sample)
	if (y_lim(1) < min_RT_sample * (1 - underscale_ratio))
		y_lim(1) = min_RT_sample * (1 - underscale_ratio);
	end
end
if ~isempty(max_RT_sample)
	if (y_lim(2) > max_RT_sample * (1 + overscale_ratio))
		y_lim(2) = max_RT_sample * (1 + overscale_ratio);
	end
end

% emergency scaling to exclude extreme samples
if (y_lim(1) < min_y_lim)
	y_lim(1) = min_y_lim;
end
if (y_lim(2) > max_y_lim)
	y_lim(2) = max_y_lim;
end


if y_lim(1) >= y_lim(2)
	y_lim(1) = min_y_lim;
	y_lim(2) = max_y_lim;
end	
	
set(gca(), 'YLim', y_lim);


xlabel('Choice combination switches', 'Interpreter', 'none', 'FontWeight', font_weight, 'FontSize', font_size);
ylabel('Reaction time [ms]', 'Interpreter', 'none', 'FontWeight', font_weight, 'FontSize', font_size);

return
end